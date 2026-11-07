// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthorModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified;// F14: the writer's title; blank is treated as none.
 String? get headline;
/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<AuthorModel> get copyWith => _$AuthorModelCopyWithImpl<AuthorModel>(this as AuthorModel, _$identity);

  /// Serializes this AuthorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified,headline);

@override
String toString() {
  return 'AuthorModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, headline: $headline)';
}


}

/// @nodoc
abstract mixin class $AuthorModelCopyWith<$Res>  {
  factory $AuthorModelCopyWith(AuthorModel value, $Res Function(AuthorModel) _then) = _$AuthorModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, String? headline
});




}
/// @nodoc
class _$AuthorModelCopyWithImpl<$Res>
    implements $AuthorModelCopyWith<$Res> {
  _$AuthorModelCopyWithImpl(this._self, this._then);

  final AuthorModel _self;
  final $Res Function(AuthorModel) _then;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? headline = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthorModel].
extension AuthorModelPatterns on AuthorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthorModel value)  $default,){
final _that = this;
switch (_that) {
case _AuthorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthorModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? headline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.headline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? headline)  $default,) {final _that = this;
switch (_that) {
case _AuthorModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.headline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? headline)?  $default,) {final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.headline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthorModel extends AuthorModel {
  const _AuthorModel({required this.id, required this.displayName, required this.username, this.avatarUrl, this.isVerified = false, this.headline}): super._();
  factory _AuthorModel.fromJson(Map<String, dynamic> json) => _$AuthorModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;
// F14: the writer's title; blank is treated as none.
@override final  String? headline;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthorModelCopyWith<_AuthorModel> get copyWith => __$AuthorModelCopyWithImpl<_AuthorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified,headline);

@override
String toString() {
  return 'AuthorModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, headline: $headline)';
}


}

