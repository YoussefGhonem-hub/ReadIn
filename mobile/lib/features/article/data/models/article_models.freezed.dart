// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthorModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified;
/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<AuthorModel> get copyWith => _$AuthorModelCopyWithImpl<AuthorModel>(this as AuthorModel, _$identity);

  /// Serializes this AuthorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified);

@override
String toString() {
  return 'AuthorModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $AuthorModelCopyWith<$Res>  {
  factory $AuthorModelCopyWith(AuthorModel value, $Res Function(AuthorModel) _then) = _$AuthorModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class _$AuthorModelCopyWithImpl<$Res>
    implements $AuthorModelCopyWith<$Res> {
  _$AuthorModelCopyWithImpl(this._self, this._then);

  final AuthorModel _self;
  final $Res Function(AuthorModel) _then;

/// Create a copy of AuthorModel
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


/// Adds pattern-matching-related methods to [AuthorModel].
extension AuthorModelPatterns on AuthorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthorModel value)  $default,){
final _that = this;
switch (_that) {
case _AuthorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthorModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
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
case _AuthorModel() when $default != null:
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
case _AuthorModel():
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
case _AuthorModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthorModel extends AuthorModel {
  const _AuthorModel({required this.id, required this.displayName, required this.username, this.avatarUrl, this.isVerified = false}): super._();
  factory _AuthorModel.fromJson(Map<String, dynamic> json) => _$AuthorModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthorModelCopyWith<_AuthorModel> get copyWith => __$AuthorModelCopyWithImpl<_AuthorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified);

@override
String toString() {
  return 'AuthorModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$AuthorModelCopyWith<$Res> implements $AuthorModelCopyWith<$Res> {
  factory _$AuthorModelCopyWith(_AuthorModel value, $Res Function(_AuthorModel) _then) = __$AuthorModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class __$AuthorModelCopyWithImpl<$Res>
    implements _$AuthorModelCopyWith<$Res> {
  __$AuthorModelCopyWithImpl(this._self, this._then);

  final _AuthorModel _self;
  final $Res Function(_AuthorModel) _then;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_AuthorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FieldRefModel {

 String get id; String get slug; String get nameAr; String get nameEn; String? get name;
/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<FieldRefModel> get copyWith => _$FieldRefModelCopyWithImpl<FieldRefModel>(this as FieldRefModel, _$identity);

  /// Serializes this FieldRefModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldRefModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,nameAr,nameEn,name);

@override
String toString() {
  return 'FieldRefModel(id: $id, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name)';
}


}

/// @nodoc
abstract mixin class $FieldRefModelCopyWith<$Res>  {
  factory $FieldRefModelCopyWith(FieldRefModel value, $Res Function(FieldRefModel) _then) = _$FieldRefModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String nameAr, String nameEn, String? name
});




}
/// @nodoc
class _$FieldRefModelCopyWithImpl<$Res>
    implements $FieldRefModelCopyWith<$Res> {
  _$FieldRefModelCopyWithImpl(this._self, this._then);

  final FieldRefModel _self;
  final $Res Function(FieldRefModel) _then;

/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldRefModel].
extension FieldRefModelPatterns on FieldRefModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldRefModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldRefModel value)  $default,){
final _that = this;
switch (_that) {
case _FieldRefModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldRefModel value)?  $default,){
final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String nameAr,  String nameEn,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String nameAr,  String nameEn,  String? name)  $default,) {final _that = this;
switch (_that) {
case _FieldRefModel():
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String nameAr,  String nameEn,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _FieldRefModel() when $default != null:
return $default(_that.id,_that.slug,_that.nameAr,_that.nameEn,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldRefModel extends FieldRefModel {
  const _FieldRefModel({required this.id, required this.slug, required this.nameAr, required this.nameEn, this.name}): super._();
  factory _FieldRefModel.fromJson(Map<String, dynamic> json) => _$FieldRefModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String nameAr;
@override final  String nameEn;
@override final  String? name;

/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldRefModelCopyWith<_FieldRefModel> get copyWith => __$FieldRefModelCopyWithImpl<_FieldRefModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldRefModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldRefModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,nameAr,nameEn,name);

@override
String toString() {
  return 'FieldRefModel(id: $id, slug: $slug, nameAr: $nameAr, nameEn: $nameEn, name: $name)';
}


}

/// @nodoc
abstract mixin class _$FieldRefModelCopyWith<$Res> implements $FieldRefModelCopyWith<$Res> {
  factory _$FieldRefModelCopyWith(_FieldRefModel value, $Res Function(_FieldRefModel) _then) = __$FieldRefModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String nameAr, String nameEn, String? name
});




}
/// @nodoc
class __$FieldRefModelCopyWithImpl<$Res>
    implements _$FieldRefModelCopyWith<$Res> {
  __$FieldRefModelCopyWithImpl(this._self, this._then);

  final _FieldRefModel _self;
  final $Res Function(_FieldRefModel) _then;

/// Create a copy of FieldRefModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? nameAr = null,Object? nameEn = null,Object? name = freezed,}) {
  return _then(_FieldRefModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ArticleCardModel {

 String get id; String get slug; String get language; String get title; String? get subtitle; String? get coverUrl; FieldRefModel get field; AuthorModel get author; int get readingTimeMinutes; bool get isReviewed; bool get isAiAssisted; String? get versionBadge; DateTime get publishedAt; int get reactionCount; int get commentCount;
/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<ArticleCardModel> get copyWith => _$ArticleCardModelCopyWithImpl<ArticleCardModel>(this as ArticleCardModel, _$identity);

  /// Serializes this ArticleCardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isReviewed,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount);

@override
String toString() {
  return 'ArticleCardModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isReviewed: $isReviewed, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount)';
}


}

/// @nodoc
abstract mixin class $ArticleCardModelCopyWith<$Res>  {
  factory $ArticleCardModelCopyWith(ArticleCardModel value, $Res Function(ArticleCardModel) _then) = _$ArticleCardModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel author, int readingTimeMinutes, bool isReviewed, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount
});


$FieldRefModelCopyWith<$Res> get field;$AuthorModelCopyWith<$Res> get author;

}
/// @nodoc
class _$ArticleCardModelCopyWithImpl<$Res>
    implements $ArticleCardModelCopyWith<$Res> {
  _$ArticleCardModelCopyWithImpl(this._self, this._then);

  final ArticleCardModel _self;
  final $Res Function(ArticleCardModel) _then;

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = null,Object? readingTimeMinutes = null,Object? isReviewed = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleCardModel].
extension ArticleCardModelPatterns on ArticleCardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleCardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleCardModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleCardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleCardModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel author,  int readingTimeMinutes,  bool isReviewed,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isReviewed,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel author,  int readingTimeMinutes,  bool isReviewed,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount)  $default,) {final _that = this;
switch (_that) {
case _ArticleCardModel():
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isReviewed,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel author,  int readingTimeMinutes,  bool isReviewed,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount)?  $default,) {final _that = this;
switch (_that) {
case _ArticleCardModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isReviewed,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleCardModel extends ArticleCardModel {
  const _ArticleCardModel({required this.id, required this.slug, required this.language, required this.title, this.subtitle, this.coverUrl, required this.field, required this.author, this.readingTimeMinutes = 1, this.isReviewed = false, this.isAiAssisted = false, this.versionBadge, required this.publishedAt, this.reactionCount = 0, this.commentCount = 0}): super._();
  factory _ArticleCardModel.fromJson(Map<String, dynamic> json) => _$ArticleCardModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String language;
@override final  String title;
@override final  String? subtitle;
@override final  String? coverUrl;
@override final  FieldRefModel field;
@override final  AuthorModel author;
@override@JsonKey() final  int readingTimeMinutes;
@override@JsonKey() final  bool isReviewed;
@override@JsonKey() final  bool isAiAssisted;
@override final  String? versionBadge;
@override final  DateTime publishedAt;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleCardModelCopyWith<_ArticleCardModel> get copyWith => __$ArticleCardModelCopyWithImpl<_ArticleCardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleCardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isReviewed,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount);

@override
String toString() {
  return 'ArticleCardModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isReviewed: $isReviewed, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount)';
}


}

/// @nodoc
abstract mixin class _$ArticleCardModelCopyWith<$Res> implements $ArticleCardModelCopyWith<$Res> {
  factory _$ArticleCardModelCopyWith(_ArticleCardModel value, $Res Function(_ArticleCardModel) _then) = __$ArticleCardModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel author, int readingTimeMinutes, bool isReviewed, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount
});


