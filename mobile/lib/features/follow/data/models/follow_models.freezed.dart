// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowStateModel {

 bool get isFollowing; int get followerCount;
/// Create a copy of FollowStateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowStateModelCopyWith<FollowStateModel> get copyWith => _$FollowStateModelCopyWithImpl<FollowStateModel>(this as FollowStateModel, _$identity);

  /// Serializes this FollowStateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowStateModel&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFollowing,followerCount);

@override
String toString() {
  return 'FollowStateModel(isFollowing: $isFollowing, followerCount: $followerCount)';
}


}

/// @nodoc
abstract mixin class $FollowStateModelCopyWith<$Res>  {
  factory $FollowStateModelCopyWith(FollowStateModel value, $Res Function(FollowStateModel) _then) = _$FollowStateModelCopyWithImpl;
@useResult
$Res call({
 bool isFollowing, int followerCount
});




}
/// @nodoc
class _$FollowStateModelCopyWithImpl<$Res>
    implements $FollowStateModelCopyWith<$Res> {
  _$FollowStateModelCopyWithImpl(this._self, this._then);

  final FollowStateModel _self;
  final $Res Function(FollowStateModel) _then;

/// Create a copy of FollowStateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isFollowing = null,Object? followerCount = null,}) {
  return _then(_self.copyWith(
isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowStateModel].
extension FollowStateModelPatterns on FollowStateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowStateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowStateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowStateModel value)  $default,){
final _that = this;
switch (_that) {
case _FollowStateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowStateModel value)?  $default,){
final _that = this;
switch (_that) {
case _FollowStateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isFollowing,  int followerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowStateModel() when $default != null:
return $default(_that.isFollowing,_that.followerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isFollowing,  int followerCount)  $default,) {final _that = this;
switch (_that) {
case _FollowStateModel():
return $default(_that.isFollowing,_that.followerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isFollowing,  int followerCount)?  $default,) {final _that = this;
switch (_that) {
case _FollowStateModel() when $default != null:
return $default(_that.isFollowing,_that.followerCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowStateModel extends FollowStateModel {
  const _FollowStateModel({required this.isFollowing, this.followerCount = 0}): super._();
  factory _FollowStateModel.fromJson(Map<String, dynamic> json) => _$FollowStateModelFromJson(json);

@override final  bool isFollowing;
@override@JsonKey() final  int followerCount;

/// Create a copy of FollowStateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowStateModelCopyWith<_FollowStateModel> get copyWith => __$FollowStateModelCopyWithImpl<_FollowStateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowStateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowStateModel&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFollowing,followerCount);

@override
String toString() {
  return 'FollowStateModel(isFollowing: $isFollowing, followerCount: $followerCount)';
}


}

/// @nodoc
abstract mixin class _$FollowStateModelCopyWith<$Res> implements $FollowStateModelCopyWith<$Res> {
  factory _$FollowStateModelCopyWith(_FollowStateModel value, $Res Function(_FollowStateModel) _then) = __$FollowStateModelCopyWithImpl;
@override @useResult
$Res call({
 bool isFollowing, int followerCount
});




}
/// @nodoc
class __$FollowStateModelCopyWithImpl<$Res>
    implements _$FollowStateModelCopyWith<$Res> {
  __$FollowStateModelCopyWithImpl(this._self, this._then);

  final _FollowStateModel _self;
  final $Res Function(_FollowStateModel) _then;

/// Create a copy of FollowStateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isFollowing = null,Object? followerCount = null,}) {
  return _then(_FollowStateModel(
isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UserSummaryModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified; String? get bio; bool get isFollowing; bool get followsYou;
/// Create a copy of UserSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<UserSummaryModel> get copyWith => _$UserSummaryModelCopyWithImpl<UserSummaryModel>(this as UserSummaryModel, _$identity);

  /// Serializes this UserSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followsYou, followsYou) || other.followsYou == followsYou));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified,bio,isFollowing,followsYou);

@override
String toString() {
  return 'UserSummaryModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, bio: $bio, isFollowing: $isFollowing, followsYou: $followsYou)';
}


}

/// @nodoc
abstract mixin class $UserSummaryModelCopyWith<$Res>  {
  factory $UserSummaryModelCopyWith(UserSummaryModel value, $Res Function(UserSummaryModel) _then) = _$UserSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, String? bio, bool isFollowing, bool followsYou
});




}
/// @nodoc
class _$UserSummaryModelCopyWithImpl<$Res>
    implements $UserSummaryModelCopyWith<$Res> {
  _$UserSummaryModelCopyWithImpl(this._self, this._then);

  final UserSummaryModel _self;
  final $Res Function(UserSummaryModel) _then;

/// Create a copy of UserSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? bio = freezed,Object? isFollowing = null,Object? followsYou = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followsYou: null == followsYou ? _self.followsYou : followsYou // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSummaryModel].
extension UserSummaryModelPatterns on UserSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _UserSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? bio,  bool isFollowing,  bool followsYou)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSummaryModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.bio,_that.isFollowing,_that.followsYou);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? bio,  bool isFollowing,  bool followsYou)  $default,) {final _that = this;
switch (_that) {
case _UserSummaryModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.bio,_that.isFollowing,_that.followsYou);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? bio,  bool isFollowing,  bool followsYou)?  $default,) {final _that = this;
switch (_that) {
case _UserSummaryModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.bio,_that.isFollowing,_that.followsYou);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSummaryModel extends UserSummaryModel {
  const _UserSummaryModel({required this.id, required this.displayName, required this.username, this.avatarUrl, this.isVerified = false, this.bio, this.isFollowing = false, this.followsYou = false}): super._();
  factory _UserSummaryModel.fromJson(Map<String, dynamic> json) => _$UserSummaryModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;
@override final  String? bio;
@override@JsonKey() final  bool isFollowing;
@override@JsonKey() final  bool followsYou;

/// Create a copy of UserSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSummaryModelCopyWith<_UserSummaryModel> get copyWith => __$UserSummaryModelCopyWithImpl<_UserSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followsYou, followsYou) || other.followsYou == followsYou));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified,bio,isFollowing,followsYou);

@override
String toString() {
  return 'UserSummaryModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, bio: $bio, isFollowing: $isFollowing, followsYou: $followsYou)';
}


}

/// @nodoc
abstract mixin class _$UserSummaryModelCopyWith<$Res> implements $UserSummaryModelCopyWith<$Res> {
  factory _$UserSummaryModelCopyWith(_UserSummaryModel value, $Res Function(_UserSummaryModel) _then) = __$UserSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, String? bio, bool isFollowing, bool followsYou
});




}
/// @nodoc
class __$UserSummaryModelCopyWithImpl<$Res>
    implements _$UserSummaryModelCopyWith<$Res> {
  __$UserSummaryModelCopyWithImpl(this._self, this._then);

  final _UserSummaryModel _self;
  final $Res Function(_UserSummaryModel) _then;

/// Create a copy of UserSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? bio = freezed,Object? isFollowing = null,Object? followsYou = null,}) {
  return _then(_UserSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followsYou: null == followsYou ? _self.followsYou : followsYou // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$UserSummaryPageModel {

 List<UserSummaryModel> get items; String? get nextCursor;
/// Create a copy of UserSummaryPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSummaryPageModelCopyWith<UserSummaryPageModel> get copyWith => _$UserSummaryPageModelCopyWithImpl<UserSummaryPageModel>(this as UserSummaryPageModel, _$identity);

  /// Serializes this UserSummaryPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSummaryPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'UserSummaryPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $UserSummaryPageModelCopyWith<$Res>  {
  factory $UserSummaryPageModelCopyWith(UserSummaryPageModel value, $Res Function(UserSummaryPageModel) _then) = _$UserSummaryPageModelCopyWithImpl;
@useResult
$Res call({
 List<UserSummaryModel> items, String? nextCursor
});




}
/// @nodoc
class _$UserSummaryPageModelCopyWithImpl<$Res>
    implements $UserSummaryPageModelCopyWith<$Res> {
  _$UserSummaryPageModelCopyWithImpl(this._self, this._then);

  final UserSummaryPageModel _self;
  final $Res Function(UserSummaryPageModel) _then;

/// Create a copy of UserSummaryPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UserSummaryModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSummaryPageModel].
extension UserSummaryPageModelPatterns on UserSummaryPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSummaryPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSummaryPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSummaryPageModel value)  $default,){
final _that = this;
switch (_that) {
case _UserSummaryPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSummaryPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserSummaryPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserSummaryModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSummaryPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserSummaryModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _UserSummaryPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserSummaryModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _UserSummaryPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSummaryPageModel implements UserSummaryPageModel {
  const _UserSummaryPageModel({final  List<UserSummaryModel> items = const <UserSummaryModel>[], this.nextCursor}): _items = items;
  factory _UserSummaryPageModel.fromJson(Map<String, dynamic> json) => _$UserSummaryPageModelFromJson(json);

 final  List<UserSummaryModel> _items;
@override@JsonKey() List<UserSummaryModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of UserSummaryPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSummaryPageModelCopyWith<_UserSummaryPageModel> get copyWith => __$UserSummaryPageModelCopyWithImpl<_UserSummaryPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSummaryPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSummaryPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'UserSummaryPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$UserSummaryPageModelCopyWith<$Res> implements $UserSummaryPageModelCopyWith<$Res> {
  factory _$UserSummaryPageModelCopyWith(_UserSummaryPageModel value, $Res Function(_UserSummaryPageModel) _then) = __$UserSummaryPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<UserSummaryModel> items, String? nextCursor
});




}
/// @nodoc
class __$UserSummaryPageModelCopyWithImpl<$Res>
    implements _$UserSummaryPageModelCopyWith<$Res> {
  __$UserSummaryPageModelCopyWithImpl(this._self, this._then);

  final _UserSummaryPageModel _self;
  final $Res Function(_UserSummaryPageModel) _then;

/// Create a copy of UserSummaryPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_UserSummaryPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<UserSummaryModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InterestsModel {

 List<String> get fieldIds; List<String> get topicIds;
/// Create a copy of InterestsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterestsModelCopyWith<InterestsModel> get copyWith => _$InterestsModelCopyWithImpl<InterestsModel>(this as InterestsModel, _$identity);

  /// Serializes this InterestsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterestsModel&&const DeepCollectionEquality().equals(other.fieldIds, fieldIds)&&const DeepCollectionEquality().equals(other.topicIds, topicIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fieldIds),const DeepCollectionEquality().hash(topicIds));

@override
String toString() {
  return 'InterestsModel(fieldIds: $fieldIds, topicIds: $topicIds)';
}


}

