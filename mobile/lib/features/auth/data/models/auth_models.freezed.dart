// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeModel {

 String get id; String? get phoneNumber; String? get email; String get displayName; String get username; String? get avatarUrl; String? get bio;// The API writes nulls, e.g. `{ "gitHub": null }`.
 Map<String, String?> get links; String get uiLanguage; String get articleLanguage; String get theme; String get timeZone; String get reminderTime; bool get isVerified; bool get onboardingCompleted; bool get mustChangePassword; bool get mustSetRecoveryPin; bool get isProfileComplete; bool get hasRecoveryPin;// Added with Google/Apple sign in; older APIs leave them out.
 bool get hasPassword; List<ExternalLoginModel> get externalLogins; List<String> get roles; List<String> get permissions; InterestsModel get interests;// F14; older APIs leave it out (reading stats stay private).
 PrivacyModel get privacy;
/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeModelCopyWith<MeModel> get copyWith => _$MeModelCopyWithImpl<MeModel>(this as MeModel, _$identity);

  /// Serializes this MeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.links, links)&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.articleLanguage, articleLanguage) || other.articleLanguage == articleLanguage)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.reminderTime, reminderTime) || other.reminderTime == reminderTime)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.mustChangePassword, mustChangePassword) || other.mustChangePassword == mustChangePassword)&&(identical(other.mustSetRecoveryPin, mustSetRecoveryPin) || other.mustSetRecoveryPin == mustSetRecoveryPin)&&(identical(other.isProfileComplete, isProfileComplete) || other.isProfileComplete == isProfileComplete)&&(identical(other.hasRecoveryPin, hasRecoveryPin) || other.hasRecoveryPin == hasRecoveryPin)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword)&&const DeepCollectionEquality().equals(other.externalLogins, externalLogins)&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.interests, interests) || other.interests == interests)&&(identical(other.privacy, privacy) || other.privacy == privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,phoneNumber,email,displayName,username,avatarUrl,bio,const DeepCollectionEquality().hash(links),uiLanguage,articleLanguage,theme,timeZone,reminderTime,isVerified,onboardingCompleted,mustChangePassword,mustSetRecoveryPin,isProfileComplete,hasRecoveryPin,hasPassword,const DeepCollectionEquality().hash(externalLogins),const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(permissions),interests,privacy]);

