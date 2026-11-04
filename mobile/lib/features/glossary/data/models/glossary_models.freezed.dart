// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'glossary_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GlossaryArticleModel {

 String get id; String get slug; String get language; String get title; int get readingTimeMinutes; FieldRefModel get field;
/// Create a copy of GlossaryArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlossaryArticleModelCopyWith<GlossaryArticleModel> get copyWith => _$GlossaryArticleModelCopyWithImpl<GlossaryArticleModel>(this as GlossaryArticleModel, _$identity);

  /// Serializes this GlossaryArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlossaryArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.field, field) || other.field == field));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,language,title,readingTimeMinutes,field);

@override
String toString() {
  return 'GlossaryArticleModel(id: $id, slug: $slug, language: $language, title: $title, readingTimeMinutes: $readingTimeMinutes, field: $field)';
}


}

/// @nodoc
abstract mixin class $GlossaryArticleModelCopyWith<$Res>  {
  factory $GlossaryArticleModelCopyWith(GlossaryArticleModel value, $Res Function(GlossaryArticleModel) _then) = _$GlossaryArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String language, String title, int readingTimeMinutes, FieldRefModel field
});


$FieldRefModelCopyWith<$Res> get field;

}
/// @nodoc
class _$GlossaryArticleModelCopyWithImpl<$Res>
    implements $GlossaryArticleModelCopyWith<$Res> {
  _$GlossaryArticleModelCopyWithImpl(this._self, this._then);

  final GlossaryArticleModel _self;
  final $Res Function(GlossaryArticleModel) _then;

/// Create a copy of GlossaryArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? readingTimeMinutes = null,Object? field = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,
  ));
}
/// Create a copy of GlossaryArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// Adds pattern-matching-related methods to [GlossaryArticleModel].
extension GlossaryArticleModelPatterns on GlossaryArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlossaryArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlossaryArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlossaryArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _GlossaryArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlossaryArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _GlossaryArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  int readingTimeMinutes,  FieldRefModel field)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GlossaryArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.readingTimeMinutes,_that.field);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  int readingTimeMinutes,  FieldRefModel field)  $default,) {final _that = this;
switch (_that) {
case _GlossaryArticleModel():
return $default(_that.id,_that.slug,_that.language,_that.title,_that.readingTimeMinutes,_that.field);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String language,  String title,  int readingTimeMinutes,  FieldRefModel field)?  $default,) {final _that = this;
switch (_that) {
case _GlossaryArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.readingTimeMinutes,_that.field);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GlossaryArticleModel extends GlossaryArticleModel {
  const _GlossaryArticleModel({required this.id, required this.slug, required this.language, required this.title, this.readingTimeMinutes = 1, required this.field}): super._();
  factory _GlossaryArticleModel.fromJson(Map<String, dynamic> json) => _$GlossaryArticleModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String language;
@override final  String title;
@override@JsonKey() final  int readingTimeMinutes;
@override final  FieldRefModel field;

/// Create a copy of GlossaryArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlossaryArticleModelCopyWith<_GlossaryArticleModel> get copyWith => __$GlossaryArticleModelCopyWithImpl<_GlossaryArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GlossaryArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlossaryArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.field, field) || other.field == field));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,language,title,readingTimeMinutes,field);

@override
String toString() {
  return 'GlossaryArticleModel(id: $id, slug: $slug, language: $language, title: $title, readingTimeMinutes: $readingTimeMinutes, field: $field)';
}


}

/// @nodoc
abstract mixin class _$GlossaryArticleModelCopyWith<$Res> implements $GlossaryArticleModelCopyWith<$Res> {
  factory _$GlossaryArticleModelCopyWith(_GlossaryArticleModel value, $Res Function(_GlossaryArticleModel) _then) = __$GlossaryArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String language, String title, int readingTimeMinutes, FieldRefModel field
});


@override $FieldRefModelCopyWith<$Res> get field;

}
/// @nodoc
class __$GlossaryArticleModelCopyWithImpl<$Res>
    implements _$GlossaryArticleModelCopyWith<$Res> {
  __$GlossaryArticleModelCopyWithImpl(this._self, this._then);

  final _GlossaryArticleModel _self;
  final $Res Function(_GlossaryArticleModel) _then;

/// Create a copy of GlossaryArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? readingTimeMinutes = null,Object? field = null,}) {
  return _then(_GlossaryArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,
  ));
}

/// Create a copy of GlossaryArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// @nodoc
mixin _$GlossaryTermModel {

 String get slug; String get term; String get definitionEn; String get explanationAr; List<GlossaryArticleModel> get articles;
/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlossaryTermModelCopyWith<GlossaryTermModel> get copyWith => _$GlossaryTermModelCopyWithImpl<GlossaryTermModel>(this as GlossaryTermModel, _$identity);

  /// Serializes this GlossaryTermModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlossaryTermModel&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.term, term) || other.term == term)&&(identical(other.definitionEn, definitionEn) || other.definitionEn == definitionEn)&&(identical(other.explanationAr, explanationAr) || other.explanationAr == explanationAr)&&const DeepCollectionEquality().equals(other.articles, articles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,term,definitionEn,explanationAr,const DeepCollectionEquality().hash(articles));

@override
String toString() {
  return 'GlossaryTermModel(slug: $slug, term: $term, definitionEn: $definitionEn, explanationAr: $explanationAr, articles: $articles)';
}


}

