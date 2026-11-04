// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthorModel _$AuthorModelFromJson(Map<String, dynamic> json) => _AuthorModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$AuthorModelToJson(_AuthorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
      'avatarUrl': ?instance.avatarUrl,
      'isVerified': instance.isVerified,
    };

_FieldRefModel _$FieldRefModelFromJson(Map<String, dynamic> json) =>
    _FieldRefModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$FieldRefModelToJson(_FieldRefModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'name': ?instance.name,
    };

_ReactionCountsModel _$ReactionCountsModelFromJson(Map<String, dynamic> json) =>
    _ReactionCountsModel(
      insightful: (json['insightful'] as num?)?.toInt() ?? 0,
      love: (json['love'] as num?)?.toInt() ?? 0,
      fire: (json['fire'] as num?)?.toInt() ?? 0,
      mindBlown: (json['mindBlown'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReactionCountsModelToJson(
  _ReactionCountsModel instance,
) => <String, dynamic>{
  'insightful': instance.insightful,
  'love': instance.love,
  'fire': instance.fire,
  'mindBlown': instance.mindBlown,
};

_ArticleCardModel _$ArticleCardModelFromJson(Map<String, dynamic> json) =>
    _ArticleCardModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      language: json['language'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      coverUrl: json['coverUrl'] as String?,
      field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
      author: json['author'] == null
          ? null
          : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 1,
      isAiAssisted: json['isAiAssisted'] as bool? ?? false,
      versionBadge: json['versionBadge'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      attachments: json['attachments'] == null
          ? null
          : ArticleAttachmentsModel.fromJson(
              json['attachments'] as Map<String, dynamic>,
            ),
      reactions: json['reactions'] == null
          ? null
          : ReactionCountsModel.fromJson(
              json['reactions'] as Map<String, dynamic>,
            ),
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      myReaction: json['myReaction'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
    );

Map<String, dynamic> _$ArticleCardModelToJson(_ArticleCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'language': instance.language,
      'title': instance.title,
      'subtitle': ?instance.subtitle,
      'coverUrl': ?instance.coverUrl,
      'field': instance.field.toJson(),
      'author': ?instance.author?.toJson(),
      'readingTimeMinutes': instance.readingTimeMinutes,
      'isAiAssisted': instance.isAiAssisted,
      'versionBadge': ?instance.versionBadge,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'reactionCount': instance.reactionCount,
      'commentCount': instance.commentCount,
      'attachments': ?instance.attachments?.toJson(),
      'reactions': ?instance.reactions?.toJson(),
      'saveCount': instance.saveCount,
      'myReaction': ?instance.myReaction,
      'isSaved': instance.isSaved,
    };

_ArticleCardPageModel _$ArticleCardPageModelFromJson(
  Map<String, dynamic> json,
) => _ArticleCardPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ArticleCardModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ArticleCardModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$ArticleCardPageModelToJson(
  _ArticleCardPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_SourceModel _$SourceModelFromJson(Map<String, dynamic> json) =>
    _SourceModel(title: json['title'] as String, url: json['url'] as String);

Map<String, dynamic> _$SourceModelToJson(_SourceModel instance) =>
    <String, dynamic>{'title': instance.title, 'url': instance.url};

_ArticleDetailsModel _$ArticleDetailsModelFromJson(Map<String, dynamic> json) =>
    _ArticleDetailsModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      language: json['language'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      coverUrl: json['coverUrl'] as String?,
      field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
      author: json['author'] == null
          ? null
          : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 1,
      isAiAssisted: json['isAiAssisted'] as bool? ?? false,
      versionBadge: json['versionBadge'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      attachments: json['attachments'] == null
          ? null
          : ArticleAttachmentsModel.fromJson(
              json['attachments'] as Map<String, dynamic>,
            ),
      reactions: json['reactions'] == null
          ? null
          : ReactionCountsModel.fromJson(
              json['reactions'] as Map<String, dynamic>,
            ),
      myReaction: json['myReaction'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
      availableLanguages:
          (json['availableLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      summary: json['summary'] as String?,
      content:
          json['content'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      topic: json['topic'] == null
          ? null
          : FieldRefModel.fromJson(json['topic'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => SourceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SourceModel>[],
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      isFollowingAuthor: json['isFollowingAuthor'] as bool? ?? false,
      collectionIds:
          (json['collectionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ArticleDetailsModelToJson(
  _ArticleDetailsModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'language': instance.language,
  'title': instance.title,
  'subtitle': ?instance.subtitle,
  'coverUrl': ?instance.coverUrl,
  'field': instance.field.toJson(),
  'author': ?instance.author?.toJson(),
  'readingTimeMinutes': instance.readingTimeMinutes,
  'isAiAssisted': instance.isAiAssisted,
  'versionBadge': ?instance.versionBadge,
  'publishedAt': instance.publishedAt.toIso8601String(),
  'reactionCount': instance.reactionCount,
  'commentCount': instance.commentCount,
  'attachments': ?instance.attachments?.toJson(),
  'reactions': ?instance.reactions?.toJson(),
  'myReaction': ?instance.myReaction,
  'isSaved': instance.isSaved,
  'availableLanguages': instance.availableLanguages,
  'summary': ?instance.summary,
  'content': instance.content,
  'topic': ?instance.topic?.toJson(),
  'tags': instance.tags,
  'sources': instance.sources.map((e) => e.toJson()).toList(),
  'saveCount': instance.saveCount,
  'readCount': instance.readCount,
  'isFollowingAuthor': instance.isFollowingAuthor,
  'collectionIds': instance.collectionIds,
};
