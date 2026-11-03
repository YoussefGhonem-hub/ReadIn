// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interests_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateInterestsRequest {

 List<String> get fieldIds; List<String> get topicIds;
/// Create a copy of UpdateInterestsRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateInterestsRequestCopyWith<UpdateInterestsRequest> get copyWith => _$UpdateInterestsRequestCopyWithImpl<UpdateInterestsRequest>(this as UpdateInterestsRequest, _$identity);

  /// Serializes this UpdateInterestsRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateInterestsRequest&&const DeepCollectionEquality().equals(other.fieldIds, fieldIds)&&const DeepCollectionEquality().equals(other.topicIds, topicIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fieldIds),const DeepCollectionEquality().hash(topicIds));

@override
String toString() {
  return 'UpdateInterestsRequest(fieldIds: $fieldIds, topicIds: $topicIds)';
}


}

/// @nodoc
abstract mixin class $UpdateInterestsRequestCopyWith<$Res>  {
  factory $UpdateInterestsRequestCopyWith(UpdateInterestsRequest value, $Res Function(UpdateInterestsRequest) _then) = _$UpdateInterestsRequestCopyWithImpl;
@useResult
$Res call({
 List<String> fieldIds, List<String> topicIds
});




}
/// @nodoc
class _$UpdateInterestsRequestCopyWithImpl<$Res>
    implements $UpdateInterestsRequestCopyWith<$Res> {
  _$UpdateInterestsRequestCopyWithImpl(this._self, this._then);

  final UpdateInterestsRequest _self;
  final $Res Function(UpdateInterestsRequest) _then;

/// Create a copy of UpdateInterestsRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fieldIds = null,Object? topicIds = null,}) {
  return _then(_self.copyWith(
fieldIds: null == fieldIds ? _self.fieldIds : fieldIds // ignore: cast_nullable_to_non_nullable
as List<String>,topicIds: null == topicIds ? _self.topicIds : topicIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateInterestsRequest].
extension UpdateInterestsRequestPatterns on UpdateInterestsRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateInterestsRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateInterestsRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateInterestsRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdateInterestsRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateInterestsRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateInterestsRequest() when $default != null:
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
case _UpdateInterestsRequest() when $default != null:
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
case _UpdateInterestsRequest():
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
case _UpdateInterestsRequest() when $default != null:
return $default(_that.fieldIds,_that.topicIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateInterestsRequest implements UpdateInterestsRequest {
  const _UpdateInterestsRequest({required final  List<String> fieldIds, required final  List<String> topicIds}): _fieldIds = fieldIds,_topicIds = topicIds;
  factory _UpdateInterestsRequest.fromJson(Map<String, dynamic> json) => _$UpdateInterestsRequestFromJson(json);

 final  List<String> _fieldIds;
@override List<String> get fieldIds {
  if (_fieldIds is EqualUnmodifiableListView) return _fieldIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fieldIds);
}

 final  List<String> _topicIds;
@override List<String> get topicIds {
  if (_topicIds is EqualUnmodifiableListView) return _topicIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topicIds);
}


/// Create a copy of UpdateInterestsRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateInterestsRequestCopyWith<_UpdateInterestsRequest> get copyWith => __$UpdateInterestsRequestCopyWithImpl<_UpdateInterestsRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateInterestsRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateInterestsRequest&&const DeepCollectionEquality().equals(other._fieldIds, _fieldIds)&&const DeepCollectionEquality().equals(other._topicIds, _topicIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fieldIds),const DeepCollectionEquality().hash(_topicIds));

@override
String toString() {
  return 'UpdateInterestsRequest(fieldIds: $fieldIds, topicIds: $topicIds)';
}


}

/// @nodoc
abstract mixin class _$UpdateInterestsRequestCopyWith<$Res> implements $UpdateInterestsRequestCopyWith<$Res> {
  factory _$UpdateInterestsRequestCopyWith(_UpdateInterestsRequest value, $Res Function(_UpdateInterestsRequest) _then) = __$UpdateInterestsRequestCopyWithImpl;
@override @useResult
$Res call({
 List<String> fieldIds, List<String> topicIds
});




}
/// @nodoc
class __$UpdateInterestsRequestCopyWithImpl<$Res>
    implements _$UpdateInterestsRequestCopyWith<$Res> {
  __$UpdateInterestsRequestCopyWithImpl(this._self, this._then);

  final _UpdateInterestsRequest _self;
  final $Res Function(_UpdateInterestsRequest) _then;

/// Create a copy of UpdateInterestsRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fieldIds = null,Object? topicIds = null,}) {
  return _then(_UpdateInterestsRequest(
fieldIds: null == fieldIds ? _self._fieldIds : fieldIds // ignore: cast_nullable_to_non_nullable
as List<String>,topicIds: null == topicIds ? _self._topicIds : topicIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
