import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_cards.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final items = ref.watch(semanticItemsProvider);
    final results = _query.trim().isEmpty ? <SemanticItem>[] : _rank(items, _query);

    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 24, DualioTheme.mobileMargin, 128),
        children: <Widget>[
          Text(strings.searchTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(strings.searchBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: strings.searchInputLabel,
              hintText: strings.searchPlaceholder,
              prefixIcon: const Icon(Icons.manage_search_rounded),
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: palette.outline.withValues(alpha: 0.45)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_query.trim().isEmpty)
            _SearchHint(text: strings.searchTryExample)
          else if (results.isEmpty)
            _SearchHint(text: strings.searchNoResults)
          else ...<Widget>[
            Text(strings.searchResults, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final item in results)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      strings.semanticDebugReason,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: palette.muted),
                    ),
                  ),
                  SemanticItemFeedCard(item: item, onTap: () => context.go('/items/${item.id}')),
                ],
              ),
          ],
        ],
      ),
    );
  }

  List<SemanticItem> _rank(List<SemanticItem> items, String query) {
    final terms = query.toLowerCase().split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList(growable: false);
    final scored = <({SemanticItem item, int score})>[];

    for (final item in items) {
      final haystack = _haystack(item);
      var score = 0;
      for (final term in terms) {
        if (item.title.toLowerCase().contains(term)) {
          score += 5;
        }
        if (item.searchableAliases.any((alias) => alias.toLowerCase().contains(term))) {
          score += 4;
        }
        if (item.searchableSummary.toLowerCase().contains(term)) {
          score += 3;
        }
        if (haystack.contains(term)) {
          score += 1;
        }
      }
      if (score > 0) {
        scored.add((item: item, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((entry) => entry.item).take(20).toList(growable: false);
  }

  String _haystack(SemanticItem item) {
    return <String>[
      item.title,
      item.searchableSummary,
      ...item.searchableAliases,
      ...item.parsedContent.values.map((value) => value.toString()),
    ].join(' ').toLowerCase();
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
        border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted)),
      ),
    );
  }
}
