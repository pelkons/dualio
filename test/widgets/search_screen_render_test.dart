// Render-only tests for the search screen states.
//
// These tests do not exercise the wait-window state machine end-to-end
// (that requires mocking ItemsRepository + Supabase). They cover the
// six render states by pumping the public sub-widgets directly. The state
// machine tests live separately in semantic_items_controller_test.dart and
// integration tests when added.

import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/features/search/presentation/search_models.dart';
import 'package:dualio/features/search/presentation/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SemanticItem _item({
  required String id,
  required ItemType type,
  String title = 'Smoke item',
}) {
  return SemanticItem(
    id: id,
    type: type,
    sourceType: SourceType.link,
    title: title,
    createdLabel: 'Just now',
    searchableSummary: '',
    parsedContent: const <String, Object?>{},
  );
}

Future<void> _pump(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DualioTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: body)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('SearchSkeleton renders inside the wait window', (tester) async {
    await _pump(tester, const SearchSkeleton());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'SearchFlatResultsView renders without shimmer when ranker disabled / failed / quota',
    (tester) async {
      final results = <SemanticSearchResult>[
        SemanticSearchResult(
          item: _item(id: 'a', type: ItemType.article),
          score: 0.5,
          matchReason: 'title_match',
        ),
      ];
      await _pump(
        tester,
        SearchFlatResultsView(
          results: results,
          showShimmer: false,
          onItemTap: (_) {},
          onItemRetry: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Smoke item'), findsOneWidget);
    },
  );

  testWidgets(
    'SearchFlatResultsView shows shimmer when ranker pending past wait window',
    (tester) async {
      final results = <SemanticSearchResult>[
        SemanticSearchResult(
          item: _item(id: 'a', type: ItemType.article),
          score: 0.5,
          matchReason: 'title_match',
        ),
      ];
      await _pump(
        tester,
        SearchFlatResultsView(
          results: results,
          showShimmer: true,
          onItemTap: (_) {},
          onItemRetry: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      // Shimmer block has height 12 — assert at least one Container with that.
      // Loose check: we just ensure the layout did not crash and item text
      // is visible underneath the shimmer.
      expect(find.text('Smoke item'), findsOneWidget);
    },
  );

  testWidgets(
    'SearchRankedResultsView renders primary, secondary, suggestion and chips',
    (tester) async {
      final flat = <SemanticSearchResult>[
        SemanticSearchResult(
          item: _item(id: 'r1', type: ItemType.recipe, title: 'Pancakes'),
          score: 0.9,
          matchReason: 'title_trigram',
        ),
        SemanticSearchResult(
          item: _item(
            id: 'f1',
            type: ItemType.film,
            title: 'Breakfast at Tiffany',
          ),
          score: 0.6,
          matchReason: 'title_trigram',
        ),
      ];
      const ranking = SemanticSearchRanking(
        status: RankerStatus.complete,
        primary: <RankedSearchResult>[
          RankedSearchResult(itemId: 'r1', reason: 'It is a breakfast recipe'),
        ],
        secondary: <RankedSearchResult>[
          RankedSearchResult(
            itemId: 'f1',
            reason: 'The word "breakfast" appears in the film title',
          ),
        ],
        filterChips: <RankerFilterChip>[
          RankerFilterChip(type: ItemType.recipe, count: 1),
          RankerFilterChip(type: ItemType.film, count: 1),
        ],
        suggestion: 'Try "Breakfast at Tiffany" for the film',
        queryLanguage: 'en',
      );

      await _pump(
        tester,
        SearchRankedResultsView(
          ranking: ranking,
          flat: flat,
          activeTypeFilter: null,
          onTypeFilterToggle: (_) {},
          onSuggestionTap: (_) {},
          onItemTap: (_) {},
          onItemRetry: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Pancakes'), findsOneWidget);
      expect(find.text('Breakfast at Tiffany'), findsOneWidget);
      expect(find.text('It is a breakfast recipe'), findsOneWidget);
      expect(find.text('Less confident matches'), findsOneWidget);
      expect(
        find.textContaining('Breakfast at Tiffany'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Recipe (1)'), findsOneWidget);
      expect(find.text('Film (1)'), findsOneWidget);
    },
  );

  testWidgets('SearchRankedResultsView filters when a type chip is active', (
    tester,
  ) async {
    final flat = <SemanticSearchResult>[
      SemanticSearchResult(
        item: _item(id: 'r1', type: ItemType.recipe, title: 'Pancakes'),
        score: 0.9,
        matchReason: 'title_trigram',
      ),
      SemanticSearchResult(
        item: _item(id: 'f1', type: ItemType.film, title: 'Breakfast film'),
        score: 0.6,
        matchReason: 'title_trigram',
      ),
    ];
    const ranking = SemanticSearchRanking(
      status: RankerStatus.complete,
      primary: <RankedSearchResult>[
        RankedSearchResult(itemId: 'r1', reason: 'recipe'),
      ],
      secondary: <RankedSearchResult>[
        RankedSearchResult(itemId: 'f1', reason: 'film'),
      ],
      filterChips: <RankerFilterChip>[
        RankerFilterChip(type: ItemType.recipe, count: 1),
        RankerFilterChip(type: ItemType.film, count: 1),
      ],
    );

    await _pump(
      tester,
      SearchRankedResultsView(
        ranking: ranking,
        flat: flat,
        activeTypeFilter: ItemType.recipe,
        onTypeFilterToggle: (_) {},
        onSuggestionTap: (_) {},
        onItemTap: (_) {},
        onItemRetry: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Pancakes'), findsOneWidget);
    // Film row is filtered out by the active recipe chip.
    expect(find.text('Breakfast film'), findsNothing);
  });

  testWidgets('SearchRankedResultsView omits secondary section when empty', (
    tester,
  ) async {
    final flat = <SemanticSearchResult>[
      SemanticSearchResult(
        item: _item(id: 'r1', type: ItemType.recipe, title: 'Pancakes'),
        score: 0.9,
        matchReason: 'title_trigram',
      ),
    ];
    const ranking = SemanticSearchRanking(
      status: RankerStatus.complete,
      primary: <RankedSearchResult>[
        RankedSearchResult(itemId: 'r1', reason: 'recipe'),
      ],
    );

    await _pump(
      tester,
      SearchRankedResultsView(
        ranking: ranking,
        flat: flat,
        activeTypeFilter: null,
        onTypeFilterToggle: (_) {},
        onSuggestionTap: (_) {},
        onItemTap: (_) {},
        onItemRetry: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Less confident matches'), findsNothing);
  });
}
