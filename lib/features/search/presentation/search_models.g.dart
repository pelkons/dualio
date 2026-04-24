// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SemanticSearchQuery _$SemanticSearchQueryFromJson(Map<String, dynamic> json) =>
    _SemanticSearchQuery(
      query: json['query'] as String,
      locale: json['locale'] as String,
      inferredType: $enumDecodeNullable(
        _$ItemTypeEnumMap,
        json['inferredType'],
      ),
    );

Map<String, dynamic> _$SemanticSearchQueryToJson(
  _SemanticSearchQuery instance,
) => <String, dynamic>{
  'query': instance.query,
  'locale': instance.locale,
  'inferredType': _$ItemTypeEnumMap[instance.inferredType],
};

const _$ItemTypeEnumMap = {
  ItemType.recipe: 'recipe',
  ItemType.film: 'film',
  ItemType.place: 'place',
  ItemType.article: 'article',
  ItemType.product: 'product',
  ItemType.video: 'video',
  ItemType.note: 'note',
  ItemType.unknown: 'unknown',
};

_SemanticSearchResult _$SemanticSearchResultFromJson(
  Map<String, dynamic> json,
) => _SemanticSearchResult(
  item: SemanticItem.fromJson(json['item'] as Map<String, dynamic>),
  score: (json['score'] as num).toDouble(),
  matchReason: json['matchReason'] as String,
);

Map<String, dynamic> _$SemanticSearchResultToJson(
  _SemanticSearchResult instance,
) => <String, dynamic>{
  'item': instance.item,
  'score': instance.score,
  'matchReason': instance.matchReason,
};
