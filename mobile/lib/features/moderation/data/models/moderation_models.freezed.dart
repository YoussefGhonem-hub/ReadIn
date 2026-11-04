// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moderation_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportRequest {

 String get targetType; String get targetId; String get reason; String? get details;
/// Create a copy of ReportRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportRequestCopyWith<ReportRequest> get copyWith => _$ReportRequestCopyWithImpl<ReportRequest>(this as ReportRequest, _$identity);

  /// Serializes this ReportRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportRequest&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetType,targetId,reason,details);

@override
String toString() {
  return 'ReportRequest(targetType: $targetType, targetId: $targetId, reason: $reason, details: $details)';
}


}

/// @nodoc
abstract mixin class $ReportRequestCopyWith<$Res>  {
  factory $ReportRequestCopyWith(ReportRequest value, $Res Function(ReportRequest) _then) = _$ReportRequestCopyWithImpl;
@useResult
$Res call({
 String targetType, String targetId, String reason, String? details
});




}
/// @nodoc
class _$ReportRequestCopyWithImpl<$Res>
    implements $ReportRequestCopyWith<$Res> {
  _$ReportRequestCopyWithImpl(this._self, this._then);

  final ReportRequest _self;
  final $Res Function(ReportRequest) _then;

/// Create a copy of ReportRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetType = null,Object? targetId = null,Object? reason = null,Object? details = freezed,}) {
  return _then(_self.copyWith(
targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportRequest].
extension ReportRequestPatterns on ReportRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportRequest value)  $default,){
final _that = this;
switch (_that) {
case _ReportRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ReportRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String targetType,  String targetId,  String reason,  String? details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportRequest() when $default != null:
return $default(_that.targetType,_that.targetId,_that.reason,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String targetType,  String targetId,  String reason,  String? details)  $default,) {final _that = this;
switch (_that) {
case _ReportRequest():
return $default(_that.targetType,_that.targetId,_that.reason,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String targetType,  String targetId,  String reason,  String? details)?  $default,) {final _that = this;
switch (_that) {
case _ReportRequest() when $default != null:
return $default(_that.targetType,_that.targetId,_that.reason,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportRequest implements ReportRequest {
  const _ReportRequest({required this.targetType, required this.targetId, required this.reason, this.details});
  factory _ReportRequest.fromJson(Map<String, dynamic> json) => _$ReportRequestFromJson(json);

@override final  String targetType;
@override final  String targetId;
@override final  String reason;
@override final  String? details;

/// Create a copy of ReportRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportRequestCopyWith<_ReportRequest> get copyWith => __$ReportRequestCopyWithImpl<_ReportRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportRequest&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetType,targetId,reason,details);

@override
String toString() {
  return 'ReportRequest(targetType: $targetType, targetId: $targetId, reason: $reason, details: $details)';
}


}

/// @nodoc
abstract mixin class _$ReportRequestCopyWith<$Res> implements $ReportRequestCopyWith<$Res> {
  factory _$ReportRequestCopyWith(_ReportRequest value, $Res Function(_ReportRequest) _then) = __$ReportRequestCopyWithImpl;
@override @useResult
$Res call({
 String targetType, String targetId, String reason, String? details
});




}
/// @nodoc
class __$ReportRequestCopyWithImpl<$Res>
    implements _$ReportRequestCopyWith<$Res> {
  __$ReportRequestCopyWithImpl(this._self, this._then);

  final _ReportRequest _self;
  final $Res Function(_ReportRequest) _then;

/// Create a copy of ReportRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetType = null,Object? targetId = null,Object? reason = null,Object? details = freezed,}) {
  return _then(_ReportRequest(
targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ModerationTargetRefModel {

 String get targetType; String get targetId;
/// Create a copy of ModerationTargetRefModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationTargetRefModelCopyWith<ModerationTargetRefModel> get copyWith => _$ModerationTargetRefModelCopyWithImpl<ModerationTargetRefModel>(this as ModerationTargetRefModel, _$identity);

  /// Serializes this ModerationTargetRefModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationTargetRefModel&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetType,targetId);

@override
String toString() {
  return 'ModerationTargetRefModel(targetType: $targetType, targetId: $targetId)';
}


}

/// @nodoc
abstract mixin class $ModerationTargetRefModelCopyWith<$Res>  {
  factory $ModerationTargetRefModelCopyWith(ModerationTargetRefModel value, $Res Function(ModerationTargetRefModel) _then) = _$ModerationTargetRefModelCopyWithImpl;
@useResult
$Res call({
 String targetType, String targetId
});




}
/// @nodoc
class _$ModerationTargetRefModelCopyWithImpl<$Res>
    implements $ModerationTargetRefModelCopyWith<$Res> {
  _$ModerationTargetRefModelCopyWithImpl(this._self, this._then);

  final ModerationTargetRefModel _self;
  final $Res Function(ModerationTargetRefModel) _then;

/// Create a copy of ModerationTargetRefModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetType = null,Object? targetId = null,}) {
  return _then(_self.copyWith(
targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationTargetRefModel].
extension ModerationTargetRefModelPatterns on ModerationTargetRefModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationTargetRefModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationTargetRefModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationTargetRefModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationTargetRefModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationTargetRefModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationTargetRefModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String targetType,  String targetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationTargetRefModel() when $default != null:
return $default(_that.targetType,_that.targetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String targetType,  String targetId)  $default,) {final _that = this;
switch (_that) {
case _ModerationTargetRefModel():
return $default(_that.targetType,_that.targetId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String targetType,  String targetId)?  $default,) {final _that = this;
switch (_that) {
case _ModerationTargetRefModel() when $default != null:
return $default(_that.targetType,_that.targetId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationTargetRefModel implements ModerationTargetRefModel {
  const _ModerationTargetRefModel({required this.targetType, required this.targetId});
  factory _ModerationTargetRefModel.fromJson(Map<String, dynamic> json) => _$ModerationTargetRefModelFromJson(json);

@override final  String targetType;
@override final  String targetId;

/// Create a copy of ModerationTargetRefModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationTargetRefModelCopyWith<_ModerationTargetRefModel> get copyWith => __$ModerationTargetRefModelCopyWithImpl<_ModerationTargetRefModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationTargetRefModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationTargetRefModel&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetType,targetId);

@override
String toString() {
  return 'ModerationTargetRefModel(targetType: $targetType, targetId: $targetId)';
}


}

/// @nodoc
abstract mixin class _$ModerationTargetRefModelCopyWith<$Res> implements $ModerationTargetRefModelCopyWith<$Res> {
  factory _$ModerationTargetRefModelCopyWith(_ModerationTargetRefModel value, $Res Function(_ModerationTargetRefModel) _then) = __$ModerationTargetRefModelCopyWithImpl;
@override @useResult
$Res call({
 String targetType, String targetId
});




}
/// @nodoc
class __$ModerationTargetRefModelCopyWithImpl<$Res>
    implements _$ModerationTargetRefModelCopyWith<$Res> {
  __$ModerationTargetRefModelCopyWithImpl(this._self, this._then);

  final _ModerationTargetRefModel _self;
  final $Res Function(_ModerationTargetRefModel) _then;

/// Create a copy of ModerationTargetRefModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetType = null,Object? targetId = null,}) {
  return _then(_ModerationTargetRefModel(
targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ModerationActionRequest {

 String get action; String get targetType; String get targetId; String? get note; int? get durationDays; ModerationTargetRefModel? get resolveReportsOf;
/// Create a copy of ModerationActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationActionRequestCopyWith<ModerationActionRequest> get copyWith => _$ModerationActionRequestCopyWithImpl<ModerationActionRequest>(this as ModerationActionRequest, _$identity);

  /// Serializes this ModerationActionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationActionRequest&&(identical(other.action, action) || other.action == action)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.note, note) || other.note == note)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.resolveReportsOf, resolveReportsOf) || other.resolveReportsOf == resolveReportsOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,targetType,targetId,note,durationDays,resolveReportsOf);

@override
String toString() {
  return 'ModerationActionRequest(action: $action, targetType: $targetType, targetId: $targetId, note: $note, durationDays: $durationDays, resolveReportsOf: $resolveReportsOf)';
}


}

/// @nodoc
abstract mixin class $ModerationActionRequestCopyWith<$Res>  {
  factory $ModerationActionRequestCopyWith(ModerationActionRequest value, $Res Function(ModerationActionRequest) _then) = _$ModerationActionRequestCopyWithImpl;
@useResult
$Res call({
 String action, String targetType, String targetId, String? note, int? durationDays, ModerationTargetRefModel? resolveReportsOf
});


$ModerationTargetRefModelCopyWith<$Res>? get resolveReportsOf;

}
/// @nodoc
class _$ModerationActionRequestCopyWithImpl<$Res>
    implements $ModerationActionRequestCopyWith<$Res> {
  _$ModerationActionRequestCopyWithImpl(this._self, this._then);

  final ModerationActionRequest _self;
  final $Res Function(ModerationActionRequest) _then;

/// Create a copy of ModerationActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? targetType = null,Object? targetId = null,Object? note = freezed,Object? durationDays = freezed,Object? resolveReportsOf = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,durationDays: freezed == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int?,resolveReportsOf: freezed == resolveReportsOf ? _self.resolveReportsOf : resolveReportsOf // ignore: cast_nullable_to_non_nullable
as ModerationTargetRefModel?,
  ));
}
/// Create a copy of ModerationActionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationTargetRefModelCopyWith<$Res>? get resolveReportsOf {
    if (_self.resolveReportsOf == null) {
    return null;
  }

  return $ModerationTargetRefModelCopyWith<$Res>(_self.resolveReportsOf!, (value) {
    return _then(_self.copyWith(resolveReportsOf: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationActionRequest].
extension ModerationActionRequestPatterns on ModerationActionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationActionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationActionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationActionRequest value)  $default,){
final _that = this;
switch (_that) {
case _ModerationActionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationActionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationActionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String targetType,  String targetId,  String? note,  int? durationDays,  ModerationTargetRefModel? resolveReportsOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationActionRequest() when $default != null:
return $default(_that.action,_that.targetType,_that.targetId,_that.note,_that.durationDays,_that.resolveReportsOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String targetType,  String targetId,  String? note,  int? durationDays,  ModerationTargetRefModel? resolveReportsOf)  $default,) {final _that = this;
switch (_that) {
case _ModerationActionRequest():
return $default(_that.action,_that.targetType,_that.targetId,_that.note,_that.durationDays,_that.resolveReportsOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String targetType,  String targetId,  String? note,  int? durationDays,  ModerationTargetRefModel? resolveReportsOf)?  $default,) {final _that = this;
switch (_that) {
case _ModerationActionRequest() when $default != null:
return $default(_that.action,_that.targetType,_that.targetId,_that.note,_that.durationDays,_that.resolveReportsOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationActionRequest implements ModerationActionRequest {
  const _ModerationActionRequest({required this.action, required this.targetType, required this.targetId, this.note, this.durationDays, this.resolveReportsOf});
  factory _ModerationActionRequest.fromJson(Map<String, dynamic> json) => _$ModerationActionRequestFromJson(json);

@override final  String action;
@override final  String targetType;
@override final  String targetId;
@override final  String? note;
@override final  int? durationDays;
@override final  ModerationTargetRefModel? resolveReportsOf;

/// Create a copy of ModerationActionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationActionRequestCopyWith<_ModerationActionRequest> get copyWith => __$ModerationActionRequestCopyWithImpl<_ModerationActionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationActionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationActionRequest&&(identical(other.action, action) || other.action == action)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.note, note) || other.note == note)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.resolveReportsOf, resolveReportsOf) || other.resolveReportsOf == resolveReportsOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,targetType,targetId,note,durationDays,resolveReportsOf);

@override
String toString() {
  return 'ModerationActionRequest(action: $action, targetType: $targetType, targetId: $targetId, note: $note, durationDays: $durationDays, resolveReportsOf: $resolveReportsOf)';
}


}

/// @nodoc
abstract mixin class _$ModerationActionRequestCopyWith<$Res> implements $ModerationActionRequestCopyWith<$Res> {
  factory _$ModerationActionRequestCopyWith(_ModerationActionRequest value, $Res Function(_ModerationActionRequest) _then) = __$ModerationActionRequestCopyWithImpl;
@override @useResult
$Res call({
 String action, String targetType, String targetId, String? note, int? durationDays, ModerationTargetRefModel? resolveReportsOf
});


@override $ModerationTargetRefModelCopyWith<$Res>? get resolveReportsOf;

}
/// @nodoc
class __$ModerationActionRequestCopyWithImpl<$Res>
    implements _$ModerationActionRequestCopyWith<$Res> {
  __$ModerationActionRequestCopyWithImpl(this._self, this._then);

  final _ModerationActionRequest _self;
  final $Res Function(_ModerationActionRequest) _then;

/// Create a copy of ModerationActionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? targetType = null,Object? targetId = null,Object? note = freezed,Object? durationDays = freezed,Object? resolveReportsOf = freezed,}) {
  return _then(_ModerationActionRequest(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,durationDays: freezed == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int?,resolveReportsOf: freezed == resolveReportsOf ? _self.resolveReportsOf : resolveReportsOf // ignore: cast_nullable_to_non_nullable
as ModerationTargetRefModel?,
  ));
}

/// Create a copy of ModerationActionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationTargetRefModelCopyWith<$Res>? get resolveReportsOf {
    if (_self.resolveReportsOf == null) {
    return null;
  }

  return $ModerationTargetRefModelCopyWith<$Res>(_self.resolveReportsOf!, (value) {
    return _then(_self.copyWith(resolveReportsOf: value));
  });
}
}


/// @nodoc
mixin _$ModerationSummaryModel {

 ModerationOpenCountsModel get open;
/// Create a copy of ModerationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationSummaryModelCopyWith<ModerationSummaryModel> get copyWith => _$ModerationSummaryModelCopyWithImpl<ModerationSummaryModel>(this as ModerationSummaryModel, _$identity);

  /// Serializes this ModerationSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationSummaryModel&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,open);

@override
String toString() {
  return 'ModerationSummaryModel(open: $open)';
}


}

/// @nodoc
abstract mixin class $ModerationSummaryModelCopyWith<$Res>  {
  factory $ModerationSummaryModelCopyWith(ModerationSummaryModel value, $Res Function(ModerationSummaryModel) _then) = _$ModerationSummaryModelCopyWithImpl;
@useResult
$Res call({
 ModerationOpenCountsModel open
});


$ModerationOpenCountsModelCopyWith<$Res> get open;

}
/// @nodoc
class _$ModerationSummaryModelCopyWithImpl<$Res>
    implements $ModerationSummaryModelCopyWith<$Res> {
  _$ModerationSummaryModelCopyWithImpl(this._self, this._then);

  final ModerationSummaryModel _self;
  final $Res Function(ModerationSummaryModel) _then;

/// Create a copy of ModerationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? open = null,}) {
  return _then(_self.copyWith(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as ModerationOpenCountsModel,
  ));
}
/// Create a copy of ModerationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationOpenCountsModelCopyWith<$Res> get open {
  
  return $ModerationOpenCountsModelCopyWith<$Res>(_self.open, (value) {
    return _then(_self.copyWith(open: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationSummaryModel].
extension ModerationSummaryModelPatterns on ModerationSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ModerationOpenCountsModel open)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationSummaryModel() when $default != null:
return $default(_that.open);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ModerationOpenCountsModel open)  $default,) {final _that = this;
switch (_that) {
case _ModerationSummaryModel():
return $default(_that.open);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ModerationOpenCountsModel open)?  $default,) {final _that = this;
switch (_that) {
case _ModerationSummaryModel() when $default != null:
return $default(_that.open);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationSummaryModel extends ModerationSummaryModel {
  const _ModerationSummaryModel({this.open = const ModerationOpenCountsModel()}): super._();
  factory _ModerationSummaryModel.fromJson(Map<String, dynamic> json) => _$ModerationSummaryModelFromJson(json);

@override@JsonKey() final  ModerationOpenCountsModel open;

/// Create a copy of ModerationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationSummaryModelCopyWith<_ModerationSummaryModel> get copyWith => __$ModerationSummaryModelCopyWithImpl<_ModerationSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationSummaryModel&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,open);

@override
String toString() {
  return 'ModerationSummaryModel(open: $open)';
}


}

/// @nodoc
abstract mixin class _$ModerationSummaryModelCopyWith<$Res> implements $ModerationSummaryModelCopyWith<$Res> {
  factory _$ModerationSummaryModelCopyWith(_ModerationSummaryModel value, $Res Function(_ModerationSummaryModel) _then) = __$ModerationSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 ModerationOpenCountsModel open
});


@override $ModerationOpenCountsModelCopyWith<$Res> get open;

}
/// @nodoc
class __$ModerationSummaryModelCopyWithImpl<$Res>
    implements _$ModerationSummaryModelCopyWith<$Res> {
  __$ModerationSummaryModelCopyWithImpl(this._self, this._then);

  final _ModerationSummaryModel _self;
  final $Res Function(_ModerationSummaryModel) _then;

/// Create a copy of ModerationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? open = null,}) {
  return _then(_ModerationSummaryModel(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as ModerationOpenCountsModel,
  ));
}

/// Create a copy of ModerationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationOpenCountsModelCopyWith<$Res> get open {
  
  return $ModerationOpenCountsModelCopyWith<$Res>(_self.open, (value) {
    return _then(_self.copyWith(open: value));
  });
}
}


/// @nodoc
mixin _$ModerationOpenCountsModel {

 int get article; int get comment; int get user; int get total;
/// Create a copy of ModerationOpenCountsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationOpenCountsModelCopyWith<ModerationOpenCountsModel> get copyWith => _$ModerationOpenCountsModelCopyWithImpl<ModerationOpenCountsModel>(this as ModerationOpenCountsModel, _$identity);

  /// Serializes this ModerationOpenCountsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationOpenCountsModel&&(identical(other.article, article) || other.article == article)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.user, user) || other.user == user)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,comment,user,total);

@override
String toString() {
  return 'ModerationOpenCountsModel(article: $article, comment: $comment, user: $user, total: $total)';
}


}

/// @nodoc
abstract mixin class $ModerationOpenCountsModelCopyWith<$Res>  {
  factory $ModerationOpenCountsModelCopyWith(ModerationOpenCountsModel value, $Res Function(ModerationOpenCountsModel) _then) = _$ModerationOpenCountsModelCopyWithImpl;
@useResult
$Res call({
 int article, int comment, int user, int total
});




}
/// @nodoc
class _$ModerationOpenCountsModelCopyWithImpl<$Res>
    implements $ModerationOpenCountsModelCopyWith<$Res> {
  _$ModerationOpenCountsModelCopyWithImpl(this._self, this._then);

  final ModerationOpenCountsModel _self;
  final $Res Function(ModerationOpenCountsModel) _then;

/// Create a copy of ModerationOpenCountsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? comment = null,Object? user = null,Object? total = null,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as int,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationOpenCountsModel].
extension ModerationOpenCountsModelPatterns on ModerationOpenCountsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationOpenCountsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationOpenCountsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationOpenCountsModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationOpenCountsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationOpenCountsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationOpenCountsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int article,  int comment,  int user,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationOpenCountsModel() when $default != null:
return $default(_that.article,_that.comment,_that.user,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int article,  int comment,  int user,  int total)  $default,) {final _that = this;
switch (_that) {
case _ModerationOpenCountsModel():
return $default(_that.article,_that.comment,_that.user,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int article,  int comment,  int user,  int total)?  $default,) {final _that = this;
switch (_that) {
case _ModerationOpenCountsModel() when $default != null:
return $default(_that.article,_that.comment,_that.user,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationOpenCountsModel implements ModerationOpenCountsModel {
  const _ModerationOpenCountsModel({this.article = 0, this.comment = 0, this.user = 0, this.total = 0});
  factory _ModerationOpenCountsModel.fromJson(Map<String, dynamic> json) => _$ModerationOpenCountsModelFromJson(json);

@override@JsonKey() final  int article;
@override@JsonKey() final  int comment;
@override@JsonKey() final  int user;
@override@JsonKey() final  int total;

/// Create a copy of ModerationOpenCountsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationOpenCountsModelCopyWith<_ModerationOpenCountsModel> get copyWith => __$ModerationOpenCountsModelCopyWithImpl<_ModerationOpenCountsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationOpenCountsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationOpenCountsModel&&(identical(other.article, article) || other.article == article)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.user, user) || other.user == user)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,comment,user,total);

@override
String toString() {
  return 'ModerationOpenCountsModel(article: $article, comment: $comment, user: $user, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ModerationOpenCountsModelCopyWith<$Res> implements $ModerationOpenCountsModelCopyWith<$Res> {
  factory _$ModerationOpenCountsModelCopyWith(_ModerationOpenCountsModel value, $Res Function(_ModerationOpenCountsModel) _then) = __$ModerationOpenCountsModelCopyWithImpl;
@override @useResult
$Res call({
 int article, int comment, int user, int total
});




}
/// @nodoc
class __$ModerationOpenCountsModelCopyWithImpl<$Res>
    implements _$ModerationOpenCountsModelCopyWith<$Res> {
  __$ModerationOpenCountsModelCopyWithImpl(this._self, this._then);

  final _ModerationOpenCountsModel _self;
  final $Res Function(_ModerationOpenCountsModel) _then;

/// Create a copy of ModerationOpenCountsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? comment = null,Object? user = null,Object? total = null,}) {
  return _then(_ModerationOpenCountsModel(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as int,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ModerationTargetModel {

 String get state; AuthorModel? get author; String? get title; String? get slug; String? get language; String? get body; String? get articleId; String? get articleSlug; String? get articleTitle; DateTime? get suspendedUntil; int get warningCount;
/// Create a copy of ModerationTargetModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationTargetModelCopyWith<ModerationTargetModel> get copyWith => _$ModerationTargetModelCopyWithImpl<ModerationTargetModel>(this as ModerationTargetModel, _$identity);

  /// Serializes this ModerationTargetModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationTargetModel&&(identical(other.state, state) || other.state == state)&&(identical(other.author, author) || other.author == author)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.body, body) || other.body == body)&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.articleTitle, articleTitle) || other.articleTitle == articleTitle)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.warningCount, warningCount) || other.warningCount == warningCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,author,title,slug,language,body,articleId,articleSlug,articleTitle,suspendedUntil,warningCount);

@override
String toString() {
  return 'ModerationTargetModel(state: $state, author: $author, title: $title, slug: $slug, language: $language, body: $body, articleId: $articleId, articleSlug: $articleSlug, articleTitle: $articleTitle, suspendedUntil: $suspendedUntil, warningCount: $warningCount)';
}


}

/// @nodoc
abstract mixin class $ModerationTargetModelCopyWith<$Res>  {
  factory $ModerationTargetModelCopyWith(ModerationTargetModel value, $Res Function(ModerationTargetModel) _then) = _$ModerationTargetModelCopyWithImpl;
@useResult
$Res call({
 String state, AuthorModel? author, String? title, String? slug, String? language, String? body, String? articleId, String? articleSlug, String? articleTitle, DateTime? suspendedUntil, int warningCount
});


$AuthorModelCopyWith<$Res>? get author;

}
/// @nodoc
class _$ModerationTargetModelCopyWithImpl<$Res>
    implements $ModerationTargetModelCopyWith<$Res> {
  _$ModerationTargetModelCopyWithImpl(this._self, this._then);

  final ModerationTargetModel _self;
  final $Res Function(ModerationTargetModel) _then;

/// Create a copy of ModerationTargetModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? author = freezed,Object? title = freezed,Object? slug = freezed,Object? language = freezed,Object? body = freezed,Object? articleId = freezed,Object? articleSlug = freezed,Object? articleTitle = freezed,Object? suspendedUntil = freezed,Object? warningCount = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,articleId: freezed == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String?,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,articleTitle: freezed == articleTitle ? _self.articleTitle : articleTitle // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,warningCount: null == warningCount ? _self.warningCount : warningCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ModerationTargetModel
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
}
}


/// Adds pattern-matching-related methods to [ModerationTargetModel].
extension ModerationTargetModelPatterns on ModerationTargetModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationTargetModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationTargetModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationTargetModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationTargetModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationTargetModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationTargetModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String state,  AuthorModel? author,  String? title,  String? slug,  String? language,  String? body,  String? articleId,  String? articleSlug,  String? articleTitle,  DateTime? suspendedUntil,  int warningCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationTargetModel() when $default != null:
return $default(_that.state,_that.author,_that.title,_that.slug,_that.language,_that.body,_that.articleId,_that.articleSlug,_that.articleTitle,_that.suspendedUntil,_that.warningCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String state,  AuthorModel? author,  String? title,  String? slug,  String? language,  String? body,  String? articleId,  String? articleSlug,  String? articleTitle,  DateTime? suspendedUntil,  int warningCount)  $default,) {final _that = this;
switch (_that) {
case _ModerationTargetModel():
return $default(_that.state,_that.author,_that.title,_that.slug,_that.language,_that.body,_that.articleId,_that.articleSlug,_that.articleTitle,_that.suspendedUntil,_that.warningCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String state,  AuthorModel? author,  String? title,  String? slug,  String? language,  String? body,  String? articleId,  String? articleSlug,  String? articleTitle,  DateTime? suspendedUntil,  int warningCount)?  $default,) {final _that = this;
switch (_that) {
case _ModerationTargetModel() when $default != null:
return $default(_that.state,_that.author,_that.title,_that.slug,_that.language,_that.body,_that.articleId,_that.articleSlug,_that.articleTitle,_that.suspendedUntil,_that.warningCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationTargetModel extends ModerationTargetModel {
  const _ModerationTargetModel({required this.state, this.author, this.title, this.slug, this.language, this.body, this.articleId, this.articleSlug, this.articleTitle, this.suspendedUntil, this.warningCount = 0}): super._();
  factory _ModerationTargetModel.fromJson(Map<String, dynamic> json) => _$ModerationTargetModelFromJson(json);

@override final  String state;
@override final  AuthorModel? author;
@override final  String? title;
@override final  String? slug;
@override final  String? language;
@override final  String? body;
@override final  String? articleId;
@override final  String? articleSlug;
@override final  String? articleTitle;
@override final  DateTime? suspendedUntil;
@override@JsonKey() final  int warningCount;

/// Create a copy of ModerationTargetModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationTargetModelCopyWith<_ModerationTargetModel> get copyWith => __$ModerationTargetModelCopyWithImpl<_ModerationTargetModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationTargetModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationTargetModel&&(identical(other.state, state) || other.state == state)&&(identical(other.author, author) || other.author == author)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.body, body) || other.body == body)&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.articleSlug, articleSlug) || other.articleSlug == articleSlug)&&(identical(other.articleTitle, articleTitle) || other.articleTitle == articleTitle)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.warningCount, warningCount) || other.warningCount == warningCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,author,title,slug,language,body,articleId,articleSlug,articleTitle,suspendedUntil,warningCount);

@override
String toString() {
  return 'ModerationTargetModel(state: $state, author: $author, title: $title, slug: $slug, language: $language, body: $body, articleId: $articleId, articleSlug: $articleSlug, articleTitle: $articleTitle, suspendedUntil: $suspendedUntil, warningCount: $warningCount)';
}


}

/// @nodoc
abstract mixin class _$ModerationTargetModelCopyWith<$Res> implements $ModerationTargetModelCopyWith<$Res> {
  factory _$ModerationTargetModelCopyWith(_ModerationTargetModel value, $Res Function(_ModerationTargetModel) _then) = __$ModerationTargetModelCopyWithImpl;
@override @useResult
$Res call({
 String state, AuthorModel? author, String? title, String? slug, String? language, String? body, String? articleId, String? articleSlug, String? articleTitle, DateTime? suspendedUntil, int warningCount
});


@override $AuthorModelCopyWith<$Res>? get author;

}
/// @nodoc
class __$ModerationTargetModelCopyWithImpl<$Res>
    implements _$ModerationTargetModelCopyWith<$Res> {
  __$ModerationTargetModelCopyWithImpl(this._self, this._then);

  final _ModerationTargetModel _self;
  final $Res Function(_ModerationTargetModel) _then;

/// Create a copy of ModerationTargetModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? author = freezed,Object? title = freezed,Object? slug = freezed,Object? language = freezed,Object? body = freezed,Object? articleId = freezed,Object? articleSlug = freezed,Object? articleTitle = freezed,Object? suspendedUntil = freezed,Object? warningCount = null,}) {
  return _then(_ModerationTargetModel(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,articleId: freezed == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String?,articleSlug: freezed == articleSlug ? _self.articleSlug : articleSlug // ignore: cast_nullable_to_non_nullable
as String?,articleTitle: freezed == articleTitle ? _self.articleTitle : articleTitle // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,warningCount: null == warningCount ? _self.warningCount : warningCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ModerationTargetModel
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
}
}


/// @nodoc
mixin _$ModerationQueueItemModel {

 String get targetType; String get targetId; String get status; int get reportCount; Map<String, int> get reasons; DateTime get firstReportedAt; DateTime get lastReportedAt; DateTime? get closedAt; ModerationTargetModel get target;
/// Create a copy of ModerationQueueItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationQueueItemModelCopyWith<ModerationQueueItemModel> get copyWith => _$ModerationQueueItemModelCopyWithImpl<ModerationQueueItemModel>(this as ModerationQueueItemModel, _$identity);

  /// Serializes this ModerationQueueItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationQueueItemModel&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&const DeepCollectionEquality().equals(other.reasons, reasons)&&(identical(other.firstReportedAt, firstReportedAt) || other.firstReportedAt == firstReportedAt)&&(identical(other.lastReportedAt, lastReportedAt) || other.lastReportedAt == lastReportedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetType,targetId,status,reportCount,const DeepCollectionEquality().hash(reasons),firstReportedAt,lastReportedAt,closedAt,target);

@override
String toString() {
  return 'ModerationQueueItemModel(targetType: $targetType, targetId: $targetId, status: $status, reportCount: $reportCount, reasons: $reasons, firstReportedAt: $firstReportedAt, lastReportedAt: $lastReportedAt, closedAt: $closedAt, target: $target)';
}


}

/// @nodoc
abstract mixin class $ModerationQueueItemModelCopyWith<$Res>  {
  factory $ModerationQueueItemModelCopyWith(ModerationQueueItemModel value, $Res Function(ModerationQueueItemModel) _then) = _$ModerationQueueItemModelCopyWithImpl;
@useResult
$Res call({
 String targetType, String targetId, String status, int reportCount, Map<String, int> reasons, DateTime firstReportedAt, DateTime lastReportedAt, DateTime? closedAt, ModerationTargetModel target
});


$ModerationTargetModelCopyWith<$Res> get target;

}
/// @nodoc
class _$ModerationQueueItemModelCopyWithImpl<$Res>
    implements $ModerationQueueItemModelCopyWith<$Res> {
  _$ModerationQueueItemModelCopyWithImpl(this._self, this._then);

  final ModerationQueueItemModel _self;
  final $Res Function(ModerationQueueItemModel) _then;

/// Create a copy of ModerationQueueItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetType = null,Object? targetId = null,Object? status = null,Object? reportCount = null,Object? reasons = null,Object? firstReportedAt = null,Object? lastReportedAt = null,Object? closedAt = freezed,Object? target = null,}) {
  return _then(_self.copyWith(
targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as Map<String, int>,firstReportedAt: null == firstReportedAt ? _self.firstReportedAt : firstReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastReportedAt: null == lastReportedAt ? _self.lastReportedAt : lastReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ModerationTargetModel,
  ));
}
/// Create a copy of ModerationQueueItemModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationTargetModelCopyWith<$Res> get target {
  
  return $ModerationTargetModelCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationQueueItemModel].
extension ModerationQueueItemModelPatterns on ModerationQueueItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationQueueItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationQueueItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationQueueItemModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationQueueItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationQueueItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationQueueItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String targetType,  String targetId,  String status,  int reportCount,  Map<String, int> reasons,  DateTime firstReportedAt,  DateTime lastReportedAt,  DateTime? closedAt,  ModerationTargetModel target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationQueueItemModel() when $default != null:
return $default(_that.targetType,_that.targetId,_that.status,_that.reportCount,_that.reasons,_that.firstReportedAt,_that.lastReportedAt,_that.closedAt,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String targetType,  String targetId,  String status,  int reportCount,  Map<String, int> reasons,  DateTime firstReportedAt,  DateTime lastReportedAt,  DateTime? closedAt,  ModerationTargetModel target)  $default,) {final _that = this;
switch (_that) {
case _ModerationQueueItemModel():
return $default(_that.targetType,_that.targetId,_that.status,_that.reportCount,_that.reasons,_that.firstReportedAt,_that.lastReportedAt,_that.closedAt,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String targetType,  String targetId,  String status,  int reportCount,  Map<String, int> reasons,  DateTime firstReportedAt,  DateTime lastReportedAt,  DateTime? closedAt,  ModerationTargetModel target)?  $default,) {final _that = this;
switch (_that) {
case _ModerationQueueItemModel() when $default != null:
return $default(_that.targetType,_that.targetId,_that.status,_that.reportCount,_that.reasons,_that.firstReportedAt,_that.lastReportedAt,_that.closedAt,_that.target);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationQueueItemModel extends ModerationQueueItemModel {
  const _ModerationQueueItemModel({required this.targetType, required this.targetId, required this.status, this.reportCount = 0, final  Map<String, int> reasons = const <String, int>{}, required this.firstReportedAt, required this.lastReportedAt, this.closedAt, required this.target}): _reasons = reasons,super._();
  factory _ModerationQueueItemModel.fromJson(Map<String, dynamic> json) => _$ModerationQueueItemModelFromJson(json);

@override final  String targetType;
@override final  String targetId;
@override final  String status;
@override@JsonKey() final  int reportCount;
 final  Map<String, int> _reasons;
@override@JsonKey() Map<String, int> get reasons {
  if (_reasons is EqualUnmodifiableMapView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reasons);
}

@override final  DateTime firstReportedAt;
@override final  DateTime lastReportedAt;
@override final  DateTime? closedAt;
@override final  ModerationTargetModel target;

/// Create a copy of ModerationQueueItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationQueueItemModelCopyWith<_ModerationQueueItemModel> get copyWith => __$ModerationQueueItemModelCopyWithImpl<_ModerationQueueItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationQueueItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationQueueItemModel&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&const DeepCollectionEquality().equals(other._reasons, _reasons)&&(identical(other.firstReportedAt, firstReportedAt) || other.firstReportedAt == firstReportedAt)&&(identical(other.lastReportedAt, lastReportedAt) || other.lastReportedAt == lastReportedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetType,targetId,status,reportCount,const DeepCollectionEquality().hash(_reasons),firstReportedAt,lastReportedAt,closedAt,target);

@override
String toString() {
  return 'ModerationQueueItemModel(targetType: $targetType, targetId: $targetId, status: $status, reportCount: $reportCount, reasons: $reasons, firstReportedAt: $firstReportedAt, lastReportedAt: $lastReportedAt, closedAt: $closedAt, target: $target)';
}


}

/// @nodoc
abstract mixin class _$ModerationQueueItemModelCopyWith<$Res> implements $ModerationQueueItemModelCopyWith<$Res> {
  factory _$ModerationQueueItemModelCopyWith(_ModerationQueueItemModel value, $Res Function(_ModerationQueueItemModel) _then) = __$ModerationQueueItemModelCopyWithImpl;
@override @useResult
$Res call({
 String targetType, String targetId, String status, int reportCount, Map<String, int> reasons, DateTime firstReportedAt, DateTime lastReportedAt, DateTime? closedAt, ModerationTargetModel target
});


@override $ModerationTargetModelCopyWith<$Res> get target;

}
/// @nodoc
class __$ModerationQueueItemModelCopyWithImpl<$Res>
    implements _$ModerationQueueItemModelCopyWith<$Res> {
  __$ModerationQueueItemModelCopyWithImpl(this._self, this._then);

  final _ModerationQueueItemModel _self;
  final $Res Function(_ModerationQueueItemModel) _then;

/// Create a copy of ModerationQueueItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetType = null,Object? targetId = null,Object? status = null,Object? reportCount = null,Object? reasons = null,Object? firstReportedAt = null,Object? lastReportedAt = null,Object? closedAt = freezed,Object? target = null,}) {
  return _then(_ModerationQueueItemModel(
targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as Map<String, int>,firstReportedAt: null == firstReportedAt ? _self.firstReportedAt : firstReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastReportedAt: null == lastReportedAt ? _self.lastReportedAt : lastReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ModerationTargetModel,
  ));
}

/// Create a copy of ModerationQueueItemModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationTargetModelCopyWith<$Res> get target {
  
  return $ModerationTargetModelCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// @nodoc
mixin _$ModerationQueuePageModel {

 List<ModerationQueueItemModel> get items; String? get nextCursor;
/// Create a copy of ModerationQueuePageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationQueuePageModelCopyWith<ModerationQueuePageModel> get copyWith => _$ModerationQueuePageModelCopyWithImpl<ModerationQueuePageModel>(this as ModerationQueuePageModel, _$identity);

  /// Serializes this ModerationQueuePageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationQueuePageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'ModerationQueuePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $ModerationQueuePageModelCopyWith<$Res>  {
  factory $ModerationQueuePageModelCopyWith(ModerationQueuePageModel value, $Res Function(ModerationQueuePageModel) _then) = _$ModerationQueuePageModelCopyWithImpl;
@useResult
$Res call({
 List<ModerationQueueItemModel> items, String? nextCursor
});




}
/// @nodoc
class _$ModerationQueuePageModelCopyWithImpl<$Res>
    implements $ModerationQueuePageModelCopyWith<$Res> {
  _$ModerationQueuePageModelCopyWithImpl(this._self, this._then);

  final ModerationQueuePageModel _self;
  final $Res Function(ModerationQueuePageModel) _then;

/// Create a copy of ModerationQueuePageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ModerationQueueItemModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationQueuePageModel].
extension ModerationQueuePageModelPatterns on ModerationQueuePageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationQueuePageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationQueuePageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationQueuePageModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationQueuePageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationQueuePageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationQueuePageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ModerationQueueItemModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationQueuePageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ModerationQueueItemModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ModerationQueuePageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ModerationQueueItemModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ModerationQueuePageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationQueuePageModel implements ModerationQueuePageModel {
  const _ModerationQueuePageModel({final  List<ModerationQueueItemModel> items = const <ModerationQueueItemModel>[], this.nextCursor}): _items = items;
  factory _ModerationQueuePageModel.fromJson(Map<String, dynamic> json) => _$ModerationQueuePageModelFromJson(json);

 final  List<ModerationQueueItemModel> _items;
@override@JsonKey() List<ModerationQueueItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of ModerationQueuePageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationQueuePageModelCopyWith<_ModerationQueuePageModel> get copyWith => __$ModerationQueuePageModelCopyWithImpl<_ModerationQueuePageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationQueuePageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationQueuePageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'ModerationQueuePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ModerationQueuePageModelCopyWith<$Res> implements $ModerationQueuePageModelCopyWith<$Res> {
  factory _$ModerationQueuePageModelCopyWith(_ModerationQueuePageModel value, $Res Function(_ModerationQueuePageModel) _then) = __$ModerationQueuePageModelCopyWithImpl;
@override @useResult
$Res call({
 List<ModerationQueueItemModel> items, String? nextCursor
});




}
/// @nodoc
class __$ModerationQueuePageModelCopyWithImpl<$Res>
    implements _$ModerationQueuePageModelCopyWith<$Res> {
  __$ModerationQueuePageModelCopyWithImpl(this._self, this._then);

  final _ModerationQueuePageModel _self;
  final $Res Function(_ModerationQueuePageModel) _then;

/// Create a copy of ModerationQueuePageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_ModerationQueuePageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ModerationQueueItemModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ModerationReportModel {

 String get id; UserSummaryModel? get reporter; String get reason; String? get details; String get status; DateTime get createdAt; DateTime? get closedAt; UserSummaryModel? get closedBy;
/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationReportModelCopyWith<ModerationReportModel> get copyWith => _$ModerationReportModelCopyWithImpl<ModerationReportModel>(this as ModerationReportModel, _$identity);

  /// Serializes this ModerationReportModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.reporter, reporter) || other.reporter == reporter)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.closedBy, closedBy) || other.closedBy == closedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reporter,reason,details,status,createdAt,closedAt,closedBy);

@override
String toString() {
  return 'ModerationReportModel(id: $id, reporter: $reporter, reason: $reason, details: $details, status: $status, createdAt: $createdAt, closedAt: $closedAt, closedBy: $closedBy)';
}


}

/// @nodoc
abstract mixin class $ModerationReportModelCopyWith<$Res>  {
  factory $ModerationReportModelCopyWith(ModerationReportModel value, $Res Function(ModerationReportModel) _then) = _$ModerationReportModelCopyWithImpl;
@useResult
$Res call({
 String id, UserSummaryModel? reporter, String reason, String? details, String status, DateTime createdAt, DateTime? closedAt, UserSummaryModel? closedBy
});


$UserSummaryModelCopyWith<$Res>? get reporter;$UserSummaryModelCopyWith<$Res>? get closedBy;

}
/// @nodoc
class _$ModerationReportModelCopyWithImpl<$Res>
    implements $ModerationReportModelCopyWith<$Res> {
  _$ModerationReportModelCopyWithImpl(this._self, this._then);

  final ModerationReportModel _self;
  final $Res Function(ModerationReportModel) _then;

/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reporter = freezed,Object? reason = null,Object? details = freezed,Object? status = null,Object? createdAt = null,Object? closedAt = freezed,Object? closedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reporter: freezed == reporter ? _self.reporter : reporter // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedBy: freezed == closedBy ? _self.closedBy : closedBy // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,
  ));
}
/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get reporter {
    if (_self.reporter == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.reporter!, (value) {
    return _then(_self.copyWith(reporter: value));
  });
}/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get closedBy {
    if (_self.closedBy == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.closedBy!, (value) {
    return _then(_self.copyWith(closedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationReportModel].
extension ModerationReportModelPatterns on ModerationReportModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationReportModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationReportModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationReportModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationReportModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationReportModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationReportModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  UserSummaryModel? reporter,  String reason,  String? details,  String status,  DateTime createdAt,  DateTime? closedAt,  UserSummaryModel? closedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationReportModel() when $default != null:
return $default(_that.id,_that.reporter,_that.reason,_that.details,_that.status,_that.createdAt,_that.closedAt,_that.closedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  UserSummaryModel? reporter,  String reason,  String? details,  String status,  DateTime createdAt,  DateTime? closedAt,  UserSummaryModel? closedBy)  $default,) {final _that = this;
switch (_that) {
case _ModerationReportModel():
return $default(_that.id,_that.reporter,_that.reason,_that.details,_that.status,_that.createdAt,_that.closedAt,_that.closedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  UserSummaryModel? reporter,  String reason,  String? details,  String status,  DateTime createdAt,  DateTime? closedAt,  UserSummaryModel? closedBy)?  $default,) {final _that = this;
switch (_that) {
case _ModerationReportModel() when $default != null:
return $default(_that.id,_that.reporter,_that.reason,_that.details,_that.status,_that.createdAt,_that.closedAt,_that.closedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationReportModel extends ModerationReportModel {
  const _ModerationReportModel({required this.id, this.reporter, required this.reason, this.details, required this.status, required this.createdAt, this.closedAt, this.closedBy}): super._();
  factory _ModerationReportModel.fromJson(Map<String, dynamic> json) => _$ModerationReportModelFromJson(json);

@override final  String id;
@override final  UserSummaryModel? reporter;
@override final  String reason;
@override final  String? details;
@override final  String status;
@override final  DateTime createdAt;
@override final  DateTime? closedAt;
@override final  UserSummaryModel? closedBy;

/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationReportModelCopyWith<_ModerationReportModel> get copyWith => __$ModerationReportModelCopyWithImpl<_ModerationReportModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationReportModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.reporter, reporter) || other.reporter == reporter)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.closedBy, closedBy) || other.closedBy == closedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reporter,reason,details,status,createdAt,closedAt,closedBy);

@override
String toString() {
  return 'ModerationReportModel(id: $id, reporter: $reporter, reason: $reason, details: $details, status: $status, createdAt: $createdAt, closedAt: $closedAt, closedBy: $closedBy)';
}


}

/// @nodoc
abstract mixin class _$ModerationReportModelCopyWith<$Res> implements $ModerationReportModelCopyWith<$Res> {
  factory _$ModerationReportModelCopyWith(_ModerationReportModel value, $Res Function(_ModerationReportModel) _then) = __$ModerationReportModelCopyWithImpl;
@override @useResult
$Res call({
 String id, UserSummaryModel? reporter, String reason, String? details, String status, DateTime createdAt, DateTime? closedAt, UserSummaryModel? closedBy
});


@override $UserSummaryModelCopyWith<$Res>? get reporter;@override $UserSummaryModelCopyWith<$Res>? get closedBy;

}
/// @nodoc
class __$ModerationReportModelCopyWithImpl<$Res>
    implements _$ModerationReportModelCopyWith<$Res> {
  __$ModerationReportModelCopyWithImpl(this._self, this._then);

  final _ModerationReportModel _self;
  final $Res Function(_ModerationReportModel) _then;

/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reporter = freezed,Object? reason = null,Object? details = freezed,Object? status = null,Object? createdAt = null,Object? closedAt = freezed,Object? closedBy = freezed,}) {
  return _then(_ModerationReportModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reporter: freezed == reporter ? _self.reporter : reporter // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedBy: freezed == closedBy ? _self.closedBy : closedBy // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,
  ));
}

/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get reporter {
    if (_self.reporter == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.reporter!, (value) {
    return _then(_self.copyWith(reporter: value));
  });
}/// Create a copy of ModerationReportModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get closedBy {
    if (_self.closedBy == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.closedBy!, (value) {
    return _then(_self.copyWith(closedBy: value));
  });
}
}


/// @nodoc
mixin _$ModerationActionModel {

 String get id; String get action; String get targetType; String get targetId; String? get targetLabel; UserSummaryModel? get targetUser; UserSummaryModel? get moderator; String? get note; DateTime? get suspendedUntil; int get reportsClosed; DateTime get createdAt;
/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationActionModelCopyWith<ModerationActionModel> get copyWith => _$ModerationActionModelCopyWithImpl<ModerationActionModel>(this as ModerationActionModel, _$identity);

  /// Serializes this ModerationActionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationActionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.targetUser, targetUser) || other.targetUser == targetUser)&&(identical(other.moderator, moderator) || other.moderator == moderator)&&(identical(other.note, note) || other.note == note)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.reportsClosed, reportsClosed) || other.reportsClosed == reportsClosed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,targetType,targetId,targetLabel,targetUser,moderator,note,suspendedUntil,reportsClosed,createdAt);

@override
String toString() {
  return 'ModerationActionModel(id: $id, action: $action, targetType: $targetType, targetId: $targetId, targetLabel: $targetLabel, targetUser: $targetUser, moderator: $moderator, note: $note, suspendedUntil: $suspendedUntil, reportsClosed: $reportsClosed, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ModerationActionModelCopyWith<$Res>  {
  factory $ModerationActionModelCopyWith(ModerationActionModel value, $Res Function(ModerationActionModel) _then) = _$ModerationActionModelCopyWithImpl;
@useResult
$Res call({
 String id, String action, String targetType, String targetId, String? targetLabel, UserSummaryModel? targetUser, UserSummaryModel? moderator, String? note, DateTime? suspendedUntil, int reportsClosed, DateTime createdAt
});


$UserSummaryModelCopyWith<$Res>? get targetUser;$UserSummaryModelCopyWith<$Res>? get moderator;

}
/// @nodoc
class _$ModerationActionModelCopyWithImpl<$Res>
    implements $ModerationActionModelCopyWith<$Res> {
  _$ModerationActionModelCopyWithImpl(this._self, this._then);

  final ModerationActionModel _self;
  final $Res Function(ModerationActionModel) _then;

/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? targetType = null,Object? targetId = null,Object? targetLabel = freezed,Object? targetUser = freezed,Object? moderator = freezed,Object? note = freezed,Object? suspendedUntil = freezed,Object? reportsClosed = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,targetUser: freezed == targetUser ? _self.targetUser : targetUser // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,moderator: freezed == moderator ? _self.moderator : moderator // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,reportsClosed: null == reportsClosed ? _self.reportsClosed : reportsClosed // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get targetUser {
    if (_self.targetUser == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.targetUser!, (value) {
    return _then(_self.copyWith(targetUser: value));
  });
}/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get moderator {
    if (_self.moderator == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.moderator!, (value) {
    return _then(_self.copyWith(moderator: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationActionModel].
extension ModerationActionModelPatterns on ModerationActionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationActionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationActionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationActionModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationActionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationActionModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationActionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  String targetType,  String targetId,  String? targetLabel,  UserSummaryModel? targetUser,  UserSummaryModel? moderator,  String? note,  DateTime? suspendedUntil,  int reportsClosed,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationActionModel() when $default != null:
return $default(_that.id,_that.action,_that.targetType,_that.targetId,_that.targetLabel,_that.targetUser,_that.moderator,_that.note,_that.suspendedUntil,_that.reportsClosed,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  String targetType,  String targetId,  String? targetLabel,  UserSummaryModel? targetUser,  UserSummaryModel? moderator,  String? note,  DateTime? suspendedUntil,  int reportsClosed,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ModerationActionModel():
return $default(_that.id,_that.action,_that.targetType,_that.targetId,_that.targetLabel,_that.targetUser,_that.moderator,_that.note,_that.suspendedUntil,_that.reportsClosed,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  String targetType,  String targetId,  String? targetLabel,  UserSummaryModel? targetUser,  UserSummaryModel? moderator,  String? note,  DateTime? suspendedUntil,  int reportsClosed,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ModerationActionModel() when $default != null:
return $default(_that.id,_that.action,_that.targetType,_that.targetId,_that.targetLabel,_that.targetUser,_that.moderator,_that.note,_that.suspendedUntil,_that.reportsClosed,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationActionModel extends ModerationActionModel {
  const _ModerationActionModel({required this.id, required this.action, required this.targetType, required this.targetId, this.targetLabel, this.targetUser, this.moderator, this.note, this.suspendedUntil, this.reportsClosed = 0, required this.createdAt}): super._();
  factory _ModerationActionModel.fromJson(Map<String, dynamic> json) => _$ModerationActionModelFromJson(json);

@override final  String id;
@override final  String action;
@override final  String targetType;
@override final  String targetId;
@override final  String? targetLabel;
@override final  UserSummaryModel? targetUser;
@override final  UserSummaryModel? moderator;
@override final  String? note;
@override final  DateTime? suspendedUntil;
@override@JsonKey() final  int reportsClosed;
@override final  DateTime createdAt;

/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationActionModelCopyWith<_ModerationActionModel> get copyWith => __$ModerationActionModelCopyWithImpl<_ModerationActionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationActionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationActionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.targetUser, targetUser) || other.targetUser == targetUser)&&(identical(other.moderator, moderator) || other.moderator == moderator)&&(identical(other.note, note) || other.note == note)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.reportsClosed, reportsClosed) || other.reportsClosed == reportsClosed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,targetType,targetId,targetLabel,targetUser,moderator,note,suspendedUntil,reportsClosed,createdAt);

@override
String toString() {
  return 'ModerationActionModel(id: $id, action: $action, targetType: $targetType, targetId: $targetId, targetLabel: $targetLabel, targetUser: $targetUser, moderator: $moderator, note: $note, suspendedUntil: $suspendedUntil, reportsClosed: $reportsClosed, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ModerationActionModelCopyWith<$Res> implements $ModerationActionModelCopyWith<$Res> {
  factory _$ModerationActionModelCopyWith(_ModerationActionModel value, $Res Function(_ModerationActionModel) _then) = __$ModerationActionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, String targetType, String targetId, String? targetLabel, UserSummaryModel? targetUser, UserSummaryModel? moderator, String? note, DateTime? suspendedUntil, int reportsClosed, DateTime createdAt
});


@override $UserSummaryModelCopyWith<$Res>? get targetUser;@override $UserSummaryModelCopyWith<$Res>? get moderator;

}
/// @nodoc
class __$ModerationActionModelCopyWithImpl<$Res>
    implements _$ModerationActionModelCopyWith<$Res> {
  __$ModerationActionModelCopyWithImpl(this._self, this._then);

  final _ModerationActionModel _self;
  final $Res Function(_ModerationActionModel) _then;

/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? targetType = null,Object? targetId = null,Object? targetLabel = freezed,Object? targetUser = freezed,Object? moderator = freezed,Object? note = freezed,Object? suspendedUntil = freezed,Object? reportsClosed = null,Object? createdAt = null,}) {
  return _then(_ModerationActionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,targetUser: freezed == targetUser ? _self.targetUser : targetUser // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,moderator: freezed == moderator ? _self.moderator : moderator // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,reportsClosed: null == reportsClosed ? _self.reportsClosed : reportsClosed // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get targetUser {
    if (_self.targetUser == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.targetUser!, (value) {
    return _then(_self.copyWith(targetUser: value));
  });
}/// Create a copy of ModerationActionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get moderator {
    if (_self.moderator == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.moderator!, (value) {
    return _then(_self.copyWith(moderator: value));
  });
}
}


/// @nodoc
mixin _$ModerationActionPageModel {

 List<ModerationActionModel> get items; String? get nextCursor;
/// Create a copy of ModerationActionPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationActionPageModelCopyWith<ModerationActionPageModel> get copyWith => _$ModerationActionPageModelCopyWithImpl<ModerationActionPageModel>(this as ModerationActionPageModel, _$identity);

  /// Serializes this ModerationActionPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationActionPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'ModerationActionPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $ModerationActionPageModelCopyWith<$Res>  {
  factory $ModerationActionPageModelCopyWith(ModerationActionPageModel value, $Res Function(ModerationActionPageModel) _then) = _$ModerationActionPageModelCopyWithImpl;
@useResult
$Res call({
 List<ModerationActionModel> items, String? nextCursor
});




}
/// @nodoc
class _$ModerationActionPageModelCopyWithImpl<$Res>
    implements $ModerationActionPageModelCopyWith<$Res> {
  _$ModerationActionPageModelCopyWithImpl(this._self, this._then);

  final ModerationActionPageModel _self;
  final $Res Function(ModerationActionPageModel) _then;

/// Create a copy of ModerationActionPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ModerationActionModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationActionPageModel].
extension ModerationActionPageModelPatterns on ModerationActionPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationActionPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationActionPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationActionPageModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationActionPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationActionPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationActionPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ModerationActionModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationActionPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ModerationActionModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ModerationActionPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ModerationActionModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ModerationActionPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationActionPageModel implements ModerationActionPageModel {
  const _ModerationActionPageModel({final  List<ModerationActionModel> items = const <ModerationActionModel>[], this.nextCursor}): _items = items;
  factory _ModerationActionPageModel.fromJson(Map<String, dynamic> json) => _$ModerationActionPageModelFromJson(json);

 final  List<ModerationActionModel> _items;
@override@JsonKey() List<ModerationActionModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of ModerationActionPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationActionPageModelCopyWith<_ModerationActionPageModel> get copyWith => __$ModerationActionPageModelCopyWithImpl<_ModerationActionPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationActionPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationActionPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'ModerationActionPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ModerationActionPageModelCopyWith<$Res> implements $ModerationActionPageModelCopyWith<$Res> {
  factory _$ModerationActionPageModelCopyWith(_ModerationActionPageModel value, $Res Function(_ModerationActionPageModel) _then) = __$ModerationActionPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<ModerationActionModel> items, String? nextCursor
});




}
/// @nodoc
class __$ModerationActionPageModelCopyWithImpl<$Res>
    implements _$ModerationActionPageModelCopyWith<$Res> {
  __$ModerationActionPageModelCopyWithImpl(this._self, this._then);

  final _ModerationActionPageModel _self;
  final $Res Function(_ModerationActionPageModel) _then;

/// Create a copy of ModerationActionPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_ModerationActionPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ModerationActionModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ModerationCaseModel {

 ModerationQueueItemModel get item; List<ModerationReportModel> get reports; List<ModerationActionModel> get history;
/// Create a copy of ModerationCaseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationCaseModelCopyWith<ModerationCaseModel> get copyWith => _$ModerationCaseModelCopyWithImpl<ModerationCaseModel>(this as ModerationCaseModel, _$identity);

  /// Serializes this ModerationCaseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationCaseModel&&(identical(other.item, item) || other.item == item)&&const DeepCollectionEquality().equals(other.reports, reports)&&const DeepCollectionEquality().equals(other.history, history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,item,const DeepCollectionEquality().hash(reports),const DeepCollectionEquality().hash(history));

@override
String toString() {
  return 'ModerationCaseModel(item: $item, reports: $reports, history: $history)';
}


}

/// @nodoc
abstract mixin class $ModerationCaseModelCopyWith<$Res>  {
  factory $ModerationCaseModelCopyWith(ModerationCaseModel value, $Res Function(ModerationCaseModel) _then) = _$ModerationCaseModelCopyWithImpl;
@useResult
$Res call({
 ModerationQueueItemModel item, List<ModerationReportModel> reports, List<ModerationActionModel> history
});


$ModerationQueueItemModelCopyWith<$Res> get item;

}
/// @nodoc
class _$ModerationCaseModelCopyWithImpl<$Res>
    implements $ModerationCaseModelCopyWith<$Res> {
  _$ModerationCaseModelCopyWithImpl(this._self, this._then);

  final ModerationCaseModel _self;
  final $Res Function(ModerationCaseModel) _then;

/// Create a copy of ModerationCaseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? reports = null,Object? history = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as ModerationQueueItemModel,reports: null == reports ? _self.reports : reports // ignore: cast_nullable_to_non_nullable
as List<ModerationReportModel>,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<ModerationActionModel>,
  ));
}
/// Create a copy of ModerationCaseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationQueueItemModelCopyWith<$Res> get item {
  
  return $ModerationQueueItemModelCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationCaseModel].
extension ModerationCaseModelPatterns on ModerationCaseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationCaseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationCaseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationCaseModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationCaseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationCaseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationCaseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ModerationQueueItemModel item,  List<ModerationReportModel> reports,  List<ModerationActionModel> history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationCaseModel() when $default != null:
return $default(_that.item,_that.reports,_that.history);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ModerationQueueItemModel item,  List<ModerationReportModel> reports,  List<ModerationActionModel> history)  $default,) {final _that = this;
switch (_that) {
case _ModerationCaseModel():
return $default(_that.item,_that.reports,_that.history);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ModerationQueueItemModel item,  List<ModerationReportModel> reports,  List<ModerationActionModel> history)?  $default,) {final _that = this;
switch (_that) {
case _ModerationCaseModel() when $default != null:
return $default(_that.item,_that.reports,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationCaseModel implements ModerationCaseModel {
  const _ModerationCaseModel({required this.item, final  List<ModerationReportModel> reports = const <ModerationReportModel>[], final  List<ModerationActionModel> history = const <ModerationActionModel>[]}): _reports = reports,_history = history;
  factory _ModerationCaseModel.fromJson(Map<String, dynamic> json) => _$ModerationCaseModelFromJson(json);

@override final  ModerationQueueItemModel item;
 final  List<ModerationReportModel> _reports;
@override@JsonKey() List<ModerationReportModel> get reports {
  if (_reports is EqualUnmodifiableListView) return _reports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reports);
}

 final  List<ModerationActionModel> _history;
@override@JsonKey() List<ModerationActionModel> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}


/// Create a copy of ModerationCaseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationCaseModelCopyWith<_ModerationCaseModel> get copyWith => __$ModerationCaseModelCopyWithImpl<_ModerationCaseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationCaseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationCaseModel&&(identical(other.item, item) || other.item == item)&&const DeepCollectionEquality().equals(other._reports, _reports)&&const DeepCollectionEquality().equals(other._history, _history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,item,const DeepCollectionEquality().hash(_reports),const DeepCollectionEquality().hash(_history));

@override
String toString() {
  return 'ModerationCaseModel(item: $item, reports: $reports, history: $history)';
}


}

/// @nodoc
abstract mixin class _$ModerationCaseModelCopyWith<$Res> implements $ModerationCaseModelCopyWith<$Res> {
  factory _$ModerationCaseModelCopyWith(_ModerationCaseModel value, $Res Function(_ModerationCaseModel) _then) = __$ModerationCaseModelCopyWithImpl;
@override @useResult
$Res call({
 ModerationQueueItemModel item, List<ModerationReportModel> reports, List<ModerationActionModel> history
});


@override $ModerationQueueItemModelCopyWith<$Res> get item;

}
/// @nodoc
class __$ModerationCaseModelCopyWithImpl<$Res>
    implements _$ModerationCaseModelCopyWith<$Res> {
  __$ModerationCaseModelCopyWithImpl(this._self, this._then);

  final _ModerationCaseModel _self;
  final $Res Function(_ModerationCaseModel) _then;

/// Create a copy of ModerationCaseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? reports = null,Object? history = null,}) {
  return _then(_ModerationCaseModel(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as ModerationQueueItemModel,reports: null == reports ? _self._reports : reports // ignore: cast_nullable_to_non_nullable
as List<ModerationReportModel>,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<ModerationActionModel>,
  ));
}

/// Create a copy of ModerationCaseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationQueueItemModelCopyWith<$Res> get item {
  
  return $ModerationQueueItemModelCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// @nodoc
mixin _$ModerationNoticeArticleModel {

 String get id; String get slug; String get title;
/// Create a copy of ModerationNoticeArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationNoticeArticleModelCopyWith<ModerationNoticeArticleModel> get copyWith => _$ModerationNoticeArticleModelCopyWithImpl<ModerationNoticeArticleModel>(this as ModerationNoticeArticleModel, _$identity);

  /// Serializes this ModerationNoticeArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationNoticeArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title);

@override
String toString() {
  return 'ModerationNoticeArticleModel(id: $id, slug: $slug, title: $title)';
}


}

/// @nodoc
abstract mixin class $ModerationNoticeArticleModelCopyWith<$Res>  {
  factory $ModerationNoticeArticleModelCopyWith(ModerationNoticeArticleModel value, $Res Function(ModerationNoticeArticleModel) _then) = _$ModerationNoticeArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title
});




}
/// @nodoc
class _$ModerationNoticeArticleModelCopyWithImpl<$Res>
    implements $ModerationNoticeArticleModelCopyWith<$Res> {
  _$ModerationNoticeArticleModelCopyWithImpl(this._self, this._then);

  final ModerationNoticeArticleModel _self;
  final $Res Function(ModerationNoticeArticleModel) _then;

/// Create a copy of ModerationNoticeArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationNoticeArticleModel].
extension ModerationNoticeArticleModelPatterns on ModerationNoticeArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationNoticeArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationNoticeArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationNoticeArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationNoticeArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationNoticeArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationNoticeArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationNoticeArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title)  $default,) {final _that = this;
switch (_that) {
case _ModerationNoticeArticleModel():
return $default(_that.id,_that.slug,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title)?  $default,) {final _that = this;
switch (_that) {
case _ModerationNoticeArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationNoticeArticleModel implements ModerationNoticeArticleModel {
  const _ModerationNoticeArticleModel({required this.id, required this.slug, required this.title});
  factory _ModerationNoticeArticleModel.fromJson(Map<String, dynamic> json) => _$ModerationNoticeArticleModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;

/// Create a copy of ModerationNoticeArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationNoticeArticleModelCopyWith<_ModerationNoticeArticleModel> get copyWith => __$ModerationNoticeArticleModelCopyWithImpl<_ModerationNoticeArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationNoticeArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationNoticeArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title);

@override
String toString() {
  return 'ModerationNoticeArticleModel(id: $id, slug: $slug, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ModerationNoticeArticleModelCopyWith<$Res> implements $ModerationNoticeArticleModelCopyWith<$Res> {
  factory _$ModerationNoticeArticleModelCopyWith(_ModerationNoticeArticleModel value, $Res Function(_ModerationNoticeArticleModel) _then) = __$ModerationNoticeArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title
});




}
/// @nodoc
class __$ModerationNoticeArticleModelCopyWithImpl<$Res>
    implements _$ModerationNoticeArticleModelCopyWith<$Res> {
  __$ModerationNoticeArticleModelCopyWithImpl(this._self, this._then);

  final _ModerationNoticeArticleModel _self;
  final $Res Function(_ModerationNoticeArticleModel) _then;

/// Create a copy of ModerationNoticeArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,}) {
  return _then(_ModerationNoticeArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ModerationNoticeModel {

 String get id; String get kind; String? get note; ModerationNoticeArticleModel? get article; DateTime get createdAt;
/// Create a copy of ModerationNoticeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationNoticeModelCopyWith<ModerationNoticeModel> get copyWith => _$ModerationNoticeModelCopyWithImpl<ModerationNoticeModel>(this as ModerationNoticeModel, _$identity);

  /// Serializes this ModerationNoticeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationNoticeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.note, note) || other.note == note)&&(identical(other.article, article) || other.article == article)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,note,article,createdAt);

@override
String toString() {
  return 'ModerationNoticeModel(id: $id, kind: $kind, note: $note, article: $article, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ModerationNoticeModelCopyWith<$Res>  {
  factory $ModerationNoticeModelCopyWith(ModerationNoticeModel value, $Res Function(ModerationNoticeModel) _then) = _$ModerationNoticeModelCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String? note, ModerationNoticeArticleModel? article, DateTime createdAt
});


$ModerationNoticeArticleModelCopyWith<$Res>? get article;

}
/// @nodoc
class _$ModerationNoticeModelCopyWithImpl<$Res>
    implements $ModerationNoticeModelCopyWith<$Res> {
  _$ModerationNoticeModelCopyWithImpl(this._self, this._then);

  final ModerationNoticeModel _self;
  final $Res Function(ModerationNoticeModel) _then;

/// Create a copy of ModerationNoticeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? note = freezed,Object? article = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ModerationNoticeArticleModel?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ModerationNoticeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationNoticeArticleModelCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $ModerationNoticeArticleModelCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [ModerationNoticeModel].
extension ModerationNoticeModelPatterns on ModerationNoticeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationNoticeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationNoticeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationNoticeModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationNoticeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationNoticeModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationNoticeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String? note,  ModerationNoticeArticleModel? article,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationNoticeModel() when $default != null:
return $default(_that.id,_that.kind,_that.note,_that.article,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String? note,  ModerationNoticeArticleModel? article,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ModerationNoticeModel():
return $default(_that.id,_that.kind,_that.note,_that.article,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String? note,  ModerationNoticeArticleModel? article,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ModerationNoticeModel() when $default != null:
return $default(_that.id,_that.kind,_that.note,_that.article,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationNoticeModel extends ModerationNoticeModel {
  const _ModerationNoticeModel({required this.id, required this.kind, this.note, this.article, required this.createdAt}): super._();
  factory _ModerationNoticeModel.fromJson(Map<String, dynamic> json) => _$ModerationNoticeModelFromJson(json);

@override final  String id;
@override final  String kind;
@override final  String? note;
@override final  ModerationNoticeArticleModel? article;
@override final  DateTime createdAt;

/// Create a copy of ModerationNoticeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationNoticeModelCopyWith<_ModerationNoticeModel> get copyWith => __$ModerationNoticeModelCopyWithImpl<_ModerationNoticeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationNoticeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationNoticeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.note, note) || other.note == note)&&(identical(other.article, article) || other.article == article)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,note,article,createdAt);

@override
String toString() {
  return 'ModerationNoticeModel(id: $id, kind: $kind, note: $note, article: $article, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ModerationNoticeModelCopyWith<$Res> implements $ModerationNoticeModelCopyWith<$Res> {
  factory _$ModerationNoticeModelCopyWith(_ModerationNoticeModel value, $Res Function(_ModerationNoticeModel) _then) = __$ModerationNoticeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String? note, ModerationNoticeArticleModel? article, DateTime createdAt
});


@override $ModerationNoticeArticleModelCopyWith<$Res>? get article;

}
/// @nodoc
class __$ModerationNoticeModelCopyWithImpl<$Res>
    implements _$ModerationNoticeModelCopyWith<$Res> {
  __$ModerationNoticeModelCopyWithImpl(this._self, this._then);

  final _ModerationNoticeModel _self;
  final $Res Function(_ModerationNoticeModel) _then;

/// Create a copy of ModerationNoticeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? note = freezed,Object? article = freezed,Object? createdAt = null,}) {
  return _then(_ModerationNoticeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ModerationNoticeArticleModel?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ModerationNoticeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerationNoticeArticleModelCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $ModerationNoticeArticleModelCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// @nodoc
mixin _$ModerationNoticesModel {

 List<ModerationNoticeModel> get items;
/// Create a copy of ModerationNoticesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationNoticesModelCopyWith<ModerationNoticesModel> get copyWith => _$ModerationNoticesModelCopyWithImpl<ModerationNoticesModel>(this as ModerationNoticesModel, _$identity);

  /// Serializes this ModerationNoticesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationNoticesModel&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ModerationNoticesModel(items: $items)';
}


}

/// @nodoc
abstract mixin class $ModerationNoticesModelCopyWith<$Res>  {
  factory $ModerationNoticesModelCopyWith(ModerationNoticesModel value, $Res Function(ModerationNoticesModel) _then) = _$ModerationNoticesModelCopyWithImpl;
@useResult
$Res call({
 List<ModerationNoticeModel> items
});




}
/// @nodoc
class _$ModerationNoticesModelCopyWithImpl<$Res>
    implements $ModerationNoticesModelCopyWith<$Res> {
  _$ModerationNoticesModelCopyWithImpl(this._self, this._then);

  final ModerationNoticesModel _self;
  final $Res Function(ModerationNoticesModel) _then;

/// Create a copy of ModerationNoticesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ModerationNoticeModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationNoticesModel].
extension ModerationNoticesModelPatterns on ModerationNoticesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationNoticesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationNoticesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationNoticesModel value)  $default,){
final _that = this;
switch (_that) {
case _ModerationNoticesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationNoticesModel value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationNoticesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ModerationNoticeModel> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationNoticesModel() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ModerationNoticeModel> items)  $default,) {final _that = this;
switch (_that) {
case _ModerationNoticesModel():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ModerationNoticeModel> items)?  $default,) {final _that = this;
switch (_that) {
case _ModerationNoticesModel() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationNoticesModel implements ModerationNoticesModel {
  const _ModerationNoticesModel({final  List<ModerationNoticeModel> items = const <ModerationNoticeModel>[]}): _items = items;
  factory _ModerationNoticesModel.fromJson(Map<String, dynamic> json) => _$ModerationNoticesModelFromJson(json);

 final  List<ModerationNoticeModel> _items;
@override@JsonKey() List<ModerationNoticeModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ModerationNoticesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationNoticesModelCopyWith<_ModerationNoticesModel> get copyWith => __$ModerationNoticesModelCopyWithImpl<_ModerationNoticesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationNoticesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationNoticesModel&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ModerationNoticesModel(items: $items)';
}


}

/// @nodoc
abstract mixin class _$ModerationNoticesModelCopyWith<$Res> implements $ModerationNoticesModelCopyWith<$Res> {
  factory _$ModerationNoticesModelCopyWith(_ModerationNoticesModel value, $Res Function(_ModerationNoticesModel) _then) = __$ModerationNoticesModelCopyWithImpl;
@override @useResult
$Res call({
 List<ModerationNoticeModel> items
});




}
/// @nodoc
class __$ModerationNoticesModelCopyWithImpl<$Res>
    implements _$ModerationNoticesModelCopyWith<$Res> {
  __$ModerationNoticesModelCopyWithImpl(this._self, this._then);

  final _ModerationNoticesModel _self;
  final $Res Function(_ModerationNoticesModel) _then;

/// Create a copy of ModerationNoticesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_ModerationNoticesModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ModerationNoticeModel>,
  ));
}


}

// dart format on
