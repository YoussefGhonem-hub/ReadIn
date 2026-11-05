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
mixin _$SearchArticleModel {

 ArticleCardModel get article; String? get matchedIn;
/// Create a copy of SearchArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchArticleModelCopyWith<SearchArticleModel> get copyWith => _$SearchArticleModelCopyWithImpl<SearchArticleModel>(this as SearchArticleModel, _$identity);

  /// Serializes this SearchArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchArticleModel&&(identical(other.article, article) || other.article == article)&&(identical(other.matchedIn, matchedIn) || other.matchedIn == matchedIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,matchedIn);

@override
String toString() {
  return 'SearchArticleModel(article: $article, matchedIn: $matchedIn)';
}


}

/// @nodoc
abstract mixin class $SearchArticleModelCopyWith<$Res>  {
  factory $SearchArticleModelCopyWith(SearchArticleModel value, $Res Function(SearchArticleModel) _then) = _$SearchArticleModelCopyWithImpl;
@useResult
$Res call({
 ArticleCardModel article, String? matchedIn
});


$ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class _$SearchArticleModelCopyWithImpl<$Res>
    implements $SearchArticleModelCopyWith<$Res> {
  _$SearchArticleModelCopyWithImpl(this._self, this._then);

  final SearchArticleModel _self;
  final $Res Function(SearchArticleModel) _then;

/// Create a copy of SearchArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? matchedIn = freezed,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,matchedIn: freezed == matchedIn ? _self.matchedIn : matchedIn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SearchArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchArticleModel].
extension SearchArticleModelPatterns on SearchArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _SearchArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _SearchArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArticleCardModel article,  String? matchedIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchArticleModel() when $default != null:
return $default(_that.article,_that.matchedIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArticleCardModel article,  String? matchedIn)  $default,) {final _that = this;
switch (_that) {
case _SearchArticleModel():
return $default(_that.article,_that.matchedIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArticleCardModel article,  String? matchedIn)?  $default,) {final _that = this;
switch (_that) {
case _SearchArticleModel() when $default != null:
return $default(_that.article,_that.matchedIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchArticleModel extends SearchArticleModel {
  const _SearchArticleModel({required this.article, this.matchedIn}): super._();
  factory _SearchArticleModel.fromJson(Map<String, dynamic> json) => _$SearchArticleModelFromJson(json);

@override final  ArticleCardModel article;
@override final  String? matchedIn;

/// Create a copy of SearchArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchArticleModelCopyWith<_SearchArticleModel> get copyWith => __$SearchArticleModelCopyWithImpl<_SearchArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchArticleModel&&(identical(other.article, article) || other.article == article)&&(identical(other.matchedIn, matchedIn) || other.matchedIn == matchedIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,matchedIn);

@override
String toString() {
  return 'SearchArticleModel(article: $article, matchedIn: $matchedIn)';
}


}

/// @nodoc
abstract mixin class _$SearchArticleModelCopyWith<$Res> implements $SearchArticleModelCopyWith<$Res> {
  factory _$SearchArticleModelCopyWith(_SearchArticleModel value, $Res Function(_SearchArticleModel) _then) = __$SearchArticleModelCopyWithImpl;
@override @useResult
$Res call({
 ArticleCardModel article, String? matchedIn
});


@override $ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class __$SearchArticleModelCopyWithImpl<$Res>
    implements _$SearchArticleModelCopyWith<$Res> {
  __$SearchArticleModelCopyWithImpl(this._self, this._then);

  final _SearchArticleModel _self;
  final $Res Function(_SearchArticleModel) _then;

/// Create a copy of SearchArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? matchedIn = freezed,}) {
  return _then(_SearchArticleModel(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,matchedIn: freezed == matchedIn ? _self.matchedIn : matchedIn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SearchArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// @nodoc
mixin _$SearchArticlePageModel {

 List<SearchArticleModel> get items; String? get nextCursor;
/// Create a copy of SearchArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchArticlePageModelCopyWith<SearchArticlePageModel> get copyWith => _$SearchArticlePageModelCopyWithImpl<SearchArticlePageModel>(this as SearchArticlePageModel, _$identity);

  /// Serializes this SearchArticlePageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchArticlePageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'SearchArticlePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $SearchArticlePageModelCopyWith<$Res>  {
  factory $SearchArticlePageModelCopyWith(SearchArticlePageModel value, $Res Function(SearchArticlePageModel) _then) = _$SearchArticlePageModelCopyWithImpl;
@useResult
$Res call({
 List<SearchArticleModel> items, String? nextCursor
});




}
/// @nodoc
class _$SearchArticlePageModelCopyWithImpl<$Res>
    implements $SearchArticlePageModelCopyWith<$Res> {
  _$SearchArticlePageModelCopyWithImpl(this._self, this._then);

  final SearchArticlePageModel _self;
  final $Res Function(SearchArticlePageModel) _then;

/// Create a copy of SearchArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SearchArticleModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchArticlePageModel].
extension SearchArticlePageModelPatterns on SearchArticlePageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchArticlePageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchArticlePageModel value)  $default,){
final _that = this;
switch (_that) {
case _SearchArticlePageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchArticlePageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SearchArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchArticleModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchArticlePageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchArticleModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _SearchArticlePageModel():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchArticleModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _SearchArticlePageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchArticlePageModel implements SearchArticlePageModel {
  const _SearchArticlePageModel({final  List<SearchArticleModel> items = const <SearchArticleModel>[], this.nextCursor}): _items = items;
  factory _SearchArticlePageModel.fromJson(Map<String, dynamic> json) => _$SearchArticlePageModelFromJson(json);

 final  List<SearchArticleModel> _items;
@override@JsonKey() List<SearchArticleModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of SearchArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchArticlePageModelCopyWith<_SearchArticlePageModel> get copyWith => __$SearchArticlePageModelCopyWithImpl<_SearchArticlePageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchArticlePageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchArticlePageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'SearchArticlePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$SearchArticlePageModelCopyWith<$Res> implements $SearchArticlePageModelCopyWith<$Res> {
  factory _$SearchArticlePageModelCopyWith(_SearchArticlePageModel value, $Res Function(_SearchArticlePageModel) _then) = __$SearchArticlePageModelCopyWithImpl;
@override @useResult
$Res call({
 List<SearchArticleModel> items, String? nextCursor
});




}
/// @nodoc
class __$SearchArticlePageModelCopyWithImpl<$Res>
    implements _$SearchArticlePageModelCopyWith<$Res> {
  __$SearchArticlePageModelCopyWithImpl(this._self, this._then);

  final _SearchArticlePageModel _self;
  final $Res Function(_SearchArticlePageModel) _then;

/// Create a copy of SearchArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_SearchArticlePageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SearchArticleModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SearchTopicModel {

 String? get kind; String get id; String get name; String get nameAr; String get nameEn; String get fieldSlug; String? get topicSlug; String get fieldName; String get icon; String get color; int get articleCount;
/// Create a copy of SearchTopicModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTopicModelCopyWith<SearchTopicModel> get copyWith => _$SearchTopicModelCopyWithImpl<SearchTopicModel>(this as SearchTopicModel, _$identity);

  /// Serializes this SearchTopicModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTopicModel&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.fieldSlug, fieldSlug) || other.fieldSlug == fieldSlug)&&(identical(other.topicSlug, topicSlug) || other.topicSlug == topicSlug)&&(identical(other.fieldName, fieldName) || other.fieldName == fieldName)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,id,name,nameAr,nameEn,fieldSlug,topicSlug,fieldName,icon,color,articleCount);

@override
String toString() {
  return 'SearchTopicModel(kind: $kind, id: $id, name: $name, nameAr: $nameAr, nameEn: $nameEn, fieldSlug: $fieldSlug, topicSlug: $topicSlug, fieldName: $fieldName, icon: $icon, color: $color, articleCount: $articleCount)';
}


}

/// @nodoc
abstract mixin class $SearchTopicModelCopyWith<$Res>  {
  factory $SearchTopicModelCopyWith(SearchTopicModel value, $Res Function(SearchTopicModel) _then) = _$SearchTopicModelCopyWithImpl;
@useResult
$Res call({
 String? kind, String id, String name, String nameAr, String nameEn, String fieldSlug, String? topicSlug, String fieldName, String icon, String color, int articleCount
});




}
/// @nodoc
class _$SearchTopicModelCopyWithImpl<$Res>
    implements $SearchTopicModelCopyWith<$Res> {
  _$SearchTopicModelCopyWithImpl(this._self, this._then);

  final SearchTopicModel _self;
  final $Res Function(SearchTopicModel) _then;

/// Create a copy of SearchTopicModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = freezed,Object? id = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? fieldSlug = null,Object? topicSlug = freezed,Object? fieldName = null,Object? icon = null,Object? color = null,Object? articleCount = null,}) {
  return _then(_self.copyWith(
kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,fieldSlug: null == fieldSlug ? _self.fieldSlug : fieldSlug // ignore: cast_nullable_to_non_nullable
as String,topicSlug: freezed == topicSlug ? _self.topicSlug : topicSlug // ignore: cast_nullable_to_non_nullable
as String?,fieldName: null == fieldName ? _self.fieldName : fieldName // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchTopicModel].
extension SearchTopicModelPatterns on SearchTopicModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTopicModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTopicModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTopicModel value)  $default,){
final _that = this;
switch (_that) {
case _SearchTopicModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTopicModel value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTopicModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? kind,  String id,  String name,  String nameAr,  String nameEn,  String fieldSlug,  String? topicSlug,  String fieldName,  String icon,  String color,  int articleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTopicModel() when $default != null:
return $default(_that.kind,_that.id,_that.name,_that.nameAr,_that.nameEn,_that.fieldSlug,_that.topicSlug,_that.fieldName,_that.icon,_that.color,_that.articleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? kind,  String id,  String name,  String nameAr,  String nameEn,  String fieldSlug,  String? topicSlug,  String fieldName,  String icon,  String color,  int articleCount)  $default,) {final _that = this;
switch (_that) {
case _SearchTopicModel():
return $default(_that.kind,_that.id,_that.name,_that.nameAr,_that.nameEn,_that.fieldSlug,_that.topicSlug,_that.fieldName,_that.icon,_that.color,_that.articleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? kind,  String id,  String name,  String nameAr,  String nameEn,  String fieldSlug,  String? topicSlug,  String fieldName,  String icon,  String color,  int articleCount)?  $default,) {final _that = this;
switch (_that) {
case _SearchTopicModel() when $default != null:
return $default(_that.kind,_that.id,_that.name,_that.nameAr,_that.nameEn,_that.fieldSlug,_that.topicSlug,_that.fieldName,_that.icon,_that.color,_that.articleCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchTopicModel extends SearchTopicModel {
  const _SearchTopicModel({this.kind, required this.id, required this.name, this.nameAr = '', this.nameEn = '', required this.fieldSlug, this.topicSlug, this.fieldName = '', this.icon = 'book-open', this.color = 'primary', this.articleCount = 0}): super._();
  factory _SearchTopicModel.fromJson(Map<String, dynamic> json) => _$SearchTopicModelFromJson(json);

@override final  String? kind;
@override final  String id;
@override final  String name;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override final  String fieldSlug;
@override final  String? topicSlug;
@override@JsonKey() final  String fieldName;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey() final  int articleCount;

/// Create a copy of SearchTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTopicModelCopyWith<_SearchTopicModel> get copyWith => __$SearchTopicModelCopyWithImpl<_SearchTopicModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchTopicModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTopicModel&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.fieldSlug, fieldSlug) || other.fieldSlug == fieldSlug)&&(identical(other.topicSlug, topicSlug) || other.topicSlug == topicSlug)&&(identical(other.fieldName, fieldName) || other.fieldName == fieldName)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,id,name,nameAr,nameEn,fieldSlug,topicSlug,fieldName,icon,color,articleCount);

@override
String toString() {
  return 'SearchTopicModel(kind: $kind, id: $id, name: $name, nameAr: $nameAr, nameEn: $nameEn, fieldSlug: $fieldSlug, topicSlug: $topicSlug, fieldName: $fieldName, icon: $icon, color: $color, articleCount: $articleCount)';
}


}

/// @nodoc
abstract mixin class _$SearchTopicModelCopyWith<$Res> implements $SearchTopicModelCopyWith<$Res> {
  factory _$SearchTopicModelCopyWith(_SearchTopicModel value, $Res Function(_SearchTopicModel) _then) = __$SearchTopicModelCopyWithImpl;
@override @useResult
$Res call({
 String? kind, String id, String name, String nameAr, String nameEn, String fieldSlug, String? topicSlug, String fieldName, String icon, String color, int articleCount
});




}
/// @nodoc
class __$SearchTopicModelCopyWithImpl<$Res>
    implements _$SearchTopicModelCopyWith<$Res> {
  __$SearchTopicModelCopyWithImpl(this._self, this._then);

  final _SearchTopicModel _self;
  final $Res Function(_SearchTopicModel) _then;

/// Create a copy of SearchTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = freezed,Object? id = null,Object? name = null,Object? nameAr = null,Object? nameEn = null,Object? fieldSlug = null,Object? topicSlug = freezed,Object? fieldName = null,Object? icon = null,Object? color = null,Object? articleCount = null,}) {
  return _then(_SearchTopicModel(
kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,fieldSlug: null == fieldSlug ? _self.fieldSlug : fieldSlug // ignore: cast_nullable_to_non_nullable
as String,topicSlug: freezed == topicSlug ? _self.topicSlug : topicSlug // ignore: cast_nullable_to_non_nullable
as String?,fieldName: null == fieldName ? _self.fieldName : fieldName // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SearchTopicPageModel {

 List<SearchTopicModel> get items; String? get nextCursor;
/// Create a copy of SearchTopicPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTopicPageModelCopyWith<SearchTopicPageModel> get copyWith => _$SearchTopicPageModelCopyWithImpl<SearchTopicPageModel>(this as SearchTopicPageModel, _$identity);

  /// Serializes this SearchTopicPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTopicPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'SearchTopicPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $SearchTopicPageModelCopyWith<$Res>  {
  factory $SearchTopicPageModelCopyWith(SearchTopicPageModel value, $Res Function(SearchTopicPageModel) _then) = _$SearchTopicPageModelCopyWithImpl;
@useResult
$Res call({
 List<SearchTopicModel> items, String? nextCursor
});




}
/// @nodoc
class _$SearchTopicPageModelCopyWithImpl<$Res>
    implements $SearchTopicPageModelCopyWith<$Res> {
  _$SearchTopicPageModelCopyWithImpl(this._self, this._then);

  final SearchTopicPageModel _self;
  final $Res Function(SearchTopicPageModel) _then;

/// Create a copy of SearchTopicPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SearchTopicModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchTopicPageModel].
extension SearchTopicPageModelPatterns on SearchTopicPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTopicPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTopicPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTopicPageModel value)  $default,){
final _that = this;
switch (_that) {
case _SearchTopicPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTopicPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTopicPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchTopicModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTopicPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchTopicModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _SearchTopicPageModel():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchTopicModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _SearchTopicPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchTopicPageModel implements SearchTopicPageModel {
  const _SearchTopicPageModel({final  List<SearchTopicModel> items = const <SearchTopicModel>[], this.nextCursor}): _items = items;
  factory _SearchTopicPageModel.fromJson(Map<String, dynamic> json) => _$SearchTopicPageModelFromJson(json);

 final  List<SearchTopicModel> _items;
@override@JsonKey() List<SearchTopicModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of SearchTopicPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTopicPageModelCopyWith<_SearchTopicPageModel> get copyWith => __$SearchTopicPageModelCopyWithImpl<_SearchTopicPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchTopicPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTopicPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'SearchTopicPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$SearchTopicPageModelCopyWith<$Res> implements $SearchTopicPageModelCopyWith<$Res> {
  factory _$SearchTopicPageModelCopyWith(_SearchTopicPageModel value, $Res Function(_SearchTopicPageModel) _then) = __$SearchTopicPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<SearchTopicModel> items, String? nextCursor
});




}
/// @nodoc
class __$SearchTopicPageModelCopyWithImpl<$Res>
    implements _$SearchTopicPageModelCopyWith<$Res> {
  __$SearchTopicPageModelCopyWithImpl(this._self, this._then);

  final _SearchTopicPageModel _self;
  final $Res Function(_SearchTopicPageModel) _then;

/// Create a copy of SearchTopicPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_SearchTopicPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SearchTopicModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TagPageModel {

 List<TagModel> get items; String? get nextCursor;
/// Create a copy of TagPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagPageModelCopyWith<TagPageModel> get copyWith => _$TagPageModelCopyWithImpl<TagPageModel>(this as TagPageModel, _$identity);

  /// Serializes this TagPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'TagPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $TagPageModelCopyWith<$Res>  {
  factory $TagPageModelCopyWith(TagPageModel value, $Res Function(TagPageModel) _then) = _$TagPageModelCopyWithImpl;
@useResult
$Res call({
 List<TagModel> items, String? nextCursor
});




}
/// @nodoc
class _$TagPageModelCopyWithImpl<$Res>
    implements $TagPageModelCopyWith<$Res> {
  _$TagPageModelCopyWithImpl(this._self, this._then);

  final TagPageModel _self;
  final $Res Function(TagPageModel) _then;

/// Create a copy of TagPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TagModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TagPageModel].
extension TagPageModelPatterns on TagPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TagPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TagPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TagPageModel value)  $default,){
final _that = this;
switch (_that) {
case _TagPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TagPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _TagPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TagModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TagPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TagModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _TagPageModel():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TagModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _TagPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TagPageModel implements TagPageModel {
  const _TagPageModel({final  List<TagModel> items = const <TagModel>[], this.nextCursor}): _items = items;
  factory _TagPageModel.fromJson(Map<String, dynamic> json) => _$TagPageModelFromJson(json);

 final  List<TagModel> _items;
@override@JsonKey() List<TagModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of TagPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagPageModelCopyWith<_TagPageModel> get copyWith => __$TagPageModelCopyWithImpl<_TagPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TagPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TagPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'TagPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$TagPageModelCopyWith<$Res> implements $TagPageModelCopyWith<$Res> {
  factory _$TagPageModelCopyWith(_TagPageModel value, $Res Function(_TagPageModel) _then) = __$TagPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<TagModel> items, String? nextCursor
});




}
/// @nodoc
class __$TagPageModelCopyWithImpl<$Res>
    implements _$TagPageModelCopyWith<$Res> {
  __$TagPageModelCopyWithImpl(this._self, this._then);

  final _TagPageModel _self;
  final $Res Function(_TagPageModel) _then;

/// Create a copy of TagPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_TagPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TagModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
