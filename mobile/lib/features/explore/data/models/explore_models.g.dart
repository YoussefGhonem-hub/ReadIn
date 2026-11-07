// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FieldSummaryModel _$FieldSummaryModelFromJson(Map<String, dynamic> json) =>
    _FieldSummaryModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      icon: json['icon'] as String? ?? 'book-open',
      color: json['color'] as String? ?? 'primary',
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FieldSummaryModelToJson(_FieldSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'icon': instance.icon,
      'color': instance.color,
      'articleCount': instance.articleCount,
    };

_ExploreModel _$ExploreModelFromJson(Map<String, dynamic> json) =>
    _ExploreModel(
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map(
                (e) => FieldSummaryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <FieldSummaryModel>[],
      trending:
          (json['trending'] as List<dynamic>?)
              ?.map((e) => ArticleCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ArticleCardModel>[],
      mostSaved:
          (json['mostSaved'] as List<dynamic>?)
              ?.map((e) => ArticleCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ArticleCardModel>[],
      newWriters:
          (json['newWriters'] as List<dynamic>?)
              ?.map((e) => UserSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <UserSummaryModel>[],
      featuredPaths:
          (json['featuredPaths'] as List<dynamic>?)
              ?.map((e) => PathCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PathCardModel>[],
      featuredArticles:
          (json['featuredArticles'] as List<dynamic>?)
              ?.map((e) => ArticleCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ArticleCardModel>[],
    );

Map<String, dynamic> _$ExploreModelToJson(
  _ExploreModel instance,
) => <String, dynamic>{
  'fields': instance.fields.map((e) => e.toJson()).toList(),
  'trending': instance.trending.map((e) => e.toJson()).toList(),
  'mostSaved': instance.mostSaved.map((e) => e.toJson()).toList(),
  'newWriters': instance.newWriters.map((e) => e.toJson()).toList(),
  'featuredPaths': instance.featuredPaths.map((e) => e.toJson()).toList(),
  'featuredArticles': instance.featuredArticles.map((e) => e.toJson()).toList(),
};

_FieldPageTopicModel _$FieldPageTopicModelFromJson(Map<String, dynamic> json) =>
    _FieldPageTopicModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );

Map<String, dynamic> _$FieldPageTopicModelToJson(
  _FieldPageTopicModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'name': instance.name,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'articleCount': instance.articleCount,
  'isFollowing': instance.isFollowing,
};

_FieldPageModel _$FieldPageModelFromJson(Map<String, dynamic> json) =>
    _FieldPageModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      icon: json['icon'] as String? ?? 'book-open',
      color: json['color'] as String? ?? 'primary',
      isSensitive: json['isSensitive'] as bool? ?? false,
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      topics:
          (json['topics'] as List<dynamic>?)
              ?.map(
                (e) => FieldPageTopicModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <FieldPageTopicModel>[],
    );

Map<String, dynamic> _$FieldPageModelToJson(_FieldPageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'icon': instance.icon,
      'color': instance.color,
      'isSensitive': instance.isSensitive,
      'articleCount': instance.articleCount,
      'followerCount': instance.followerCount,
      'isFollowing': instance.isFollowing,
      'topics': instance.topics.map((e) => e.toJson()).toList(),
    };
