// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WriterCategoryModel {

 String get id; String get slug; String get name; int get articleCount; int get sortOrder;
/// Create a copy of WriterCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriterCategoryModelCopyWith<WriterCategoryModel> get copyWith => _$WriterCategoryModelCopyWithImpl<WriterCategoryModel>(this as WriterCategoryModel, _$identity);

  /// Serializes this WriterCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriterCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,articleCount,sortOrder);

@override
String toString() {
  return 'WriterCategoryModel(id: $id, slug: $slug, name: $name, articleCount: $articleCount, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $WriterCategoryModelCopyWith<$Res>  {
  factory $WriterCategoryModelCopyWith(WriterCategoryModel value, $Res Function(WriterCategoryModel) _then) = _$WriterCategoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, int articleCount, int sortOrder
});




}
/// @nodoc
class _$WriterCategoryModelCopyWithImpl<$Res>
    implements $WriterCategoryModelCopyWith<$Res> {
  _$WriterCategoryModelCopyWithImpl(this._self, this._then);

  final WriterCategoryModel _self;
  final $Res Function(WriterCategoryModel) _then;

/// Create a copy of WriterCategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? articleCount = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WriterCategoryModel].
extension WriterCategoryModelPatterns on WriterCategoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WriterCategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WriterCategoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WriterCategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WriterCategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  int articleCount,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WriterCategoryModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.articleCount,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  int articleCount,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryModel():
return $default(_that.id,_that.slug,_that.name,_that.articleCount,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  int articleCount,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.articleCount,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WriterCategoryModel extends WriterCategoryModel {
  const _WriterCategoryModel({required this.id, required this.slug, required this.name, this.articleCount = 0, this.sortOrder = 0}): super._();
  factory _WriterCategoryModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String name;
@override@JsonKey() final  int articleCount;
@override@JsonKey() final  int sortOrder;

/// Create a copy of WriterCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WriterCategoryModelCopyWith<_WriterCategoryModel> get copyWith => __$WriterCategoryModelCopyWithImpl<_WriterCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WriterCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WriterCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,articleCount,sortOrder);

@override
String toString() {
  return 'WriterCategoryModel(id: $id, slug: $slug, name: $name, articleCount: $articleCount, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$WriterCategoryModelCopyWith<$Res> implements $WriterCategoryModelCopyWith<$Res> {
  factory _$WriterCategoryModelCopyWith(_WriterCategoryModel value, $Res Function(_WriterCategoryModel) _then) = __$WriterCategoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, int articleCount, int sortOrder
});




}
/// @nodoc
class __$WriterCategoryModelCopyWithImpl<$Res>
    implements _$WriterCategoryModelCopyWith<$Res> {
  __$WriterCategoryModelCopyWithImpl(this._self, this._then);

  final _WriterCategoryModel _self;
  final $Res Function(_WriterCategoryModel) _then;

/// Create a copy of WriterCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? articleCount = null,Object? sortOrder = null,}) {
  return _then(_WriterCategoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WriterCategoryListModel {

 List<WriterCategoryModel> get items; int get uncategorizedCount;
/// Create a copy of WriterCategoryListModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriterCategoryListModelCopyWith<WriterCategoryListModel> get copyWith => _$WriterCategoryListModelCopyWithImpl<WriterCategoryListModel>(this as WriterCategoryListModel, _$identity);

  /// Serializes this WriterCategoryListModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriterCategoryListModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.uncategorizedCount, uncategorizedCount) || other.uncategorizedCount == uncategorizedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),uncategorizedCount);

@override
String toString() {
  return 'WriterCategoryListModel(items: $items, uncategorizedCount: $uncategorizedCount)';
}


}

/// @nodoc
abstract mixin class $WriterCategoryListModelCopyWith<$Res>  {
  factory $WriterCategoryListModelCopyWith(WriterCategoryListModel value, $Res Function(WriterCategoryListModel) _then) = _$WriterCategoryListModelCopyWithImpl;
@useResult
$Res call({
 List<WriterCategoryModel> items, int uncategorizedCount
});




}
/// @nodoc
class _$WriterCategoryListModelCopyWithImpl<$Res>
    implements $WriterCategoryListModelCopyWith<$Res> {
  _$WriterCategoryListModelCopyWithImpl(this._self, this._then);

  final WriterCategoryListModel _self;
  final $Res Function(WriterCategoryListModel) _then;

/// Create a copy of WriterCategoryListModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? uncategorizedCount = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<WriterCategoryModel>,uncategorizedCount: null == uncategorizedCount ? _self.uncategorizedCount : uncategorizedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WriterCategoryListModel].
extension WriterCategoryListModelPatterns on WriterCategoryListModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WriterCategoryListModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WriterCategoryListModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WriterCategoryListModel value)  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryListModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WriterCategoryListModel value)?  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryListModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WriterCategoryModel> items,  int uncategorizedCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WriterCategoryListModel() when $default != null:
return $default(_that.items,_that.uncategorizedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WriterCategoryModel> items,  int uncategorizedCount)  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryListModel():
return $default(_that.items,_that.uncategorizedCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WriterCategoryModel> items,  int uncategorizedCount)?  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryListModel() when $default != null:
return $default(_that.items,_that.uncategorizedCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WriterCategoryListModel extends WriterCategoryListModel {
  const _WriterCategoryListModel({final  List<WriterCategoryModel> items = const <WriterCategoryModel>[], this.uncategorizedCount = 0}): _items = items,super._();
  factory _WriterCategoryListModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryListModelFromJson(json);

 final  List<WriterCategoryModel> _items;
@override@JsonKey() List<WriterCategoryModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int uncategorizedCount;

/// Create a copy of WriterCategoryListModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WriterCategoryListModelCopyWith<_WriterCategoryListModel> get copyWith => __$WriterCategoryListModelCopyWithImpl<_WriterCategoryListModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WriterCategoryListModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WriterCategoryListModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.uncategorizedCount, uncategorizedCount) || other.uncategorizedCount == uncategorizedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),uncategorizedCount);

@override
String toString() {
  return 'WriterCategoryListModel(items: $items, uncategorizedCount: $uncategorizedCount)';
}


}

/// @nodoc
abstract mixin class _$WriterCategoryListModelCopyWith<$Res> implements $WriterCategoryListModelCopyWith<$Res> {
  factory _$WriterCategoryListModelCopyWith(_WriterCategoryListModel value, $Res Function(_WriterCategoryListModel) _then) = __$WriterCategoryListModelCopyWithImpl;
@override @useResult
$Res call({
 List<WriterCategoryModel> items, int uncategorizedCount
});




}
/// @nodoc
class __$WriterCategoryListModelCopyWithImpl<$Res>
    implements _$WriterCategoryListModelCopyWith<$Res> {
  __$WriterCategoryListModelCopyWithImpl(this._self, this._then);

  final _WriterCategoryListModel _self;
  final $Res Function(_WriterCategoryListModel) _then;

/// Create a copy of WriterCategoryListModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? uncategorizedCount = null,}) {
  return _then(_WriterCategoryListModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<WriterCategoryModel>,uncategorizedCount: null == uncategorizedCount ? _self.uncategorizedCount : uncategorizedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WriterCategoryPageModel {

 String? get id; String get slug; String? get name; int get articleCount; AuthorModel get author;
/// Create a copy of WriterCategoryPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriterCategoryPageModelCopyWith<WriterCategoryPageModel> get copyWith => _$WriterCategoryPageModelCopyWithImpl<WriterCategoryPageModel>(this as WriterCategoryPageModel, _$identity);

  /// Serializes this WriterCategoryPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriterCategoryPageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,articleCount,author);

@override
String toString() {
  return 'WriterCategoryPageModel(id: $id, slug: $slug, name: $name, articleCount: $articleCount, author: $author)';
}


}

/// @nodoc
abstract mixin class $WriterCategoryPageModelCopyWith<$Res>  {
  factory $WriterCategoryPageModelCopyWith(WriterCategoryPageModel value, $Res Function(WriterCategoryPageModel) _then) = _$WriterCategoryPageModelCopyWithImpl;
@useResult
$Res call({
 String? id, String slug, String? name, int articleCount, AuthorModel author
});


$AuthorModelCopyWith<$Res> get author;

}
/// @nodoc
class _$WriterCategoryPageModelCopyWithImpl<$Res>
    implements $WriterCategoryPageModelCopyWith<$Res> {
  _$WriterCategoryPageModelCopyWithImpl(this._self, this._then);

  final WriterCategoryPageModel _self;
  final $Res Function(WriterCategoryPageModel) _then;

/// Create a copy of WriterCategoryPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? slug = null,Object? name = freezed,Object? articleCount = null,Object? author = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,
  ));
}
/// Create a copy of WriterCategoryPageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [WriterCategoryPageModel].
extension WriterCategoryPageModelPatterns on WriterCategoryPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WriterCategoryPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WriterCategoryPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WriterCategoryPageModel value)  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WriterCategoryPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String slug,  String? name,  int articleCount,  AuthorModel author)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WriterCategoryPageModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.articleCount,_that.author);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String slug,  String? name,  int articleCount,  AuthorModel author)  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryPageModel():
return $default(_that.id,_that.slug,_that.name,_that.articleCount,_that.author);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String slug,  String? name,  int articleCount,  AuthorModel author)?  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryPageModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.articleCount,_that.author);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WriterCategoryPageModel extends WriterCategoryPageModel {
  const _WriterCategoryPageModel({this.id, required this.slug, this.name, this.articleCount = 0, required this.author}): super._();
  factory _WriterCategoryPageModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryPageModelFromJson(json);

@override final  String? id;
@override final  String slug;
@override final  String? name;
@override@JsonKey() final  int articleCount;
@override final  AuthorModel author;

/// Create a copy of WriterCategoryPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WriterCategoryPageModelCopyWith<_WriterCategoryPageModel> get copyWith => __$WriterCategoryPageModelCopyWithImpl<_WriterCategoryPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WriterCategoryPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WriterCategoryPageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,articleCount,author);

@override
String toString() {
  return 'WriterCategoryPageModel(id: $id, slug: $slug, name: $name, articleCount: $articleCount, author: $author)';
}


}

