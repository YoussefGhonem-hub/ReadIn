// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SourceRequestModel {

 String get title; String get url;
/// Create a copy of SourceRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceRequestModelCopyWith<SourceRequestModel> get copyWith => _$SourceRequestModelCopyWithImpl<SourceRequestModel>(this as SourceRequestModel, _$identity);

  /// Serializes this SourceRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceRequestModel&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url);

@override
String toString() {
  return 'SourceRequestModel(title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class $SourceRequestModelCopyWith<$Res>  {
  factory $SourceRequestModelCopyWith(SourceRequestModel value, $Res Function(SourceRequestModel) _then) = _$SourceRequestModelCopyWithImpl;
@useResult
$Res call({
 String title, String url
});




}
/// @nodoc
class _$SourceRequestModelCopyWithImpl<$Res>
    implements $SourceRequestModelCopyWith<$Res> {
  _$SourceRequestModelCopyWithImpl(this._self, this._then);

  final SourceRequestModel _self;
  final $Res Function(SourceRequestModel) _then;

/// Create a copy of SourceRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? url = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceRequestModel].
extension SourceRequestModelPatterns on SourceRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _SourceRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _SourceRequestModel() when $default != null:
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
case _SourceRequestModel() when $default != null:
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
case _SourceRequestModel():
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
case _SourceRequestModel() when $default != null:
return $default(_that.title,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceRequestModel implements SourceRequestModel {
  const _SourceRequestModel({required this.title, required this.url});
  factory _SourceRequestModel.fromJson(Map<String, dynamic> json) => _$SourceRequestModelFromJson(json);

@override final  String title;
@override final  String url;

/// Create a copy of SourceRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceRequestModelCopyWith<_SourceRequestModel> get copyWith => __$SourceRequestModelCopyWithImpl<_SourceRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceRequestModel&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url);

@override
String toString() {
  return 'SourceRequestModel(title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SourceRequestModelCopyWith<$Res> implements $SourceRequestModelCopyWith<$Res> {
  factory _$SourceRequestModelCopyWith(_SourceRequestModel value, $Res Function(_SourceRequestModel) _then) = __$SourceRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String url
});




}
/// @nodoc
class __$SourceRequestModelCopyWithImpl<$Res>
    implements _$SourceRequestModelCopyWith<$Res> {
  __$SourceRequestModelCopyWithImpl(this._self, this._then);

  final _SourceRequestModel _self;
  final $Res Function(_SourceRequestModel) _then;

/// Create a copy of SourceRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? url = null,}) {
  return _then(_SourceRequestModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CreateArticleRequestModel {

 String get fieldId; String? get topicId; String get language; String get title; String? get subtitle; Map<String, dynamic> get content; List<String>? get tags; List<SourceRequestModel>? get sources; String? get coverUrl; String? get versionBadge; bool get isAiAssisted;
/// Create a copy of CreateArticleRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateArticleRequestModelCopyWith<CreateArticleRequestModel> get copyWith => _$CreateArticleRequestModelCopyWithImpl<CreateArticleRequestModel>(this as CreateArticleRequestModel, _$identity);

  /// Serializes this CreateArticleRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateArticleRequestModel&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fieldId,topicId,language,title,subtitle,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(sources),coverUrl,versionBadge,isAiAssisted);

@override
String toString() {
  return 'CreateArticleRequestModel(fieldId: $fieldId, topicId: $topicId, language: $language, title: $title, subtitle: $subtitle, content: $content, tags: $tags, sources: $sources, coverUrl: $coverUrl, versionBadge: $versionBadge, isAiAssisted: $isAiAssisted)';
}


}

/// @nodoc
abstract mixin class $CreateArticleRequestModelCopyWith<$Res>  {
  factory $CreateArticleRequestModelCopyWith(CreateArticleRequestModel value, $Res Function(CreateArticleRequestModel) _then) = _$CreateArticleRequestModelCopyWithImpl;
@useResult
$Res call({
 String fieldId, String? topicId, String language, String title, String? subtitle, Map<String, dynamic> content, List<String>? tags, List<SourceRequestModel>? sources, String? coverUrl, String? versionBadge, bool isAiAssisted
});




}
/// @nodoc
class _$CreateArticleRequestModelCopyWithImpl<$Res>
    implements $CreateArticleRequestModelCopyWith<$Res> {
  _$CreateArticleRequestModelCopyWithImpl(this._self, this._then);

  final CreateArticleRequestModel _self;
  final $Res Function(CreateArticleRequestModel) _then;

/// Create a copy of CreateArticleRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fieldId = null,Object? topicId = freezed,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? content = null,Object? tags = freezed,Object? sources = freezed,Object? coverUrl = freezed,Object? versionBadge = freezed,Object? isAiAssisted = null,}) {
  return _then(_self.copyWith(
fieldId: null == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,sources: freezed == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceRequestModel>?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateArticleRequestModel].
extension CreateArticleRequestModelPatterns on CreateArticleRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateArticleRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateArticleRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateArticleRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _CreateArticleRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateArticleRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _CreateArticleRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fieldId,  String? topicId,  String language,  String title,  String? subtitle,  Map<String, dynamic> content,  List<String>? tags,  List<SourceRequestModel>? sources,  String? coverUrl,  String? versionBadge,  bool isAiAssisted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateArticleRequestModel() when $default != null:
return $default(_that.fieldId,_that.topicId,_that.language,_that.title,_that.subtitle,_that.content,_that.tags,_that.sources,_that.coverUrl,_that.versionBadge,_that.isAiAssisted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fieldId,  String? topicId,  String language,  String title,  String? subtitle,  Map<String, dynamic> content,  List<String>? tags,  List<SourceRequestModel>? sources,  String? coverUrl,  String? versionBadge,  bool isAiAssisted)  $default,) {final _that = this;
switch (_that) {
case _CreateArticleRequestModel():
return $default(_that.fieldId,_that.topicId,_that.language,_that.title,_that.subtitle,_that.content,_that.tags,_that.sources,_that.coverUrl,_that.versionBadge,_that.isAiAssisted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fieldId,  String? topicId,  String language,  String title,  String? subtitle,  Map<String, dynamic> content,  List<String>? tags,  List<SourceRequestModel>? sources,  String? coverUrl,  String? versionBadge,  bool isAiAssisted)?  $default,) {final _that = this;
switch (_that) {
case _CreateArticleRequestModel() when $default != null:
return $default(_that.fieldId,_that.topicId,_that.language,_that.title,_that.subtitle,_that.content,_that.tags,_that.sources,_that.coverUrl,_that.versionBadge,_that.isAiAssisted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateArticleRequestModel implements CreateArticleRequestModel {
  const _CreateArticleRequestModel({required this.fieldId, this.topicId, required this.language, required this.title, this.subtitle, required final  Map<String, dynamic> content, final  List<String>? tags, final  List<SourceRequestModel>? sources, this.coverUrl, this.versionBadge, required this.isAiAssisted}): _content = content,_tags = tags,_sources = sources;
  factory _CreateArticleRequestModel.fromJson(Map<String, dynamic> json) => _$CreateArticleRequestModelFromJson(json);

@override final  String fieldId;
@override final  String? topicId;
@override final  String language;
@override final  String title;
@override final  String? subtitle;
 final  Map<String, dynamic> _content;
@override Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

 final  List<String>? _tags;
@override List<String>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<SourceRequestModel>? _sources;
@override List<SourceRequestModel>? get sources {
  final value = _sources;
  if (value == null) return null;
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? coverUrl;
@override final  String? versionBadge;
@override final  bool isAiAssisted;

/// Create a copy of CreateArticleRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateArticleRequestModelCopyWith<_CreateArticleRequestModel> get copyWith => __$CreateArticleRequestModelCopyWithImpl<_CreateArticleRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateArticleRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateArticleRequestModel&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other._content, _content)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fieldId,topicId,language,title,subtitle,const DeepCollectionEquality().hash(_content),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_sources),coverUrl,versionBadge,isAiAssisted);

@override
String toString() {
  return 'CreateArticleRequestModel(fieldId: $fieldId, topicId: $topicId, language: $language, title: $title, subtitle: $subtitle, content: $content, tags: $tags, sources: $sources, coverUrl: $coverUrl, versionBadge: $versionBadge, isAiAssisted: $isAiAssisted)';
}


}

/// @nodoc
abstract mixin class _$CreateArticleRequestModelCopyWith<$Res> implements $CreateArticleRequestModelCopyWith<$Res> {
  factory _$CreateArticleRequestModelCopyWith(_CreateArticleRequestModel value, $Res Function(_CreateArticleRequestModel) _then) = __$CreateArticleRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String fieldId, String? topicId, String language, String title, String? subtitle, Map<String, dynamic> content, List<String>? tags, List<SourceRequestModel>? sources, String? coverUrl, String? versionBadge, bool isAiAssisted
});




}
/// @nodoc
class __$CreateArticleRequestModelCopyWithImpl<$Res>
    implements _$CreateArticleRequestModelCopyWith<$Res> {
  __$CreateArticleRequestModelCopyWithImpl(this._self, this._then);

  final _CreateArticleRequestModel _self;
  final $Res Function(_CreateArticleRequestModel) _then;

/// Create a copy of CreateArticleRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fieldId = null,Object? topicId = freezed,Object? language = null,Object? title = null,Object? subtitle = freezed,Object? content = null,Object? tags = freezed,Object? sources = freezed,Object? coverUrl = freezed,Object? versionBadge = freezed,Object? isAiAssisted = null,}) {
  return _then(_CreateArticleRequestModel(
fieldId: null == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,sources: freezed == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceRequestModel>?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CreatedArticleModel {

 String get id; String get slug;
/// Create a copy of CreatedArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedArticleModelCopyWith<CreatedArticleModel> get copyWith => _$CreatedArticleModelCopyWithImpl<CreatedArticleModel>(this as CreatedArticleModel, _$identity);

  /// Serializes this CreatedArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug);

@override
String toString() {
  return 'CreatedArticleModel(id: $id, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $CreatedArticleModelCopyWith<$Res>  {
  factory $CreatedArticleModelCopyWith(CreatedArticleModel value, $Res Function(CreatedArticleModel) _then) = _$CreatedArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug
});




}
/// @nodoc
class _$CreatedArticleModelCopyWithImpl<$Res>
    implements $CreatedArticleModelCopyWith<$Res> {
  _$CreatedArticleModelCopyWithImpl(this._self, this._then);

  final CreatedArticleModel _self;
  final $Res Function(CreatedArticleModel) _then;

/// Create a copy of CreatedArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatedArticleModel].
extension CreatedArticleModelPatterns on CreatedArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatedArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatedArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatedArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _CreatedArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatedArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _CreatedArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatedArticleModel() when $default != null:
return $default(_that.id,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug)  $default,) {final _that = this;
switch (_that) {
case _CreatedArticleModel():
return $default(_that.id,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _CreatedArticleModel() when $default != null:
return $default(_that.id,_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatedArticleModel extends CreatedArticleModel {
  const _CreatedArticleModel({required this.id, required this.slug}): super._();
  factory _CreatedArticleModel.fromJson(Map<String, dynamic> json) => _$CreatedArticleModelFromJson(json);

@override final  String id;
@override final  String slug;

/// Create a copy of CreatedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatedArticleModelCopyWith<_CreatedArticleModel> get copyWith => __$CreatedArticleModelCopyWithImpl<_CreatedArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatedArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatedArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug);

@override
String toString() {
  return 'CreatedArticleModel(id: $id, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$CreatedArticleModelCopyWith<$Res> implements $CreatedArticleModelCopyWith<$Res> {
  factory _$CreatedArticleModelCopyWith(_CreatedArticleModel value, $Res Function(_CreatedArticleModel) _then) = __$CreatedArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug
});




}
/// @nodoc
class __$CreatedArticleModelCopyWithImpl<$Res>
    implements _$CreatedArticleModelCopyWith<$Res> {
  __$CreatedArticleModelCopyWithImpl(this._self, this._then);

  final _CreatedArticleModel _self;
  final $Res Function(_CreatedArticleModel) _then;

/// Create a copy of CreatedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,}) {
  return _then(_CreatedArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
