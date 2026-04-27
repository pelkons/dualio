import 'dart:async';

import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_cards.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/data/items_repository.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/features/search/presentation/search_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const Duration _searchDebounce = Duration(milliseconds: 350);
const Duration _rankerWaitWindow = Duration(milliseconds: 800);
const Duration _layoutCrossFade = Duration(milliseconds: 200);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  Timer? _waitWindow;
  int _searchGeneration = 0;

  // Phase 1 state.
  bool _phase1Loading = false;
  List<SemanticSearchResult>? _phase1Results;

  // Phase 2 state.
  bool _phase2Pending = false;
  bool _waitWindowElapsed = false;
  SemanticSearchRanking? _ranking;

  // User-applied type filter (from a tappable chip).
  ItemType? _activeTypeFilter;

  @override
  void dispose() {
    _debounce?.cancel();
    _waitWindow?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final normalizedQuery = _query.trim();

    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DualioTheme.mobileMargin,
          24,
          DualioTheme.mobileMargin,
          128,
        ),
        children: <Widget>[
          Text(
            strings.searchTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.searchBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() => _query = value);
              _scheduleRemoteSearch(value, _localeCode(context));
            },
            decoration: InputDecoration(
              labelText: strings.searchInputLabel,
              hintText: strings.searchPlaceholder,
              prefixIcon: const Icon(Icons.manage_search_rounded),
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: palette.outline.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: _layoutCrossFade,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(
              key: ValueKey<String>(_currentLayoutKey(normalizedQuery)),
              child: _buildBody(context, strings, palette, normalizedQuery),
            ),
          ),
        ],
      ),
    );
  }

  String _currentLayoutKey(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return 'hint';
    }
    if (_phase1Loading) {
      return 'phase1-loading';
    }
    if (_phase1Results == null) {
      return 'idle';
    }
    if (_phase1Results!.isEmpty) {
      return 'no-results';
    }
    final ranking = _ranking;
    if (ranking != null && ranking.status == RankerStatus.complete) {
      return 'ranked';
    }
    if (_phase2Pending && !_waitWindowElapsed) {
      return 'wait-window';
    }
    return 'flat';
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations strings,
    DualioPalette palette,
    String normalizedQuery,
  ) {
    if (normalizedQuery.isEmpty) {
      return _SearchHint(text: strings.searchTryExample);
    }
    if (_phase1Loading || _phase1Results == null) {
      return const SearchSkeleton();
    }
    final phase1 = _phase1Results!;
    if (phase1.isEmpty) {
      return _SearchHint(text: strings.searchNoResults);
    }

    final ranking = _ranking;
    if (ranking != null && ranking.status == RankerStatus.complete) {
      return SearchRankedResultsView(
        ranking: ranking,
        flat: phase1,
        activeTypeFilter: _activeTypeFilter,
        onTypeFilterToggle: (type) {
          setState(() {
            _activeTypeFilter = _activeTypeFilter == type ? null : type;
          });
        },
        onSuggestionTap: (text) {
          _controller.text = text;
          _controller.selection = TextSelection.collapsed(offset: text.length);
          setState(() => _query = text);
          _scheduleRemoteSearch(text, _localeCode(context));
        },
        onItemTap: (item) => context.push('/items/${item.id}'),
        onItemRetry: (item) =>
            ref.read(semanticItemsProvider.notifier).retryProcessing(item),
      );
    }

    final showShimmer = _phase2Pending && _waitWindowElapsed;
    if (_phase2Pending && !_waitWindowElapsed) {
      // Inside the wait window: brief, intentional pause before any layout
      // shows. Skeleton keeps the screen feeling alive without painting a
      // layout we'd have to swap out a moment later.
      return const SearchSkeleton();
    }
    return SearchFlatResultsView(
      results: phase1,
      showShimmer: showShimmer,
      onItemTap: (item) => context.push('/items/${item.id}'),
      onItemRetry: (item) =>
          ref.read(semanticItemsProvider.notifier).retryProcessing(item),
    );
  }

  void _scheduleRemoteSearch(String value, String locale) {
    _debounce?.cancel();
    _waitWindow?.cancel();
    _searchGeneration++;
    final normalized = value.trim();
    final repository = ref.read(itemsRepositoryProvider);
    if (normalized.isEmpty ||
        repository == null ||
        !repository.hasSignedInUser) {
      setState(() {
        _phase1Loading = false;
        _phase1Results = null;
        _phase2Pending = false;
        _waitWindowElapsed = false;
        _ranking = null;
        _activeTypeFilter = null;
      });
      return;
    }

    _debounce = Timer(_searchDebounce, () {
      _runRemoteSearch(normalized, locale);
    });
  }

  Future<void> _runRemoteSearch(String query, String locale) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    final generation = ++_searchGeneration;
    setState(() {
      _phase1Loading = true;
      _phase2Pending = false;
      _waitWindowElapsed = false;
      _ranking = null;
      _activeTypeFilter = null;
    });
    try {
      final results = await repository.searchItems(
        query: query,
        locale: locale,
      );
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() {
        _phase1Loading = false;
        _phase1Results = results;
      });
      if (results.isNotEmpty) {
        _startRankerPhase(generation, query, locale, results);
      }
    } on Object {
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() {
        _phase1Loading = false;
        _phase1Results = const <SemanticSearchResult>[];
      });
    }
  }

  void _startRankerPhase(
    int generation,
    String query,
    String locale,
    List<SemanticSearchResult> phase1Results,
  ) {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    setState(() {
      _phase2Pending = true;
      _waitWindowElapsed = false;
      _ranking = null;
    });

    _waitWindow?.cancel();
    _waitWindow = Timer(_rankerWaitWindow, () {
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      if (_phase2Pending && _ranking == null) {
        setState(() => _waitWindowElapsed = true);
      }
    });

    final candidateIds = phase1Results
        .map((result) => result.item.id)
        .take(20)
        .toList(growable: false);
    unawaited(_runRanker(generation, query, locale, candidateIds));
  }

  Future<void> _runRanker(
    int generation,
    String query,
    String locale,
    List<String> candidateIds,
  ) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null) {
      return;
    }
    final ranking = await repository.rankSearchResults(
      query: query,
      locale: locale,
      candidateItemIds: candidateIds,
    );
    if (!mounted || generation != _searchGeneration) {
      return;
    }
    setState(() {
      _phase2Pending = false;
      _ranking = ranking;
    });
  }

  String _localeCode(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return switch (code) {
      'he' || 'ru' || 'it' || 'fr' || 'es' || 'de' => code,
      _ => 'en',
    };
  }
}

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < 3; i++) ...<Widget>[
          _ShimmerBlock(
            color: palette.card,
            height: 84,
            radius: DualioTheme.cardRadius,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class SearchRankedResultsView extends StatelessWidget {
  const SearchRankedResultsView({
    required this.ranking,
    required this.flat,
    required this.activeTypeFilter,
    required this.onTypeFilterToggle,
    required this.onSuggestionTap,
    required this.onItemTap,
    required this.onItemRetry,
    super.key,
  });

  final SemanticSearchRanking ranking;
  final List<SemanticSearchResult> flat;
  final ItemType? activeTypeFilter;
  final ValueChanged<ItemType> onTypeFilterToggle;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<SemanticItem> onItemTap;
  final ValueChanged<SemanticItem> onItemRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final strings = AppLocalizations.of(context);
    final itemsById = <String, SemanticItem>{
      for (final result in flat) result.item.id: result.item,
    };

    Widget? renderRow(RankedSearchResult ranked) {
      final item = itemsById[ranked.itemId];
      if (item == null) {
        return null;
      }
      if (activeTypeFilter != null && item.type != activeTypeFilter) {
        return null;
      }
      return _RankedRow(
        item: item,
        reason: ranked.reason,
        onTap: () => onItemTap(item),
        onRetry: () => onItemRetry(item),
      );
    }

    final primaryRows = ranking.primary
        .map(renderRow)
        .whereType<Widget>()
        .toList(growable: false);
    final secondaryRows = ranking.secondary
        .map(renderRow)
        .whereType<Widget>()
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (ranking.suggestion != null && ranking.suggestion!.trim().isNotEmpty)
          _SuggestionBar(
            text: ranking.suggestion!,
            onTap: () => onSuggestionTap(ranking.suggestion!),
          ),
        if (ranking.filterChips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final chip in ranking.filterChips)
                _TypeFilterChip(
                  type: chip.type,
                  count: chip.count,
                  selected: activeTypeFilter == chip.type,
                  onTap: () => onTypeFilterToggle(chip.type),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ] else
          const SizedBox(height: 8),
        if (primaryRows.isNotEmpty) ...<Widget>[
          Text(
            strings.searchResults,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...primaryRows,
        ],
        if (secondaryRows.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Divider(color: palette.outline.withValues(alpha: 0.45)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  strings.searchLessConfident,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: palette.muted),
                ),
              ),
              Expanded(
                child: Divider(color: palette.outline.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...secondaryRows,
        ],
      ],
    );
  }
}

