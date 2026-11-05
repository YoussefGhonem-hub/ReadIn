// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WriterCategoryModel _$WriterCategoryModelFromJson(Map<String, dynamic> json) =>
    _WriterCategoryModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WriterCategoryModelToJson(
  _WriterCategoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'name': instance.name,
  'articleCount': instance.articleCount,
  'sortOrder': instance.sortOrder,
};

_WriterCategoryListModel _$WriterCategoryListModelFromJson(
  Map<String, dynamic> json,
) => _WriterCategoryListModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => WriterCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <WriterCategoryModel>[],
  uncategorizedCount: (json['uncategorizedCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$WriterCategoryListModelToJson(
  _WriterCategoryListModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'uncategorizedCount': instance.uncategorizedCount,
};

_WriterCategoryPageModel _$WriterCategoryPageModelFromJson(
  Map<String, dynamic> json,
) => _WriterCategoryPageModel(
  id: json['id'] as String?,
  slug: json['slug'] as String,
  name: json['name'] as String?,
  articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
  author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WriterCategoryPageModelToJson(
  _WriterCategoryPageModel instance,
) => <String, dynamic>{
  'id': ?instance.id,
  'slug': instance.slug,
  'name': ?instance.name,
  'articleCount': instance.articleCount,
  'author': instance.author.toJson(),
};

_WriterCategoryRefModel _$WriterCategoryRefModelFromJson(
  Map<String, dynamic> json,
) => _WriterCategoryRefModel(
  slug: json['slug'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$WriterCategoryRefModelToJson(
  _WriterCategoryRefModel instance,
) => <String, dynamic>{'slug': instance.slug, 'name': instance.name};

_CategoryNameRequest _$CategoryNameRequestFromJson(Map<String, dynamic> json) =>
    _CategoryNameRequest(name: json['name'] as String);

Map<String, dynamic> _$CategoryNameRequestToJson(
  _CategoryNameRequest instance,
) => <String, dynamic>{'name': instance.name};

_CategoryOrderRequest _$CategoryOrderRequestFromJson(
  Map<String, dynamic> json,
) => _CategoryOrderRequest(
  categoryIds: (json['categoryIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CategoryOrderRequestToJson(
  _CategoryOrderRequest instance,
) => <String, dynamic>{'categoryIds': instance.categoryIds};
