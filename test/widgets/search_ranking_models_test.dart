// Wire-format parsing tests for the search-rank Edge Function response.
//
// The backend sends snake_case keys (`ranker_status`, `filter_chips`,
// `quota_exceeded`); the Flutter models live in camelCase. These tests lock
// in the translation so a backend rename surfaces immediately.

import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/features/search/presentation/search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticSearchRanking.fromWire', () {
    test('parses a complete ranker response', () {
      final wire = <String, Object?>{
        'ranker_status': 'complete',
        'queryLanguage': 'ru',
        'primary': <Map<String, Object?>>[
          {'itemId': 'a', 'reason': 'Это рецепт.'},
        ],
        'secondary': <Map<String, Object?>>[
          {'itemId': 'b', 'reason': 'Совпадение в названии.'},
        ],
        'filter_chips': <Map<String, Object?>>[
          {'type': 'recipe', 'count': 1},
          {'type': 'film', 'count': 1},
        ],
        'suggestion': 'попробуйте «завтрак у тиффани»',
      };

      final ranking = SemanticSearchRanking.fromWire(wire);

      expect(ranking.status, RankerStatus.complete);
      expect(ranking.queryLanguage, 'ru');
      expect(ranking.primary, hasLength(1));
      expect(ranking.primary.single.itemId, 'a');
      expect(ranking.primary.single.reason, 'Это рецепт.');
      expect(ranking.secondary, hasLength(1));
      expect(ranking.secondary.single.itemId, 'b');
      expect(ranking.filterChips, hasLength(2));
      expect(ranking.filterChips.first.type, ItemType.recipe);
      expect(ranking.filterChips.first.count, 1);
      expect(ranking.suggestion, 'попробуйте «завтрак у тиффани»');
    });

    test('maps "quota_exceeded" status', () {
      final ranking = SemanticSearchRanking.fromWire(<String, Object?>{
        'ranker_status': 'quota_exceeded',
      });
      expect(ranking.status, RankerStatus.quotaExceeded);
      expect(ranking.primary, isEmpty);
      expect(ranking.secondary, isEmpty);
      expect(ranking.filterChips, isEmpty);
    });

    test('falls back to failed for unknown status', () {
      final ranking = SemanticSearchRanking.fromWire(<String, Object?>{
        'ranker_status': 'something_new',
      });
      expect(ranking.status, RankerStatus.failed);
    });

    test('accepts snake_case item_id in ranked results', () {
      final ranking = SemanticSearchRanking.fromWire(<String, Object?>{
        'ranker_status': 'complete',
        'primary': <Map<String, Object?>>[
          {'item_id': 'snake', 'reason': 'snake-case wins'},
        ],
      });
      expect(ranking.primary.single.itemId, 'snake');
    });

    test('coerces unknown filter chip type to ItemType.unknown', () {
      final ranking = SemanticSearchRanking.fromWire(<String, Object?>{
        'ranker_status': 'complete',
        'filter_chips': <Map<String, Object?>>[
          {'type': 'mystery', 'count': 3},
        ],
      });
      expect(ranking.filterChips.single.type, ItemType.unknown);
      expect(ranking.filterChips.single.count, 3);
    });

    test('treats missing arrays as empty', () {
      final ranking = SemanticSearchRanking.fromWire(<String, Object?>{
        'ranker_status': 'complete',
      });
      expect(ranking.primary, isEmpty);
      expect(ranking.secondary, isEmpty);
      expect(ranking.filterChips, isEmpty);
      expect(ranking.suggestion, isNull);
    });
  });

  group('SemanticSearchRanking helpers', () {
    test('disabled() yields RankerStatus.disabled with empty fields', () {
      final ranking = SemanticSearchRanking.disabled();
      expect(ranking.status, RankerStatus.disabled);
      expect(ranking.primary, isEmpty);
    });

    test('failed() yields RankerStatus.failed with empty fields', () {
      final ranking = SemanticSearchRanking.failed();
      expect(ranking.status, RankerStatus.failed);
      expect(ranking.secondary, isEmpty);
    });

    test('quotaExceeded() yields RankerStatus.quotaExceeded', () {
      final ranking = SemanticSearchRanking.quotaExceeded();
      expect(ranking.status, RankerStatus.quotaExceeded);
      expect(ranking.filterChips, isEmpty);
    });
  });
}
