import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
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
                    return _DismissibleFeedCard(item: item);
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
                  return _DismissibleFeedCard(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissibleFeedCard extends ConsumerWidget {
  const _DismissibleFeedCard({required this.item});

  final SemanticItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey<String>('feed-item-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref.read(semanticItemsProvider.notifier).removeItem(item),
      background: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(height: 4),
                  Text(
                    strings.deleteItem,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: SemanticItemFeedCard(item: item, onTap: () => context.go('/items/${item.id}')),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteItemTitle),
          content: Text(strings.deleteItemBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.deleteItemCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.deleteItemConfirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