/// @nodoc
abstract mixin class _$AuthorModelCopyWith<$Res> implements $AuthorModelCopyWith<$Res> {
  factory _$AuthorModelCopyWith(_AuthorModel value, $Res Function(_AuthorModel) _then) = __$AuthorModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, String? headline
});




}
/// @nodoc
class __$AuthorModelCopyWithImpl<$Res>
    implements _$AuthorModelCopyWith<$Res> {
  __$AuthorModelCopyWithImpl(this._self, this._then);

  final _AuthorModel _self;
  final $Res Function(_AuthorModel) _then;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? headline = freezed,}) {
  return _then(_AuthorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RepostLabelModel {

 AuthorModel get user; int get othersCount; DateTime get repostedAt;// `user`'s thoughts on it; missing, null or blank is none.
 String? get caption;
/// Create a copy of RepostLabelModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepostLabelModelCopyWith<RepostLabelModel> get copyWith => _$RepostLabelModelCopyWithImpl<RepostLabelModel>(this as RepostLabelModel, _$identity);

  /// Serializes this RepostLabelModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepostLabelModel&&(identical(other.user, user) || other.user == user)&&(identical(other.othersCount, othersCount) || other.othersCount == othersCount)&&(identical(other.repostedAt, repostedAt) || other.repostedAt == repostedAt)&&(identical(other.caption, caption) || other.caption == caption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,othersCount,repostedAt,caption);

@override
String toString() {
  return 'RepostLabelModel(user: $user, othersCount: $othersCount, repostedAt: $repostedAt, caption: $caption)';
}


}

/// @nodoc
abstract mixin class $RepostLabelModelCopyWith<$Res>  {
  factory $RepostLabelModelCopyWith(RepostLabelModel value, $Res Function(RepostLabelModel) _then) = _$RepostLabelModelCopyWithImpl;
@useResult
$Res call({
 AuthorModel user, int othersCount, DateTime repostedAt, String? caption
});


$AuthorModelCopyWith<$Res> get user;

}
/// @nodoc
class _$RepostLabelModelCopyWithImpl<$Res>
    implements $RepostLabelModelCopyWith<$Res> {
  _$RepostLabelModelCopyWithImpl(this._self, this._then);

  final RepostLabelModel _self;
  final $Res Function(RepostLabelModel) _then;

/// Create a copy of RepostLabelModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? othersCount = null,Object? repostedAt = null,Object? caption = freezed,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthorModel,othersCount: null == othersCount ? _self.othersCount : othersCount // ignore: cast_nullable_to_non_nullable
as int,repostedAt: null == repostedAt ? _self.repostedAt : repostedAt // ignore: cast_nullable_to_non_nullable
as DateTime,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RepostLabelModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get user {
  
  return $AuthorModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [RepostLabelModel].
extension RepostLabelModelPatterns on RepostLabelModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepostLabelModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepostLabelModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepostLabelModel value)  $default,){
final _that = this;
switch (_that) {
case _RepostLabelModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepostLabelModel value)?  $default,){
final _that = this;
switch (_that) {
case _RepostLabelModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthorModel user,  int othersCount,  DateTime repostedAt,  String? caption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepostLabelModel() when $default != null:
return $default(_that.user,_that.othersCount,_that.repostedAt,_that.caption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthorModel user,  int othersCount,  DateTime repostedAt,  String? caption)  $default,) {final _that = this;
switch (_that) {
case _RepostLabelModel():
return $default(_that.user,_that.othersCount,_that.repostedAt,_that.caption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthorModel user,  int othersCount,  DateTime repostedAt,  String? caption)?  $default,) {final _that = this;
switch (_that) {
case _RepostLabelModel() when $default != null:
return $default(_that.user,_that.othersCount,_that.repostedAt,_that.caption);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RepostLabelModel extends RepostLabelModel {
  const _RepostLabelModel({required this.user, this.othersCount = 0, required this.repostedAt, this.caption}): super._();
  factory _RepostLabelModel.fromJson(Map<String, dynamic> json) => _$RepostLabelModelFromJson(json);

@override final  AuthorModel user;
@override@JsonKey() final  int othersCount;
@override final  DateTime repostedAt;
// `user`'s thoughts on it; missing, null or blank is none.
@override final  String? caption;

/// Create a copy of RepostLabelModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepostLabelModelCopyWith<_RepostLabelModel> get copyWith => __$RepostLabelModelCopyWithImpl<_RepostLabelModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepostLabelModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepostLabelModel&&(identical(other.user, user) || other.user == user)&&(identical(other.othersCount, othersCount) || other.othersCount == othersCount)&&(identical(other.repostedAt, repostedAt) || other.repostedAt == repostedAt)&&(identical(other.caption, caption) || other.caption == caption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,othersCount,repostedAt,caption);

@override
String toString() {
  return 'RepostLabelModel(user: $user, othersCount: $othersCount, repostedAt: $repostedAt, caption: $caption)';
}


}

/// @nodoc
abstract mixin class _$RepostLabelModelCopyWith<$Res> implements $RepostLabelModelCopyWith<$Res> {
  factory _$RepostLabelModelCopyWith(_RepostLabelModel value, $Res Function(_RepostLabelModel) _then) = __$RepostLabelModelCopyWithImpl;
@override @useResult
$Res call({
 AuthorModel user, int othersCount, DateTime repostedAt, String? caption
});


@override $AuthorModelCopyWith<$Res> get user;

}
/// @nodoc
class __$RepostLabelModelCopyWithImpl<$Res>
    implements _$RepostLabelModelCopyWith<$Res> {
  __$RepostLabelModelCopyWithImpl(this._self, this._then);

  final _RepostLabelModel _self;
  final $Res Function(_RepostLabelModel) _then;

/// Create a copy of RepostLabelModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? othersCount = null,Object? repostedAt = null,Object? caption = freezed,}) {
  return _then(_RepostLabelModel(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthorModel,othersCount: null == othersCount ? _self.othersCount : othersCount // ignore: cast_nullable_to_non_nullable
as int,repostedAt: null == repostedAt ? _self.repostedAt : repostedAt // ignore: cast_nullable_to_non_nullable
as DateTime,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RepostLabelModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get user {
  
  return $AuthorModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$FieldRefModel {

 String get id; String get slug; String get nameAr; String get nameEn; String? get name; bool get isSensitive;
/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<FieldRefModel> get copyWith => _$FieldRefModelCopyWithImpl<FieldRefModel>(this as FieldRefModel, _$identity);

  /// Serializes this FieldRefModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldRefModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,nameAr,nameEn,name,isSensitive);

@override
String toString() {
  return 'FieldRefModel(id: $id, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name, isSensitive: $isSensitive)';
}


}

/// @nodoc
abstract mixin class $FieldRefModelCopyWith<$Res>  {
  factory $FieldRefModelCopyWith(FieldRefModel value, $Res Function(FieldRefModel) _then) = _$FieldRefModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String nameAr, String nameEn, String? name, bool isSensitive
});




}
/// @nodoc
class _$FieldRefModelCopyWithImpl<$Res>
    implements $FieldRefModelCopyWith<$Res> {
  _$FieldRefModelCopyWithImpl(this._self, this._then);

  final FieldRefModel _self;
  final $Res Function(FieldRefModel) _then;

/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,Object? isSensitive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldRefModel].
extension FieldRefModelPatterns on FieldRefModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldRefModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldRefModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldRefModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldRefModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String nameAr,  String nameEn,  String? name,  bool isSensitive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name,_that.isSensitive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String nameAr,  String nameEn,  String? name,  bool isSensitive)  $default,) {final _that = this;
switch (_that) {
case _FieldRefModel():
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name,_that.isSensitive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String nameAr,  String nameEn,  String? name,  bool isSensitive)?  $default,) {final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name,_that.isSensitive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldRefModel extends FieldRefModel {
  const _FieldRefModel({required this.id, required this.slug, required this.nameAr, required this.nameEn, this.name, this.isSensitive = false}): super._();
  factory _FieldRefModel.fromJson(Map<String, dynamic> json) => _$FieldRefModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String nameAr;
@override final  String nameEn;
@override final  String? name;
@override@JsonKey() final  bool isSensitive;

/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldRefModelCopyWith<_FieldRefModel> get copyWith => __$FieldRefModelCopyWithImpl<_FieldRefModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldRefModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldRefModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,nameAr,nameEn,name,isSensitive);

@override
String toString() {
  return 'FieldRefModel(id: $id, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name, isSensitive: $isSensitive)';
}


}

/// @nodoc
abstract mixin class _$FieldRefModelCopyWith<$Res> implements $FieldRefModelCopyWith<$Res> {
  factory _$FieldRefModelCopyWith(_FieldRefModel value, $Res Function(_FieldRefModel) _then) = __$FieldRefModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String nameAr, String nameEn, String? name, bool isSensitive
});




}
/// @nodoc
class __$FieldRefModelCopyWithImpl<$Res>
    implements _$FieldRefModelCopyWith<$Res> {
  __$FieldRefModelCopyWithImpl(this._self, this._then);

  final _FieldRefModel _self;
  final $Res Function(_FieldRefModel) _then;

/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,Object? isSensitive = null,}) {
  return _then(_FieldRefModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ReactionCountsModel {

 int get insightful; int get love; int get fire; int get mindBlown;
/// Create a copy of ReactionCountsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<ReactionCountsModel> get copyWith => _$ReactionCountsModelCopyWithImpl<ReactionCountsModel>(this as ReactionCountsModel, _$identity);

  /// Serializes this ReactionCountsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactionCountsModel&&(identical(other.insightful, insightful) || other.insightful == insightful)&&(identical(other.love, love) || other.love == love)&&(identical(other.fire, fire) || other.fire == fire)&&(identical(other.mindBlown, mindBlown) || other.mindBlown == mindBlown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,insightful,love,fire,mindBlown);

@override
String toString() {
  return 'ReactionCountsModel(insightful: $insightful, love: $love, fire: $fire, mindBlown: $mindBlown)';
}


}

/// @nodoc
abstract mixin class $ReactionCountsModelCopyWith<$Res>  {
  factory $ReactionCountsModelCopyWith(ReactionCountsModel value, $Res Function(ReactionCountsModel) _then) = _$ReactionCountsModelCopyWithImpl;
@useResult
$Res call({
 int insightful, int love, int fire, int mindBlown
});




}
/// @nodoc
class _$ReactionCountsModelCopyWithImpl<$Res>
    implements $ReactionCountsModelCopyWith<$Res> {
  _$ReactionCountsModelCopyWithImpl(this._self, this._then);

  final ReactionCountsModel _self;
  final $Res Function(ReactionCountsModel) _then;

/// Create a copy of ReactionCountsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? insightful = null,Object? love = null,Object? fire = null,Object? mindBlown = null,}) {
  return _then(_self.copyWith(
insightful: null == insightful ? _self.insightful : insightful // ignore: cast_nullable_to_non_nullable
as int,love: null == love ? _self.love : love // ignore: cast_nullable_to_non_nullable
as int,fire: null == fire ? _self.fire : fire // ignore: cast_nullable_to_non_nullable
as int,mindBlown: null == mindBlown ? _self.mindBlown : mindBlown // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReactionCountsModel].
extension ReactionCountsModelPatterns on ReactionCountsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReactionCountsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReactionCountsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReactionCountsModel value)  $default,){
final _that = this;
switch (_that) {
case _ReactionCountsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReactionCountsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReactionCountsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int insightful,  int love,  int fire,  int mindBlown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReactionCountsModel() when $default != null:
return $default(_that.insightful,_that.love,_that.fire,_that.mindBlown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int insightful,  int love,  int fire,  int mindBlown)  $default,) {final _that = this;
switch (_that) {
case _ReactionCountsModel():
return $default(_that.insightful,_that.love,_that.fire,_that.mindBlown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int insightful,  int love,  int fire,  int mindBlown)?  $default,) {final _that = this;
switch (_that) {
case _ReactionCountsModel() when $default != null:
return $default(_that.insightful,_that.love,_that.fire,_that.mindBlown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReactionCountsModel extends ReactionCountsModel {
  const _ReactionCountsModel({this.insightful = 0, this.love = 0, this.fire = 0, this.mindBlown = 0}): super._();
  factory _ReactionCountsModel.fromJson(Map<String, dynamic> json) => _$ReactionCountsModelFromJson(json);

@override@JsonKey() final  int insightful;
@override@JsonKey() final  int love;
@override@JsonKey() final  int fire;
@override@JsonKey() final  int mindBlown;

/// Create a copy of ReactionCountsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReactionCountsModelCopyWith<_ReactionCountsModel> get copyWith => __$ReactionCountsModelCopyWithImpl<_ReactionCountsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReactionCountsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReactionCountsModel&&(identical(other.insightful, insightful) || other.insightful == insightful)&&(identical(other.love, love) || other.love == love)&&(identical(other.fire, fire) || other.fire == fire)&&(identical(other.mindBlown, mindBlown) || other.mindBlown == mindBlown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,insightful,love,fire,mindBlown);

@override
String toString() {
  return 'ReactionCountsModel(insightful: $insightful, love: $love, fire: $fire, mindBlown: $mindBlown)';
}


}

/// @nodoc
abstract mixin class _$ReactionCountsModelCopyWith<$Res> implements $ReactionCountsModelCopyWith<$Res> {
  factory _$ReactionCountsModelCopyWith(_ReactionCountsModel value, $Res Function(_ReactionCountsModel) _then) = __$ReactionCountsModelCopyWithImpl;
@override @useResult
$Res call({
 int insightful, int love, int fire, int mindBlown
});




}
/// @nodoc
class __$ReactionCountsModelCopyWithImpl<$Res>
    implements _$ReactionCountsModelCopyWith<$Res> {
  __$ReactionCountsModelCopyWithImpl(this._self, this._then);

  final _ReactionCountsModel _self;
  final $Res Function(_ReactionCountsModel) _then;

/// Create a copy of ReactionCountsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? insightful = null,Object? love = null,Object? fire = null,Object? mindBlown = null,}) {
  return _then(_ReactionCountsModel(
insightful: null == insightful ? _self.insightful : insightful // ignore: cast_nullable_to_non_nullable
as int,love: null == love ? _self.love : love // ignore: cast_nullable_to_non_nullable
as int,fire: null == fire ? _self.fire : fire // ignore: cast_nullable_to_non_nullable
as int,mindBlown: null == mindBlown ? _self.mindBlown : mindBlown // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ArticleCardModel {

 String get id; String get slug; String get language; String get title; String? get subtitle; String? get coverUrl; FieldRefModel get field; AuthorModel? get author; int get readingTimeMinutes; bool get isAiAssisted; String? get versionBadge; DateTime get publishedAt; int get reactionCount; int get commentCount; ArticleAttachmentsModel? get attachments; ReactionCountsModel? get reactions; int get saveCount; String? get myReaction; bool get isSaved; String? get excerpt; bool get hasMore; bool get isFollowingAuthor;@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> get tags; int get tagCount;// F28: the card's topic and the viewer's mutes.
 FieldRefModel? get topic; bool get isAuthorMuted; bool get isFieldMuted; bool get isTopicMuted;// F29: reposts, and the label on Following-feed cards a repost placed and on a profile's Reposts tab.
 int get repostCount; bool get isReposted; RepostLabelModel? get repostedBy;
/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<ArticleCardModel> get copyWith => _$ArticleCardModelCopyWithImpl<ArticleCardModel>(this as ArticleCardModel, _$identity);

  /// Serializes this ArticleCardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.attachments, attachments) || other.attachments == attachments)&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isFollowingAuthor, isFollowingAuthor) || other.isFollowingAuthor == isFollowingAuthor)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.tagCount, tagCount) || other.tagCount == tagCount)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.isAuthorMuted, isAuthorMuted) || other.isAuthorMuted == isAuthorMuted)&&(identical(other.isFieldMuted, isFieldMuted) || other.isFieldMuted == isFieldMuted)&&(identical(other.isTopicMuted, isTopicMuted) || other.isTopicMuted == isTopicMuted)&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted)&&(identical(other.repostedBy, repostedBy) || other.repostedBy == repostedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount,attachments,reactions,saveCount,myReaction,isSaved,excerpt,hasMore,isFollowingAuthor,const DeepCollectionEquality().hash(tags),tagCount,topic,isAuthorMuted,isFieldMuted,isTopicMuted,repostCount,isReposted,repostedBy]);

@override
String toString() {
  return 'ArticleCardModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount, attachments: $attachments, reactions: $reactions, saveCount: $saveCount, myReaction: $myReaction, isSaved: $isSaved, excerpt: $excerpt, hasMore: $hasMore, isFollowingAuthor: $isFollowingAuthor, tags: $tags, tagCount: $tagCount, topic: $topic, isAuthorMuted: $isAuthorMuted, isFieldMuted: $isFieldMuted, isTopicMuted: $isTopicMuted, repostCount: $repostCount, isReposted: $isReposted, repostedBy: $repostedBy)';
}


}

/// @nodoc
abstract mixin class $ArticleCardModelCopyWith<$Res>  {
  factory $ArticleCardModelCopyWith(ArticleCardModel value, $Res Function(ArticleCardModel) _then) = _$ArticleCardModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel? author, int readingTimeMinutes, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount, ArticleAttachmentsModel? attachments, ReactionCountsModel? reactions, int saveCount, String? myReaction, bool isSaved, String? excerpt, bool hasMore, bool isFollowingAuthor,@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> tags, int tagCount, FieldRefModel? topic, bool isAuthorMuted, bool isFieldMuted, bool isTopicMuted, int repostCount, bool isReposted, RepostLabelModel? repostedBy
});


$FieldRefModelCopyWith<$Res> get field;$AuthorModelCopyWith<$Res>? get author;$ArticleAttachmentsModelCopyWith<$Res>? get attachments;$ReactionCountsModelCopyWith<$Res>? get reactions;$FieldRefModelCopyWith<$Res>? get topic;$RepostLabelModelCopyWith<$Res>? get repostedBy;

}
/// @nodoc
class _$ArticleCardModelCopyWithImpl<$Res>
    implements $ArticleCardModelCopyWith<$Res> {
  _$ArticleCardModelCopyWithImpl(this._self, this._then);

  final ArticleCardModel _self;
  final $Res Function(ArticleCardModel) _then;

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = freezed,Object? readingTimeMinutes = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,Object? attachments = freezed,Object? reactions = freezed,Object? saveCount = null,Object? myReaction = freezed,Object? isSaved = null,Object? excerpt = freezed,Object? hasMore = null,Object? isFollowingAuthor = null,Object? tags = null,Object? tagCount = null,Object? topic = freezed,Object? isAuthorMuted = null,Object? isFieldMuted = null,Object? isTopicMuted = null,Object? repostCount = null,Object? isReposted = null,Object? repostedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as ArticleAttachmentsModel?,reactions: freezed == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as ReactionCountsModel?,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isFollowingAuthor: null == isFollowingAuthor ? _self.isFollowingAuthor : isFollowingAuthor // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<TagRefModel>,tagCount: null == tagCount ? _self.tagCount : tagCount // ignore: cast_nullable_to_non_nullable
as int,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,isAuthorMuted: null == isAuthorMuted ? _self.isAuthorMuted : isAuthorMuted // ignore: cast_nullable_to_non_nullable
as bool,isFieldMuted: null == isFieldMuted ? _self.isFieldMuted : isFieldMuted // ignore: cast_nullable_to_non_nullable
as bool,isTopicMuted: null == isTopicMuted ? _self.isTopicMuted : isTopicMuted // ignore: cast_nullable_to_non_nullable
as bool,repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,repostedBy: freezed == repostedBy ? _self.repostedBy : repostedBy // ignore: cast_nullable_to_non_nullable
as RepostLabelModel?,
  ));
}
/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $AuthorModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleAttachmentsModelCopyWith<$Res>? get attachments {
    if (_self.attachments == null) {
    return null;
  }

  return $ArticleAttachmentsModelCopyWith<$Res>(_self.attachments!, (value) {
    return _then(_self.copyWith(attachments: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<$Res>? get reactions {
    if (_self.reactions == null) {
    return null;
  }

  return $ReactionCountsModelCopyWith<$Res>(_self.reactions!, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepostLabelModelCopyWith<$Res>? get repostedBy {
    if (_self.repostedBy == null) {
    return null;
  }

  return $RepostLabelModelCopyWith<$Res>(_self.repostedBy!, (value) {
    return _then(_self.copyWith(repostedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleCardModel].
extension ArticleCardModelPatterns on ArticleCardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleCardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleCardModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleCardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleCardModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel? author,  int readingTimeMinutes,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  ArticleAttachmentsModel? attachments,  ReactionCountsModel? reactions,  int saveCount,  String? myReaction,  bool isSaved,  String? excerpt,  bool hasMore,  bool isFollowingAuthor, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson)  List<TagRefModel> tags,  int tagCount,  FieldRefModel? topic,  bool isAuthorMuted,  bool isFieldMuted,  bool isTopicMuted,  int repostCount,  bool isReposted,  RepostLabelModel? repostedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.attachments,_that.reactions,_that.saveCount,_that.myReaction,_that.isSaved,_that.excerpt,_that.hasMore,_that.isFollowingAuthor,_that.tags,_that.tagCount,_that.topic,_that.isAuthorMuted,_that.isFieldMuted,_that.isTopicMuted,_that.repostCount,_that.isReposted,_that.repostedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel? author,  int readingTimeMinutes,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  ArticleAttachmentsModel? attachments,  ReactionCountsModel? reactions,  int saveCount,  String? myReaction,  bool isSaved,  String? excerpt,  bool hasMore,  bool isFollowingAuthor, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson)  List<TagRefModel> tags,  int tagCount,  FieldRefModel? topic,  bool isAuthorMuted,  bool isFieldMuted,  bool isTopicMuted,  int repostCount,  bool isReposted,  RepostLabelModel? repostedBy)  $default,) {final _that = this;
switch (_that) {
case _ArticleCardModel():
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.attachments,_that.reactions,_that.saveCount,_that.myReaction,_that.isSaved,_that.excerpt,_that.hasMore,_that.isFollowingAuthor,_that.tags,_that.tagCount,_that.topic,_that.isAuthorMuted,_that.isFieldMuted,_that.isTopicMuted,_that.repostCount,_that.isReposted,_that.repostedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel? author,  int readingTimeMinutes,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  ArticleAttachmentsModel? attachments,  ReactionCountsModel? reactions,  int saveCount,  String? myReaction,  bool isSaved,  String? excerpt,  bool hasMore,  bool isFollowingAuthor, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson)  List<TagRefModel> tags,  int tagCount,  FieldRefModel? topic,  bool isAuthorMuted,  bool isFieldMuted,  bool isTopicMuted,  int repostCount,  bool isReposted,  RepostLabelModel? repostedBy)?  $default,) {final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.attachments,_that.reactions,_that.saveCount,_that.myReaction,_that.isSaved,_that.excerpt,_that.hasMore,_that.isFollowingAuthor,_that.tags,_that.tagCount,_that.topic,_that.isAuthorMuted,_that.isFieldMuted,_that.isTopicMuted,_that.repostCount,_that.isReposted,_that.repostedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleCardModel extends ArticleCardModel {
  const _ArticleCardModel({required this.id, required this.slug, required this.language, required this.title, this.subtitle, this.coverUrl, required this.field, required this.author, this.readingTimeMinutes = 1, this.isAiAssisted = false, this.versionBadge, required this.publishedAt, this.reactionCount = 0, this.commentCount = 0, this.attachments, this.reactions, this.saveCount = 0, this.myReaction, this.isSaved = false, this.excerpt, this.hasMore = false, this.isFollowingAuthor = false, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) final  List<TagRefModel> tags = const <TagRefModel>[], this.tagCount = 0, this.topic, this.isAuthorMuted = false, this.isFieldMuted = false, this.isTopicMuted = false, this.repostCount = 0, this.isReposted = false, this.repostedBy}): _tags = tags,super._();
  factory _ArticleCardModel.fromJson(Map<String, dynamic> json) => _$ArticleCardModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String language;
@override final  String title;
@override final  String? subtitle;
@override final  String? coverUrl;
@override final  FieldRefModel field;
@override final  AuthorModel? author;
@override@JsonKey() final  int readingTimeMinutes;
@override@JsonKey() final  bool isAiAssisted;
@override final  String? versionBadge;
@override final  DateTime publishedAt;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;
@override final  ArticleAttachmentsModel? attachments;
@override final  ReactionCountsModel? reactions;
@override@JsonKey() final  int saveCount;
@override final  String? myReaction;
@override@JsonKey() final  bool isSaved;
@override final  String? excerpt;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool isFollowingAuthor;
 final  List<TagRefModel> _tags;
@override@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int tagCount;
// F28: the card's topic and the viewer's mutes.
@override final  FieldRefModel? topic;
@override@JsonKey() final  bool isAuthorMuted;
@override@JsonKey() final  bool isFieldMuted;
@override@JsonKey() final  bool isTopicMuted;
// F29: reposts, and the label on Following-feed cards a repost placed and on a profile's Reposts tab.
@override@JsonKey() final  int repostCount;
@override@JsonKey() final  bool isReposted;
@override final  RepostLabelModel? repostedBy;

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleCardModelCopyWith<_ArticleCardModel> get copyWith => __$ArticleCardModelCopyWithImpl<_ArticleCardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleCardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.attachments, attachments) || other.attachments == attachments)&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isFollowingAuthor, isFollowingAuthor) || other.isFollowingAuthor == isFollowingAuthor)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.tagCount, tagCount) || other.tagCount == tagCount)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.isAuthorMuted, isAuthorMuted) || other.isAuthorMuted == isAuthorMuted)&&(identical(other.isFieldMuted, isFieldMuted) || other.isFieldMuted == isFieldMuted)&&(identical(other.isTopicMuted, isTopicMuted) || other.isTopicMuted == isTopicMuted)&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted)&&(identical(other.repostedBy, repostedBy) || other.repostedBy == repostedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount,attachments,reactions,saveCount,myReaction,isSaved,excerpt,hasMore,isFollowingAuthor,const DeepCollectionEquality().hash(_tags),tagCount,topic,isAuthorMuted,isFieldMuted,isTopicMuted,repostCount,isReposted,repostedBy]);

@override
String toString() {
  return 'ArticleCardModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount, attachments: $attachments, reactions: $reactions, saveCount: $saveCount, myReaction: $myReaction, isSaved: $isSaved, excerpt: $excerpt, hasMore: $hasMore, isFollowingAuthor: $isFollowingAuthor, tags: $tags, tagCount: $tagCount, topic: $topic, isAuthorMuted: $isAuthorMuted, isFieldMuted: $isFieldMuted, isTopicMuted: $isTopicMuted, repostCount: $repostCount, isReposted: $isReposted, repostedBy: $repostedBy)';
}


}

/// @nodoc
abstract mixin class _$ArticleCardModelCopyWith<$Res> implements $ArticleCardModelCopyWith<$Res> {
  factory _$ArticleCardModelCopyWith(_ArticleCardModel value, $Res Function(_ArticleCardModel) _then) = __$ArticleCardModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel? author, int readingTimeMinutes, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount, ArticleAttachmentsModel? attachments, ReactionCountsModel? reactions, int saveCount, String? myReaction, bool isSaved, String? excerpt, bool hasMore, bool isFollowingAuthor,@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> tags, int tagCount, FieldRefModel? topic, bool isAuthorMuted, bool isFieldMuted, bool isTopicMuted, int repostCount, bool isReposted, RepostLabelModel? repostedBy
});


@override $FieldRefModelCopyWith<$Res> get field;@override $AuthorModelCopyWith<$Res>? get author;@override $ArticleAttachmentsModelCopyWith<$Res>? get attachments;@override $ReactionCountsModelCopyWith<$Res>? get reactions;@override $FieldRefModelCopyWith<$Res>? get topic;@override $RepostLabelModelCopyWith<$Res>? get repostedBy;

}
/// @nodoc
class __$ArticleCardModelCopyWithImpl<$Res>
    implements _$ArticleCardModelCopyWith<$Res> {
  __$ArticleCardModelCopyWithImpl(this._self, this._then);

  final _ArticleCardModel _self;
  final $Res Function(_ArticleCardModel) _then;

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = freezed,Object? readingTimeMinutes = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,Object? attachments = freezed,Object? reactions = freezed,Object? saveCount = null,Object? myReaction = freezed,Object? isSaved = null,Object? excerpt = freezed,Object? hasMore = null,Object? isFollowingAuthor = null,Object? tags = null,Object? tagCount = null,Object? topic = freezed,Object? isAuthorMuted = null,Object? isFieldMuted = null,Object? isTopicMuted = null,Object? repostCount = null,Object? isReposted = null,Object? repostedBy = freezed,}) {
  return _then(_ArticleCardModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as ArticleAttachmentsModel?,reactions: freezed == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as ReactionCountsModel?,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isFollowingAuthor: null == isFollowingAuthor ? _self.isFollowingAuthor : isFollowingAuthor // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<TagRefModel>,tagCount: null == tagCount ? _self.tagCount : tagCount // ignore: cast_nullable_to_non_nullable
as int,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,isAuthorMuted: null == isAuthorMuted ? _self.isAuthorMuted : isAuthorMuted // ignore: cast_nullable_to_non_nullable
as bool,isFieldMuted: null == isFieldMuted ? _self.isFieldMuted : isFieldMuted // ignore: cast_nullable_to_non_nullable
as bool,isTopicMuted: null == isTopicMuted ? _self.isTopicMuted : isTopicMuted // ignore: cast_nullable_to_non_nullable
as bool,repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,repostedBy: freezed == repostedBy ? _self.repostedBy : repostedBy // ignore: cast_nullable_to_non_nullable
as RepostLabelModel?,
  ));
}

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $AuthorModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleAttachmentsModelCopyWith<$Res>? get attachments {
    if (_self.attachments == null) {
    return null;
  }

  return $ArticleAttachmentsModelCopyWith<$Res>(_self.attachments!, (value) {
    return _then(_self.copyWith(attachments: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<$Res>? get reactions {
    if (_self.reactions == null) {
    return null;
  }

  return $ReactionCountsModelCopyWith<$Res>(_self.reactions!, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepostLabelModelCopyWith<$Res>? get repostedBy {
    if (_self.repostedBy == null) {
    return null;
  }

  return $RepostLabelModelCopyWith<$Res>(_self.repostedBy!, (value) {
    return _then(_self.copyWith(repostedBy: value));
  });
}
}


/// @nodoc
mixin _$ArticlePreviewModel {

 String get id; String get language; Map<String, dynamic> get content; bool get isComplete;
/// Create a copy of ArticlePreviewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticlePreviewModelCopyWith<ArticlePreviewModel> get copyWith => _$ArticlePreviewModelCopyWithImpl<ArticlePreviewModel>(this as ArticlePreviewModel, _$identity);

  /// Serializes this ArticlePreviewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticlePreviewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,const DeepCollectionEquality().hash(content),isComplete);

@override
String toString() {
  return 'ArticlePreviewModel(id: $id, language: $language, content: $content, isComplete: $isComplete)';
}


}

/// @nodoc
abstract mixin class $ArticlePreviewModelCopyWith<$Res>  {
  factory $ArticlePreviewModelCopyWith(ArticlePreviewModel value, $Res Function(ArticlePreviewModel) _then) = _$ArticlePreviewModelCopyWithImpl;
@useResult
$Res call({
 String id, String language, Map<String, dynamic> content, bool isComplete
});




}
/// @nodoc
class _$ArticlePreviewModelCopyWithImpl<$Res>
    implements $ArticlePreviewModelCopyWith<$Res> {
  _$ArticlePreviewModelCopyWithImpl(this._self, this._then);

  final ArticlePreviewModel _self;
  final $Res Function(ArticlePreviewModel) _then;

/// Create a copy of ArticlePreviewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? language = null,Object? content = null,Object? isComplete = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticlePreviewModel].
extension ArticlePreviewModelPatterns on ArticlePreviewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticlePreviewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticlePreviewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticlePreviewModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticlePreviewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticlePreviewModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticlePreviewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String language,  Map<String, dynamic> content,  bool isComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticlePreviewModel() when $default != null:
return $default(_that.id,_that.language,_that.content,_that.isComplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String language,  Map<String, dynamic> content,  bool isComplete)  $default,) {final _that = this;
switch (_that) {
case _ArticlePreviewModel():
return $default(_that.id,_that.language,_that.content,_that.isComplete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String language,  Map<String, dynamic> content,  bool isComplete)?  $default,) {final _that = this;
switch (_that) {
case _ArticlePreviewModel() when $default != null:
return $default(_that.id,_that.language,_that.content,_that.isComplete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticlePreviewModel extends ArticlePreviewModel {
  const _ArticlePreviewModel({required this.id, required this.language, final  Map<String, dynamic> content = const <String, dynamic>{}, this.isComplete = false}): _content = content,super._();
  factory _ArticlePreviewModel.fromJson(Map<String, dynamic> json) => _$ArticlePreviewModelFromJson(json);

@override final  String id;
@override final  String language;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

@override@JsonKey() final  bool isComplete;

/// Create a copy of ArticlePreviewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticlePreviewModelCopyWith<_ArticlePreviewModel> get copyWith => __$ArticlePreviewModelCopyWithImpl<_ArticlePreviewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticlePreviewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticlePreviewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,const DeepCollectionEquality().hash(_content),isComplete);

@override
String toString() {
  return 'ArticlePreviewModel(id: $id, language: $language, content: $content, isComplete: $isComplete)';
}


}

/// @nodoc
abstract mixin class _$ArticlePreviewModelCopyWith<$Res> implements $ArticlePreviewModelCopyWith<$Res> {
  factory _$ArticlePreviewModelCopyWith(_ArticlePreviewModel value, $Res Function(_ArticlePreviewModel) _then) = __$ArticlePreviewModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String language, Map<String, dynamic> content, bool isComplete
});




}
/// @nodoc
class __$ArticlePreviewModelCopyWithImpl<$Res>
    implements _$ArticlePreviewModelCopyWith<$Res> {
  __$ArticlePreviewModelCopyWithImpl(this._self, this._then);

  final _ArticlePreviewModel _self;
  final $Res Function(_ArticlePreviewModel) _then;

/// Create a copy of ArticlePreviewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? language = null,Object? content = null,Object? isComplete = null,}) {
  return _then(_ArticlePreviewModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ArticleCardPageModel {

 List<ArticleCardModel> get items; String? get nextCursor;
/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleCardPageModelCopyWith<ArticleCardPageModel> get copyWith => _$ArticleCardPageModelCopyWithImpl<ArticleCardPageModel>(this as ArticleCardPageModel, _$identity);

  /// Serializes this ArticleCardPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleCardPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'ArticleCardPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $ArticleCardPageModelCopyWith<$Res>  {
  factory $ArticleCardPageModelCopyWith(ArticleCardPageModel value, $Res Function(ArticleCardPageModel) _then) = _$ArticleCardPageModelCopyWithImpl;
@useResult
$Res call({
 List<ArticleCardModel> items, String? nextCursor
});




}
/// @nodoc
class _$ArticleCardPageModelCopyWithImpl<$Res>
    implements $ArticleCardPageModelCopyWith<$Res> {
  _$ArticleCardPageModelCopyWithImpl(this._self, this._then);

  final ArticleCardPageModel _self;
  final $Res Function(ArticleCardPageModel) _then;

/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleCardPageModel].
extension ArticleCardPageModelPatterns on ArticleCardPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleCardPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleCardPageModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleCardPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleCardPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ArticleCardModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ArticleCardModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ArticleCardPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ArticleCardModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleCardPageModel implements ArticleCardPageModel {
  const _ArticleCardPageModel({final  List<ArticleCardModel> items = const <ArticleCardModel>[], this.nextCursor}): _items = items;
  factory _ArticleCardPageModel.fromJson(Map<String, dynamic> json) => _$ArticleCardPageModelFromJson(json);

 final  List<ArticleCardModel> _items;
@override@JsonKey() List<ArticleCardModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleCardPageModelCopyWith<_ArticleCardPageModel> get copyWith => __$ArticleCardPageModelCopyWithImpl<_ArticleCardPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleCardPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleCardPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'ArticleCardPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ArticleCardPageModelCopyWith<$Res> implements $ArticleCardPageModelCopyWith<$Res> {
  factory _$ArticleCardPageModelCopyWith(_ArticleCardPageModel value, $Res Function(_ArticleCardPageModel) _then) = __$ArticleCardPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<ArticleCardModel> items, String? nextCursor
});




}
/// @nodoc
class __$ArticleCardPageModelCopyWithImpl<$Res>
    implements _$ArticleCardPageModelCopyWith<$Res> {
  __$ArticleCardPageModelCopyWithImpl(this._self, this._then);

  final _ArticleCardPageModel _self;
  final $Res Function(_ArticleCardPageModel) _then;

/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_ArticleCardPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SourceModel {

 String get title; String get url;
/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceModelCopyWith<SourceModel> get copyWith => _$SourceModelCopyWithImpl<SourceModel>(this as SourceModel, _$identity);

  /// Serializes this SourceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceModel&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url);

@override
String toString() {
  return 'SourceModel(title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class $SourceModelCopyWith<$Res>  {
  factory $SourceModelCopyWith(SourceModel value, $Res Function(SourceModel) _then) = _$SourceModelCopyWithImpl;
@useResult
$Res call({
 String title, String url
});




}
/// @nodoc
class _$SourceModelCopyWithImpl<$Res>
    implements $SourceModelCopyWith<$Res> {
  _$SourceModelCopyWithImpl(this._self, this._then);

  final SourceModel _self;
  final $Res Function(SourceModel) _then;

/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? url = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceModel].
extension SourceModelPatterns on SourceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceModel value)  $default,){
final _that = this;
switch (_that) {
case _SourceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceModel value)?  $default,){
final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
return $default(_that.title,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String url)  $default,) {final _that = this;
switch (_that) {
case _SourceModel():
return $default(_that.title,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String url)?  $default,) {final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
return $default(_that.title,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceModel implements SourceModel {
  const _SourceModel({required this.title, required this.url});
  factory _SourceModel.fromJson(Map<String, dynamic> json) => _$SourceModelFromJson(json);

@override final  String title;
@override final  String url;

/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceModelCopyWith<_SourceModel> get copyWith => __$SourceModelCopyWithImpl<_SourceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceModel&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url);

@override
String toString() {
  return 'SourceModel(title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SourceModelCopyWith<$Res> implements $SourceModelCopyWith<$Res> {
  factory _$SourceModelCopyWith(_SourceModel value, $Res Function(_SourceModel) _then) = __$SourceModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String url
});




}
/// @nodoc
class __$SourceModelCopyWithImpl<$Res>
    implements _$SourceModelCopyWith<$Res> {
  __$SourceModelCopyWithImpl(this._self, this._then);

  final _SourceModel _self;
  final $Res Function(_SourceModel) _then;

/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? url = null,}) {
  return _then(_SourceModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MyProgressModel {

 String get language; int get percent; String? get lastPosition; DateTime? get completedAt;
/// Create a copy of MyProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyProgressModelCopyWith<MyProgressModel> get copyWith => _$MyProgressModelCopyWithImpl<MyProgressModel>(this as MyProgressModel, _$identity);

  /// Serializes this MyProgressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyProgressModel&&(identical(other.language, language) || other.language == language)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.lastPosition, lastPosition) || other.lastPosition == lastPosition)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,percent,lastPosition,completedAt);

@override
String toString() {
  return 'MyProgressModel(language: $language, percent: $percent, lastPosition: $lastPosition, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $MyProgressModelCopyWith<$Res>  {
  factory $MyProgressModelCopyWith(MyProgressModel value, $Res Function(MyProgressModel) _then) = _$MyProgressModelCopyWithImpl;
@useResult
$Res call({
 String language, int percent, String? lastPosition, DateTime? completedAt
});




}
/// @nodoc
class _$MyProgressModelCopyWithImpl<$Res>
    implements $MyProgressModelCopyWith<$Res> {
  _$MyProgressModelCopyWithImpl(this._self, this._then);

  final MyProgressModel _self;
  final $Res Function(MyProgressModel) _then;

/// Create a copy of MyProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? percent = null,Object? lastPosition = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,lastPosition: freezed == lastPosition ? _self.lastPosition : lastPosition // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MyProgressModel].
extension MyProgressModelPatterns on MyProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _MyProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _MyProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  int percent,  String? lastPosition,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyProgressModel() when $default != null:
return $default(_that.language,_that.percent,_that.lastPosition,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  int percent,  String? lastPosition,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _MyProgressModel():
return $default(_that.language,_that.percent,_that.lastPosition,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  int percent,  String? lastPosition,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _MyProgressModel() when $default != null:
return $default(_that.language,_that.percent,_that.lastPosition,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyProgressModel extends MyProgressModel {
  const _MyProgressModel({required this.language, this.percent = 0, this.lastPosition, this.completedAt}): super._();
  factory _MyProgressModel.fromJson(Map<String, dynamic> json) => _$MyProgressModelFromJson(json);

@override final  String language;
@override@JsonKey() final  int percent;
@override final  String? lastPosition;
@override final  DateTime? completedAt;

/// Create a copy of MyProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyProgressModelCopyWith<_MyProgressModel> get copyWith => __$MyProgressModelCopyWithImpl<_MyProgressModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyProgressModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyProgressModel&&(identical(other.language, language) || other.language == language)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.lastPosition, lastPosition) || other.lastPosition == lastPosition)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,percent,lastPosition,completedAt);

@override
String toString() {
  return 'MyProgressModel(language: $language, percent: $percent, lastPosition: $lastPosition, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$MyProgressModelCopyWith<$Res> implements $MyProgressModelCopyWith<$Res> {
  factory _$MyProgressModelCopyWith(_MyProgressModel value, $Res Function(_MyProgressModel) _then) = __$MyProgressModelCopyWithImpl;
@override @useResult
$Res call({
 String language, int percent, String? lastPosition, DateTime? completedAt
});




}
/// @nodoc
class __$MyProgressModelCopyWithImpl<$Res>
    implements _$MyProgressModelCopyWith<$Res> {
  __$MyProgressModelCopyWithImpl(this._self, this._then);

  final _MyProgressModel _self;
  final $Res Function(_MyProgressModel) _then;

/// Create a copy of MyProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? percent = null,Object? lastPosition = freezed,Object? completedAt = freezed,}) {
  return _then(_MyProgressModel(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,lastPosition: freezed == lastPosition ? _self.lastPosition : lastPosition // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ArticleModerationModel {

 DateTime get hiddenAt; String? get note;
/// Create a copy of ArticleModerationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleModerationModelCopyWith<ArticleModerationModel> get copyWith => _$ArticleModerationModelCopyWithImpl<ArticleModerationModel>(this as ArticleModerationModel, _$identity);

  /// Serializes this ArticleModerationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleModerationModel&&(identical(other.hiddenAt, hiddenAt) || other.hiddenAt == hiddenAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hiddenAt,note);

@override
String toString() {
  return 'ArticleModerationModel(hiddenAt: $hiddenAt, note: $note)';
}


}

/// @nodoc
abstract mixin class $ArticleModerationModelCopyWith<$Res>  {
  factory $ArticleModerationModelCopyWith(ArticleModerationModel value, $Res Function(ArticleModerationModel) _then) = _$ArticleModerationModelCopyWithImpl;
@useResult
$Res call({
 DateTime hiddenAt, String? note
});




}
/// @nodoc
class _$ArticleModerationModelCopyWithImpl<$Res>
    implements $ArticleModerationModelCopyWith<$Res> {
  _$ArticleModerationModelCopyWithImpl(this._self, this._then);

  final ArticleModerationModel _self;
  final $Res Function(ArticleModerationModel) _then;

/// Create a copy of ArticleModerationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hiddenAt = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
hiddenAt: null == hiddenAt ? _self.hiddenAt : hiddenAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleModerationModel].
extension ArticleModerationModelPatterns on ArticleModerationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleModerationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleModerationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleModerationModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleModerationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleModerationModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleModerationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime hiddenAt,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleModerationModel() when $default != null:
return $default(_that.hiddenAt,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime hiddenAt,  String? note)  $default,) {final _that = this;
switch (_that) {
case _ArticleModerationModel():
return $default(_that.hiddenAt,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime hiddenAt,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _ArticleModerationModel() when $default != null:
return $default(_that.hiddenAt,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleModerationModel extends ArticleModerationModel {
  const _ArticleModerationModel({required this.hiddenAt, this.note}): super._();
  factory _ArticleModerationModel.fromJson(Map<String, dynamic> json) => _$ArticleModerationModelFromJson(json);

@override final  DateTime hiddenAt;
@override final  String? note;

/// Create a copy of ArticleModerationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleModerationModelCopyWith<_ArticleModerationModel> get copyWith => __$ArticleModerationModelCopyWithImpl<_ArticleModerationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleModerationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleModerationModel&&(identical(other.hiddenAt, hiddenAt) || other.hiddenAt == hiddenAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hiddenAt,note);

@override
String toString() {
  return 'ArticleModerationModel(hiddenAt: $hiddenAt, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ArticleModerationModelCopyWith<$Res> implements $ArticleModerationModelCopyWith<$Res> {
  factory _$ArticleModerationModelCopyWith(_ArticleModerationModel value, $Res Function(_ArticleModerationModel) _then) = __$ArticleModerationModelCopyWithImpl;
@override @useResult
$Res call({
 DateTime hiddenAt, String? note
});




}
/// @nodoc
class __$ArticleModerationModelCopyWithImpl<$Res>
    implements _$ArticleModerationModelCopyWith<$Res> {
  __$ArticleModerationModelCopyWithImpl(this._self, this._then);

  final _ArticleModerationModel _self;
  final $Res Function(_ArticleModerationModel) _then;

/// Create a copy of ArticleModerationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hiddenAt = null,Object? note = freezed,}) {
  return _then(_ArticleModerationModel(
hiddenAt: null == hiddenAt ? _self.hiddenAt : hiddenAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ArticleDetailsModel {

 String get id; String get slug; String get language; String get title; String? get subtitle; String? get coverUrl; FieldRefModel get field; AuthorModel? get author; int get readingTimeMinutes; bool get isAiAssisted; String? get versionBadge; DateTime get publishedAt; int get reactionCount; int get commentCount; ArticleAttachmentsModel? get attachments; ReactionCountsModel? get reactions; String? get myReaction; bool get isSaved; List<String> get availableLanguages; String? get summary; Map<String, dynamic> get content; FieldRefModel? get topic;@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> get tags; List<SourceModel> get sources; int get saveCount; int get readCount; bool get isFollowingAuthor; List<String> get collectionIds; MyProgressModel? get myProgress; ArticleModerationModel? get moderation;// F31: the writer's category of the article, { slug, name } or null.
 WriterCategoryRefModel? get category;// F28: the viewer's mutes ("انت كاتم الكاتب ده" and the "كتم المواضيع" sheet).
 bool get isAuthorMuted; bool get isFieldMuted; bool get isTopicMuted;// F29: the reader's Repost button.
 int get repostCount; bool get isReposted;// F23: featured on Explore (the "⋯" offers Feature / Unfeature with `articles.feature`).
 bool get isFeatured;
/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleDetailsModelCopyWith<ArticleDetailsModel> get copyWith => _$ArticleDetailsModelCopyWithImpl<ArticleDetailsModel>(this as ArticleDetailsModel, _$identity);

  /// Serializes this ArticleDetailsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleDetailsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.attachments, attachments) || other.attachments == attachments)&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&const DeepCollectionEquality().equals(other.availableLanguages, availableLanguages)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.readCount, readCount) || other.readCount == readCount)&&(identical(other.isFollowingAuthor, isFollowingAuthor) || other.isFollowingAuthor == isFollowingAuthor)&&const DeepCollectionEquality().equals(other.collectionIds, collectionIds)&&(identical(other.myProgress, myProgress) || other.myProgress == myProgress)&&(identical(other.moderation, moderation) || other.moderation == moderation)&&(identical(other.category, category) || other.category == category)&&(identical(other.isAuthorMuted, isAuthorMuted) || other.isAuthorMuted == isAuthorMuted)&&(identical(other.isFieldMuted, isFieldMuted) || other.isFieldMuted == isFieldMuted)&&(identical(other.isTopicMuted, isTopicMuted) || other.isTopicMuted == isTopicMuted)&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount,attachments,reactions,myReaction,isSaved,const DeepCollectionEquality().hash(availableLanguages),summary,const DeepCollectionEquality().hash(content),topic,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(sources),saveCount,readCount,isFollowingAuthor,const DeepCollectionEquality().hash(collectionIds),myProgress,moderation,category,isAuthorMuted,isFieldMuted,isTopicMuted,repostCount,isReposted,isFeatured]);

@override
String toString() {
  return 'ArticleDetailsModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount, attachments: $attachments, reactions: $reactions, myReaction: $myReaction, isSaved: $isSaved, availableLanguages: $availableLanguages, summary: $summary, content: $content, topic: $topic, tags: $tags, sources: $sources, saveCount: $saveCount, readCount: $readCount, isFollowingAuthor: $isFollowingAuthor, collectionIds: $collectionIds, myProgress: $myProgress, moderation: $moderation, category: $category, isAuthorMuted: $isAuthorMuted, isFieldMuted: $isFieldMuted, isTopicMuted: $isTopicMuted, repostCount: $repostCount, isReposted: $isReposted, isFeatured: $isFeatured)';
}


}

/// @nodoc
abstract mixin class $ArticleDetailsModelCopyWith<$Res>  {
  factory $ArticleDetailsModelCopyWith(ArticleDetailsModel value, $Res Function(ArticleDetailsModel) _then) = _$ArticleDetailsModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel? author, int readingTimeMinutes, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount, ArticleAttachmentsModel? attachments, ReactionCountsModel? reactions, String? myReaction, bool isSaved, List<String> availableLanguages, String? summary, Map<String, dynamic> content, FieldRefModel? topic,@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> tags, List<SourceModel> sources, int saveCount, int readCount, bool isFollowingAuthor, List<String> collectionIds, MyProgressModel? myProgress, ArticleModerationModel? moderation, WriterCategoryRefModel? category, bool isAuthorMuted, bool isFieldMuted, bool isTopicMuted, int repostCount, bool isReposted, bool isFeatured
});


$FieldRefModelCopyWith<$Res> get field;$AuthorModelCopyWith<$Res>? get author;$ArticleAttachmentsModelCopyWith<$Res>? get attachments;$ReactionCountsModelCopyWith<$Res>? get reactions;$FieldRefModelCopyWith<$Res>? get topic;$MyProgressModelCopyWith<$Res>? get myProgress;$ArticleModerationModelCopyWith<$Res>? get moderation;$WriterCategoryRefModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$ArticleDetailsModelCopyWithImpl<$Res>
    implements $ArticleDetailsModelCopyWith<$Res> {
  _$ArticleDetailsModelCopyWithImpl(this._self, this._then);

  final ArticleDetailsModel _self;
  final $Res Function(ArticleDetailsModel) _then;

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = freezed,Object? readingTimeMinutes = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,Object? attachments = freezed,Object? reactions = freezed,Object? myReaction = freezed,Object? isSaved = null,Object? availableLanguages = null,Object? summary = freezed,Object? content = null,Object? topic = freezed,Object? tags = null,Object? sources = null,Object? saveCount = null,Object? readCount = null,Object? isFollowingAuthor = null,Object? collectionIds = null,Object? myProgress = freezed,Object? moderation = freezed,Object? category = freezed,Object? isAuthorMuted = null,Object? isFieldMuted = null,Object? isTopicMuted = null,Object? repostCount = null,Object? isReposted = null,Object? isFeatured = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as ArticleAttachmentsModel?,reactions: freezed == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as ReactionCountsModel?,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,availableLanguages: null == availableLanguages ? _self.availableLanguages : availableLanguages // ignore: cast_nullable_to_non_nullable
as List<String>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<TagRefModel>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceModel>,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,isFollowingAuthor: null == isFollowingAuthor ? _self.isFollowingAuthor : isFollowingAuthor // ignore: cast_nullable_to_non_nullable
as bool,collectionIds: null == collectionIds ? _self.collectionIds : collectionIds // ignore: cast_nullable_to_non_nullable
as List<String>,myProgress: freezed == myProgress ? _self.myProgress : myProgress // ignore: cast_nullable_to_non_nullable
as MyProgressModel?,moderation: freezed == moderation ? _self.moderation : moderation // ignore: cast_nullable_to_non_nullable
as ArticleModerationModel?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WriterCategoryRefModel?,isAuthorMuted: null == isAuthorMuted ? _self.isAuthorMuted : isAuthorMuted // ignore: cast_nullable_to_non_nullable
as bool,isFieldMuted: null == isFieldMuted ? _self.isFieldMuted : isFieldMuted // ignore: cast_nullable_to_non_nullable
as bool,isTopicMuted: null == isTopicMuted ? _self.isTopicMuted : isTopicMuted // ignore: cast_nullable_to_non_nullable
as bool,repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $AuthorModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleAttachmentsModelCopyWith<$Res>? get attachments {
    if (_self.attachments == null) {
    return null;
  }

  return $ArticleAttachmentsModelCopyWith<$Res>(_self.attachments!, (value) {
    return _then(_self.copyWith(attachments: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<$Res>? get reactions {
    if (_self.reactions == null) {
    return null;
  }

  return $ReactionCountsModelCopyWith<$Res>(_self.reactions!, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyProgressModelCopyWith<$Res>? get myProgress {
    if (_self.myProgress == null) {
    return null;
  }

  return $MyProgressModelCopyWith<$Res>(_self.myProgress!, (value) {
    return _then(_self.copyWith(myProgress: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleModerationModelCopyWith<$Res>? get moderation {
    if (_self.moderation == null) {
    return null;
  }

  return $ArticleModerationModelCopyWith<$Res>(_self.moderation!, (value) {
    return _then(_self.copyWith(moderation: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WriterCategoryRefModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $WriterCategoryRefModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleDetailsModel].
extension ArticleDetailsModelPatterns on ArticleDetailsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleDetailsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleDetailsModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleDetailsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleDetailsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel? author,  int readingTimeMinutes,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  ArticleAttachmentsModel? attachments,  ReactionCountsModel? reactions,  String? myReaction,  bool isSaved,  List<String> availableLanguages,  String? summary,  Map<String, dynamic> content,  FieldRefModel? topic, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson)  List<TagRefModel> tags,  List<SourceModel> sources,  int saveCount,  int readCount,  bool isFollowingAuthor,  List<String> collectionIds,  MyProgressModel? myProgress,  ArticleModerationModel? moderation,  WriterCategoryRefModel? category,  bool isAuthorMuted,  bool isFieldMuted,  bool isTopicMuted,  int repostCount,  bool isReposted,  bool isFeatured)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.attachments,_that.reactions,_that.myReaction,_that.isSaved,_that.availableLanguages,_that.summary,_that.content,_that.topic,_that.tags,_that.sources,_that.saveCount,_that.readCount,_that.isFollowingAuthor,_that.collectionIds,_that.myProgress,_that.moderation,_that.category,_that.isAuthorMuted,_that.isFieldMuted,_that.isTopicMuted,_that.repostCount,_that.isReposted,_that.isFeatured);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel? author,  int readingTimeMinutes,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  ArticleAttachmentsModel? attachments,  ReactionCountsModel? reactions,  String? myReaction,  bool isSaved,  List<String> availableLanguages,  String? summary,  Map<String, dynamic> content,  FieldRefModel? topic, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson)  List<TagRefModel> tags,  List<SourceModel> sources,  int saveCount,  int readCount,  bool isFollowingAuthor,  List<String> collectionIds,  MyProgressModel? myProgress,  ArticleModerationModel? moderation,  WriterCategoryRefModel? category,  bool isAuthorMuted,  bool isFieldMuted,  bool isTopicMuted,  int repostCount,  bool isReposted,  bool isFeatured)  $default,) {final _that = this;
switch (_that) {
case _ArticleDetailsModel():
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.attachments,_that.reactions,_that.myReaction,_that.isSaved,_that.availableLanguages,_that.summary,_that.content,_that.topic,_that.tags,_that.sources,_that.saveCount,_that.readCount,_that.isFollowingAuthor,_that.collectionIds,_that.myProgress,_that.moderation,_that.category,_that.isAuthorMuted,_that.isFieldMuted,_that.isTopicMuted,_that.repostCount,_that.isReposted,_that.isFeatured);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel? author,  int readingTimeMinutes,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  ArticleAttachmentsModel? attachments,  ReactionCountsModel? reactions,  String? myReaction,  bool isSaved,  List<String> availableLanguages,  String? summary,  Map<String, dynamic> content,  FieldRefModel? topic, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson)  List<TagRefModel> tags,  List<SourceModel> sources,  int saveCount,  int readCount,  bool isFollowingAuthor,  List<String> collectionIds,  MyProgressModel? myProgress,  ArticleModerationModel? moderation,  WriterCategoryRefModel? category,  bool isAuthorMuted,  bool isFieldMuted,  bool isTopicMuted,  int repostCount,  bool isReposted,  bool isFeatured)?  $default,) {final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.attachments,_that.reactions,_that.myReaction,_that.isSaved,_that.availableLanguages,_that.summary,_that.content,_that.topic,_that.tags,_that.sources,_that.saveCount,_that.readCount,_that.isFollowingAuthor,_that.collectionIds,_that.myProgress,_that.moderation,_that.category,_that.isAuthorMuted,_that.isFieldMuted,_that.isTopicMuted,_that.repostCount,_that.isReposted,_that.isFeatured);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleDetailsModel extends ArticleDetailsModel {
  const _ArticleDetailsModel({required this.id, required this.slug, required this.language, required this.title, this.subtitle, this.coverUrl, required this.field, required this.author, this.readingTimeMinutes = 1, this.isAiAssisted = false, this.versionBadge, required this.publishedAt, this.reactionCount = 0, this.commentCount = 0, this.attachments, this.reactions, this.myReaction, this.isSaved = false, final  List<String> availableLanguages = const <String>[], this.summary, final  Map<String, dynamic> content = const <String, dynamic>{}, this.topic, @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) final  List<TagRefModel> tags = const <TagRefModel>[], final  List<SourceModel> sources = const <SourceModel>[], this.saveCount = 0, this.readCount = 0, this.isFollowingAuthor = false, final  List<String> collectionIds = const <String>[], this.myProgress, this.moderation, this.category, this.isAuthorMuted = false, this.isFieldMuted = false, this.isTopicMuted = false, this.repostCount = 0, this.isReposted = false, this.isFeatured = false}): _availableLanguages = availableLanguages,_content = content,_tags = tags,_sources = sources,_collectionIds = collectionIds,super._();
  factory _ArticleDetailsModel.fromJson(Map<String, dynamic> json) => _$ArticleDetailsModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String language;
@override final  String title;
@override final  String? subtitle;
@override final  String? coverUrl;
@override final  FieldRefModel field;
@override final  AuthorModel? author;
@override@JsonKey() final  int readingTimeMinutes;
@override@JsonKey() final  bool isAiAssisted;
@override final  String? versionBadge;
@override final  DateTime publishedAt;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;
@override final  ArticleAttachmentsModel? attachments;
@override final  ReactionCountsModel? reactions;
@override final  String? myReaction;
@override@JsonKey() final  bool isSaved;
 final  List<String> _availableLanguages;
@override@JsonKey() List<String> get availableLanguages {
  if (_availableLanguages is EqualUnmodifiableListView) return _availableLanguages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableLanguages);
}

@override final  String? summary;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

@override final  FieldRefModel? topic;
 final  List<TagRefModel> _tags;
@override@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<SourceModel> _sources;
@override@JsonKey() List<SourceModel> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

@override@JsonKey() final  int saveCount;
@override@JsonKey() final  int readCount;
@override@JsonKey() final  bool isFollowingAuthor;
 final  List<String> _collectionIds;
@override@JsonKey() List<String> get collectionIds {
  if (_collectionIds is EqualUnmodifiableListView) return _collectionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collectionIds);
}

@override final  MyProgressModel? myProgress;
@override final  ArticleModerationModel? moderation;
// F31: the writer's category of the article, { slug, name } or null.
@override final  WriterCategoryRefModel? category;
// F28: the viewer's mutes ("انت كاتم الكاتب ده" and the "كتم المواضيع" sheet).
@override@JsonKey() final  bool isAuthorMuted;
@override@JsonKey() final  bool isFieldMuted;
@override@JsonKey() final  bool isTopicMuted;
// F29: the reader's Repost button.
@override@JsonKey() final  int repostCount;
@override@JsonKey() final  bool isReposted;
// F23: featured on Explore (the "⋯" offers Feature / Unfeature with `articles.feature`).
@override@JsonKey() final  bool isFeatured;

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleDetailsModelCopyWith<_ArticleDetailsModel> get copyWith => __$ArticleDetailsModelCopyWithImpl<_ArticleDetailsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleDetailsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleDetailsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.attachments, attachments) || other.attachments == attachments)&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&const DeepCollectionEquality().equals(other._availableLanguages, _availableLanguages)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.readCount, readCount) || other.readCount == readCount)&&(identical(other.isFollowingAuthor, isFollowingAuthor) || other.isFollowingAuthor == isFollowingAuthor)&&const DeepCollectionEquality().equals(other._collectionIds, _collectionIds)&&(identical(other.myProgress, myProgress) || other.myProgress == myProgress)&&(identical(other.moderation, moderation) || other.moderation == moderation)&&(identical(other.category, category) || other.category == category)&&(identical(other.isAuthorMuted, isAuthorMuted) || other.isAuthorMuted == isAuthorMuted)&&(identical(other.isFieldMuted, isFieldMuted) || other.isFieldMuted == isFieldMuted)&&(identical(other.isTopicMuted, isTopicMuted) || other.isTopicMuted == isTopicMuted)&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount,attachments,reactions,myReaction,isSaved,const DeepCollectionEquality().hash(_availableLanguages),summary,const DeepCollectionEquality().hash(_content),topic,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_sources),saveCount,readCount,isFollowingAuthor,const DeepCollectionEquality().hash(_collectionIds),myProgress,moderation,category,isAuthorMuted,isFieldMuted,isTopicMuted,repostCount,isReposted,isFeatured]);

@override
String toString() {
  return 'ArticleDetailsModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount, attachments: $attachments, reactions: $reactions, myReaction: $myReaction, isSaved: $isSaved, availableLanguages: $availableLanguages, summary: $summary, content: $content, topic: $topic, tags: $tags, sources: $sources, saveCount: $saveCount, readCount: $readCount, isFollowingAuthor: $isFollowingAuthor, collectionIds: $collectionIds, myProgress: $myProgress, moderation: $moderation, category: $category, isAuthorMuted: $isAuthorMuted, isFieldMuted: $isFieldMuted, isTopicMuted: $isTopicMuted, repostCount: $repostCount, isReposted: $isReposted, isFeatured: $isFeatured)';
}


}

/// @nodoc
abstract mixin class _$ArticleDetailsModelCopyWith<$Res> implements $ArticleDetailsModelCopyWith<$Res> {
  factory _$ArticleDetailsModelCopyWith(_ArticleDetailsModel value, $Res Function(_ArticleDetailsModel) _then) = __$ArticleDetailsModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel? author, int readingTimeMinutes, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount, ArticleAttachmentsModel? attachments, ReactionCountsModel? reactions, String? myReaction, bool isSaved, List<String> availableLanguages, String? summary, Map<String, dynamic> content, FieldRefModel? topic,@JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) List<TagRefModel> tags, List<SourceModel> sources, int saveCount, int readCount, bool isFollowingAuthor, List<String> collectionIds, MyProgressModel? myProgress, ArticleModerationModel? moderation, WriterCategoryRefModel? category, bool isAuthorMuted, bool isFieldMuted, bool isTopicMuted, int repostCount, bool isReposted, bool isFeatured
});


@override $FieldRefModelCopyWith<$Res> get field;@override $AuthorModelCopyWith<$Res>? get author;@override $ArticleAttachmentsModelCopyWith<$Res>? get attachments;@override $ReactionCountsModelCopyWith<$Res>? get reactions;@override $FieldRefModelCopyWith<$Res>? get topic;@override $MyProgressModelCopyWith<$Res>? get myProgress;@override $ArticleModerationModelCopyWith<$Res>? get moderation;@override $WriterCategoryRefModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$ArticleDetailsModelCopyWithImpl<$Res>
    implements _$ArticleDetailsModelCopyWith<$Res> {
  __$ArticleDetailsModelCopyWithImpl(this._self, this._then);

  final _ArticleDetailsModel _self;
  final $Res Function(_ArticleDetailsModel) _then;

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = freezed,Object? readingTimeMinutes = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,Object? attachments = freezed,Object? reactions = freezed,Object? myReaction = freezed,Object? isSaved = null,Object? availableLanguages = null,Object? summary = freezed,Object? content = null,Object? topic = freezed,Object? tags = null,Object? sources = null,Object? saveCount = null,Object? readCount = null,Object? isFollowingAuthor = null,Object? collectionIds = null,Object? myProgress = freezed,Object? moderation = freezed,Object? category = freezed,Object? isAuthorMuted = null,Object? isFieldMuted = null,Object? isTopicMuted = null,Object? repostCount = null,Object? isReposted = null,Object? isFeatured = null,}) {
  return _then(_ArticleDetailsModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as ArticleAttachmentsModel?,reactions: freezed == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as ReactionCountsModel?,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,availableLanguages: null == availableLanguages ? _self._availableLanguages : availableLanguages // ignore: cast_nullable_to_non_nullable
as List<String>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<TagRefModel>,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceModel>,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,isFollowingAuthor: null == isFollowingAuthor ? _self.isFollowingAuthor : isFollowingAuthor // ignore: cast_nullable_to_non_nullable
as bool,collectionIds: null == collectionIds ? _self._collectionIds : collectionIds // ignore: cast_nullable_to_non_nullable
as List<String>,myProgress: freezed == myProgress ? _self.myProgress : myProgress // ignore: cast_nullable_to_non_nullable
as MyProgressModel?,moderation: freezed == moderation ? _self.moderation : moderation // ignore: cast_nullable_to_non_nullable
as ArticleModerationModel?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WriterCategoryRefModel?,isAuthorMuted: null == isAuthorMuted ? _self.isAuthorMuted : isAuthorMuted // ignore: cast_nullable_to_non_nullable
as bool,isFieldMuted: null == isFieldMuted ? _self.isFieldMuted : isFieldMuted // ignore: cast_nullable_to_non_nullable
as bool,isTopicMuted: null == isTopicMuted ? _self.isTopicMuted : isTopicMuted // ignore: cast_nullable_to_non_nullable
as bool,repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $AuthorModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleAttachmentsModelCopyWith<$Res>? get attachments {
    if (_self.attachments == null) {
    return null;
  }

  return $ArticleAttachmentsModelCopyWith<$Res>(_self.attachments!, (value) {
    return _then(_self.copyWith(attachments: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<$Res>? get reactions {
    if (_self.reactions == null) {
    return null;
  }

  return $ReactionCountsModelCopyWith<$Res>(_self.reactions!, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyProgressModelCopyWith<$Res>? get myProgress {
    if (_self.myProgress == null) {
    return null;
  }

  return $MyProgressModelCopyWith<$Res>(_self.myProgress!, (value) {
    return _then(_self.copyWith(myProgress: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleModerationModelCopyWith<$Res>? get moderation {
    if (_self.moderation == null) {
    return null;
  }

  return $ArticleModerationModelCopyWith<$Res>(_self.moderation!, (value) {
    return _then(_self.copyWith(moderation: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WriterCategoryRefModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $WriterCategoryRefModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
