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

  factory SemanticSearchQuery.fromJson(Map<String, Object?> json) => _$SemanticSearchQueryFromJson(json);
}

@freezed
abstract class SemanticSearchResult with _$SemanticSearchResult {
  const factory SemanticSearchResult({
    required SemanticItem item,
    required double score,
    required String matchReason,
  }) = _SemanticSearchResult;

  factory SemanticSearchResult.fromJson(Map<String, Object?> json) => _$SemanticSearchResultFromJson(json);
}
