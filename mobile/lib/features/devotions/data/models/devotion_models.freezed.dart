// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'devotion_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PersonalDuaModel {

 String get id; String? get title; String get text; int get repeat; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of PersonalDuaModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalDuaModelCopyWith<PersonalDuaModel> get copyWith => _$PersonalDuaModelCopyWithImpl<PersonalDuaModel>(this as PersonalDuaModel, _$identity);

  /// Serializes this PersonalDuaModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalDuaModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,text,repeat,createdAt,updatedAt);

@override
String toString() {
  return 'PersonalDuaModel(id: $id, title: $title, text: $text, repeat: $repeat, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PersonalDuaModelCopyWith<$Res>  {
  factory $PersonalDuaModelCopyWith(PersonalDuaModel value, $Res Function(PersonalDuaModel) _then) = _$PersonalDuaModelCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String text, int repeat, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$PersonalDuaModelCopyWithImpl<$Res>
    implements $PersonalDuaModelCopyWith<$Res> {
  _$PersonalDuaModelCopyWithImpl(this._self, this._then);

  final PersonalDuaModel _self;
  final $Res Function(PersonalDuaModel) _then;

/// Create a copy of PersonalDuaModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? text = null,Object? repeat = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalDuaModel].
extension PersonalDuaModelPatterns on PersonalDuaModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalDuaModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalDuaModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalDuaModel value)  $default,){
final _that = this;
switch (_that) {
case _PersonalDuaModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalDuaModel value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalDuaModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String text,  int repeat,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalDuaModel() when $default != null:
return $default(_that.id,_that.title,_that.text,_that.repeat,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String text,  int repeat,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PersonalDuaModel():
return $default(_that.id,_that.title,_that.text,_that.repeat,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String text,  int repeat,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PersonalDuaModel() when $default != null:
return $default(_that.id,_that.title,_that.text,_that.repeat,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalDuaModel extends PersonalDuaModel {
  const _PersonalDuaModel({required this.id, this.title, required this.text, this.repeat = 1, required this.createdAt, required this.updatedAt}): super._();
  factory _PersonalDuaModel.fromJson(Map<String, dynamic> json) => _$PersonalDuaModelFromJson(json);

@override final  String id;
@override final  String? title;
@override final  String text;
@override@JsonKey() final  int repeat;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of PersonalDuaModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalDuaModelCopyWith<_PersonalDuaModel> get copyWith => __$PersonalDuaModelCopyWithImpl<_PersonalDuaModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalDuaModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalDuaModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,text,repeat,createdAt,updatedAt);

@override
String toString() {
  return 'PersonalDuaModel(id: $id, title: $title, text: $text, repeat: $repeat, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PersonalDuaModelCopyWith<$Res> implements $PersonalDuaModelCopyWith<$Res> {
  factory _$PersonalDuaModelCopyWith(_PersonalDuaModel value, $Res Function(_PersonalDuaModel) _then) = __$PersonalDuaModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String text, int repeat, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$PersonalDuaModelCopyWithImpl<$Res>
    implements _$PersonalDuaModelCopyWith<$Res> {
  __$PersonalDuaModelCopyWithImpl(this._self, this._then);

  final _PersonalDuaModel _self;
  final $Res Function(_PersonalDuaModel) _then;

/// Create a copy of PersonalDuaModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? text = null,Object? repeat = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PersonalDuaModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
