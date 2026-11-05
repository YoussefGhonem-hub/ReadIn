// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repost_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RepostStateModel {

 int get repostCount; bool get isReposted;
/// Create a copy of RepostStateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepostStateModelCopyWith<RepostStateModel> get copyWith => _$RepostStateModelCopyWithImpl<RepostStateModel>(this as RepostStateModel, _$identity);

  /// Serializes this RepostStateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepostStateModel&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,repostCount,isReposted);

@override
String toString() {
  return 'RepostStateModel(repostCount: $repostCount, isReposted: $isReposted)';
}


}

/// @nodoc
abstract mixin class $RepostStateModelCopyWith<$Res>  {
  factory $RepostStateModelCopyWith(RepostStateModel value, $Res Function(RepostStateModel) _then) = _$RepostStateModelCopyWithImpl;
@useResult
$Res call({
 int repostCount, bool isReposted
});




}
/// @nodoc
class _$RepostStateModelCopyWithImpl<$Res>
    implements $RepostStateModelCopyWith<$Res> {
  _$RepostStateModelCopyWithImpl(this._self, this._then);

  final RepostStateModel _self;
  final $Res Function(RepostStateModel) _then;

/// Create a copy of RepostStateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? repostCount = null,Object? isReposted = null,}) {
  return _then(_self.copyWith(
repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RepostStateModel].
extension RepostStateModelPatterns on RepostStateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepostStateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepostStateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepostStateModel value)  $default,){
final _that = this;
switch (_that) {
case _RepostStateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepostStateModel value)?  $default,){
final _that = this;
switch (_that) {
case _RepostStateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int repostCount,  bool isReposted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepostStateModel() when $default != null:
return $default(_that.repostCount,_that.isReposted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int repostCount,  bool isReposted)  $default,) {final _that = this;
switch (_that) {
case _RepostStateModel():
return $default(_that.repostCount,_that.isReposted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int repostCount,  bool isReposted)?  $default,) {final _that = this;
switch (_that) {
case _RepostStateModel() when $default != null:
return $default(_that.repostCount,_that.isReposted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RepostStateModel extends RepostStateModel {
  const _RepostStateModel({this.repostCount = 0, this.isReposted = false}): super._();
  factory _RepostStateModel.fromJson(Map<String, dynamic> json) => _$RepostStateModelFromJson(json);

@override@JsonKey() final  int repostCount;
@override@JsonKey() final  bool isReposted;

/// Create a copy of RepostStateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepostStateModelCopyWith<_RepostStateModel> get copyWith => __$RepostStateModelCopyWithImpl<_RepostStateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepostStateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepostStateModel&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.isReposted, isReposted) || other.isReposted == isReposted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,repostCount,isReposted);

@override
String toString() {
  return 'RepostStateModel(repostCount: $repostCount, isReposted: $isReposted)';
}


}

/// @nodoc
abstract mixin class _$RepostStateModelCopyWith<$Res> implements $RepostStateModelCopyWith<$Res> {
  factory _$RepostStateModelCopyWith(_RepostStateModel value, $Res Function(_RepostStateModel) _then) = __$RepostStateModelCopyWithImpl;
@override @useResult
$Res call({
 int repostCount, bool isReposted
});




}
/// @nodoc
class __$RepostStateModelCopyWithImpl<$Res>
    implements _$RepostStateModelCopyWith<$Res> {
  __$RepostStateModelCopyWithImpl(this._self, this._then);

  final _RepostStateModel _self;
  final $Res Function(_RepostStateModel) _then;

/// Create a copy of RepostStateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? repostCount = null,Object? isReposted = null,}) {
  return _then(_RepostStateModel(
repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,isReposted: null == isReposted ? _self.isReposted : isReposted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
