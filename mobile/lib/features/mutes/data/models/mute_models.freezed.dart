// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mute_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserMuteStateModel {

 bool get isMuted; bool get isFollowing; int get followerCount; bool get followRemoved;
/// Create a copy of UserMuteStateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserMuteStateModelCopyWith<UserMuteStateModel> get copyWith => _$UserMuteStateModelCopyWithImpl<UserMuteStateModel>(this as UserMuteStateModel, _$identity);

  /// Serializes this UserMuteStateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserMuteStateModel&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount)&&(identical(other.followRemoved, followRemoved) || other.followRemoved == followRemoved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isMuted,isFollowing,followerCount,followRemoved);

@override
String toString() {
  return 'UserMuteStateModel(isMuted: $isMuted, isFollowing: $isFollowing, followerCount: $followerCount, followRemoved: $followRemoved)';
}


}

/// @nodoc
abstract mixin class $UserMuteStateModelCopyWith<$Res>  {
  factory $UserMuteStateModelCopyWith(UserMuteStateModel value, $Res Function(UserMuteStateModel) _then) = _$UserMuteStateModelCopyWithImpl;
@useResult
$Res call({
 bool isMuted, bool isFollowing, int followerCount, bool followRemoved
});




}
/// @nodoc
class _$UserMuteStateModelCopyWithImpl<$Res>
    implements $UserMuteStateModelCopyWith<$Res> {
  _$UserMuteStateModelCopyWithImpl(this._self, this._then);

  final UserMuteStateModel _self;
  final $Res Function(UserMuteStateModel) _then;

/// Create a copy of UserMuteStateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isMuted = null,Object? isFollowing = null,Object? followerCount = null,Object? followRemoved = null,}) {
  return _then(_self.copyWith(
isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,followRemoved: null == followRemoved ? _self.followRemoved : followRemoved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserMuteStateModel].
extension UserMuteStateModelPatterns on UserMuteStateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserMuteStateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserMuteStateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserMuteStateModel value)  $default,){
final _that = this;
switch (_that) {
case _UserMuteStateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserMuteStateModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserMuteStateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isMuted,  bool isFollowing,  int followerCount,  bool followRemoved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserMuteStateModel() when $default != null:
return $default(_that.isMuted,_that.isFollowing,_that.followerCount,_that.followRemoved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isMuted,  bool isFollowing,  int followerCount,  bool followRemoved)  $default,) {final _that = this;
switch (_that) {
case _UserMuteStateModel():
return $default(_that.isMuted,_that.isFollowing,_that.followerCount,_that.followRemoved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isMuted,  bool isFollowing,  int followerCount,  bool followRemoved)?  $default,) {final _that = this;
switch (_that) {
case _UserMuteStateModel() when $default != null:
return $default(_that.isMuted,_that.isFollowing,_that.followerCount,_that.followRemoved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserMuteStateModel extends UserMuteStateModel {
  const _UserMuteStateModel({required this.isMuted, this.isFollowing = false, this.followerCount = 0, this.followRemoved = false}): super._();
  factory _UserMuteStateModel.fromJson(Map<String, dynamic> json) => _$UserMuteStateModelFromJson(json);

@override final  bool isMuted;
@override@JsonKey() final  bool isFollowing;
@override@JsonKey() final  int followerCount;
@override@JsonKey() final  bool followRemoved;

/// Create a copy of UserMuteStateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserMuteStateModelCopyWith<_UserMuteStateModel> get copyWith => __$UserMuteStateModelCopyWithImpl<_UserMuteStateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserMuteStateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserMuteStateModel&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followerCount, followerCount) || other.followerCount == followerCount)&&(identical(other.followRemoved, followRemoved) || other.followRemoved == followRemoved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isMuted,isFollowing,followerCount,followRemoved);

@override
String toString() {
  return 'UserMuteStateModel(isMuted: $isMuted, isFollowing: $isFollowing, followerCount: $followerCount, followRemoved: $followRemoved)';
}


}

/// @nodoc
abstract mixin class _$UserMuteStateModelCopyWith<$Res> implements $UserMuteStateModelCopyWith<$Res> {
  factory _$UserMuteStateModelCopyWith(_UserMuteStateModel value, $Res Function(_UserMuteStateModel) _then) = __$UserMuteStateModelCopyWithImpl;
@override @useResult
$Res call({
 bool isMuted, bool isFollowing, int followerCount, bool followRemoved
});




}
/// @nodoc
class __$UserMuteStateModelCopyWithImpl<$Res>
    implements _$UserMuteStateModelCopyWith<$Res> {
  __$UserMuteStateModelCopyWithImpl(this._self, this._then);

  final _UserMuteStateModel _self;
  final $Res Function(_UserMuteStateModel) _then;

/// Create a copy of UserMuteStateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isMuted = null,Object? isFollowing = null,Object? followerCount = null,Object? followRemoved = null,}) {
  return _then(_UserMuteStateModel(
isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followerCount: null == followerCount ? _self.followerCount : followerCount // ignore: cast_nullable_to_non_nullable
as int,followRemoved: null == followRemoved ? _self.followRemoved : followRemoved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ContentMutesModel {

 List<String> get fieldIds; List<String> get topicIds;
/// Create a copy of ContentMutesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentMutesModelCopyWith<ContentMutesModel> get copyWith => _$ContentMutesModelCopyWithImpl<ContentMutesModel>(this as ContentMutesModel, _$identity);

  /// Serializes this ContentMutesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentMutesModel&&const DeepCollectionEquality().equals(other.fieldIds, fieldIds)&&const DeepCollectionEquality().equals(other.topicIds, topicIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fieldIds),const DeepCollectionEquality().hash(topicIds));

@override
String toString() {
  return 'ContentMutesModel(fieldIds: $fieldIds, topicIds: $topicIds)';
}


}

/// @nodoc
abstract mixin class $ContentMutesModelCopyWith<$Res>  {
  factory $ContentMutesModelCopyWith(ContentMutesModel value, $Res Function(ContentMutesModel) _then) = _$ContentMutesModelCopyWithImpl;
@useResult
$Res call({
 List<String> fieldIds, List<String> topicIds
});




}
/// @nodoc
class _$ContentMutesModelCopyWithImpl<$Res>
    implements $ContentMutesModelCopyWith<$Res> {
  _$ContentMutesModelCopyWithImpl(this._self, this._then);

  final ContentMutesModel _self;
  final $Res Function(ContentMutesModel) _then;

/// Create a copy of ContentMutesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fieldIds = null,Object? topicIds = null,}) {
  return _then(_self.copyWith(
fieldIds: null == fieldIds ? _self.fieldIds : fieldIds // ignore: cast_nullable_to_non_nullable
as List<String>,topicIds: null == topicIds ? _self.topicIds : topicIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentMutesModel].
extension ContentMutesModelPatterns on ContentMutesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentMutesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentMutesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentMutesModel value)  $default,){
final _that = this;
switch (_that) {
case _ContentMutesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentMutesModel value)?  $default,){
final _that = this;
switch (_that) {
case _ContentMutesModel() when $default != null:
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
case _ContentMutesModel() when $default != null:
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
case _ContentMutesModel():
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
case _ContentMutesModel() when $default != null:
return $default(_that.fieldIds,_that.topicIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContentMutesModel extends ContentMutesModel {
  const _ContentMutesModel({final  List<String> fieldIds = const <String>[], final  List<String> topicIds = const <String>[]}): _fieldIds = fieldIds,_topicIds = topicIds,super._();
  factory _ContentMutesModel.fromJson(Map<String, dynamic> json) => _$ContentMutesModelFromJson(json);

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


/// Create a copy of ContentMutesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentMutesModelCopyWith<_ContentMutesModel> get copyWith => __$ContentMutesModelCopyWithImpl<_ContentMutesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentMutesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentMutesModel&&const DeepCollectionEquality().equals(other._fieldIds, _fieldIds)&&const DeepCollectionEquality().equals(other._topicIds, _topicIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fieldIds),const DeepCollectionEquality().hash(_topicIds));

@override
String toString() {
  return 'ContentMutesModel(fieldIds: $fieldIds, topicIds: $topicIds)';
}


}

/// @nodoc
abstract mixin class _$ContentMutesModelCopyWith<$Res> implements $ContentMutesModelCopyWith<$Res> {
  factory _$ContentMutesModelCopyWith(_ContentMutesModel value, $Res Function(_ContentMutesModel) _then) = __$ContentMutesModelCopyWithImpl;
@override @useResult
$Res call({
 List<String> fieldIds, List<String> topicIds
});




}
/// @nodoc
class __$ContentMutesModelCopyWithImpl<$Res>
    implements _$ContentMutesModelCopyWith<$Res> {
  __$ContentMutesModelCopyWithImpl(this._self, this._then);

  final _ContentMutesModel _self;
  final $Res Function(_ContentMutesModel) _then;

/// Create a copy of ContentMutesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fieldIds = null,Object? topicIds = null,}) {
  return _then(_ContentMutesModel(
fieldIds: null == fieldIds ? _self._fieldIds : fieldIds // ignore: cast_nullable_to_non_nullable
as List<String>,topicIds: null == topicIds ? _self._topicIds : topicIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$MutedFieldModel {

 String get id; String get slug; String? get name; String get nameAr; String get nameEn; String get icon; String get color;
/// Create a copy of MutedFieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutedFieldModelCopyWith<MutedFieldModel> get copyWith => _$MutedFieldModelCopyWithImpl<MutedFieldModel>(this as MutedFieldModel, _$identity);

  /// Serializes this MutedFieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutedFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,icon,color);

@override
String toString() {
  return 'MutedFieldModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $MutedFieldModelCopyWith<$Res>  {
  factory $MutedFieldModelCopyWith(MutedFieldModel value, $Res Function(MutedFieldModel) _then) = _$MutedFieldModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String? name, String nameAr, String nameEn, String icon, String color
});




}
/// @nodoc
class _$MutedFieldModelCopyWithImpl<$Res>
    implements $MutedFieldModelCopyWith<$Res> {
  _$MutedFieldModelCopyWithImpl(this._self, this._then);

  final MutedFieldModel _self;
  final $Res Function(MutedFieldModel) _then;

/// Create a copy of MutedFieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = freezed,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MutedFieldModel].
extension MutedFieldModelPatterns on MutedFieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MutedFieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MutedFieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MutedFieldModel value)  $default,){
final _that = this;
switch (_that) {
case _MutedFieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MutedFieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _MutedFieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String? name,  String nameAr,  String nameEn,  String icon,  String color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MutedFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String? name,  String nameAr,  String nameEn,  String icon,  String color)  $default,) {final _that = this;
switch (_that) {
case _MutedFieldModel():
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String? name,  String nameAr,  String nameEn,  String icon,  String color)?  $default,) {final _that = this;
switch (_that) {
case _MutedFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.icon,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MutedFieldModel extends MutedFieldModel {
  const _MutedFieldModel({required this.id, required this.slug, this.name, required this.nameAr, required this.nameEn, this.icon = 'book-open', this.color = 'primary'}): super._();
  factory _MutedFieldModel.fromJson(Map<String, dynamic> json) => _$MutedFieldModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String? name;
@override final  String nameAr;
@override final  String nameEn;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;

/// Create a copy of MutedFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MutedFieldModelCopyWith<_MutedFieldModel> get copyWith => __$MutedFieldModelCopyWithImpl<_MutedFieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MutedFieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MutedFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,icon,color);

@override
String toString() {
  return 'MutedFieldModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class _$MutedFieldModelCopyWith<$Res> implements $MutedFieldModelCopyWith<$Res> {
  factory _$MutedFieldModelCopyWith(_MutedFieldModel value, $Res Function(_MutedFieldModel) _then) = __$MutedFieldModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String? name, String nameAr, String nameEn, String icon, String color
});




}
/// @nodoc
class __$MutedFieldModelCopyWithImpl<$Res>
    implements _$MutedFieldModelCopyWith<$Res> {
  __$MutedFieldModelCopyWithImpl(this._self, this._then);

  final _MutedFieldModel _self;
  final $Res Function(_MutedFieldModel) _then;

/// Create a copy of MutedFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = freezed,Object? nameAr = null,Object? nameEn = null,Object? icon = null,Object? color = null,}) {
  return _then(_MutedFieldModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MutedTopicModel {

 String get id; String get slug; String? get name; String get nameAr; String get nameEn; MutedFieldModel get field;
/// Create a copy of MutedTopicModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutedTopicModelCopyWith<MutedTopicModel> get copyWith => _$MutedTopicModelCopyWithImpl<MutedTopicModel>(this as MutedTopicModel, _$identity);

  /// Serializes this MutedTopicModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutedTopicModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.field, field) || other.field == field));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,field);

@override
String toString() {
  return 'MutedTopicModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, field: $field)';
}


}

/// @nodoc
abstract mixin class $MutedTopicModelCopyWith<$Res>  {
  factory $MutedTopicModelCopyWith(MutedTopicModel value, $Res Function(MutedTopicModel) _then) = _$MutedTopicModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String? name, String nameAr, String nameEn, MutedFieldModel field
});


$MutedFieldModelCopyWith<$Res> get field;

}
/// @nodoc
class _$MutedTopicModelCopyWithImpl<$Res>
    implements $MutedTopicModelCopyWith<$Res> {
  _$MutedTopicModelCopyWithImpl(this._self, this._then);

  final MutedTopicModel _self;
  final $Res Function(MutedTopicModel) _then;

/// Create a copy of MutedTopicModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = freezed,Object? nameAr = null,Object? nameEn = null,Object? field = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as MutedFieldModel,
  ));
}
/// Create a copy of MutedTopicModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MutedFieldModelCopyWith<$Res> get field {
  
  return $MutedFieldModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// Adds pattern-matching-related methods to [MutedTopicModel].
extension MutedTopicModelPatterns on MutedTopicModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MutedTopicModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MutedTopicModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MutedTopicModel value)  $default,){
final _that = this;
switch (_that) {
case _MutedTopicModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MutedTopicModel value)?  $default,){
final _that = this;
switch (_that) {
case _MutedTopicModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String? name,  String nameAr,  String nameEn,  MutedFieldModel field)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MutedTopicModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.field);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String? name,  String nameAr,  String nameEn,  MutedFieldModel field)  $default,) {final _that = this;
switch (_that) {
case _MutedTopicModel():
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.field);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String? name,  String nameAr,  String nameEn,  MutedFieldModel field)?  $default,) {final _that = this;
switch (_that) {
case _MutedTopicModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.nameAr,_that.nameEn,_that.field);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MutedTopicModel extends MutedTopicModel {
  const _MutedTopicModel({required this.id, required this.slug, this.name, required this.nameAr, required this.nameEn, required this.field}): super._();
  factory _MutedTopicModel.fromJson(Map<String, dynamic> json) => _$MutedTopicModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String? name;
@override final  String nameAr;
@override final  String nameEn;
@override final  MutedFieldModel field;

/// Create a copy of MutedTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MutedTopicModelCopyWith<_MutedTopicModel> get copyWith => __$MutedTopicModelCopyWithImpl<_MutedTopicModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MutedTopicModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MutedTopicModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.field, field) || other.field == field));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,nameAr,nameEn,field);

@override
String toString() {
  return 'MutedTopicModel(id: $id, slug: $slug, name: $name, nameAr: $nameAr, nameEn: $nameEn, field: $field)';
}


}

/// @nodoc
abstract mixin class _$MutedTopicModelCopyWith<$Res> implements $MutedTopicModelCopyWith<$Res> {
  factory _$MutedTopicModelCopyWith(_MutedTopicModel value, $Res Function(_MutedTopicModel) _then) = __$MutedTopicModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String? name, String nameAr, String nameEn, MutedFieldModel field
});


@override $MutedFieldModelCopyWith<$Res> get field;

}
/// @nodoc
class __$MutedTopicModelCopyWithImpl<$Res>
    implements _$MutedTopicModelCopyWith<$Res> {
  __$MutedTopicModelCopyWithImpl(this._self, this._then);

  final _MutedTopicModel _self;
  final $Res Function(_MutedTopicModel) _then;

/// Create a copy of MutedTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = freezed,Object? nameAr = null,Object? nameEn = null,Object? field = null,}) {
  return _then(_MutedTopicModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as MutedFieldModel,
  ));
}

/// Create a copy of MutedTopicModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MutedFieldModelCopyWith<$Res> get field {
  
  return $MutedFieldModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// @nodoc
mixin _$MutesModel {

 List<UserSummaryModel> get users; List<MutedFieldModel> get fields; List<MutedTopicModel> get topics;
/// Create a copy of MutesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutesModelCopyWith<MutesModel> get copyWith => _$MutesModelCopyWithImpl<MutesModel>(this as MutesModel, _$identity);

  /// Serializes this MutesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutesModel&&const DeepCollectionEquality().equals(other.users, users)&&const DeepCollectionEquality().equals(other.fields, fields)&&const DeepCollectionEquality().equals(other.topics, topics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(users),const DeepCollectionEquality().hash(fields),const DeepCollectionEquality().hash(topics));

@override
String toString() {
  return 'MutesModel(users: $users, fields: $fields, topics: $topics)';
}


}

/// @nodoc
abstract mixin class $MutesModelCopyWith<$Res>  {
  factory $MutesModelCopyWith(MutesModel value, $Res Function(MutesModel) _then) = _$MutesModelCopyWithImpl;
@useResult
$Res call({
 List<UserSummaryModel> users, List<MutedFieldModel> fields, List<MutedTopicModel> topics
});




}
/// @nodoc
class _$MutesModelCopyWithImpl<$Res>
    implements $MutesModelCopyWith<$Res> {
  _$MutesModelCopyWithImpl(this._self, this._then);

  final MutesModel _self;
  final $Res Function(MutesModel) _then;

/// Create a copy of MutesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? users = null,Object? fields = null,Object? topics = null,}) {
  return _then(_self.copyWith(
users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<UserSummaryModel>,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<MutedFieldModel>,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<MutedTopicModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [MutesModel].
extension MutesModelPatterns on MutesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MutesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MutesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MutesModel value)  $default,){
final _that = this;
switch (_that) {
case _MutesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MutesModel value)?  $default,){
final _that = this;
switch (_that) {
case _MutesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserSummaryModel> users,  List<MutedFieldModel> fields,  List<MutedTopicModel> topics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MutesModel() when $default != null:
return $default(_that.users,_that.fields,_that.topics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserSummaryModel> users,  List<MutedFieldModel> fields,  List<MutedTopicModel> topics)  $default,) {final _that = this;
switch (_that) {
case _MutesModel():
return $default(_that.users,_that.fields,_that.topics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserSummaryModel> users,  List<MutedFieldModel> fields,  List<MutedTopicModel> topics)?  $default,) {final _that = this;
switch (_that) {
case _MutesModel() when $default != null:
return $default(_that.users,_that.fields,_that.topics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MutesModel extends MutesModel {
  const _MutesModel({final  List<UserSummaryModel> users = const <UserSummaryModel>[], final  List<MutedFieldModel> fields = const <MutedFieldModel>[], final  List<MutedTopicModel> topics = const <MutedTopicModel>[]}): _users = users,_fields = fields,_topics = topics,super._();
  factory _MutesModel.fromJson(Map<String, dynamic> json) => _$MutesModelFromJson(json);

 final  List<UserSummaryModel> _users;
@override@JsonKey() List<UserSummaryModel> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}

 final  List<MutedFieldModel> _fields;
@override@JsonKey() List<MutedFieldModel> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  List<MutedTopicModel> _topics;
@override@JsonKey() List<MutedTopicModel> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}


/// Create a copy of MutesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MutesModelCopyWith<_MutesModel> get copyWith => __$MutesModelCopyWithImpl<_MutesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MutesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MutesModel&&const DeepCollectionEquality().equals(other._users, _users)&&const DeepCollectionEquality().equals(other._fields, _fields)&&const DeepCollectionEquality().equals(other._topics, _topics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_users),const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_topics));

@override
String toString() {
  return 'MutesModel(users: $users, fields: $fields, topics: $topics)';
}


}

/// @nodoc
abstract mixin class _$MutesModelCopyWith<$Res> implements $MutesModelCopyWith<$Res> {
  factory _$MutesModelCopyWith(_MutesModel value, $Res Function(_MutesModel) _then) = __$MutesModelCopyWithImpl;
@override @useResult
$Res call({
 List<UserSummaryModel> users, List<MutedFieldModel> fields, List<MutedTopicModel> topics
});




}
/// @nodoc
class __$MutesModelCopyWithImpl<$Res>
    implements _$MutesModelCopyWith<$Res> {
  __$MutesModelCopyWithImpl(this._self, this._then);

  final _MutesModel _self;
  final $Res Function(_MutesModel) _then;

/// Create a copy of MutesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? users = null,Object? fields = null,Object? topics = null,}) {
  return _then(_MutesModel(
users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<UserSummaryModel>,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<MutedFieldModel>,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<MutedTopicModel>,
  ));
}


}

// dart format on