@override
String toString() {
  return 'MeModel(id: $id, phoneNumber: $phoneNumber, email: $email, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, bio: $bio, links: $links, uiLanguage: $uiLanguage, articleLanguage: $articleLanguage, theme: $theme, timeZone: $timeZone, reminderTime: $reminderTime, isVerified: $isVerified, onboardingCompleted: $onboardingCompleted, mustChangePassword: $mustChangePassword, mustSetRecoveryPin: $mustSetRecoveryPin, isProfileComplete: $isProfileComplete, hasRecoveryPin: $hasRecoveryPin, hasPassword: $hasPassword, externalLogins: $externalLogins, roles: $roles, permissions: $permissions, interests: $interests, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class $MeModelCopyWith<$Res>  {
  factory $MeModelCopyWith(MeModel value, $Res Function(MeModel) _then) = _$MeModelCopyWithImpl;
@useResult
$Res call({
 String id, String? phoneNumber, String? email, String displayName, String username, String? avatarUrl, String? bio, Map<String, String?> links, String uiLanguage, String articleLanguage, String theme, String timeZone, String reminderTime, bool isVerified, bool onboardingCompleted, bool mustChangePassword, bool mustSetRecoveryPin, bool isProfileComplete, bool hasRecoveryPin, bool hasPassword, List<ExternalLoginModel> externalLogins, List<String> roles, List<String> permissions, InterestsModel interests, PrivacyModel privacy
});


$InterestsModelCopyWith<$Res> get interests;$PrivacyModelCopyWith<$Res> get privacy;

}
/// @nodoc
class _$MeModelCopyWithImpl<$Res>
    implements $MeModelCopyWith<$Res> {
  _$MeModelCopyWithImpl(this._self, this._then);

  final MeModel _self;
  final $Res Function(MeModel) _then;

/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phoneNumber = freezed,Object? email = freezed,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? links = null,Object? uiLanguage = null,Object? articleLanguage = null,Object? theme = null,Object? timeZone = null,Object? reminderTime = null,Object? isVerified = null,Object? onboardingCompleted = null,Object? mustChangePassword = null,Object? mustSetRecoveryPin = null,Object? isProfileComplete = null,Object? hasRecoveryPin = null,Object? hasPassword = null,Object? externalLogins = null,Object? roles = null,Object? permissions = null,Object? interests = null,Object? privacy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,articleLanguage: null == articleLanguage ? _self.articleLanguage : articleLanguage // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,reminderTime: null == reminderTime ? _self.reminderTime : reminderTime // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,mustChangePassword: null == mustChangePassword ? _self.mustChangePassword : mustChangePassword // ignore: cast_nullable_to_non_nullable
as bool,mustSetRecoveryPin: null == mustSetRecoveryPin ? _self.mustSetRecoveryPin : mustSetRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,isProfileComplete: null == isProfileComplete ? _self.isProfileComplete : isProfileComplete // ignore: cast_nullable_to_non_nullable
as bool,hasRecoveryPin: null == hasRecoveryPin ? _self.hasRecoveryPin : hasRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,externalLogins: null == externalLogins ? _self.externalLogins : externalLogins // ignore: cast_nullable_to_non_nullable
as List<ExternalLoginModel>,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,interests: null == interests ? _self.interests : interests // ignore: cast_nullable_to_non_nullable
as InterestsModel,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as PrivacyModel,
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
}/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<$Res> get privacy {
  
  return $PrivacyModelCopyWith<$Res>(_self.privacy, (value) {
    return _then(_self.copyWith(privacy: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? phoneNumber,  String? email,  String displayName,  String username,  String? avatarUrl,  String? bio,  Map<String, String?> links,  String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime,  bool isVerified,  bool onboardingCompleted,  bool mustChangePassword,  bool mustSetRecoveryPin,  bool isProfileComplete,  bool hasRecoveryPin,  bool hasPassword,  List<ExternalLoginModel> externalLogins,  List<String> roles,  List<String> permissions,  InterestsModel interests,  PrivacyModel privacy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.email,_that.displayName,_that.username,_that.avatarUrl,_that.bio,_that.links,_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime,_that.isVerified,_that.onboardingCompleted,_that.mustChangePassword,_that.mustSetRecoveryPin,_that.isProfileComplete,_that.hasRecoveryPin,_that.hasPassword,_that.externalLogins,_that.roles,_that.permissions,_that.interests,_that.privacy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? phoneNumber,  String? email,  String displayName,  String username,  String? avatarUrl,  String? bio,  Map<String, String?> links,  String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime,  bool isVerified,  bool onboardingCompleted,  bool mustChangePassword,  bool mustSetRecoveryPin,  bool isProfileComplete,  bool hasRecoveryPin,  bool hasPassword,  List<ExternalLoginModel> externalLogins,  List<String> roles,  List<String> permissions,  InterestsModel interests,  PrivacyModel privacy)  $default,) {final _that = this;
switch (_that) {
case _MeModel():
return $default(_that.id,_that.phoneNumber,_that.email,_that.displayName,_that.username,_that.avatarUrl,_that.bio,_that.links,_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime,_that.isVerified,_that.onboardingCompleted,_that.mustChangePassword,_that.mustSetRecoveryPin,_that.isProfileComplete,_that.hasRecoveryPin,_that.hasPassword,_that.externalLogins,_that.roles,_that.permissions,_that.interests,_that.privacy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? phoneNumber,  String? email,  String displayName,  String username,  String? avatarUrl,  String? bio,  Map<String, String?> links,  String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime,  bool isVerified,  bool onboardingCompleted,  bool mustChangePassword,  bool mustSetRecoveryPin,  bool isProfileComplete,  bool hasRecoveryPin,  bool hasPassword,  List<ExternalLoginModel> externalLogins,  List<String> roles,  List<String> permissions,  InterestsModel interests,  PrivacyModel privacy)?  $default,) {final _that = this;
switch (_that) {
case _MeModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.email,_that.displayName,_that.username,_that.avatarUrl,_that.bio,_that.links,_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime,_that.isVerified,_that.onboardingCompleted,_that.mustChangePassword,_that.mustSetRecoveryPin,_that.isProfileComplete,_that.hasRecoveryPin,_that.hasPassword,_that.externalLogins,_that.roles,_that.permissions,_that.interests,_that.privacy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeModel extends MeModel {
  const _MeModel({required this.id, this.phoneNumber, this.email, required this.displayName, required this.username, this.avatarUrl, this.bio, final  Map<String, String?> links = const <String, String?>{}, this.uiLanguage = 'ar', this.articleLanguage = 'ar-EG', this.theme = 'system', this.timeZone = 'UTC', this.reminderTime = '08:00', this.isVerified = false, this.onboardingCompleted = false, this.mustChangePassword = false, this.mustSetRecoveryPin = false, this.isProfileComplete = true, this.hasRecoveryPin = true, this.hasPassword = true, final  List<ExternalLoginModel> externalLogins = const <ExternalLoginModel>[], final  List<String> roles = const <String>[], final  List<String> permissions = const <String>[], this.interests = const InterestsModel(), this.privacy = const PrivacyModel()}): _links = links,_externalLogins = externalLogins,_roles = roles,_permissions = permissions,super._();
  factory _MeModel.fromJson(Map<String, dynamic> json) => _$MeModelFromJson(json);

@override final  String id;
@override final  String? phoneNumber;
@override final  String? email;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override final  String? bio;
// The API writes nulls, e.g. `{ "gitHub": null }`.
 final  Map<String, String?> _links;
// The API writes nulls, e.g. `{ "gitHub": null }`.
@override@JsonKey() Map<String, String?> get links {
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
@override@JsonKey() final  bool mustChangePassword;
@override@JsonKey() final  bool mustSetRecoveryPin;
@override@JsonKey() final  bool isProfileComplete;
@override@JsonKey() final  bool hasRecoveryPin;
// Added with Google/Apple sign in; older APIs leave them out.
@override@JsonKey() final  bool hasPassword;
 final  List<ExternalLoginModel> _externalLogins;
@override@JsonKey() List<ExternalLoginModel> get externalLogins {
  if (_externalLogins is EqualUnmodifiableListView) return _externalLogins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_externalLogins);
}

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
// F14; older APIs leave it out (reading stats stay private).
@override@JsonKey() final  PrivacyModel privacy;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._links, _links)&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.articleLanguage, articleLanguage) || other.articleLanguage == articleLanguage)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.reminderTime, reminderTime) || other.reminderTime == reminderTime)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.mustChangePassword, mustChangePassword) || other.mustChangePassword == mustChangePassword)&&(identical(other.mustSetRecoveryPin, mustSetRecoveryPin) || other.mustSetRecoveryPin == mustSetRecoveryPin)&&(identical(other.isProfileComplete, isProfileComplete) || other.isProfileComplete == isProfileComplete)&&(identical(other.hasRecoveryPin, hasRecoveryPin) || other.hasRecoveryPin == hasRecoveryPin)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword)&&const DeepCollectionEquality().equals(other._externalLogins, _externalLogins)&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.interests, interests) || other.interests == interests)&&(identical(other.privacy, privacy) || other.privacy == privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,phoneNumber,email,displayName,username,avatarUrl,bio,const DeepCollectionEquality().hash(_links),uiLanguage,articleLanguage,theme,timeZone,reminderTime,isVerified,onboardingCompleted,mustChangePassword,mustSetRecoveryPin,isProfileComplete,hasRecoveryPin,hasPassword,const DeepCollectionEquality().hash(_externalLogins),const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_permissions),interests,privacy]);

