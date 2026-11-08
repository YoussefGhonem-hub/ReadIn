// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationActorModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified;
/// Create a copy of NotificationActorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationActorModelCopyWith<NotificationActorModel> get copyWith => _$NotificationActorModelCopyWithImpl<NotificationActorModel>(this as NotificationActorModel, _$identity);

  /// Serializes this NotificationActorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationActorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified);

@override
String toString() {
  return 'NotificationActorModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $NotificationActorModelCopyWith<$Res>  {
  factory $NotificationActorModelCopyWith(NotificationActorModel value, $Res Function(NotificationActorModel) _then) = _$NotificationActorModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class _$NotificationActorModelCopyWithImpl<$Res>
    implements $NotificationActorModelCopyWith<$Res> {
  _$NotificationActorModelCopyWithImpl(this._self, this._then);

  final NotificationActorModel _self;
  final $Res Function(NotificationActorModel) _then;

/// Create a copy of NotificationActorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationActorModel].
extension NotificationActorModelPatterns on NotificationActorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationActorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationActorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationActorModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationActorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationActorModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationActorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationActorModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified)  $default,) {final _that = this;
switch (_that) {
case _NotificationActorModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified)?  $default,) {final _that = this;
switch (_that) {
case _NotificationActorModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationActorModel extends NotificationActorModel {
  const _NotificationActorModel({required this.id, required this.displayName, required this.username, this.avatarUrl, this.isVerified = false}): super._();
  factory _NotificationActorModel.fromJson(Map<String, dynamic> json) => _$NotificationActorModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;

/// Create a copy of NotificationActorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationActorModelCopyWith<_NotificationActorModel> get copyWith => __$NotificationActorModelCopyWithImpl<_NotificationActorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationActorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationActorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified);

@override
String toString() {
  return 'NotificationActorModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$NotificationActorModelCopyWith<$Res> implements $NotificationActorModelCopyWith<$Res> {
  factory _$NotificationActorModelCopyWith(_NotificationActorModel value, $Res Function(_NotificationActorModel) _then) = __$NotificationActorModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class __$NotificationActorModelCopyWithImpl<$Res>
    implements _$NotificationActorModelCopyWith<$Res> {
  __$NotificationActorModelCopyWithImpl(this._self, this._then);

  final _NotificationActorModel _self;
  final $Res Function(_NotificationActorModel) _then;

/// Create a copy of NotificationActorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_NotificationActorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NotificationArticleModel {

 String get id; String get slug; String get title; String get language;
/// Create a copy of NotificationArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationArticleModelCopyWith<NotificationArticleModel> get copyWith => _$NotificationArticleModelCopyWithImpl<NotificationArticleModel>(this as NotificationArticleModel, _$identity);

  /// Serializes this NotificationArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language);

@override
String toString() {
  return 'NotificationArticleModel(id: $id, slug: $slug, title: $title, language: $language)';
}


}

/// @nodoc
abstract mixin class $NotificationArticleModelCopyWith<$Res>  {
  factory $NotificationArticleModelCopyWith(NotificationArticleModel value, $Res Function(NotificationArticleModel) _then) = _$NotificationArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String language
});




}
/// @nodoc
class _$NotificationArticleModelCopyWithImpl<$Res>
    implements $NotificationArticleModelCopyWith<$Res> {
  _$NotificationArticleModelCopyWithImpl(this._self, this._then);

  final NotificationArticleModel _self;
  final $Res Function(NotificationArticleModel) _then;

/// Create a copy of NotificationArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationArticleModel].
extension NotificationArticleModelPatterns on NotificationArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language)  $default,) {final _that = this;
switch (_that) {
case _NotificationArticleModel():
return $default(_that.id,_that.slug,_that.title,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String language)?  $default,) {final _that = this;
switch (_that) {
case _NotificationArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationArticleModel extends NotificationArticleModel {
  const _NotificationArticleModel({required this.id, required this.slug, required this.title, this.language = 'ar-EG'}): super._();
  factory _NotificationArticleModel.fromJson(Map<String, dynamic> json) => _$NotificationArticleModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override@JsonKey() final  String language;

/// Create a copy of NotificationArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationArticleModelCopyWith<_NotificationArticleModel> get copyWith => __$NotificationArticleModelCopyWithImpl<_NotificationArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language);

@override
String toString() {
  return 'NotificationArticleModel(id: $id, slug: $slug, title: $title, language: $language)';
}


}

/// @nodoc
abstract mixin class _$NotificationArticleModelCopyWith<$Res> implements $NotificationArticleModelCopyWith<$Res> {
  factory _$NotificationArticleModelCopyWith(_NotificationArticleModel value, $Res Function(_NotificationArticleModel) _then) = __$NotificationArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String language
});




}
/// @nodoc
class __$NotificationArticleModelCopyWithImpl<$Res>
    implements _$NotificationArticleModelCopyWith<$Res> {
  __$NotificationArticleModelCopyWithImpl(this._self, this._then);

  final _NotificationArticleModel _self;
  final $Res Function(_NotificationArticleModel) _then;

/// Create a copy of NotificationArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,}) {
  return _then(_NotificationArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationCommentModel {

 String get id; String? get parentId; String get excerpt;
/// Create a copy of NotificationCommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationCommentModelCopyWith<NotificationCommentModel> get copyWith => _$NotificationCommentModelCopyWithImpl<NotificationCommentModel>(this as NotificationCommentModel, _$identity);

  /// Serializes this NotificationCommentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,parentId,excerpt);

@override
String toString() {
  return 'NotificationCommentModel(id: $id, parentId: $parentId, excerpt: $excerpt)';
}


}

/// @nodoc
abstract mixin class $NotificationCommentModelCopyWith<$Res>  {
  factory $NotificationCommentModelCopyWith(NotificationCommentModel value, $Res Function(NotificationCommentModel) _then) = _$NotificationCommentModelCopyWithImpl;
@useResult
$Res call({
 String id, String? parentId, String excerpt
});




}
/// @nodoc
class _$NotificationCommentModelCopyWithImpl<$Res>
    implements $NotificationCommentModelCopyWith<$Res> {
  _$NotificationCommentModelCopyWithImpl(this._self, this._then);

  final NotificationCommentModel _self;
  final $Res Function(NotificationCommentModel) _then;

/// Create a copy of NotificationCommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parentId = freezed,Object? excerpt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationCommentModel].
extension NotificationCommentModelPatterns on NotificationCommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationCommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationCommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationCommentModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationCommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationCommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationCommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? parentId,  String excerpt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationCommentModel() when $default != null:
return $default(_that.id,_that.parentId,_that.excerpt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? parentId,  String excerpt)  $default,) {final _that = this;
switch (_that) {
case _NotificationCommentModel():
return $default(_that.id,_that.parentId,_that.excerpt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? parentId,  String excerpt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationCommentModel() when $default != null:
return $default(_that.id,_that.parentId,_that.excerpt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationCommentModel extends NotificationCommentModel {
  const _NotificationCommentModel({required this.id, this.parentId, this.excerpt = ''}): super._();
  factory _NotificationCommentModel.fromJson(Map<String, dynamic> json) => _$NotificationCommentModelFromJson(json);

@override final  String id;
@override final  String? parentId;
@override@JsonKey() final  String excerpt;

/// Create a copy of NotificationCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationCommentModelCopyWith<_NotificationCommentModel> get copyWith => __$NotificationCommentModelCopyWithImpl<_NotificationCommentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationCommentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,parentId,excerpt);

@override
String toString() {
  return 'NotificationCommentModel(id: $id, parentId: $parentId, excerpt: $excerpt)';
}


}

/// @nodoc
abstract mixin class _$NotificationCommentModelCopyWith<$Res> implements $NotificationCommentModelCopyWith<$Res> {
  factory _$NotificationCommentModelCopyWith(_NotificationCommentModel value, $Res Function(_NotificationCommentModel) _then) = __$NotificationCommentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? parentId, String excerpt
});




}
/// @nodoc
class __$NotificationCommentModelCopyWithImpl<$Res>
    implements _$NotificationCommentModelCopyWith<$Res> {
  __$NotificationCommentModelCopyWithImpl(this._self, this._then);

  final _NotificationCommentModel _self;
  final $Res Function(_NotificationCommentModel) _then;

/// Create a copy of NotificationCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parentId = freezed,Object? excerpt = null,}) {
  return _then(_NotificationCommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationDataModel {

 int? get threshold; int? get streakDays; Object? get securityChange; bool? get approved; int? get articleCount;// F23 `announcement`: its title and body in the UI language.
 String? get title; String? get body;// F35 `support_reply` / `support_ticket`: the ticket; `closed` when support closed it.
 int? get ticketNumber; String? get subject; bool? get closed;// F22 store additions `report_new` / `report_resolved`.
 String? get targetType; String? get targetLabel; int? get reportCount; bool? get system; String? get outcome;
/// Create a copy of NotificationDataModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationDataModelCopyWith<NotificationDataModel> get copyWith => _$NotificationDataModelCopyWithImpl<NotificationDataModel>(this as NotificationDataModel, _$identity);

  /// Serializes this NotificationDataModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationDataModel&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&const DeepCollectionEquality().equals(other.securityChange, securityChange)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.closed, closed) || other.closed == closed)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&(identical(other.system, system) || other.system == system)&&(identical(other.outcome, outcome) || other.outcome == outcome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,threshold,streakDays,const DeepCollectionEquality().hash(securityChange),approved,articleCount,title,body,ticketNumber,subject,closed,targetType,targetLabel,reportCount,system,outcome);

@override
String toString() {
  return 'NotificationDataModel(threshold: $threshold, streakDays: $streakDays, securityChange: $securityChange, approved: $approved, articleCount: $articleCount, title: $title, body: $body, ticketNumber: $ticketNumber, subject: $subject, closed: $closed, targetType: $targetType, targetLabel: $targetLabel, reportCount: $reportCount, system: $system, outcome: $outcome)';
}


}

/// @nodoc
abstract mixin class $NotificationDataModelCopyWith<$Res>  {
  factory $NotificationDataModelCopyWith(NotificationDataModel value, $Res Function(NotificationDataModel) _then) = _$NotificationDataModelCopyWithImpl;
@useResult
$Res call({
 int? threshold, int? streakDays, Object? securityChange, bool? approved, int? articleCount, String? title, String? body, int? ticketNumber, String? subject, bool? closed, String? targetType, String? targetLabel, int? reportCount, bool? system, String? outcome
});




}
/// @nodoc
class _$NotificationDataModelCopyWithImpl<$Res>
    implements $NotificationDataModelCopyWith<$Res> {
  _$NotificationDataModelCopyWithImpl(this._self, this._then);

  final NotificationDataModel _self;
  final $Res Function(NotificationDataModel) _then;

/// Create a copy of NotificationDataModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? threshold = freezed,Object? streakDays = freezed,Object? securityChange = freezed,Object? approved = freezed,Object? articleCount = freezed,Object? title = freezed,Object? body = freezed,Object? ticketNumber = freezed,Object? subject = freezed,Object? closed = freezed,Object? targetType = freezed,Object? targetLabel = freezed,Object? reportCount = freezed,Object? system = freezed,Object? outcome = freezed,}) {
  return _then(_self.copyWith(
threshold: freezed == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int?,streakDays: freezed == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int?,securityChange: freezed == securityChange ? _self.securityChange : securityChange ,approved: freezed == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool?,articleCount: freezed == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,ticketNumber: freezed == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as int?,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,closed: freezed == closed ? _self.closed : closed // ignore: cast_nullable_to_non_nullable
as bool?,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String?,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,reportCount: freezed == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int?,system: freezed == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as bool?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationDataModel].
extension NotificationDataModelPatterns on NotificationDataModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationDataModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationDataModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationDataModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationDataModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationDataModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationDataModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? threshold,  int? streakDays,  Object? securityChange,  bool? approved,  int? articleCount,  String? title,  String? body,  int? ticketNumber,  String? subject,  bool? closed,  String? targetType,  String? targetLabel,  int? reportCount,  bool? system,  String? outcome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationDataModel() when $default != null:
return $default(_that.threshold,_that.streakDays,_that.securityChange,_that.approved,_that.articleCount,_that.title,_that.body,_that.ticketNumber,_that.subject,_that.closed,_that.targetType,_that.targetLabel,_that.reportCount,_that.system,_that.outcome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? threshold,  int? streakDays,  Object? securityChange,  bool? approved,  int? articleCount,  String? title,  String? body,  int? ticketNumber,  String? subject,  bool? closed,  String? targetType,  String? targetLabel,  int? reportCount,  bool? system,  String? outcome)  $default,) {final _that = this;
switch (_that) {
case _NotificationDataModel():
return $default(_that.threshold,_that.streakDays,_that.securityChange,_that.approved,_that.articleCount,_that.title,_that.body,_that.ticketNumber,_that.subject,_that.closed,_that.targetType,_that.targetLabel,_that.reportCount,_that.system,_that.outcome);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? threshold,  int? streakDays,  Object? securityChange,  bool? approved,  int? articleCount,  String? title,  String? body,  int? ticketNumber,  String? subject,  bool? closed,  String? targetType,  String? targetLabel,  int? reportCount,  bool? system,  String? outcome)?  $default,) {final _that = this;
switch (_that) {
case _NotificationDataModel() when $default != null:
return $default(_that.threshold,_that.streakDays,_that.securityChange,_that.approved,_that.articleCount,_that.title,_that.body,_that.ticketNumber,_that.subject,_that.closed,_that.targetType,_that.targetLabel,_that.reportCount,_that.system,_that.outcome);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationDataModel implements NotificationDataModel {
  const _NotificationDataModel({this.threshold, this.streakDays, this.securityChange, this.approved, this.articleCount, this.title, this.body, this.ticketNumber, this.subject, this.closed, this.targetType, this.targetLabel, this.reportCount, this.system, this.outcome});
  factory _NotificationDataModel.fromJson(Map<String, dynamic> json) => _$NotificationDataModelFromJson(json);

@override final  int? threshold;
@override final  int? streakDays;
@override final  Object? securityChange;
@override final  bool? approved;
@override final  int? articleCount;
// F23 `announcement`: its title and body in the UI language.
@override final  String? title;
@override final  String? body;
// F35 `support_reply` / `support_ticket`: the ticket; `closed` when support closed it.
@override final  int? ticketNumber;
@override final  String? subject;
@override final  bool? closed;
// F22 store additions `report_new` / `report_resolved`.
@override final  String? targetType;
@override final  String? targetLabel;
@override final  int? reportCount;
@override final  bool? system;
@override final  String? outcome;

/// Create a copy of NotificationDataModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationDataModelCopyWith<_NotificationDataModel> get copyWith => __$NotificationDataModelCopyWithImpl<_NotificationDataModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationDataModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationDataModel&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&const DeepCollectionEquality().equals(other.securityChange, securityChange)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.ticketNumber, ticketNumber) || other.ticketNumber == ticketNumber)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.closed, closed) || other.closed == closed)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&(identical(other.system, system) || other.system == system)&&(identical(other.outcome, outcome) || other.outcome == outcome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,threshold,streakDays,const DeepCollectionEquality().hash(securityChange),approved,articleCount,title,body,ticketNumber,subject,closed,targetType,targetLabel,reportCount,system,outcome);

@override
String toString() {
  return 'NotificationDataModel(threshold: $threshold, streakDays: $streakDays, securityChange: $securityChange, approved: $approved, articleCount: $articleCount, title: $title, body: $body, ticketNumber: $ticketNumber, subject: $subject, closed: $closed, targetType: $targetType, targetLabel: $targetLabel, reportCount: $reportCount, system: $system, outcome: $outcome)';
}


}

/// @nodoc
abstract mixin class _$NotificationDataModelCopyWith<$Res> implements $NotificationDataModelCopyWith<$Res> {
  factory _$NotificationDataModelCopyWith(_NotificationDataModel value, $Res Function(_NotificationDataModel) _then) = __$NotificationDataModelCopyWithImpl;
@override @useResult
$Res call({
 int? threshold, int? streakDays, Object? securityChange, bool? approved, int? articleCount, String? title, String? body, int? ticketNumber, String? subject, bool? closed, String? targetType, String? targetLabel, int? reportCount, bool? system, String? outcome
});




}
/// @nodoc
class __$NotificationDataModelCopyWithImpl<$Res>
    implements _$NotificationDataModelCopyWith<$Res> {
  __$NotificationDataModelCopyWithImpl(this._self, this._then);

  final _NotificationDataModel _self;
  final $Res Function(_NotificationDataModel) _then;

/// Create a copy of NotificationDataModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? threshold = freezed,Object? streakDays = freezed,Object? securityChange = freezed,Object? approved = freezed,Object? articleCount = freezed,Object? title = freezed,Object? body = freezed,Object? ticketNumber = freezed,Object? subject = freezed,Object? closed = freezed,Object? targetType = freezed,Object? targetLabel = freezed,Object? reportCount = freezed,Object? system = freezed,Object? outcome = freezed,}) {
  return _then(_NotificationDataModel(
threshold: freezed == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int?,streakDays: freezed == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int?,securityChange: freezed == securityChange ? _self.securityChange : securityChange ,approved: freezed == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool?,articleCount: freezed == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,ticketNumber: freezed == ticketNumber ? _self.ticketNumber : ticketNumber // ignore: cast_nullable_to_non_nullable
as int?,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,closed: freezed == closed ? _self.closed : closed // ignore: cast_nullable_to_non_nullable
as bool?,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String?,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,reportCount: freezed == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int?,system: freezed == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as bool?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NotificationModel {

 String get id; String get type; DateTime get createdAt; DateTime get updatedAt; bool get isRead; NotificationActorModel? get actor; int get actorCount; NotificationArticleModel? get article; NotificationCommentModel? get comment; NotificationDataModel? get data; String get link;
/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationModelCopyWith<NotificationModel> get copyWith => _$NotificationModelCopyWithImpl<NotificationModel>(this as NotificationModel, _$identity);

  /// Serializes this NotificationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.actorCount, actorCount) || other.actorCount == actorCount)&&(identical(other.article, article) || other.article == article)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.data, data) || other.data == data)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,createdAt,updatedAt,isRead,actor,actorCount,article,comment,data,link);

@override
String toString() {
  return 'NotificationModel(id: $id, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, isRead: $isRead, actor: $actor, actorCount: $actorCount, article: $article, comment: $comment, data: $data, link: $link)';
}


}

/// @nodoc
abstract mixin class $NotificationModelCopyWith<$Res>  {
  factory $NotificationModelCopyWith(NotificationModel value, $Res Function(NotificationModel) _then) = _$NotificationModelCopyWithImpl;
@useResult
$Res call({
 String id, String type, DateTime createdAt, DateTime updatedAt, bool isRead, NotificationActorModel? actor, int actorCount, NotificationArticleModel? article, NotificationCommentModel? comment, NotificationDataModel? data, String link
});


$NotificationActorModelCopyWith<$Res>? get actor;$NotificationArticleModelCopyWith<$Res>? get article;$NotificationCommentModelCopyWith<$Res>? get comment;$NotificationDataModelCopyWith<$Res>? get data;

}
/// @nodoc
class _$NotificationModelCopyWithImpl<$Res>
    implements $NotificationModelCopyWith<$Res> {
  _$NotificationModelCopyWithImpl(this._self, this._then);

  final NotificationModel _self;
  final $Res Function(NotificationModel) _then;

/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,Object? isRead = null,Object? actor = freezed,Object? actorCount = null,Object? article = freezed,Object? comment = freezed,Object? data = freezed,Object? link = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as NotificationActorModel?,actorCount: null == actorCount ? _self.actorCount : actorCount // ignore: cast_nullable_to_non_nullable
as int,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as NotificationArticleModel?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as NotificationCommentModel?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NotificationDataModel?,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationActorModelCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $NotificationActorModelCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationArticleModelCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $NotificationArticleModelCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationCommentModelCopyWith<$Res>? get comment {
    if (_self.comment == null) {
    return null;
  }

  return $NotificationCommentModelCopyWith<$Res>(_self.comment!, (value) {
    return _then(_self.copyWith(comment: value));
  });
}/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationDataModelCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $NotificationDataModelCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationModel].
extension NotificationModelPatterns on NotificationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  DateTime createdAt,  DateTime updatedAt,  bool isRead,  NotificationActorModel? actor,  int actorCount,  NotificationArticleModel? article,  NotificationCommentModel? comment,  NotificationDataModel? data,  String link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationModel() when $default != null:
return $default(_that.id,_that.type,_that.createdAt,_that.updatedAt,_that.isRead,_that.actor,_that.actorCount,_that.article,_that.comment,_that.data,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  DateTime createdAt,  DateTime updatedAt,  bool isRead,  NotificationActorModel? actor,  int actorCount,  NotificationArticleModel? article,  NotificationCommentModel? comment,  NotificationDataModel? data,  String link)  $default,) {final _that = this;
switch (_that) {
case _NotificationModel():
return $default(_that.id,_that.type,_that.createdAt,_that.updatedAt,_that.isRead,_that.actor,_that.actorCount,_that.article,_that.comment,_that.data,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  DateTime createdAt,  DateTime updatedAt,  bool isRead,  NotificationActorModel? actor,  int actorCount,  NotificationArticleModel? article,  NotificationCommentModel? comment,  NotificationDataModel? data,  String link)?  $default,) {final _that = this;
switch (_that) {
case _NotificationModel() when $default != null:
return $default(_that.id,_that.type,_that.createdAt,_that.updatedAt,_that.isRead,_that.actor,_that.actorCount,_that.article,_that.comment,_that.data,_that.link);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationModel extends NotificationModel {
  const _NotificationModel({required this.id, required this.type, required this.createdAt, required this.updatedAt, this.isRead = false, this.actor, this.actorCount = 0, this.article, this.comment, this.data, this.link = ''}): super._();
  factory _NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);

@override final  String id;
@override final  String type;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isRead;
@override final  NotificationActorModel? actor;
@override@JsonKey() final  int actorCount;
@override final  NotificationArticleModel? article;
@override final  NotificationCommentModel? comment;
@override final  NotificationDataModel? data;
@override@JsonKey() final  String link;

/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationModelCopyWith<_NotificationModel> get copyWith => __$NotificationModelCopyWithImpl<_NotificationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.actorCount, actorCount) || other.actorCount == actorCount)&&(identical(other.article, article) || other.article == article)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.data, data) || other.data == data)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,createdAt,updatedAt,isRead,actor,actorCount,article,comment,data,link);

@override
String toString() {
  return 'NotificationModel(id: $id, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, isRead: $isRead, actor: $actor, actorCount: $actorCount, article: $article, comment: $comment, data: $data, link: $link)';
}


}

/// @nodoc
abstract mixin class _$NotificationModelCopyWith<$Res> implements $NotificationModelCopyWith<$Res> {
  factory _$NotificationModelCopyWith(_NotificationModel value, $Res Function(_NotificationModel) _then) = __$NotificationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, DateTime createdAt, DateTime updatedAt, bool isRead, NotificationActorModel? actor, int actorCount, NotificationArticleModel? article, NotificationCommentModel? comment, NotificationDataModel? data, String link
});


@override $NotificationActorModelCopyWith<$Res>? get actor;@override $NotificationArticleModelCopyWith<$Res>? get article;@override $NotificationCommentModelCopyWith<$Res>? get comment;@override $NotificationDataModelCopyWith<$Res>? get data;

}
/// @nodoc
class __$NotificationModelCopyWithImpl<$Res>
    implements _$NotificationModelCopyWith<$Res> {
  __$NotificationModelCopyWithImpl(this._self, this._then);

  final _NotificationModel _self;
  final $Res Function(_NotificationModel) _then;

/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,Object? isRead = null,Object? actor = freezed,Object? actorCount = null,Object? article = freezed,Object? comment = freezed,Object? data = freezed,Object? link = null,}) {
  return _then(_NotificationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as NotificationActorModel?,actorCount: null == actorCount ? _self.actorCount : actorCount // ignore: cast_nullable_to_non_nullable
as int,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as NotificationArticleModel?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as NotificationCommentModel?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NotificationDataModel?,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationActorModelCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $NotificationActorModelCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationArticleModelCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $NotificationArticleModelCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationCommentModelCopyWith<$Res>? get comment {
    if (_self.comment == null) {
    return null;
  }

  return $NotificationCommentModelCopyWith<$Res>(_self.comment!, (value) {
    return _then(_self.copyWith(comment: value));
  });
}/// Create a copy of NotificationModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationDataModelCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $NotificationDataModelCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$NotificationPageModel {

 List<NotificationModel> get items; String? get nextCursor;
/// Create a copy of NotificationPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPageModelCopyWith<NotificationPageModel> get copyWith => _$NotificationPageModelCopyWithImpl<NotificationPageModel>(this as NotificationPageModel, _$identity);

  /// Serializes this NotificationPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'NotificationPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $NotificationPageModelCopyWith<$Res>  {
  factory $NotificationPageModelCopyWith(NotificationPageModel value, $Res Function(NotificationPageModel) _then) = _$NotificationPageModelCopyWithImpl;
@useResult
$Res call({
 List<NotificationModel> items, String? nextCursor
});




}
/// @nodoc
class _$NotificationPageModelCopyWithImpl<$Res>
    implements $NotificationPageModelCopyWith<$Res> {
  _$NotificationPageModelCopyWithImpl(this._self, this._then);

  final NotificationPageModel _self;
  final $Res Function(NotificationPageModel) _then;

/// Create a copy of NotificationPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPageModel].
extension NotificationPageModelPatterns on NotificationPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPageModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _NotificationPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPageModel implements NotificationPageModel {
  const _NotificationPageModel({final  List<NotificationModel> items = const <NotificationModel>[], this.nextCursor}): _items = items;
  factory _NotificationPageModel.fromJson(Map<String, dynamic> json) => _$NotificationPageModelFromJson(json);

 final  List<NotificationModel> _items;
@override@JsonKey() List<NotificationModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of NotificationPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPageModelCopyWith<_NotificationPageModel> get copyWith => __$NotificationPageModelCopyWithImpl<_NotificationPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'NotificationPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$NotificationPageModelCopyWith<$Res> implements $NotificationPageModelCopyWith<$Res> {
  factory _$NotificationPageModelCopyWith(_NotificationPageModel value, $Res Function(_NotificationPageModel) _then) = __$NotificationPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationModel> items, String? nextCursor
});




}
/// @nodoc
class __$NotificationPageModelCopyWithImpl<$Res>
    implements _$NotificationPageModelCopyWith<$Res> {
  __$NotificationPageModelCopyWithImpl(this._self, this._then);

  final _NotificationPageModel _self;
  final $Res Function(_NotificationPageModel) _then;

/// Create a copy of NotificationPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_NotificationPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UnreadCountModel {

 int get unread;
/// Create a copy of UnreadCountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnreadCountModelCopyWith<UnreadCountModel> get copyWith => _$UnreadCountModelCopyWithImpl<UnreadCountModel>(this as UnreadCountModel, _$identity);

  /// Serializes this UnreadCountModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadCountModel&&(identical(other.unread, unread) || other.unread == unread));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unread);

@override
String toString() {
  return 'UnreadCountModel(unread: $unread)';
}


}

/// @nodoc
abstract mixin class $UnreadCountModelCopyWith<$Res>  {
  factory $UnreadCountModelCopyWith(UnreadCountModel value, $Res Function(UnreadCountModel) _then) = _$UnreadCountModelCopyWithImpl;
@useResult
$Res call({
 int unread
});




}
/// @nodoc
class _$UnreadCountModelCopyWithImpl<$Res>
    implements $UnreadCountModelCopyWith<$Res> {
  _$UnreadCountModelCopyWithImpl(this._self, this._then);

  final UnreadCountModel _self;
  final $Res Function(UnreadCountModel) _then;

/// Create a copy of UnreadCountModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unread = null,}) {
  return _then(_self.copyWith(
unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UnreadCountModel].
extension UnreadCountModelPatterns on UnreadCountModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnreadCountModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnreadCountModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnreadCountModel value)  $default,){
final _that = this;
switch (_that) {
case _UnreadCountModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnreadCountModel value)?  $default,){
final _that = this;
switch (_that) {
case _UnreadCountModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int unread)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnreadCountModel() when $default != null:
return $default(_that.unread);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int unread)  $default,) {final _that = this;
switch (_that) {
case _UnreadCountModel():
return $default(_that.unread);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int unread)?  $default,) {final _that = this;
switch (_that) {
case _UnreadCountModel() when $default != null:
return $default(_that.unread);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnreadCountModel implements UnreadCountModel {
  const _UnreadCountModel({this.unread = 0});
  factory _UnreadCountModel.fromJson(Map<String, dynamic> json) => _$UnreadCountModelFromJson(json);

@override@JsonKey() final  int unread;

/// Create a copy of UnreadCountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnreadCountModelCopyWith<_UnreadCountModel> get copyWith => __$UnreadCountModelCopyWithImpl<_UnreadCountModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnreadCountModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnreadCountModel&&(identical(other.unread, unread) || other.unread == unread));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unread);

@override
String toString() {
  return 'UnreadCountModel(unread: $unread)';
}


}

/// @nodoc
abstract mixin class _$UnreadCountModelCopyWith<$Res> implements $UnreadCountModelCopyWith<$Res> {
  factory _$UnreadCountModelCopyWith(_UnreadCountModel value, $Res Function(_UnreadCountModel) _then) = __$UnreadCountModelCopyWithImpl;
@override @useResult
$Res call({
 int unread
});




}
/// @nodoc
class __$UnreadCountModelCopyWithImpl<$Res>
    implements _$UnreadCountModelCopyWith<$Res> {
  __$UnreadCountModelCopyWithImpl(this._self, this._then);

  final _UnreadCountModel _self;
  final $Res Function(_UnreadCountModel) _then;

/// Create a copy of UnreadCountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unread = null,}) {
  return _then(_UnreadCountModel(
unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QuietHoursModel {

 bool get enabled; String get start; String get end;
/// Create a copy of QuietHoursModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuietHoursModelCopyWith<QuietHoursModel> get copyWith => _$QuietHoursModelCopyWithImpl<QuietHoursModel>(this as QuietHoursModel, _$identity);

  /// Serializes this QuietHoursModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuietHoursModel&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,start,end);

@override
String toString() {
  return 'QuietHoursModel(enabled: $enabled, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $QuietHoursModelCopyWith<$Res>  {
  factory $QuietHoursModelCopyWith(QuietHoursModel value, $Res Function(QuietHoursModel) _then) = _$QuietHoursModelCopyWithImpl;
@useResult
$Res call({
 bool enabled, String start, String end
});




}
/// @nodoc
class _$QuietHoursModelCopyWithImpl<$Res>
    implements $QuietHoursModelCopyWith<$Res> {
  _$QuietHoursModelCopyWithImpl(this._self, this._then);

  final QuietHoursModel _self;
  final $Res Function(QuietHoursModel) _then;

/// Create a copy of QuietHoursModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? start = null,Object? end = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuietHoursModel].
extension QuietHoursModelPatterns on QuietHoursModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuietHoursModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuietHoursModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuietHoursModel value)  $default,){
final _that = this;
switch (_that) {
case _QuietHoursModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuietHoursModel value)?  $default,){
final _that = this;
switch (_that) {
case _QuietHoursModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String start,  String end)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuietHoursModel() when $default != null:
return $default(_that.enabled,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String start,  String end)  $default,) {final _that = this;
switch (_that) {
case _QuietHoursModel():
return $default(_that.enabled,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String start,  String end)?  $default,) {final _that = this;
switch (_that) {
case _QuietHoursModel() when $default != null:
return $default(_that.enabled,_that.start,_that.end);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuietHoursModel implements QuietHoursModel {
  const _QuietHoursModel({this.enabled = true, this.start = '23:00', this.end = '07:00'});
  factory _QuietHoursModel.fromJson(Map<String, dynamic> json) => _$QuietHoursModelFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String start;
@override@JsonKey() final  String end;

/// Create a copy of QuietHoursModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuietHoursModelCopyWith<_QuietHoursModel> get copyWith => __$QuietHoursModelCopyWithImpl<_QuietHoursModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuietHoursModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuietHoursModel&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,start,end);

@override
String toString() {
  return 'QuietHoursModel(enabled: $enabled, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class _$QuietHoursModelCopyWith<$Res> implements $QuietHoursModelCopyWith<$Res> {
  factory _$QuietHoursModelCopyWith(_QuietHoursModel value, $Res Function(_QuietHoursModel) _then) = __$QuietHoursModelCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String start, String end
});




}
/// @nodoc
class __$QuietHoursModelCopyWithImpl<$Res>
    implements _$QuietHoursModelCopyWith<$Res> {
  __$QuietHoursModelCopyWithImpl(this._self, this._then);

  final _QuietHoursModel _self;
  final $Res Function(_QuietHoursModel) _then;

/// Create a copy of QuietHoursModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? start = null,Object? end = null,}) {
  return _then(_QuietHoursModel(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationSettingsModel {

 QuietHoursModel get quietHours; Map<String, String> get types;
/// Create a copy of NotificationSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingsModelCopyWith<NotificationSettingsModel> get copyWith => _$NotificationSettingsModelCopyWithImpl<NotificationSettingsModel>(this as NotificationSettingsModel, _$identity);

  /// Serializes this NotificationSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettingsModel&&(identical(other.quietHours, quietHours) || other.quietHours == quietHours)&&const DeepCollectionEquality().equals(other.types, types));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quietHours,const DeepCollectionEquality().hash(types));

@override
String toString() {
  return 'NotificationSettingsModel(quietHours: $quietHours, types: $types)';
}


}

/// @nodoc
abstract mixin class $NotificationSettingsModelCopyWith<$Res>  {
  factory $NotificationSettingsModelCopyWith(NotificationSettingsModel value, $Res Function(NotificationSettingsModel) _then) = _$NotificationSettingsModelCopyWithImpl;
@useResult
$Res call({
 QuietHoursModel quietHours, Map<String, String> types
});


$QuietHoursModelCopyWith<$Res> get quietHours;

}
/// @nodoc
class _$NotificationSettingsModelCopyWithImpl<$Res>
    implements $NotificationSettingsModelCopyWith<$Res> {
  _$NotificationSettingsModelCopyWithImpl(this._self, this._then);

  final NotificationSettingsModel _self;
  final $Res Function(NotificationSettingsModel) _then;

/// Create a copy of NotificationSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quietHours = null,Object? types = null,}) {
  return _then(_self.copyWith(
quietHours: null == quietHours ? _self.quietHours : quietHours // ignore: cast_nullable_to_non_nullable
as QuietHoursModel,types: null == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of NotificationSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuietHoursModelCopyWith<$Res> get quietHours {
  
  return $QuietHoursModelCopyWith<$Res>(_self.quietHours, (value) {
    return _then(_self.copyWith(quietHours: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationSettingsModel].
extension NotificationSettingsModelPatterns on NotificationSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QuietHoursModel quietHours,  Map<String, String> types)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettingsModel() when $default != null:
return $default(_that.quietHours,_that.types);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QuietHoursModel quietHours,  Map<String, String> types)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettingsModel():
return $default(_that.quietHours,_that.types);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QuietHoursModel quietHours,  Map<String, String> types)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettingsModel() when $default != null:
return $default(_that.quietHours,_that.types);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationSettingsModel extends NotificationSettingsModel {
  const _NotificationSettingsModel({this.quietHours = const QuietHoursModel(), final  Map<String, String> types = const <String, String>{}}): _types = types,super._();
  factory _NotificationSettingsModel.fromJson(Map<String, dynamic> json) => _$NotificationSettingsModelFromJson(json);

@override@JsonKey() final  QuietHoursModel quietHours;
 final  Map<String, String> _types;
@override@JsonKey() Map<String, String> get types {
  if (_types is EqualUnmodifiableMapView) return _types;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_types);
}


/// Create a copy of NotificationSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingsModelCopyWith<_NotificationSettingsModel> get copyWith => __$NotificationSettingsModelCopyWithImpl<_NotificationSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettingsModel&&(identical(other.quietHours, quietHours) || other.quietHours == quietHours)&&const DeepCollectionEquality().equals(other._types, _types));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quietHours,const DeepCollectionEquality().hash(_types));

@override
String toString() {
  return 'NotificationSettingsModel(quietHours: $quietHours, types: $types)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingsModelCopyWith<$Res> implements $NotificationSettingsModelCopyWith<$Res> {
  factory _$NotificationSettingsModelCopyWith(_NotificationSettingsModel value, $Res Function(_NotificationSettingsModel) _then) = __$NotificationSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 QuietHoursModel quietHours, Map<String, String> types
});


@override $QuietHoursModelCopyWith<$Res> get quietHours;

}
/// @nodoc
class __$NotificationSettingsModelCopyWithImpl<$Res>
    implements _$NotificationSettingsModelCopyWith<$Res> {
  __$NotificationSettingsModelCopyWithImpl(this._self, this._then);

  final _NotificationSettingsModel _self;
  final $Res Function(_NotificationSettingsModel) _then;

/// Create a copy of NotificationSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quietHours = null,Object? types = null,}) {
  return _then(_NotificationSettingsModel(
quietHours: null == quietHours ? _self.quietHours : quietHours // ignore: cast_nullable_to_non_nullable
as QuietHoursModel,types: null == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of NotificationSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuietHoursModelCopyWith<$Res> get quietHours {
  
  return $QuietHoursModelCopyWith<$Res>(_self.quietHours, (value) {
    return _then(_self.copyWith(quietHours: value));
  });
}
}

// dart format on
