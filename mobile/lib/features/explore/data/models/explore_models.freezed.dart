// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FieldSummaryModel {

 String get id; String get slug; String get name; String get nameAr; String get nameEn; String get icon; String get color; int get articleCount;
/// Create a copy of FieldSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldSummaryModelCopyWith<FieldSummaryModel> get copyWith => _$FieldSummaryModelCopyWithImpl<FieldSummaryModel>(this as FieldSummaryModel, _$identity);

  /// Serializes this FieldSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,icon,color,articleCount);

@override
String toString() {
  return 'FieldSummaryModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, color: $color, articleCount: $articleCount)';
}


}

/// @nodoc
abstract mixin class $FieldSummaryModelCopyWith<$Res>  {
  factory $FieldSummaryModelCopyWith(FieldSummaryModel value, $Res Function(FieldSummaryModel) _then) = _$FieldSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String nameAr, String nameEn, String icon, String color, int articleCount
});




}
/// @nodoc
class _$FieldSummaryModelCopyWithImpl<$Res>
    implements $FieldSummaryModelCopyWith<$Res> {
  _$FieldSummaryModelCopyWithImpl(this._self, this._then);

  final FieldSummaryModel _self;
  final $Res Function(FieldSummaryModel) _then;

/// Create a copy of FieldSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? color = null,Object? articleCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldSummaryModel].
extension FieldSummaryModelPatterns on FieldSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  String icon,  String color,  int articleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldSummaryModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color,_that.articleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  String icon,  String color,  int articleCount)  $default,) {final _that = this;
switch (_that) {
case _FieldSummaryModel():
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color,_that.articleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  String icon,  String color,  int articleCount)?  $default,) {final _that = this;
switch (_that) {
case _FieldSummaryModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color,_that.articleCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldSummaryModel extends FieldSummaryModel {
  const _FieldSummaryModel({required this.id, required this.slug, this.name = '', this.nameAr = '', this.nameEn = '', this.icon = 'book-open', this.color = 'primary', this.articleCount = 0}): super._();
  factory _FieldSummaryModel.fromJson(Map<String, dynamic> json) => _$FieldSummaryModelFromJson(json);

@override final  String id;
@override final  String slug;
@override@JsonKey() final  String name;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey() final  int articleCount;

/// Create a copy of FieldSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldSummaryModelCopyWith<_FieldSummaryModel> get copyWith => __$FieldSummaryModelCopyWithImpl<_FieldSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,icon,color,articleCount);

@override
String toString() {
  return 'FieldSummaryModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, color: $color, articleCount: $articleCount)';
}


}

/// @nodoc
abstract mixin class _$FieldSummaryModelCopyWith<$Res> implements $FieldSummaryModelCopyWith<$Res> {
  factory _$FieldSummaryModelCopyWith(_FieldSummaryModel value, $Res Function(_FieldSummaryModel) _then) = __$FieldSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String nameAr, String nameEn, String icon, String color, int articleCount
});




}
/// @nodoc
class __$FieldSummaryModelCopyWithImpl<$Res>
    implements _$FieldSummaryModelCopyWith<$Res> {
  __$FieldSummaryModelCopyWithImpl(this._self, this._then);

  final _FieldSummaryModel _self;
  final $Res Function(_FieldSummaryModel) _then;

/// Create a copy of FieldSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? color = null,Object? articleCount = null,}) {
  return _then(_FieldSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ExploreModel {

 List<FieldSummaryModel> get fields; List<ArticleCardModel> get trending; List<ArticleCardModel> get mostSaved; List<UserSummaryModel> get newWriters; List<PathCardModel> get featuredPaths;// F23: the articles the SuperAdmin featured (≤ 6, most recently featured first); [] hides the section.
 List<ArticleCardModel> get featuredArticles;
/// Create a copy of ExploreModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreModelCopyWith<ExploreModel> get copyWith => _$ExploreModelCopyWithImpl<ExploreModel>(this as ExploreModel, _$identity);

  /// Serializes this ExploreModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreModel&&const DeepCollectionEquality().equals(other.fields, fields)&&const DeepCollectionEquality().equals(other.trending, trending)&&const DeepCollectionEquality().equals(other.mostSaved, mostSaved)&&const DeepCollectionEquality().equals(other.newWriters, newWriters)&&const DeepCollectionEquality().equals(other.featuredPaths, featuredPaths)&&const DeepCollectionEquality().equals(other.featuredArticles, featuredArticles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fields),const DeepCollectionEquality().hash(trending),const DeepCollectionEquality().hash(mostSaved),const DeepCollectionEquality().hash(newWriters),const DeepCollectionEquality().hash(featuredPaths),const DeepCollectionEquality().hash(featuredArticles));

@override
String toString() {
  return 'ExploreModel(fields: $fields, trending: $trending, mostSaved: $mostSaved, newWriters: $newWriters, featuredPaths: $featuredPaths, featuredArticles: $featuredArticles)';
}


}

/// @nodoc
abstract mixin class $ExploreModelCopyWith<$Res>  {
  factory $ExploreModelCopyWith(ExploreModel value, $Res Function(ExploreModel) _then) = _$ExploreModelCopyWithImpl;
@useResult
$Res call({
 List<FieldSummaryModel> fields, List<ArticleCardModel> trending, List<ArticleCardModel> mostSaved, List<UserSummaryModel> newWriters, List<PathCardModel> featuredPaths, List<ArticleCardModel> featuredArticles
});




}
/// @nodoc
class _$ExploreModelCopyWithImpl<$Res>
    implements $ExploreModelCopyWith<$Res> {
  _$ExploreModelCopyWithImpl(this._self, this._then);

  final ExploreModel _self;
  final $Res Function(ExploreModel) _then;

/// Create a copy of ExploreModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fields = null,Object? trending = null,Object? mostSaved = null,Object? newWriters = null,Object? featuredPaths = null,Object? featuredArticles = null,}) {
  return _then(_self.copyWith(
fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<FieldSummaryModel>,trending: null == trending ? _self.trending : trending // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,mostSaved: null == mostSaved ? _self.mostSaved : mostSaved // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,newWriters: null == newWriters ? _self.newWriters : newWriters // ignore: cast_nullable_to_non_nullable
as List<UserSummaryModel>,featuredPaths: null == featuredPaths ? _self.featuredPaths : featuredPaths // ignore: cast_nullable_to_non_nullable
as List<PathCardModel>,featuredArticles: null == featuredArticles ? _self.featuredArticles : featuredArticles // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExploreModel].
extension ExploreModelPatterns on ExploreModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreModel value)  $default,){
final _that = this;
switch (_that) {
case _ExploreModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FieldSummaryModel> fields,  List<ArticleCardModel> trending,  List<ArticleCardModel> mostSaved,  List<UserSummaryModel> newWriters,  List<PathCardModel> featuredPaths,  List<ArticleCardModel> featuredArticles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreModel() when $default != null:
return $default(_that.fields,_that.trending,_that.mostSaved,_that.newWriters,_that.featuredPaths,_that.featuredArticles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FieldSummaryModel> fields,  List<ArticleCardModel> trending,  List<ArticleCardModel> mostSaved,  List<UserSummaryModel> newWriters,  List<PathCardModel> featuredPaths,  List<ArticleCardModel> featuredArticles)  $default,) {final _that = this;
switch (_that) {
case _ExploreModel():
return $default(_that.fields,_that.trending,_that.mostSaved,_that.newWriters,_that.featuredPaths,_that.featuredArticles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FieldSummaryModel> fields,  List<ArticleCardModel> trending,  List<ArticleCardModel> mostSaved,  List<UserSummaryModel> newWriters,  List<PathCardModel> featuredPaths,  List<ArticleCardModel> featuredArticles)?  $default,) {final _that = this;
switch (_that) {
case _ExploreModel() when $default != null:
return $default(_that.fields,_that.trending,_that.mostSaved,_that.newWriters,_that.featuredPaths,_that.featuredArticles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExploreModel extends ExploreModel {
  const _ExploreModel({final  List<FieldSummaryModel> fields = const <FieldSummaryModel>[], final  List<ArticleCardModel> trending = const <ArticleCardModel>[], final  List<ArticleCardModel> mostSaved = const <ArticleCardModel>[], final  List<UserSummaryModel> newWriters = const <UserSummaryModel>[], final  List<PathCardModel> featuredPaths = const <PathCardModel>[], final  List<ArticleCardModel> featuredArticles = const <ArticleCardModel>[]}): _fields = fields,_trending = trending,_mostSaved = mostSaved,_newWriters = newWriters,_featuredPaths = featuredPaths,_featuredArticles = featuredArticles,super._();
  factory _ExploreModel.fromJson(Map<String, dynamic> json) => _$ExploreModelFromJson(json);

 final  List<FieldSummaryModel> _fields;
@override@JsonKey() List<FieldSummaryModel> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  List<ArticleCardModel> _trending;
@override@JsonKey() List<ArticleCardModel> get trending {
  if (_trending is EqualUnmodifiableListView) return _trending;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trending);
}

 final  List<ArticleCardModel> _mostSaved;
@override@JsonKey() List<ArticleCardModel> get mostSaved {
  if (_mostSaved is EqualUnmodifiableListView) return _mostSaved;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mostSaved);
}

 final  List<UserSummaryModel> _newWriters;
@override@JsonKey() List<UserSummaryModel> get newWriters {
  if (_newWriters is EqualUnmodifiableListView) return _newWriters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newWriters);
}

 final  List<PathCardModel> _featuredPaths;
@override@JsonKey() List<PathCardModel> get featuredPaths {
  if (_featuredPaths is EqualUnmodifiableListView) return _featuredPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_featuredPaths);
}

// F23: the articles the SuperAdmin featured (≤ 6, most recently featured first); [] hides the section.
 final  List<ArticleCardModel> _featuredArticles;
// F23: the articles the SuperAdmin featured (≤ 6, most recently featured first); [] hides the section.
@override@JsonKey() List<ArticleCardModel> get featuredArticles {
  if (_featuredArticles is EqualUnmodifiableListView) return _featuredArticles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_featuredArticles);
}


/// Create a copy of ExploreModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreModelCopyWith<_ExploreModel> get copyWith => __$ExploreModelCopyWithImpl<_ExploreModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExploreModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreModel&&const DeepCollectionEquality().equals(other._fields, _fields)&&const DeepCollectionEquality().equals(other._trending, _trending)&&const DeepCollectionEquality().equals(other._mostSaved, _mostSaved)&&const DeepCollectionEquality().equals(other._newWriters, _newWriters)&&const DeepCollectionEquality().equals(other._featuredPaths, _featuredPaths)&&const DeepCollectionEquality().equals(other._featuredArticles, _featuredArticles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_trending),const DeepCollectionEquality().hash(_mostSaved),const DeepCollectionEquality().hash(_newWriters),const DeepCollectionEquality().hash(_featuredPaths),const DeepCollectionEquality().hash(_featuredArticles));

@override
String toString() {
  return 'ExploreModel(fields: $fields, trending: $trending, mostSaved: $mostSaved, newWriters: $newWriters, featuredPaths: $featuredPaths, featuredArticles: $featuredArticles)';
}


}

/// @nodoc
abstract mixin class _$ExploreModelCopyWith<$Res> implements $ExploreModelCopyWith<$Res> {
  factory _$ExploreModelCopyWith(_ExploreModel value, $Res Function(_ExploreModel) _then) = __$ExploreModelCopyWithImpl;
@override @useResult
$Res call({
 List<FieldSummaryModel> fields, List<ArticleCardModel> trending, List<ArticleCardModel> mostSaved, List<UserSummaryModel> newWriters, List<PathCardModel> featuredPaths, List<ArticleCardModel> featuredArticles
});




}
/// @nodoc
class __$ExploreModelCopyWithImpl<$Res>
    implements _$ExploreModelCopyWith<$Res> {
  __$ExploreModelCopyWithImpl(this._self, this._then);

  final _ExploreModel _self;
  final $Res Function(_ExploreModel) _then;

/// Create a copy of ExploreModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fields = null,Object? trending = null,Object? mostSaved = null,Object? newWriters = null,Object? featuredPaths = null,Object? featuredArticles = null,}) {
  return _then(_ExploreModel(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<FieldSummaryModel>,trending: null == trending ? _self._trending : trending // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,mostSaved: null == mostSaved ? _self._mostSaved : mostSaved // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,newWriters: null == newWriters ? _self._newWriters : newWriters // ignore: cast_nullable_to_non_nullable
as List<UserSummaryModel>,featuredPaths: null == featuredPaths ? _self._featuredPaths : featuredPaths // ignore: cast_nullable_to_non_nullable
as List<PathCardModel>,featuredArticles: null == featuredArticles ? _self._featuredArticles : featuredArticles // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,
  ));
}


}


/// @nodoc
mixin _$FieldPageTopicModel {

 String get id; String get slug; String get name; String get nameAr; String get nameEn; int get articleCount; bool get isFollowing;
/// Create a copy of FieldPageTopicModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldPageTopicModelCopyWith<FieldPageTopicModel> get copyWith => _$FieldPageTopicModelCopyWithImpl<FieldPageTopicModel>(this as FieldPageTopicModel, _$identity);

  /// Serializes this FieldPageTopicModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldPageTopicModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,articleCount,isFollowing);

@override
String toString() {
  return 'FieldPageTopicModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, articleCount: $articleCount, isFollowing: $isFollowing)';
}


}

/// @nodoc
abstract mixin class $FieldPageTopicModelCopyWith<$Res>  {
  factory $FieldPageTopicModelCopyWith(FieldPageTopicModel value, $Res Function(FieldPageTopicModel) _then) = _$FieldPageTopicModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String nameAr, String nameEn, int articleCount, bool isFollowing
});




}
/// @nodoc
class _$FieldPageTopicModelCopyWithImpl<$Res>
    implements $FieldPageTopicModelCopyWith<$Res> {
  _$FieldPageTopicModelCopyWithImpl(this._self, this._then);

  final FieldPageTopicModel _self;
  final $Res Function(FieldPageTopicModel) _then;

/// Create a copy of FieldPageTopicModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? articleCount = null,Object? isFollowing = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldPageTopicModel].
extension FieldPageTopicModelPatterns on FieldPageTopicModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldPageTopicModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldPageTopicModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldPageTopicModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldPageTopicModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldPageTopicModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldPageTopicModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  int articleCount,  bool isFollowing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldPageTopicModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.articleCount,_that.isFollowing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  int articleCount,  bool isFollowing)  $default,) {final _that = this;
switch (_that) {
case _FieldPageTopicModel():
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.articleCount,_that.isFollowing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  int articleCount,  bool isFollowing)?  $default,) {final _that = this;
switch (_that) {
case _FieldPageTopicModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.articleCount,_that.isFollowing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldPageTopicModel extends FieldPageTopicModel {
  const _FieldPageTopicModel({required this.id, required this.slug, this.name = '', this.nameAr = '', this.nameEn = '', this.articleCount = 0, this.isFollowing = false}): super._();
  factory _FieldPageTopicModel.fromJson(Map<String, dynamic> json) => _$FieldPageTopicModelFromJson(json);

@override final  String id;
@override final  String slug;
@override@JsonKey() final  String name;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override@JsonKey() final  int articleCount;
@override@JsonKey() final  bool isFollowing;

/// Create a copy of FieldPageTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldPageTopicModelCopyWith<_FieldPageTopicModel> get copyWith => __$FieldPageTopicModelCopyWithImpl<_FieldPageTopicModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldPageTopicModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldPageTopicModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,articleCount,isFollowing);

@override
String toString() {
  return 'FieldPageTopicModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, articleCount: $articleCount, isFollowing: $isFollowing)';
}


}

/// @nodoc
abstract mixin class _$FieldPageTopicModelCopyWith<$Res> implements $FieldPageTopicModelCopyWith<$Res> {
  factory _$FieldPageTopicModelCopyWith(_FieldPageTopicModel value, $Res Function(_FieldPageTopicModel) _then) = __$FieldPageTopicModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String nameAr, String nameEn, int articleCount, bool isFollowing
});




}
/// @nodoc
class __$FieldPageTopicModelCopyWithImpl<$Res>
    implements _$FieldPageTopicModelCopyWith<$Res> {
  __$FieldPageTopicModelCopyWithImpl(this._self, this._then);

  final _FieldPageTopicModel _self;
  final $Res Function(_FieldPageTopicModel) _then;

/// Create a copy of FieldPageTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? articleCount = null,Object? isFollowing = null,}) {
  return _then(_FieldPageTopicModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FieldPageModel {

 String get id; String get slug; String get name; String get nameAr; String get nameEn; String get icon; String get color; bool get isSensitive; int get articleCount; int get followerCount; bool get isFollowing; List<FieldPageTopicModel> get topics;
/// Create a copy of FieldPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldPageModelCopyWith<FieldPageModel> get copyWith => _$FieldPageModelCopyWithImpl<FieldPageModel>(this as FieldPageModel, _$identity);

  /// Serializes this FieldPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldPageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&const DeepCollectionEquality().equals(other.topics, topics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,icon,color,isSensitive,articleCount,followerCount,isFollowing,const DeepCollectionEquality().hash(topics));

@override
String toString() {
  return 'FieldPageModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, color: $color, isSensitive: $isSensitive, articleCount: $articleCount, followerCount: $followerCount, isFollowing: $isFollowing, topics: $topics)';
}


}

/// @nodoc
abstract mixin class $FieldPageModelCopyWith<$Res>  {
  factory $FieldPageModelCopyWith(FieldPageModel value, $Res Function(FieldPageModel) _then) = _$FieldPageModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String nameAr, String nameEn, String icon, String color, bool isSensitive, int articleCount, int followerCount, bool isFollowing, List<FieldPageTopicModel> topics
});




}
/// @nodoc
class _$FieldPageModelCopyWithImpl<$Res>
    implements $FieldPageModelCopyWith<$Res> {
  _$FieldPageModelCopyWithImpl(this._self, this._then);

  final FieldPageModel _self;
  final $Res Function(FieldPageModel) _then;

/// Create a copy of FieldPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? color = null,Object? isSensitive = null,Object? articleCount = null,Object? followerCount = null,Object? isFollowing = null,Object? topics = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<FieldPageTopicModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldPageModel].
extension FieldPageModelPatterns on FieldPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldPageModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  String icon,  String color,  bool isSensitive,  int articleCount,  int followerCount,  bool isFollowing,  List<FieldPageTopicModel> topics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldPageModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color,_that.isSensitive,_that.articleCount,_that.followerCount,_that.isFollowing,_that.topics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  String icon,  String color,  bool isSensitive,  int articleCount,  int followerCount,  bool isFollowing,  List<FieldPageTopicModel> topics)  $default,) {final _that = this;
switch (_that) {
case _FieldPageModel():
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color,_that.isSensitive,_that.articleCount,_that.followerCount,_that.isFollowing,_that.topics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String nameAr,  String nameEn,  String icon,  String color,  bool isSensitive,  int articleCount,  int followerCount,  bool isFollowing,  List<FieldPageTopicModel> topics)?  $default,) {final _that = this;
switch (_that) {
case _FieldPageModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color,_that.isSensitive,_that.articleCount,_that.followerCount,_that.isFollowing,_that.topics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldPageModel extends FieldPageModel {
  const _FieldPageModel({required this.id, required this.slug, this.name = '', this.nameAr = '', this.nameEn = '', this.icon = 'book-open', this.color = 'primary', this.isSensitive = false, this.articleCount = 0, this.followerCount = 0, this.isFollowing = false, final  List<FieldPageTopicModel> topics = const <FieldPageTopicModel>[]}): _topics = topics,super._();
  factory _FieldPageModel.fromJson(Map<String, dynamic> json) => _$FieldPageModelFromJson(json);

@override final  String id;
@override final  String slug;
@override@JsonKey() final  String name;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey() final  bool isSensitive;
@override@JsonKey() final  int articleCount;
@override@JsonKey() final  int followerCount;
@override@JsonKey() final  bool isFollowing;
 final  List<FieldPageTopicModel> _topics;
@override@JsonKey() List<FieldPageTopicModel> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}


/// Create a copy of FieldPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldPageModelCopyWith<_FieldPageModel> get copyWith => __$FieldPageModelCopyWithImpl<_FieldPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldPageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&const DeepCollectionEquality().equals(other._topics, _topics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,icon,color,isSensitive,articleCount,followerCount,isFollowing,const DeepCollectionEquality().hash(_topics));

@override
String toString() {
  return 'FieldPageModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, color: $color, isSensitive: $isSensitive, articleCount: $articleCount, followerCount: $followerCount, isFollowing: $isFollowing, topics: $topics)';
}


}

/// @nodoc
abstract mixin class _$FieldPageModelCopyWith<$Res> implements $FieldPageModelCopyWith<$Res> {
  factory _$FieldPageModelCopyWith(_FieldPageModel value, $Res Function(_FieldPageModel) _then) = __$FieldPageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String nameAr, String nameEn, String icon, String color, bool isSensitive, int articleCount, int followerCount, bool isFollowing, List<FieldPageTopicModel> topics
});




}
/// @nodoc
class __$FieldPageModelCopyWithImpl<$Res>
    implements _$FieldPageModelCopyWith<$Res> {
  __$FieldPageModelCopyWithImpl(this._self, this._then);

  final _FieldPageModel _self;
  final $Res Function(_FieldPageModel) _then;

/// Create a copy of FieldPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? color = null,Object? isSensitive = null,Object? articleCount = null,Object? followerCount = null,Object? isFollowing = null,Object? topics = null,}) {
  return _then(_FieldPageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<FieldPageTopicModel>,
  ));
}


}

// dart format on
