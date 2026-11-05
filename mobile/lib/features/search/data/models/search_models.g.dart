// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchArticleModel _$SearchArticleModelFromJson(Map<String, dynamic> json) =>
    _SearchArticleModel(
      article: ArticleCardModel.fromJson(
        json['article'] as Map<String, dynamic>,
      ),
      matchedIn: json['matchedIn'] as String?,
    );

Map<String, dynamic> _$SearchArticleModelToJson(_SearchArticleModel instance) =>
    <String, dynamic>{
      'article': instance.article.toJson(),
      'matchedIn': ?instance.matchedIn,
    };

_SearchArticlePageModel _$SearchArticlePageModelFromJson(
  Map<String, dynamic> json,
) => _SearchArticlePageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SearchArticleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SearchArticleModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$SearchArticlePageModelToJson(
  _SearchArticlePageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_SearchTopicModel _$SearchTopicModelFromJson(Map<String, dynamic> json) =>
    _SearchTopicModel(
      kind: json['kind'] as String?,
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      fieldSlug: json['fieldSlug'] as String,
      topicSlug: json['topicSlug'] as String?,
      fieldName: json['fieldName'] as String? ?? '',
      icon: json['icon'] as String? ?? 'book-open',
      color: json['color'] as String? ?? 'primary',
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SearchTopicModelToJson(_SearchTopicModel instance) =>
    <String, dynamic>{
      'kind': ?instance.kind,
      'id': instance.id,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'fieldSlug': instance.fieldSlug,
      'topicSlug': ?instance.topicSlug,
      'fieldName': instance.fieldName,
      'icon': instance.icon,
      'color': instance.color,
      'articleCount': instance.articleCount,
    };

_SearchTopicPageModel _$SearchTopicPageModelFromJson(
  Map<String, dynamic> json,
) => _SearchTopicPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SearchTopicModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SearchTopicModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$SearchTopicPageModelToJson(
  _SearchTopicPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_TagPageModel _$TagPageModelFromJson(Map<String, dynamic> json) =>
    _TagPageModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TagModel>[],
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$TagPageModelToJson(_TagPageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
