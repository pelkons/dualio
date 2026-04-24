// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_chunk.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemChunk {

 String get id; String get itemId; String get chunkType; String get content; Map<String, Object?> get metadata;
/// Create a copy of ItemChunk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemChunkCopyWith<ItemChunk> get copyWith => _$ItemChunkCopyWithImpl<ItemChunk>(this as ItemChunk, _$identity);

  /// Serializes this ItemChunk to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemChunk&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.chunkType, chunkType) || other.chunkType == chunkType)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,chunkType,content,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ItemChunk(id: $id, itemId: $itemId, chunkType: $chunkType, content: $content, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ItemChunkCopyWith<$Res>  {
  factory $ItemChunkCopyWith(ItemChunk value, $Res Function(ItemChunk) _then) = _$ItemChunkCopyWithImpl;
@useResult
$Res call({
 String id, String itemId, String chunkType, String content, Map<String, Object?> metadata
});




}
/// @nodoc
class _$ItemChunkCopyWithImpl<$Res>
    implements $ItemChunkCopyWith<$Res> {
  _$ItemChunkCopyWithImpl(this._self, this._then);

  final ItemChunk _self;
  final $Res Function(ItemChunk) _then;

/// Create a copy of ItemChunk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = null,Object? chunkType = null,Object? content = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,chunkType: null == chunkType ? _self.chunkType : chunkType // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemChunk].
extension ItemChunkPatterns on ItemChunk {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemChunk value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemChunk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemChunk value)  $default,){
final _that = this;
switch (_that) {
case _ItemChunk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemChunk value)?  $default,){
final _that = this;
switch (_that) {
case _ItemChunk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String itemId,  String chunkType,  String content,  Map<String, Object?> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemChunk() when $default != null:
return $default(_that.id,_that.itemId,_that.chunkType,_that.content,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String itemId,  String chunkType,  String content,  Map<String, Object?> metadata)  $default,) {final _that = this;
switch (_that) {
case _ItemChunk():
return $default(_that.id,_that.itemId,_that.chunkType,_that.content,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String itemId,  String chunkType,  String content,  Map<String, Object?> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ItemChunk() when $default != null:
return $default(_that.id,_that.itemId,_that.chunkType,_that.content,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemChunk implements ItemChunk {
  const _ItemChunk({required this.id, required this.itemId, required this.chunkType, required this.content, final  Map<String, Object?> metadata = const <String, Object?>{}}): _metadata = metadata;
  factory _ItemChunk.fromJson(Map<String, dynamic> json) => _$ItemChunkFromJson(json);

@override final  String id;
@override final  String itemId;
@override final  String chunkType;
@override final  String content;
 final  Map<String, Object?> _metadata;
@override@JsonKey() Map<String, Object?> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ItemChunk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemChunkCopyWith<_ItemChunk> get copyWith => __$ItemChunkCopyWithImpl<_ItemChunk>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemChunkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemChunk&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.chunkType, chunkType) || other.chunkType == chunkType)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,chunkType,content,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ItemChunk(id: $id, itemId: $itemId, chunkType: $chunkType, content: $content, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ItemChunkCopyWith<$Res> implements $ItemChunkCopyWith<$Res> {
  factory _$ItemChunkCopyWith(_ItemChunk value, $Res Function(_ItemChunk) _then) = __$ItemChunkCopyWithImpl;
@override @useResult
$Res call({
 String id, String itemId, String chunkType, String content, Map<String, Object?> metadata
});




}
/// @nodoc
class __$ItemChunkCopyWithImpl<$Res>
    implements _$ItemChunkCopyWith<$Res> {
  __$ItemChunkCopyWithImpl(this._self, this._then);

  final _ItemChunk _self;
  final $Res Function(_ItemChunk) _then;

/// Create a copy of ItemChunk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = null,Object? chunkType = null,Object? content = null,Object? metadata = null,}) {
  return _then(_ItemChunk(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,chunkType: null == chunkType ? _self.chunkType : chunkType // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
