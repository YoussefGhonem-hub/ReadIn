// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeModel {

 String get id; String get email; String get displayName; String get username; String? get avatarUrl; String? get bio; Map<String, String> get links; String get uiLanguage; String get articleLanguage; String get theme; String get timeZone; String get reminderTime; bool get isVerified; bool get onboardingCompleted; List<String> get roles; List<String> get permissions; InterestsModel get interests;
/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeModelCopyWith<MeModel> get copyWith => _$MeModelCopyWithImpl<MeModel>(this as MeModel, _$identity);

  /// Serializes this MeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.links, links)&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.articleLanguage, articleLanguage) || other.articleLanguage == articleLanguage)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.reminderTime, reminderTime) || other.reminderTime == reminderTime)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.interests, interests) || other.interests == interests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,username,avatarUrl,bio,const DeepCollectionEquality().hash(links),uiLanguage,articleLanguage,theme,timeZone,reminderTime,isVerified,onboardingCompleted,const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(permissions),interests);

@override
String toString() {
  return 'MeModel(id: $id, email: $email, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, bio: $bio, links: $links, uiLanguage: $uiLanguage, articleLanguage: $articleLanguage, theme: $theme, timeZone: $timeZone, reminderTime: $reminderTime, isVerified: $isVerified, onboardingCompleted: $onboardingCompleted, roles: $roles, permissions: $permissions, interests: $interests)';
}


}

/// @nodoc
abstract mixin class $MeModelCopyWith<$Res>  {
  factory $MeModelCopyWith(MeModel value, $Res Function(MeModel) _then) = _$MeModelCopyWithImpl;
@useResult
$Res call({
 String id, String email, String displayName, String username, String? avatarUrl, String? bio, Map<String, String> links, String uiLanguage, String articleLanguage, String theme, String timeZone, String reminderTime, bool isVerified, bool onboardingCompleted, List<String> roles, List<String> permissions, InterestsModel interests
});


$InterestsModelCopyWith<$Res> get interests;

}
/// @nodoc
class _$MeModelCopyWithImpl<$Res>
    implements $MeModelCopyWith<$Res> {
  _$MeModelCopyWithImpl(this._self, this._then);

  final MeModel _self;
  final $Res Function(MeModel) _then;

/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? links = null,Object? uiLanguage = null,Object? articleLanguage = null,Object? theme = null,Object? timeZone = null,Object? reminderTime = null,Object? isVerified = null,Object? onboardingCompleted = null,Object? roles = null,Object? permissions = null,Object? interests = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as Map<String, String>,uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,articleLanguage: null == articleLanguage ? _self.articleLanguage : articleLanguage // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,reminderTime: null == reminderTime ? _self.reminderTime : reminderTime // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,interests: null == interests ? _self.interests : interests // ignore: cast_nullable_to_non_nullable
as InterestsModel,
  ));
}
/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InterestsModelCopyWith<$Res> get interests {
  
  return $InterestsModelCopyWith<$Res>(_self.interests, (value) {
    return _then(_self.copyWith(interests: value));
  });
}
}