/// @nodoc
abstract mixin class $GlossaryTermModelCopyWith<$Res>  {
  factory $GlossaryTermModelCopyWith(GlossaryTermModel value, $Res Function(GlossaryTermModel) _then) = _$GlossaryTermModelCopyWithImpl;
@useResult
$Res call({
 String slug, String term, String definitionEn, String explanationAr, List<GlossaryArticleModel> articles
});




}
/// @nodoc
class _$GlossaryTermModelCopyWithImpl<$Res>
    implements $GlossaryTermModelCopyWith<$Res> {
  _$GlossaryTermModelCopyWithImpl(this._self, this._then);

  final GlossaryTermModel _self;
  final $Res Function(GlossaryTermModel) _then;

/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? term = null,Object? definitionEn = null,Object? explanationAr = null,Object? articles = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,definitionEn: null == definitionEn ? _self.definitionEn : definitionEn // ignore: cast_nullable_to_non_nullable
as String,explanationAr: null == explanationAr ? _self.explanationAr : explanationAr // ignore: cast_nullable_to_non_nullable
as String,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as List<GlossaryArticleModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [GlossaryTermModel].
extension GlossaryTermModelPatterns on GlossaryTermModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlossaryTermModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlossaryTermModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlossaryTermModel value)  $default,){
final _that = this;
switch (_that) {
case _GlossaryTermModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlossaryTermModel value)?  $default,){
final _that = this;
switch (_that) {
case _GlossaryTermModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String term,  String definitionEn,  String explanationAr,  List<GlossaryArticleModel> articles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GlossaryTermModel() when $default != null:
return $default(_that.slug,_that.term,_that.definitionEn,_that.explanationAr,_that.articles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String term,  String definitionEn,  String explanationAr,  List<GlossaryArticleModel> articles)  $default,) {final _that = this;
switch (_that) {
case _GlossaryTermModel():
return $default(_that.slug,_that.term,_that.definitionEn,_that.explanationAr,_that.articles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String term,  String definitionEn,  String explanationAr,  List<GlossaryArticleModel> articles)?  $default,) {final _that = this;
switch (_that) {
case _GlossaryTermModel() when $default != null:
return $default(_that.slug,_that.term,_that.definitionEn,_that.explanationAr,_that.articles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GlossaryTermModel extends GlossaryTermModel {
  const _GlossaryTermModel({required this.slug, required this.term, this.definitionEn = '', this.explanationAr = '', final  List<GlossaryArticleModel> articles = const <GlossaryArticleModel>[]}): _articles = articles,super._();
  factory _GlossaryTermModel.fromJson(Map<String, dynamic> json) => _$GlossaryTermModelFromJson(json);

@override final  String slug;
@override final  String term;
@override@JsonKey() final  String definitionEn;
@override@JsonKey() final  String explanationAr;
 final  List<GlossaryArticleModel> _articles;
@override@JsonKey() List<GlossaryArticleModel> get articles {
  if (_articles is EqualUnmodifiableListView) return _articles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_articles);
}


/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlossaryTermModelCopyWith<_GlossaryTermModel> get copyWith => __$GlossaryTermModelCopyWithImpl<_GlossaryTermModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GlossaryTermModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlossaryTermModel&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.term, term) || other.term == term)&&(identical(other.definitionEn, definitionEn) || other.definitionEn == definitionEn)&&(identical(other.explanationAr, explanationAr) || other.explanationAr == explanationAr)&&const DeepCollectionEquality().equals(other._articles, _articles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,term,definitionEn,explanationAr,const DeepCollectionEquality().hash(_articles));

@override
String toString() {
  return 'GlossaryTermModel(slug: $slug, term: $term, definitionEn: $definitionEn, explanationAr: $explanationAr, articles: $articles)';
}


}

/// @nodoc
abstract mixin class _$GlossaryTermModelCopyWith<$Res> implements $GlossaryTermModelCopyWith<$Res> {
  factory _$GlossaryTermModelCopyWith(_GlossaryTermModel value, $Res Function(_GlossaryTermModel) _then) = __$GlossaryTermModelCopyWithImpl;
@override @useResult
$Res call({
 String slug, String term, String definitionEn, String explanationAr, List<GlossaryArticleModel> articles
});




}
/// @nodoc
class __$GlossaryTermModelCopyWithImpl<$Res>
    implements _$GlossaryTermModelCopyWith<$Res> {
  __$GlossaryTermModelCopyWithImpl(this._self, this._then);

  final _GlossaryTermModel _self;
  final $Res Function(_GlossaryTermModel) _then;

/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? term = null,Object? definitionEn = null,Object? explanationAr = null,Object? articles = null,}) {
  return _then(_GlossaryTermModel(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,definitionEn: null == definitionEn ? _self.definitionEn : definitionEn // ignore: cast_nullable_to_non_nullable
as String,explanationAr: null == explanationAr ? _self.explanationAr : explanationAr // ignore: cast_nullable_to_non_nullable
as String,articles: null == articles ? _self._articles : articles // ignore: cast_nullable_to_non_nullable
as List<GlossaryArticleModel>,
  ));
}


}