@override $FieldRefModelCopyWith<$Res> get field;@override $AuthorModelCopyWith<$Res> get author;

}
/// @nodoc
class __$ArticleCardModelCopyWithImpl<$Res>
    implements _$ArticleCardModelCopyWith<$Res> {
  __$ArticleCardModelCopyWithImpl(this._self, this._then);

  final _ArticleCardModel _self;
  final $Res Function(_ArticleCardModel) _then;

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = null,Object? readingTimeMinutes = null,Object? isReviewed = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,}) {
  return _then(_ArticleCardModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$ArticleCardPageModel {

 List<ArticleCardModel> get items; String? get nextCursor;
/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleCardPageModelCopyWith<ArticleCardPageModel> get copyWith => _$ArticleCardPageModelCopyWithImpl<ArticleCardPageModel>(this as ArticleCardPageModel, _$identity);

  /// Serializes this ArticleCardPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleCardPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'ArticleCardPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $ArticleCardPageModelCopyWith<$Res>  {
  factory $ArticleCardPageModelCopyWith(ArticleCardPageModel value, $Res Function(ArticleCardPageModel) _then) = _$ArticleCardPageModelCopyWithImpl;
@useResult
$Res call({
 List<ArticleCardModel> items, String? nextCursor
});




}
/// @nodoc
class _$ArticleCardPageModelCopyWithImpl<$Res>
    implements $ArticleCardPageModelCopyWith<$Res> {
  _$ArticleCardPageModelCopyWithImpl(this._self, this._then);

  final ArticleCardPageModel _self;
  final $Res Function(ArticleCardPageModel) _then;

/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleCardPageModel].
extension ArticleCardPageModelPatterns on ArticleCardPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleCardPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleCardPageModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleCardPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleCardPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ArticleCardModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ArticleCardModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ArticleCardPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ArticleCardModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ArticleCardPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleCardPageModel implements ArticleCardPageModel {
  const _ArticleCardPageModel({final  List<ArticleCardModel> items = const <ArticleCardModel>[], this.nextCursor}): _items = items;
  factory _ArticleCardPageModel.fromJson(Map<String, dynamic> json) => _$ArticleCardPageModelFromJson(json);

 final  List<ArticleCardModel> _items;
@override@JsonKey() List<ArticleCardModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleCardPageModelCopyWith<_ArticleCardPageModel> get copyWith => __$ArticleCardPageModelCopyWithImpl<_ArticleCardPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleCardPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleCardPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'ArticleCardPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ArticleCardPageModelCopyWith<$Res> implements $ArticleCardPageModelCopyWith<$Res> {
  factory _$ArticleCardPageModelCopyWith(_ArticleCardPageModel value, $Res Function(_ArticleCardPageModel) _then) = __$ArticleCardPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<ArticleCardModel> items, String? nextCursor
});




}
/// @nodoc
class __$ArticleCardPageModelCopyWithImpl<$Res>
    implements _$ArticleCardPageModelCopyWith<$Res> {
  __$ArticleCardPageModelCopyWithImpl(this._self, this._then);

  final _ArticleCardPageModel _self;
  final $Res Function(_ArticleCardPageModel) _then;

/// Create a copy of ArticleCardPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_ArticleCardPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ArticleCardModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SourceModel {

 String get title; String get url;
/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceModelCopyWith<SourceModel> get copyWith => _$SourceModelCopyWithImpl<SourceModel>(this as SourceModel, _$identity);

  /// Serializes this SourceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceModel&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url);

@override
String toString() {
  return 'SourceModel(title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class $SourceModelCopyWith<$Res>  {
  factory $SourceModelCopyWith(SourceModel value, $Res Function(SourceModel) _then) = _$SourceModelCopyWithImpl;
@useResult
$Res call({
 String title, String url
});




}
/// @nodoc
class _$SourceModelCopyWithImpl<$Res>
    implements $SourceModelCopyWith<$Res> {
  _$SourceModelCopyWithImpl(this._self, this._then);

  final SourceModel _self;
  final $Res Function(SourceModel) _then;

/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? url = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceModel].
extension SourceModelPatterns on SourceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceModel value)  $default,){
final _that = this;
switch (_that) {
case _SourceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceModel value)?  $default,){
final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
return $default(_that.title,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String url)  $default,) {final _that = this;
switch (_that) {
case _SourceModel():
return $default(_that.title,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String url)?  $default,) {final _that = this;
switch (_that) {
case _SourceModel() when $default != null:
return $default(_that.title,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceModel implements SourceModel {
  const _SourceModel({required this.title, required this.url});
  factory _SourceModel.fromJson(Map<String, dynamic> json) => _$SourceModelFromJson(json);

@override final  String title;
@override final  String url;

/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceModelCopyWith<_SourceModel> get copyWith => __$SourceModelCopyWithImpl<_SourceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceModel&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url);

@override
String toString() {
  return 'SourceModel(title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SourceModelCopyWith<$Res> implements $SourceModelCopyWith<$Res> {
  factory _$SourceModelCopyWith(_SourceModel value, $Res Function(_SourceModel) _then) = __$SourceModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String url
});




}
/// @nodoc
class __$SourceModelCopyWithImpl<$Res>
    implements _$SourceModelCopyWith<$Res> {
  __$SourceModelCopyWithImpl(this._self, this._then);

  final _SourceModel _self;
  final $Res Function(_SourceModel) _then;

/// Create a copy of SourceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? url = null,}) {
  return _then(_SourceModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ReviewerModel {

 String get displayName; String get username;
/// Create a copy of ReviewerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewerModelCopyWith<ReviewerModel> get copyWith => _$ReviewerModelCopyWithImpl<ReviewerModel>(this as ReviewerModel, _$identity);

  /// Serializes this ReviewerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewerModel&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,username);

@override
String toString() {
  return 'ReviewerModel(displayName: $displayName, username: $username)';
}


}

/// @nodoc
abstract mixin class $ReviewerModelCopyWith<$Res>  {
  factory $ReviewerModelCopyWith(ReviewerModel value, $Res Function(ReviewerModel) _then) = _$ReviewerModelCopyWithImpl;
@useResult
$Res call({
 String displayName, String username
});




}
/// @nodoc
class _$ReviewerModelCopyWithImpl<$Res>
    implements $ReviewerModelCopyWith<$Res> {
  _$ReviewerModelCopyWithImpl(this._self, this._then);

  final ReviewerModel _self;
  final $Res Function(ReviewerModel) _then;

/// Create a copy of ReviewerModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? username = null,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewerModel].
extension ReviewerModelPatterns on ReviewerModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewerModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewerModel value)  $default,){
final _that = this;
switch (_that) {
case _ReviewerModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewerModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewerModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewerModel() when $default != null:
return $default(_that.displayName,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String username)  $default,) {final _that = this;
switch (_that) {
case _ReviewerModel():
return $default(_that.displayName,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String username)?  $default,) {final _that = this;
switch (_that) {
case _ReviewerModel() when $default != null:
return $default(_that.displayName,_that.username);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewerModel implements ReviewerModel {
  const _ReviewerModel({required this.displayName, required this.username});
  factory _ReviewerModel.fromJson(Map<String, dynamic> json) => _$ReviewerModelFromJson(json);

@override final  String displayName;
@override final  String username;

/// Create a copy of ReviewerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewerModelCopyWith<_ReviewerModel> get copyWith => __$ReviewerModelCopyWithImpl<_ReviewerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewerModel&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,username);

@override
String toString() {
  return 'ReviewerModel(displayName: $displayName, username: $username)';
}


}

/// @nodoc
abstract mixin class _$ReviewerModelCopyWith<$Res> implements $ReviewerModelCopyWith<$Res> {
  factory _$ReviewerModelCopyWith(_ReviewerModel value, $Res Function(_ReviewerModel) _then) = __$ReviewerModelCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String username
});




}
/// @nodoc
class __$ReviewerModelCopyWithImpl<$Res>
    implements _$ReviewerModelCopyWith<$Res> {
  __$ReviewerModelCopyWithImpl(this._self, this._then);

  final _ReviewerModel _self;
  final $Res Function(_ReviewerModel) _then;

/// Create a copy of ReviewerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? username = null,}) {
  return _then(_ReviewerModel(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ArticleDetailsModel {

 String get id; String get slug; String get language; String get title; String? get subtitle; String? get coverUrl; FieldRefModel get field; AuthorModel get author; int get readingTimeMinutes; bool get isReviewed; bool get isAiAssisted; String? get versionBadge; DateTime get publishedAt; int get reactionCount; int get commentCount; List<String> get availableLanguages; String? get summary; Map<String, dynamic> get content; FieldRefModel? get topic; List<String> get tags; List<SourceModel> get sources; ReviewerModel? get reviewedBy; DateTime? get lastReviewedAt; int get saveCount; int get readCount;
/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleDetailsModelCopyWith<ArticleDetailsModel> get copyWith => _$ArticleDetailsModelCopyWithImpl<ArticleDetailsModel>(this as ArticleDetailsModel, _$identity);

  /// Serializes this ArticleDetailsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleDetailsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&const DeepCollectionEquality().equals(other.availableLanguages, availableLanguages)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.lastReviewedAt, lastReviewedAt) || other.lastReviewedAt == lastReviewedAt)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.readCount, readCount) || other.readCount == readCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isReviewed,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount,const DeepCollectionEquality().hash(availableLanguages),summary,const DeepCollectionEquality().hash(content),topic,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(sources),reviewedBy,lastReviewedAt,saveCount,readCount]);

@override
String toString() {
  return 'ArticleDetailsModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isReviewed: $isReviewed, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount, availableLanguages: $availableLanguages, summary: $summary, content: $content, topic: $topic, tags: $tags, sources: $sources, reviewedBy: $reviewedBy, lastReviewedAt: $lastReviewedAt, saveCount: $saveCount, readCount: $readCount)';
}


}

/// @nodoc
abstract mixin class $ArticleDetailsModelCopyWith<$Res>  {
  factory $ArticleDetailsModelCopyWith(ArticleDetailsModel value, $Res Function(ArticleDetailsModel) _then) = _$ArticleDetailsModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel author, int readingTimeMinutes, bool isReviewed, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount, List<String> availableLanguages, String? summary, Map<String, dynamic> content, FieldRefModel? topic, List<String> tags, List<SourceModel> sources, ReviewerModel? reviewedBy, DateTime? lastReviewedAt, int saveCount, int readCount
});


$FieldRefModelCopyWith<$Res> get field;$AuthorModelCopyWith<$Res> get author;$FieldRefModelCopyWith<$Res>? get topic;$ReviewerModelCopyWith<$Res>? get reviewedBy;

}
/// @nodoc
class _$ArticleDetailsModelCopyWithImpl<$Res>
    implements $ArticleDetailsModelCopyWith<$Res> {
  _$ArticleDetailsModelCopyWithImpl(this._self, this._then);

  final ArticleDetailsModel _self;
  final $Res Function(ArticleDetailsModel) _then;

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = null,Object? readingTimeMinutes = null,Object? isReviewed = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,Object? availableLanguages = null,Object? summary = freezed,Object? content = null,Object? topic = freezed,Object? tags = null,Object? sources = null,Object? reviewedBy = freezed,Object? lastReviewedAt = freezed,Object? saveCount = null,Object? readCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,availableLanguages: null == availableLanguages ? _self.availableLanguages : availableLanguages // ignore: cast_nullable_to_non_nullable
as List<String>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceModel>,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as ReviewerModel?,lastReviewedAt: freezed == lastReviewedAt ? _self.lastReviewedAt : lastReviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewerModelCopyWith<$Res>? get reviewedBy {
    if (_self.reviewedBy == null) {
    return null;
  }

  return $ReviewerModelCopyWith<$Res>(_self.reviewedBy!, (value) {
    return _then(_self.copyWith(reviewedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleDetailsModel].
extension ArticleDetailsModelPatterns on ArticleDetailsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleDetailsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleDetailsModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleDetailsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleDetailsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel author,  int readingTimeMinutes,  bool isReviewed,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  List<String> availableLanguages,  String? summary,  Map<String, dynamic> content,  FieldRefModel? topic,  List<String> tags,  List<SourceModel> sources,  ReviewerModel? reviewedBy,  DateTime? lastReviewedAt,  int saveCount,  int readCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isReviewed,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.availableLanguages,_that.summary,_that.content,_that.topic,_that.tags,_that.sources,_that.reviewedBy,_that.lastReviewedAt,_that.saveCount,_that.readCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel author,  int readingTimeMinutes,  bool isReviewed,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  List<String> availableLanguages,  String? summary,  Map<String, dynamic> content,  FieldRefModel? topic,  List<String> tags,  List<SourceModel> sources,  ReviewerModel? reviewedBy,  DateTime? lastReviewedAt,  int saveCount,  int readCount)  $default,) {final _that = this;
switch (_that) {
case _ArticleDetailsModel():
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isReviewed,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.availableLanguages,_that.summary,_that.content,_that.topic,_that.tags,_that.sources,_that.reviewedBy,_that.lastReviewedAt,_that.saveCount,_that.readCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String language,  String title,  String? subtitle,  String? coverUrl,  FieldRefModel field,  AuthorModel author,  int readingTimeMinutes,  bool isReviewed,  bool isAiAssisted,  String? versionBadge,  DateTime publishedAt,  int reactionCount,  int commentCount,  List<String> availableLanguages,  String? summary,  Map<String, dynamic> content,  FieldRefModel? topic,  List<String> tags,  List<SourceModel> sources,  ReviewerModel? reviewedBy,  DateTime? lastReviewedAt,  int saveCount,  int readCount)?  $default,) {final _that = this;
switch (_that) {
case _ArticleDetailsModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.subtitle,_that.coverUrl,_that.field,_that.author,_that.readingTimeMinutes,_that.isReviewed,_that.isAiAssisted,_that.versionBadge,_that.publishedAt,_that.reactionCount,_that.commentCount,_that.availableLanguages,_that.summary,_that.content,_that.topic,_that.tags,_that.sources,_that.reviewedBy,_that.lastReviewedAt,_that.saveCount,_that.readCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleDetailsModel extends ArticleDetailsModel {
  const _ArticleDetailsModel({required this.id, required this.slug, required this.language, required this.title, this.subtitle, this.coverUrl, required this.field, required this.author, this.readingTimeMinutes = 1, this.isReviewed = false, this.isAiAssisted = false, this.versionBadge, required this.publishedAt, this.reactionCount = 0, this.commentCount = 0, final  List<String> availableLanguages = const <String>[], this.summary, final  Map<String, dynamic> content = const <String, dynamic>{}, this.topic, final  List<String> tags = const <String>[], final  List<SourceModel> sources = const <SourceModel>[], this.reviewedBy, this.lastReviewedAt, this.saveCount = 0, this.readCount = 0}): _availableLanguages = availableLanguages,_content = content,_tags = tags,_sources = sources,super._();
  factory _ArticleDetailsModel.fromJson(Map<String, dynamic> json) => _$ArticleDetailsModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String language;
@override final  String title;
@override final  String? subtitle;
@override final  String? coverUrl;
@override final  FieldRefModel field;
@override final  AuthorModel author;
@override@JsonKey() final  int readingTimeMinutes;
@override@JsonKey() final  bool isReviewed;
@override@JsonKey() final  bool isAiAssisted;
@override final  String? versionBadge;
@override final  DateTime publishedAt;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;
 final  List<String> _availableLanguages;
@override@JsonKey() List<String> get availableLanguages {
  if (_availableLanguages is EqualUnmodifiableListView) return _availableLanguages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableLanguages);
}

@override final  String? summary;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

@override final  FieldRefModel? topic;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<SourceModel> _sources;
@override@JsonKey() List<SourceModel> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

@override final  ReviewerModel? reviewedBy;
@override final  DateTime? lastReviewedAt;
@override@JsonKey() final  int saveCount;
@override@JsonKey() final  int readCount;

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleDetailsModelCopyWith<_ArticleDetailsModel> get copyWith => __$ArticleDetailsModelCopyWithImpl<_ArticleDetailsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleDetailsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleDetailsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.author, author) || other.author == author)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&const DeepCollectionEquality().equals(other._availableLanguages, _availableLanguages)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.topic, topic) || other.topic == topic)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.lastReviewedAt, lastReviewedAt) || other.lastReviewedAt == lastReviewedAt)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.readCount, readCount) || other.readCount == readCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,language,title,subtitle,coverUrl,field,author,readingTimeMinutes,isReviewed,isAiAssisted,versionBadge,publishedAt,reactionCount,commentCount,const DeepCollectionEquality().hash(_availableLanguages),summary,const DeepCollectionEquality().hash(_content),topic,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_sources),reviewedBy,lastReviewedAt,saveCount,readCount]);

@override
String toString() {
  return 'ArticleDetailsModel(id: $id, slug: $slug, language: $language, title: $title, subtitle: $subtitle, coverUrl: $coverUrl, field: $field, author: $author, readingTimeMinutes: $readingTimeMinutes, isReviewed: $isReviewed, isAiAssisted: $isAiAssisted, versionBadge: $versionBadge, publishedAt: $publishedAt, reactionCount: $reactionCount, commentCount: $commentCount, availableLanguages: $availableLanguages, summary: $summary, content: $content, topic: $topic, tags: $tags, sources: $sources, reviewedBy: $reviewedBy, lastReviewedAt: $lastReviewedAt, saveCount: $saveCount, readCount: $readCount)';
}


}

