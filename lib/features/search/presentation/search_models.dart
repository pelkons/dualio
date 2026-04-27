import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_models.freezed.dart';
part 'search_models.g.dart';

@freezed
abstract class SemanticSearchQuery with _$SemanticSearchQuery {
  const factory SemanticSearchQuery({
    required String query,
    required String locale,
    ItemType? inferredType,
  }) = _SemanticSearchQuery;

  factory SemanticSearchQuery.fromJson(Map<String, Object?> json) =>
      _$SemanticSearchQueryFromJson(json);
}

@freezed
abstract class SemanticSearchResult with _$SemanticSearchResult {
  const factory SemanticSearchResult({
    required SemanticItem item,
    required double score,
    required String matchReason,
  }) = _SemanticSearchResult;

  factory SemanticSearchResult.fromJson(Map<String, Object?> json) =>
      _$SemanticSearchResultFromJson(json);
}

enum RankerStatus { complete, failed, disabled, quotaExceeded }

RankerStatus _rankerStatusFromWire(String? value) {
  switch (value) {
    case 'complete':
      return RankerStatus.complete;
    case 'quota_exceeded':
      return RankerStatus.quotaExceeded;
    case 'disabled':
      return RankerStatus.disabled;
    case 'failed':
    default:
      return RankerStatus.failed;
  }
}

ItemType _itemTypeFromWire(String? value) {
  for (final type in ItemType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return ItemType.unknown;
}

@freezed
abstract class RankedSearchResult with _$RankedSearchResult {
  const factory RankedSearchResult({
    required String itemId,
    required String reason,
  }) = _RankedSearchResult;

  factory RankedSearchResult.fromWire(Map<String, Object?> json) {
    return RankedSearchResult(
      itemId: (json['itemId'] as String?) ?? (json['item_id'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
    );
  }
}

@freezed
abstract class RankerFilterChip with _$RankerFilterChip {
  const factory RankerFilterChip({required ItemType type, required int count}) =
      _RankerFilterChip;

  factory RankerFilterChip.fromWire(Map<String, Object?> json) {
    return RankerFilterChip(
      type: _itemTypeFromWire(json['type'] as String?),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

@freezed
abstract class SemanticSearchRanking with _$SemanticSearchRanking {
  const factory SemanticSearchRanking({
    required RankerStatus status,
    @Default(<RankedSearchResult>[]) List<RankedSearchResult> primary,
    @Default(<RankedSearchResult>[]) List<RankedSearchResult> secondary,
    @Default(<RankerFilterChip>[]) List<RankerFilterChip> filterChips,
    String? suggestion,
    String? queryLanguage,
  }) = _SemanticSearchRanking;

  factory SemanticSearchRanking.fromWire(Map<String, Object?> json) {
    final status = _rankerStatusFromWire(json['ranker_status'] as String?);
    final primaryRaw = json['primary'];
    final secondaryRaw = json['secondary'];
    final chipsRaw = json['filter_chips'];

    return SemanticSearchRanking(
      status: status,
      primary: primaryRaw is List
          ? primaryRaw
                .whereType<Map<Object?, Object?>>()
                .map(
                  (entry) => RankedSearchResult.fromWire(
                    Map<String, Object?>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const <RankedSearchResult>[],
      secondary: secondaryRaw is List
          ? secondaryRaw
                .whereType<Map<Object?, Object?>>()
                .map(
                  (entry) => RankedSearchResult.fromWire(
                    Map<String, Object?>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const <RankedSearchResult>[],
      filterChips: chipsRaw is List
          ? chipsRaw
                .whereType<Map<Object?, Object?>>()
                .map(
                  (entry) => RankerFilterChip.fromWire(
                    Map<String, Object?>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const <RankerFilterChip>[],
      suggestion: json['suggestion'] as String?,
      queryLanguage: json['queryLanguage'] as String?,
    );
  }

  factory SemanticSearchRanking.disabled() =>
      const SemanticSearchRanking(status: RankerStatus.disabled);

  factory SemanticSearchRanking.failed() =>
      const SemanticSearchRanking(status: RankerStatus.failed);

  factory SemanticSearchRanking.quotaExceeded() =>
      const SemanticSearchRanking(status: RankerStatus.quotaExceeded);
}