/// @nodoc
mixin _$GlossaryTermSummaryModel {

 String get slug; String get term; String get definitionEn;
/// Create a copy of GlossaryTermSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlossaryTermSummaryModelCopyWith<GlossaryTermSummaryModel> get copyWith => _$GlossaryTermSummaryModelCopyWithImpl<GlossaryTermSummaryModel>(this as GlossaryTermSummaryModel, _$identity);

  /// Serializes this GlossaryTermSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlossaryTermSummaryModel&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.term, term) || other.term == term)&&(identical(other.definitionEn, definitionEn) || other.definitionEn == definitionEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,term,definitionEn);

@override
String toString() {
  return 'GlossaryTermSummaryModel(slug: $slug, term: $term, definitionEn: $definitionEn)';
}


}

/// @nodoc
abstract mixin class $GlossaryTermSummaryModelCopyWith<$Res>  {
  factory $GlossaryTermSummaryModelCopyWith(GlossaryTermSummaryModel value, $Res Function(GlossaryTermSummaryModel) _then) = _$GlossaryTermSummaryModelCopyWithImpl;
@useResult
$Res call({
 String slug, String term, String definitionEn
});




}
/// @nodoc
class _$GlossaryTermSummaryModelCopyWithImpl<$Res>
    implements $GlossaryTermSummaryModelCopyWith<$Res> {
  _$GlossaryTermSummaryModelCopyWithImpl(this._self, this._then);

  final GlossaryTermSummaryModel _self;
  final $Res Function(GlossaryTermSummaryModel) _then;

/// Create a copy of GlossaryTermSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? term = null,Object? definitionEn = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,definitionEn: null == definitionEn ? _self.definitionEn : definitionEn // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GlossaryTermSummaryModel].
extension GlossaryTermSummaryModelPatterns on GlossaryTermSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlossaryTermSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlossaryTermSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlossaryTermSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _GlossaryTermSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlossaryTermSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _GlossaryTermSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String term,  String definitionEn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GlossaryTermSummaryModel() when $default != null:
return $default(_that.slug,_that.term,_that.definitionEn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String term,  String definitionEn)  $default,) {final _that = this;
switch (_that) {
case _GlossaryTermSummaryModel():
return $default(_that.slug,_that.term,_that.definitionEn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String term,  String definitionEn)?  $default,) {final _that = this;
switch (_that) {
case _GlossaryTermSummaryModel() when $default != null:
return $default(_that.slug,_that.term,_that.definitionEn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GlossaryTermSummaryModel extends GlossaryTermSummaryModel {
  const _GlossaryTermSummaryModel({required this.slug, required this.term, this.definitionEn = ''}): super._();
  factory _GlossaryTermSummaryModel.fromJson(Map<String, dynamic> json) => _$GlossaryTermSummaryModelFromJson(json);

@override final  String slug;
@override final  String term;
@override@JsonKey() final  String definitionEn;

/// Create a copy of GlossaryTermSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlossaryTermSummaryModelCopyWith<_GlossaryTermSummaryModel> get copyWith => __$GlossaryTermSummaryModelCopyWithImpl<_GlossaryTermSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GlossaryTermSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlossaryTermSummaryModel&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.term, term) || other.term == term)&&(identical(other.definitionEn, definitionEn) || other.definitionEn == definitionEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,term,definitionEn);

@override
String toString() {
  return 'GlossaryTermSummaryModel(slug: $slug, term: $term, definitionEn: $definitionEn)';
}


}

/// @nodoc
abstract mixin class _$GlossaryTermSummaryModelCopyWith<$Res> implements $GlossaryTermSummaryModelCopyWith<$Res> {
  factory _$GlossaryTermSummaryModelCopyWith(_GlossaryTermSummaryModel value, $Res Function(_GlossaryTermSummaryModel) _then) = __$GlossaryTermSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String slug, String term, String definitionEn
});




}
/// @nodoc
class __$GlossaryTermSummaryModelCopyWithImpl<$Res>
    implements _$GlossaryTermSummaryModelCopyWith<$Res> {
  __$GlossaryTermSummaryModelCopyWithImpl(this._self, this._then);

  final _GlossaryTermSummaryModel _self;
  final $Res Function(_GlossaryTermSummaryModel) _then;

/// Create a copy of GlossaryTermSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? term = null,Object? definitionEn = null,}) {
  return _then(_GlossaryTermSummaryModel(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,definitionEn: null == definitionEn ? _self.definitionEn : definitionEn // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
