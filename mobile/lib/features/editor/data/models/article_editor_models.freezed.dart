// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_editor_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DraftTranslationModel {

 String get language; String get title;@JsonKey(includeIfNull: true) String? get subtitle; Map<String, dynamic> get content;
/// Create a copy of DraftTranslationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftTranslationModelCopyWith<DraftTranslationModel> get copyWith => _$DraftTranslationModelCopyWithImpl<DraftTranslationModel>(this as DraftTranslationModel, _$identity);

  /// Serializes this DraftTranslationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftTranslationModel&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other.content, content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,title,subtitle,const DeepCollectionEquality().hash(content));

@override
String toString() {
  return 'DraftTranslationModel(language: $language, title: $title, subtitle: $subtitle, content: $content)';
}


}

/// @nodoc
abstract mixin class $DraftTranslationModelCopyWith<$Res>  {
  factory $DraftTranslationModelCopyWith(DraftTranslationModel value, $Res Function(DraftTranslationModel) _then) = _$DraftTranslationModelCopyWithImpl;
@useResult
$Res call({
 String language, String title,@JsonKey(includeIfNull: true) String? subtitle, Map<String, dynamic> content
});




}
/// @nodoc
class _$DraftTranslationModelCopyWithImpl<$Res>
    implements $DraftTranslationModelCopyWith<$Res> {
  _$DraftTranslationModelCopyWithImpl(this._self, this._then);

  final DraftTranslationModel _self;
  final $Res Function(DraftTranslationModel) _then;

/// Create a copy of DraftTranslationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? title = null,Object? subtitle = freezed,Object? content = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftTranslationModel].
extension DraftTranslationModelPatterns on DraftTranslationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftTranslationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftTranslationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftTranslationModel value)  $default,){
final _that = this;
switch (_that) {
case _DraftTranslationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftTranslationModel value)?  $default,){
final _that = this;
switch (_that) {
case _DraftTranslationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  String title, @JsonKey(includeIfNull: true)  String? subtitle,  Map<String, dynamic> content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraftTranslationModel() when $default != null:
return $default(_that.language,_that.title,_that.subtitle,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  String title, @JsonKey(includeIfNull: true)  String? subtitle,  Map<String, dynamic> content)  $default,) {final _that = this;
switch (_that) {
case _DraftTranslationModel():
return $default(_that.language,_that.title,_that.subtitle,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  String title, @JsonKey(includeIfNull: true)  String? subtitle,  Map<String, dynamic> content)?  $default,) {final _that = this;
switch (_that) {
case _DraftTranslationModel() when $default != null:
return $default(_that.language,_that.title,_that.subtitle,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftTranslationModel extends DraftTranslationModel {
  const _DraftTranslationModel({required this.language, this.title = '', @JsonKey(includeIfNull: true) this.subtitle, final  Map<String, dynamic> content = const <String, dynamic>{}}): _content = content,super._();
  factory _DraftTranslationModel.fromJson(Map<String, dynamic> json) => _$DraftTranslationModelFromJson(json);

@override final  String language;
@override@JsonKey() final  String title;
@override@JsonKey(includeIfNull: true) final  String? subtitle;
 final  Map<String, dynamic> _content;
@override@JsonKey() Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}


/// Create a copy of DraftTranslationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftTranslationModelCopyWith<_DraftTranslationModel> get copyWith => __$DraftTranslationModelCopyWithImpl<_DraftTranslationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftTranslationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftTranslationModel&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other._content, _content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,title,subtitle,const DeepCollectionEquality().hash(_content));

@override
String toString() {
  return 'DraftTranslationModel(language: $language, title: $title, subtitle: $subtitle, content: $content)';
}


}

/// @nodoc
abstract mixin class _$DraftTranslationModelCopyWith<$Res> implements $DraftTranslationModelCopyWith<$Res> {
  factory _$DraftTranslationModelCopyWith(_DraftTranslationModel value, $Res Function(_DraftTranslationModel) _then) = __$DraftTranslationModelCopyWithImpl;
@override @useResult
$Res call({
 String language, String title,@JsonKey(includeIfNull: true) String? subtitle, Map<String, dynamic> content
});




}
/// @nodoc
class __$DraftTranslationModelCopyWithImpl<$Res>
    implements _$DraftTranslationModelCopyWith<$Res> {
  __$DraftTranslationModelCopyWithImpl(this._self, this._then);

  final _DraftTranslationModel _self;
  final $Res Function(_DraftTranslationModel) _then;

/// Create a copy of DraftTranslationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? title = null,Object? subtitle = freezed,Object? content = null,}) {
  return _then(_DraftTranslationModel(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ArticleDraftDocumentModel {

 String get sourceLanguage; List<DraftTranslationModel> get translations;@JsonKey(includeIfNull: true) String? get fieldId;@JsonKey(includeIfNull: true) String? get topicId; List<String> get tags; List<SourceModel> get sources;@JsonKey(includeIfNull: true) String? get coverUrl;@JsonKey(includeIfNull: true) String? get versionBadge; bool get isAiAssisted; List<AttachmentItemModel> get attachments;
/// Create a copy of ArticleDraftDocumentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<ArticleDraftDocumentModel> get copyWith => _$ArticleDraftDocumentModelCopyWithImpl<ArticleDraftDocumentModel>(this as ArticleDraftDocumentModel, _$identity);

  /// Serializes this ArticleDraftDocumentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleDraftDocumentModel&&(identical(other.sourceLanguage, sourceLanguage) || other.sourceLanguage == sourceLanguage)&&const DeepCollectionEquality().equals(other.translations, translations)&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&const DeepCollectionEquality().equals(other.attachments, attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceLanguage,const DeepCollectionEquality().hash(translations),fieldId,topicId,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(sources),coverUrl,versionBadge,isAiAssisted,const DeepCollectionEquality().hash(attachments));

@override
String toString() {
  return 'ArticleDraftDocumentModel(sourceLanguage: $sourceLanguage, translations: $translations, fieldId: $fieldId, topicId: $topicId, tags: $tags, sources: $sources, coverUrl: $coverUrl, versionBadge: $versionBadge, isAiAssisted: $isAiAssisted, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $ArticleDraftDocumentModelCopyWith<$Res>  {
  factory $ArticleDraftDocumentModelCopyWith(ArticleDraftDocumentModel value, $Res Function(ArticleDraftDocumentModel) _then) = _$ArticleDraftDocumentModelCopyWithImpl;
@useResult
$Res call({
 String sourceLanguage, List<DraftTranslationModel> translations,@JsonKey(includeIfNull: true) String? fieldId,@JsonKey(includeIfNull: true) String? topicId, List<String> tags, List<SourceModel> sources,@JsonKey(includeIfNull: true) String? coverUrl,@JsonKey(includeIfNull: true) String? versionBadge, bool isAiAssisted, List<AttachmentItemModel> attachments
});




}
/// @nodoc
class _$ArticleDraftDocumentModelCopyWithImpl<$Res>
    implements $ArticleDraftDocumentModelCopyWith<$Res> {
  _$ArticleDraftDocumentModelCopyWithImpl(this._self, this._then);

  final ArticleDraftDocumentModel _self;
  final $Res Function(ArticleDraftDocumentModel) _then;

/// Create a copy of ArticleDraftDocumentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceLanguage = null,Object? translations = null,Object? fieldId = freezed,Object? topicId = freezed,Object? tags = null,Object? sources = null,Object? coverUrl = freezed,Object? versionBadge = freezed,Object? isAiAssisted = null,Object? attachments = null,}) {
  return _then(_self.copyWith(
sourceLanguage: null == sourceLanguage ? _self.sourceLanguage : sourceLanguage // ignore: cast_nullable_to_non_nullable
as String,translations: null == translations ? _self.translations : translations // ignore: cast_nullable_to_non_nullable
as List<DraftTranslationModel>,fieldId: freezed == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String?,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceModel>,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AttachmentItemModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleDraftDocumentModel].
extension ArticleDraftDocumentModelPatterns on ArticleDraftDocumentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleDraftDocumentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleDraftDocumentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleDraftDocumentModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleDraftDocumentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleDraftDocumentModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleDraftDocumentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourceLanguage,  List<DraftTranslationModel> translations, @JsonKey(includeIfNull: true)  String? fieldId, @JsonKey(includeIfNull: true)  String? topicId,  List<String> tags,  List<SourceModel> sources, @JsonKey(includeIfNull: true)  String? coverUrl, @JsonKey(includeIfNull: true)  String? versionBadge,  bool isAiAssisted,  List<AttachmentItemModel> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleDraftDocumentModel() when $default != null:
return $default(_that.sourceLanguage,_that.translations,_that.fieldId,_that.topicId,_that.tags,_that.sources,_that.coverUrl,_that.versionBadge,_that.isAiAssisted,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourceLanguage,  List<DraftTranslationModel> translations, @JsonKey(includeIfNull: true)  String? fieldId, @JsonKey(includeIfNull: true)  String? topicId,  List<String> tags,  List<SourceModel> sources, @JsonKey(includeIfNull: true)  String? coverUrl, @JsonKey(includeIfNull: true)  String? versionBadge,  bool isAiAssisted,  List<AttachmentItemModel> attachments)  $default,) {final _that = this;
switch (_that) {
case _ArticleDraftDocumentModel():
return $default(_that.sourceLanguage,_that.translations,_that.fieldId,_that.topicId,_that.tags,_that.sources,_that.coverUrl,_that.versionBadge,_that.isAiAssisted,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourceLanguage,  List<DraftTranslationModel> translations, @JsonKey(includeIfNull: true)  String? fieldId, @JsonKey(includeIfNull: true)  String? topicId,  List<String> tags,  List<SourceModel> sources, @JsonKey(includeIfNull: true)  String? coverUrl, @JsonKey(includeIfNull: true)  String? versionBadge,  bool isAiAssisted,  List<AttachmentItemModel> attachments)?  $default,) {final _that = this;
switch (_that) {
case _ArticleDraftDocumentModel() when $default != null:
return $default(_that.sourceLanguage,_that.translations,_that.fieldId,_that.topicId,_that.tags,_that.sources,_that.coverUrl,_that.versionBadge,_that.isAiAssisted,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleDraftDocumentModel extends ArticleDraftDocumentModel {
  const _ArticleDraftDocumentModel({required this.sourceLanguage, final  List<DraftTranslationModel> translations = const <DraftTranslationModel>[], @JsonKey(includeIfNull: true) this.fieldId, @JsonKey(includeIfNull: true) this.topicId, final  List<String> tags = const <String>[], final  List<SourceModel> sources = const <SourceModel>[], @JsonKey(includeIfNull: true) this.coverUrl, @JsonKey(includeIfNull: true) this.versionBadge, this.isAiAssisted = false, final  List<AttachmentItemModel> attachments = const <AttachmentItemModel>[]}): _translations = translations,_tags = tags,_sources = sources,_attachments = attachments,super._();
  factory _ArticleDraftDocumentModel.fromJson(Map<String, dynamic> json) => _$ArticleDraftDocumentModelFromJson(json);

@override final  String sourceLanguage;
 final  List<DraftTranslationModel> _translations;
@override@JsonKey() List<DraftTranslationModel> get translations {
  if (_translations is EqualUnmodifiableListView) return _translations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_translations);
}

@override@JsonKey(includeIfNull: true) final  String? fieldId;
@override@JsonKey(includeIfNull: true) final  String? topicId;
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

@override@JsonKey(includeIfNull: true) final  String? coverUrl;
@override@JsonKey(includeIfNull: true) final  String? versionBadge;
@override@JsonKey() final  bool isAiAssisted;
 final  List<AttachmentItemModel> _attachments;
@override@JsonKey() List<AttachmentItemModel> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of ArticleDraftDocumentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleDraftDocumentModelCopyWith<_ArticleDraftDocumentModel> get copyWith => __$ArticleDraftDocumentModelCopyWithImpl<_ArticleDraftDocumentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleDraftDocumentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleDraftDocumentModel&&(identical(other.sourceLanguage, sourceLanguage) || other.sourceLanguage == sourceLanguage)&&const DeepCollectionEquality().equals(other._translations, _translations)&&(identical(other.fieldId, fieldId) || other.fieldId == fieldId)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.versionBadge, versionBadge) || other.versionBadge == versionBadge)&&(identical(other.isAiAssisted, isAiAssisted) || other.isAiAssisted == isAiAssisted)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceLanguage,const DeepCollectionEquality().hash(_translations),fieldId,topicId,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_sources),coverUrl,versionBadge,isAiAssisted,const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'ArticleDraftDocumentModel(sourceLanguage: $sourceLanguage, translations: $translations, fieldId: $fieldId, topicId: $topicId, tags: $tags, sources: $sources, coverUrl: $coverUrl, versionBadge: $versionBadge, isAiAssisted: $isAiAssisted, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$ArticleDraftDocumentModelCopyWith<$Res> implements $ArticleDraftDocumentModelCopyWith<$Res> {
  factory _$ArticleDraftDocumentModelCopyWith(_ArticleDraftDocumentModel value, $Res Function(_ArticleDraftDocumentModel) _then) = __$ArticleDraftDocumentModelCopyWithImpl;
@override @useResult
$Res call({
 String sourceLanguage, List<DraftTranslationModel> translations,@JsonKey(includeIfNull: true) String? fieldId,@JsonKey(includeIfNull: true) String? topicId, List<String> tags, List<SourceModel> sources,@JsonKey(includeIfNull: true) String? coverUrl,@JsonKey(includeIfNull: true) String? versionBadge, bool isAiAssisted, List<AttachmentItemModel> attachments
});




}
/// @nodoc
class __$ArticleDraftDocumentModelCopyWithImpl<$Res>
    implements _$ArticleDraftDocumentModelCopyWith<$Res> {
  __$ArticleDraftDocumentModelCopyWithImpl(this._self, this._then);

  final _ArticleDraftDocumentModel _self;
  final $Res Function(_ArticleDraftDocumentModel) _then;

/// Create a copy of ArticleDraftDocumentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceLanguage = null,Object? translations = null,Object? fieldId = freezed,Object? topicId = freezed,Object? tags = null,Object? sources = null,Object? coverUrl = freezed,Object? versionBadge = freezed,Object? isAiAssisted = null,Object? attachments = null,}) {
  return _then(_ArticleDraftDocumentModel(
sourceLanguage: null == sourceLanguage ? _self.sourceLanguage : sourceLanguage // ignore: cast_nullable_to_non_nullable
as String,translations: null == translations ? _self._translations : translations // ignore: cast_nullable_to_non_nullable
as List<DraftTranslationModel>,fieldId: freezed == fieldId ? _self.fieldId : fieldId // ignore: cast_nullable_to_non_nullable
as String?,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceModel>,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,versionBadge: freezed == versionBadge ? _self.versionBadge : versionBadge // ignore: cast_nullable_to_non_nullable
as String?,isAiAssisted: null == isAiAssisted ? _self.isAiAssisted : isAiAssisted // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AttachmentItemModel>,
  ));
}


}


/// @nodoc
mixin _$SaveDraftRequestModel {

 int get baseVersion; ArticleDraftDocumentModel get document;
/// Create a copy of SaveDraftRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveDraftRequestModelCopyWith<SaveDraftRequestModel> get copyWith => _$SaveDraftRequestModelCopyWithImpl<SaveDraftRequestModel>(this as SaveDraftRequestModel, _$identity);

  /// Serializes this SaveDraftRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveDraftRequestModel&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion)&&(identical(other.document, document) || other.document == document));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseVersion,document);

@override
String toString() {
  return 'SaveDraftRequestModel(baseVersion: $baseVersion, document: $document)';
}


}

/// @nodoc
abstract mixin class $SaveDraftRequestModelCopyWith<$Res>  {
  factory $SaveDraftRequestModelCopyWith(SaveDraftRequestModel value, $Res Function(SaveDraftRequestModel) _then) = _$SaveDraftRequestModelCopyWithImpl;
@useResult
$Res call({
 int baseVersion, ArticleDraftDocumentModel document
});


$ArticleDraftDocumentModelCopyWith<$Res> get document;

}
/// @nodoc
class _$SaveDraftRequestModelCopyWithImpl<$Res>
    implements $SaveDraftRequestModelCopyWith<$Res> {
  _$SaveDraftRequestModelCopyWithImpl(this._self, this._then);

  final SaveDraftRequestModel _self;
  final $Res Function(SaveDraftRequestModel) _then;

/// Create a copy of SaveDraftRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseVersion = null,Object? document = null,}) {
  return _then(_self.copyWith(
baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ArticleDraftDocumentModel,
  ));
}
/// Create a copy of SaveDraftRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<$Res> get document {
  
  return $ArticleDraftDocumentModelCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [SaveDraftRequestModel].
extension SaveDraftRequestModelPatterns on SaveDraftRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveDraftRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveDraftRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveDraftRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _SaveDraftRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveDraftRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _SaveDraftRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int baseVersion,  ArticleDraftDocumentModel document)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveDraftRequestModel() when $default != null:
return $default(_that.baseVersion,_that.document);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int baseVersion,  ArticleDraftDocumentModel document)  $default,) {final _that = this;
switch (_that) {
case _SaveDraftRequestModel():
return $default(_that.baseVersion,_that.document);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int baseVersion,  ArticleDraftDocumentModel document)?  $default,) {final _that = this;
switch (_that) {
case _SaveDraftRequestModel() when $default != null:
return $default(_that.baseVersion,_that.document);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaveDraftRequestModel implements SaveDraftRequestModel {
  const _SaveDraftRequestModel({required this.baseVersion, required this.document});
  factory _SaveDraftRequestModel.fromJson(Map<String, dynamic> json) => _$SaveDraftRequestModelFromJson(json);

@override final  int baseVersion;
@override final  ArticleDraftDocumentModel document;

/// Create a copy of SaveDraftRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveDraftRequestModelCopyWith<_SaveDraftRequestModel> get copyWith => __$SaveDraftRequestModelCopyWithImpl<_SaveDraftRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveDraftRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveDraftRequestModel&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion)&&(identical(other.document, document) || other.document == document));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseVersion,document);

@override
String toString() {
  return 'SaveDraftRequestModel(baseVersion: $baseVersion, document: $document)';
}


}

/// @nodoc
abstract mixin class _$SaveDraftRequestModelCopyWith<$Res> implements $SaveDraftRequestModelCopyWith<$Res> {
  factory _$SaveDraftRequestModelCopyWith(_SaveDraftRequestModel value, $Res Function(_SaveDraftRequestModel) _then) = __$SaveDraftRequestModelCopyWithImpl;
@override @useResult
$Res call({
 int baseVersion, ArticleDraftDocumentModel document
});


@override $ArticleDraftDocumentModelCopyWith<$Res> get document;

}
/// @nodoc
class __$SaveDraftRequestModelCopyWithImpl<$Res>
    implements _$SaveDraftRequestModelCopyWith<$Res> {
  __$SaveDraftRequestModelCopyWithImpl(this._self, this._then);

  final _SaveDraftRequestModel _self;
  final $Res Function(_SaveDraftRequestModel) _then;

/// Create a copy of SaveDraftRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseVersion = null,Object? document = null,}) {
  return _then(_SaveDraftRequestModel(
baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ArticleDraftDocumentModel,
  ));
}

/// Create a copy of SaveDraftRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<$Res> get document {
  
  return $ArticleDraftDocumentModelCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// @nodoc
mixin _$BaseVersionRequestModel {

 int get baseVersion;
/// Create a copy of BaseVersionRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BaseVersionRequestModelCopyWith<BaseVersionRequestModel> get copyWith => _$BaseVersionRequestModelCopyWithImpl<BaseVersionRequestModel>(this as BaseVersionRequestModel, _$identity);

  /// Serializes this BaseVersionRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BaseVersionRequestModel&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseVersion);

@override
String toString() {
  return 'BaseVersionRequestModel(baseVersion: $baseVersion)';
}


}

/// @nodoc
abstract mixin class $BaseVersionRequestModelCopyWith<$Res>  {
  factory $BaseVersionRequestModelCopyWith(BaseVersionRequestModel value, $Res Function(BaseVersionRequestModel) _then) = _$BaseVersionRequestModelCopyWithImpl;
@useResult
$Res call({
 int baseVersion
});




}
/// @nodoc
class _$BaseVersionRequestModelCopyWithImpl<$Res>
    implements $BaseVersionRequestModelCopyWith<$Res> {
  _$BaseVersionRequestModelCopyWithImpl(this._self, this._then);

  final BaseVersionRequestModel _self;
  final $Res Function(BaseVersionRequestModel) _then;

/// Create a copy of BaseVersionRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseVersion = null,}) {
  return _then(_self.copyWith(
baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BaseVersionRequestModel].
extension BaseVersionRequestModelPatterns on BaseVersionRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BaseVersionRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BaseVersionRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BaseVersionRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _BaseVersionRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BaseVersionRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _BaseVersionRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int baseVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BaseVersionRequestModel() when $default != null:
return $default(_that.baseVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int baseVersion)  $default,) {final _that = this;
switch (_that) {
case _BaseVersionRequestModel():
return $default(_that.baseVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int baseVersion)?  $default,) {final _that = this;
switch (_that) {
case _BaseVersionRequestModel() when $default != null:
return $default(_that.baseVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BaseVersionRequestModel implements BaseVersionRequestModel {
  const _BaseVersionRequestModel({required this.baseVersion});
  factory _BaseVersionRequestModel.fromJson(Map<String, dynamic> json) => _$BaseVersionRequestModelFromJson(json);

@override final  int baseVersion;

/// Create a copy of BaseVersionRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BaseVersionRequestModelCopyWith<_BaseVersionRequestModel> get copyWith => __$BaseVersionRequestModelCopyWithImpl<_BaseVersionRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BaseVersionRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BaseVersionRequestModel&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseVersion);

@override
String toString() {
  return 'BaseVersionRequestModel(baseVersion: $baseVersion)';
}


}

/// @nodoc
abstract mixin class _$BaseVersionRequestModelCopyWith<$Res> implements $BaseVersionRequestModelCopyWith<$Res> {
  factory _$BaseVersionRequestModelCopyWith(_BaseVersionRequestModel value, $Res Function(_BaseVersionRequestModel) _then) = __$BaseVersionRequestModelCopyWithImpl;
@override @useResult
$Res call({
 int baseVersion
});




}
/// @nodoc
class __$BaseVersionRequestModelCopyWithImpl<$Res>
    implements _$BaseVersionRequestModelCopyWith<$Res> {
  __$BaseVersionRequestModelCopyWithImpl(this._self, this._then);

  final _BaseVersionRequestModel _self;
  final $Res Function(_BaseVersionRequestModel) _then;

/// Create a copy of BaseVersionRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseVersion = null,}) {
  return _then(_BaseVersionRequestModel(
baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ReadingTimeModel {

 String get language; int get minutes; int get words;
/// Create a copy of ReadingTimeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingTimeModelCopyWith<ReadingTimeModel> get copyWith => _$ReadingTimeModelCopyWithImpl<ReadingTimeModel>(this as ReadingTimeModel, _$identity);

  /// Serializes this ReadingTimeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingTimeModel&&(identical(other.language, language) || other.language == language)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.words, words) || other.words == words));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,minutes,words);

@override
String toString() {
  return 'ReadingTimeModel(language: $language, minutes: $minutes, words: $words)';
}


}

/// @nodoc
abstract mixin class $ReadingTimeModelCopyWith<$Res>  {
  factory $ReadingTimeModelCopyWith(ReadingTimeModel value, $Res Function(ReadingTimeModel) _then) = _$ReadingTimeModelCopyWithImpl;
@useResult
$Res call({
 String language, int minutes, int words
});




}
/// @nodoc
class _$ReadingTimeModelCopyWithImpl<$Res>
    implements $ReadingTimeModelCopyWith<$Res> {
  _$ReadingTimeModelCopyWithImpl(this._self, this._then);

  final ReadingTimeModel _self;
  final $Res Function(ReadingTimeModel) _then;

/// Create a copy of ReadingTimeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? minutes = null,Object? words = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self.words : words // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingTimeModel].
extension ReadingTimeModelPatterns on ReadingTimeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingTimeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingTimeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingTimeModel value)  $default,){
final _that = this;
switch (_that) {
case _ReadingTimeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingTimeModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingTimeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  int minutes,  int words)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingTimeModel() when $default != null:
return $default(_that.language,_that.minutes,_that.words);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  int minutes,  int words)  $default,) {final _that = this;
switch (_that) {
case _ReadingTimeModel():
return $default(_that.language,_that.minutes,_that.words);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  int minutes,  int words)?  $default,) {final _that = this;
switch (_that) {
case _ReadingTimeModel() when $default != null:
return $default(_that.language,_that.minutes,_that.words);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingTimeModel extends ReadingTimeModel {
  const _ReadingTimeModel({required this.language, this.minutes = 0, this.words = 0}): super._();
  factory _ReadingTimeModel.fromJson(Map<String, dynamic> json) => _$ReadingTimeModelFromJson(json);

@override final  String language;
@override@JsonKey() final  int minutes;
@override@JsonKey() final  int words;

/// Create a copy of ReadingTimeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingTimeModelCopyWith<_ReadingTimeModel> get copyWith => __$ReadingTimeModelCopyWithImpl<_ReadingTimeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingTimeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingTimeModel&&(identical(other.language, language) || other.language == language)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.words, words) || other.words == words));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,minutes,words);

@override
String toString() {
  return 'ReadingTimeModel(language: $language, minutes: $minutes, words: $words)';
}


}

/// @nodoc
abstract mixin class _$ReadingTimeModelCopyWith<$Res> implements $ReadingTimeModelCopyWith<$Res> {
  factory _$ReadingTimeModelCopyWith(_ReadingTimeModel value, $Res Function(_ReadingTimeModel) _then) = __$ReadingTimeModelCopyWithImpl;
@override @useResult
$Res call({
 String language, int minutes, int words
});




}
/// @nodoc
class __$ReadingTimeModelCopyWithImpl<$Res>
    implements _$ReadingTimeModelCopyWith<$Res> {
  __$ReadingTimeModelCopyWithImpl(this._self, this._then);

  final _ReadingTimeModel _self;
  final $Res Function(_ReadingTimeModel) _then;

/// Create a copy of ReadingTimeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? minutes = null,Object? words = null,}) {
  return _then(_ReadingTimeModel(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self.words : words // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DraftProblemModel {

 String get code; String? get language; String? get blockId; String? get mediaAssetId; String? get tag;
/// Create a copy of DraftProblemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftProblemModelCopyWith<DraftProblemModel> get copyWith => _$DraftProblemModelCopyWithImpl<DraftProblemModel>(this as DraftProblemModel, _$identity);

  /// Serializes this DraftProblemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftProblemModel&&(identical(other.code, code) || other.code == code)&&(identical(other.language, language) || other.language == language)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.mediaAssetId, mediaAssetId) || other.mediaAssetId == mediaAssetId)&&(identical(other.tag, tag) || other.tag == tag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,language,blockId,mediaAssetId,tag);

@override
String toString() {
  return 'DraftProblemModel(code: $code, language: $language, blockId: $blockId, mediaAssetId: $mediaAssetId, tag: $tag)';
}


}

/// @nodoc
abstract mixin class $DraftProblemModelCopyWith<$Res>  {
  factory $DraftProblemModelCopyWith(DraftProblemModel value, $Res Function(DraftProblemModel) _then) = _$DraftProblemModelCopyWithImpl;
@useResult
$Res call({
 String code, String? language, String? blockId, String? mediaAssetId, String? tag
});




}
/// @nodoc
class _$DraftProblemModelCopyWithImpl<$Res>
    implements $DraftProblemModelCopyWith<$Res> {
  _$DraftProblemModelCopyWithImpl(this._self, this._then);

  final DraftProblemModel _self;
  final $Res Function(DraftProblemModel) _then;

/// Create a copy of DraftProblemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? language = freezed,Object? blockId = freezed,Object? mediaAssetId = freezed,Object? tag = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,blockId: freezed == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String?,mediaAssetId: freezed == mediaAssetId ? _self.mediaAssetId : mediaAssetId // ignore: cast_nullable_to_non_nullable
as String?,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftProblemModel].
extension DraftProblemModelPatterns on DraftProblemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftProblemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftProblemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftProblemModel value)  $default,){
final _that = this;
switch (_that) {
case _DraftProblemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftProblemModel value)?  $default,){
final _that = this;
switch (_that) {
case _DraftProblemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String? language,  String? blockId,  String? mediaAssetId,  String? tag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraftProblemModel() when $default != null:
return $default(_that.code,_that.language,_that.blockId,_that.mediaAssetId,_that.tag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String? language,  String? blockId,  String? mediaAssetId,  String? tag)  $default,) {final _that = this;
switch (_that) {
case _DraftProblemModel():
return $default(_that.code,_that.language,_that.blockId,_that.mediaAssetId,_that.tag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String? language,  String? blockId,  String? mediaAssetId,  String? tag)?  $default,) {final _that = this;
switch (_that) {
case _DraftProblemModel() when $default != null:
return $default(_that.code,_that.language,_that.blockId,_that.mediaAssetId,_that.tag);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftProblemModel extends DraftProblemModel {
  const _DraftProblemModel({required this.code, this.language, this.blockId, this.mediaAssetId, this.tag}): super._();
  factory _DraftProblemModel.fromJson(Map<String, dynamic> json) => _$DraftProblemModelFromJson(json);

@override final  String code;
@override final  String? language;
@override final  String? blockId;
@override final  String? mediaAssetId;
@override final  String? tag;

/// Create a copy of DraftProblemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftProblemModelCopyWith<_DraftProblemModel> get copyWith => __$DraftProblemModelCopyWithImpl<_DraftProblemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftProblemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftProblemModel&&(identical(other.code, code) || other.code == code)&&(identical(other.language, language) || other.language == language)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.mediaAssetId, mediaAssetId) || other.mediaAssetId == mediaAssetId)&&(identical(other.tag, tag) || other.tag == tag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,language,blockId,mediaAssetId,tag);

@override
String toString() {
  return 'DraftProblemModel(code: $code, language: $language, blockId: $blockId, mediaAssetId: $mediaAssetId, tag: $tag)';
}


}

/// @nodoc
abstract mixin class _$DraftProblemModelCopyWith<$Res> implements $DraftProblemModelCopyWith<$Res> {
  factory _$DraftProblemModelCopyWith(_DraftProblemModel value, $Res Function(_DraftProblemModel) _then) = __$DraftProblemModelCopyWithImpl;
@override @useResult
$Res call({
 String code, String? language, String? blockId, String? mediaAssetId, String? tag
});




}
/// @nodoc
class __$DraftProblemModelCopyWithImpl<$Res>
    implements _$DraftProblemModelCopyWith<$Res> {
  __$DraftProblemModelCopyWithImpl(this._self, this._then);

  final _DraftProblemModel _self;
  final $Res Function(_DraftProblemModel) _then;

/// Create a copy of DraftProblemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? language = freezed,Object? blockId = freezed,Object? mediaAssetId = freezed,Object? tag = freezed,}) {
  return _then(_DraftProblemModel(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,blockId: freezed == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String?,mediaAssetId: freezed == mediaAssetId ? _self.mediaAssetId : mediaAssetId // ignore: cast_nullable_to_non_nullable
as String?,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DraftChecksModel {

 List<ReadingTimeModel> get readingTime; List<DraftProblemModel> get problems;
/// Create a copy of DraftChecksModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftChecksModelCopyWith<DraftChecksModel> get copyWith => _$DraftChecksModelCopyWithImpl<DraftChecksModel>(this as DraftChecksModel, _$identity);

  /// Serializes this DraftChecksModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftChecksModel&&const DeepCollectionEquality().equals(other.readingTime, readingTime)&&const DeepCollectionEquality().equals(other.problems, problems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(readingTime),const DeepCollectionEquality().hash(problems));

@override
String toString() {
  return 'DraftChecksModel(readingTime: $readingTime, problems: $problems)';
}


}

/// @nodoc
abstract mixin class $DraftChecksModelCopyWith<$Res>  {
  factory $DraftChecksModelCopyWith(DraftChecksModel value, $Res Function(DraftChecksModel) _then) = _$DraftChecksModelCopyWithImpl;
@useResult
$Res call({
 List<ReadingTimeModel> readingTime, List<DraftProblemModel> problems
});




}
/// @nodoc
class _$DraftChecksModelCopyWithImpl<$Res>
    implements $DraftChecksModelCopyWith<$Res> {
  _$DraftChecksModelCopyWithImpl(this._self, this._then);

  final DraftChecksModel _self;
  final $Res Function(DraftChecksModel) _then;

/// Create a copy of DraftChecksModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readingTime = null,Object? problems = null,}) {
  return _then(_self.copyWith(
readingTime: null == readingTime ? _self.readingTime : readingTime // ignore: cast_nullable_to_non_nullable
as List<ReadingTimeModel>,problems: null == problems ? _self.problems : problems // ignore: cast_nullable_to_non_nullable
as List<DraftProblemModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftChecksModel].
extension DraftChecksModelPatterns on DraftChecksModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftChecksModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftChecksModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftChecksModel value)  $default,){
final _that = this;
switch (_that) {
case _DraftChecksModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftChecksModel value)?  $default,){
final _that = this;
switch (_that) {
case _DraftChecksModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ReadingTimeModel> readingTime,  List<DraftProblemModel> problems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraftChecksModel() when $default != null:
return $default(_that.readingTime,_that.problems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ReadingTimeModel> readingTime,  List<DraftProblemModel> problems)  $default,) {final _that = this;
switch (_that) {
case _DraftChecksModel():
return $default(_that.readingTime,_that.problems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ReadingTimeModel> readingTime,  List<DraftProblemModel> problems)?  $default,) {final _that = this;
switch (_that) {
case _DraftChecksModel() when $default != null:
return $default(_that.readingTime,_that.problems);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftChecksModel extends DraftChecksModel {
  const _DraftChecksModel({final  List<ReadingTimeModel> readingTime = const <ReadingTimeModel>[], final  List<DraftProblemModel> problems = const <DraftProblemModel>[]}): _readingTime = readingTime,_problems = problems,super._();
  factory _DraftChecksModel.fromJson(Map<String, dynamic> json) => _$DraftChecksModelFromJson(json);

 final  List<ReadingTimeModel> _readingTime;
@override@JsonKey() List<ReadingTimeModel> get readingTime {
  if (_readingTime is EqualUnmodifiableListView) return _readingTime;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readingTime);
}

 final  List<DraftProblemModel> _problems;
@override@JsonKey() List<DraftProblemModel> get problems {
  if (_problems is EqualUnmodifiableListView) return _problems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_problems);
}


/// Create a copy of DraftChecksModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftChecksModelCopyWith<_DraftChecksModel> get copyWith => __$DraftChecksModelCopyWithImpl<_DraftChecksModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftChecksModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftChecksModel&&const DeepCollectionEquality().equals(other._readingTime, _readingTime)&&const DeepCollectionEquality().equals(other._problems, _problems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_readingTime),const DeepCollectionEquality().hash(_problems));

@override
String toString() {
  return 'DraftChecksModel(readingTime: $readingTime, problems: $problems)';
}


}

/// @nodoc
abstract mixin class _$DraftChecksModelCopyWith<$Res> implements $DraftChecksModelCopyWith<$Res> {
  factory _$DraftChecksModelCopyWith(_DraftChecksModel value, $Res Function(_DraftChecksModel) _then) = __$DraftChecksModelCopyWithImpl;
@override @useResult
$Res call({
 List<ReadingTimeModel> readingTime, List<DraftProblemModel> problems
});




}
/// @nodoc
class __$DraftChecksModelCopyWithImpl<$Res>
    implements _$DraftChecksModelCopyWith<$Res> {
  __$DraftChecksModelCopyWithImpl(this._self, this._then);

  final _DraftChecksModel _self;
  final $Res Function(_DraftChecksModel) _then;

/// Create a copy of DraftChecksModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readingTime = null,Object? problems = null,}) {
  return _then(_DraftChecksModel(
readingTime: null == readingTime ? _self._readingTime : readingTime // ignore: cast_nullable_to_non_nullable
as List<ReadingTimeModel>,problems: null == problems ? _self._problems : problems // ignore: cast_nullable_to_non_nullable
as List<DraftProblemModel>,
  ));
}


}


/// @nodoc
mixin _$ArticleEditModel {

 String get id; String get status; String? get slug; DateTime? get publishedAt; int get version; DateTime? get savedAt; bool get hasUnpublishedChanges; ArticleDraftDocumentModel get document; List<MediaAssetModel> get media; DraftChecksModel get checks;
/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleEditModelCopyWith<ArticleEditModel> get copyWith => _$ArticleEditModelCopyWithImpl<ArticleEditModel>(this as ArticleEditModel, _$identity);

  /// Serializes this ArticleEditModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleEditModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.hasUnpublishedChanges, hasUnpublishedChanges) || other.hasUnpublishedChanges == hasUnpublishedChanges)&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other.media, media)&&(identical(other.checks, checks) || other.checks == checks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,slug,publishedAt,version,savedAt,hasUnpublishedChanges,document,const DeepCollectionEquality().hash(media),checks);

@override
String toString() {
  return 'ArticleEditModel(id: $id, status: $status, slug: $slug, publishedAt: $publishedAt, version: $version, savedAt: $savedAt, hasUnpublishedChanges: $hasUnpublishedChanges, document: $document, media: $media, checks: $checks)';
}


}

/// @nodoc
abstract mixin class $ArticleEditModelCopyWith<$Res>  {
  factory $ArticleEditModelCopyWith(ArticleEditModel value, $Res Function(ArticleEditModel) _then) = _$ArticleEditModelCopyWithImpl;
@useResult
$Res call({
 String id, String status, String? slug, DateTime? publishedAt, int version, DateTime? savedAt, bool hasUnpublishedChanges, ArticleDraftDocumentModel document, List<MediaAssetModel> media, DraftChecksModel checks
});


$ArticleDraftDocumentModelCopyWith<$Res> get document;$DraftChecksModelCopyWith<$Res> get checks;

}
/// @nodoc
class _$ArticleEditModelCopyWithImpl<$Res>
    implements $ArticleEditModelCopyWith<$Res> {
  _$ArticleEditModelCopyWithImpl(this._self, this._then);

  final ArticleEditModel _self;
  final $Res Function(ArticleEditModel) _then;

/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? slug = freezed,Object? publishedAt = freezed,Object? version = null,Object? savedAt = freezed,Object? hasUnpublishedChanges = null,Object? document = null,Object? media = null,Object? checks = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasUnpublishedChanges: null == hasUnpublishedChanges ? _self.hasUnpublishedChanges : hasUnpublishedChanges // ignore: cast_nullable_to_non_nullable
as bool,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ArticleDraftDocumentModel,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<MediaAssetModel>,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as DraftChecksModel,
  ));
}
/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<$Res> get document {
  
  return $ArticleDraftDocumentModelCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftChecksModelCopyWith<$Res> get checks {
  
  return $DraftChecksModelCopyWith<$Res>(_self.checks, (value) {
    return _then(_self.copyWith(checks: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleEditModel].
extension ArticleEditModelPatterns on ArticleEditModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleEditModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleEditModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleEditModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleEditModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleEditModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleEditModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  String? slug,  DateTime? publishedAt,  int version,  DateTime? savedAt,  bool hasUnpublishedChanges,  ArticleDraftDocumentModel document,  List<MediaAssetModel> media,  DraftChecksModel checks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleEditModel() when $default != null:
return $default(_that.id,_that.status,_that.slug,_that.publishedAt,_that.version,_that.savedAt,_that.hasUnpublishedChanges,_that.document,_that.media,_that.checks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  String? slug,  DateTime? publishedAt,  int version,  DateTime? savedAt,  bool hasUnpublishedChanges,  ArticleDraftDocumentModel document,  List<MediaAssetModel> media,  DraftChecksModel checks)  $default,) {final _that = this;
switch (_that) {
case _ArticleEditModel():
return $default(_that.id,_that.status,_that.slug,_that.publishedAt,_that.version,_that.savedAt,_that.hasUnpublishedChanges,_that.document,_that.media,_that.checks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  String? slug,  DateTime? publishedAt,  int version,  DateTime? savedAt,  bool hasUnpublishedChanges,  ArticleDraftDocumentModel document,  List<MediaAssetModel> media,  DraftChecksModel checks)?  $default,) {final _that = this;
switch (_that) {
case _ArticleEditModel() when $default != null:
return $default(_that.id,_that.status,_that.slug,_that.publishedAt,_that.version,_that.savedAt,_that.hasUnpublishedChanges,_that.document,_that.media,_that.checks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleEditModel extends ArticleEditModel {
  const _ArticleEditModel({required this.id, this.status = 'draft', this.slug, this.publishedAt, this.version = 1, this.savedAt, this.hasUnpublishedChanges = false, required this.document, final  List<MediaAssetModel> media = const <MediaAssetModel>[], this.checks = const DraftChecksModel()}): _media = media,super._();
  factory _ArticleEditModel.fromJson(Map<String, dynamic> json) => _$ArticleEditModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String status;
@override final  String? slug;
@override final  DateTime? publishedAt;
@override@JsonKey() final  int version;
@override final  DateTime? savedAt;
@override@JsonKey() final  bool hasUnpublishedChanges;
@override final  ArticleDraftDocumentModel document;
 final  List<MediaAssetModel> _media;
@override@JsonKey() List<MediaAssetModel> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override@JsonKey() final  DraftChecksModel checks;

/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleEditModelCopyWith<_ArticleEditModel> get copyWith => __$ArticleEditModelCopyWithImpl<_ArticleEditModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleEditModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleEditModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.hasUnpublishedChanges, hasUnpublishedChanges) || other.hasUnpublishedChanges == hasUnpublishedChanges)&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other._media, _media)&&(identical(other.checks, checks) || other.checks == checks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,slug,publishedAt,version,savedAt,hasUnpublishedChanges,document,const DeepCollectionEquality().hash(_media),checks);

@override
String toString() {
  return 'ArticleEditModel(id: $id, status: $status, slug: $slug, publishedAt: $publishedAt, version: $version, savedAt: $savedAt, hasUnpublishedChanges: $hasUnpublishedChanges, document: $document, media: $media, checks: $checks)';
}


}

/// @nodoc
abstract mixin class _$ArticleEditModelCopyWith<$Res> implements $ArticleEditModelCopyWith<$Res> {
  factory _$ArticleEditModelCopyWith(_ArticleEditModel value, $Res Function(_ArticleEditModel) _then) = __$ArticleEditModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, String? slug, DateTime? publishedAt, int version, DateTime? savedAt, bool hasUnpublishedChanges, ArticleDraftDocumentModel document, List<MediaAssetModel> media, DraftChecksModel checks
});


@override $ArticleDraftDocumentModelCopyWith<$Res> get document;@override $DraftChecksModelCopyWith<$Res> get checks;

}
/// @nodoc
class __$ArticleEditModelCopyWithImpl<$Res>
    implements _$ArticleEditModelCopyWith<$Res> {
  __$ArticleEditModelCopyWithImpl(this._self, this._then);

  final _ArticleEditModel _self;
  final $Res Function(_ArticleEditModel) _then;

/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? slug = freezed,Object? publishedAt = freezed,Object? version = null,Object? savedAt = freezed,Object? hasUnpublishedChanges = null,Object? document = null,Object? media = null,Object? checks = null,}) {
  return _then(_ArticleEditModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasUnpublishedChanges: null == hasUnpublishedChanges ? _self.hasUnpublishedChanges : hasUnpublishedChanges // ignore: cast_nullable_to_non_nullable
as bool,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ArticleDraftDocumentModel,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<MediaAssetModel>,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as DraftChecksModel,
  ));
}

/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<$Res> get document {
  
  return $ArticleDraftDocumentModelCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}/// Create a copy of ArticleEditModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftChecksModelCopyWith<$Res> get checks {
  
  return $DraftChecksModelCopyWith<$Res>(_self.checks, (value) {
    return _then(_self.copyWith(checks: value));
  });
}
}


/// @nodoc
mixin _$PublishedArticleModel {

 String get id; String get slug; DateTime get publishedAt; int get revision; bool get firstPublish;
/// Create a copy of PublishedArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublishedArticleModelCopyWith<PublishedArticleModel> get copyWith => _$PublishedArticleModelCopyWithImpl<PublishedArticleModel>(this as PublishedArticleModel, _$identity);

  /// Serializes this PublishedArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublishedArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.firstPublish, firstPublish) || other.firstPublish == firstPublish));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,publishedAt,revision,firstPublish);

@override
String toString() {
  return 'PublishedArticleModel(id: $id, slug: $slug, publishedAt: $publishedAt, revision: $revision, firstPublish: $firstPublish)';
}


}

/// @nodoc
abstract mixin class $PublishedArticleModelCopyWith<$Res>  {
  factory $PublishedArticleModelCopyWith(PublishedArticleModel value, $Res Function(PublishedArticleModel) _then) = _$PublishedArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, DateTime publishedAt, int revision, bool firstPublish
});




}
/// @nodoc
class _$PublishedArticleModelCopyWithImpl<$Res>
    implements $PublishedArticleModelCopyWith<$Res> {
  _$PublishedArticleModelCopyWithImpl(this._self, this._then);

  final PublishedArticleModel _self;
  final $Res Function(PublishedArticleModel) _then;

/// Create a copy of PublishedArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? publishedAt = null,Object? revision = null,Object? firstPublish = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,firstPublish: null == firstPublish ? _self.firstPublish : firstPublish // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PublishedArticleModel].
extension PublishedArticleModelPatterns on PublishedArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublishedArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublishedArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublishedArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _PublishedArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublishedArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _PublishedArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  DateTime publishedAt,  int revision,  bool firstPublish)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublishedArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.publishedAt,_that.revision,_that.firstPublish);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  DateTime publishedAt,  int revision,  bool firstPublish)  $default,) {final _that = this;
switch (_that) {
case _PublishedArticleModel():
return $default(_that.id,_that.slug,_that.publishedAt,_that.revision,_that.firstPublish);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  DateTime publishedAt,  int revision,  bool firstPublish)?  $default,) {final _that = this;
switch (_that) {
case _PublishedArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.publishedAt,_that.revision,_that.firstPublish);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublishedArticleModel extends PublishedArticleModel {
  const _PublishedArticleModel({required this.id, required this.slug, required this.publishedAt, this.revision = 1, this.firstPublish = false}): super._();
  factory _PublishedArticleModel.fromJson(Map<String, dynamic> json) => _$PublishedArticleModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  DateTime publishedAt;
@override@JsonKey() final  int revision;
@override@JsonKey() final  bool firstPublish;

/// Create a copy of PublishedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublishedArticleModelCopyWith<_PublishedArticleModel> get copyWith => __$PublishedArticleModelCopyWithImpl<_PublishedArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublishedArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublishedArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.firstPublish, firstPublish) || other.firstPublish == firstPublish));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,publishedAt,revision,firstPublish);

@override
String toString() {
  return 'PublishedArticleModel(id: $id, slug: $slug, publishedAt: $publishedAt, revision: $revision, firstPublish: $firstPublish)';
}


}

/// @nodoc
abstract mixin class _$PublishedArticleModelCopyWith<$Res> implements $PublishedArticleModelCopyWith<$Res> {
  factory _$PublishedArticleModelCopyWith(_PublishedArticleModel value, $Res Function(_PublishedArticleModel) _then) = __$PublishedArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, DateTime publishedAt, int revision, bool firstPublish
});




}
/// @nodoc
class __$PublishedArticleModelCopyWithImpl<$Res>
    implements _$PublishedArticleModelCopyWith<$Res> {
  __$PublishedArticleModelCopyWithImpl(this._self, this._then);

  final _PublishedArticleModel _self;
  final $Res Function(_PublishedArticleModel) _then;

/// Create a copy of PublishedArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? publishedAt = null,Object? revision = null,Object? firstPublish = null,}) {
  return _then(_PublishedArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,firstPublish: null == firstPublish ? _self.firstPublish : firstPublish // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ArticleRevisionModel {

 int get number; DateTime get createdAt; String get title; List<String> get languages;
/// Create a copy of ArticleRevisionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleRevisionModelCopyWith<ArticleRevisionModel> get copyWith => _$ArticleRevisionModelCopyWithImpl<ArticleRevisionModel>(this as ArticleRevisionModel, _$identity);

  /// Serializes this ArticleRevisionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleRevisionModel&&(identical(other.number, number) || other.number == number)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.languages, languages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,createdAt,title,const DeepCollectionEquality().hash(languages));

@override
String toString() {
  return 'ArticleRevisionModel(number: $number, createdAt: $createdAt, title: $title, languages: $languages)';
}


}

/// @nodoc
abstract mixin class $ArticleRevisionModelCopyWith<$Res>  {
  factory $ArticleRevisionModelCopyWith(ArticleRevisionModel value, $Res Function(ArticleRevisionModel) _then) = _$ArticleRevisionModelCopyWithImpl;
@useResult
$Res call({
 int number, DateTime createdAt, String title, List<String> languages
});




}
/// @nodoc
class _$ArticleRevisionModelCopyWithImpl<$Res>
    implements $ArticleRevisionModelCopyWith<$Res> {
  _$ArticleRevisionModelCopyWithImpl(this._self, this._then);

  final ArticleRevisionModel _self;
  final $Res Function(ArticleRevisionModel) _then;

/// Create a copy of ArticleRevisionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? createdAt = null,Object? title = null,Object? languages = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleRevisionModel].
extension ArticleRevisionModelPatterns on ArticleRevisionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleRevisionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleRevisionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleRevisionModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleRevisionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleRevisionModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleRevisionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  DateTime createdAt,  String title,  List<String> languages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleRevisionModel() when $default != null:
return $default(_that.number,_that.createdAt,_that.title,_that.languages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  DateTime createdAt,  String title,  List<String> languages)  $default,) {final _that = this;
switch (_that) {
case _ArticleRevisionModel():
return $default(_that.number,_that.createdAt,_that.title,_that.languages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  DateTime createdAt,  String title,  List<String> languages)?  $default,) {final _that = this;
switch (_that) {
case _ArticleRevisionModel() when $default != null:
return $default(_that.number,_that.createdAt,_that.title,_that.languages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleRevisionModel extends ArticleRevisionModel {
  const _ArticleRevisionModel({required this.number, required this.createdAt, this.title = '', final  List<String> languages = const <String>[]}): _languages = languages,super._();
  factory _ArticleRevisionModel.fromJson(Map<String, dynamic> json) => _$ArticleRevisionModelFromJson(json);

@override final  int number;
@override final  DateTime createdAt;
@override@JsonKey() final  String title;
 final  List<String> _languages;
@override@JsonKey() List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}


/// Create a copy of ArticleRevisionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleRevisionModelCopyWith<_ArticleRevisionModel> get copyWith => __$ArticleRevisionModelCopyWithImpl<_ArticleRevisionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleRevisionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleRevisionModel&&(identical(other.number, number) || other.number == number)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._languages, _languages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,createdAt,title,const DeepCollectionEquality().hash(_languages));

@override
String toString() {
  return 'ArticleRevisionModel(number: $number, createdAt: $createdAt, title: $title, languages: $languages)';
}


}

/// @nodoc
abstract mixin class _$ArticleRevisionModelCopyWith<$Res> implements $ArticleRevisionModelCopyWith<$Res> {
  factory _$ArticleRevisionModelCopyWith(_ArticleRevisionModel value, $Res Function(_ArticleRevisionModel) _then) = __$ArticleRevisionModelCopyWithImpl;
@override @useResult
$Res call({
 int number, DateTime createdAt, String title, List<String> languages
});




}
/// @nodoc
class __$ArticleRevisionModelCopyWithImpl<$Res>
    implements _$ArticleRevisionModelCopyWith<$Res> {
  __$ArticleRevisionModelCopyWithImpl(this._self, this._then);

  final _ArticleRevisionModel _self;
  final $Res Function(_ArticleRevisionModel) _then;

/// Create a copy of ArticleRevisionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? createdAt = null,Object? title = null,Object? languages = null,}) {
  return _then(_ArticleRevisionModel(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ArticleRevisionDetailsModel {

 int get number; DateTime get createdAt; String get title; List<String> get languages; ArticleDraftDocumentModel get document; List<MediaAssetModel> get media;
/// Create a copy of ArticleRevisionDetailsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleRevisionDetailsModelCopyWith<ArticleRevisionDetailsModel> get copyWith => _$ArticleRevisionDetailsModelCopyWithImpl<ArticleRevisionDetailsModel>(this as ArticleRevisionDetailsModel, _$identity);

  /// Serializes this ArticleRevisionDetailsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleRevisionDetailsModel&&(identical(other.number, number) || other.number == number)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.languages, languages)&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other.media, media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,createdAt,title,const DeepCollectionEquality().hash(languages),document,const DeepCollectionEquality().hash(media));

@override
String toString() {
  return 'ArticleRevisionDetailsModel(number: $number, createdAt: $createdAt, title: $title, languages: $languages, document: $document, media: $media)';
}


}

/// @nodoc
abstract mixin class $ArticleRevisionDetailsModelCopyWith<$Res>  {
  factory $ArticleRevisionDetailsModelCopyWith(ArticleRevisionDetailsModel value, $Res Function(ArticleRevisionDetailsModel) _then) = _$ArticleRevisionDetailsModelCopyWithImpl;
@useResult
$Res call({
 int number, DateTime createdAt, String title, List<String> languages, ArticleDraftDocumentModel document, List<MediaAssetModel> media
});


$ArticleDraftDocumentModelCopyWith<$Res> get document;

}
/// @nodoc
class _$ArticleRevisionDetailsModelCopyWithImpl<$Res>
    implements $ArticleRevisionDetailsModelCopyWith<$Res> {
  _$ArticleRevisionDetailsModelCopyWithImpl(this._self, this._then);

  final ArticleRevisionDetailsModel _self;
  final $Res Function(ArticleRevisionDetailsModel) _then;

/// Create a copy of ArticleRevisionDetailsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? createdAt = null,Object? title = null,Object? languages = null,Object? document = null,Object? media = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ArticleDraftDocumentModel,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<MediaAssetModel>,
  ));
}
/// Create a copy of ArticleRevisionDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<$Res> get document {
  
  return $ArticleDraftDocumentModelCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleRevisionDetailsModel].
extension ArticleRevisionDetailsModelPatterns on ArticleRevisionDetailsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleRevisionDetailsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleRevisionDetailsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleRevisionDetailsModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleRevisionDetailsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleRevisionDetailsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleRevisionDetailsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  DateTime createdAt,  String title,  List<String> languages,  ArticleDraftDocumentModel document,  List<MediaAssetModel> media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleRevisionDetailsModel() when $default != null:
return $default(_that.number,_that.createdAt,_that.title,_that.languages,_that.document,_that.media);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  DateTime createdAt,  String title,  List<String> languages,  ArticleDraftDocumentModel document,  List<MediaAssetModel> media)  $default,) {final _that = this;
switch (_that) {
case _ArticleRevisionDetailsModel():
return $default(_that.number,_that.createdAt,_that.title,_that.languages,_that.document,_that.media);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  DateTime createdAt,  String title,  List<String> languages,  ArticleDraftDocumentModel document,  List<MediaAssetModel> media)?  $default,) {final _that = this;
switch (_that) {
case _ArticleRevisionDetailsModel() when $default != null:
return $default(_that.number,_that.createdAt,_that.title,_that.languages,_that.document,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleRevisionDetailsModel extends ArticleRevisionDetailsModel {
  const _ArticleRevisionDetailsModel({required this.number, required this.createdAt, this.title = '', final  List<String> languages = const <String>[], required this.document, final  List<MediaAssetModel> media = const <MediaAssetModel>[]}): _languages = languages,_media = media,super._();
  factory _ArticleRevisionDetailsModel.fromJson(Map<String, dynamic> json) => _$ArticleRevisionDetailsModelFromJson(json);

@override final  int number;
@override final  DateTime createdAt;
@override@JsonKey() final  String title;
 final  List<String> _languages;
@override@JsonKey() List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

@override final  ArticleDraftDocumentModel document;
 final  List<MediaAssetModel> _media;
@override@JsonKey() List<MediaAssetModel> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}


/// Create a copy of ArticleRevisionDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleRevisionDetailsModelCopyWith<_ArticleRevisionDetailsModel> get copyWith => __$ArticleRevisionDetailsModelCopyWithImpl<_ArticleRevisionDetailsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleRevisionDetailsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleRevisionDetailsModel&&(identical(other.number, number) || other.number == number)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._languages, _languages)&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other._media, _media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,createdAt,title,const DeepCollectionEquality().hash(_languages),document,const DeepCollectionEquality().hash(_media));

@override
String toString() {
  return 'ArticleRevisionDetailsModel(number: $number, createdAt: $createdAt, title: $title, languages: $languages, document: $document, media: $media)';
}


}

/// @nodoc
abstract mixin class _$ArticleRevisionDetailsModelCopyWith<$Res> implements $ArticleRevisionDetailsModelCopyWith<$Res> {
  factory _$ArticleRevisionDetailsModelCopyWith(_ArticleRevisionDetailsModel value, $Res Function(_ArticleRevisionDetailsModel) _then) = __$ArticleRevisionDetailsModelCopyWithImpl;
@override @useResult
$Res call({
 int number, DateTime createdAt, String title, List<String> languages, ArticleDraftDocumentModel document, List<MediaAssetModel> media
});


@override $ArticleDraftDocumentModelCopyWith<$Res> get document;

}
/// @nodoc
class __$ArticleRevisionDetailsModelCopyWithImpl<$Res>
    implements _$ArticleRevisionDetailsModelCopyWith<$Res> {
  __$ArticleRevisionDetailsModelCopyWithImpl(this._self, this._then);

  final _ArticleRevisionDetailsModel _self;
  final $Res Function(_ArticleRevisionDetailsModel) _then;

/// Create a copy of ArticleRevisionDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? createdAt = null,Object? title = null,Object? languages = null,Object? document = null,Object? media = null,}) {
  return _then(_ArticleRevisionDetailsModel(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ArticleDraftDocumentModel,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<MediaAssetModel>,
  ));
}

/// Create a copy of ArticleRevisionDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleDraftDocumentModelCopyWith<$Res> get document {
  
  return $ArticleDraftDocumentModelCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// @nodoc
mixin _$MyArticleModel {

 String get id; String get status; String? get slug; String get language; String get title; String? get coverUrl; FieldRefModel? get field; int get readingTimeMinutes; DateTime? get savedAt; DateTime? get publishedAt; bool get hasUnpublishedChanges; int get reactionCount; int get commentCount; int get readCount;
/// Create a copy of MyArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyArticleModelCopyWith<MyArticleModel> get copyWith => _$MyArticleModelCopyWithImpl<MyArticleModel>(this as MyArticleModel, _$identity);

  /// Serializes this MyArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.hasUnpublishedChanges, hasUnpublishedChanges) || other.hasUnpublishedChanges == hasUnpublishedChanges)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.readCount, readCount) || other.readCount == readCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,slug,language,title,coverUrl,field,readingTimeMinutes,savedAt,publishedAt,hasUnpublishedChanges,reactionCount,commentCount,readCount);

@override
String toString() {
  return 'MyArticleModel(id: $id, status: $status, slug: $slug, language: $language, title: $title, coverUrl: $coverUrl, field: $field, readingTimeMinutes: $readingTimeMinutes, savedAt: $savedAt, publishedAt: $publishedAt, hasUnpublishedChanges: $hasUnpublishedChanges, reactionCount: $reactionCount, commentCount: $commentCount, readCount: $readCount)';
}


}

/// @nodoc
abstract mixin class $MyArticleModelCopyWith<$Res>  {
  factory $MyArticleModelCopyWith(MyArticleModel value, $Res Function(MyArticleModel) _then) = _$MyArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String status, String? slug, String language, String title, String? coverUrl, FieldRefModel? field, int readingTimeMinutes, DateTime? savedAt, DateTime? publishedAt, bool hasUnpublishedChanges, int reactionCount, int commentCount, int readCount
});


$FieldRefModelCopyWith<$Res>? get field;

}
/// @nodoc
class _$MyArticleModelCopyWithImpl<$Res>
    implements $MyArticleModelCopyWith<$Res> {
  _$MyArticleModelCopyWithImpl(this._self, this._then);

  final MyArticleModel _self;
  final $Res Function(MyArticleModel) _then;

/// Create a copy of MyArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? slug = freezed,Object? language = null,Object? title = null,Object? coverUrl = freezed,Object? field = freezed,Object? readingTimeMinutes = null,Object? savedAt = freezed,Object? publishedAt = freezed,Object? hasUnpublishedChanges = null,Object? reactionCount = null,Object? commentCount = null,Object? readCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasUnpublishedChanges: null == hasUnpublishedChanges ? _self.hasUnpublishedChanges : hasUnpublishedChanges // ignore: cast_nullable_to_non_nullable
as bool,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of MyArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get field {
    if (_self.field == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.field!, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// Adds pattern-matching-related methods to [MyArticleModel].
extension MyArticleModelPatterns on MyArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _MyArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _MyArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  String? slug,  String language,  String title,  String? coverUrl,  FieldRefModel? field,  int readingTimeMinutes,  DateTime? savedAt,  DateTime? publishedAt,  bool hasUnpublishedChanges,  int reactionCount,  int commentCount,  int readCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyArticleModel() when $default != null:
return $default(_that.id,_that.status,_that.slug,_that.language,_that.title,_that.coverUrl,_that.field,_that.readingTimeMinutes,_that.savedAt,_that.publishedAt,_that.hasUnpublishedChanges,_that.reactionCount,_that.commentCount,_that.readCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  String? slug,  String language,  String title,  String? coverUrl,  FieldRefModel? field,  int readingTimeMinutes,  DateTime? savedAt,  DateTime? publishedAt,  bool hasUnpublishedChanges,  int reactionCount,  int commentCount,  int readCount)  $default,) {final _that = this;
switch (_that) {
case _MyArticleModel():
return $default(_that.id,_that.status,_that.slug,_that.language,_that.title,_that.coverUrl,_that.field,_that.readingTimeMinutes,_that.savedAt,_that.publishedAt,_that.hasUnpublishedChanges,_that.reactionCount,_that.commentCount,_that.readCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  String? slug,  String language,  String title,  String? coverUrl,  FieldRefModel? field,  int readingTimeMinutes,  DateTime? savedAt,  DateTime? publishedAt,  bool hasUnpublishedChanges,  int reactionCount,  int commentCount,  int readCount)?  $default,) {final _that = this;
switch (_that) {
case _MyArticleModel() when $default != null:
return $default(_that.id,_that.status,_that.slug,_that.language,_that.title,_that.coverUrl,_that.field,_that.readingTimeMinutes,_that.savedAt,_that.publishedAt,_that.hasUnpublishedChanges,_that.reactionCount,_that.commentCount,_that.readCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyArticleModel extends MyArticleModel {
  const _MyArticleModel({required this.id, this.status = 'draft', this.slug, this.language = 'ar-EG', this.title = '', this.coverUrl, this.field, this.readingTimeMinutes = 0, this.savedAt, this.publishedAt, this.hasUnpublishedChanges = false, this.reactionCount = 0, this.commentCount = 0, this.readCount = 0}): super._();
  factory _MyArticleModel.fromJson(Map<String, dynamic> json) => _$MyArticleModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String status;
@override final  String? slug;
@override@JsonKey() final  String language;
@override@JsonKey() final  String title;
@override final  String? coverUrl;
@override final  FieldRefModel? field;
@override@JsonKey() final  int readingTimeMinutes;
@override final  DateTime? savedAt;
@override final  DateTime? publishedAt;
@override@JsonKey() final  bool hasUnpublishedChanges;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;
@override@JsonKey() final  int readCount;

/// Create a copy of MyArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyArticleModelCopyWith<_MyArticleModel> get copyWith => __$MyArticleModelCopyWithImpl<_MyArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.field, field) || other.field == field)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.hasUnpublishedChanges, hasUnpublishedChanges) || other.hasUnpublishedChanges == hasUnpublishedChanges)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.readCount, readCount) || other.readCount == readCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,slug,language,title,coverUrl,field,readingTimeMinutes,savedAt,publishedAt,hasUnpublishedChanges,reactionCount,commentCount,readCount);

@override
String toString() {
  return 'MyArticleModel(id: $id, status: $status, slug: $slug, language: $language, title: $title, coverUrl: $coverUrl, field: $field, readingTimeMinutes: $readingTimeMinutes, savedAt: $savedAt, publishedAt: $publishedAt, hasUnpublishedChanges: $hasUnpublishedChanges, reactionCount: $reactionCount, commentCount: $commentCount, readCount: $readCount)';
}


}

/// @nodoc
abstract mixin class _$MyArticleModelCopyWith<$Res> implements $MyArticleModelCopyWith<$Res> {
  factory _$MyArticleModelCopyWith(_MyArticleModel value, $Res Function(_MyArticleModel) _then) = __$MyArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, String? slug, String language, String title, String? coverUrl, FieldRefModel? field, int readingTimeMinutes, DateTime? savedAt, DateTime? publishedAt, bool hasUnpublishedChanges, int reactionCount, int commentCount, int readCount
});


@override $FieldRefModelCopyWith<$Res>? get field;

}
/// @nodoc
class __$MyArticleModelCopyWithImpl<$Res>
    implements _$MyArticleModelCopyWith<$Res> {
  __$MyArticleModelCopyWithImpl(this._self, this._then);

  final _MyArticleModel _self;
  final $Res Function(_MyArticleModel) _then;

/// Create a copy of MyArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? slug = freezed,Object? language = null,Object? title = null,Object? coverUrl = freezed,Object? field = freezed,Object? readingTimeMinutes = null,Object? savedAt = freezed,Object? publishedAt = freezed,Object? hasUnpublishedChanges = null,Object? reactionCount = null,Object? commentCount = null,Object? readCount = null,}) {
  return _then(_MyArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasUnpublishedChanges: null == hasUnpublishedChanges ? _self.hasUnpublishedChanges : hasUnpublishedChanges // ignore: cast_nullable_to_non_nullable
as bool,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of MyArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get field {
    if (_self.field == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.field!, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// @nodoc
mixin _$MyArticlePageModel {

 List<MyArticleModel> get items; String? get nextCursor;
/// Create a copy of MyArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyArticlePageModelCopyWith<MyArticlePageModel> get copyWith => _$MyArticlePageModelCopyWithImpl<MyArticlePageModel>(this as MyArticlePageModel, _$identity);

  /// Serializes this MyArticlePageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyArticlePageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'MyArticlePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $MyArticlePageModelCopyWith<$Res>  {
  factory $MyArticlePageModelCopyWith(MyArticlePageModel value, $Res Function(MyArticlePageModel) _then) = _$MyArticlePageModelCopyWithImpl;
@useResult
$Res call({
 List<MyArticleModel> items, String? nextCursor
});




}
/// @nodoc
class _$MyArticlePageModelCopyWithImpl<$Res>
    implements $MyArticlePageModelCopyWith<$Res> {
  _$MyArticlePageModelCopyWithImpl(this._self, this._then);

  final MyArticlePageModel _self;
  final $Res Function(MyArticlePageModel) _then;

/// Create a copy of MyArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MyArticleModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MyArticlePageModel].
extension MyArticlePageModelPatterns on MyArticlePageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyArticlePageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyArticlePageModel value)  $default,){
final _that = this;
switch (_that) {
case _MyArticlePageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyArticlePageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MyArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MyArticleModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MyArticleModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _MyArticlePageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MyArticleModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _MyArticlePageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyArticlePageModel implements MyArticlePageModel {
  const _MyArticlePageModel({final  List<MyArticleModel> items = const <MyArticleModel>[], this.nextCursor}): _items = items;
  factory _MyArticlePageModel.fromJson(Map<String, dynamic> json) => _$MyArticlePageModelFromJson(json);

 final  List<MyArticleModel> _items;
@override@JsonKey() List<MyArticleModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of MyArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyArticlePageModelCopyWith<_MyArticlePageModel> get copyWith => __$MyArticlePageModelCopyWithImpl<_MyArticlePageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyArticlePageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyArticlePageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'MyArticlePageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$MyArticlePageModelCopyWith<$Res> implements $MyArticlePageModelCopyWith<$Res> {
  factory _$MyArticlePageModelCopyWith(_MyArticlePageModel value, $Res Function(_MyArticlePageModel) _then) = __$MyArticlePageModelCopyWithImpl;
@override @useResult
$Res call({
 List<MyArticleModel> items, String? nextCursor
});




}
/// @nodoc
class __$MyArticlePageModelCopyWithImpl<$Res>
    implements _$MyArticlePageModelCopyWith<$Res> {
  __$MyArticlePageModelCopyWithImpl(this._self, this._then);

  final _MyArticlePageModel _self;
  final $Res Function(_MyArticlePageModel) _then;

/// Create a copy of MyArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_MyArticlePageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MyArticleModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
