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

// dart format on
