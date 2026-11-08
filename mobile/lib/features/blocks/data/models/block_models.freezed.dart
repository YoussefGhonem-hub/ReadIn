// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'block_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserBlockStateModel {

 String get userId; bool get isBlocked; bool get followRemoved;
/// Create a copy of UserBlockStateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserBlockStateModelCopyWith<UserBlockStateModel> get copyWith => _$UserBlockStateModelCopyWithImpl<UserBlockStateModel>(this as UserBlockStateModel, _$identity);

  /// Serializes this UserBlockStateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserBlockStateModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.followRemoved, followRemoved) || other.followRemoved == followRemoved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,isBlocked,followRemoved);

@override
String toString() {
  return 'UserBlockStateModel(userId: $userId, isBlocked: $isBlocked, followRemoved: $followRemoved)';
}


}

/// @nodoc
abstract mixin class $UserBlockStateModelCopyWith<$Res>  {
  factory $UserBlockStateModelCopyWith(UserBlockStateModel value, $Res Function(UserBlockStateModel) _then) = _$UserBlockStateModelCopyWithImpl;
@useResult
$Res call({
 String userId, bool isBlocked, bool followRemoved
});




}
/// @nodoc
class _$UserBlockStateModelCopyWithImpl<$Res>
    implements $UserBlockStateModelCopyWith<$Res> {
  _$UserBlockStateModelCopyWithImpl(this._self, this._then);

  final UserBlockStateModel _self;
  final $Res Function(UserBlockStateModel) _then;

/// Create a copy of UserBlockStateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? isBlocked = null,Object? followRemoved = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,followRemoved: null == followRemoved ? _self.followRemoved : followRemoved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserBlockStateModel].
extension UserBlockStateModelPatterns on UserBlockStateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserBlockStateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserBlockStateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserBlockStateModel value)  $default,){
final _that = this;
switch (_that) {
case _UserBlockStateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserBlockStateModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserBlockStateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  bool isBlocked,  bool followRemoved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserBlockStateModel() when $default != null:
return $default(_that.userId,_that.isBlocked,_that.followRemoved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  bool isBlocked,  bool followRemoved)  $default,) {final _that = this;
switch (_that) {
case _UserBlockStateModel():
return $default(_that.userId,_that.isBlocked,_that.followRemoved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  bool isBlocked,  bool followRemoved)?  $default,) {final _that = this;
switch (_that) {
case _UserBlockStateModel() when $default != null:
return $default(_that.userId,_that.isBlocked,_that.followRemoved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserBlockStateModel extends UserBlockStateModel {
  const _UserBlockStateModel({required this.userId, required this.isBlocked, this.followRemoved = false}): super._();
  factory _UserBlockStateModel.fromJson(Map<String, dynamic> json) => _$UserBlockStateModelFromJson(json);

@override final  String userId;
@override final  bool isBlocked;
@override@JsonKey() final  bool followRemoved;

/// Create a copy of UserBlockStateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserBlockStateModelCopyWith<_UserBlockStateModel> get copyWith => __$UserBlockStateModelCopyWithImpl<_UserBlockStateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserBlockStateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserBlockStateModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.followRemoved, followRemoved) || other.followRemoved == followRemoved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,isBlocked,followRemoved);

@override
String toString() {
  return 'UserBlockStateModel(userId: $userId, isBlocked: $isBlocked, followRemoved: $followRemoved)';
}


}

/// @nodoc
abstract mixin class _$UserBlockStateModelCopyWith<$Res> implements $UserBlockStateModelCopyWith<$Res> {
  factory _$UserBlockStateModelCopyWith(_UserBlockStateModel value, $Res Function(_UserBlockStateModel) _then) = __$UserBlockStateModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, bool isBlocked, bool followRemoved
});




}
/// @nodoc
class __$UserBlockStateModelCopyWithImpl<$Res>
    implements _$UserBlockStateModelCopyWith<$Res> {
  __$UserBlockStateModelCopyWithImpl(this._self, this._then);

  final _UserBlockStateModel _self;
  final $Res Function(_UserBlockStateModel) _then;

/// Create a copy of UserBlockStateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? isBlocked = null,Object? followRemoved = null,}) {
  return _then(_UserBlockStateModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,followRemoved: null == followRemoved ? _self.followRemoved : followRemoved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BlockedUserModel {

 UserSummaryModel get user; DateTime get blockedAt;
/// Create a copy of BlockedUserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockedUserModelCopyWith<BlockedUserModel> get copyWith => _$BlockedUserModelCopyWithImpl<BlockedUserModel>(this as BlockedUserModel, _$identity);

  /// Serializes this BlockedUserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockedUserModel&&(identical(other.user, user) || other.user == user)&&(identical(other.blockedAt, blockedAt) || other.blockedAt == blockedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,blockedAt);

@override
String toString() {
  return 'BlockedUserModel(user: $user, blockedAt: $blockedAt)';
}


}

/// @nodoc
abstract mixin class $BlockedUserModelCopyWith<$Res>  {
  factory $BlockedUserModelCopyWith(BlockedUserModel value, $Res Function(BlockedUserModel) _then) = _$BlockedUserModelCopyWithImpl;
@useResult
$Res call({
 UserSummaryModel user, DateTime blockedAt
});


$UserSummaryModelCopyWith<$Res> get user;

}
/// @nodoc
class _$BlockedUserModelCopyWithImpl<$Res>
    implements $BlockedUserModelCopyWith<$Res> {
  _$BlockedUserModelCopyWithImpl(this._self, this._then);

  final BlockedUserModel _self;
  final $Res Function(BlockedUserModel) _then;

/// Create a copy of BlockedUserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? blockedAt = null,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserSummaryModel,blockedAt: null == blockedAt ? _self.blockedAt : blockedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of BlockedUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res> get user {
  
  return $UserSummaryModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [BlockedUserModel].
extension BlockedUserModelPatterns on BlockedUserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockedUserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockedUserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockedUserModel value)  $default,){
final _that = this;
switch (_that) {
case _BlockedUserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockedUserModel value)?  $default,){
final _that = this;
switch (_that) {
case _BlockedUserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserSummaryModel user,  DateTime blockedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockedUserModel() when $default != null:
return $default(_that.user,_that.blockedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserSummaryModel user,  DateTime blockedAt)  $default,) {final _that = this;
switch (_that) {
case _BlockedUserModel():
return $default(_that.user,_that.blockedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserSummaryModel user,  DateTime blockedAt)?  $default,) {final _that = this;
switch (_that) {
case _BlockedUserModel() when $default != null:
return $default(_that.user,_that.blockedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockedUserModel extends BlockedUserModel {
  const _BlockedUserModel({required this.user, required this.blockedAt}): super._();
  factory _BlockedUserModel.fromJson(Map<String, dynamic> json) => _$BlockedUserModelFromJson(json);

@override final  UserSummaryModel user;
@override final  DateTime blockedAt;

/// Create a copy of BlockedUserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockedUserModelCopyWith<_BlockedUserModel> get copyWith => __$BlockedUserModelCopyWithImpl<_BlockedUserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockedUserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockedUserModel&&(identical(other.user, user) || other.user == user)&&(identical(other.blockedAt, blockedAt) || other.blockedAt == blockedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,blockedAt);

@override
String toString() {
  return 'BlockedUserModel(user: $user, blockedAt: $blockedAt)';
}


}

/// @nodoc
abstract mixin class _$BlockedUserModelCopyWith<$Res> implements $BlockedUserModelCopyWith<$Res> {
  factory _$BlockedUserModelCopyWith(_BlockedUserModel value, $Res Function(_BlockedUserModel) _then) = __$BlockedUserModelCopyWithImpl;
@override @useResult
$Res call({
 UserSummaryModel user, DateTime blockedAt
});


@override $UserSummaryModelCopyWith<$Res> get user;

}
/// @nodoc
class __$BlockedUserModelCopyWithImpl<$Res>
    implements _$BlockedUserModelCopyWith<$Res> {
  __$BlockedUserModelCopyWithImpl(this._self, this._then);

  final _BlockedUserModel _self;
  final $Res Function(_BlockedUserModel) _then;

/// Create a copy of BlockedUserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? blockedAt = null,}) {
  return _then(_BlockedUserModel(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserSummaryModel,blockedAt: null == blockedAt ? _self.blockedAt : blockedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of BlockedUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res> get user {
  
  return $UserSummaryModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$BlockedUsersModel {

 List<BlockedUserModel> get items;
/// Create a copy of BlockedUsersModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockedUsersModelCopyWith<BlockedUsersModel> get copyWith => _$BlockedUsersModelCopyWithImpl<BlockedUsersModel>(this as BlockedUsersModel, _$identity);

  /// Serializes this BlockedUsersModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockedUsersModel&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'BlockedUsersModel(items: $items)';
}


}

/// @nodoc
abstract mixin class $BlockedUsersModelCopyWith<$Res>  {
  factory $BlockedUsersModelCopyWith(BlockedUsersModel value, $Res Function(BlockedUsersModel) _then) = _$BlockedUsersModelCopyWithImpl;
@useResult
$Res call({
 List<BlockedUserModel> items
});




}
/// @nodoc
class _$BlockedUsersModelCopyWithImpl<$Res>
    implements $BlockedUsersModelCopyWith<$Res> {
  _$BlockedUsersModelCopyWithImpl(this._self, this._then);

  final BlockedUsersModel _self;
  final $Res Function(BlockedUsersModel) _then;

/// Create a copy of BlockedUsersModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BlockedUserModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockedUsersModel].
extension BlockedUsersModelPatterns on BlockedUsersModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockedUsersModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockedUsersModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockedUsersModel value)  $default,){
final _that = this;
switch (_that) {
case _BlockedUsersModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockedUsersModel value)?  $default,){
final _that = this;
switch (_that) {
case _BlockedUsersModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BlockedUserModel> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockedUsersModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BlockedUserModel> items)  $default,) {final _that = this;
switch (_that) {
case _BlockedUsersModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BlockedUserModel> items)?  $default,) {final _that = this;
switch (_that) {
case _BlockedUsersModel() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockedUsersModel implements BlockedUsersModel {
  const _BlockedUsersModel({final  List<BlockedUserModel> items = const <BlockedUserModel>[]}): _items = items;
  factory _BlockedUsersModel.fromJson(Map<String, dynamic> json) => _$BlockedUsersModelFromJson(json);

 final  List<BlockedUserModel> _items;
@override@JsonKey() List<BlockedUserModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BlockedUsersModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockedUsersModelCopyWith<_BlockedUsersModel> get copyWith => __$BlockedUsersModelCopyWithImpl<_BlockedUsersModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockedUsersModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockedUsersModel&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'BlockedUsersModel(items: $items)';
}


}

/// @nodoc
abstract mixin class _$BlockedUsersModelCopyWith<$Res> implements $BlockedUsersModelCopyWith<$Res> {
  factory _$BlockedUsersModelCopyWith(_BlockedUsersModel value, $Res Function(_BlockedUsersModel) _then) = __$BlockedUsersModelCopyWithImpl;
@override @useResult
$Res call({
 List<BlockedUserModel> items
});




}
/// @nodoc
class __$BlockedUsersModelCopyWithImpl<$Res>
    implements _$BlockedUsersModelCopyWith<$Res> {
  __$BlockedUsersModelCopyWithImpl(this._self, this._then);

  final _BlockedUsersModel _self;
  final $Res Function(_BlockedUsersModel) _then;

/// Create a copy of BlockedUsersModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_BlockedUsersModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BlockedUserModel>,
  ));
}


}

// dart format on
