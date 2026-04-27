// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SemanticSearchQuery {

 String get query; String get locale; ItemType? get inferredType;
/// Create a copy of SemanticSearchQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SemanticSearchQueryCopyWith<SemanticSearchQuery> get copyWith => _$SemanticSearchQueryCopyWithImpl<SemanticSearchQuery>(this as SemanticSearchQuery, _$identity);

  /// Serializes this SemanticSearchQuery to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SemanticSearchQuery&&(identical(other.query, query) || other.query == query)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.inferredType, inferredType) || other.inferredType == inferredType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,locale,inferredType);

@override
String toString() {
  return 'SemanticSearchQuery(query: $query, locale: $locale, inferredType: $inferredType)';
}


}

/// @nodoc
abstract mixin class $SemanticSearchQueryCopyWith<$Res>  {
  factory $SemanticSearchQueryCopyWith(SemanticSearchQuery value, $Res Function(SemanticSearchQuery) _then) = _$SemanticSearchQueryCopyWithImpl;
@useResult
$Res call({
 String query, String locale, ItemType? inferredType
});




}
/// @nodoc
class _$SemanticSearchQueryCopyWithImpl<$Res>
    implements $SemanticSearchQueryCopyWith<$Res> {
  _$SemanticSearchQueryCopyWithImpl(this._self, this._then);

  final SemanticSearchQuery _self;
  final $Res Function(SemanticSearchQuery) _then;

/// Create a copy of SemanticSearchQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? locale = null,Object? inferredType = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,inferredType: freezed == inferredType ? _self.inferredType : inferredType // ignore: cast_nullable_to_non_nullable
as ItemType?,
  ));
}

}


