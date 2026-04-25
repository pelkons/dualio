import 'dart:async';

import 'package:dualio/features/feed/presentation/screens/feed_screen.dart';
import 'package:dualio/features/auth/application/auth_controller.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/data/items_repository.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('auth user change clears local pending items and removed ids', () async {
    final authChanges = StreamController<Session?>.broadcast();
    final container = ProviderContainer(
      overrides: <Override>[
        authSessionProvider.overrideWith((ref) => authChanges.stream),
        itemsRepositoryProvider.overrideWithValue(null),
      ],
    );
    addTearDown(() async {
      await authChanges.close();
      container.dispose();
    });

    final items = container.read(semanticItemsProvider.notifier);
    items.addPendingText(
      content: 'https://example.com/article',
      sourceType: SourceType.link,
    );
    container.read(removedItemIdsProvider.notifier).add('remote-item');

    expect(container.read(semanticItemsProvider), hasLength(1));
    expect(container.read(removedItemIdsProvider), contains('remote-item'));

    authChanges.add(_session('user-a'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(semanticItemsProvider), isEmpty);
    expect(container.read(removedItemIdsProvider), isEmpty);
  });

  test(
    'optimistic feed merge hides local item once matching remote exists',
    () {
      final localItem = _item(
        id: 'local-1',
        sourceType: SourceType.photo,
        title: 'recipe.jpg',
        summary: r'C:\cache\recipe.jpg',
        status: ProcessingStatus.pending,
      );
      final remoteItem = _item(
        id: '3d03851b-fcd3-4661-91af-7890a57626fc',
        sourceType: SourceType.photo,
        title: 'recipe.jpg',
        summary: r'C:\cache\recipe.jpg',
        status: ProcessingStatus.processing,
      );

      final merged = mergeOptimisticFeedItems(
        <SemanticItem>[remoteItem],
        <SemanticItem>[localItem],
        const <String>{},
      );

      expect(merged, <SemanticItem>[remoteItem]);
    },
  );

  test('feed never exposes more than one processing placeholder', () {
    final firstProcessing = _item(
      id: 'remote-1',
      sourceType: SourceType.photo,
      title: 'first.jpg',
      summary: 'first.jpg',
      status: ProcessingStatus.processing,
    );
    final secondProcessing = _item(
      id: 'remote-2',
      sourceType: SourceType.screenshot,
      title: 'second.jpg',
      summary: 'second.jpg',
      status: ProcessingStatus.pending,
    );
    final readyItem = _item(
      id: 'remote-3',
      sourceType: SourceType.link,
      title: 'Ready',
      summary: 'Ready item',
      status: ProcessingStatus.ready,
    ).copyWith(type: ItemType.article);

    final visibleItems = enforceSingleProcessingPlaceholder(<SemanticItem>[
      firstProcessing,
      secondProcessing,
      readyItem,
    ]);

    expect(visibleItems, <SemanticItem>[firstProcessing, readyItem]);
  });

  test(
    'optimistic feed merge also enforces a single processing placeholder',
    () {
      final optimistic = _item(
        id: 'local-1',
        sourceType: SourceType.photo,
        title: 'local.jpg',
        summary: 'local.jpg',
        status: ProcessingStatus.pending,
      );
      final remoteProcessing = _item(
        id: 'remote-1',
        sourceType: SourceType.screenshot,
        title: 'remote.jpg',
        summary: 'remote.jpg',
        status: ProcessingStatus.processing,
      );

      final merged = mergeOptimisticFeedItems(
        <SemanticItem>[remoteProcessing],
        <SemanticItem>[optimistic],
        const <String>{},
      );

      expect(merged, <SemanticItem>[optimistic]);
    },
  );
}

SemanticItem _item({
  required String id,
  required SourceType sourceType,
  required String title,
  required String summary,
  required ProcessingStatus status,
}) {
  return SemanticItem(
    id: id,
    type: ItemType.unknown,
    sourceType: sourceType,
    title: title,
    searchableSummary: summary,
    parsedContent: const <String, Object?>{},
    language: 'en',
    processingStatus: status,
    createdLabel: 'Just now',
  );
}

Session _session(String userId) {
  return Session(
    accessToken: 'token-$userId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: 'authenticated',
      createdAt: DateTime.utc(2026).toIso8601String(),
    ),
  );
}
