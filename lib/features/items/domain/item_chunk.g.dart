// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_chunk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemChunk _$ItemChunkFromJson(Map<String, dynamic> json) => _ItemChunk(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  chunkType: json['chunkType'] as String,
  content: json['content'] as String,
  metadata:
      json['metadata'] as Map<String, dynamic>? ?? const <String, Object?>{},
);

Map<String, dynamic> _$ItemChunkToJson(_ItemChunk instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'chunkType': instance.chunkType,
      'content': instance.content,
      'metadata': instance.metadata,
    };
