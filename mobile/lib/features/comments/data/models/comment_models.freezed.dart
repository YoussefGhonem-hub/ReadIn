// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentBodyRequest {

 String get body;
/// Create a copy of CommentBodyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentBodyRequestCopyWith<CommentBodyRequest> get copyWith => _$CommentBodyRequestCopyWithImpl<CommentBodyRequest>(this as CommentBodyRequest, _$identity);

  /// Serializes this CommentBodyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentBodyRequest&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body);

@override
String toString() {
  return 'CommentBodyRequest(body: $body)';
}


}

/// @nodoc
abstract mixin class $CommentBodyRequestCopyWith<$Res>  {
  factory $CommentBodyRequestCopyWith(CommentBodyRequest value, $Res Function(CommentBodyRequest) _then) = _$CommentBodyRequestCopyWithImpl;
@useResult
$Res call({
 String body
});




}
/// @nodoc
class _$CommentBodyRequestCopyWithImpl<$Res>
    implements $CommentBodyRequestCopyWith<$Res> {
  _$CommentBodyRequestCopyWithImpl(this._self, this._then);

  final CommentBodyRequest _self;
  final $Res Function(CommentBodyRequest) _then;

/// Create a copy of CommentBodyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentBodyRequest].
extension CommentBodyRequestPatterns on CommentBodyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentBodyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentBodyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentBodyRequest value)  $default,){
final _that = this;
switch (_that) {
case _CommentBodyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentBodyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CommentBodyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentBodyRequest() when $default != null:
return $default(_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body)  $default,) {final _that = this;
switch (_that) {
case _CommentBodyRequest():
return $default(_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body)?  $default,) {final _that = this;
switch (_that) {
case _CommentBodyRequest() when $default != null:
return $default(_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentBodyRequest implements CommentBodyRequest {
  const _CommentBodyRequest({required this.body});
  factory _CommentBodyRequest.fromJson(Map<String, dynamic> json) => _$CommentBodyRequestFromJson(json);

@override final  String body;

/// Create a copy of CommentBodyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentBodyRequestCopyWith<_CommentBodyRequest> get copyWith => __$CommentBodyRequestCopyWithImpl<_CommentBodyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentBodyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentBodyRequest&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body);

@override
String toString() {
  return 'CommentBodyRequest(body: $body)';
}


}

/// @nodoc
abstract mixin class _$CommentBodyRequestCopyWith<$Res> implements $CommentBodyRequestCopyWith<$Res> {
  factory _$CommentBodyRequestCopyWith(_CommentBodyRequest value, $Res Function(_CommentBodyRequest) _then) = __$CommentBodyRequestCopyWithImpl;
@override @useResult
$Res call({
 String body
});




}
/// @nodoc
class __$CommentBodyRequestCopyWithImpl<$Res>
    implements _$CommentBodyRequestCopyWith<$Res> {
  __$CommentBodyRequestCopyWithImpl(this._self, this._then);

  final _CommentBodyRequest _self;
  final $Res Function(_CommentBodyRequest) _then;

/// Create a copy of CommentBodyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,}) {
  return _then(_CommentBodyRequest(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CommentMentionModel {

 String get userId; String get username;
/// Create a copy of CommentMentionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentMentionModelCopyWith<CommentMentionModel> get copyWith => _$CommentMentionModelCopyWithImpl<CommentMentionModel>(this as CommentMentionModel, _$identity);

  /// Serializes this CommentMentionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentMentionModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username);

@override
String toString() {
  return 'CommentMentionModel(userId: $userId, username: $username)';
}


}

/// @nodoc
abstract mixin class $CommentMentionModelCopyWith<$Res>  {
  factory $CommentMentionModelCopyWith(CommentMentionModel value, $Res Function(CommentMentionModel) _then) = _$CommentMentionModelCopyWithImpl;
@useResult
$Res call({
 String userId, String username
});




}
/// @nodoc
class _$CommentMentionModelCopyWithImpl<$Res>
    implements $CommentMentionModelCopyWith<$Res> {
  _$CommentMentionModelCopyWithImpl(this._self, this._then);

  final CommentMentionModel _self;
  final $Res Function(CommentMentionModel) _then;

/// Create a copy of CommentMentionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentMentionModel].
extension CommentMentionModelPatterns on CommentMentionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentMentionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentMentionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentMentionModel value)  $default,){
final _that = this;
switch (_that) {
case _CommentMentionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentMentionModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommentMentionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentMentionModel() when $default != null:
return $default(_that.userId,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String username)  $default,) {final _that = this;
switch (_that) {
case _CommentMentionModel():
return $default(_that.userId,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String username)?  $default,) {final _that = this;
switch (_that) {
case _CommentMentionModel() when $default != null:
return $default(_that.userId,_that.username);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentMentionModel extends CommentMentionModel {
  const _CommentMentionModel({required this.userId, required this.username}): super._();
  factory _CommentMentionModel.fromJson(Map<String, dynamic> json) => _$CommentMentionModelFromJson(json);

@override final  String userId;
@override final  String username;

/// Create a copy of CommentMentionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentMentionModelCopyWith<_CommentMentionModel> get copyWith => __$CommentMentionModelCopyWithImpl<_CommentMentionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentMentionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentMentionModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username);

@override
String toString() {
  return 'CommentMentionModel(userId: $userId, username: $username)';
}


}

/// @nodoc
abstract mixin class _$CommentMentionModelCopyWith<$Res> implements $CommentMentionModelCopyWith<$Res> {
  factory _$CommentMentionModelCopyWith(_CommentMentionModel value, $Res Function(_CommentMentionModel) _then) = __$CommentMentionModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String username
});




}
/// @nodoc
class __$CommentMentionModelCopyWithImpl<$Res>
    implements _$CommentMentionModelCopyWith<$Res> {
  __$CommentMentionModelCopyWithImpl(this._self, this._then);

  final _CommentMentionModel _self;
  final $Res Function(_CommentMentionModel) _then;

/// Create a copy of CommentMentionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = null,}) {
  return _then(_CommentMentionModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CommentModel {

 String get id; String get articleId; String? get parentId; String? get body; AuthorModel? get author; bool get isArticleAuthor; List<CommentMentionModel> get mentions; int get likeCount; bool get likedByMe; int get replyCount; bool get isPinned; DateTime get createdAt; DateTime? get editedAt; bool get isDeleted; bool get isHidden; bool get canEdit; bool get canDelete; bool get canPin; bool get canReport; bool get canModerate; List<CommentModel>? get replies;// F28: the viewer muted the author (collapsed to "تعليق من شخص كتمته").
 bool get isAuthorMuted;// F11: the viewer follows the author (the row's "متابعة"; seeds the follow store).
 bool get isFollowingAuthor;// F22 store additions: the viewer reported it (collapsed for them, with "Show").
 bool get reportedByMe;// F36: someone the viewer is blocked with, kept as a placeholder for others' replies (body and author null).
 bool get isUnavailable;
/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentModelCopyWith<CommentModel> get copyWith => _$CommentModelCopyWithImpl<CommentModel>(this as CommentModel, _$identity);

  /// Serializes this CommentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.isArticleAuthor, isArticleAuthor) || other.isArticleAuthor == isArticleAuthor)&&const DeepCollectionEquality().equals(other.mentions, mentions)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.likedByMe, likedByMe) || other.likedByMe == likedByMe)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.canPin, canPin) || other.canPin == canPin)&&(identical(other.canReport, canReport) || other.canReport == canReport)&&(identical(other.canModerate, canModerate) || other.canModerate == canModerate)&&const DeepCollectionEquality().equals(other.replies, replies)&&(identical(other.isAuthorMuted, isAuthorMuted) || other.isAuthorMuted == isAuthorMuted)&&(identical(other.isFollowingAuthor, isFollowingAuthor) || other.isFollowingAuthor == isFollowingAuthor)&&(identical(other.reportedByMe, reportedByMe) || other.reportedByMe == reportedByMe)&&(identical(other.isUnavailable, isUnavailable) || other.isUnavailable == isUnavailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,articleId,parentId,body,author,isArticleAuthor,const DeepCollectionEquality().hash(mentions),likeCount,likedByMe,replyCount,isPinned,createdAt,editedAt,isDeleted,isHidden,canEdit,canDelete,canPin,canReport,canModerate,const DeepCollectionEquality().hash(replies),isAuthorMuted,isFollowingAuthor,reportedByMe,isUnavailable]);

@override
String toString() {
  return 'CommentModel(id: $id, articleId: $articleId, parentId: $parentId, body: $body, author: $author, isArticleAuthor: $isArticleAuthor, mentions: $mentions, likeCount: $likeCount, likedByMe: $likedByMe, replyCount: $replyCount, isPinned: $isPinned, createdAt: $createdAt, editedAt: $editedAt, isDeleted: $isDeleted, isHidden: $isHidden, canEdit: $canEdit, canDelete: $canDelete, canPin: $canPin, canReport: $canReport, canModerate: $canModerate, replies: $replies, isAuthorMuted: $isAuthorMuted, isFollowingAuthor: $isFollowingAuthor, reportedByMe: $reportedByMe, isUnavailable: $isUnavailable)';
}


}

/// @nodoc
abstract mixin class $CommentModelCopyWith<$Res>  {
  factory $CommentModelCopyWith(CommentModel value, $Res Function(CommentModel) _then) = _$CommentModelCopyWithImpl;
@useResult
$Res call({
 String id, String articleId, String? parentId, String? body, AuthorModel? author, bool isArticleAuthor, List<CommentMentionModel> mentions, int likeCount, bool likedByMe, int replyCount, bool isPinned, DateTime createdAt, DateTime? editedAt, bool isDeleted, bool isHidden, bool canEdit, bool canDelete, bool canPin, bool canReport, bool canModerate, List<CommentModel>? replies, bool isAuthorMuted, bool isFollowingAuthor, bool reportedByMe, bool isUnavailable
});


$AuthorModelCopyWith<$Res>? get author;

}
/// @nodoc
class _$CommentModelCopyWithImpl<$Res>
    implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._self, this._then);

  final CommentModel _self;
  final $Res Function(CommentModel) _then;

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? articleId = null,Object? parentId = freezed,Object? body = freezed,Object? author = freezed,Object? isArticleAuthor = null,Object? mentions = null,Object? likeCount = null,Object? likedByMe = null,Object? replyCount = null,Object? isPinned = null,Object? createdAt = null,Object? editedAt = freezed,Object? isDeleted = null,Object? isHidden = null,Object? canEdit = null,Object? canDelete = null,Object? canPin = null,Object? canReport = null,Object? canModerate = null,Object? replies = freezed,Object? isAuthorMuted = null,Object? isFollowingAuthor = null,Object? reportedByMe = null,Object? isUnavailable = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,articleId: null == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,isArticleAuthor: null == isArticleAuthor ? _self.isArticleAuthor : isArticleAuthor // ignore: cast_nullable_to_non_nullable
as bool,mentions: null == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<CommentMentionModel>,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,likedByMe: null == likedByMe ? _self.likedByMe : likedByMe // ignore: cast_nullable_to_non_nullable
as bool,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,canPin: null == canPin ? _self.canPin : canPin // ignore: cast_nullable_to_non_nullable
as bool,canReport: null == canReport ? _self.canReport : canReport // ignore: cast_nullable_to_non_nullable
as bool,canModerate: null == canModerate ? _self.canModerate : canModerate // ignore: cast_nullable_to_non_nullable
as bool,replies: freezed == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentModel>?,isAuthorMuted: null == isAuthorMuted ? _self.isAuthorMuted : isAuthorMuted // ignore: cast_nullable_to_non_nullable
as bool,isFollowingAuthor: null == isFollowingAuthor ? _self.isFollowingAuthor : isFollowingAuthor // ignore: cast_nullable_to_non_nullable
as bool,reportedByMe: null == reportedByMe ? _self.reportedByMe : reportedByMe // ignore: cast_nullable_to_non_nullable
as bool,isUnavailable: null == isUnavailable ? _self.isUnavailable : isUnavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CommentModel
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


/// Adds pattern-matching-related methods to [CommentModel].
extension CommentModelPatterns on CommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentModel value)  $default,){
final _that = this;
switch (_that) {
case _CommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String articleId,  String? parentId,  String? body,  AuthorModel? author,  bool isArticleAuthor,  List<CommentMentionModel> mentions,  int likeCount,  bool likedByMe,  int replyCount,  bool isPinned,  DateTime createdAt,  DateTime? editedAt,  bool isDeleted,  bool isHidden,  bool canEdit,  bool canDelete,  bool canPin,  bool canReport,  bool canModerate,  List<CommentModel>? replies,  bool isAuthorMuted,  bool isFollowingAuthor,  bool reportedByMe,  bool isUnavailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
return $default(_that.id,_that.articleId,_that.parentId,_that.body,_that.author,_that.isArticleAuthor,_that.mentions,_that.likeCount,_that.likedByMe,_that.replyCount,_that.isPinned,_that.createdAt,_that.editedAt,_that.isDeleted,_that.isHidden,_that.canEdit,_that.canDelete,_that.canPin,_that.canReport,_that.canModerate,_that.replies,_that.isAuthorMuted,_that.isFollowingAuthor,_that.reportedByMe,_that.isUnavailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String articleId,  String? parentId,  String? body,  AuthorModel? author,  bool isArticleAuthor,  List<CommentMentionModel> mentions,  int likeCount,  bool likedByMe,  int replyCount,  bool isPinned,  DateTime createdAt,  DateTime? editedAt,  bool isDeleted,  bool isHidden,  bool canEdit,  bool canDelete,  bool canPin,  bool canReport,  bool canModerate,  List<CommentModel>? replies,  bool isAuthorMuted,  bool isFollowingAuthor,  bool reportedByMe,  bool isUnavailable)  $default,) {final _that = this;
switch (_that) {
case _CommentModel():
return $default(_that.id,_that.articleId,_that.parentId,_that.body,_that.author,_that.isArticleAuthor,_that.mentions,_that.likeCount,_that.likedByMe,_that.replyCount,_that.isPinned,_that.createdAt,_that.editedAt,_that.isDeleted,_that.isHidden,_that.canEdit,_that.canDelete,_that.canPin,_that.canReport,_that.canModerate,_that.replies,_that.isAuthorMuted,_that.isFollowingAuthor,_that.reportedByMe,_that.isUnavailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String articleId,  String? parentId,  String? body,  AuthorModel? author,  bool isArticleAuthor,  List<CommentMentionModel> mentions,  int likeCount,  bool likedByMe,  int replyCount,  bool isPinned,  DateTime createdAt,  DateTime? editedAt,  bool isDeleted,  bool isHidden,  bool canEdit,  bool canDelete,  bool canPin,  bool canReport,  bool canModerate,  List<CommentModel>? replies,  bool isAuthorMuted,  bool isFollowingAuthor,  bool reportedByMe,  bool isUnavailable)?  $default,) {final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
return $default(_that.id,_that.articleId,_that.parentId,_that.body,_that.author,_that.isArticleAuthor,_that.mentions,_that.likeCount,_that.likedByMe,_that.replyCount,_that.isPinned,_that.createdAt,_that.editedAt,_that.isDeleted,_that.isHidden,_that.canEdit,_that.canDelete,_that.canPin,_that.canReport,_that.canModerate,_that.replies,_that.isAuthorMuted,_that.isFollowingAuthor,_that.reportedByMe,_that.isUnavailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentModel extends CommentModel {
  const _CommentModel({required this.id, required this.articleId, this.parentId, this.body, this.author, this.isArticleAuthor = false, final  List<CommentMentionModel> mentions = const <CommentMentionModel>[], this.likeCount = 0, this.likedByMe = false, this.replyCount = 0, this.isPinned = false, required this.createdAt, this.editedAt, this.isDeleted = false, this.isHidden = false, this.canEdit = false, this.canDelete = false, this.canPin = false, this.canReport = false, this.canModerate = false, final  List<CommentModel>? replies, this.isAuthorMuted = false, this.isFollowingAuthor = false, this.reportedByMe = false, this.isUnavailable = false}): _mentions = mentions,_replies = replies,super._();
  factory _CommentModel.fromJson(Map<String, dynamic> json) => _$CommentModelFromJson(json);

@override final  String id;
@override final  String articleId;
@override final  String? parentId;
@override final  String? body;
@override final  AuthorModel? author;
@override@JsonKey() final  bool isArticleAuthor;
 final  List<CommentMentionModel> _mentions;
@override@JsonKey() List<CommentMentionModel> get mentions {
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentions);
}

@override@JsonKey() final  int likeCount;
@override@JsonKey() final  bool likedByMe;
@override@JsonKey() final  int replyCount;
@override@JsonKey() final  bool isPinned;
@override final  DateTime createdAt;
@override final  DateTime? editedAt;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  bool isHidden;
@override@JsonKey() final  bool canEdit;
@override@JsonKey() final  bool canDelete;
@override@JsonKey() final  bool canPin;
@override@JsonKey() final  bool canReport;
@override@JsonKey() final  bool canModerate;
 final  List<CommentModel>? _replies;
@override List<CommentModel>? get replies {
  final value = _replies;
  if (value == null) return null;
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// F28: the viewer muted the author (collapsed to "تعليق من شخص كتمته").
@override@JsonKey() final  bool isAuthorMuted;
// F11: the viewer follows the author (the row's "متابعة"; seeds the follow store).
@override@JsonKey() final  bool isFollowingAuthor;
// F22 store additions: the viewer reported it (collapsed for them, with "Show").
@override@JsonKey() final  bool reportedByMe;
// F36: someone the viewer is blocked with, kept as a placeholder for others' replies (body and author null).
@override@JsonKey() final  bool isUnavailable;

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentModelCopyWith<_CommentModel> get copyWith => __$CommentModelCopyWithImpl<_CommentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.isArticleAuthor, isArticleAuthor) || other.isArticleAuthor == isArticleAuthor)&&const DeepCollectionEquality().equals(other._mentions, _mentions)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.likedByMe, likedByMe) || other.likedByMe == likedByMe)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.canPin, canPin) || other.canPin == canPin)&&(identical(other.canReport, canReport) || other.canReport == canReport)&&(identical(other.canModerate, canModerate) || other.canModerate == canModerate)&&const DeepCollectionEquality().equals(other._replies, _replies)&&(identical(other.isAuthorMuted, isAuthorMuted) || other.isAuthorMuted == isAuthorMuted)&&(identical(other.isFollowingAuthor, isFollowingAuthor) || other.isFollowingAuthor == isFollowingAuthor)&&(identical(other.reportedByMe, reportedByMe) || other.reportedByMe == reportedByMe)&&(identical(other.isUnavailable, isUnavailable) || other.isUnavailable == isUnavailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,articleId,parentId,body,author,isArticleAuthor,const DeepCollectionEquality().hash(_mentions),likeCount,likedByMe,replyCount,isPinned,createdAt,editedAt,isDeleted,isHidden,canEdit,canDelete,canPin,canReport,canModerate,const DeepCollectionEquality().hash(_replies),isAuthorMuted,isFollowingAuthor,reportedByMe,isUnavailable]);

@override
String toString() {
  return 'CommentModel(id: $id, articleId: $articleId, parentId: $parentId, body: $body, author: $author, isArticleAuthor: $isArticleAuthor, mentions: $mentions, likeCount: $likeCount, likedByMe: $likedByMe, replyCount: $replyCount, isPinned: $isPinned, createdAt: $createdAt, editedAt: $editedAt, isDeleted: $isDeleted, isHidden: $isHidden, canEdit: $canEdit, canDelete: $canDelete, canPin: $canPin, canReport: $canReport, canModerate: $canModerate, replies: $replies, isAuthorMuted: $isAuthorMuted, isFollowingAuthor: $isFollowingAuthor, reportedByMe: $reportedByMe, isUnavailable: $isUnavailable)';
}


}

/// @nodoc
abstract mixin class _$CommentModelCopyWith<$Res> implements $CommentModelCopyWith<$Res> {
  factory _$CommentModelCopyWith(_CommentModel value, $Res Function(_CommentModel) _then) = __$CommentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String articleId, String? parentId, String? body, AuthorModel? author, bool isArticleAuthor, List<CommentMentionModel> mentions, int likeCount, bool likedByMe, int replyCount, bool isPinned, DateTime createdAt, DateTime? editedAt, bool isDeleted, bool isHidden, bool canEdit, bool canDelete, bool canPin, bool canReport, bool canModerate, List<CommentModel>? replies, bool isAuthorMuted, bool isFollowingAuthor, bool reportedByMe, bool isUnavailable
});


@override $AuthorModelCopyWith<$Res>? get author;

}
/// @nodoc
class __$CommentModelCopyWithImpl<$Res>
    implements _$CommentModelCopyWith<$Res> {
  __$CommentModelCopyWithImpl(this._self, this._then);

  final _CommentModel _self;
  final $Res Function(_CommentModel) _then;

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? articleId = null,Object? parentId = freezed,Object? body = freezed,Object? author = freezed,Object? isArticleAuthor = null,Object? mentions = null,Object? likeCount = null,Object? likedByMe = null,Object? replyCount = null,Object? isPinned = null,Object? createdAt = null,Object? editedAt = freezed,Object? isDeleted = null,Object? isHidden = null,Object? canEdit = null,Object? canDelete = null,Object? canPin = null,Object? canReport = null,Object? canModerate = null,Object? replies = freezed,Object? isAuthorMuted = null,Object? isFollowingAuthor = null,Object? reportedByMe = null,Object? isUnavailable = null,}) {
  return _then(_CommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,articleId: null == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,isArticleAuthor: null == isArticleAuthor ? _self.isArticleAuthor : isArticleAuthor // ignore: cast_nullable_to_non_nullable
as bool,mentions: null == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<CommentMentionModel>,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,likedByMe: null == likedByMe ? _self.likedByMe : likedByMe // ignore: cast_nullable_to_non_nullable
as bool,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,canPin: null == canPin ? _self.canPin : canPin // ignore: cast_nullable_to_non_nullable
as bool,canReport: null == canReport ? _self.canReport : canReport // ignore: cast_nullable_to_non_nullable
as bool,canModerate: null == canModerate ? _self.canModerate : canModerate // ignore: cast_nullable_to_non_nullable
as bool,replies: freezed == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentModel>?,isAuthorMuted: null == isAuthorMuted ? _self.isAuthorMuted : isAuthorMuted // ignore: cast_nullable_to_non_nullable
as bool,isFollowingAuthor: null == isFollowingAuthor ? _self.isFollowingAuthor : isFollowingAuthor // ignore: cast_nullable_to_non_nullable
as bool,reportedByMe: null == reportedByMe ? _self.reportedByMe : reportedByMe // ignore: cast_nullable_to_non_nullable
as bool,isUnavailable: null == isUnavailable ? _self.isUnavailable : isUnavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CommentModel
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
mixin _$CommentPageModel {

 List<CommentModel> get items; String? get nextCursor; int get total;
/// Create a copy of CommentPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentPageModelCopyWith<CommentPageModel> get copyWith => _$CommentPageModelCopyWithImpl<CommentPageModel>(this as CommentPageModel, _$identity);

  /// Serializes this CommentPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor,total);

@override
String toString() {
  return 'CommentPageModel(items: $items, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class $CommentPageModelCopyWith<$Res>  {
  factory $CommentPageModelCopyWith(CommentPageModel value, $Res Function(CommentPageModel) _then) = _$CommentPageModelCopyWithImpl;
@useResult
$Res call({
 List<CommentModel> items, String? nextCursor, int total
});




}
/// @nodoc
class _$CommentPageModelCopyWithImpl<$Res>
    implements $CommentPageModelCopyWith<$Res> {
  _$CommentPageModelCopyWithImpl(this._self, this._then);

  final CommentPageModel _self;
  final $Res Function(CommentPageModel) _then;

/// Create a copy of CommentPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CommentModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentPageModel].
extension CommentPageModelPatterns on CommentPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentPageModel value)  $default,){
final _that = this;
switch (_that) {
case _CommentPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommentPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CommentModel> items,  String? nextCursor,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentPageModel() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CommentModel> items,  String? nextCursor,  int total)  $default,) {final _that = this;
switch (_that) {
case _CommentPageModel():
return $default(_that.items,_that.nextCursor,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CommentModel> items,  String? nextCursor,  int total)?  $default,) {final _that = this;
switch (_that) {
case _CommentPageModel() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentPageModel extends CommentPageModel {
  const _CommentPageModel({final  List<CommentModel> items = const <CommentModel>[], this.nextCursor, this.total = 0}): _items = items,super._();
  factory _CommentPageModel.fromJson(Map<String, dynamic> json) => _$CommentPageModelFromJson(json);

 final  List<CommentModel> _items;
@override@JsonKey() List<CommentModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override@JsonKey() final  int total;

/// Create a copy of CommentPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentPageModelCopyWith<_CommentPageModel> get copyWith => __$CommentPageModelCopyWithImpl<_CommentPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total);

@override
String toString() {
  return 'CommentPageModel(items: $items, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class _$CommentPageModelCopyWith<$Res> implements $CommentPageModelCopyWith<$Res> {
  factory _$CommentPageModelCopyWith(_CommentPageModel value, $Res Function(_CommentPageModel) _then) = __$CommentPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<CommentModel> items, String? nextCursor, int total
});




}
/// @nodoc
class __$CommentPageModelCopyWithImpl<$Res>
    implements _$CommentPageModelCopyWith<$Res> {
  __$CommentPageModelCopyWithImpl(this._self, this._then);

  final _CommentPageModel _self;
  final $Res Function(_CommentPageModel) _then;

/// Create a copy of CommentPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_CommentPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CommentModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CommentRepliesPageModel {

 List<CommentModel> get items; String? get nextCursor;
/// Create a copy of CommentRepliesPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentRepliesPageModelCopyWith<CommentRepliesPageModel> get copyWith => _$CommentRepliesPageModelCopyWithImpl<CommentRepliesPageModel>(this as CommentRepliesPageModel, _$identity);

  /// Serializes this CommentRepliesPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentRepliesPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'CommentRepliesPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $CommentRepliesPageModelCopyWith<$Res>  {
  factory $CommentRepliesPageModelCopyWith(CommentRepliesPageModel value, $Res Function(CommentRepliesPageModel) _then) = _$CommentRepliesPageModelCopyWithImpl;
@useResult
$Res call({
 List<CommentModel> items, String? nextCursor
});




}
/// @nodoc
class _$CommentRepliesPageModelCopyWithImpl<$Res>
    implements $CommentRepliesPageModelCopyWith<$Res> {
  _$CommentRepliesPageModelCopyWithImpl(this._self, this._then);

  final CommentRepliesPageModel _self;
  final $Res Function(CommentRepliesPageModel) _then;

/// Create a copy of CommentRepliesPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CommentModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentRepliesPageModel].
extension CommentRepliesPageModelPatterns on CommentRepliesPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentRepliesPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentRepliesPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentRepliesPageModel value)  $default,){
final _that = this;
switch (_that) {
case _CommentRepliesPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentRepliesPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommentRepliesPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CommentModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentRepliesPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CommentModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _CommentRepliesPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CommentModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _CommentRepliesPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentRepliesPageModel implements CommentRepliesPageModel {
  const _CommentRepliesPageModel({final  List<CommentModel> items = const <CommentModel>[], this.nextCursor}): _items = items;
  factory _CommentRepliesPageModel.fromJson(Map<String, dynamic> json) => _$CommentRepliesPageModelFromJson(json);

 final  List<CommentModel> _items;
@override@JsonKey() List<CommentModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of CommentRepliesPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentRepliesPageModelCopyWith<_CommentRepliesPageModel> get copyWith => __$CommentRepliesPageModelCopyWithImpl<_CommentRepliesPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentRepliesPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentRepliesPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'CommentRepliesPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$CommentRepliesPageModelCopyWith<$Res> implements $CommentRepliesPageModelCopyWith<$Res> {
  factory _$CommentRepliesPageModelCopyWith(_CommentRepliesPageModel value, $Res Function(_CommentRepliesPageModel) _then) = __$CommentRepliesPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<CommentModel> items, String? nextCursor
});




}
/// @nodoc
class __$CommentRepliesPageModelCopyWithImpl<$Res>
    implements _$CommentRepliesPageModelCopyWith<$Res> {
  __$CommentRepliesPageModelCopyWithImpl(this._self, this._then);

  final _CommentRepliesPageModel _self;
  final $Res Function(_CommentRepliesPageModel) _then;

/// Create a copy of CommentRepliesPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_CommentRepliesPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CommentModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CommentLikeModel {

 int get likeCount; bool get liked;
/// Create a copy of CommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentLikeModelCopyWith<CommentLikeModel> get copyWith => _$CommentLikeModelCopyWithImpl<CommentLikeModel>(this as CommentLikeModel, _$identity);

  /// Serializes this CommentLikeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentLikeModel&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.liked, liked) || other.liked == liked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,likeCount,liked);

@override
String toString() {
  return 'CommentLikeModel(likeCount: $likeCount, liked: $liked)';
}


}

/// @nodoc
abstract mixin class $CommentLikeModelCopyWith<$Res>  {
  factory $CommentLikeModelCopyWith(CommentLikeModel value, $Res Function(CommentLikeModel) _then) = _$CommentLikeModelCopyWithImpl;
@useResult
$Res call({
 int likeCount, bool liked
});




}
/// @nodoc
class _$CommentLikeModelCopyWithImpl<$Res>
    implements $CommentLikeModelCopyWith<$Res> {
  _$CommentLikeModelCopyWithImpl(this._self, this._then);

  final CommentLikeModel _self;
  final $Res Function(CommentLikeModel) _then;

/// Create a copy of CommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? likeCount = null,Object? liked = null,}) {
  return _then(_self.copyWith(
likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentLikeModel].
extension CommentLikeModelPatterns on CommentLikeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentLikeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentLikeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentLikeModel value)  $default,){
final _that = this;
switch (_that) {
case _CommentLikeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentLikeModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommentLikeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int likeCount,  bool liked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentLikeModel() when $default != null:
return $default(_that.likeCount,_that.liked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int likeCount,  bool liked)  $default,) {final _that = this;
switch (_that) {
case _CommentLikeModel():
return $default(_that.likeCount,_that.liked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int likeCount,  bool liked)?  $default,) {final _that = this;
switch (_that) {
case _CommentLikeModel() when $default != null:
return $default(_that.likeCount,_that.liked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentLikeModel extends CommentLikeModel {
  const _CommentLikeModel({required this.likeCount, required this.liked}): super._();
  factory _CommentLikeModel.fromJson(Map<String, dynamic> json) => _$CommentLikeModelFromJson(json);

@override final  int likeCount;
@override final  bool liked;

/// Create a copy of CommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentLikeModelCopyWith<_CommentLikeModel> get copyWith => __$CommentLikeModelCopyWithImpl<_CommentLikeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentLikeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentLikeModel&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.liked, liked) || other.liked == liked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,likeCount,liked);

@override
String toString() {
  return 'CommentLikeModel(likeCount: $likeCount, liked: $liked)';
}


}

/// @nodoc
abstract mixin class _$CommentLikeModelCopyWith<$Res> implements $CommentLikeModelCopyWith<$Res> {
  factory _$CommentLikeModelCopyWith(_CommentLikeModel value, $Res Function(_CommentLikeModel) _then) = __$CommentLikeModelCopyWithImpl;
@override @useResult
$Res call({
 int likeCount, bool liked
});




}
/// @nodoc
class __$CommentLikeModelCopyWithImpl<$Res>
    implements _$CommentLikeModelCopyWith<$Res> {
  __$CommentLikeModelCopyWithImpl(this._self, this._then);

  final _CommentLikeModel _self;
  final $Res Function(_CommentLikeModel) _then;

/// Create a copy of CommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? likeCount = null,Object? liked = null,}) {
  return _then(_CommentLikeModel(
likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MentionCandidateModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified;
/// Create a copy of MentionCandidateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MentionCandidateModelCopyWith<MentionCandidateModel> get copyWith => _$MentionCandidateModelCopyWithImpl<MentionCandidateModel>(this as MentionCandidateModel, _$identity);

  /// Serializes this MentionCandidateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MentionCandidateModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified);

@override
String toString() {
  return 'MentionCandidateModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $MentionCandidateModelCopyWith<$Res>  {
  factory $MentionCandidateModelCopyWith(MentionCandidateModel value, $Res Function(MentionCandidateModel) _then) = _$MentionCandidateModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class _$MentionCandidateModelCopyWithImpl<$Res>
    implements $MentionCandidateModelCopyWith<$Res> {
  _$MentionCandidateModelCopyWithImpl(this._self, this._then);

  final MentionCandidateModel _self;
  final $Res Function(MentionCandidateModel) _then;

/// Create a copy of MentionCandidateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MentionCandidateModel].
extension MentionCandidateModelPatterns on MentionCandidateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MentionCandidateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MentionCandidateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MentionCandidateModel value)  $default,){
final _that = this;
switch (_that) {
case _MentionCandidateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MentionCandidateModel value)?  $default,){
final _that = this;
switch (_that) {
case _MentionCandidateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MentionCandidateModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified)  $default,) {final _that = this;
switch (_that) {
case _MentionCandidateModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified)?  $default,) {final _that = this;
switch (_that) {
case _MentionCandidateModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MentionCandidateModel extends MentionCandidateModel {
  const _MentionCandidateModel({required this.id, required this.displayName, required this.username, this.avatarUrl, this.isVerified = false}): super._();
  factory _MentionCandidateModel.fromJson(Map<String, dynamic> json) => _$MentionCandidateModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;

/// Create a copy of MentionCandidateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MentionCandidateModelCopyWith<_MentionCandidateModel> get copyWith => __$MentionCandidateModelCopyWithImpl<_MentionCandidateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MentionCandidateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MentionCandidateModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified);

@override
String toString() {
  return 'MentionCandidateModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$MentionCandidateModelCopyWith<$Res> implements $MentionCandidateModelCopyWith<$Res> {
  factory _$MentionCandidateModelCopyWith(_MentionCandidateModel value, $Res Function(_MentionCandidateModel) _then) = __$MentionCandidateModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class __$MentionCandidateModelCopyWithImpl<$Res>
    implements _$MentionCandidateModelCopyWith<$Res> {
  __$MentionCandidateModelCopyWithImpl(this._self, this._then);

  final _MentionCandidateModel _self;
  final $Res Function(_MentionCandidateModel) _then;

/// Create a copy of MentionCandidateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_MentionCandidateModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
