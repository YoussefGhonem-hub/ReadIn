// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SourceRequestModel _$SourceRequestModelFromJson(Map<String, dynamic> json) =>
    _SourceRequestModel(
      title: json['title'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$SourceRequestModelToJson(_SourceRequestModel instance) =>
    <String, dynamic>{'title': instance.title, 'url': instance.url};

_CreateArticleRequestModel _$CreateArticleRequestModelFromJson(
  Map<String, dynamic> json,
) => _CreateArticleRequestModel(
  fieldId: json['fieldId'] as String,
  topicId: json['topicId'] as String?,
  language: json['language'] as String,
  title: json['title'] as String,
  subtitle: json['subtitle'] as String?,
  content: json['content'] as Map<String, dynamic>,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  sources: (json['sources'] as List<dynamic>?)
      ?.map((e) => SourceRequestModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  coverUrl: json['coverUrl'] as String?,
  versionBadge: json['versionBadge'] as String?,
  isAiAssisted: json['isAiAssisted'] as bool,
);

Map<String, dynamic> _$CreateArticleRequestModelToJson(
  _CreateArticleRequestModel instance,
) => <String, dynamic>{
  'fieldId': instance.fieldId,
  'topicId': ?instance.topicId,
  'language': instance.language,
  'title': instance.title,
  'subtitle': ?instance.subtitle,
  'content': instance.content,
  'tags': ?instance.tags,
  'sources': ?instance.sources?.map((e) => e.toJson()).toList(),
  'coverUrl': ?instance.coverUrl,
  'versionBadge': ?instance.versionBadge,
  'isAiAssisted': instance.isAiAssisted,
};

_CreatedArticleModel _$CreatedArticleModelFromJson(Map<String, dynamic> json) =>
    _CreatedArticleModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
    );

Map<String, dynamic> _$CreatedArticleModelToJson(
  _CreatedArticleModel instance,
) => <String, dynamic>{'id': instance.id, 'slug': instance.slug};