class SearchFlatResultsView extends StatelessWidget {
  const SearchFlatResultsView({
    required this.results,
    required this.showShimmer,
    required this.onItemTap,
    required this.onItemRetry,
    super.key,
  });

  final List<SemanticSearchResult> results;
  final bool showShimmer;
  final ValueChanged<SemanticItem> onItemTap;
  final ValueChanged<SemanticItem> onItemRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          strings.searchResults,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final result in results)
          _FlatRow(
            item: result.item,
            showShimmer: showShimmer,
            onTap: () => onItemTap(result.item),
            onRetry: () => onItemRetry(result.item),
          ),
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.item,
    required this.reason,
    required this.onTap,
    required this.onRetry,
  });

  final SemanticItem item;
  final String reason;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (reason.trim().isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                reason,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.muted),
              ),
            ),
          ],
          SemanticItemFeedCard(item: item, onTap: onTap, onRetry: onRetry),
        ],
      ),
    );
  }
}

class _FlatRow extends StatelessWidget {
  const _FlatRow({
    required this.item,
    required this.showShimmer,
    required this.onTap,
    required this.onRetry,
  });

  final SemanticItem item;
  final bool showShimmer;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showShimmer)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: _ShimmerBlock(
                color: palette.card,
                height: 12,
                width: 160,
                radius: 4,
              ),
            ),
          SemanticItemFeedCard(item: item, onTap: onTap, onRetry: onRetry),
        ],
      ),
    );
  }
}

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
          border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: palette.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.type,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final ItemType type;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final label = _labelFor(type, AppLocalizations.of(context));
    return Material(
      color: selected ? palette.outline.withValues(alpha: 0.18) : palette.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? palette.muted
              : palette.outline.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }

  String _labelFor(ItemType type, AppLocalizations strings) {
    return switch (type) {
      ItemType.recipe => strings.recipeType,
      ItemType.film => strings.filmType,
      ItemType.place => strings.placeType,
      ItemType.article => strings.articleType,
      ItemType.product => strings.productType,
      ItemType.video => strings.videoType,
      ItemType.manual => strings.manualType,
      ItemType.note => strings.noteType,
      ItemType.unknown => strings.unknownType,
    };
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    required this.color,
    required this.height,
    this.width,
    this.radius = 12,
  });

  final Color color;
  final double height;
  final double? width;
  final double radius;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = 0.4 + 0.4 * t;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
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
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
      ),
    );
  }
}
