import 'dart:async';

import 'package:dualio/features/items/data/items_repository.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class SemanticItemsController extends Notifier<List<SemanticItem>> {
  @override
  List<SemanticItem> build() {
    final timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final repository = ref.read(itemsRepositoryProvider);
      if (repository != null && repository.hasSignedInUser) {
        ref.invalidate(visibleSemanticItemsProvider);
      }
    });
    ref.onDispose(timer.cancel);
    return <SemanticItem>[];
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
    return _sameNormalized(localItem.sourceUrl, remoteItem.sourceUrl) ||
        _sameNormalized(localItem.searchableSummary, remoteItem.sourceUrl);
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

String _normalizeMatchText(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\.[a-z0-9]+$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
