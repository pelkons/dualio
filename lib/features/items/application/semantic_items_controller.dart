import 'dart:async';

import 'package:dualio/features/items/data/items_repository.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final semanticItemsProvider = NotifierProvider<SemanticItemsController, List<SemanticItem>>(SemanticItemsController.new);

final removedItemIdsProvider = NotifierProvider<RemovedItemIdsController, Set<String>>(RemovedItemIdsController.new);

final visibleSemanticItemsProvider = FutureProvider<List<SemanticItem>>((ref) async {
  final localItems = ref.watch(semanticItemsProvider);
  final removedIds = ref.watch(removedItemIdsProvider);
  final repository = ref.watch(itemsRepositoryProvider);
  if (repository == null || !repository.hasSignedInUser) {
    return localItems.where((item) => !removedIds.contains(item.id)).toList(growable: false);
  }

  final localOnlyItems = localItems.where((item) => item.id.startsWith('local-'));
  final remoteItems = await repository.fetchLatestItems();
  if (remoteItems.isEmpty) {
    return localOnlyItems.where((item) => !removedIds.contains(item.id)).toList(growable: false);
  }

  final optimisticItems = localOnlyItems.where((item) {
    return item.id.startsWith('local-') && !remoteItems.any((remote) => remote.title == item.title && remote.searchableSummary == item.searchableSummary);
  });

  return <SemanticItem>[...optimisticItems, ...remoteItems].where((item) => !removedIds.contains(item.id)).toList(growable: false);
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
    return <SemanticItem>[];
  }

  void addPendingText({
    required String content,
    required SourceType sourceType,
  }) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return;
    }

    final item = SemanticItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: _inferLocalType(normalized),
      sourceType: sourceType,
      title: _titleFromContent(normalized),
      sourceUrl: sourceType == SourceType.link ? normalized : null,
      language: 'en',
      searchableSummary: normalized,
      searchableAliases: _aliasesFromContent(normalized),
      parsedContent: <String, Object?>{
        'rawText': normalized,
        'createdLocally': true,
      },
      processingStatus: ProcessingStatus.pending,
      createdLabel: 'Just now',
    );

    state = <SemanticItem>[item, ...state];

    unawaited(_syncPendingInput(normalized, sourceType));
  }

  void removeItem(SemanticItem item) {
    ref.read(removedItemIdsProvider.notifier).add(item.id);
    state = state.where((candidate) => candidate.id != item.id).toList(growable: false);
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

  Future<void> _syncPendingInput(String normalized, SourceType sourceType) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    try {
      await repository.createPendingInput(content: normalized, sourceType: sourceType);
      ref.invalidate(visibleSemanticItemsProvider);
    } on Object {
      // Local capture should stay responsive even if remote sync fails.
    }
  }

  ItemType _inferLocalType(String content) {
    final lower = content.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return ItemType.unknown;
    }
    return ItemType.note;
  }

  String _titleFromContent(String content) {
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
}
