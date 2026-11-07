// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_policy_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlatformUpdatePolicyModel {

 String? get minimumVersion; String? get storeUrl;
/// Create a copy of PlatformUpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlatformUpdatePolicyModelCopyWith<PlatformUpdatePolicyModel> get copyWith => _$PlatformUpdatePolicyModelCopyWithImpl<PlatformUpdatePolicyModel>(this as PlatformUpdatePolicyModel, _$identity);

  /// Serializes this PlatformUpdatePolicyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformUpdatePolicyModel&&(identical(other.minimumVersion, minimumVersion) || other.minimumVersion == minimumVersion)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minimumVersion,storeUrl);

@override
String toString() {
  return 'PlatformUpdatePolicyModel(minimumVersion: $minimumVersion, storeUrl: $storeUrl)';
}


}

/// @nodoc
abstract mixin class $PlatformUpdatePolicyModelCopyWith<$Res>  {
  factory $PlatformUpdatePolicyModelCopyWith(PlatformUpdatePolicyModel value, $Res Function(PlatformUpdatePolicyModel) _then) = _$PlatformUpdatePolicyModelCopyWithImpl;
@useResult
$Res call({
 String? minimumVersion, String? storeUrl
});




}
/// @nodoc
class _$PlatformUpdatePolicyModelCopyWithImpl<$Res>
    implements $PlatformUpdatePolicyModelCopyWith<$Res> {
  _$PlatformUpdatePolicyModelCopyWithImpl(this._self, this._then);

  final PlatformUpdatePolicyModel _self;
  final $Res Function(PlatformUpdatePolicyModel) _then;

/// Create a copy of PlatformUpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minimumVersion = freezed,Object? storeUrl = freezed,}) {
  return _then(_self.copyWith(
minimumVersion: freezed == minimumVersion ? _self.minimumVersion : minimumVersion // ignore: cast_nullable_to_non_nullable
as String?,storeUrl: freezed == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlatformUpdatePolicyModel].
extension PlatformUpdatePolicyModelPatterns on PlatformUpdatePolicyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlatformUpdatePolicyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlatformUpdatePolicyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlatformUpdatePolicyModel value)  $default,){
final _that = this;
switch (_that) {
case _PlatformUpdatePolicyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlatformUpdatePolicyModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlatformUpdatePolicyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? minimumVersion,  String? storeUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlatformUpdatePolicyModel() when $default != null:
return $default(_that.minimumVersion,_that.storeUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? minimumVersion,  String? storeUrl)  $default,) {final _that = this;
switch (_that) {
case _PlatformUpdatePolicyModel():
return $default(_that.minimumVersion,_that.storeUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? minimumVersion,  String? storeUrl)?  $default,) {final _that = this;
switch (_that) {
case _PlatformUpdatePolicyModel() when $default != null:
return $default(_that.minimumVersion,_that.storeUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlatformUpdatePolicyModel extends PlatformUpdatePolicyModel {
  const _PlatformUpdatePolicyModel({this.minimumVersion, this.storeUrl}): super._();
  factory _PlatformUpdatePolicyModel.fromJson(Map<String, dynamic> json) => _$PlatformUpdatePolicyModelFromJson(json);

@override final  String? minimumVersion;
@override final  String? storeUrl;

/// Create a copy of PlatformUpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlatformUpdatePolicyModelCopyWith<_PlatformUpdatePolicyModel> get copyWith => __$PlatformUpdatePolicyModelCopyWithImpl<_PlatformUpdatePolicyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlatformUpdatePolicyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlatformUpdatePolicyModel&&(identical(other.minimumVersion, minimumVersion) || other.minimumVersion == minimumVersion)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minimumVersion,storeUrl);

@override
String toString() {
  return 'PlatformUpdatePolicyModel(minimumVersion: $minimumVersion, storeUrl: $storeUrl)';
}


}

/// @nodoc
abstract mixin class _$PlatformUpdatePolicyModelCopyWith<$Res> implements $PlatformUpdatePolicyModelCopyWith<$Res> {
  factory _$PlatformUpdatePolicyModelCopyWith(_PlatformUpdatePolicyModel value, $Res Function(_PlatformUpdatePolicyModel) _then) = __$PlatformUpdatePolicyModelCopyWithImpl;
@override @useResult
$Res call({
 String? minimumVersion, String? storeUrl
});




}
/// @nodoc
class __$PlatformUpdatePolicyModelCopyWithImpl<$Res>
    implements _$PlatformUpdatePolicyModelCopyWith<$Res> {
  __$PlatformUpdatePolicyModelCopyWithImpl(this._self, this._then);

  final _PlatformUpdatePolicyModel _self;
  final $Res Function(_PlatformUpdatePolicyModel) _then;

/// Create a copy of PlatformUpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minimumVersion = freezed,Object? storeUrl = freezed,}) {
  return _then(_PlatformUpdatePolicyModel(
minimumVersion: freezed == minimumVersion ? _self.minimumVersion : minimumVersion // ignore: cast_nullable_to_non_nullable
as String?,storeUrl: freezed == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UpdatePolicyModel {

 PlatformUpdatePolicyModel? get ios; PlatformUpdatePolicyModel? get android;
/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePolicyModelCopyWith<UpdatePolicyModel> get copyWith => _$UpdatePolicyModelCopyWithImpl<UpdatePolicyModel>(this as UpdatePolicyModel, _$identity);

  /// Serializes this UpdatePolicyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePolicyModel&&(identical(other.ios, ios) || other.ios == ios)&&(identical(other.android, android) || other.android == android));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ios,android);

@override
String toString() {
  return 'UpdatePolicyModel(ios: $ios, android: $android)';
}


}

/// @nodoc
abstract mixin class $UpdatePolicyModelCopyWith<$Res>  {
  factory $UpdatePolicyModelCopyWith(UpdatePolicyModel value, $Res Function(UpdatePolicyModel) _then) = _$UpdatePolicyModelCopyWithImpl;
@useResult
$Res call({
 PlatformUpdatePolicyModel? ios, PlatformUpdatePolicyModel? android
});


$PlatformUpdatePolicyModelCopyWith<$Res>? get ios;$PlatformUpdatePolicyModelCopyWith<$Res>? get android;

}
/// @nodoc
class _$UpdatePolicyModelCopyWithImpl<$Res>
    implements $UpdatePolicyModelCopyWith<$Res> {
  _$UpdatePolicyModelCopyWithImpl(this._self, this._then);

  final UpdatePolicyModel _self;
  final $Res Function(UpdatePolicyModel) _then;

/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ios = freezed,Object? android = freezed,}) {
  return _then(_self.copyWith(
ios: freezed == ios ? _self.ios : ios // ignore: cast_nullable_to_non_nullable
as PlatformUpdatePolicyModel?,android: freezed == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as PlatformUpdatePolicyModel?,
  ));
}
/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlatformUpdatePolicyModelCopyWith<$Res>? get ios {
    if (_self.ios == null) {
    return null;
  }

  return $PlatformUpdatePolicyModelCopyWith<$Res>(_self.ios!, (value) {
    return _then(_self.copyWith(ios: value));
  });
}/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlatformUpdatePolicyModelCopyWith<$Res>? get android {
    if (_self.android == null) {
    return null;
  }

  return $PlatformUpdatePolicyModelCopyWith<$Res>(_self.android!, (value) {
    return _then(_self.copyWith(android: value));
  });
}
}


/// Adds pattern-matching-related methods to [UpdatePolicyModel].
extension UpdatePolicyModelPatterns on UpdatePolicyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdatePolicyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdatePolicyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdatePolicyModel value)  $default,){
final _that = this;
switch (_that) {
case _UpdatePolicyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdatePolicyModel value)?  $default,){
final _that = this;
switch (_that) {
case _UpdatePolicyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlatformUpdatePolicyModel? ios,  PlatformUpdatePolicyModel? android)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePolicyModel() when $default != null:
return $default(_that.ios,_that.android);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlatformUpdatePolicyModel? ios,  PlatformUpdatePolicyModel? android)  $default,) {final _that = this;
switch (_that) {
case _UpdatePolicyModel():
return $default(_that.ios,_that.android);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlatformUpdatePolicyModel? ios,  PlatformUpdatePolicyModel? android)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePolicyModel() when $default != null:
return $default(_that.ios,_that.android);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdatePolicyModel extends UpdatePolicyModel {
  const _UpdatePolicyModel({this.ios, this.android}): super._();
  factory _UpdatePolicyModel.fromJson(Map<String, dynamic> json) => _$UpdatePolicyModelFromJson(json);

@override final  PlatformUpdatePolicyModel? ios;
@override final  PlatformUpdatePolicyModel? android;

/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePolicyModelCopyWith<_UpdatePolicyModel> get copyWith => __$UpdatePolicyModelCopyWithImpl<_UpdatePolicyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdatePolicyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePolicyModel&&(identical(other.ios, ios) || other.ios == ios)&&(identical(other.android, android) || other.android == android));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ios,android);

@override
String toString() {
  return 'UpdatePolicyModel(ios: $ios, android: $android)';
}


}

/// @nodoc
abstract mixin class _$UpdatePolicyModelCopyWith<$Res> implements $UpdatePolicyModelCopyWith<$Res> {
  factory _$UpdatePolicyModelCopyWith(_UpdatePolicyModel value, $Res Function(_UpdatePolicyModel) _then) = __$UpdatePolicyModelCopyWithImpl;
@override @useResult
$Res call({
 PlatformUpdatePolicyModel? ios, PlatformUpdatePolicyModel? android
});


@override $PlatformUpdatePolicyModelCopyWith<$Res>? get ios;@override $PlatformUpdatePolicyModelCopyWith<$Res>? get android;

}
/// @nodoc
class __$UpdatePolicyModelCopyWithImpl<$Res>
    implements _$UpdatePolicyModelCopyWith<$Res> {
  __$UpdatePolicyModelCopyWithImpl(this._self, this._then);

  final _UpdatePolicyModel _self;
  final $Res Function(_UpdatePolicyModel) _then;

/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ios = freezed,Object? android = freezed,}) {
  return _then(_UpdatePolicyModel(
ios: freezed == ios ? _self.ios : ios // ignore: cast_nullable_to_non_nullable
as PlatformUpdatePolicyModel?,android: freezed == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as PlatformUpdatePolicyModel?,
  ));
}

/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlatformUpdatePolicyModelCopyWith<$Res>? get ios {
    if (_self.ios == null) {
    return null;
  }

  return $PlatformUpdatePolicyModelCopyWith<$Res>(_self.ios!, (value) {
    return _then(_self.copyWith(ios: value));
  });
}/// Create a copy of UpdatePolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlatformUpdatePolicyModelCopyWith<$Res>? get android {
    if (_self.android == null) {
    return null;
  }

  return $PlatformUpdatePolicyModelCopyWith<$Res>(_self.android!, (value) {
    return _then(_self.copyWith(android: value));
  });
}
}

// dart format on
