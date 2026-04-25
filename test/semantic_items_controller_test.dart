import 'dart:async';

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