/// Adds pattern-matching-related methods to [MeModel].
extension MeModelPatterns on MeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeModel value)  $default,){
final _that = this;
switch (_that) {
case _MeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeModel value)?  $default,){
final _that = this;
switch (_that) {
case _MeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String username,  String? avatarUrl,  String? bio,  Map<String, String> links,  String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime,  bool isVerified,  bool onboardingCompleted,  List<String> roles,  List<String> permissions,  InterestsModel interests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeModel() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.username,_that.avatarUrl,_that.bio,_that.links,_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime,_that.isVerified,_that.onboardingCompleted,_that.roles,_that.permissions,_that.interests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String username,  String? avatarUrl,  String? bio,  Map<String, String> links,  String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime,  bool isVerified,  bool onboardingCompleted,  List<String> roles,  List<String> permissions,  InterestsModel interests)  $default,) {final _that = this;
switch (_that) {
case _MeModel():
return $default(_that.id,_that.email,_that.displayName,_that.username,_that.avatarUrl,_that.bio,_that.links,_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime,_that.isVerified,_that.onboardingCompleted,_that.roles,_that.permissions,_that.interests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String displayName,  String username,  String? avatarUrl,  String? bio,  Map<String, String> links,  String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime,  bool isVerified,  bool onboardingCompleted,  List<String> roles,  List<String> permissions,  InterestsModel interests)?  $default,) {final _that = this;
switch (_that) {
case _MeModel() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.username,_that.avatarUrl,_that.bio,_that.links,_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime,_that.isVerified,_that.onboardingCompleted,_that.roles,_that.permissions,_that.interests);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeModel extends MeModel {
  const _MeModel({required this.id, required this.email, required this.displayName, required this.username, this.avatarUrl, this.bio, final  Map<String, String> links = const <String, String>{}, this.uiLanguage = 'ar', this.articleLanguage = 'ar-EG', this.theme = 'system', this.timeZone = 'UTC', this.reminderTime = '08:00', this.isVerified = false, this.onboardingCompleted = false, final  List<String> roles = const <String>[], final  List<String> permissions = const <String>[], this.interests = const InterestsModel()}): _links = links,_roles = roles,_permissions = permissions,super._();
  factory _MeModel.fromJson(Map<String, dynamic> json) => _$MeModelFromJson(json);

@override final  String id;
@override final  String email;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override final  String? bio;
 final  Map<String, String> _links;
@override@JsonKey() Map<String, String> get links {
  if (_links is EqualUnmodifiableMapView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_links);
}

@override@JsonKey() final  String uiLanguage;
@override@JsonKey() final  String articleLanguage;
@override@JsonKey() final  String theme;
@override@JsonKey() final  String timeZone;
@override@JsonKey() final  String reminderTime;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool onboardingCompleted;
 final  List<String> _roles;
@override@JsonKey() List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

 final  List<String> _permissions;
@override@JsonKey() List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

@override@JsonKey() final  InterestsModel interests;

/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeModelCopyWith<_MeModel> get copyWith => __$MeModelCopyWithImpl<_MeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._links, _links)&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.articleLanguage, articleLanguage) || other.articleLanguage == articleLanguage)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.reminderTime, reminderTime) || other.reminderTime == reminderTime)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.interests, interests) || other.interests == interests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,username,avatarUrl,bio,const DeepCollectionEquality().hash(_links),uiLanguage,articleLanguage,theme,timeZone,reminderTime,isVerified,onboardingCompleted,const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_permissions),interests);

@override
String toString() {
  return 'MeModel(id: $id, email: $email, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, bio: $bio, links: $links, uiLanguage: $uiLanguage, articleLanguage: $articleLanguage, theme: $theme, timeZone: $timeZone, reminderTime: $reminderTime, isVerified: $isVerified, onboardingCompleted: $onboardingCompleted, roles: $roles, permissions: $permissions, interests: $interests)';
}


}

/// @nodoc
abstract mixin class _$MeModelCopyWith<$Res> implements $MeModelCopyWith<$Res> {
  factory _$MeModelCopyWith(_MeModel value, $Res Function(_MeModel) _then) = __$MeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String displayName, String username, String? avatarUrl, String? bio, Map<String, String> links, String uiLanguage, String articleLanguage, String theme, String timeZone, String reminderTime, bool isVerified, bool onboardingCompleted, List<String> roles, List<String> permissions, InterestsModel interests
});


@override $InterestsModelCopyWith<$Res> get interests;

}
/// @nodoc
class __$MeModelCopyWithImpl<$Res>
    implements _$MeModelCopyWith<$Res> {
  __$MeModelCopyWithImpl(this._self, this._then);

  final _MeModel _self;
  final $Res Function(_MeModel) _then;

/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? links = null,Object? uiLanguage = null,Object? articleLanguage = null,Object? theme = null,Object? timeZone = null,Object? reminderTime = null,Object? isVerified = null,Object? onboardingCompleted = null,Object? roles = null,Object? permissions = null,Object? interests = null,}) {
  return _then(_MeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as Map<String, String>,uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,articleLanguage: null == articleLanguage ? _self.articleLanguage : articleLanguage // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,reminderTime: null == reminderTime ? _self.reminderTime : reminderTime // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,interests: null == interests ? _self.interests : interests // ignore: cast_nullable_to_non_nullable
as InterestsModel,
  ));
}

