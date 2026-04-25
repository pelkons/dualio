import 'dart:async';

import 'package:dualio/core/supabase/supabase_bootstrap.dart';
import 'package:dualio/features/auth/application/auth_controller.dart';
import 'package:dualio/features/items/data/items_repository.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final semanticItemsProvider =
    NotifierProvider<SemanticItemsController, List<SemanticItem>>(
      SemanticItemsController.new,
    );

final removedItemIdsProvider =
    NotifierProvider<RemovedItemIdsController, Set<String>>(
      RemovedItemIdsController.new,
    );

final visibleSemanticItemsProvider = FutureProvider<List<SemanticItem>>((
  ref,
) async {
  // Recompute whenever the signed-in user changes.
  ref.watch(authSessionProvider);
  final localItems = ref.watch(semanticItemsProvider);
  final removedIds = ref.watch(removedItemIdsProvider);
  final repository = ref.watch(itemsRepositoryProvider);
  if (repository == null || !repository.hasSignedInUser) {
    return localItems
        .where((item) => !removedIds.contains(item.id))
        .toList(growable: false);
  }

  final localOnlyItems = localItems.where(
    (item) => item.id.startsWith('local-'),
  );
  final remoteItems = await repository.fetchLatestItems();
  if (remoteItems.isEmpty) {
    return localOnlyItems
        .where((item) => !removedIds.contains(item.id))
        .toList(growable: false);
  }

  final optimisticItems = localOnlyItems.where((item) {
    return item.id.startsWith('local-') &&
        !remoteItems.any((remote) => _isLikelySameCapture(item, remote));
  });

  return <SemanticItem>[
    ...optimisticItems,
    ...remoteItems,
  ].where((item) => !removedIds.contains(item.id)).toList(growable: false);
});

class RemovedItemIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return <String>{};
  }

  void add(String itemId) {
    state = <String>{...state, itemId};
  }

  void clear() {
    state = <String>{};
  }
}

class SemanticItemsController extends Notifier<List<SemanticItem>> {
  RealtimeChannel? _itemsChannel;
  String? _subscribedUserId;

