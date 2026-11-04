// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PathArticleRefModel _$PathArticleRefModelFromJson(Map<String, dynamic> json) =>
    _PathArticleRefModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      position: (json['position'] as num).toInt(),
      readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$PathArticleRefModelToJson(
  _PathArticleRefModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'language': instance.language,
  'position': instance.position,
  'readingTimeMinutes': instance.readingTimeMinutes,
};

_PathProgressModel _$PathProgressModelFromJson(Map<String, dynamic> json) =>
    _PathProgressModel(
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      next: json['next'] == null
          ? null
          : PathArticleRefModel.fromJson(json['next'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PathProgressModelToJson(_PathProgressModel instance) =>
    <String, dynamic>{
      'readCount': instance.readCount,
      'total': instance.total,
      'percent': instance.percent,
      'next': ?instance.next?.toJson(),
    };

_PathEnrollmentModel _$PathEnrollmentModelFromJson(Map<String, dynamic> json) =>
    _PathEnrollmentModel(
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$PathEnrollmentModelToJson(
  _PathEnrollmentModel instance,
) => <String, dynamic>{
  'enrolledAt': instance.enrolledAt.toIso8601String(),
  'completedAt': ?instance.completedAt?.toIso8601String(),
};

_PathCardModel _$PathCardModelFromJson(Map<String, dynamic> json) =>
    _PathCardModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 0,
      coverUrl: json['coverUrl'] as String?,
      progress: json['progress'] == null
          ? null
          : PathProgressModel.fromJson(
              json['progress'] as Map<String, dynamic>,
            ),
      enrollment: json['enrollment'] == null
          ? null
          : PathEnrollmentModel.fromJson(
              json['enrollment'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PathCardModelToJson(_PathCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'title': instance.title,
      'description': ?instance.description,
      'field': instance.field.toJson(),
      'articleCount': instance.articleCount,
      'readingTimeMinutes': instance.readingTimeMinutes,
      'coverUrl': ?instance.coverUrl,
      'progress': ?instance.progress?.toJson(),
      'enrollment': ?instance.enrollment?.toJson(),
    };

_PathItemModel _$PathItemModelFromJson(Map<String, dynamic> json) =>
    _PathItemModel(
      position: (json['position'] as num).toInt(),
      article: ArticleCardModel.fromJson(
        json['article'] as Map<String, dynamic>,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );

Map<String, dynamic> _$PathItemModelToJson(_PathItemModel instance) =>
    <String, dynamic>{
      'position': instance.position,
      'article': instance.article.toJson(),
      'isRead': instance.isRead,
    };

_PathDetailsModel _$PathDetailsModelFromJson(Map<String, dynamic> json) =>
    _PathDetailsModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 0,
      coverUrl: json['coverUrl'] as String?,
      progress: json['progress'] == null
          ? null
          : PathProgressModel.fromJson(
              json['progress'] as Map<String, dynamic>,
            ),
      enrollment: json['enrollment'] == null
          ? null
          : PathEnrollmentModel.fromJson(
              json['enrollment'] as Map<String, dynamic>,
            ),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => PathItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PathItemModel>[],
    );

Map<String, dynamic> _$PathDetailsModelToJson(_PathDetailsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'title': instance.title,
      'description': ?instance.description,
      'field': instance.field.toJson(),
      'articleCount': instance.articleCount,
      'readingTimeMinutes': instance.readingTimeMinutes,
      'coverUrl': ?instance.coverUrl,
      'progress': ?instance.progress?.toJson(),
      'enrollment': ?instance.enrollment?.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_ArticlePathModel _$ArticlePathModelFromJson(Map<String, dynamic> json) =>
    _ArticlePathModel(
      path: PathCardModel.fromJson(json['path'] as Map<String, dynamic>),
      position: (json['position'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      previous: json['previous'] == null
          ? null
          : PathArticleRefModel.fromJson(
              json['previous'] as Map<String, dynamic>,
            ),
      next: json['next'] == null
          ? null
          : ArticleCardModel.fromJson(json['next'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ArticlePathModelToJson(_ArticlePathModel instance) =>
    <String, dynamic>{
      'path': instance.path.toJson(),
      'position': instance.position,
      'total': instance.total,
      'previous': ?instance.previous?.toJson(),
      'next': ?instance.next?.toJson(),
    };
