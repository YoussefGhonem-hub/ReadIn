// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'continue_reading_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContinueReadingModel {

 ArticleCardModel get article; int get percent; String get language; DateTime get updatedAt;
/// Create a copy of ContinueReadingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContinueReadingModelCopyWith<ContinueReadingModel> get copyWith => _$ContinueReadingModelCopyWithImpl<ContinueReadingModel>(this as ContinueReadingModel, _$identity);

  /// Serializes this ContinueReadingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContinueReadingModel&&(identical(other.article, article) || other.article == article)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.language, language) || other.language == language)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,percent,language,updatedAt);

@override
String toString() {
  return 'ContinueReadingModel(article: $article, percent: $percent, language: $language, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ContinueReadingModelCopyWith<$Res>  {
  factory $ContinueReadingModelCopyWith(ContinueReadingModel value, $Res Function(ContinueReadingModel) _then) = _$ContinueReadingModelCopyWithImpl;
@useResult
$Res call({
 ArticleCardModel article, int percent, String language, DateTime updatedAt
});


$ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class _$ContinueReadingModelCopyWithImpl<$Res>
    implements $ContinueReadingModelCopyWith<$Res> {
  _$ContinueReadingModelCopyWithImpl(this._self, this._then);

  final ContinueReadingModel _self;
  final $Res Function(ContinueReadingModel) _then;

/// Create a copy of ContinueReadingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? percent = null,Object? language = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ContinueReadingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContinueReadingModel].
extension ContinueReadingModelPatterns on ContinueReadingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContinueReadingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContinueReadingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContinueReadingModel value)  $default,){
final _that = this;
switch (_that) {
case _ContinueReadingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContinueReadingModel value)?  $default,){
final _that = this;
switch (_that) {
case _ContinueReadingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArticleCardModel article,  int percent,  String language,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContinueReadingModel() when $default != null:
return $default(_that.article,_that.percent,_that.language,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArticleCardModel article,  int percent,  String language,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ContinueReadingModel():
return $default(_that.article,_that.percent,_that.language,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArticleCardModel article,  int percent,  String language,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ContinueReadingModel() when $default != null:
return $default(_that.article,_that.percent,_that.language,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContinueReadingModel extends ContinueReadingModel {
  const _ContinueReadingModel({required this.article, this.percent = 0, required this.language, required this.updatedAt}): super._();
  factory _ContinueReadingModel.fromJson(Map<String, dynamic> json) => _$ContinueReadingModelFromJson(json);

@override final  ArticleCardModel article;
@override@JsonKey() final  int percent;
@override final  String language;
@override final  DateTime updatedAt;

/// Create a copy of ContinueReadingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContinueReadingModelCopyWith<_ContinueReadingModel> get copyWith => __$ContinueReadingModelCopyWithImpl<_ContinueReadingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContinueReadingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContinueReadingModel&&(identical(other.article, article) || other.article == article)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.language, language) || other.language == language)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,percent,language,updatedAt);

@override
String toString() {
  return 'ContinueReadingModel(article: $article, percent: $percent, language: $language, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ContinueReadingModelCopyWith<$Res> implements $ContinueReadingModelCopyWith<$Res> {
  factory _$ContinueReadingModelCopyWith(_ContinueReadingModel value, $Res Function(_ContinueReadingModel) _then) = __$ContinueReadingModelCopyWithImpl;
@override @useResult
$Res call({
 ArticleCardModel article, int percent, String language, DateTime updatedAt
});


@override $ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class __$ContinueReadingModelCopyWithImpl<$Res>
    implements _$ContinueReadingModelCopyWith<$Res> {
  __$ContinueReadingModelCopyWithImpl(this._self, this._then);

  final _ContinueReadingModel _self;
  final $Res Function(_ContinueReadingModel) _then;

/// Create a copy of ContinueReadingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? percent = null,Object? language = null,Object? updatedAt = null,}) {
  return _then(_ContinueReadingModel(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ContinueReadingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}

// dart format on