@override
String toString() {
  return 'MeModel(id: $id, phoneNumber: $phoneNumber, email: $email, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, bio: $bio, links: $links, uiLanguage: $uiLanguage, articleLanguage: $articleLanguage, theme: $theme, timeZone: $timeZone, reminderTime: $reminderTime, isVerified: $isVerified, onboardingCompleted: $onboardingCompleted, mustChangePassword: $mustChangePassword, mustSetRecoveryPin: $mustSetRecoveryPin, isProfileComplete: $isProfileComplete, hasRecoveryPin: $hasRecoveryPin, hasPassword: $hasPassword, externalLogins: $externalLogins, roles: $roles, permissions: $permissions, interests: $interests, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class _$MeModelCopyWith<$Res> implements $MeModelCopyWith<$Res> {
  factory _$MeModelCopyWith(_MeModel value, $Res Function(_MeModel) _then) = __$MeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? phoneNumber, String? email, String displayName, String username, String? avatarUrl, String? bio, Map<String, String?> links, String uiLanguage, String articleLanguage, String theme, String timeZone, String reminderTime, bool isVerified, bool onboardingCompleted, bool mustChangePassword, bool mustSetRecoveryPin, bool isProfileComplete, bool hasRecoveryPin, bool hasPassword, List<ExternalLoginModel> externalLogins, List<String> roles, List<String> permissions, InterestsModel interests, PrivacyModel privacy
});


@override $InterestsModelCopyWith<$Res> get interests;@override $PrivacyModelCopyWith<$Res> get privacy;

}
/// @nodoc
class __$MeModelCopyWithImpl<$Res>
    implements _$MeModelCopyWith<$Res> {
  __$MeModelCopyWithImpl(this._self, this._then);

  final _MeModel _self;
  final $Res Function(_MeModel) _then;

/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phoneNumber = freezed,Object? email = freezed,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? links = null,Object? uiLanguage = null,Object? articleLanguage = null,Object? theme = null,Object? timeZone = null,Object? reminderTime = null,Object? isVerified = null,Object? onboardingCompleted = null,Object? mustChangePassword = null,Object? mustSetRecoveryPin = null,Object? isProfileComplete = null,Object? hasRecoveryPin = null,Object? hasPassword = null,Object? externalLogins = null,Object? roles = null,Object? permissions = null,Object? interests = null,Object? privacy = null,}) {
  return _then(_MeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,articleLanguage: null == articleLanguage ? _self.articleLanguage : articleLanguage // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,reminderTime: null == reminderTime ? _self.reminderTime : reminderTime // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,mustChangePassword: null == mustChangePassword ? _self.mustChangePassword : mustChangePassword // ignore: cast_nullable_to_non_nullable
as bool,mustSetRecoveryPin: null == mustSetRecoveryPin ? _self.mustSetRecoveryPin : mustSetRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,isProfileComplete: null == isProfileComplete ? _self.isProfileComplete : isProfileComplete // ignore: cast_nullable_to_non_nullable
as bool,hasRecoveryPin: null == hasRecoveryPin ? _self.hasRecoveryPin : hasRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,externalLogins: null == externalLogins ? _self._externalLogins : externalLogins // ignore: cast_nullable_to_non_nullable
as List<ExternalLoginModel>,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,interests: null == interests ? _self.interests : interests // ignore: cast_nullable_to_non_nullable
as InterestsModel,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as PrivacyModel,
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
}/// Create a copy of MeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<$Res> get privacy {
  
  return $PrivacyModelCopyWith<$Res>(_self.privacy, (value) {
    return _then(_self.copyWith(privacy: value));
  });
}
}


/// @nodoc
mixin _$ExternalLoginModel {

 String get provider; String? get email; DateTime? get linkedAt;
/// Create a copy of ExternalLoginModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExternalLoginModelCopyWith<ExternalLoginModel> get copyWith => _$ExternalLoginModelCopyWithImpl<ExternalLoginModel>(this as ExternalLoginModel, _$identity);

  /// Serializes this ExternalLoginModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExternalLoginModel&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.email, email) || other.email == email)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,email,linkedAt);

@override
String toString() {
  return 'ExternalLoginModel(provider: $provider, email: $email, linkedAt: $linkedAt)';
}


}

