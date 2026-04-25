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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  int _searchGeneration = 0;
  String _remoteQuery = '';
  bool _isSearching = false;
  List<SemanticSearchResult>? _remoteResults;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final remoteItems = ref.watch(visibleSemanticItemsProvider).valueOrNull;
    final List<SemanticItem> items =
        remoteItems ?? ref.watch(semanticItemsProvider);
    final normalizedQuery = _query.trim();
    final useRemoteResults =
        normalizedQuery.isNotEmpty &&
        _remoteQuery == normalizedQuery &&
        _remoteResults != null;
    final results = normalizedQuery.isEmpty
        ? <SemanticItem>[]
        : useRemoteResults
        ? _remoteResults!.map((result) => result.item).toList(growable: false)
        : _rank(items, normalizedQuery);

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
          if (_isSearching) ...<Widget>[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 18),
          if (_query.trim().isEmpty)
            _SearchHint(text: strings.searchTryExample)
          else if (results.isEmpty)
            _SearchHint(text: strings.searchNoResults)
          else ...<Widget>[
            Text(
              strings.searchResults,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final item in results)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      useRemoteResults
                          ? _remoteMatchReason(item.id, strings)
                          : strings.semanticDebugReason,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: palette.muted),
                    ),
                  ),
                  SemanticItemFeedCard(
                    item: item,
                    onTap: () => context.push('/items/${item.id}'),
                    onRetry: () => ref
                        .read(semanticItemsProvider.notifier)
                        .retryProcessing(item),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  void _scheduleRemoteSearch(String value, String locale) {
    _debounce?.cancel();
    _searchGeneration++;
    final normalized = value.trim();
    final repository = ref.read(itemsRepositoryProvider);
    if (normalized.isEmpty ||
        repository == null ||
        !repository.hasSignedInUser) {
      setState(() {
        _remoteQuery = '';
        _remoteResults = null;
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runRemoteSearch(normalized, locale);
    });
  }

  Future<void> _runRemoteSearch(String query, String locale) async {
    final repository = ref.read(itemsRepositoryProvider);
    if (repository == null || !repository.hasSignedInUser) {
      return;
    }

    final generation = ++_searchGeneration;
    setState(() => _isSearching = true);
    try {
      final results = await repository.searchItems(
        query: query,
        locale: locale,
      );
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() {
        _remoteQuery = query;
        _remoteResults = results;
        _isSearching = false;
      });
    } on Object {
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() {
        _remoteQuery = '';
        _remoteResults = null;
        _isSearching = false;
      });
    }
  }

  String _remoteMatchReason(String itemId, AppLocalizations strings) {
    String? reason;
    for (final result in _remoteResults ?? const <SemanticSearchResult>[]) {
      if (result.item.id == itemId) {
        reason = result.matchReason.trim();
        break;
      }
    }
    return reason == null || reason.isEmpty
        ? strings.semanticDebugReason
        : reason;
  }

  String _localeCode(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return switch (code) {
      'he' || 'ru' || 'it' || 'fr' || 'es' || 'de' => code,
      _ => 'en',
    };
  }

  List<SemanticItem> _rank(List<SemanticItem> items, String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    final scored = <({SemanticItem item, int score})>[];

    for (final item in items) {
      final haystack = _haystack(item);
      var score = 0;
      for (final term in terms) {
        if (item.title.toLowerCase().contains(term)) {
          score += 5;
        }
        if (item.searchableAliases.any(
          (alias) => alias.toLowerCase().contains(term),
        )) {
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
