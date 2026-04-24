// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'semantic_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SemanticItem {

 String get id; ItemType get type; SourceType get sourceType; String get title; String get createdLabel; String get searchableSummary; Map<String, Object?> get parsedContent; String? get sourceUrl; String? get thumbnailUrl; String get language; List<String> get searchableAliases; ProcessingStatus get processingStatus; String? get clarificationQuestion;
/// Create a copy of SemanticItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SemanticItemCopyWith<SemanticItem> get copyWith => _$SemanticItemCopyWithImpl<SemanticItem>(this as SemanticItem, _$identity);

  /// Serializes this SemanticItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SemanticItem&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdLabel, createdLabel) || other.createdLabel == createdLabel)&&(identical(other.searchableSummary, searchableSummary) || other.searchableSummary == searchableSummary)&&const DeepCollectionEquality().equals(other.parsedContent, parsedContent)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.searchableAliases, searchableAliases)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.clarificationQuestion, clarificationQuestion) || other.clarificationQuestion == clarificationQuestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,sourceType,title,createdLabel,searchableSummary,const DeepCollectionEquality().hash(parsedContent),sourceUrl,thumbnailUrl,language,const DeepCollectionEquality().hash(searchableAliases),processingStatus,clarificationQuestion);

@override
String toString() {
  return 'SemanticItem(id: $id, type: $type, sourceType: $sourceType, title: $title, createdLabel: $createdLabel, searchableSummary: $searchableSummary, parsedContent: $parsedContent, sourceUrl: $sourceUrl, thumbnailUrl: $thumbnailUrl, language: $language, searchableAliases: $searchableAliases, processingStatus: $processingStatus, clarificationQuestion: $clarificationQuestion)';
}


}

