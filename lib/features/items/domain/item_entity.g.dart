// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemEntity _$ItemEntityFromJson(Map<String, dynamic> json) => _ItemEntity(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  entity: json['entity'] as String,
  entityType: json['entityType'] as String,
  normalizedValue: json['normalizedValue'] as String,
  metadata:
      json['metadata'] as Map<String, dynamic>? ?? const <String, Object?>{},
);

Map<String, dynamic> _$ItemEntityToJson(_ItemEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'entity': instance.entity,
      'entityType': instance.entityType,
      'normalizedValue': instance.normalizedValue,
      'metadata': instance.metadata,
    };