  @override
  List<SemanticItem> build() {
    final timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final repository = ref.read(itemsRepositoryProvider);
      if (repository != null && repository.hasSignedInUser) {
        ref.invalidate(visibleSemanticItemsProvider);
      }
    });
    ref.onDispose(() {
      timer.cancel();
      _teardownRealtime();
    });

    ref.listen<AsyncValue<Session?>>(authSessionProvider, (previous, next) {
      final previousUserId = previous?.value?.user.id;
      final nextUserId = next.value?.user.id;
      if (previousUserId != nextUserId) {
        state = <SemanticItem>[];
        ref.read(removedItemIdsProvider.notifier).clear();
      }
      _syncRealtime(nextUserId);
    });

    // Initial subscription if a session is already restored on app launch.
    final initialUserId = ref.read(authSessionProvider).value?.user.id;
    if (initialUserId != null) {
      _syncRealtime(initialUserId);
    }

    return <SemanticItem>[];
  }

  void _syncRealtime(String? userId) {
    if (userId == _subscribedUserId) {
      return;
    }
    _teardownRealtime();
    if (userId == null) {
      return;
    }
    final client = SupabaseBootstrap.client;
    if (client == null) {
      return;
    }
    final channel = client
        .channel('items:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            ref.invalidate(visibleSemanticItemsProvider);
          },
        )
        .subscribe();
    _itemsChannel = channel;
    _subscribedUserId = userId;
  }

  void _teardownRealtime() {
    final channel = _itemsChannel;
    if (channel != null) {
      SupabaseBootstrap.client?.removeChannel(channel);
    }
    _itemsChannel = null;
    _subscribedUserId = null;
  }

  void addPendingText({
    required String content,
    required SourceType sourceType,
    String personalNote = '',
  }) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return;
    }
    final isDuplicateLocalPending = state.any(
      (item) =>
          item.id.startsWith('local-') &&
          item.sourceType == sourceType &&
          item.searchableSummary == normalized,
    );
    if (isDuplicateLocalPending) {
      return;
    }

    final item = SemanticItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: _inferLocalType(normalized),
      sourceType: sourceType,
      title: _titleFromContent(normalized),
      sourceUrl: sourceType == SourceType.link ? normalized : null,
      thumbnailUrl: _isImageSource(sourceType) ? normalized : null,
      language: 'en',
      searchableSummary: normalized,
      searchableAliases: _aliasesFromContent(normalized),
      parsedContent: <String, Object?>{
        'rawText': normalized,
        'createdLocally': true,
        if (personalNote.trim().isNotEmpty) 'userNote': personalNote.trim(),
      },
      processingStatus: ProcessingStatus.pending,
      createdLabel: 'Just now',
    );

    state = <SemanticItem>[item, ...state];

    unawaited(
      _syncPendingInput(
        localItemId: item.id,
        normalized: normalized,
        sourceType: sourceType,
        personalNote: personalNote,
      ),
    );
  }

  void removeItem(SemanticItem item) {
    ref.read(removedItemIdsProvider.notifier).add(item.id);
    state = state
        .where((candidate) => candidate.id != item.id)
        .toList(growable: false);
    unawaited(_deleteRemoteItem(item.id));
  }

  Future<void> _deleteRemoteItem(String itemId) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    try {
      await repository.deleteItem(itemId);
    } on Object {
      // Deleting should keep the feed responsive even if remote sync fails.
    }
  }

  Future<void> retryProcessing(SemanticItem item) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    try {
      await repository.retryProcessing(item.id);
      ref.invalidate(visibleSemanticItemsProvider);
    } on Object {
      ref.invalidate(visibleSemanticItemsProvider);
    }
  }

  Future<void> updateUserNote(SemanticItem item, String note) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    try {
      final updated = await repository.updateUserNote(item, note);
      if (updated != null) {
        state = state
            .map((candidate) => candidate.id == item.id ? updated : candidate)
            .toList(growable: false);
      }
      ref.invalidate(visibleSemanticItemsProvider);
    } on Object {
      ref.invalidate(visibleSemanticItemsProvider);
    }
  }

  Future<void> updateGeneratedContent(
    SemanticItem item, {
    required String title,
    required Map<String, Object?> parsedContentPatch,
    required String searchableSummary,
  }) async {
    final normalizedTitle = title.trim().isEmpty ? item.title : title.trim();
    final normalizedSummary = searchableSummary.trim().isEmpty
        ? item.searchableSummary
        : searchableSummary.trim();
    final parsedContent = <String, Object?>{
      ...item.parsedContent,
      ...parsedContentPatch,
    };
    final optimisticItem = item.copyWith(
      title: normalizedTitle,
      parsedContent: parsedContent,
      searchableSummary: normalizedSummary,
    );
    state = state
        .map(
          (candidate) => candidate.id == item.id ? optimisticItem : candidate,
        )
        .toList(growable: false);

    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      ref.invalidate(visibleSemanticItemsProvider);
      return;
    }

    try {
      final updated = await repository.updateGeneratedContent(
        item,
        title: normalizedTitle,
        parsedContentPatch: parsedContentPatch,
        searchableSummary: normalizedSummary,
      );
      if (updated != null) {
        state = state
            .map((candidate) => candidate.id == item.id ? updated : candidate)
            .toList(growable: false);
      }
      ref.invalidate(visibleSemanticItemsProvider);
    } on Object {
      ref.invalidate(visibleSemanticItemsProvider);
    }
  }

  Future<void> _syncPendingInput({
    required String localItemId,
    required String normalized,
    required SourceType sourceType,
    required String personalNote,
  }) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    try {
      final remoteItem = await repository.createPendingInput(
        content: normalized,
        sourceType: sourceType,
        personalNote: personalNote,
      );
      if (remoteItem != null) {
        state = state
            .where(
              (candidate) =>
                  candidate.id != localItemId &&
                  !_isLikelySamePendingInput(
                    candidate,
                    normalized,
                    sourceType,
                    remoteItem,
                  ),
            )
            .toList(growable: false);
      }
      ref.invalidate(visibleSemanticItemsProvider);
    } on Object {
      // Local capture should stay responsive even if remote sync fails.
    }
  }

  ItemType _inferLocalType(String content) {
    if (_isImageSourceFromContent(content)) {
      return ItemType.unknown;
    }
    final lower = content.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return ItemType.unknown;
    }
    return ItemType.note;
  }

  String _titleFromContent(String content) {
    final filename = content.split(RegExp(r'[/\\]')).last;
    if (_isImageSourceFromContent(content) && filename.isNotEmpty) {
      return filename;
    }
    final compact = content.replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length <= 64) {
      return compact;
    }
    return '${compact.substring(0, 61)}...';
  }

  List<String> _aliasesFromContent(String content) {
    return content
        .split(RegExp(r'[\s,.;:!?]+'))
        .where((word) => word.length > 3)
        .take(8)
        .map((word) => word.toLowerCase())
        .toList(growable: false);
  }

  bool _isImageSource(SourceType sourceType) {
    return sourceType == SourceType.photo ||
        sourceType == SourceType.screenshot;
  }

  bool _isImageSourceFromContent(String content) {
    final lower = content.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }
}