/// @nodoc
abstract mixin class _$ArticleDetailsModelCopyWith<$Res> implements $ArticleDetailsModelCopyWith<$Res> {
  factory _$ArticleDetailsModelCopyWith(_ArticleDetailsModel value, $Res Function(_ArticleDetailsModel) _then) = __$ArticleDetailsModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String language, String title, String? subtitle, String? coverUrl, FieldRefModel field, AuthorModel author, int readingTimeMinutes, bool isReviewed, bool isAiAssisted, String? versionBadge, DateTime publishedAt, int reactionCount, int commentCount, List<String> availableLanguages, String? summary, Map<String, dynamic> content, FieldRefModel? topic, List<String> tags, List<SourceModel> sources, ReviewerModel? reviewedBy, DateTime? lastReviewedAt, int saveCount, int readCount
});


@override $FieldRefModelCopyWith<$Res> get field;@override $AuthorModelCopyWith<$Res> get author;@override $FieldRefModelCopyWith<$Res>? get topic;@override $ReviewerModelCopyWith<$Res>? get reviewedBy;

}
/// @nodoc
class __$ArticleDetailsModelCopyWithImpl<$Res>
    implements _$ArticleDetailsModelCopyWith<$Res> {
  __$ArticleDetailsModelCopyWithImpl(this._self, this._then);

  final _ArticleDetailsModel _self;
  final $Res Function(_ArticleDetailsModel) _then;

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? coverUrl = freezed,Object? field = null,Object? author = null,Object? readingTimeMinutes = null,Object? isReviewed = null,Object? isAiAssisted = null,Object? versionBadge = freezed,Object? publishedAt = null,Object? reactionCount = null,Object? commentCount = null,Object? availableLanguages = null,Object? summary = freezed,Object? content = null,Object? topic = freezed,Object? tags = null,Object? sources = null,Object? reviewedBy = freezed,Object? lastReviewedAt = freezed,Object? saveCount = null,Object? readCount = null,}) {
  return _then(_ArticleDetailsModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,availableLanguages: null == availableLanguages ? _self._availableLanguages : availableLanguages // ignore: cast_nullable_to_non_nullable
as List<String>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceModel>,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as ReviewerModel?,lastReviewedAt: freezed == lastReviewedAt ? _self.lastReviewedAt : lastReviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of ArticleDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewerModelCopyWith<$Res>? get reviewedBy {
    if (_self.reviewedBy == null) {
    return null;
  }

  return $ReviewerModelCopyWith<$Res>(_self.reviewedBy!, (value) {
    return _then(_self.copyWith(reviewedBy: value));
  });
}
}

// dart format on
