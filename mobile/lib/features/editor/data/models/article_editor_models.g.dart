// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_editor_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DraftTranslationModel _$DraftTranslationModelFromJson(
  Map<String, dynamic> json,
) => _DraftTranslationModel(
  language: json['language'] as String,
  title: json['title'] as String? ?? '',
  subtitle: json['subtitle'] as String?,
  content:
      json['content'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$DraftTranslationModelToJson(
  _DraftTranslationModel instance,
) => <String, dynamic>{
  'language': instance.language,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'content': instance.content,
};

_ArticleDraftDocumentModel _$ArticleDraftDocumentModelFromJson(
  Map<String, dynamic> json,
) => _ArticleDraftDocumentModel(
  sourceLanguage: json['sourceLanguage'] as String,
  translations:
      (json['translations'] as List<dynamic>?)
          ?.map(
            (e) => DraftTranslationModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <DraftTranslationModel>[],
  fieldId: json['fieldId'] as String?,
  topicId: json['topicId'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  sources:
      (json['sources'] as List<dynamic>?)
          ?.map((e) => SourceModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SourceModel>[],
  coverUrl: json['coverUrl'] as String?,
  versionBadge: json['versionBadge'] as String?,
  isAiAssisted: json['isAiAssisted'] as bool? ?? false,
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AttachmentItemModel>[],
);

Map<String, dynamic> _$ArticleDraftDocumentModelToJson(
  _ArticleDraftDocumentModel instance,
) => <String, dynamic>{
  'sourceLanguage': instance.sourceLanguage,
  'translations': instance.translations.map((e) => e.toJson()).toList(),
  'fieldId': instance.fieldId,
  'topicId': instance.topicId,
  'tags': instance.tags,
  'sources': instance.sources.map((e) => e.toJson()).toList(),
  'coverUrl': instance.coverUrl,
  'versionBadge': instance.versionBadge,
  'isAiAssisted': instance.isAiAssisted,
  'attachments': instance.attachments.map((e) => e.toJson()).toList(),
};

_SaveDraftRequestModel _$SaveDraftRequestModelFromJson(
  Map<String, dynamic> json,
) => _SaveDraftRequestModel(
  baseVersion: (json['baseVersion'] as num).toInt(),
  document: ArticleDraftDocumentModel.fromJson(
    json['document'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SaveDraftRequestModelToJson(
  _SaveDraftRequestModel instance,
) => <String, dynamic>{
  'baseVersion': instance.baseVersion,
  'document': instance.document.toJson(),
};

_BaseVersionRequestModel _$BaseVersionRequestModelFromJson(
  Map<String, dynamic> json,
) =>
    _BaseVersionRequestModel(baseVersion: (json['baseVersion'] as num).toInt());

Map<String, dynamic> _$BaseVersionRequestModelToJson(
  _BaseVersionRequestModel instance,
) => <String, dynamic>{'baseVersion': instance.baseVersion};

_ReadingTimeModel _$ReadingTimeModelFromJson(Map<String, dynamic> json) =>
    _ReadingTimeModel(
      language: json['language'] as String,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      words: (json['words'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReadingTimeModelToJson(_ReadingTimeModel instance) =>
    <String, dynamic>{
      'language': instance.language,
      'minutes': instance.minutes,
      'words': instance.words,
    };

_DraftProblemModel _$DraftProblemModelFromJson(Map<String, dynamic> json) =>
    _DraftProblemModel(
      code: json['code'] as String,
      language: json['language'] as String?,
      blockId: json['blockId'] as String?,
      mediaAssetId: json['mediaAssetId'] as String?,
      tag: json['tag'] as String?,
    );

Map<String, dynamic> _$DraftProblemModelToJson(_DraftProblemModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'language': ?instance.language,
      'blockId': ?instance.blockId,
      'mediaAssetId': ?instance.mediaAssetId,
      'tag': ?instance.tag,
    };

_DraftChecksModel _$DraftChecksModelFromJson(Map<String, dynamic> json) =>
    _DraftChecksModel(
      readingTime:
          (json['readingTime'] as List<dynamic>?)
              ?.map((e) => ReadingTimeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ReadingTimeModel>[],
      problems:
          (json['problems'] as List<dynamic>?)
              ?.map(
                (e) => DraftProblemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <DraftProblemModel>[],
    );

Map<String, dynamic> _$DraftChecksModelToJson(_DraftChecksModel instance) =>
    <String, dynamic>{
      'readingTime': instance.readingTime.map((e) => e.toJson()).toList(),
      'problems': instance.problems.map((e) => e.toJson()).toList(),
    };

_ArticleEditModel _$ArticleEditModelFromJson(Map<String, dynamic> json) =>
    _ArticleEditModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'draft',
      slug: json['slug'] as String?,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      savedAt: json['savedAt'] == null
          ? null
          : DateTime.parse(json['savedAt'] as String),
      hasUnpublishedChanges: json['hasUnpublishedChanges'] as bool? ?? false,
      document: ArticleDraftDocumentModel.fromJson(
        json['document'] as Map<String, dynamic>,
      ),
      media:
          (json['media'] as List<dynamic>?)
              ?.map((e) => MediaAssetModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MediaAssetModel>[],
      checks: json['checks'] == null
          ? const DraftChecksModel()
          : DraftChecksModel.fromJson(json['checks'] as Map<String, dynamic>),
      categoryId: json['categoryId'] as String?,
    );

Map<String, dynamic> _$ArticleEditModelToJson(_ArticleEditModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'slug': ?instance.slug,
      'publishedAt': ?instance.publishedAt?.toIso8601String(),
      'version': instance.version,
      'savedAt': ?instance.savedAt?.toIso8601String(),
      'hasUnpublishedChanges': instance.hasUnpublishedChanges,
      'document': instance.document.toJson(),
      'media': instance.media.map((e) => e.toJson()).toList(),
      'checks': instance.checks.toJson(),
      'categoryId': ?instance.categoryId,
    };

_PublishedArticleModel _$PublishedArticleModelFromJson(
  Map<String, dynamic> json,
) => _PublishedArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  publishedAt: DateTime.parse(json['publishedAt'] as String),
  revision: (json['revision'] as num?)?.toInt() ?? 1,
  firstPublish: json['firstPublish'] as bool? ?? false,
);

Map<String, dynamic> _$PublishedArticleModelToJson(
  _PublishedArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'publishedAt': instance.publishedAt.toIso8601String(),
  'revision': instance.revision,
  'firstPublish': instance.firstPublish,
};

_ArticleRevisionModel _$ArticleRevisionModelFromJson(
  Map<String, dynamic> json,
) => _ArticleRevisionModel(
  number: (json['number'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  title: json['title'] as String? ?? '',
  languages:
      (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$ArticleRevisionModelToJson(
  _ArticleRevisionModel instance,
) => <String, dynamic>{
  'number': instance.number,
  'createdAt': instance.createdAt.toIso8601String(),
  'title': instance.title,
  'languages': instance.languages,
};

_ArticleRevisionDetailsModel _$ArticleRevisionDetailsModelFromJson(
  Map<String, dynamic> json,
) => _ArticleRevisionDetailsModel(
  number: (json['number'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  title: json['title'] as String? ?? '',
  languages:
      (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  document: ArticleDraftDocumentModel.fromJson(
    json['document'] as Map<String, dynamic>,
  ),
  media:
      (json['media'] as List<dynamic>?)
          ?.map((e) => MediaAssetModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MediaAssetModel>[],
);

Map<String, dynamic> _$ArticleRevisionDetailsModelToJson(
  _ArticleRevisionDetailsModel instance,
) => <String, dynamic>{
  'number': instance.number,
  'createdAt': instance.createdAt.toIso8601String(),
  'title': instance.title,
  'languages': instance.languages,
  'document': instance.document.toJson(),
  'media': instance.media.map((e) => e.toJson()).toList(),
};

_MyArticleModel _$MyArticleModelFromJson(Map<String, dynamic> json) =>
    _MyArticleModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'draft',
      slug: json['slug'] as String?,
      language: json['language'] as String? ?? 'ar-EG',
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      field: json['field'] == null
          ? null
          : FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
      readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 0,
      savedAt: json['savedAt'] == null
          ? null
          : DateTime.parse(json['savedAt'] as String),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      hasUnpublishedChanges: json['hasUnpublishedChanges'] as bool? ?? false,
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      publishedLanguages:
          (json['publishedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$MyArticleModelToJson(_MyArticleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'slug': ?instance.slug,
      'language': instance.language,
      'title': instance.title,
      'coverUrl': ?instance.coverUrl,
      'field': ?instance.field?.toJson(),
      'readingTimeMinutes': instance.readingTimeMinutes,
      'savedAt': ?instance.savedAt?.toIso8601String(),
      'publishedAt': ?instance.publishedAt?.toIso8601String(),
      'hasUnpublishedChanges': instance.hasUnpublishedChanges,
      'reactionCount': instance.reactionCount,
      'commentCount': instance.commentCount,
      'readCount': instance.readCount,
      'publishedLanguages': instance.publishedLanguages,
    };

_MyArticlePageModel _$MyArticlePageModelFromJson(Map<String, dynamic> json) =>
    _MyArticlePageModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => MyArticleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MyArticleModel>[],
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$MyArticlePageModelToJson(_MyArticlePageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
