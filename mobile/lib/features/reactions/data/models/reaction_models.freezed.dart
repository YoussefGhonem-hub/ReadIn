// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reaction_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SetReactionRequest {

 String get type;
/// Create a copy of SetReactionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetReactionRequestCopyWith<SetReactionRequest> get copyWith => _$SetReactionRequestCopyWithImpl<SetReactionRequest>(this as SetReactionRequest, _$identity);

  /// Serializes this SetReactionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetReactionRequest&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'SetReactionRequest(type: $type)';
}


}

/// @nodoc
abstract mixin class $SetReactionRequestCopyWith<$Res>  {
  factory $SetReactionRequestCopyWith(SetReactionRequest value, $Res Function(SetReactionRequest) _then) = _$SetReactionRequestCopyWithImpl;
@useResult
$Res call({
 String type
});




}
/// @nodoc
class _$SetReactionRequestCopyWithImpl<$Res>
    implements $SetReactionRequestCopyWith<$Res> {
  _$SetReactionRequestCopyWithImpl(this._self, this._then);

  final SetReactionRequest _self;
  final $Res Function(SetReactionRequest) _then;

/// Create a copy of SetReactionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SetReactionRequest].
extension SetReactionRequestPatterns on SetReactionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetReactionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetReactionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetReactionRequest value)  $default,){
final _that = this;
switch (_that) {
case _SetReactionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetReactionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SetReactionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetReactionRequest() when $default != null:
return $default(_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type)  $default,) {final _that = this;
switch (_that) {
case _SetReactionRequest():
return $default(_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type)?  $default,) {final _that = this;
switch (_that) {
case _SetReactionRequest() when $default != null:
return $default(_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetReactionRequest implements SetReactionRequest {
  const _SetReactionRequest({required this.type});
  factory _SetReactionRequest.fromJson(Map<String, dynamic> json) => _$SetReactionRequestFromJson(json);

@override final  String type;

/// Create a copy of SetReactionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetReactionRequestCopyWith<_SetReactionRequest> get copyWith => __$SetReactionRequestCopyWithImpl<_SetReactionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetReactionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetReactionRequest&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'SetReactionRequest(type: $type)';
}


}

/// @nodoc
abstract mixin class _$SetReactionRequestCopyWith<$Res> implements $SetReactionRequestCopyWith<$Res> {
  factory _$SetReactionRequestCopyWith(_SetReactionRequest value, $Res Function(_SetReactionRequest) _then) = __$SetReactionRequestCopyWithImpl;
@override @useResult
$Res call({
 String type
});




}
/// @nodoc
class __$SetReactionRequestCopyWithImpl<$Res>
    implements _$SetReactionRequestCopyWith<$Res> {
  __$SetReactionRequestCopyWithImpl(this._self, this._then);

  final _SetReactionRequest _self;
  final $Res Function(_SetReactionRequest) _then;

/// Create a copy of SetReactionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_SetReactionRequest(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ArticleReactionsModel {

 ReactionCountsModel get reactions; int? get total; String? get myReaction;
/// Create a copy of ArticleReactionsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleReactionsModelCopyWith<ArticleReactionsModel> get copyWith => _$ArticleReactionsModelCopyWithImpl<ArticleReactionsModel>(this as ArticleReactionsModel, _$identity);

  /// Serializes this ArticleReactionsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleReactionsModel&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.total, total) || other.total == total)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reactions,total,myReaction);

@override
String toString() {
  return 'ArticleReactionsModel(reactions: $reactions, total: $total, myReaction: $myReaction)';
}


}

/// @nodoc
abstract mixin class $ArticleReactionsModelCopyWith<$Res>  {
  factory $ArticleReactionsModelCopyWith(ArticleReactionsModel value, $Res Function(ArticleReactionsModel) _then) = _$ArticleReactionsModelCopyWithImpl;
@useResult
$Res call({
 ReactionCountsModel reactions, int? total, String? myReaction
});


$ReactionCountsModelCopyWith<$Res> get reactions;

}
/// @nodoc
class _$ArticleReactionsModelCopyWithImpl<$Res>
    implements $ArticleReactionsModelCopyWith<$Res> {
  _$ArticleReactionsModelCopyWithImpl(this._self, this._then);

  final ArticleReactionsModel _self;
  final $Res Function(ArticleReactionsModel) _then;

/// Create a copy of ArticleReactionsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reactions = null,Object? total = freezed,Object? myReaction = freezed,}) {
  return _then(_self.copyWith(
reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as ReactionCountsModel,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ArticleReactionsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<$Res> get reactions {
  
  return $ReactionCountsModelCopyWith<$Res>(_self.reactions, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleReactionsModel].
extension ArticleReactionsModelPatterns on ArticleReactionsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleReactionsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleReactionsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleReactionsModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleReactionsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleReactionsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleReactionsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReactionCountsModel reactions,  int? total,  String? myReaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleReactionsModel() when $default != null:
return $default(_that.reactions,_that.total,_that.myReaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReactionCountsModel reactions,  int? total,  String? myReaction)  $default,) {final _that = this;
switch (_that) {
case _ArticleReactionsModel():
return $default(_that.reactions,_that.total,_that.myReaction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReactionCountsModel reactions,  int? total,  String? myReaction)?  $default,) {final _that = this;
switch (_that) {
case _ArticleReactionsModel() when $default != null:
return $default(_that.reactions,_that.total,_that.myReaction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleReactionsModel extends ArticleReactionsModel {
  const _ArticleReactionsModel({this.reactions = const ReactionCountsModel(), this.total, this.myReaction}): super._();
  factory _ArticleReactionsModel.fromJson(Map<String, dynamic> json) => _$ArticleReactionsModelFromJson(json);

@override@JsonKey() final  ReactionCountsModel reactions;
@override final  int? total;
@override final  String? myReaction;

/// Create a copy of ArticleReactionsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleReactionsModelCopyWith<_ArticleReactionsModel> get copyWith => __$ArticleReactionsModelCopyWithImpl<_ArticleReactionsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleReactionsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleReactionsModel&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.total, total) || other.total == total)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reactions,total,myReaction);

@override
String toString() {
  return 'ArticleReactionsModel(reactions: $reactions, total: $total, myReaction: $myReaction)';
}


}

/// @nodoc
abstract mixin class _$ArticleReactionsModelCopyWith<$Res> implements $ArticleReactionsModelCopyWith<$Res> {
  factory _$ArticleReactionsModelCopyWith(_ArticleReactionsModel value, $Res Function(_ArticleReactionsModel) _then) = __$ArticleReactionsModelCopyWithImpl;
@override @useResult
$Res call({
 ReactionCountsModel reactions, int? total, String? myReaction
});


@override $ReactionCountsModelCopyWith<$Res> get reactions;

}
/// @nodoc
class __$ArticleReactionsModelCopyWithImpl<$Res>
    implements _$ArticleReactionsModelCopyWith<$Res> {
  __$ArticleReactionsModelCopyWithImpl(this._self, this._then);

  final _ArticleReactionsModel _self;
  final $Res Function(_ArticleReactionsModel) _then;

/// Create a copy of ArticleReactionsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reactions = null,Object? total = freezed,Object? myReaction = freezed,}) {
  return _then(_ArticleReactionsModel(
reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as ReactionCountsModel,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ArticleReactionsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReactionCountsModelCopyWith<$Res> get reactions {
  
  return $ReactionCountsModelCopyWith<$Res>(_self.reactions, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}
}


/// @nodoc
mixin _$ReactorModel {

 AuthorModel get user; String get type; DateTime get reactedAt;
/// Create a copy of ReactorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactorModelCopyWith<ReactorModel> get copyWith => _$ReactorModelCopyWithImpl<ReactorModel>(this as ReactorModel, _$identity);

  /// Serializes this ReactorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactorModel&&(identical(other.user, user) || other.user == user)&&(identical(other.type, type) || other.type == type)&&(identical(other.reactedAt, reactedAt) || other.reactedAt == reactedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,type,reactedAt);

@override
String toString() {
  return 'ReactorModel(user: $user, type: $type, reactedAt: $reactedAt)';
}


}

/// @nodoc
abstract mixin class $ReactorModelCopyWith<$Res>  {
  factory $ReactorModelCopyWith(ReactorModel value, $Res Function(ReactorModel) _then) = _$ReactorModelCopyWithImpl;
@useResult
$Res call({
 AuthorModel user, String type, DateTime reactedAt
});


$AuthorModelCopyWith<$Res> get user;

}
/// @nodoc
class _$ReactorModelCopyWithImpl<$Res>
    implements $ReactorModelCopyWith<$Res> {
  _$ReactorModelCopyWithImpl(this._self, this._then);

  final ReactorModel _self;
  final $Res Function(ReactorModel) _then;

/// Create a copy of ReactorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? type = null,Object? reactedAt = null,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthorModel,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,reactedAt: null == reactedAt ? _self.reactedAt : reactedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ReactorModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get user {
  
  return $AuthorModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReactorModel].
extension ReactorModelPatterns on ReactorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReactorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReactorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReactorModel value)  $default,){
final _that = this;
switch (_that) {
case _ReactorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReactorModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReactorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthorModel user,  String type,  DateTime reactedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReactorModel() when $default != null:
return $default(_that.user,_that.type,_that.reactedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthorModel user,  String type,  DateTime reactedAt)  $default,) {final _that = this;
switch (_that) {
case _ReactorModel():
return $default(_that.user,_that.type,_that.reactedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthorModel user,  String type,  DateTime reactedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReactorModel() when $default != null:
return $default(_that.user,_that.type,_that.reactedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReactorModel extends ReactorModel {
  const _ReactorModel({required this.user, required this.type, required this.reactedAt}): super._();
  factory _ReactorModel.fromJson(Map<String, dynamic> json) => _$ReactorModelFromJson(json);

@override final  AuthorModel user;
@override final  String type;
@override final  DateTime reactedAt;

/// Create a copy of ReactorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReactorModelCopyWith<_ReactorModel> get copyWith => __$ReactorModelCopyWithImpl<_ReactorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReactorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReactorModel&&(identical(other.user, user) || other.user == user)&&(identical(other.type, type) || other.type == type)&&(identical(other.reactedAt, reactedAt) || other.reactedAt == reactedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,type,reactedAt);

@override
String toString() {
  return 'ReactorModel(user: $user, type: $type, reactedAt: $reactedAt)';
}


}

/// @nodoc
abstract mixin class _$ReactorModelCopyWith<$Res> implements $ReactorModelCopyWith<$Res> {
  factory _$ReactorModelCopyWith(_ReactorModel value, $Res Function(_ReactorModel) _then) = __$ReactorModelCopyWithImpl;
@override @useResult
$Res call({
 AuthorModel user, String type, DateTime reactedAt
});


@override $AuthorModelCopyWith<$Res> get user;

}
/// @nodoc
class __$ReactorModelCopyWithImpl<$Res>
    implements _$ReactorModelCopyWith<$Res> {
  __$ReactorModelCopyWithImpl(this._self, this._then);

  final _ReactorModel _self;
  final $Res Function(_ReactorModel) _then;

/// Create a copy of ReactorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? type = null,Object? reactedAt = null,}) {
  return _then(_ReactorModel(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthorModel,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,reactedAt: null == reactedAt ? _self.reactedAt : reactedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ReactorModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get user {
  
  return $AuthorModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$ReactorPageModel {

 List<ReactorModel> get items; String? get nextCursor;
/// Create a copy of ReactorPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactorPageModelCopyWith<ReactorPageModel> get copyWith => _$ReactorPageModelCopyWithImpl<ReactorPageModel>(this as ReactorPageModel, _$identity);

  /// Serializes this ReactorPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactorPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'ReactorPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $ReactorPageModelCopyWith<$Res>  {
  factory $ReactorPageModelCopyWith(ReactorPageModel value, $Res Function(ReactorPageModel) _then) = _$ReactorPageModelCopyWithImpl;
@useResult
$Res call({
 List<ReactorModel> items, String? nextCursor
});




}
/// @nodoc
class _$ReactorPageModelCopyWithImpl<$Res>
    implements $ReactorPageModelCopyWith<$Res> {
  _$ReactorPageModelCopyWithImpl(this._self, this._then);

  final ReactorPageModel _self;
  final $Res Function(ReactorPageModel) _then;

/// Create a copy of ReactorPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReactorModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReactorPageModel].
extension ReactorPageModelPatterns on ReactorPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReactorPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReactorPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReactorPageModel value)  $default,){
final _that = this;
switch (_that) {
case _ReactorPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReactorPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReactorPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ReactorModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReactorPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ReactorModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ReactorPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ReactorModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ReactorPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReactorPageModel implements ReactorPageModel {
  const _ReactorPageModel({final  List<ReactorModel> items = const <ReactorModel>[], this.nextCursor}): _items = items;
  factory _ReactorPageModel.fromJson(Map<String, dynamic> json) => _$ReactorPageModelFromJson(json);

 final  List<ReactorModel> _items;
@override@JsonKey() List<ReactorModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of ReactorPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReactorPageModelCopyWith<_ReactorPageModel> get copyWith => __$ReactorPageModelCopyWithImpl<_ReactorPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReactorPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReactorPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'ReactorPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ReactorPageModelCopyWith<$Res> implements $ReactorPageModelCopyWith<$Res> {
  factory _$ReactorPageModelCopyWith(_ReactorPageModel value, $Res Function(_ReactorPageModel) _then) = __$ReactorPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<ReactorModel> items, String? nextCursor
});




}
/// @nodoc
class __$ReactorPageModelCopyWithImpl<$Res>
    implements _$ReactorPageModelCopyWith<$Res> {
  __$ReactorPageModelCopyWithImpl(this._self, this._then);

  final _ReactorPageModel _self;
  final $Res Function(_ReactorPageModel) _then;

/// Create a copy of ReactorPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_ReactorPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReactorModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