/// @nodoc
abstract mixin class _$WriterCategoryPageModelCopyWith<$Res> implements $WriterCategoryPageModelCopyWith<$Res> {
  factory _$WriterCategoryPageModelCopyWith(_WriterCategoryPageModel value, $Res Function(_WriterCategoryPageModel) _then) = __$WriterCategoryPageModelCopyWithImpl;
@override @useResult
$Res call({
 String? id, String slug, String? name, int articleCount, AuthorModel author
});


@override $AuthorModelCopyWith<$Res> get author;

}
/// @nodoc
class __$WriterCategoryPageModelCopyWithImpl<$Res>
    implements _$WriterCategoryPageModelCopyWith<$Res> {
  __$WriterCategoryPageModelCopyWithImpl(this._self, this._then);

  final _WriterCategoryPageModel _self;
  final $Res Function(_WriterCategoryPageModel) _then;

/// Create a copy of WriterCategoryPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? slug = null,Object? name = freezed,Object? articleCount = null,Object? author = null,}) {
  return _then(_WriterCategoryPageModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,
  ));
}

/// Create a copy of WriterCategoryPageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$WriterCategoryRefModel {

 String get slug; String get name;
/// Create a copy of WriterCategoryRefModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriterCategoryRefModelCopyWith<WriterCategoryRefModel> get copyWith => _$WriterCategoryRefModelCopyWithImpl<WriterCategoryRefModel>(this as WriterCategoryRefModel, _$identity);

  /// Serializes this WriterCategoryRefModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriterCategoryRefModel&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name);