/// @nodoc
abstract mixin class $ExternalLoginModelCopyWith<$Res>  {
  factory $ExternalLoginModelCopyWith(ExternalLoginModel value, $Res Function(ExternalLoginModel) _then) = _$ExternalLoginModelCopyWithImpl;
@useResult
$Res call({
 String provider, String? email, DateTime? linkedAt
});




}
/// @nodoc
class _$ExternalLoginModelCopyWithImpl<$Res>
    implements $ExternalLoginModelCopyWith<$Res> {
  _$ExternalLoginModelCopyWithImpl(this._self, this._then);

  final ExternalLoginModel _self;
  final $Res Function(ExternalLoginModel) _then;

/// Create a copy of ExternalLoginModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? email = freezed,Object? linkedAt = freezed,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,linkedAt: freezed == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExternalLoginModel].
extension ExternalLoginModelPatterns on ExternalLoginModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExternalLoginModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExternalLoginModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExternalLoginModel value)  $default,){
final _that = this;
switch (_that) {
case _ExternalLoginModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExternalLoginModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExternalLoginModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String? email,  DateTime? linkedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExternalLoginModel() when $default != null:
return $default(_that.provider,_that.email,_that.linkedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String? email,  DateTime? linkedAt)  $default,) {final _that = this;
switch (_that) {
case _ExternalLoginModel():
return $default(_that.provider,_that.email,_that.linkedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String? email,  DateTime? linkedAt)?  $default,) {final _that = this;
switch (_that) {
case _ExternalLoginModel() when $default != null:
return $default(_that.provider,_that.email,_that.linkedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExternalLoginModel extends ExternalLoginModel {
  const _ExternalLoginModel({required this.provider, this.email, this.linkedAt}): super._();
  factory _ExternalLoginModel.fromJson(Map<String, dynamic> json) => _$ExternalLoginModelFromJson(json);

@override final  String provider;
@override final  String? email;
@override final  DateTime? linkedAt;

/// Create a copy of ExternalLoginModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExternalLoginModelCopyWith<_ExternalLoginModel> get copyWith => __$ExternalLoginModelCopyWithImpl<_ExternalLoginModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExternalLoginModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExternalLoginModel&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.email, email) || other.email == email)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,email,linkedAt);

@override
String toString() {
  return 'ExternalLoginModel(provider: $provider, email: $email, linkedAt: $linkedAt)';
}


}

/// @nodoc
abstract mixin class _$ExternalLoginModelCopyWith<$Res> implements $ExternalLoginModelCopyWith<$Res> {
  factory _$ExternalLoginModelCopyWith(_ExternalLoginModel value, $Res Function(_ExternalLoginModel) _then) = __$ExternalLoginModelCopyWithImpl;
@override @useResult
$Res call({
 String provider, String? email, DateTime? linkedAt
});




}
/// @nodoc
class __$ExternalLoginModelCopyWithImpl<$Res>
    implements _$ExternalLoginModelCopyWith<$Res> {
  __$ExternalLoginModelCopyWithImpl(this._self, this._then);

  final _ExternalLoginModel _self;
  final $Res Function(_ExternalLoginModel) _then;

/// Create a copy of ExternalLoginModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? email = freezed,Object? linkedAt = freezed,}) {
  return _then(_ExternalLoginModel(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,linkedAt: freezed == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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
mixin _$PrivacyModel {

 bool get publicReadingStats;
/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<PrivacyModel> get copyWith => _$PrivacyModelCopyWithImpl<PrivacyModel>(this as PrivacyModel, _$identity);

  /// Serializes this PrivacyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyModel&&(identical(other.publicReadingStats, publicReadingStats) || other.publicReadingStats == publicReadingStats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicReadingStats);

@override
String toString() {
  return 'PrivacyModel(publicReadingStats: $publicReadingStats)';
}


}

/// @nodoc
abstract mixin class $PrivacyModelCopyWith<$Res>  {
  factory $PrivacyModelCopyWith(PrivacyModel value, $Res Function(PrivacyModel) _then) = _$PrivacyModelCopyWithImpl;
@useResult
$Res call({
 bool publicReadingStats
});




}
/// @nodoc
class _$PrivacyModelCopyWithImpl<$Res>
    implements $PrivacyModelCopyWith<$Res> {
  _$PrivacyModelCopyWithImpl(this._self, this._then);

  final PrivacyModel _self;
  final $Res Function(PrivacyModel) _then;

/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicReadingStats = null,}) {
  return _then(_self.copyWith(
publicReadingStats: null == publicReadingStats ? _self.publicReadingStats : publicReadingStats // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivacyModel].
extension PrivacyModelPatterns on PrivacyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivacyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivacyModel value)  $default,){
final _that = this;
switch (_that) {
case _PrivacyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivacyModel value)?  $default,){
final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool publicReadingStats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
return $default(_that.publicReadingStats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool publicReadingStats)  $default,) {final _that = this;
switch (_that) {
case _PrivacyModel():
return $default(_that.publicReadingStats);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool publicReadingStats)?  $default,) {final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
return $default(_that.publicReadingStats);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrivacyModel implements PrivacyModel {
  const _PrivacyModel({this.publicReadingStats = false});
  factory _PrivacyModel.fromJson(Map<String, dynamic> json) => _$PrivacyModelFromJson(json);

@override@JsonKey() final  bool publicReadingStats;

/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivacyModelCopyWith<_PrivacyModel> get copyWith => __$PrivacyModelCopyWithImpl<_PrivacyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrivacyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivacyModel&&(identical(other.publicReadingStats, publicReadingStats) || other.publicReadingStats == publicReadingStats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicReadingStats);

@override
String toString() {
  return 'PrivacyModel(publicReadingStats: $publicReadingStats)';
}


}

/// @nodoc
abstract mixin class _$PrivacyModelCopyWith<$Res> implements $PrivacyModelCopyWith<$Res> {
  factory _$PrivacyModelCopyWith(_PrivacyModel value, $Res Function(_PrivacyModel) _then) = __$PrivacyModelCopyWithImpl;
@override @useResult
$Res call({
 bool publicReadingStats
});




}
/// @nodoc
class __$PrivacyModelCopyWithImpl<$Res>
    implements _$PrivacyModelCopyWith<$Res> {
  __$PrivacyModelCopyWithImpl(this._self, this._then);

  final _PrivacyModel _self;
  final $Res Function(_PrivacyModel) _then;

/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicReadingStats = null,}) {
  return _then(_PrivacyModel(
publicReadingStats: null == publicReadingStats ? _self.publicReadingStats : publicReadingStats // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SessionModel {

 String get accessToken; DateTime get accessTokenExpiresAt; String? get refreshToken; DateTime get refreshTokenExpiresAt; MeModel get user;
/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionModelCopyWith<SessionModel> get copyWith => _$SessionModelCopyWithImpl<SessionModel>(this as SessionModel, _$identity);

  /// Serializes this SessionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionModel&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.accessTokenExpiresAt, accessTokenExpiresAt) || other.accessTokenExpiresAt == accessTokenExpiresAt)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.refreshTokenExpiresAt, refreshTokenExpiresAt) || other.refreshTokenExpiresAt == refreshTokenExpiresAt)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,accessTokenExpiresAt,refreshToken,refreshTokenExpiresAt,user);

@override
String toString() {
  return 'SessionModel(accessToken: $accessToken, accessTokenExpiresAt: $accessTokenExpiresAt, refreshToken: $refreshToken, refreshTokenExpiresAt: $refreshTokenExpiresAt, user: $user)';
}


}

/// @nodoc
abstract mixin class $SessionModelCopyWith<$Res>  {
  factory $SessionModelCopyWith(SessionModel value, $Res Function(SessionModel) _then) = _$SessionModelCopyWithImpl;
@useResult
$Res call({
 String accessToken, DateTime accessTokenExpiresAt, String? refreshToken, DateTime refreshTokenExpiresAt, MeModel user
});


$MeModelCopyWith<$Res> get user;

}
/// @nodoc
class _$SessionModelCopyWithImpl<$Res>
    implements $SessionModelCopyWith<$Res> {
  _$SessionModelCopyWithImpl(this._self, this._then);

  final SessionModel _self;
  final $Res Function(SessionModel) _then;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? accessTokenExpiresAt = null,Object? refreshToken = freezed,Object? refreshTokenExpiresAt = null,Object? user = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,accessTokenExpiresAt: null == accessTokenExpiresAt ? _self.accessTokenExpiresAt : accessTokenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,refreshTokenExpiresAt: null == refreshTokenExpiresAt ? _self.refreshTokenExpiresAt : refreshTokenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as MeModel,
  ));
}
/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeModelCopyWith<$Res> get user {
  
  return $MeModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionModel].
extension SessionModelPatterns on SessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionModel value)  $default,){
final _that = this;
switch (_that) {
case _SessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  DateTime accessTokenExpiresAt,  String? refreshToken,  DateTime refreshTokenExpiresAt,  MeModel user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
return $default(_that.accessToken,_that.accessTokenExpiresAt,_that.refreshToken,_that.refreshTokenExpiresAt,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  DateTime accessTokenExpiresAt,  String? refreshToken,  DateTime refreshTokenExpiresAt,  MeModel user)  $default,) {final _that = this;
switch (_that) {
case _SessionModel():
return $default(_that.accessToken,_that.accessTokenExpiresAt,_that.refreshToken,_that.refreshTokenExpiresAt,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  DateTime accessTokenExpiresAt,  String? refreshToken,  DateTime refreshTokenExpiresAt,  MeModel user)?  $default,) {final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
return $default(_that.accessToken,_that.accessTokenExpiresAt,_that.refreshToken,_that.refreshTokenExpiresAt,_that.user);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionModel implements SessionModel {
  const _SessionModel({required this.accessToken, required this.accessTokenExpiresAt, this.refreshToken, required this.refreshTokenExpiresAt, required this.user});
  factory _SessionModel.fromJson(Map<String, dynamic> json) => _$SessionModelFromJson(json);

@override final  String accessToken;
@override final  DateTime accessTokenExpiresAt;
@override final  String? refreshToken;
@override final  DateTime refreshTokenExpiresAt;
@override final  MeModel user;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionModelCopyWith<_SessionModel> get copyWith => __$SessionModelCopyWithImpl<_SessionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionModel&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.accessTokenExpiresAt, accessTokenExpiresAt) || other.accessTokenExpiresAt == accessTokenExpiresAt)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.refreshTokenExpiresAt, refreshTokenExpiresAt) || other.refreshTokenExpiresAt == refreshTokenExpiresAt)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,accessTokenExpiresAt,refreshToken,refreshTokenExpiresAt,user);

@override
String toString() {
  return 'SessionModel(accessToken: $accessToken, accessTokenExpiresAt: $accessTokenExpiresAt, refreshToken: $refreshToken, refreshTokenExpiresAt: $refreshTokenExpiresAt, user: $user)';
}


}

/// @nodoc
abstract mixin class _$SessionModelCopyWith<$Res> implements $SessionModelCopyWith<$Res> {
  factory _$SessionModelCopyWith(_SessionModel value, $Res Function(_SessionModel) _then) = __$SessionModelCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, DateTime accessTokenExpiresAt, String? refreshToken, DateTime refreshTokenExpiresAt, MeModel user
});


@override $MeModelCopyWith<$Res> get user;

}
/// @nodoc
class __$SessionModelCopyWithImpl<$Res>
    implements _$SessionModelCopyWith<$Res> {
  __$SessionModelCopyWithImpl(this._self, this._then);

  final _SessionModel _self;
  final $Res Function(_SessionModel) _then;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? accessTokenExpiresAt = null,Object? refreshToken = freezed,Object? refreshTokenExpiresAt = null,Object? user = null,}) {
  return _then(_SessionModel(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,accessTokenExpiresAt: null == accessTokenExpiresAt ? _self.accessTokenExpiresAt : accessTokenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,refreshTokenExpiresAt: null == refreshTokenExpiresAt ? _self.refreshTokenExpiresAt : refreshTokenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as MeModel,
  ));
}

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeModelCopyWith<$Res> get user {
  
  return $MeModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$AuthConfigModel {

 int get pinLength; PasswordRulesModel get password;// Added with Google/Apple sign in; older APIs leave it out.
 List<String> get externalProviders;
/// Create a copy of AuthConfigModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthConfigModelCopyWith<AuthConfigModel> get copyWith => _$AuthConfigModelCopyWithImpl<AuthConfigModel>(this as AuthConfigModel, _$identity);

  /// Serializes this AuthConfigModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthConfigModel&&(identical(other.pinLength, pinLength) || other.pinLength == pinLength)&&(identical(other.password, password) || other.password == password)&&const DeepCollectionEquality().equals(other.externalProviders, externalProviders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pinLength,password,const DeepCollectionEquality().hash(externalProviders));

@override
String toString() {
  return 'AuthConfigModel(pinLength: $pinLength, password: $password, externalProviders: $externalProviders)';
}


}

/// @nodoc
abstract mixin class $AuthConfigModelCopyWith<$Res>  {
  factory $AuthConfigModelCopyWith(AuthConfigModel value, $Res Function(AuthConfigModel) _then) = _$AuthConfigModelCopyWithImpl;
@useResult
$Res call({
 int pinLength, PasswordRulesModel password, List<String> externalProviders
});


$PasswordRulesModelCopyWith<$Res> get password;

}
/// @nodoc
class _$AuthConfigModelCopyWithImpl<$Res>
    implements $AuthConfigModelCopyWith<$Res> {
  _$AuthConfigModelCopyWithImpl(this._self, this._then);

  final AuthConfigModel _self;
  final $Res Function(AuthConfigModel) _then;

/// Create a copy of AuthConfigModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pinLength = null,Object? password = null,Object? externalProviders = null,}) {
  return _then(_self.copyWith(
pinLength: null == pinLength ? _self.pinLength : pinLength // ignore: cast_nullable_to_non_nullable
as int,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as PasswordRulesModel,externalProviders: null == externalProviders ? _self.externalProviders : externalProviders // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of AuthConfigModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PasswordRulesModelCopyWith<$Res> get password {
  
  return $PasswordRulesModelCopyWith<$Res>(_self.password, (value) {
    return _then(_self.copyWith(password: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthConfigModel].
extension AuthConfigModelPatterns on AuthConfigModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthConfigModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthConfigModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthConfigModel value)  $default,){
final _that = this;
switch (_that) {
case _AuthConfigModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthConfigModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuthConfigModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pinLength,  PasswordRulesModel password,  List<String> externalProviders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthConfigModel() when $default != null:
return $default(_that.pinLength,_that.password,_that.externalProviders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pinLength,  PasswordRulesModel password,  List<String> externalProviders)  $default,) {final _that = this;
switch (_that) {
case _AuthConfigModel():
return $default(_that.pinLength,_that.password,_that.externalProviders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pinLength,  PasswordRulesModel password,  List<String> externalProviders)?  $default,) {final _that = this;
switch (_that) {
case _AuthConfigModel() when $default != null:
return $default(_that.pinLength,_that.password,_that.externalProviders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthConfigModel extends AuthConfigModel {
  const _AuthConfigModel({this.pinLength = RecoveryPinRules.defaultLength, this.password = const PasswordRulesModel(), final  List<String> externalProviders = const <String>[]}): _externalProviders = externalProviders,super._();
  factory _AuthConfigModel.fromJson(Map<String, dynamic> json) => _$AuthConfigModelFromJson(json);

@override@JsonKey() final  int pinLength;
@override@JsonKey() final  PasswordRulesModel password;
// Added with Google/Apple sign in; older APIs leave it out.
 final  List<String> _externalProviders;
// Added with Google/Apple sign in; older APIs leave it out.
@override@JsonKey() List<String> get externalProviders {
  if (_externalProviders is EqualUnmodifiableListView) return _externalProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_externalProviders);
}


/// Create a copy of AuthConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthConfigModelCopyWith<_AuthConfigModel> get copyWith => __$AuthConfigModelCopyWithImpl<_AuthConfigModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthConfigModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthConfigModel&&(identical(other.pinLength, pinLength) || other.pinLength == pinLength)&&(identical(other.password, password) || other.password == password)&&const DeepCollectionEquality().equals(other._externalProviders, _externalProviders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pinLength,password,const DeepCollectionEquality().hash(_externalProviders));

@override
String toString() {
  return 'AuthConfigModel(pinLength: $pinLength, password: $password, externalProviders: $externalProviders)';
}


}

/// @nodoc
abstract mixin class _$AuthConfigModelCopyWith<$Res> implements $AuthConfigModelCopyWith<$Res> {
  factory _$AuthConfigModelCopyWith(_AuthConfigModel value, $Res Function(_AuthConfigModel) _then) = __$AuthConfigModelCopyWithImpl;
@override @useResult
$Res call({
 int pinLength, PasswordRulesModel password, List<String> externalProviders
});


@override $PasswordRulesModelCopyWith<$Res> get password;

}
/// @nodoc
class __$AuthConfigModelCopyWithImpl<$Res>
    implements _$AuthConfigModelCopyWith<$Res> {
  __$AuthConfigModelCopyWithImpl(this._self, this._then);

  final _AuthConfigModel _self;
  final $Res Function(_AuthConfigModel) _then;

/// Create a copy of AuthConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pinLength = null,Object? password = null,Object? externalProviders = null,}) {
  return _then(_AuthConfigModel(
pinLength: null == pinLength ? _self.pinLength : pinLength // ignore: cast_nullable_to_non_nullable
as int,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as PasswordRulesModel,externalProviders: null == externalProviders ? _self._externalProviders : externalProviders // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of AuthConfigModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PasswordRulesModelCopyWith<$Res> get password {
  
  return $PasswordRulesModelCopyWith<$Res>(_self.password, (value) {
    return _then(_self.copyWith(password: value));
  });
}
}


/// @nodoc
mixin _$PasswordRulesModel {

 int get minLength; int get maxLength; bool get requireLetter; bool get requireDigit;
/// Create a copy of PasswordRulesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PasswordRulesModelCopyWith<PasswordRulesModel> get copyWith => _$PasswordRulesModelCopyWithImpl<PasswordRulesModel>(this as PasswordRulesModel, _$identity);

  /// Serializes this PasswordRulesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PasswordRulesModel&&(identical(other.minLength, minLength) || other.minLength == minLength)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength)&&(identical(other.requireLetter, requireLetter) || other.requireLetter == requireLetter)&&(identical(other.requireDigit, requireDigit) || other.requireDigit == requireDigit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minLength,maxLength,requireLetter,requireDigit);

@override
String toString() {
  return 'PasswordRulesModel(minLength: $minLength, maxLength: $maxLength, requireLetter: $requireLetter, requireDigit: $requireDigit)';
}


}

/// @nodoc
abstract mixin class $PasswordRulesModelCopyWith<$Res>  {
  factory $PasswordRulesModelCopyWith(PasswordRulesModel value, $Res Function(PasswordRulesModel) _then) = _$PasswordRulesModelCopyWithImpl;
@useResult
$Res call({
 int minLength, int maxLength, bool requireLetter, bool requireDigit
});




}
/// @nodoc
class _$PasswordRulesModelCopyWithImpl<$Res>
    implements $PasswordRulesModelCopyWith<$Res> {
  _$PasswordRulesModelCopyWithImpl(this._self, this._then);

  final PasswordRulesModel _self;
  final $Res Function(PasswordRulesModel) _then;

/// Create a copy of PasswordRulesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minLength = null,Object? maxLength = null,Object? requireLetter = null,Object? requireDigit = null,}) {
  return _then(_self.copyWith(
minLength: null == minLength ? _self.minLength : minLength // ignore: cast_nullable_to_non_nullable
as int,maxLength: null == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int,requireLetter: null == requireLetter ? _self.requireLetter : requireLetter // ignore: cast_nullable_to_non_nullable
as bool,requireDigit: null == requireDigit ? _self.requireDigit : requireDigit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PasswordRulesModel].
extension PasswordRulesModelPatterns on PasswordRulesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PasswordRulesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PasswordRulesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PasswordRulesModel value)  $default,){
final _that = this;
switch (_that) {
case _PasswordRulesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PasswordRulesModel value)?  $default,){
final _that = this;
switch (_that) {
case _PasswordRulesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minLength,  int maxLength,  bool requireLetter,  bool requireDigit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PasswordRulesModel() when $default != null:
return $default(_that.minLength,_that.maxLength,_that.requireLetter,_that.requireDigit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minLength,  int maxLength,  bool requireLetter,  bool requireDigit)  $default,) {final _that = this;
switch (_that) {
case _PasswordRulesModel():
return $default(_that.minLength,_that.maxLength,_that.requireLetter,_that.requireDigit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minLength,  int maxLength,  bool requireLetter,  bool requireDigit)?  $default,) {final _that = this;
switch (_that) {
case _PasswordRulesModel() when $default != null:
return $default(_that.minLength,_that.maxLength,_that.requireLetter,_that.requireDigit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PasswordRulesModel implements PasswordRulesModel {
  const _PasswordRulesModel({this.minLength = 8, this.maxLength = 128, this.requireLetter = true, this.requireDigit = true});
  factory _PasswordRulesModel.fromJson(Map<String, dynamic> json) => _$PasswordRulesModelFromJson(json);

@override@JsonKey() final  int minLength;
@override@JsonKey() final  int maxLength;
@override@JsonKey() final  bool requireLetter;
@override@JsonKey() final  bool requireDigit;

/// Create a copy of PasswordRulesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PasswordRulesModelCopyWith<_PasswordRulesModel> get copyWith => __$PasswordRulesModelCopyWithImpl<_PasswordRulesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PasswordRulesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PasswordRulesModel&&(identical(other.minLength, minLength) || other.minLength == minLength)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength)&&(identical(other.requireLetter, requireLetter) || other.requireLetter == requireLetter)&&(identical(other.requireDigit, requireDigit) || other.requireDigit == requireDigit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minLength,maxLength,requireLetter,requireDigit);

@override
String toString() {
  return 'PasswordRulesModel(minLength: $minLength, maxLength: $maxLength, requireLetter: $requireLetter, requireDigit: $requireDigit)';
}


}

/// @nodoc
abstract mixin class _$PasswordRulesModelCopyWith<$Res> implements $PasswordRulesModelCopyWith<$Res> {
  factory _$PasswordRulesModelCopyWith(_PasswordRulesModel value, $Res Function(_PasswordRulesModel) _then) = __$PasswordRulesModelCopyWithImpl;
@override @useResult
$Res call({
 int minLength, int maxLength, bool requireLetter, bool requireDigit
});




}
/// @nodoc
class __$PasswordRulesModelCopyWithImpl<$Res>
    implements _$PasswordRulesModelCopyWith<$Res> {
  __$PasswordRulesModelCopyWithImpl(this._self, this._then);

  final _PasswordRulesModel _self;
  final $Res Function(_PasswordRulesModel) _then;

/// Create a copy of PasswordRulesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minLength = null,Object? maxLength = null,Object? requireLetter = null,Object? requireDigit = null,}) {
  return _then(_PasswordRulesModel(
minLength: null == minLength ? _self.minLength : minLength // ignore: cast_nullable_to_non_nullable
as int,maxLength: null == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int,requireLetter: null == requireLetter ? _self.requireLetter : requireLetter // ignore: cast_nullable_to_non_nullable
as bool,requireDigit: null == requireDigit ? _self.requireDigit : requireDigit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ResetTokenModel {

 String get resetToken; DateTime get expiresAt;
/// Create a copy of ResetTokenModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetTokenModelCopyWith<ResetTokenModel> get copyWith => _$ResetTokenModelCopyWithImpl<ResetTokenModel>(this as ResetTokenModel, _$identity);

  /// Serializes this ResetTokenModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetTokenModel&&(identical(other.resetToken, resetToken) || other.resetToken == resetToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resetToken,expiresAt);

@override
String toString() {
  return 'ResetTokenModel(resetToken: $resetToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ResetTokenModelCopyWith<$Res>  {
  factory $ResetTokenModelCopyWith(ResetTokenModel value, $Res Function(ResetTokenModel) _then) = _$ResetTokenModelCopyWithImpl;
@useResult
$Res call({
 String resetToken, DateTime expiresAt
});




}
/// @nodoc
class _$ResetTokenModelCopyWithImpl<$Res>
    implements $ResetTokenModelCopyWith<$Res> {
  _$ResetTokenModelCopyWithImpl(this._self, this._then);

  final ResetTokenModel _self;
  final $Res Function(ResetTokenModel) _then;

/// Create a copy of ResetTokenModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resetToken = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
resetToken: null == resetToken ? _self.resetToken : resetToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ResetTokenModel].
extension ResetTokenModelPatterns on ResetTokenModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResetTokenModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResetTokenModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResetTokenModel value)  $default,){
final _that = this;
switch (_that) {
case _ResetTokenModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResetTokenModel value)?  $default,){
final _that = this;
switch (_that) {
case _ResetTokenModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resetToken,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResetTokenModel() when $default != null:
return $default(_that.resetToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resetToken,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ResetTokenModel():
return $default(_that.resetToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resetToken,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ResetTokenModel() when $default != null:
return $default(_that.resetToken,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResetTokenModel implements ResetTokenModel {
  const _ResetTokenModel({required this.resetToken, required this.expiresAt});
  factory _ResetTokenModel.fromJson(Map<String, dynamic> json) => _$ResetTokenModelFromJson(json);

@override final  String resetToken;
@override final  DateTime expiresAt;

/// Create a copy of ResetTokenModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResetTokenModelCopyWith<_ResetTokenModel> get copyWith => __$ResetTokenModelCopyWithImpl<_ResetTokenModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResetTokenModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetTokenModel&&(identical(other.resetToken, resetToken) || other.resetToken == resetToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resetToken,expiresAt);

@override
String toString() {
  return 'ResetTokenModel(resetToken: $resetToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ResetTokenModelCopyWith<$Res> implements $ResetTokenModelCopyWith<$Res> {
  factory _$ResetTokenModelCopyWith(_ResetTokenModel value, $Res Function(_ResetTokenModel) _then) = __$ResetTokenModelCopyWithImpl;
@override @useResult
$Res call({
 String resetToken, DateTime expiresAt
});




}
/// @nodoc
class __$ResetTokenModelCopyWithImpl<$Res>
    implements _$ResetTokenModelCopyWith<$Res> {
  __$ResetTokenModelCopyWithImpl(this._self, this._then);

  final _ResetTokenModel _self;
  final $Res Function(_ResetTokenModel) _then;

/// Create a copy of ResetTokenModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resetToken = null,Object? expiresAt = null,}) {
  return _then(_ResetTokenModel(
resetToken: null == resetToken ? _self.resetToken : resetToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$UsernameAvailabilityModel {

 String get username; bool get valid; bool get available;
/// Create a copy of UsernameAvailabilityModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsernameAvailabilityModelCopyWith<UsernameAvailabilityModel> get copyWith => _$UsernameAvailabilityModelCopyWithImpl<UsernameAvailabilityModel>(this as UsernameAvailabilityModel, _$identity);

  /// Serializes this UsernameAvailabilityModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsernameAvailabilityModel&&(identical(other.username, username) || other.username == username)&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,valid,available);

@override
String toString() {
  return 'UsernameAvailabilityModel(username: $username, valid: $valid, available: $available)';
}


}

/// @nodoc
abstract mixin class $UsernameAvailabilityModelCopyWith<$Res>  {
  factory $UsernameAvailabilityModelCopyWith(UsernameAvailabilityModel value, $Res Function(UsernameAvailabilityModel) _then) = _$UsernameAvailabilityModelCopyWithImpl;
@useResult
$Res call({
 String username, bool valid, bool available
});




}
/// @nodoc
class _$UsernameAvailabilityModelCopyWithImpl<$Res>
    implements $UsernameAvailabilityModelCopyWith<$Res> {
  _$UsernameAvailabilityModelCopyWithImpl(this._self, this._then);

  final UsernameAvailabilityModel _self;
  final $Res Function(UsernameAvailabilityModel) _then;

/// Create a copy of UsernameAvailabilityModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? valid = null,Object? available = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,valid: null == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UsernameAvailabilityModel].
extension UsernameAvailabilityModelPatterns on UsernameAvailabilityModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsernameAvailabilityModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsernameAvailabilityModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsernameAvailabilityModel value)  $default,){
final _that = this;
switch (_that) {
case _UsernameAvailabilityModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsernameAvailabilityModel value)?  $default,){
final _that = this;
switch (_that) {
case _UsernameAvailabilityModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  bool valid,  bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsernameAvailabilityModel() when $default != null:
return $default(_that.username,_that.valid,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  bool valid,  bool available)  $default,) {final _that = this;
switch (_that) {
case _UsernameAvailabilityModel():
return $default(_that.username,_that.valid,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  bool valid,  bool available)?  $default,) {final _that = this;
switch (_that) {
case _UsernameAvailabilityModel() when $default != null:
return $default(_that.username,_that.valid,_that.available);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsernameAvailabilityModel extends UsernameAvailabilityModel {
  const _UsernameAvailabilityModel({required this.username, required this.valid, required this.available}): super._();
  factory _UsernameAvailabilityModel.fromJson(Map<String, dynamic> json) => _$UsernameAvailabilityModelFromJson(json);

@override final  String username;
@override final  bool valid;
@override final  bool available;

/// Create a copy of UsernameAvailabilityModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsernameAvailabilityModelCopyWith<_UsernameAvailabilityModel> get copyWith => __$UsernameAvailabilityModelCopyWithImpl<_UsernameAvailabilityModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsernameAvailabilityModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsernameAvailabilityModel&&(identical(other.username, username) || other.username == username)&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,valid,available);

@override
String toString() {
  return 'UsernameAvailabilityModel(username: $username, valid: $valid, available: $available)';
}


}

/// @nodoc
abstract mixin class _$UsernameAvailabilityModelCopyWith<$Res> implements $UsernameAvailabilityModelCopyWith<$Res> {
  factory _$UsernameAvailabilityModelCopyWith(_UsernameAvailabilityModel value, $Res Function(_UsernameAvailabilityModel) _then) = __$UsernameAvailabilityModelCopyWithImpl;
@override @useResult
$Res call({
 String username, bool valid, bool available
});




}
/// @nodoc
class __$UsernameAvailabilityModelCopyWithImpl<$Res>
    implements _$UsernameAvailabilityModelCopyWith<$Res> {
  __$UsernameAvailabilityModelCopyWithImpl(this._self, this._then);

  final _UsernameAvailabilityModel _self;
  final $Res Function(_UsernameAvailabilityModel) _then;

/// Create a copy of UsernameAvailabilityModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? valid = null,Object? available = null,}) {
  return _then(_UsernameAvailabilityModel(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,valid: null == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
