// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'taxonomy_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FieldModel {

 String get id; String get slug; String get nameAr; String get nameEn; String? get name; String get icon; String get color; bool get isSensitive; int get topicCount;
/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldModelCopyWith<FieldModel> get copyWith => _$FieldModelCopyWithImpl<FieldModel>(this as FieldModel, _$identity);

  /// Serializes this FieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive)&&(identical(other.topicCount, topicCount) || other.topicCount == topicCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,nameAr,nameEn,name,icon,color,isSensitive,topicCount);

@override
String toString() {
  return 'FieldModel(id: $id, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name, icon: $icon, color: $color, isSensitive: $isSensitive, topicCount: $topicCount)';
}


}

/// @nodoc
abstract mixin class $FieldModelCopyWith<$Res>  {
  factory $FieldModelCopyWith(FieldModel value, $Res Function(FieldModel) _then) = _$FieldModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String nameAr, String nameEn, String? name, String icon, String color, bool isSensitive, int topicCount
});




}
/// @nodoc
class _$FieldModelCopyWithImpl<$Res>
    implements $FieldModelCopyWith<$Res> {
  _$FieldModelCopyWithImpl(this._self, this._then);

  final FieldModel _self;
  final $Res Function(FieldModel) _then;

/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,Object? icon = null,Object? color = null,Object? isSensitive = null,Object? topicCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,topicCount: null == topicCount ? _self.topicCount : topicCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldModel].
extension FieldModelPatterns on FieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String nameAr,  String nameEn,  String? name,  String icon,  String color,  bool isSensitive,  int topicCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name,_that.icon,_that.color,_that.isSensitive,_that.topicCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String nameAr,  String nameEn,  String? name,  String icon,  String color,  bool isSensitive,  int topicCount)  $default,) {final _that = this;
switch (_that) {
case _FieldModel():
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name,_that.icon,_that.color,_that.isSensitive,_that.topicCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String nameAr,  String nameEn,  String? name,  String icon,  String color,  bool isSensitive,  int topicCount)?  $default,) {final _that = this;
switch (_that) {
case _FieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name,_that.icon,_that.color,_that.isSensitive,_that.topicCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldModel extends FieldModel {
  const _FieldModel({required this.id, required this.slug, required this.nameAr, required this.nameEn, this.name, this.icon = 'book-open', this.color = 'primary', this.isSensitive = false, this.topicCount = 0}): super._();
  factory _FieldModel.fromJson(Map<String, dynamic> json) => _$FieldModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String nameAr;
@override final  String nameEn;
@override final  String? name;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey() final  bool isSensitive;
@override@JsonKey() final  int topicCount;

/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldModelCopyWith<_FieldModel> get copyWith => __$FieldModelCopyWithImpl<_FieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive)&&(identical(other.topicCount, topicCount) || other.topicCount == topicCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,nameAr,nameEn,name,icon,color,isSensitive,topicCount);

@override
String toString() {
  return 'FieldModel(id: $id, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name, icon: $icon, color: $color, isSensitive: $isSensitive, topicCount: $topicCount)';
}


}

/// @nodoc
abstract mixin class _$FieldModelCopyWith<$Res> implements $FieldModelCopyWith<$Res> {
  factory _$FieldModelCopyWith(_FieldModel value, $Res Function(_FieldModel) _then) = __$FieldModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String nameAr, String nameEn, String? name, String icon, String color, bool isSensitive, int topicCount
});




}
/// @nodoc
class __$FieldModelCopyWithImpl<$Res>
    implements _$FieldModelCopyWith<$Res> {
  __$FieldModelCopyWithImpl(this._self, this._then);

  final _FieldModel _self;
  final $Res Function(_FieldModel) _then;

/// Create a copy of FieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,Object? icon = null,Object? color = null,Object? isSensitive = null,Object? topicCount = null,}) {
  return _then(_FieldModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,topicCount: null == topicCount ? _self.topicCount : topicCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TopicModel {

 String get id; String get fieldId; String get slug; String get nameAr; String get nameEn; String? get name;
/// Create a copy of TopicModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicModelCopyWith<TopicModel> get copyWith => _$TopicModelCopyWithImpl<TopicModel>(this as TopicModel, _$identity);

  /// Serializes this TopicModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopicModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fieldId,slug,nameAr,nameEn,name);

@override
String toString() {
  return 'TopicModel(id: $id, fieldId: $fieldId, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name)';
}


}

/// @nodoc
abstract mixin class $TopicModelCopyWith<$Res>  {
  factory $TopicModelCopyWith(TopicModel value, $Res Function(TopicModel) _then) = _$TopicModelCopyWithImpl;
@useResult
$Res call({
 String id, String fieldId, String slug, String nameAr, String nameEn, String? name
});




}
/// @nodoc
class _$TopicModelCopyWithImpl<$Res>
    implements $TopicModelCopyWith<$Res> {
  _$TopicModelCopyWithImpl(this._self, this._then);

  final TopicModel _self;
  final $Res Function(TopicModel) _then;

/// Create a copy of TopicModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fieldId = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fieldId: null == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TopicModel].
extension TopicModelPatterns on TopicModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopicModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopicModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopicModel value)  $default,){
final _that = this;
switch (_that) {
case _TopicModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopicModel value)?  $default,){
final _that = this;
switch (_that) {
case _TopicModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fieldId,  String slug,  String nameAr,  String nameEn,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopicModel() when $default != null:
return $default(_that.id,_that.fieldId,_that.slug,_that.nameAr,_that.nameEn,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fieldId,  String slug,  String nameAr,  String nameEn,  String? name)  $default,) {final _that = this;
switch (_that) {
case _TopicModel():
return $default(_that.id,_that.fieldId,_that.slug,_that.nameAr,_that.nameEn,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fieldId,  String slug,  String nameAr,  String nameEn,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _TopicModel() when $default != null:
return $default(_that.id,_that.fieldId,_that.slug,_that.nameAr,_that.nameEn,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TopicModel extends TopicModel {
  const _TopicModel({required this.id, required this.fieldId, required this.slug, required this.nameAr, required this.nameEn, this.name}): super._();
  factory _TopicModel.fromJson(Map<String, dynamic> json) => _$TopicModelFromJson(json);

@override final  String id;
@override final  String fieldId;
@override final  String slug;
@override final  String nameAr;
@override final  String nameEn;
@override final  String? name;

/// Create a copy of TopicModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicModelCopyWith<_TopicModel> get copyWith => __$TopicModelCopyWithImpl<_TopicModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopicModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopicModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fieldId,slug,nameAr,nameEn,name);

@override
String toString() {
  return 'TopicModel(id: $id, fieldId: $fieldId, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name)';
}


}

/// @nodoc
abstract mixin class _$TopicModelCopyWith<$Res> implements $TopicModelCopyWith<$Res> {
  factory _$TopicModelCopyWith(_TopicModel value, $Res Function(_TopicModel) _then) = __$TopicModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String fieldId, String slug, String nameAr, String nameEn, String? name
});




}
/// @nodoc
class __$TopicModelCopyWithImpl<$Res>
    implements _$TopicModelCopyWith<$Res> {
  __$TopicModelCopyWithImpl(this._self, this._then);

  final _TopicModel _self;
  final $Res Function(_TopicModel) _then;

/// Create a copy of TopicModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fieldId = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,}) {
  return _then(_TopicModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fieldId: null == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