@override
String toString() {
  return 'WriterCategoryRefModel(slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class $WriterCategoryRefModelCopyWith<$Res>  {
  factory $WriterCategoryRefModelCopyWith(WriterCategoryRefModel value, $Res Function(WriterCategoryRefModel) _then) = _$WriterCategoryRefModelCopyWithImpl;
@useResult
$Res call({
 String slug, String name
});




}
/// @nodoc
class _$WriterCategoryRefModelCopyWithImpl<$Res>
    implements $WriterCategoryRefModelCopyWith<$Res> {
  _$WriterCategoryRefModelCopyWithImpl(this._self, this._then);

  final WriterCategoryRefModel _self;
  final $Res Function(WriterCategoryRefModel) _then;

/// Create a copy of WriterCategoryRefModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? name = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WriterCategoryRefModel].
extension WriterCategoryRefModelPatterns on WriterCategoryRefModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WriterCategoryRefModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WriterCategoryRefModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WriterCategoryRefModel value)  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryRefModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WriterCategoryRefModel value)?  $default,){
final _that = this;
switch (_that) {
case _WriterCategoryRefModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WriterCategoryRefModel() when $default != null:
return $default(_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String name)  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryRefModel():
return $default(_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String name)?  $default,) {final _that = this;
switch (_that) {
case _WriterCategoryRefModel() when $default != null:
return $default(_that.slug,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WriterCategoryRefModel extends WriterCategoryRefModel {
  const _WriterCategoryRefModel({required this.slug, required this.name}): super._();
  factory _WriterCategoryRefModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryRefModelFromJson(json);

@override final  String slug;
@override final  String name;

/// Create a copy of WriterCategoryRefModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WriterCategoryRefModelCopyWith<_WriterCategoryRefModel> get copyWith => __$WriterCategoryRefModelCopyWithImpl<_WriterCategoryRefModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WriterCategoryRefModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WriterCategoryRefModel&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name);

@override
String toString() {
  return 'WriterCategoryRefModel(slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class _$WriterCategoryRefModelCopyWith<$Res> implements $WriterCategoryRefModelCopyWith<$Res> {
  factory _$WriterCategoryRefModelCopyWith(_WriterCategoryRefModel value, $Res Function(_WriterCategoryRefModel) _then) = __$WriterCategoryRefModelCopyWithImpl;
@override @useResult
$Res call({
 String slug, String name
});




}
/// @nodoc
class __$WriterCategoryRefModelCopyWithImpl<$Res>
    implements _$WriterCategoryRefModelCopyWith<$Res> {
  __$WriterCategoryRefModelCopyWithImpl(this._self, this._then);

  final _WriterCategoryRefModel _self;
  final $Res Function(_WriterCategoryRefModel) _then;

/// Create a copy of WriterCategoryRefModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? name = null,}) {
  return _then(_WriterCategoryRefModel(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CategoryNameRequest {

 String get name;
/// Create a copy of CategoryNameRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryNameRequestCopyWith<CategoryNameRequest> get copyWith => _$CategoryNameRequestCopyWithImpl<CategoryNameRequest>(this as CategoryNameRequest, _$identity);

  /// Serializes this CategoryNameRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryNameRequest&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'CategoryNameRequest(name: $name)';
}


}

/// @nodoc
abstract mixin class $CategoryNameRequestCopyWith<$Res>  {
  factory $CategoryNameRequestCopyWith(CategoryNameRequest value, $Res Function(CategoryNameRequest) _then) = _$CategoryNameRequestCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$CategoryNameRequestCopyWithImpl<$Res>
    implements $CategoryNameRequestCopyWith<$Res> {
  _$CategoryNameRequestCopyWithImpl(this._self, this._then);

  final CategoryNameRequest _self;
  final $Res Function(CategoryNameRequest) _then;

/// Create a copy of CategoryNameRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryNameRequest].
extension CategoryNameRequestPatterns on CategoryNameRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryNameRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryNameRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryNameRequest value)  $default,){
final _that = this;
switch (_that) {
case _CategoryNameRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryNameRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryNameRequest() when $default != null:
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
case _CategoryNameRequest() when $default != null:
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
case _CategoryNameRequest():
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
case _CategoryNameRequest() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryNameRequest implements CategoryNameRequest {
  const _CategoryNameRequest({required this.name});
  factory _CategoryNameRequest.fromJson(Map<String, dynamic> json) => _$CategoryNameRequestFromJson(json);

@override final  String name;

/// Create a copy of CategoryNameRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryNameRequestCopyWith<_CategoryNameRequest> get copyWith => __$CategoryNameRequestCopyWithImpl<_CategoryNameRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryNameRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryNameRequest&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'CategoryNameRequest(name: $name)';
}


}

/// @nodoc
abstract mixin class _$CategoryNameRequestCopyWith<$Res> implements $CategoryNameRequestCopyWith<$Res> {
  factory _$CategoryNameRequestCopyWith(_CategoryNameRequest value, $Res Function(_CategoryNameRequest) _then) = __$CategoryNameRequestCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$CategoryNameRequestCopyWithImpl<$Res>
    implements _$CategoryNameRequestCopyWith<$Res> {
  __$CategoryNameRequestCopyWithImpl(this._self, this._then);

  final _CategoryNameRequest _self;
  final $Res Function(_CategoryNameRequest) _then;

/// Create a copy of CategoryNameRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_CategoryNameRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CategoryOrderRequest {

 List<String> get categoryIds;
/// Create a copy of CategoryOrderRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryOrderRequestCopyWith<CategoryOrderRequest> get copyWith => _$CategoryOrderRequestCopyWithImpl<CategoryOrderRequest>(this as CategoryOrderRequest, _$identity);

  /// Serializes this CategoryOrderRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryOrderRequest&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categoryIds));

@override
String toString() {
  return 'CategoryOrderRequest(categoryIds: $categoryIds)';
}


}

/// @nodoc
abstract mixin class $CategoryOrderRequestCopyWith<$Res>  {
  factory $CategoryOrderRequestCopyWith(CategoryOrderRequest value, $Res Function(CategoryOrderRequest) _then) = _$CategoryOrderRequestCopyWithImpl;
@useResult
$Res call({
 List<String> categoryIds
});




}
/// @nodoc
class _$CategoryOrderRequestCopyWithImpl<$Res>
    implements $CategoryOrderRequestCopyWith<$Res> {
  _$CategoryOrderRequestCopyWithImpl(this._self, this._then);

  final CategoryOrderRequest _self;
  final $Res Function(CategoryOrderRequest) _then;

/// Create a copy of CategoryOrderRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryIds = null,}) {
  return _then(_self.copyWith(
categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryOrderRequest].
extension CategoryOrderRequestPatterns on CategoryOrderRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryOrderRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryOrderRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryOrderRequest value)  $default,){
final _that = this;
switch (_that) {
case _CategoryOrderRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryOrderRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryOrderRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> categoryIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryOrderRequest() when $default != null:
return $default(_that.categoryIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> categoryIds)  $default,) {final _that = this;
switch (_that) {
case _CategoryOrderRequest():
return $default(_that.categoryIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> categoryIds)?  $default,) {final _that = this;
switch (_that) {
case _CategoryOrderRequest() when $default != null:
return $default(_that.categoryIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryOrderRequest implements CategoryOrderRequest {
  const _CategoryOrderRequest({required final  List<String> categoryIds}): _categoryIds = categoryIds;
  factory _CategoryOrderRequest.fromJson(Map<String, dynamic> json) => _$CategoryOrderRequestFromJson(json);

 final  List<String> _categoryIds;
@override List<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}


/// Create a copy of CategoryOrderRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryOrderRequestCopyWith<_CategoryOrderRequest> get copyWith => __$CategoryOrderRequestCopyWithImpl<_CategoryOrderRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryOrderRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryOrderRequest&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categoryIds));

@override
String toString() {
  return 'CategoryOrderRequest(categoryIds: $categoryIds)';
}


}

/// @nodoc
abstract mixin class _$CategoryOrderRequestCopyWith<$Res> implements $CategoryOrderRequestCopyWith<$Res> {
  factory _$CategoryOrderRequestCopyWith(_CategoryOrderRequest value, $Res Function(_CategoryOrderRequest) _then) = __$CategoryOrderRequestCopyWithImpl;
@override @useResult
$Res call({
 List<String> categoryIds
});




}
/// @nodoc
class __$CategoryOrderRequestCopyWithImpl<$Res>
    implements _$CategoryOrderRequestCopyWith<$Res> {
  __$CategoryOrderRequestCopyWithImpl(this._self, this._then);

  final _CategoryOrderRequest _self;
  final $Res Function(_CategoryOrderRequest) _then;

/// Create a copy of CategoryOrderRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryIds = null,}) {
  return _then(_CategoryOrderRequest(
categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
