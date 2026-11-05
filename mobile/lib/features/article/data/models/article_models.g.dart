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
  headline: json['headline'] as String?,
);

Map<String, dynamic> _$AuthorModelToJson(_AuthorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
      'avatarUrl': ?instance.avatarUrl,
      'isVerified': instance.isVerified,
      'headline': ?instance.headline,
    };

_RepostLabelModel _$RepostLabelModelFromJson(Map<String, dynamic> json) =>
    _RepostLabelModel(
      user: AuthorModel.fromJson(json['user'] as Map<String, dynamic>),
      othersCount: (json['othersCount'] as num?)?.toInt() ?? 0,
      repostedAt: DateTime.parse(json['repostedAt'] as String),
    );

Map<String, dynamic> _$RepostLabelModelToJson(_RepostLabelModel instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'othersCount': instance.othersCount,
      'repostedAt': instance.repostedAt.toIso8601String(),
    };

_FieldRefModel _$FieldRefModelFromJson(Map<String, dynamic> json) =>
    _FieldRefModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      name: json['name'] as String?,
      isSensitive: json['isSensitive'] as bool? ?? false,
    );

Map<String, dynamic> _$FieldRefModelToJson(_FieldRefModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'name': ?instance.name,
      'isSensitive': instance.isSensitive,
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

_ArticleCardModel _$ArticleCardModelFromJson(
  Map<String, dynamic> json,
) => _ArticleCardModel(
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
      : ReactionCountsModel.fromJson(json['reactions'] as Map<String, dynamic>),
  saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
  myReaction: json['myReaction'] as String?,
  isSaved: json['isSaved'] as bool? ?? false,
  excerpt: json['excerpt'] as String?,
  hasMore: json['hasMore'] as bool? ?? false,
  isFollowingAuthor: json['isFollowingAuthor'] as bool? ?? false,
  tags: json['tags'] == null
      ? const <TagRefModel>[]
      : tagRefsFromJson(json['tags']),
  tagCount: (json['tagCount'] as num?)?.toInt() ?? 0,
  topic: json['topic'] == null
      ? null
      : FieldRefModel.fromJson(json['topic'] as Map<String, dynamic>),
  isAuthorMuted: json['isAuthorMuted'] as bool? ?? false,
  isFieldMuted: json['isFieldMuted'] as bool? ?? false,
  isTopicMuted: json['isTopicMuted'] as bool? ?? false,
  repostCount: (json['repostCount'] as num?)?.toInt() ?? 0,
  isReposted: json['isReposted'] as bool? ?? false,
  repostedBy: json['repostedBy'] == null
      ? null
      : RepostLabelModel.fromJson(json['repostedBy'] as Map<String, dynamic>),
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
      'excerpt': ?instance.excerpt,
      'hasMore': instance.hasMore,
      'isFollowingAuthor': instance.isFollowingAuthor,
      'tags': tagRefsToJson(instance.tags),
      'tagCount': instance.tagCount,
      'topic': ?instance.topic?.toJson(),
      'isAuthorMuted': instance.isAuthorMuted,
      'isFieldMuted': instance.isFieldMuted,
      'isTopicMuted': instance.isTopicMuted,
      'repostCount': instance.repostCount,
      'isReposted': instance.isReposted,
      'repostedBy': ?instance.repostedBy?.toJson(),
    };

_ArticlePreviewModel _$ArticlePreviewModelFromJson(Map<String, dynamic> json) =>
    _ArticlePreviewModel(
      id: json['id'] as String,
      language: json['language'] as String,
      content:
          json['content'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      isComplete: json['isComplete'] as bool? ?? false,
    );

Map<String, dynamic> _$ArticlePreviewModelToJson(
  _ArticlePreviewModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'language': instance.language,
  'content': instance.content,
  'isComplete': instance.isComplete,
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

_MyProgressModel _$MyProgressModelFromJson(Map<String, dynamic> json) =>
    _MyProgressModel(
      language: json['language'] as String,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      lastPosition: json['lastPosition'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$MyProgressModelToJson(_MyProgressModel instance) =>
    <String, dynamic>{
      'language': instance.language,
      'percent': instance.percent,
      'lastPosition': ?instance.lastPosition,
      'completedAt': ?instance.completedAt?.toIso8601String(),
    };

_ArticleModerationModel _$ArticleModerationModelFromJson(
  Map<String, dynamic> json,
) => _ArticleModerationModel(
  hiddenAt: DateTime.parse(json['hiddenAt'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$ArticleModerationModelToJson(
  _ArticleModerationModel instance,
) => <String, dynamic>{
  'hiddenAt': instance.hiddenAt.toIso8601String(),
  'note': ?instance.note,
};

_ArticleDetailsModel _$ArticleDetailsModelFromJson(
  Map<String, dynamic> json,
) => _ArticleDetailsModel(
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
      : ReactionCountsModel.fromJson(json['reactions'] as Map<String, dynamic>),
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
  tags: json['tags'] == null
      ? const <TagRefModel>[]
      : tagRefsFromJson(json['tags']),
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
  myProgress: json['myProgress'] == null
      ? null
      : MyProgressModel.fromJson(json['myProgress'] as Map<String, dynamic>),
  moderation: json['moderation'] == null
      ? null
      : ArticleModerationModel.fromJson(
          json['moderation'] as Map<String, dynamic>,
        ),
  category: json['category'] == null
      ? null
      : WriterCategoryRefModel.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
  isAuthorMuted: json['isAuthorMuted'] as bool? ?? false,
  isFieldMuted: json['isFieldMuted'] as bool? ?? false,
  isTopicMuted: json['isTopicMuted'] as bool? ?? false,
  repostCount: (json['repostCount'] as num?)?.toInt() ?? 0,
  isReposted: json['isReposted'] as bool? ?? false,
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
  'tags': tagRefsToJson(instance.tags),
  'sources': instance.sources.map((e) => e.toJson()).toList(),
  'saveCount': instance.saveCount,
  'readCount': instance.readCount,
  'isFollowingAuthor': instance.isFollowingAuthor,
  'collectionIds': instance.collectionIds,
  'myProgress': ?instance.myProgress?.toJson(),
  'moderation': ?instance.moderation?.toJson(),
  'category': ?instance.category?.toJson(),
  'isAuthorMuted': instance.isAuthorMuted,
  'isFieldMuted': instance.isFieldMuted,
  'isTopicMuted': instance.isTopicMuted,
  'repostCount': instance.repostCount,
  'isReposted': instance.isReposted,
};