/// @nodoc
abstract mixin class $InterestsModelCopyWith<$Res>  {
  factory $InterestsModelCopyWith(InterestsModel value, $Res Function(InterestsModel) _then) = _$InterestsModelCopyWithImpl;
@useResult
$Res call({
 List<String> fieldIds, List<String> topicIds
});




}
/// @nodoc
class _$InterestsModelCopyWithImpl<$Res>
    implements $InterestsModelCopyWith<$Res> {
  _$InterestsModelCopyWithImpl(this._self, this._then);

  final InterestsModel _self;
  final $Res Function(InterestsModel) _then;

/// Create a copy of InterestsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fieldIds = null,Object? topicIds = null,}) {
  return _then(_self.copyWith(
fieldIds: null == fieldIds ? _self.fieldIds : fieldIds // ignore: cast_nullable_to_non_nullable
as List<String>,topicIds: null == topicIds ? _self.topicIds : topicIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [InterestsModel].
extension InterestsModelPatterns on InterestsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterestsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterestsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterestsModel value)  $default,){
final _that = this;
switch (_that) {
case _InterestsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterestsModel value)?  $default,){
final _that = this;
switch (_that) {
case _InterestsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> fieldIds,  List<String> topicIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterestsModel() when $default != null:
return $default(_that.fieldIds,_that.topicIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> fieldIds,  List<String> topicIds)  $default,) {final _that = this;
switch (_that) {
case _InterestsModel():
return $default(_that.fieldIds,_that.topicIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> fieldIds,  List<String> topicIds)?  $default,) {final _that = this;
switch (_that) {
case _InterestsModel() when $default != null:
return $default(_that.fieldIds,_that.topicIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InterestsModel extends InterestsModel {
  const _InterestsModel({final  List<String> fieldIds = const <String>[], final  List<String> topicIds = const <String>[]}): _fieldIds = fieldIds,_topicIds = topicIds,super._();
  factory _InterestsModel.fromJson(Map<String, dynamic> json) => _$InterestsModelFromJson(json);

 final  List<String> _fieldIds;
@override@JsonKey() List<String> get fieldIds {
  if (_fieldIds is EqualUnmodifiableListView) return _fieldIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fieldIds);
}

 final  List<String> _topicIds;
@override@JsonKey() List<String> get topicIds {
  if (_topicIds is EqualUnmodifiableListView) return _topicIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topicIds);
}


/// Create a copy of InterestsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterestsModelCopyWith<_InterestsModel> get copyWith => __$InterestsModelCopyWithImpl<_InterestsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InterestsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterestsModel&&const DeepCollectionEquality().equals(other._fieldIds, _fieldIds)&&const DeepCollectionEquality().equals(other._topicIds, _topicIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fieldIds),const DeepCollectionEquality().hash(_topicIds));

@override
String toString() {
  return 'InterestsModel(fieldIds: $fieldIds, topicIds: $topicIds)';
}


}

/// @nodoc
abstract mixin class _$InterestsModelCopyWith<$Res> implements $InterestsModelCopyWith<$Res> {
  factory _$InterestsModelCopyWith(_InterestsModel value, $Res Function(_InterestsModel) _then) = __$InterestsModelCopyWithImpl;
@override @useResult
$Res call({
 List<String> fieldIds, List<String> topicIds
});




}
/// @nodoc
class __$InterestsModelCopyWithImpl<$Res>
    implements _$InterestsModelCopyWith<$Res> {
  __$InterestsModelCopyWithImpl(this._self, this._then);

  final _InterestsModel _self;
  final $Res Function(_InterestsModel) _then;

/// Create a copy of InterestsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fieldIds = null,Object? topicIds = null,}) {
  return _then(_InterestsModel(
fieldIds: null == fieldIds ? _self._fieldIds : fieldIds // ignore: cast_nullable_to_non_nullable
as List<String>,topicIds: null == topicIds ? _self._topicIds : topicIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
