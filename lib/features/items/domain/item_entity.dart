import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_entity.freezed.dart';
part 'item_entity.g.dart';

@freezed
abstract class ItemEntity with _$ItemEntity {
  const factory ItemEntity({
    required String id,
    required String itemId,
    required String entity,
    required String entityType,
    required String normalizedValue,
    @Default(<String, Object?>{}) Map<String, Object?> metadata,
  }) = _ItemEntity;

  factory ItemEntity.fromJson(Map<String, Object?> json) => _$ItemEntityFromJson(json);
}