/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InterestsModelCopyWith<$Res> get interests {
  
  return $InterestsModelCopyWith<$Res>(_self.interests, (value) {
    return _then(_self.copyWith(interests: value));
  });
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

class _InterestsModel implements InterestsModel {
  const _InterestsModel({final  List<String> fieldIds = const <String>[], final  List<String> topicIds = const <String>[]}): _fieldIds = fieldIds,_topicIds = topicIds;
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


/// @nodoc
mixin _$SyncUserRequest {

 String? get uiLanguage; String? get timeZone;
/// Create a copy of SyncUserRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncUserRequestCopyWith<SyncUserRequest> get copyWith => _$SyncUserRequestCopyWithImpl<SyncUserRequest>(this as SyncUserRequest, _$identity);

  /// Serializes this SyncUserRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncUserRequest&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uiLanguage,timeZone);

@override
String toString() {
  return 'SyncUserRequest(uiLanguage: $uiLanguage, timeZone: $timeZone)';
}


}

/// @nodoc
abstract mixin class $SyncUserRequestCopyWith<$Res>  {
  factory $SyncUserRequestCopyWith(SyncUserRequest value, $Res Function(SyncUserRequest) _then) = _$SyncUserRequestCopyWithImpl;
@useResult
$Res call({
 String? uiLanguage, String? timeZone
});




}
/// @nodoc
class _$SyncUserRequestCopyWithImpl<$Res>
    implements $SyncUserRequestCopyWith<$Res> {
  _$SyncUserRequestCopyWithImpl(this._self, this._then);

  final SyncUserRequest _self;
  final $Res Function(SyncUserRequest) _then;

/// Create a copy of SyncUserRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uiLanguage = freezed,Object? timeZone = freezed,}) {
  return _then(_self.copyWith(
uiLanguage: freezed == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String?,timeZone: freezed == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncUserRequest].
extension SyncUserRequestPatterns on SyncUserRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncUserRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncUserRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncUserRequest value)  $default,){
final _that = this;
switch (_that) {
case _SyncUserRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncUserRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SyncUserRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? uiLanguage,  String? timeZone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncUserRequest() when $default != null:
return $default(_that.uiLanguage,_that.timeZone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? uiLanguage,  String? timeZone)  $default,) {final _that = this;
switch (_that) {
case _SyncUserRequest():
return $default(_that.uiLanguage,_that.timeZone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? uiLanguage,  String? timeZone)?  $default,) {final _that = this;
switch (_that) {
case _SyncUserRequest() when $default != null:
return $default(_that.uiLanguage,_that.timeZone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncUserRequest implements SyncUserRequest {
  const _SyncUserRequest({this.uiLanguage, this.timeZone});
  factory _SyncUserRequest.fromJson(Map<String, dynamic> json) => _$SyncUserRequestFromJson(json);

@override final  String? uiLanguage;
@override final  String? timeZone;

/// Create a copy of SyncUserRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncUserRequestCopyWith<_SyncUserRequest> get copyWith => __$SyncUserRequestCopyWithImpl<_SyncUserRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncUserRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncUserRequest&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uiLanguage,timeZone);

@override
String toString() {
  return 'SyncUserRequest(uiLanguage: $uiLanguage, timeZone: $timeZone)';
}


}

/// @nodoc
abstract mixin class _$SyncUserRequestCopyWith<$Res> implements $SyncUserRequestCopyWith<$Res> {
  factory _$SyncUserRequestCopyWith(_SyncUserRequest value, $Res Function(_SyncUserRequest) _then) = __$SyncUserRequestCopyWithImpl;
@override @useResult
$Res call({
 String? uiLanguage, String? timeZone
});




}
/// @nodoc
class __$SyncUserRequestCopyWithImpl<$Res>
    implements _$SyncUserRequestCopyWith<$Res> {
  __$SyncUserRequestCopyWithImpl(this._self, this._then);

  final _SyncUserRequest _self;
  final $Res Function(_SyncUserRequest) _then;

/// Create a copy of SyncUserRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uiLanguage = freezed,Object? timeZone = freezed,}) {
  return _then(_SyncUserRequest(
uiLanguage: freezed == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String?,timeZone: freezed == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
