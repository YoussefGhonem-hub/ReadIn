// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SaveStateModel {

 bool get isSaved; int get saveCount;
/// Create a copy of SaveStateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStateModelCopyWith<SaveStateModel> get copyWith => _$SaveStateModelCopyWithImpl<SaveStateModel>(this as SaveStateModel, _$identity);

  /// Serializes this SaveStateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStateModel&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSaved,saveCount);

@override
String toString() {
  return 'SaveStateModel(isSaved: $isSaved, saveCount: $saveCount)';
}


}

/// @nodoc
abstract mixin class $SaveStateModelCopyWith<$Res>  {
  factory $SaveStateModelCopyWith(SaveStateModel value, $Res Function(SaveStateModel) _then) = _$SaveStateModelCopyWithImpl;
@useResult
$Res call({
 bool isSaved, int saveCount
});




}
/// @nodoc
class _$SaveStateModelCopyWithImpl<$Res>
    implements $SaveStateModelCopyWith<$Res> {
  _$SaveStateModelCopyWithImpl(this._self, this._then);

  final SaveStateModel _self;
  final $Res Function(SaveStateModel) _then;

/// Create a copy of SaveStateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSaved = null,Object? saveCount = null,}) {
  return _then(_self.copyWith(
isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SaveStateModel].
extension SaveStateModelPatterns on SaveStateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveStateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveStateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveStateModel value)  $default,){
final _that = this;
switch (_that) {
case _SaveStateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveStateModel value)?  $default,){
final _that = this;
switch (_that) {
case _SaveStateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSaved,  int saveCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveStateModel() when $default != null:
return $default(_that.isSaved,_that.saveCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSaved,  int saveCount)  $default,) {final _that = this;
switch (_that) {
case _SaveStateModel():
return $default(_that.isSaved,_that.saveCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSaved,  int saveCount)?  $default,) {final _that = this;
switch (_that) {
case _SaveStateModel() when $default != null:
return $default(_that.isSaved,_that.saveCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaveStateModel extends SaveStateModel {
  const _SaveStateModel({required this.isSaved, this.saveCount = 0}): super._();
  factory _SaveStateModel.fromJson(Map<String, dynamic> json) => _$SaveStateModelFromJson(json);

@override final  bool isSaved;
@override@JsonKey() final  int saveCount;

/// Create a copy of SaveStateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveStateModelCopyWith<_SaveStateModel> get copyWith => __$SaveStateModelCopyWithImpl<_SaveStateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveStateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveStateModel&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSaved,saveCount);

@override
String toString() {
  return 'SaveStateModel(isSaved: $isSaved, saveCount: $saveCount)';
}


}

/// @nodoc
abstract mixin class _$SaveStateModelCopyWith<$Res> implements $SaveStateModelCopyWith<$Res> {
  factory _$SaveStateModelCopyWith(_SaveStateModel value, $Res Function(_SaveStateModel) _then) = __$SaveStateModelCopyWithImpl;
@override @useResult
$Res call({
 bool isSaved, int saveCount
});




}
/// @nodoc
class __$SaveStateModelCopyWithImpl<$Res>
    implements _$SaveStateModelCopyWith<$Res> {
  __$SaveStateModelCopyWithImpl(this._self, this._then);

  final _SaveStateModel _self;
  final $Res Function(_SaveStateModel) _then;

/// Create a copy of SaveStateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSaved = null,Object? saveCount = null,}) {
  return _then(_SaveStateModel(
isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SavedArticleModel {

 DateTime get savedAt; List<String> get collectionIds; ArticleCardModel get article;
/// Create a copy of SavedArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedArticleModelCopyWith<SavedArticleModel> get copyWith => _$SavedArticleModelCopyWithImpl<SavedArticleModel>(this as SavedArticleModel, _$identity);

  /// Serializes this SavedArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedArticleModel&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&const DeepCollectionEquality().equals(other.collectionIds, collectionIds)&&(identical(other.article, article) || other.article == article));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,savedAt,const DeepCollectionEquality().hash(collectionIds),article);

@override
String toString() {
  return 'SavedArticleModel(savedAt: $savedAt, collectionIds: $collectionIds, article: $article)';
}


}

/// @nodoc
abstract mixin class $SavedArticleModelCopyWith<$Res>  {
  factory $SavedArticleModelCopyWith(SavedArticleModel value, $Res Function(SavedArticleModel) _then) = _$SavedArticleModelCopyWithImpl;
@useResult
$Res call({
 DateTime savedAt, List<String> collectionIds, ArticleCardModel article
});


$ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class _$SavedArticleModelCopyWithImpl<$Res>
    implements $SavedArticleModelCopyWith<$Res> {
  _$SavedArticleModelCopyWithImpl(this._self, this._then);

  final SavedArticleModel _self;
  final $Res Function(SavedArticleModel) _then;

/// Create a copy of SavedArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? savedAt = null,Object? collectionIds = null,Object? article = null,}) {
  return _then(_self.copyWith(
savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,collectionIds: null == collectionIds ? _self.collectionIds : collectionIds // ignore: cast_nullable_to_non_nullable
as List<String>,article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,
  ));
}
/// Create a copy of SavedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavedArticleModel].
extension SavedArticleModelPatterns on SavedArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _SavedArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _SavedArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime savedAt,  List<String> collectionIds,  ArticleCardModel article)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedArticleModel() when $default != null:
return $default(_that.savedAt,_that.collectionIds,_that.article);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime savedAt,  List<String> collectionIds,  ArticleCardModel article)  $default,) {final _that = this;
switch (_that) {
case _SavedArticleModel():
return $default(_that.savedAt,_that.collectionIds,_that.article);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime savedAt,  List<String> collectionIds,  ArticleCardModel article)?  $default,) {final _that = this;
switch (_that) {
case _SavedArticleModel() when $default != null:
return $default(_that.savedAt,_that.collectionIds,_that.article);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedArticleModel extends SavedArticleModel {
  const _SavedArticleModel({required this.savedAt, final  List<String> collectionIds = const <String>[], required this.article}): _collectionIds = collectionIds,super._();
  factory _SavedArticleModel.fromJson(Map<String, dynamic> json) => _$SavedArticleModelFromJson(json);

@override final  DateTime savedAt;
 final  List<String> _collectionIds;
@override@JsonKey() List<String> get collectionIds {
  if (_collectionIds is EqualUnmodifiableListView) return _collectionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collectionIds);
}

@override final  ArticleCardModel article;

/// Create a copy of SavedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedArticleModelCopyWith<_SavedArticleModel> get copyWith => __$SavedArticleModelCopyWithImpl<_SavedArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedArticleModel&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&const DeepCollectionEquality().equals(other._collectionIds, _collectionIds)&&(identical(other.article, article) || other.article == article));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,savedAt,const DeepCollectionEquality().hash(_collectionIds),article);

@override
String toString() {
  return 'SavedArticleModel(savedAt: $savedAt, collectionIds: $collectionIds, article: $article)';
}


}

/// @nodoc
abstract mixin class _$SavedArticleModelCopyWith<$Res> implements $SavedArticleModelCopyWith<$Res> {
  factory _$SavedArticleModelCopyWith(_SavedArticleModel value, $Res Function(_SavedArticleModel) _then) = __$SavedArticleModelCopyWithImpl;
@override @useResult
$Res call({
 DateTime savedAt, List<String> collectionIds, ArticleCardModel article
});


@override $ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class __$SavedArticleModelCopyWithImpl<$Res>
    implements _$SavedArticleModelCopyWith<$Res> {
  __$SavedArticleModelCopyWithImpl(this._self, this._then);

  final _SavedArticleModel _self;
  final $Res Function(_SavedArticleModel) _then;

/// Create a copy of SavedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? savedAt = null,Object? collectionIds = null,Object? article = null,}) {
  return _then(_SavedArticleModel(
savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,collectionIds: null == collectionIds ? _self._collectionIds : collectionIds // ignore: cast_nullable_to_non_nullable
as List<String>,article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,
  ));
}

/// Create a copy of SavedArticleModel
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
mixin _$SavedArticlePageModel {

 List<SavedArticleModel> get items; String? get nextCursor;
/// Create a copy of SavedArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedArticlePageModelCopyWith<SavedArticlePageModel> get copyWith => _$SavedArticlePageModelCopyWithImpl<SavedArticlePageModel>(this as SavedArticlePageModel, _$identity);

  /// Serializes this SavedArticlePageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedArticlePageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'SavedArticlePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $SavedArticlePageModelCopyWith<$Res>  {
  factory $SavedArticlePageModelCopyWith(SavedArticlePageModel value, $Res Function(SavedArticlePageModel) _then) = _$SavedArticlePageModelCopyWithImpl;
@useResult
$Res call({
 List<SavedArticleModel> items, String? nextCursor
});




}
/// @nodoc
class _$SavedArticlePageModelCopyWithImpl<$Res>
    implements $SavedArticlePageModelCopyWith<$Res> {
  _$SavedArticlePageModelCopyWithImpl(this._self, this._then);

  final SavedArticlePageModel _self;
  final $Res Function(SavedArticlePageModel) _then;

/// Create a copy of SavedArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SavedArticleModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedArticlePageModel].
extension SavedArticlePageModelPatterns on SavedArticlePageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedArticlePageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedArticlePageModel value)  $default,){
final _that = this;
switch (_that) {
case _SavedArticlePageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedArticlePageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SavedArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SavedArticleModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SavedArticleModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _SavedArticlePageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SavedArticleModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _SavedArticlePageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedArticlePageModel implements SavedArticlePageModel {
  const _SavedArticlePageModel({final  List<SavedArticleModel> items = const <SavedArticleModel>[], this.nextCursor}): _items = items;
  factory _SavedArticlePageModel.fromJson(Map<String, dynamic> json) => _$SavedArticlePageModelFromJson(json);

 final  List<SavedArticleModel> _items;
@override@JsonKey() List<SavedArticleModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of SavedArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedArticlePageModelCopyWith<_SavedArticlePageModel> get copyWith => __$SavedArticlePageModelCopyWithImpl<_SavedArticlePageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedArticlePageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedArticlePageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'SavedArticlePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$SavedArticlePageModelCopyWith<$Res> implements $SavedArticlePageModelCopyWith<$Res> {
  factory _$SavedArticlePageModelCopyWith(_SavedArticlePageModel value, $Res Function(_SavedArticlePageModel) _then) = __$SavedArticlePageModelCopyWithImpl;
@override @useResult
$Res call({
 List<SavedArticleModel> items, String? nextCursor
});




}
/// @nodoc
class __$SavedArticlePageModelCopyWithImpl<$Res>
    implements _$SavedArticlePageModelCopyWith<$Res> {
  __$SavedArticlePageModelCopyWithImpl(this._self, this._then);

  final _SavedArticlePageModel _self;
  final $Res Function(_SavedArticlePageModel) _then;

/// Create a copy of SavedArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_SavedArticlePageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SavedArticleModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CollectionModel {

 String get id; String get name; int get articleCount; DateTime get createdAt;
/// Create a copy of CollectionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionModelCopyWith<CollectionModel> get copyWith => _$CollectionModelCopyWithImpl<CollectionModel>(this as CollectionModel, _$identity);

  /// Serializes this CollectionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,articleCount,createdAt);

@override
String toString() {
  return 'CollectionModel(id: $id, name: $name, articleCount: $articleCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CollectionModelCopyWith<$Res>  {
  factory $CollectionModelCopyWith(CollectionModel value, $Res Function(CollectionModel) _then) = _$CollectionModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, int articleCount, DateTime createdAt
});




}
/// @nodoc
class _$CollectionModelCopyWithImpl<$Res>
    implements $CollectionModelCopyWith<$Res> {
  _$CollectionModelCopyWithImpl(this._self, this._then);

  final CollectionModel _self;
  final $Res Function(CollectionModel) _then;

/// Create a copy of CollectionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? articleCount = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionModel].
extension CollectionModelPatterns on CollectionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionModel value)  $default,){
final _that = this;
switch (_that) {
case _CollectionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionModel value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int articleCount,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionModel() when $default != null:
return $default(_that.id,_that.name,_that.articleCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int articleCount,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CollectionModel():
return $default(_that.id,_that.name,_that.articleCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int articleCount,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CollectionModel() when $default != null:
return $default(_that.id,_that.name,_that.articleCount,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionModel extends CollectionModel {
  const _CollectionModel({required this.id, required this.name, this.articleCount = 0, required this.createdAt}): super._();
  factory _CollectionModel.fromJson(Map<String, dynamic> json) => _$CollectionModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int articleCount;
@override final  DateTime createdAt;

/// Create a copy of CollectionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionModelCopyWith<_CollectionModel> get copyWith => __$CollectionModelCopyWithImpl<_CollectionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,articleCount,createdAt);

@override
String toString() {
  return 'CollectionModel(id: $id, name: $name, articleCount: $articleCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CollectionModelCopyWith<$Res> implements $CollectionModelCopyWith<$Res> {
  factory _$CollectionModelCopyWith(_CollectionModel value, $Res Function(_CollectionModel) _then) = __$CollectionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int articleCount, DateTime createdAt
});




}
/// @nodoc
class __$CollectionModelCopyWithImpl<$Res>
    implements _$CollectionModelCopyWith<$Res> {
  __$CollectionModelCopyWithImpl(this._self, this._then);

  final _CollectionModel _self;
  final $Res Function(_CollectionModel) _then;

/// Create a copy of CollectionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? articleCount = null,Object? createdAt = null,}) {
  return _then(_CollectionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CollectionNameRequest {

 String get name;
/// Create a copy of CollectionNameRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionNameRequestCopyWith<CollectionNameRequest> get copyWith => _$CollectionNameRequestCopyWithImpl<CollectionNameRequest>(this as CollectionNameRequest, _$identity);

  /// Serializes this CollectionNameRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionNameRequest&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'CollectionNameRequest(name: $name)';
}


}

/// @nodoc
abstract mixin class $CollectionNameRequestCopyWith<$Res>  {
  factory $CollectionNameRequestCopyWith(CollectionNameRequest value, $Res Function(CollectionNameRequest) _then) = _$CollectionNameRequestCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$CollectionNameRequestCopyWithImpl<$Res>
    implements $CollectionNameRequestCopyWith<$Res> {
  _$CollectionNameRequestCopyWithImpl(this._self, this._then);

  final CollectionNameRequest _self;
  final $Res Function(CollectionNameRequest) _then;

/// Create a copy of CollectionNameRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionNameRequest].
extension CollectionNameRequestPatterns on CollectionNameRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionNameRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionNameRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionNameRequest value)  $default,){
final _that = this;
switch (_that) {
case _CollectionNameRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionNameRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionNameRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionNameRequest() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _CollectionNameRequest():
return $default(_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _CollectionNameRequest() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionNameRequest implements CollectionNameRequest {
  const _CollectionNameRequest({required this.name});
  factory _CollectionNameRequest.fromJson(Map<String, dynamic> json) => _$CollectionNameRequestFromJson(json);

@override final  String name;

/// Create a copy of CollectionNameRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionNameRequestCopyWith<_CollectionNameRequest> get copyWith => __$CollectionNameRequestCopyWithImpl<_CollectionNameRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionNameRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionNameRequest&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'CollectionNameRequest(name: $name)';
}


}

/// @nodoc
abstract mixin class _$CollectionNameRequestCopyWith<$Res> implements $CollectionNameRequestCopyWith<$Res> {
  factory _$CollectionNameRequestCopyWith(_CollectionNameRequest value, $Res Function(_CollectionNameRequest) _then) = __$CollectionNameRequestCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$CollectionNameRequestCopyWithImpl<$Res>
    implements _$CollectionNameRequestCopyWith<$Res> {
  __$CollectionNameRequestCopyWithImpl(this._self, this._then);

  final _CollectionNameRequest _self;
  final $Res Function(_CollectionNameRequest) _then;

/// Create a copy of CollectionNameRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_CollectionNameRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
