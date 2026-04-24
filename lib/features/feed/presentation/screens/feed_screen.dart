import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/feed/presentation/widgets/dualio_search_bar.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_cards.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(visibleSemanticItemsProvider);

    return FeedShell(
      child: itemsState.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(visibleSemanticItemsProvider),
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(child: DualioSearchBar()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 6, DualioTheme.mobileMargin, 108),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SemanticItemFeedCard(item: item, onTap: () => context.go('/items/${item.id}'));
                  },
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: DualioSearchBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 6, DualioTheme.mobileMargin, 108),
              sliver: SliverList.builder(
                itemCount: ref.watch(semanticItemsProvider).length,
                itemBuilder: (context, index) {
                  final item = ref.watch(semanticItemsProvider)[index];
                  return SemanticItemFeedCard(item: item, onTap: () => context.go('/items/${item.id}'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
