// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semantic_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SemanticItem _$SemanticItemFromJson(Map<String, dynamic> json) =>
    _SemanticItem(
      id: json['id'] as String,
      type: $enumDecode(_$ItemTypeEnumMap, json['type']),
      sourceType: $enumDecode(_$SourceTypeEnumMap, json['sourceType']),
      title: json['title'] as String,
      createdLabel: json['createdLabel'] as String,
      searchableSummary: json['searchableSummary'] as String,
      parsedContent: json['parsedContent'] as Map<String, dynamic>,
      sourceUrl: json['sourceUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      language: json['language'] as String? ?? 'en',
      searchableAliases:
          (json['searchableAliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      processingStatus:
          $enumDecodeNullable(
            _$ProcessingStatusEnumMap,
            json['processingStatus'],
          ) ??
          ProcessingStatus.ready,
      clarificationQuestion: json['clarificationQuestion'] as String?,
    );

Map<String, dynamic> _$SemanticItemToJson(_SemanticItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ItemTypeEnumMap[instance.type]!,
      'sourceType': _$SourceTypeEnumMap[instance.sourceType]!,
      'title': instance.title,
      'createdLabel': instance.createdLabel,
      'searchableSummary': instance.searchableSummary,
      'parsedContent': instance.parsedContent,
      'sourceUrl': instance.sourceUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'language': instance.language,
      'searchableAliases': instance.searchableAliases,
      'processingStatus': _$ProcessingStatusEnumMap[instance.processingStatus]!,
      'clarificationQuestion': instance.clarificationQuestion,
    };

const _$ItemTypeEnumMap = {
  ItemType.recipe: 'recipe',
  ItemType.film: 'film',
  ItemType.place: 'place',
  ItemType.article: 'article',
  ItemType.product: 'product',
  ItemType.video: 'video',
  ItemType.manual: 'manual',
  ItemType.note: 'note',
  ItemType.unknown: 'unknown',
};

const _$SourceTypeEnumMap = {
  SourceType.link: 'link',
  SourceType.screenshot: 'screenshot',
  SourceType.photo: 'photo',
  SourceType.text: 'text',
};

const _$ProcessingStatusEnumMap = {
  ProcessingStatus.pending: 'pending',
  ProcessingStatus.processing: 'processing',
  ProcessingStatus.ready: 'ready',
  ProcessingStatus.needsClarification: 'needsClarification',
  ProcessingStatus.failed: 'failed',
};