bool _isLikelySamePendingInput(
  SemanticItem candidate,
  String normalized,
  SourceType sourceType,
  SemanticItem remoteItem,
) {
  if (!candidate.id.startsWith('local-') ||
      candidate.sourceType != sourceType) {
    return false;
  }
  if (_sameNormalized(candidate.searchableSummary, normalized)) {
    return true;
  }
  return _isLikelySameCapture(candidate, remoteItem);
}

bool _isLikelySameCapture(SemanticItem localItem, SemanticItem remoteItem) {
  if (!localItem.id.startsWith('local-')) {
    return false;
  }
  if (localItem.sourceType != remoteItem.sourceType) {
    return false;
  }
  if (_sameNormalized(
    localItem.searchableSummary,
    remoteItem.searchableSummary,
  )) {
    return true;
  }
  if (localItem.sourceType == SourceType.link) {
    if (_sameNormalized(localItem.sourceUrl, remoteItem.sourceUrl) ||
        _sameNormalized(localItem.searchableSummary, remoteItem.sourceUrl)) {
      return true;
    }
    final localKey =
        _urlMatchKey(localItem.sourceUrl) ??
        _urlMatchKey(localItem.searchableSummary);
    final remoteKey =
        _urlMatchKey(remoteItem.sourceUrl) ??
        _urlMatchKey(_remoteParsedUrl(remoteItem));
    if (localKey != null && remoteKey != null && localKey == remoteKey) {
      return true;
    }
    return false;
  }
  if (localItem.sourceType == SourceType.photo ||
      localItem.sourceType == SourceType.screenshot) {
    final localFilename = _filename(localItem.searchableSummary);
    final remoteOriginalFilename =
        _assetString(remoteItem, 'originalFilename') ??
        _filename(remoteItem.title);
    return _sameNormalized(localFilename, remoteOriginalFilename) ||
        _sameNormalized(_filename(localItem.title), remoteOriginalFilename) ||
        _containsNormalized(remoteItem.searchableSummary, localFilename);
  }
  return false;
}

String? _assetString(SemanticItem item, String key) {
  final asset = item.parsedContent['asset'];
  if (asset is Map<String, dynamic>) {
    final value = asset[key];
    return value is String ? value : null;
  }
  if (asset is Map<String, Object?>) {
    final value = asset[key];
    return value is String ? value : null;
  }
  return null;
}

String _filename(String? value) {
  if (value == null) {
    return '';
  }
  return value.split(RegExp(r'[/\\]')).last;
}

bool _sameNormalized(String? left, String? right) {
  final normalizedLeft = _normalizeMatchText(left);
  final normalizedRight = _normalizeMatchText(right);
  return normalizedLeft.isNotEmpty && normalizedLeft == normalizedRight;
}

bool _containsNormalized(String? value, String fragment) {
  final normalizedValue = _normalizeMatchText(value);
  final normalizedFragment = _normalizeMatchText(fragment);
  return normalizedFragment.isNotEmpty &&
      normalizedValue.contains(normalizedFragment);
}

String? _remoteParsedUrl(SemanticItem item) {
  final raw = item.parsedContent['url'];
  return raw is String ? raw : null;
}

String? _urlMatchKey(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  Uri uri;
  try {
    uri = Uri.parse(value.trim());
  } on FormatException {
    return null;
  }
  if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  var host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return null;
  }
  // Strip common mobile/www prefixes so canonicalisations match the original.
  for (final prefix in const ['www.', 'm.', 'mobile.', 'amp.']) {
    if (host.startsWith(prefix)) {
      host = host.substring(prefix.length);
      break;
    }
  }
  var path = uri.path;
  // Strip trailing extension and slash so /foo, /foo/, /foo.html all match.
  path = path.replaceAll(
    RegExp(r'\.(html?|php|aspx?)$', caseSensitive: false),
    '',
  );
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return '$host$path';
}

String _normalizeMatchText(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\.[a-z0-9]+$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