/// Adds pattern-matching-related methods to [SemanticSearchQuery].
extension SemanticSearchQueryPatterns on SemanticSearchQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SemanticSearchQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SemanticSearchQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SemanticSearchQuery value)  $default,){
final _that = this;
switch (_that) {
case _SemanticSearchQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SemanticSearchQuery value)?  $default,){
final _that = this;
switch (_that) {
case _SemanticSearchQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  String locale,  ItemType? inferredType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SemanticSearchQuery() when $default != null:
return $default(_that.query,_that.locale,_that.inferredType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  String locale,  ItemType? inferredType)  $default,) {final _that = this;
switch (_that) {
case _SemanticSearchQuery():
return $default(_that.query,_that.locale,_that.inferredType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  String locale,  ItemType? inferredType)?  $default,) {final _that = this;
switch (_that) {
case _SemanticSearchQuery() when $default != null:
return $default(_that.query,_that.locale,_that.inferredType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SemanticSearchQuery implements SemanticSearchQuery {
  const _SemanticSearchQuery({required this.query, required this.locale, this.inferredType});
  factory _SemanticSearchQuery.fromJson(Map<String, dynamic> json) => _$SemanticSearchQueryFromJson(json);

@override final  String query;
@override final  String locale;
@override final  ItemType? inferredType;

/// Create a copy of SemanticSearchQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SemanticSearchQueryCopyWith<_SemanticSearchQuery> get copyWith => __$SemanticSearchQueryCopyWithImpl<_SemanticSearchQuery>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SemanticSearchQueryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SemanticSearchQuery&&(identical(other.query, query) || other.query == query)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.inferredType, inferredType) || other.inferredType == inferredType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,locale,inferredType);

@override
String toString() {
  return 'SemanticSearchQuery(query: $query, locale: $locale, inferredType: $inferredType)';
}


}

/// @nodoc
abstract mixin class _$SemanticSearchQueryCopyWith<$Res> implements $SemanticSearchQueryCopyWith<$Res> {
  factory _$SemanticSearchQueryCopyWith(_SemanticSearchQuery value, $Res Function(_SemanticSearchQuery) _then) = __$SemanticSearchQueryCopyWithImpl;
@override @useResult
$Res call({
 String query, String locale, ItemType? inferredType
});




}
/// @nodoc
class __$SemanticSearchQueryCopyWithImpl<$Res>
    implements _$SemanticSearchQueryCopyWith<$Res> {
  __$SemanticSearchQueryCopyWithImpl(this._self, this._then);

  final _SemanticSearchQuery _self;
  final $Res Function(_SemanticSearchQuery) _then;

/// Create a copy of SemanticSearchQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? locale = null,Object? inferredType = freezed,}) {
  return _then(_SemanticSearchQuery(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,inferredType: freezed == inferredType ? _self.inferredType : inferredType // ignore: cast_nullable_to_non_nullable
as ItemType?,
  ));
}


}


/// @nodoc
mixin _$SemanticSearchResult {

 SemanticItem get item; double get score; String get matchReason;
/// Create a copy of SemanticSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SemanticSearchResultCopyWith<SemanticSearchResult> get copyWith => _$SemanticSearchResultCopyWithImpl<SemanticSearchResult>(this as SemanticSearchResult, _$identity);

  /// Serializes this SemanticSearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SemanticSearchResult&&(identical(other.item, item) || other.item == item)&&(identical(other.score, score) || other.score == score)&&(identical(other.matchReason, matchReason) || other.matchReason == matchReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,item,score,matchReason);

@override
String toString() {
  return 'SemanticSearchResult(item: $item, score: $score, matchReason: $matchReason)';
}


}

/// @nodoc
abstract mixin class $SemanticSearchResultCopyWith<$Res>  {
  factory $SemanticSearchResultCopyWith(SemanticSearchResult value, $Res Function(SemanticSearchResult) _then) = _$SemanticSearchResultCopyWithImpl;
@useResult
$Res call({
 SemanticItem item, double score, String matchReason
});


$SemanticItemCopyWith<$Res> get item;

}
/// @nodoc
class _$SemanticSearchResultCopyWithImpl<$Res>
    implements $SemanticSearchResultCopyWith<$Res> {
  _$SemanticSearchResultCopyWithImpl(this._self, this._then);

  final SemanticSearchResult _self;
  final $Res Function(SemanticSearchResult) _then;

/// Create a copy of SemanticSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? score = null,Object? matchReason = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as SemanticItem,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,matchReason: null == matchReason ? _self.matchReason : matchReason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SemanticSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SemanticItemCopyWith<$Res> get item {
  
  return $SemanticItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// Adds pattern-matching-related methods to [SemanticSearchResult].
extension SemanticSearchResultPatterns on SemanticSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SemanticSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SemanticSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SemanticSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SemanticSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SemanticSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SemanticSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SemanticItem item,  double score,  String matchReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SemanticSearchResult() when $default != null:
return $default(_that.item,_that.score,_that.matchReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SemanticItem item,  double score,  String matchReason)  $default,) {final _that = this;
switch (_that) {
case _SemanticSearchResult():
return $default(_that.item,_that.score,_that.matchReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SemanticItem item,  double score,  String matchReason)?  $default,) {final _that = this;
switch (_that) {
case _SemanticSearchResult() when $default != null:
return $default(_that.item,_that.score,_that.matchReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SemanticSearchResult implements SemanticSearchResult {
  const _SemanticSearchResult({required this.item, required this.score, required this.matchReason});
  factory _SemanticSearchResult.fromJson(Map<String, dynamic> json) => _$SemanticSearchResultFromJson(json);

@override final  SemanticItem item;
@override final  double score;
@override final  String matchReason;

/// Create a copy of SemanticSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SemanticSearchResultCopyWith<_SemanticSearchResult> get copyWith => __$SemanticSearchResultCopyWithImpl<_SemanticSearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SemanticSearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SemanticSearchResult&&(identical(other.item, item) || other.item == item)&&(identical(other.score, score) || other.score == score)&&(identical(other.matchReason, matchReason) || other.matchReason == matchReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,item,score,matchReason);

@override
String toString() {
  return 'SemanticSearchResult(item: $item, score: $score, matchReason: $matchReason)';
}


}

/// @nodoc
abstract mixin class _$SemanticSearchResultCopyWith<$Res> implements $SemanticSearchResultCopyWith<$Res> {
  factory _$SemanticSearchResultCopyWith(_SemanticSearchResult value, $Res Function(_SemanticSearchResult) _then) = __$SemanticSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SemanticItem item, double score, String matchReason
});


@override $SemanticItemCopyWith<$Res> get item;

}
/// @nodoc
class __$SemanticSearchResultCopyWithImpl<$Res>
    implements _$SemanticSearchResultCopyWith<$Res> {
  __$SemanticSearchResultCopyWithImpl(this._self, this._then);

  final _SemanticSearchResult _self;
  final $Res Function(_SemanticSearchResult) _then;

/// Create a copy of SemanticSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? score = null,Object? matchReason = null,}) {
  return _then(_SemanticSearchResult(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as SemanticItem,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,matchReason: null == matchReason ? _self.matchReason : matchReason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SemanticSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SemanticItemCopyWith<$Res> get item {
  
  return $SemanticItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

/// @nodoc
mixin _$RankedSearchResult {

 String get itemId; String get reason;
/// Create a copy of RankedSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankedSearchResultCopyWith<RankedSearchResult> get copyWith => _$RankedSearchResultCopyWithImpl<RankedSearchResult>(this as RankedSearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankedSearchResult&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,reason);

@override
String toString() {
  return 'RankedSearchResult(itemId: $itemId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RankedSearchResultCopyWith<$Res>  {
  factory $RankedSearchResultCopyWith(RankedSearchResult value, $Res Function(RankedSearchResult) _then) = _$RankedSearchResultCopyWithImpl;
@useResult
$Res call({
 String itemId, String reason
});




}
/// @nodoc
class _$RankedSearchResultCopyWithImpl<$Res>
    implements $RankedSearchResultCopyWith<$Res> {
  _$RankedSearchResultCopyWithImpl(this._self, this._then);

  final RankedSearchResult _self;
  final $Res Function(RankedSearchResult) _then;

/// Create a copy of RankedSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? reason = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RankedSearchResult].
extension RankedSearchResultPatterns on RankedSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankedSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankedSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankedSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _RankedSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankedSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _RankedSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankedSearchResult() when $default != null:
return $default(_that.itemId,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String reason)  $default,) {final _that = this;
switch (_that) {
case _RankedSearchResult():
return $default(_that.itemId,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _RankedSearchResult() when $default != null:
return $default(_that.itemId,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _RankedSearchResult implements RankedSearchResult {
  const _RankedSearchResult({required this.itemId, required this.reason});


@override final  String itemId;
@override final  String reason;

/// Create a copy of RankedSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankedSearchResultCopyWith<_RankedSearchResult> get copyWith => __$RankedSearchResultCopyWithImpl<_RankedSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankedSearchResult&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,reason);

@override
String toString() {
  return 'RankedSearchResult(itemId: $itemId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$RankedSearchResultCopyWith<$Res> implements $RankedSearchResultCopyWith<$Res> {
  factory _$RankedSearchResultCopyWith(_RankedSearchResult value, $Res Function(_RankedSearchResult) _then) = __$RankedSearchResultCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String reason
});




}
/// @nodoc
class __$RankedSearchResultCopyWithImpl<$Res>
    implements _$RankedSearchResultCopyWith<$Res> {
  __$RankedSearchResultCopyWithImpl(this._self, this._then);

  final _RankedSearchResult _self;
  final $Res Function(_RankedSearchResult) _then;

/// Create a copy of RankedSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? reason = null,}) {
  return _then(_RankedSearchResult(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RankerFilterChip {

 ItemType get type; int get count;
/// Create a copy of RankerFilterChip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankerFilterChipCopyWith<RankerFilterChip> get copyWith => _$RankerFilterChipCopyWithImpl<RankerFilterChip>(this as RankerFilterChip, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankerFilterChip&&(identical(other.type, type) || other.type == type)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,type,count);

@override
String toString() {
  return 'RankerFilterChip(type: $type, count: $count)';
}


}

/// @nodoc
abstract mixin class $RankerFilterChipCopyWith<$Res>  {
  factory $RankerFilterChipCopyWith(RankerFilterChip value, $Res Function(RankerFilterChip) _then) = _$RankerFilterChipCopyWithImpl;
@useResult
$Res call({
 ItemType type, int count
});




}
/// @nodoc
class _$RankerFilterChipCopyWithImpl<$Res>
    implements $RankerFilterChipCopyWith<$Res> {
  _$RankerFilterChipCopyWithImpl(this._self, this._then);

  final RankerFilterChip _self;
  final $Res Function(RankerFilterChip) _then;

/// Create a copy of RankerFilterChip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? count = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ItemType,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RankerFilterChip].
extension RankerFilterChipPatterns on RankerFilterChip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankerFilterChip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankerFilterChip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankerFilterChip value)  $default,){
final _that = this;
switch (_that) {
case _RankerFilterChip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankerFilterChip value)?  $default,){
final _that = this;
switch (_that) {
case _RankerFilterChip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ItemType type,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankerFilterChip() when $default != null:
return $default(_that.type,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ItemType type,  int count)  $default,) {final _that = this;
switch (_that) {
case _RankerFilterChip():
return $default(_that.type,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ItemType type,  int count)?  $default,) {final _that = this;
switch (_that) {
case _RankerFilterChip() when $default != null:
return $default(_that.type,_that.count);case _:
  return null;

}
}

}

/// @nodoc


class _RankerFilterChip implements RankerFilterChip {
  const _RankerFilterChip({required this.type, required this.count});


@override final  ItemType type;
@override final  int count;

/// Create a copy of RankerFilterChip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankerFilterChipCopyWith<_RankerFilterChip> get copyWith => __$RankerFilterChipCopyWithImpl<_RankerFilterChip>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankerFilterChip&&(identical(other.type, type) || other.type == type)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,type,count);

@override
String toString() {
  return 'RankerFilterChip(type: $type, count: $count)';
}


}

/// @nodoc
abstract mixin class _$RankerFilterChipCopyWith<$Res> implements $RankerFilterChipCopyWith<$Res> {
  factory _$RankerFilterChipCopyWith(_RankerFilterChip value, $Res Function(_RankerFilterChip) _then) = __$RankerFilterChipCopyWithImpl;
@override @useResult
$Res call({
 ItemType type, int count
});




}
/// @nodoc
class __$RankerFilterChipCopyWithImpl<$Res>
    implements _$RankerFilterChipCopyWith<$Res> {
  __$RankerFilterChipCopyWithImpl(this._self, this._then);

  final _RankerFilterChip _self;
  final $Res Function(_RankerFilterChip) _then;

/// Create a copy of RankerFilterChip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? count = null,}) {
  return _then(_RankerFilterChip(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ItemType,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$SemanticSearchRanking {

 RankerStatus get status; List<RankedSearchResult> get primary; List<RankedSearchResult> get secondary; List<RankerFilterChip> get filterChips; String? get suggestion; String? get queryLanguage;
/// Create a copy of SemanticSearchRanking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SemanticSearchRankingCopyWith<SemanticSearchRanking> get copyWith => _$SemanticSearchRankingCopyWithImpl<SemanticSearchRanking>(this as SemanticSearchRanking, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SemanticSearchRanking&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.primary, primary)&&const DeepCollectionEquality().equals(other.secondary, secondary)&&const DeepCollectionEquality().equals(other.filterChips, filterChips)&&(identical(other.suggestion, suggestion) || other.suggestion == suggestion)&&(identical(other.queryLanguage, queryLanguage) || other.queryLanguage == queryLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(primary),const DeepCollectionEquality().hash(secondary),const DeepCollectionEquality().hash(filterChips),suggestion,queryLanguage);

@override
String toString() {
  return 'SemanticSearchRanking(status: $status, primary: $primary, secondary: $secondary, filterChips: $filterChips, suggestion: $suggestion, queryLanguage: $queryLanguage)';
}


}

/// @nodoc
abstract mixin class $SemanticSearchRankingCopyWith<$Res>  {
  factory $SemanticSearchRankingCopyWith(SemanticSearchRanking value, $Res Function(SemanticSearchRanking) _then) = _$SemanticSearchRankingCopyWithImpl;
@useResult
$Res call({
 RankerStatus status, List<RankedSearchResult> primary, List<RankedSearchResult> secondary, List<RankerFilterChip> filterChips, String? suggestion, String? queryLanguage
});




}
/// @nodoc
class _$SemanticSearchRankingCopyWithImpl<$Res>
    implements $SemanticSearchRankingCopyWith<$Res> {
  _$SemanticSearchRankingCopyWithImpl(this._self, this._then);

  final SemanticSearchRanking _self;
  final $Res Function(SemanticSearchRanking) _then;

/// Create a copy of SemanticSearchRanking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? primary = null,Object? secondary = null,Object? filterChips = null,Object? suggestion = freezed,Object? queryLanguage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RankerStatus,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as List<RankedSearchResult>,secondary: null == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as List<RankedSearchResult>,filterChips: null == filterChips ? _self.filterChips : filterChips // ignore: cast_nullable_to_non_nullable
as List<RankerFilterChip>,suggestion: freezed == suggestion ? _self.suggestion : suggestion // ignore: cast_nullable_to_non_nullable
as String?,queryLanguage: freezed == queryLanguage ? _self.queryLanguage : queryLanguage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SemanticSearchRanking].
extension SemanticSearchRankingPatterns on SemanticSearchRanking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SemanticSearchRanking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SemanticSearchRanking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SemanticSearchRanking value)  $default,){
final _that = this;
switch (_that) {
case _SemanticSearchRanking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SemanticSearchRanking value)?  $default,){
final _that = this;
switch (_that) {
case _SemanticSearchRanking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RankerStatus status,  List<RankedSearchResult> primary,  List<RankedSearchResult> secondary,  List<RankerFilterChip> filterChips,  String? suggestion,  String? queryLanguage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SemanticSearchRanking() when $default != null:
return $default(_that.status,_that.primary,_that.secondary,_that.filterChips,_that.suggestion,_that.queryLanguage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RankerStatus status,  List<RankedSearchResult> primary,  List<RankedSearchResult> secondary,  List<RankerFilterChip> filterChips,  String? suggestion,  String? queryLanguage)  $default,) {final _that = this;
switch (_that) {
case _SemanticSearchRanking():
return $default(_that.status,_that.primary,_that.secondary,_that.filterChips,_that.suggestion,_that.queryLanguage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RankerStatus status,  List<RankedSearchResult> primary,  List<RankedSearchResult> secondary,  List<RankerFilterChip> filterChips,  String? suggestion,  String? queryLanguage)?  $default,) {final _that = this;
switch (_that) {
case _SemanticSearchRanking() when $default != null:
return $default(_that.status,_that.primary,_that.secondary,_that.filterChips,_that.suggestion,_that.queryLanguage);case _:
  return null;

}
}

}

/// @nodoc


class _SemanticSearchRanking implements SemanticSearchRanking {
  const _SemanticSearchRanking({required this.status, final  List<RankedSearchResult> primary = const <RankedSearchResult>[], final  List<RankedSearchResult> secondary = const <RankedSearchResult>[], final  List<RankerFilterChip> filterChips = const <RankerFilterChip>[], this.suggestion, this.queryLanguage}): _primary = primary,_secondary = secondary,_filterChips = filterChips;


@override final  RankerStatus status;
 final  List<RankedSearchResult> _primary;
@override@JsonKey() List<RankedSearchResult> get primary {
  if (_primary is EqualUnmodifiableListView) return _primary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_primary);
}

 final  List<RankedSearchResult> _secondary;
@override@JsonKey() List<RankedSearchResult> get secondary {
  if (_secondary is EqualUnmodifiableListView) return _secondary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondary);
}

 final  List<RankerFilterChip> _filterChips;
@override@JsonKey() List<RankerFilterChip> get filterChips {
  if (_filterChips is EqualUnmodifiableListView) return _filterChips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filterChips);
}

@override final  String? suggestion;
@override final  String? queryLanguage;

/// Create a copy of SemanticSearchRanking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SemanticSearchRankingCopyWith<_SemanticSearchRanking> get copyWith => __$SemanticSearchRankingCopyWithImpl<_SemanticSearchRanking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SemanticSearchRanking&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._primary, _primary)&&const DeepCollectionEquality().equals(other._secondary, _secondary)&&const DeepCollectionEquality().equals(other._filterChips, _filterChips)&&(identical(other.suggestion, suggestion) || other.suggestion == suggestion)&&(identical(other.queryLanguage, queryLanguage) || other.queryLanguage == queryLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_primary),const DeepCollectionEquality().hash(_secondary),const DeepCollectionEquality().hash(_filterChips),suggestion,queryLanguage);

@override
String toString() {
  return 'SemanticSearchRanking(status: $status, primary: $primary, secondary: $secondary, filterChips: $filterChips, suggestion: $suggestion, queryLanguage: $queryLanguage)';
}


}

/// @nodoc
abstract mixin class _$SemanticSearchRankingCopyWith<$Res> implements $SemanticSearchRankingCopyWith<$Res> {
  factory _$SemanticSearchRankingCopyWith(_SemanticSearchRanking value, $Res Function(_SemanticSearchRanking) _then) = __$SemanticSearchRankingCopyWithImpl;
@override @useResult
$Res call({
 RankerStatus status, List<RankedSearchResult> primary, List<RankedSearchResult> secondary, List<RankerFilterChip> filterChips, String? suggestion, String? queryLanguage
});




}
/// @nodoc
class __$SemanticSearchRankingCopyWithImpl<$Res>
    implements _$SemanticSearchRankingCopyWith<$Res> {
  __$SemanticSearchRankingCopyWithImpl(this._self, this._then);

  final _SemanticSearchRanking _self;
  final $Res Function(_SemanticSearchRanking) _then;

/// Create a copy of SemanticSearchRanking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? primary = null,Object? secondary = null,Object? filterChips = null,Object? suggestion = freezed,Object? queryLanguage = freezed,}) {
  return _then(_SemanticSearchRanking(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RankerStatus,primary: null == primary ? _self._primary : primary // ignore: cast_nullable_to_non_nullable
as List<RankedSearchResult>,secondary: null == secondary ? _self._secondary : secondary // ignore: cast_nullable_to_non_nullable
as List<RankedSearchResult>,filterChips: null == filterChips ? _self._filterChips : filterChips // ignore: cast_nullable_to_non_nullable
as List<RankerFilterChip>,suggestion: freezed == suggestion ? _self.suggestion : suggestion // ignore: cast_nullable_to_non_nullable
as String?,queryLanguage: freezed == queryLanguage ? _self.queryLanguage : queryLanguage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
