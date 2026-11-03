// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingProgressRequestModel {

 String get language; int get percent; String? get lastPosition; int get activeSecondsDelta;
/// Create a copy of ReadingProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingProgressRequestModelCopyWith<ReadingProgressRequestModel> get copyWith => _$ReadingProgressRequestModelCopyWithImpl<ReadingProgressRequestModel>(this as ReadingProgressRequestModel, _$identity);

  /// Serializes this ReadingProgressRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingProgressRequestModel&&(identical(other.language, language) || other.language == language)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.lastPosition, lastPosition) || other.lastPosition == lastPosition)&&(identical(other.activeSecondsDelta, activeSecondsDelta) || other.activeSecondsDelta == activeSecondsDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,percent,lastPosition,activeSecondsDelta);

@override
String toString() {
  return 'ReadingProgressRequestModel(language: $language, percent: $percent, lastPosition: $lastPosition, activeSecondsDelta: $activeSecondsDelta)';
}


}

/// @nodoc
abstract mixin class $ReadingProgressRequestModelCopyWith<$Res>  {
  factory $ReadingProgressRequestModelCopyWith(ReadingProgressRequestModel value, $Res Function(ReadingProgressRequestModel) _then) = _$ReadingProgressRequestModelCopyWithImpl;
@useResult
$Res call({
 String language, int percent, String? lastPosition, int activeSecondsDelta
});




}
/// @nodoc
class _$ReadingProgressRequestModelCopyWithImpl<$Res>
    implements $ReadingProgressRequestModelCopyWith<$Res> {
  _$ReadingProgressRequestModelCopyWithImpl(this._self, this._then);

  final ReadingProgressRequestModel _self;
  final $Res Function(ReadingProgressRequestModel) _then;

/// Create a copy of ReadingProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? percent = null,Object? lastPosition = freezed,Object? activeSecondsDelta = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,lastPosition: freezed == lastPosition ? _self.lastPosition : lastPosition // ignore: cast_nullable_to_non_nullable
as String?,activeSecondsDelta: null == activeSecondsDelta ? _self.activeSecondsDelta : activeSecondsDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingProgressRequestModel].
extension ReadingProgressRequestModelPatterns on ReadingProgressRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingProgressRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingProgressRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingProgressRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _ReadingProgressRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingProgressRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingProgressRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  int percent,  String? lastPosition,  int activeSecondsDelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingProgressRequestModel() when $default != null:
return $default(_that.language,_that.percent,_that.lastPosition,_that.activeSecondsDelta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  int percent,  String? lastPosition,  int activeSecondsDelta)  $default,) {final _that = this;
switch (_that) {
case _ReadingProgressRequestModel():
return $default(_that.language,_that.percent,_that.lastPosition,_that.activeSecondsDelta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  int percent,  String? lastPosition,  int activeSecondsDelta)?  $default,) {final _that = this;
switch (_that) {
case _ReadingProgressRequestModel() when $default != null:
return $default(_that.language,_that.percent,_that.lastPosition,_that.activeSecondsDelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingProgressRequestModel implements ReadingProgressRequestModel {
  const _ReadingProgressRequestModel({required this.language, required this.percent, this.lastPosition, required this.activeSecondsDelta});
  factory _ReadingProgressRequestModel.fromJson(Map<String, dynamic> json) => _$ReadingProgressRequestModelFromJson(json);

@override final  String language;
@override final  int percent;
@override final  String? lastPosition;
@override final  int activeSecondsDelta;

/// Create a copy of ReadingProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingProgressRequestModelCopyWith<_ReadingProgressRequestModel> get copyWith => __$ReadingProgressRequestModelCopyWithImpl<_ReadingProgressRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingProgressRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingProgressRequestModel&&(identical(other.language, language) || other.language == language)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.lastPosition, lastPosition) || other.lastPosition == lastPosition)&&(identical(other.activeSecondsDelta, activeSecondsDelta) || other.activeSecondsDelta == activeSecondsDelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,percent,lastPosition,activeSecondsDelta);

@override
String toString() {
  return 'ReadingProgressRequestModel(language: $language, percent: $percent, lastPosition: $lastPosition, activeSecondsDelta: $activeSecondsDelta)';
}


}

/// @nodoc
abstract mixin class _$ReadingProgressRequestModelCopyWith<$Res> implements $ReadingProgressRequestModelCopyWith<$Res> {
  factory _$ReadingProgressRequestModelCopyWith(_ReadingProgressRequestModel value, $Res Function(_ReadingProgressRequestModel) _then) = __$ReadingProgressRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String language, int percent, String? lastPosition, int activeSecondsDelta
});




}
/// @nodoc
class __$ReadingProgressRequestModelCopyWithImpl<$Res>
    implements _$ReadingProgressRequestModelCopyWith<$Res> {
  __$ReadingProgressRequestModelCopyWithImpl(this._self, this._then);

  final _ReadingProgressRequestModel _self;
  final $Res Function(_ReadingProgressRequestModel) _then;

/// Create a copy of ReadingProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? percent = null,Object? lastPosition = freezed,Object? activeSecondsDelta = null,}) {
  return _then(_ReadingProgressRequestModel(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,lastPosition: freezed == lastPosition ? _self.lastPosition : lastPosition // ignore: cast_nullable_to_non_nullable
as String?,activeSecondsDelta: null == activeSecondsDelta ? _self.activeSecondsDelta : activeSecondsDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StreakModel {

 int get current; int get longest; bool get readToday; bool get freezeAvailable; bool get freezePending; String get today;
/// Create a copy of StreakModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakModelCopyWith<StreakModel> get copyWith => _$StreakModelCopyWithImpl<StreakModel>(this as StreakModel, _$identity);

  /// Serializes this StreakModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakModel&&(identical(other.current, current) || other.current == current)&&(identical(other.longest, longest) || other.longest == longest)&&(identical(other.readToday, readToday) || other.readToday == readToday)&&(identical(other.freezeAvailable, freezeAvailable) || other.freezeAvailable == freezeAvailable)&&(identical(other.freezePending, freezePending) || other.freezePending == freezePending)&&(identical(other.today, today) || other.today == today));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,current,longest,readToday,freezeAvailable,freezePending,today);

@override
String toString() {
  return 'StreakModel(current: $current, longest: $longest, readToday: $readToday, freezeAvailable: $freezeAvailable, freezePending: $freezePending, today: $today)';
}


}

/// @nodoc
abstract mixin class $StreakModelCopyWith<$Res>  {
  factory $StreakModelCopyWith(StreakModel value, $Res Function(StreakModel) _then) = _$StreakModelCopyWithImpl;
@useResult
$Res call({
 int current, int longest, bool readToday, bool freezeAvailable, bool freezePending, String today
});




}
/// @nodoc
class _$StreakModelCopyWithImpl<$Res>
    implements $StreakModelCopyWith<$Res> {
  _$StreakModelCopyWithImpl(this._self, this._then);

  final StreakModel _self;
  final $Res Function(StreakModel) _then;

/// Create a copy of StreakModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? current = null,Object? longest = null,Object? readToday = null,Object? freezeAvailable = null,Object? freezePending = null,Object? today = null,}) {
  return _then(_self.copyWith(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,longest: null == longest ? _self.longest : longest // ignore: cast_nullable_to_non_nullable
as int,readToday: null == readToday ? _self.readToday : readToday // ignore: cast_nullable_to_non_nullable
as bool,freezeAvailable: null == freezeAvailable ? _self.freezeAvailable : freezeAvailable // ignore: cast_nullable_to_non_nullable
as bool,freezePending: null == freezePending ? _self.freezePending : freezePending // ignore: cast_nullable_to_non_nullable
as bool,today: null == today ? _self.today : today // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakModel].
extension StreakModelPatterns on StreakModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakModel value)  $default,){
final _that = this;
switch (_that) {
case _StreakModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakModel value)?  $default,){
final _that = this;
switch (_that) {
case _StreakModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int current,  int longest,  bool readToday,  bool freezeAvailable,  bool freezePending,  String today)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakModel() when $default != null:
return $default(_that.current,_that.longest,_that.readToday,_that.freezeAvailable,_that.freezePending,_that.today);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int current,  int longest,  bool readToday,  bool freezeAvailable,  bool freezePending,  String today)  $default,) {final _that = this;
switch (_that) {
case _StreakModel():
return $default(_that.current,_that.longest,_that.readToday,_that.freezeAvailable,_that.freezePending,_that.today);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int current,  int longest,  bool readToday,  bool freezeAvailable,  bool freezePending,  String today)?  $default,) {final _that = this;
switch (_that) {
case _StreakModel() when $default != null:
return $default(_that.current,_that.longest,_that.readToday,_that.freezeAvailable,_that.freezePending,_that.today);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakModel extends StreakModel {
  const _StreakModel({this.current = 0, this.longest = 0, this.readToday = false, this.freezeAvailable = false, this.freezePending = false, required this.today}): super._();
  factory _StreakModel.fromJson(Map<String, dynamic> json) => _$StreakModelFromJson(json);

@override@JsonKey() final  int current;
@override@JsonKey() final  int longest;
@override@JsonKey() final  bool readToday;
@override@JsonKey() final  bool freezeAvailable;
@override@JsonKey() final  bool freezePending;
@override final  String today;

/// Create a copy of StreakModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakModelCopyWith<_StreakModel> get copyWith => __$StreakModelCopyWithImpl<_StreakModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakModel&&(identical(other.current, current) || other.current == current)&&(identical(other.longest, longest) || other.longest == longest)&&(identical(other.readToday, readToday) || other.readToday == readToday)&&(identical(other.freezeAvailable, freezeAvailable) || other.freezeAvailable == freezeAvailable)&&(identical(other.freezePending, freezePending) || other.freezePending == freezePending)&&(identical(other.today, today) || other.today == today));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,current,longest,readToday,freezeAvailable,freezePending,today);

@override
String toString() {
  return 'StreakModel(current: $current, longest: $longest, readToday: $readToday, freezeAvailable: $freezeAvailable, freezePending: $freezePending, today: $today)';
}


}

/// @nodoc
abstract mixin class _$StreakModelCopyWith<$Res> implements $StreakModelCopyWith<$Res> {
  factory _$StreakModelCopyWith(_StreakModel value, $Res Function(_StreakModel) _then) = __$StreakModelCopyWithImpl;
@override @useResult
$Res call({
 int current, int longest, bool readToday, bool freezeAvailable, bool freezePending, String today
});




}
/// @nodoc
class __$StreakModelCopyWithImpl<$Res>
    implements _$StreakModelCopyWith<$Res> {
  __$StreakModelCopyWithImpl(this._self, this._then);

  final _StreakModel _self;
  final $Res Function(_StreakModel) _then;

/// Create a copy of StreakModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? current = null,Object? longest = null,Object? readToday = null,Object? freezeAvailable = null,Object? freezePending = null,Object? today = null,}) {
  return _then(_StreakModel(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,longest: null == longest ? _self.longest : longest // ignore: cast_nullable_to_non_nullable
as int,readToday: null == readToday ? _self.readToday : readToday // ignore: cast_nullable_to_non_nullable
as bool,freezeAvailable: null == freezeAvailable ? _self.freezeAvailable : freezeAvailable // ignore: cast_nullable_to_non_nullable
as bool,freezePending: null == freezePending ? _self.freezePending : freezePending // ignore: cast_nullable_to_non_nullable
as bool,today: null == today ? _self.today : today // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ReadingProgressResultModel {

 int get percent; bool get completed; bool get completedNow; StreakModel? get streak; int? get milestone;
/// Create a copy of ReadingProgressResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingProgressResultModelCopyWith<ReadingProgressResultModel> get copyWith => _$ReadingProgressResultModelCopyWithImpl<ReadingProgressResultModel>(this as ReadingProgressResultModel, _$identity);

  /// Serializes this ReadingProgressResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingProgressResultModel&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.completedNow, completedNow) || other.completedNow == completedNow)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.milestone, milestone) || other.milestone == milestone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,percent,completed,completedNow,streak,milestone);

@override
String toString() {
  return 'ReadingProgressResultModel(percent: $percent, completed: $completed, completedNow: $completedNow, streak: $streak, milestone: $milestone)';
}


}

/// @nodoc
abstract mixin class $ReadingProgressResultModelCopyWith<$Res>  {
  factory $ReadingProgressResultModelCopyWith(ReadingProgressResultModel value, $Res Function(ReadingProgressResultModel) _then) = _$ReadingProgressResultModelCopyWithImpl;
@useResult
$Res call({
 int percent, bool completed, bool completedNow, StreakModel? streak, int? milestone
});


$StreakModelCopyWith<$Res>? get streak;

}
/// @nodoc
class _$ReadingProgressResultModelCopyWithImpl<$Res>
    implements $ReadingProgressResultModelCopyWith<$Res> {
  _$ReadingProgressResultModelCopyWithImpl(this._self, this._then);

  final ReadingProgressResultModel _self;
  final $Res Function(ReadingProgressResultModel) _then;

/// Create a copy of ReadingProgressResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? percent = null,Object? completed = null,Object? completedNow = null,Object? streak = freezed,Object? milestone = freezed,}) {
  return _then(_self.copyWith(
percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,completedNow: null == completedNow ? _self.completedNow : completedNow // ignore: cast_nullable_to_non_nullable
as bool,streak: freezed == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as StreakModel?,milestone: freezed == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ReadingProgressResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakModelCopyWith<$Res>? get streak {
    if (_self.streak == null) {
    return null;
  }

  return $StreakModelCopyWith<$Res>(_self.streak!, (value) {
    return _then(_self.copyWith(streak: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingProgressResultModel].
extension ReadingProgressResultModelPatterns on ReadingProgressResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingProgressResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingProgressResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingProgressResultModel value)  $default,){
final _that = this;
switch (_that) {
case _ReadingProgressResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingProgressResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingProgressResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int percent,  bool completed,  bool completedNow,  StreakModel? streak,  int? milestone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingProgressResultModel() when $default != null:
return $default(_that.percent,_that.completed,_that.completedNow,_that.streak,_that.milestone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int percent,  bool completed,  bool completedNow,  StreakModel? streak,  int? milestone)  $default,) {final _that = this;
switch (_that) {
case _ReadingProgressResultModel():
return $default(_that.percent,_that.completed,_that.completedNow,_that.streak,_that.milestone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int percent,  bool completed,  bool completedNow,  StreakModel? streak,  int? milestone)?  $default,) {final _that = this;
switch (_that) {
case _ReadingProgressResultModel() when $default != null:
return $default(_that.percent,_that.completed,_that.completedNow,_that.streak,_that.milestone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingProgressResultModel extends ReadingProgressResultModel {
  const _ReadingProgressResultModel({this.percent = 0, this.completed = false, this.completedNow = false, this.streak, this.milestone}): super._();
  factory _ReadingProgressResultModel.fromJson(Map<String, dynamic> json) => _$ReadingProgressResultModelFromJson(json);

@override@JsonKey() final  int percent;
@override@JsonKey() final  bool completed;
@override@JsonKey() final  bool completedNow;
@override final  StreakModel? streak;
@override final  int? milestone;

/// Create a copy of ReadingProgressResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingProgressResultModelCopyWith<_ReadingProgressResultModel> get copyWith => __$ReadingProgressResultModelCopyWithImpl<_ReadingProgressResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingProgressResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingProgressResultModel&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.completedNow, completedNow) || other.completedNow == completedNow)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.milestone, milestone) || other.milestone == milestone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,percent,completed,completedNow,streak,milestone);

@override
String toString() {
  return 'ReadingProgressResultModel(percent: $percent, completed: $completed, completedNow: $completedNow, streak: $streak, milestone: $milestone)';
}


}

/// @nodoc
abstract mixin class _$ReadingProgressResultModelCopyWith<$Res> implements $ReadingProgressResultModelCopyWith<$Res> {
  factory _$ReadingProgressResultModelCopyWith(_ReadingProgressResultModel value, $Res Function(_ReadingProgressResultModel) _then) = __$ReadingProgressResultModelCopyWithImpl;
@override @useResult
$Res call({
 int percent, bool completed, bool completedNow, StreakModel? streak, int? milestone
});


@override $StreakModelCopyWith<$Res>? get streak;

}
/// @nodoc
class __$ReadingProgressResultModelCopyWithImpl<$Res>
    implements _$ReadingProgressResultModelCopyWith<$Res> {
  __$ReadingProgressResultModelCopyWithImpl(this._self, this._then);

  final _ReadingProgressResultModel _self;
  final $Res Function(_ReadingProgressResultModel) _then;

/// Create a copy of ReadingProgressResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? percent = null,Object? completed = null,Object? completedNow = null,Object? streak = freezed,Object? milestone = freezed,}) {
  return _then(_ReadingProgressResultModel(
percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,completedNow: null == completedNow ? _self.completedNow : completedNow // ignore: cast_nullable_to_non_nullable
as bool,streak: freezed == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as StreakModel?,milestone: freezed == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ReadingProgressResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakModelCopyWith<$Res>? get streak {
    if (_self.streak == null) {
    return null;
  }

  return $StreakModelCopyWith<$Res>(_self.streak!, (value) {
    return _then(_self.copyWith(streak: value));
  });
}
}


/// @nodoc
mixin _$TopFieldModel {

 String get id; String get slug; String get name; String get icon; String get color; int get articles;
/// Create a copy of TopFieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopFieldModelCopyWith<TopFieldModel> get copyWith => _$TopFieldModelCopyWithImpl<TopFieldModel>(this as TopFieldModel, _$identity);

  /// Serializes this TopFieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.articles, articles) || other.articles == articles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,icon,color,articles);

@override
String toString() {
  return 'TopFieldModel(id: $id, slug: $slug, name: $name, icon: $icon, color: $color, articles: $articles)';
}


}

/// @nodoc
abstract mixin class $TopFieldModelCopyWith<$Res>  {
  factory $TopFieldModelCopyWith(TopFieldModel value, $Res Function(TopFieldModel) _then) = _$TopFieldModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String icon, String color, int articles
});




}
/// @nodoc
class _$TopFieldModelCopyWithImpl<$Res>
    implements $TopFieldModelCopyWith<$Res> {
  _$TopFieldModelCopyWithImpl(this._self, this._then);

  final TopFieldModel _self;
  final $Res Function(TopFieldModel) _then;

/// Create a copy of TopFieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? icon = null,Object? color = null,Object? articles = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopFieldModel].
extension TopFieldModelPatterns on TopFieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopFieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopFieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopFieldModel value)  $default,){
final _that = this;
switch (_that) {
case _TopFieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopFieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _TopFieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String icon,  String color,  int articles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.icon,_that.color,_that.articles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String icon,  String color,  int articles)  $default,) {final _that = this;
switch (_that) {
case _TopFieldModel():
return $default(_that.id,_that.slug,_that.name,_that.icon,_that.color,_that.articles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String icon,  String color,  int articles)?  $default,) {final _that = this;
switch (_that) {
case _TopFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.icon,_that.color,_that.articles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TopFieldModel extends TopFieldModel {
  const _TopFieldModel({required this.id, required this.slug, required this.name, this.icon = 'book-open', this.color = 'primary', this.articles = 0}): super._();
  factory _TopFieldModel.fromJson(Map<String, dynamic> json) => _$TopFieldModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String name;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey() final  int articles;

/// Create a copy of TopFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopFieldModelCopyWith<_TopFieldModel> get copyWith => __$TopFieldModelCopyWithImpl<_TopFieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopFieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.articles, articles) || other.articles == articles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,icon,color,articles);

@override
String toString() {
  return 'TopFieldModel(id: $id, slug: $slug, name: $name, icon: $icon, color: $color, articles: $articles)';
}


}

/// @nodoc
abstract mixin class _$TopFieldModelCopyWith<$Res> implements $TopFieldModelCopyWith<$Res> {
  factory _$TopFieldModelCopyWith(_TopFieldModel value, $Res Function(_TopFieldModel) _then) = __$TopFieldModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String icon, String color, int articles
});




}
/// @nodoc
class __$TopFieldModelCopyWithImpl<$Res>
    implements _$TopFieldModelCopyWith<$Res> {
  __$TopFieldModelCopyWithImpl(this._self, this._then);

  final _TopFieldModel _self;
  final $Res Function(_TopFieldModel) _then;

/// Create a copy of TopFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? icon = null,Object? color = null,Object? articles = null,}) {
  return _then(_TopFieldModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ReadingStatsModel {

 StreakModel get streak; int get totalArticles; int get minutesRead; int get articlesThisWeek; int get minutesThisWeek; int get articlesThisMonth; List<TopFieldModel> get topFields;
/// Create a copy of ReadingStatsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingStatsModelCopyWith<ReadingStatsModel> get copyWith => _$ReadingStatsModelCopyWithImpl<ReadingStatsModel>(this as ReadingStatsModel, _$identity);

  /// Serializes this ReadingStatsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatsModel&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.totalArticles, totalArticles) || other.totalArticles == totalArticles)&&(identical(other.minutesRead, minutesRead) || other.minutesRead == minutesRead)&&(identical(other.articlesThisWeek, articlesThisWeek) || other.articlesThisWeek == articlesThisWeek)&&(identical(other.minutesThisWeek, minutesThisWeek) || other.minutesThisWeek == minutesThisWeek)&&(identical(other.articlesThisMonth, articlesThisMonth) || other.articlesThisMonth == articlesThisMonth)&&const DeepCollectionEquality().equals(other.topFields, topFields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streak,totalArticles,minutesRead,articlesThisWeek,minutesThisWeek,articlesThisMonth,const DeepCollectionEquality().hash(topFields));

@override
String toString() {
  return 'ReadingStatsModel(streak: $streak, totalArticles: $totalArticles, minutesRead: $minutesRead, articlesThisWeek: $articlesThisWeek, minutesThisWeek: $minutesThisWeek, articlesThisMonth: $articlesThisMonth, topFields: $topFields)';
}


}

/// @nodoc
abstract mixin class $ReadingStatsModelCopyWith<$Res>  {
  factory $ReadingStatsModelCopyWith(ReadingStatsModel value, $Res Function(ReadingStatsModel) _then) = _$ReadingStatsModelCopyWithImpl;
@useResult
$Res call({
 StreakModel streak, int totalArticles, int minutesRead, int articlesThisWeek, int minutesThisWeek, int articlesThisMonth, List<TopFieldModel> topFields
});


$StreakModelCopyWith<$Res> get streak;

}
/// @nodoc
class _$ReadingStatsModelCopyWithImpl<$Res>
    implements $ReadingStatsModelCopyWith<$Res> {
  _$ReadingStatsModelCopyWithImpl(this._self, this._then);

  final ReadingStatsModel _self;
  final $Res Function(ReadingStatsModel) _then;

/// Create a copy of ReadingStatsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streak = null,Object? totalArticles = null,Object? minutesRead = null,Object? articlesThisWeek = null,Object? minutesThisWeek = null,Object? articlesThisMonth = null,Object? topFields = null,}) {
  return _then(_self.copyWith(
streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as StreakModel,totalArticles: null == totalArticles ? _self.totalArticles : totalArticles // ignore: cast_nullable_to_non_nullable
as int,minutesRead: null == minutesRead ? _self.minutesRead : minutesRead // ignore: cast_nullable_to_non_nullable
as int,articlesThisWeek: null == articlesThisWeek ? _self.articlesThisWeek : articlesThisWeek // ignore: cast_nullable_to_non_nullable
as int,minutesThisWeek: null == minutesThisWeek ? _self.minutesThisWeek : minutesThisWeek // ignore: cast_nullable_to_non_nullable
as int,articlesThisMonth: null == articlesThisMonth ? _self.articlesThisMonth : articlesThisMonth // ignore: cast_nullable_to_non_nullable
as int,topFields: null == topFields ? _self.topFields : topFields // ignore: cast_nullable_to_non_nullable
as List<TopFieldModel>,
  ));
}
/// Create a copy of ReadingStatsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakModelCopyWith<$Res> get streak {
  
  return $StreakModelCopyWith<$Res>(_self.streak, (value) {
    return _then(_self.copyWith(streak: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingStatsModel].
extension ReadingStatsModelPatterns on ReadingStatsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingStatsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingStatsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingStatsModel value)  $default,){
final _that = this;
switch (_that) {
case _ReadingStatsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingStatsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingStatsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StreakModel streak,  int totalArticles,  int minutesRead,  int articlesThisWeek,  int minutesThisWeek,  int articlesThisMonth,  List<TopFieldModel> topFields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingStatsModel() when $default != null:
return $default(_that.streak,_that.totalArticles,_that.minutesRead,_that.articlesThisWeek,_that.minutesThisWeek,_that.articlesThisMonth,_that.topFields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StreakModel streak,  int totalArticles,  int minutesRead,  int articlesThisWeek,  int minutesThisWeek,  int articlesThisMonth,  List<TopFieldModel> topFields)  $default,) {final _that = this;
switch (_that) {
case _ReadingStatsModel():
return $default(_that.streak,_that.totalArticles,_that.minutesRead,_that.articlesThisWeek,_that.minutesThisWeek,_that.articlesThisMonth,_that.topFields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StreakModel streak,  int totalArticles,  int minutesRead,  int articlesThisWeek,  int minutesThisWeek,  int articlesThisMonth,  List<TopFieldModel> topFields)?  $default,) {final _that = this;
switch (_that) {
case _ReadingStatsModel() when $default != null:
return $default(_that.streak,_that.totalArticles,_that.minutesRead,_that.articlesThisWeek,_that.minutesThisWeek,_that.articlesThisMonth,_that.topFields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingStatsModel extends ReadingStatsModel {
  const _ReadingStatsModel({required this.streak, this.totalArticles = 0, this.minutesRead = 0, this.articlesThisWeek = 0, this.minutesThisWeek = 0, this.articlesThisMonth = 0, final  List<TopFieldModel> topFields = const <TopFieldModel>[]}): _topFields = topFields,super._();
  factory _ReadingStatsModel.fromJson(Map<String, dynamic> json) => _$ReadingStatsModelFromJson(json);

@override final  StreakModel streak;
@override@JsonKey() final  int totalArticles;
@override@JsonKey() final  int minutesRead;
@override@JsonKey() final  int articlesThisWeek;
@override@JsonKey() final  int minutesThisWeek;
@override@JsonKey() final  int articlesThisMonth;
 final  List<TopFieldModel> _topFields;
@override@JsonKey() List<TopFieldModel> get topFields {
  if (_topFields is EqualUnmodifiableListView) return _topFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topFields);
}


/// Create a copy of ReadingStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingStatsModelCopyWith<_ReadingStatsModel> get copyWith => __$ReadingStatsModelCopyWithImpl<_ReadingStatsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingStatsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingStatsModel&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.totalArticles, totalArticles) || other.totalArticles == totalArticles)&&(identical(other.minutesRead, minutesRead) || other.minutesRead == minutesRead)&&(identical(other.articlesThisWeek, articlesThisWeek) || other.articlesThisWeek == articlesThisWeek)&&(identical(other.minutesThisWeek, minutesThisWeek) || other.minutesThisWeek == minutesThisWeek)&&(identical(other.articlesThisMonth, articlesThisMonth) || other.articlesThisMonth == articlesThisMonth)&&const DeepCollectionEquality().equals(other._topFields, _topFields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streak,totalArticles,minutesRead,articlesThisWeek,minutesThisWeek,articlesThisMonth,const DeepCollectionEquality().hash(_topFields));

@override
String toString() {
  return 'ReadingStatsModel(streak: $streak, totalArticles: $totalArticles, minutesRead: $minutesRead, articlesThisWeek: $articlesThisWeek, minutesThisWeek: $minutesThisWeek, articlesThisMonth: $articlesThisMonth, topFields: $topFields)';
}


}

/// @nodoc
abstract mixin class _$ReadingStatsModelCopyWith<$Res> implements $ReadingStatsModelCopyWith<$Res> {
  factory _$ReadingStatsModelCopyWith(_ReadingStatsModel value, $Res Function(_ReadingStatsModel) _then) = __$ReadingStatsModelCopyWithImpl;
@override @useResult
$Res call({
 StreakModel streak, int totalArticles, int minutesRead, int articlesThisWeek, int minutesThisWeek, int articlesThisMonth, List<TopFieldModel> topFields
});


@override $StreakModelCopyWith<$Res> get streak;

}
/// @nodoc
class __$ReadingStatsModelCopyWithImpl<$Res>
    implements _$ReadingStatsModelCopyWith<$Res> {
  __$ReadingStatsModelCopyWithImpl(this._self, this._then);

  final _ReadingStatsModel _self;
  final $Res Function(_ReadingStatsModel) _then;

/// Create a copy of ReadingStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streak = null,Object? totalArticles = null,Object? minutesRead = null,Object? articlesThisWeek = null,Object? minutesThisWeek = null,Object? articlesThisMonth = null,Object? topFields = null,}) {
  return _then(_ReadingStatsModel(
streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as StreakModel,totalArticles: null == totalArticles ? _self.totalArticles : totalArticles // ignore: cast_nullable_to_non_nullable
as int,minutesRead: null == minutesRead ? _self.minutesRead : minutesRead // ignore: cast_nullable_to_non_nullable
as int,articlesThisWeek: null == articlesThisWeek ? _self.articlesThisWeek : articlesThisWeek // ignore: cast_nullable_to_non_nullable
as int,minutesThisWeek: null == minutesThisWeek ? _self.minutesThisWeek : minutesThisWeek // ignore: cast_nullable_to_non_nullable
as int,articlesThisMonth: null == articlesThisMonth ? _self.articlesThisMonth : articlesThisMonth // ignore: cast_nullable_to_non_nullable
as int,topFields: null == topFields ? _self._topFields : topFields // ignore: cast_nullable_to_non_nullable
as List<TopFieldModel>,
  ));
}

/// Create a copy of ReadingStatsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakModelCopyWith<$Res> get streak {
  
  return $StreakModelCopyWith<$Res>(_self.streak, (value) {
    return _then(_self.copyWith(streak: value));
  });
}
}


/// @nodoc
mixin _$HeatmapDayModel {

 String get date; int get articles; int get minutes; bool get frozen;
/// Create a copy of HeatmapDayModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeatmapDayModelCopyWith<HeatmapDayModel> get copyWith => _$HeatmapDayModelCopyWithImpl<HeatmapDayModel>(this as HeatmapDayModel, _$identity);

  /// Serializes this HeatmapDayModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeatmapDayModel&&(identical(other.date, date) || other.date == date)&&(identical(other.articles, articles) || other.articles == articles)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.frozen, frozen) || other.frozen == frozen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,articles,minutes,frozen);

@override
String toString() {
  return 'HeatmapDayModel(date: $date, articles: $articles, minutes: $minutes, frozen: $frozen)';
}


}

/// @nodoc
abstract mixin class $HeatmapDayModelCopyWith<$Res>  {
  factory $HeatmapDayModelCopyWith(HeatmapDayModel value, $Res Function(HeatmapDayModel) _then) = _$HeatmapDayModelCopyWithImpl;
@useResult
$Res call({
 String date, int articles, int minutes, bool frozen
});




}
/// @nodoc
class _$HeatmapDayModelCopyWithImpl<$Res>
    implements $HeatmapDayModelCopyWith<$Res> {
  _$HeatmapDayModelCopyWithImpl(this._self, this._then);

  final HeatmapDayModel _self;
  final $Res Function(HeatmapDayModel) _then;

/// Create a copy of HeatmapDayModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? articles = null,Object? minutes = null,Object? frozen = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,frozen: null == frozen ? _self.frozen : frozen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HeatmapDayModel].
extension HeatmapDayModelPatterns on HeatmapDayModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeatmapDayModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeatmapDayModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeatmapDayModel value)  $default,){
final _that = this;
switch (_that) {
case _HeatmapDayModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeatmapDayModel value)?  $default,){
final _that = this;
switch (_that) {
case _HeatmapDayModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int articles,  int minutes,  bool frozen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeatmapDayModel() when $default != null:
return $default(_that.date,_that.articles,_that.minutes,_that.frozen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int articles,  int minutes,  bool frozen)  $default,) {final _that = this;
switch (_that) {
case _HeatmapDayModel():
return $default(_that.date,_that.articles,_that.minutes,_that.frozen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int articles,  int minutes,  bool frozen)?  $default,) {final _that = this;
switch (_that) {
case _HeatmapDayModel() when $default != null:
return $default(_that.date,_that.articles,_that.minutes,_that.frozen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HeatmapDayModel extends HeatmapDayModel {
  const _HeatmapDayModel({required this.date, this.articles = 0, this.minutes = 0, this.frozen = false}): super._();
  factory _HeatmapDayModel.fromJson(Map<String, dynamic> json) => _$HeatmapDayModelFromJson(json);

@override final  String date;
@override@JsonKey() final  int articles;
@override@JsonKey() final  int minutes;
@override@JsonKey() final  bool frozen;

/// Create a copy of HeatmapDayModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeatmapDayModelCopyWith<_HeatmapDayModel> get copyWith => __$HeatmapDayModelCopyWithImpl<_HeatmapDayModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeatmapDayModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeatmapDayModel&&(identical(other.date, date) || other.date == date)&&(identical(other.articles, articles) || other.articles == articles)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.frozen, frozen) || other.frozen == frozen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,articles,minutes,frozen);

@override
String toString() {
  return 'HeatmapDayModel(date: $date, articles: $articles, minutes: $minutes, frozen: $frozen)';
}


}

/// @nodoc
abstract mixin class _$HeatmapDayModelCopyWith<$Res> implements $HeatmapDayModelCopyWith<$Res> {
  factory _$HeatmapDayModelCopyWith(_HeatmapDayModel value, $Res Function(_HeatmapDayModel) _then) = __$HeatmapDayModelCopyWithImpl;
@override @useResult
$Res call({
 String date, int articles, int minutes, bool frozen
});




}
/// @nodoc
class __$HeatmapDayModelCopyWithImpl<$Res>
    implements _$HeatmapDayModelCopyWith<$Res> {
  __$HeatmapDayModelCopyWithImpl(this._self, this._then);

  final _HeatmapDayModel _self;
  final $Res Function(_HeatmapDayModel) _then;

/// Create a copy of HeatmapDayModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? articles = null,Object? minutes = null,Object? frozen = null,}) {
  return _then(_HeatmapDayModel(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,frozen: null == frozen ? _self.frozen : frozen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ReadingHeatmapModel {

 String get from; String get to; List<HeatmapDayModel> get days;
/// Create a copy of ReadingHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingHeatmapModelCopyWith<ReadingHeatmapModel> get copyWith => _$ReadingHeatmapModelCopyWithImpl<ReadingHeatmapModel>(this as ReadingHeatmapModel, _$identity);

  /// Serializes this ReadingHeatmapModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHeatmapModel&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&const DeepCollectionEquality().equals(other.days, days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,const DeepCollectionEquality().hash(days));

@override
String toString() {
  return 'ReadingHeatmapModel(from: $from, to: $to, days: $days)';
}


}

/// @nodoc
abstract mixin class $ReadingHeatmapModelCopyWith<$Res>  {
  factory $ReadingHeatmapModelCopyWith(ReadingHeatmapModel value, $Res Function(ReadingHeatmapModel) _then) = _$ReadingHeatmapModelCopyWithImpl;
@useResult
$Res call({
 String from, String to, List<HeatmapDayModel> days
});




}
/// @nodoc
class _$ReadingHeatmapModelCopyWithImpl<$Res>
    implements $ReadingHeatmapModelCopyWith<$Res> {
  _$ReadingHeatmapModelCopyWithImpl(this._self, this._then);

  final ReadingHeatmapModel _self;
  final $Res Function(ReadingHeatmapModel) _then;

/// Create a copy of ReadingHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? days = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<HeatmapDayModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingHeatmapModel].
extension ReadingHeatmapModelPatterns on ReadingHeatmapModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingHeatmapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingHeatmapModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingHeatmapModel value)  $default,){
final _that = this;
switch (_that) {
case _ReadingHeatmapModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingHeatmapModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingHeatmapModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String to,  List<HeatmapDayModel> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingHeatmapModel() when $default != null:
return $default(_that.from,_that.to,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String to,  List<HeatmapDayModel> days)  $default,) {final _that = this;
switch (_that) {
case _ReadingHeatmapModel():
return $default(_that.from,_that.to,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String to,  List<HeatmapDayModel> days)?  $default,) {final _that = this;
switch (_that) {
case _ReadingHeatmapModel() when $default != null:
return $default(_that.from,_that.to,_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingHeatmapModel extends ReadingHeatmapModel {
  const _ReadingHeatmapModel({required this.from, required this.to, final  List<HeatmapDayModel> days = const <HeatmapDayModel>[]}): _days = days,super._();
  factory _ReadingHeatmapModel.fromJson(Map<String, dynamic> json) => _$ReadingHeatmapModelFromJson(json);

@override final  String from;
@override final  String to;
 final  List<HeatmapDayModel> _days;
@override@JsonKey() List<HeatmapDayModel> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of ReadingHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingHeatmapModelCopyWith<_ReadingHeatmapModel> get copyWith => __$ReadingHeatmapModelCopyWithImpl<_ReadingHeatmapModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingHeatmapModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingHeatmapModel&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&const DeepCollectionEquality().equals(other._days, _days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,const DeepCollectionEquality().hash(_days));

@override
String toString() {
  return 'ReadingHeatmapModel(from: $from, to: $to, days: $days)';
}


}

/// @nodoc
abstract mixin class _$ReadingHeatmapModelCopyWith<$Res> implements $ReadingHeatmapModelCopyWith<$Res> {
  factory _$ReadingHeatmapModelCopyWith(_ReadingHeatmapModel value, $Res Function(_ReadingHeatmapModel) _then) = __$ReadingHeatmapModelCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, List<HeatmapDayModel> days
});




}
/// @nodoc
class __$ReadingHeatmapModelCopyWithImpl<$Res>
    implements _$ReadingHeatmapModelCopyWith<$Res> {
  __$ReadingHeatmapModelCopyWithImpl(this._self, this._then);

  final _ReadingHeatmapModel _self;
  final $Res Function(_ReadingHeatmapModel) _then;

/// Create a copy of ReadingHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? days = null,}) {
  return _then(_ReadingHeatmapModel(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<HeatmapDayModel>,
  ));
}


}

// dart format on
