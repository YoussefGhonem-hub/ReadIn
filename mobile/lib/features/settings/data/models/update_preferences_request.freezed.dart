// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_preferences_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdatePreferencesRequest {

 String get uiLanguage; String get articleLanguage; String get theme; String get timeZone; String get reminderTime;
/// Create a copy of UpdatePreferencesRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePreferencesRequestCopyWith<UpdatePreferencesRequest> get copyWith => _$UpdatePreferencesRequestCopyWithImpl<UpdatePreferencesRequest>(this as UpdatePreferencesRequest, _$identity);

  /// Serializes this UpdatePreferencesRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePreferencesRequest&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.articleLanguage, articleLanguage) || other.articleLanguage == articleLanguage)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.reminderTime, reminderTime) || other.reminderTime == reminderTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uiLanguage,articleLanguage,theme,timeZone,reminderTime);

@override
String toString() {
  return 'UpdatePreferencesRequest(uiLanguage: $uiLanguage, articleLanguage: $articleLanguage, theme: $theme, timeZone: $timeZone, reminderTime: $reminderTime)';
}


}

/// @nodoc
abstract mixin class $UpdatePreferencesRequestCopyWith<$Res>  {
  factory $UpdatePreferencesRequestCopyWith(UpdatePreferencesRequest value, $Res Function(UpdatePreferencesRequest) _then) = _$UpdatePreferencesRequestCopyWithImpl;
@useResult
$Res call({
 String uiLanguage, String articleLanguage, String theme, String timeZone, String reminderTime
});




}
/// @nodoc
class _$UpdatePreferencesRequestCopyWithImpl<$Res>
    implements $UpdatePreferencesRequestCopyWith<$Res> {
  _$UpdatePreferencesRequestCopyWithImpl(this._self, this._then);

  final UpdatePreferencesRequest _self;
  final $Res Function(UpdatePreferencesRequest) _then;

/// Create a copy of UpdatePreferencesRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uiLanguage = null,Object? articleLanguage = null,Object? theme = null,Object? timeZone = null,Object? reminderTime = null,}) {
  return _then(_self.copyWith(
uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,articleLanguage: null == articleLanguage ? _self.articleLanguage : articleLanguage // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,reminderTime: null == reminderTime ? _self.reminderTime : reminderTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdatePreferencesRequest].
extension UpdatePreferencesRequestPatterns on UpdatePreferencesRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdatePreferencesRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdatePreferencesRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdatePreferencesRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdatePreferencesRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdatePreferencesRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdatePreferencesRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePreferencesRequest() when $default != null:
return $default(_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime)  $default,) {final _that = this;
switch (_that) {
case _UpdatePreferencesRequest():
return $default(_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uiLanguage,  String articleLanguage,  String theme,  String timeZone,  String reminderTime)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePreferencesRequest() when $default != null:
return $default(_that.uiLanguage,_that.articleLanguage,_that.theme,_that.timeZone,_that.reminderTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdatePreferencesRequest implements UpdatePreferencesRequest {
  const _UpdatePreferencesRequest({required this.uiLanguage, required this.articleLanguage, required this.theme, required this.timeZone, required this.reminderTime});
  factory _UpdatePreferencesRequest.fromJson(Map<String, dynamic> json) => _$UpdatePreferencesRequestFromJson(json);

@override final  String uiLanguage;
@override final  String articleLanguage;
@override final  String theme;
@override final  String timeZone;
@override final  String reminderTime;

/// Create a copy of UpdatePreferencesRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePreferencesRequestCopyWith<_UpdatePreferencesRequest> get copyWith => __$UpdatePreferencesRequestCopyWithImpl<_UpdatePreferencesRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdatePreferencesRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePreferencesRequest&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.articleLanguage, articleLanguage) || other.articleLanguage == articleLanguage)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.reminderTime, reminderTime) || other.reminderTime == reminderTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uiLanguage,articleLanguage,theme,timeZone,reminderTime);

@override
String toString() {
  return 'UpdatePreferencesRequest(uiLanguage: $uiLanguage, articleLanguage: $articleLanguage, theme: $theme, timeZone: $timeZone, reminderTime: $reminderTime)';
}


}

/// @nodoc
abstract mixin class _$UpdatePreferencesRequestCopyWith<$Res> implements $UpdatePreferencesRequestCopyWith<$Res> {
  factory _$UpdatePreferencesRequestCopyWith(_UpdatePreferencesRequest value, $Res Function(_UpdatePreferencesRequest) _then) = __$UpdatePreferencesRequestCopyWithImpl;
@override @useResult
$Res call({
 String uiLanguage, String articleLanguage, String theme, String timeZone, String reminderTime
});




}
/// @nodoc
class __$UpdatePreferencesRequestCopyWithImpl<$Res>
    implements _$UpdatePreferencesRequestCopyWith<$Res> {
  __$UpdatePreferencesRequestCopyWithImpl(this._self, this._then);

  final _UpdatePreferencesRequest _self;
  final $Res Function(_UpdatePreferencesRequest) _then;

/// Create a copy of UpdatePreferencesRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uiLanguage = null,Object? articleLanguage = null,Object? theme = null,Object? timeZone = null,Object? reminderTime = null,}) {
  return _then(_UpdatePreferencesRequest(
uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,articleLanguage: null == articleLanguage ? _self.articleLanguage : articleLanguage // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,reminderTime: null == reminderTime ? _self.reminderTime : reminderTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
