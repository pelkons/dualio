import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_chunk.freezed.dart';
part 'item_chunk.g.dart';

@freezed
abstract class ItemChunk with _$ItemChunk {
  const factory ItemChunk({
    required String id,
    required String itemId,
    required String chunkType,
    required String content,
    @Default(<String, Object?>{}) Map<String, Object?> metadata,
  }) = _ItemChunk;

  factory ItemChunk.fromJson(Map<String, Object?> json) => _$ItemChunkFromJson(json);
}