/// @nodoc
abstract mixin class $SemanticItemCopyWith<$Res>  {
  factory $SemanticItemCopyWith(SemanticItem value, $Res Function(SemanticItem) _then) = _$SemanticItemCopyWithImpl;
@useResult
$Res call({
 String id, ItemType type, SourceType sourceType, String title, String createdLabel, String searchableSummary, Map<String, Object?> parsedContent, String? sourceUrl, String? thumbnailUrl, String language, List<String> searchableAliases, ProcessingStatus processingStatus, String? clarificationQuestion
});




}
/// @nodoc
class _$SemanticItemCopyWithImpl<$Res>
    implements $SemanticItemCopyWith<$Res> {
  _$SemanticItemCopyWithImpl(this._self, this._then);

  final SemanticItem _self;
  final $Res Function(SemanticItem) _then;

/// Create a copy of SemanticItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? sourceType = null,Object? title = null,Object? createdLabel = null,Object? searchableSummary = null,Object? parsedContent = null,Object? sourceUrl = freezed,Object? thumbnailUrl = freezed,Object? language = null,Object? searchableAliases = null,Object? processingStatus = null,Object? clarificationQuestion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ItemType,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as SourceType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdLabel: null == createdLabel ? _self.createdLabel : createdLabel // ignore: cast_nullable_to_non_nullable
as String,searchableSummary: null == searchableSummary ? _self.searchableSummary : searchableSummary // ignore: cast_nullable_to_non_nullable
as String,parsedContent: null == parsedContent ? _self.parsedContent : parsedContent // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,searchableAliases: null == searchableAliases ? _self.searchableAliases : searchableAliases // ignore: cast_nullable_to_non_nullable
as List<String>,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as ProcessingStatus,clarificationQuestion: freezed == clarificationQuestion ? _self.clarificationQuestion : clarificationQuestion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SemanticItem].
extension SemanticItemPatterns on SemanticItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SemanticItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SemanticItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SemanticItem value)  $default,){
final _that = this;
switch (_that) {
case _SemanticItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SemanticItem value)?  $default,){
final _that = this;
switch (_that) {
case _SemanticItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ItemType type,  SourceType sourceType,  String title,  String createdLabel,  String searchableSummary,  Map<String, Object?> parsedContent,  String? sourceUrl,  String? thumbnailUrl,  String language,  List<String> searchableAliases,  ProcessingStatus processingStatus,  String? clarificationQuestion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SemanticItem() when $default != null:
return $default(_that.id,_that.type,_that.sourceType,_that.title,_that.createdLabel,_that.searchableSummary,_that.parsedContent,_that.sourceUrl,_that.thumbnailUrl,_that.language,_that.searchableAliases,_that.processingStatus,_that.clarificationQuestion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ItemType type,  SourceType sourceType,  String title,  String createdLabel,  String searchableSummary,  Map<String, Object?> parsedContent,  String? sourceUrl,  String? thumbnailUrl,  String language,  List<String> searchableAliases,  ProcessingStatus processingStatus,  String? clarificationQuestion)  $default,) {final _that = this;
switch (_that) {
case _SemanticItem():
return $default(_that.id,_that.type,_that.sourceType,_that.title,_that.createdLabel,_that.searchableSummary,_that.parsedContent,_that.sourceUrl,_that.thumbnailUrl,_that.language,_that.searchableAliases,_that.processingStatus,_that.clarificationQuestion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ItemType type,  SourceType sourceType,  String title,  String createdLabel,  String searchableSummary,  Map<String, Object?> parsedContent,  String? sourceUrl,  String? thumbnailUrl,  String language,  List<String> searchableAliases,  ProcessingStatus processingStatus,  String? clarificationQuestion)?  $default,) {final _that = this;
switch (_that) {
case _SemanticItem() when $default != null:
return $default(_that.id,_that.type,_that.sourceType,_that.title,_that.createdLabel,_that.searchableSummary,_that.parsedContent,_that.sourceUrl,_that.thumbnailUrl,_that.language,_that.searchableAliases,_that.processingStatus,_that.clarificationQuestion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SemanticItem implements SemanticItem {
  const _SemanticItem({required this.id, required this.type, required this.sourceType, required this.title, required this.createdLabel, required this.searchableSummary, required final  Map<String, Object?> parsedContent, this.sourceUrl, this.thumbnailUrl, this.language = 'en', final  List<String> searchableAliases = const <String>[], this.processingStatus = ProcessingStatus.ready, this.clarificationQuestion}): _parsedContent = parsedContent,_searchableAliases = searchableAliases;
  factory _SemanticItem.fromJson(Map<String, dynamic> json) => _$SemanticItemFromJson(json);

@override final  String id;
@override final  ItemType type;
@override final  SourceType sourceType;
@override final  String title;
@override final  String createdLabel;
@override final  String searchableSummary;
 final  Map<String, Object?> _parsedContent;
@override Map<String, Object?> get parsedContent {
  if (_parsedContent is EqualUnmodifiableMapView) return _parsedContent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_parsedContent);
}

@override final  String? sourceUrl;
@override final  String? thumbnailUrl;
@override@JsonKey() final  String language;
 final  List<String> _searchableAliases;
@override@JsonKey() List<String> get searchableAliases {
  if (_searchableAliases is EqualUnmodifiableListView) return _searchableAliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchableAliases);
}

@override@JsonKey() final  ProcessingStatus processingStatus;
@override final  String? clarificationQuestion;

/// Create a copy of SemanticItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SemanticItemCopyWith<_SemanticItem> get copyWith => __$SemanticItemCopyWithImpl<_SemanticItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SemanticItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SemanticItem&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdLabel, createdLabel) || other.createdLabel == createdLabel)&&(identical(other.searchableSummary, searchableSummary) || other.searchableSummary == searchableSummary)&&const DeepCollectionEquality().equals(other._parsedContent, _parsedContent)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._searchableAliases, _searchableAliases)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.clarificationQuestion, clarificationQuestion) || other.clarificationQuestion == clarificationQuestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,sourceType,title,createdLabel,searchableSummary,const DeepCollectionEquality().hash(_parsedContent),sourceUrl,thumbnailUrl,language,const DeepCollectionEquality().hash(_searchableAliases),processingStatus,clarificationQuestion);

@override
String toString() {
  return 'SemanticItem(id: $id, type: $type, sourceType: $sourceType, title: $title, createdLabel: $createdLabel, searchableSummary: $searchableSummary, parsedContent: $parsedContent, sourceUrl: $sourceUrl, thumbnailUrl: $thumbnailUrl, language: $language, searchableAliases: $searchableAliases, processingStatus: $processingStatus, clarificationQuestion: $clarificationQuestion)';
}


}

/// @nodoc
abstract mixin class _$SemanticItemCopyWith<$Res> implements $SemanticItemCopyWith<$Res> {
  factory _$SemanticItemCopyWith(_SemanticItem value, $Res Function(_SemanticItem) _then) = __$SemanticItemCopyWithImpl;
@override @useResult
$Res call({
 String id, ItemType type, SourceType sourceType, String title, String createdLabel, String searchableSummary, Map<String, Object?> parsedContent, String? sourceUrl, String? thumbnailUrl, String language, List<String> searchableAliases, ProcessingStatus processingStatus, String? clarificationQuestion
});




}
/// @nodoc
class __$SemanticItemCopyWithImpl<$Res>
    implements _$SemanticItemCopyWith<$Res> {
  __$SemanticItemCopyWithImpl(this._self, this._then);

  final _SemanticItem _self;
  final $Res Function(_SemanticItem) _then;

/// Create a copy of SemanticItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? sourceType = null,Object? title = null,Object? createdLabel = null,Object? searchableSummary = null,Object? parsedContent = null,Object? sourceUrl = freezed,Object? thumbnailUrl = freezed,Object? language = null,Object? searchableAliases = null,Object? processingStatus = null,Object? clarificationQuestion = freezed,}) {
  return _then(_SemanticItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ItemType,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as SourceType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdLabel: null == createdLabel ? _self.createdLabel : createdLabel // ignore: cast_nullable_to_non_nullable
as String,searchableSummary: null == searchableSummary ? _self.searchableSummary : searchableSummary // ignore: cast_nullable_to_non_nullable
as String,parsedContent: null == parsedContent ? _self._parsedContent : parsedContent // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,searchableAliases: null == searchableAliases ? _self._searchableAliases : searchableAliases // ignore: cast_nullable_to_non_nullable
as List<String>,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as ProcessingStatus,clarificationQuestion: freezed == clarificationQuestion ? _self.clarificationQuestion : clarificationQuestion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
