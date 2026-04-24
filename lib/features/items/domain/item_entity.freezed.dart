// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemEntity {

 String get id; String get itemId; String get entity; String get entityType; String get normalizedValue; Map<String, Object?> get metadata;
/// Create a copy of ItemEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemEntityCopyWith<ItemEntity> get copyWith => _$ItemEntityCopyWithImpl<ItemEntity>(this as ItemEntity, _$identity);

  /// Serializes this ItemEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.normalizedValue, normalizedValue) || other.normalizedValue == normalizedValue)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,entity,entityType,normalizedValue,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ItemEntity(id: $id, itemId: $itemId, entity: $entity, entityType: $entityType, normalizedValue: $normalizedValue, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ItemEntityCopyWith<$Res>  {
  factory $ItemEntityCopyWith(ItemEntity value, $Res Function(ItemEntity) _then) = _$ItemEntityCopyWithImpl;
@useResult
$Res call({
 String id, String itemId, String entity, String entityType, String normalizedValue, Map<String, Object?> metadata
});




}
/// @nodoc
class _$ItemEntityCopyWithImpl<$Res>
    implements $ItemEntityCopyWith<$Res> {
  _$ItemEntityCopyWithImpl(this._self, this._then);

  final ItemEntity _self;
  final $Res Function(ItemEntity) _then;

/// Create a copy of ItemEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = null,Object? entity = null,Object? entityType = null,Object? normalizedValue = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,normalizedValue: null == normalizedValue ? _self.normalizedValue : normalizedValue // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemEntity].
extension ItemEntityPatterns on ItemEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemEntity value)  $default,){
final _that = this;
switch (_that) {
case _ItemEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ItemEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String itemId,  String entity,  String entityType,  String normalizedValue,  Map<String, Object?> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemEntity() when $default != null:
return $default(_that.id,_that.itemId,_that.entity,_that.entityType,_that.normalizedValue,_that.metadata);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String itemId,  String entity,  String entityType,  String normalizedValue,  Map<String, Object?> metadata)  $default,) {final _that = this;
switch (_that) {
case _ItemEntity():
return $default(_that.id,_that.itemId,_that.entity,_that.entityType,_that.normalizedValue,_that.metadata);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String itemId,  String entity,  String entityType,  String normalizedValue,  Map<String, Object?> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ItemEntity() when $default != null:
return $default(_that.id,_that.itemId,_that.entity,_that.entityType,_that.normalizedValue,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemEntity implements ItemEntity {
  const _ItemEntity({required this.id, required this.itemId, required this.entity, required this.entityType, required this.normalizedValue, final  Map<String, Object?> metadata = const <String, Object?>{}}): _metadata = metadata;
  factory _ItemEntity.fromJson(Map<String, dynamic> json) => _$ItemEntityFromJson(json);

@override final  String id;
@override final  String itemId;
@override final  String entity;
@override final  String entityType;
@override final  String normalizedValue;
 final  Map<String, Object?> _metadata;
@override@JsonKey() Map<String, Object?> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ItemEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemEntityCopyWith<_ItemEntity> get copyWith => __$ItemEntityCopyWithImpl<_ItemEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.normalizedValue, normalizedValue) || other.normalizedValue == normalizedValue)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,entity,entityType,normalizedValue,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ItemEntity(id: $id, itemId: $itemId, entity: $entity, entityType: $entityType, normalizedValue: $normalizedValue, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ItemEntityCopyWith<$Res> implements $ItemEntityCopyWith<$Res> {
  factory _$ItemEntityCopyWith(_ItemEntity value, $Res Function(_ItemEntity) _then) = __$ItemEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String itemId, String entity, String entityType, String normalizedValue, Map<String, Object?> metadata
});




}
/// @nodoc
class __$ItemEntityCopyWithImpl<$Res>
    implements _$ItemEntityCopyWith<$Res> {
  __$ItemEntityCopyWithImpl(this._self, this._then);

  final _ItemEntity _self;
  final $Res Function(_ItemEntity) _then;

/// Create a copy of ItemEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = null,Object? entity = null,Object? entityType = null,Object? normalizedValue = null,Object? metadata = null,}) {
  return _then(_ItemEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,normalizedValue: null == normalizedValue ? _self.normalizedValue : normalizedValue // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
