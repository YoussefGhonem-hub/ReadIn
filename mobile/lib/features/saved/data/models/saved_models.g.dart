// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SaveStateModel _$SaveStateModelFromJson(Map<String, dynamic> json) =>
    _SaveStateModel(
      isSaved: json['isSaved'] as bool,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SaveStateModelToJson(_SaveStateModel instance) =>
    <String, dynamic>{
      'isSaved': instance.isSaved,
      'saveCount': instance.saveCount,
    };

_SavedArticleModel _$SavedArticleModelFromJson(Map<String, dynamic> json) =>
    _SavedArticleModel(
      savedAt: DateTime.parse(json['savedAt'] as String),
      collectionIds:
          (json['collectionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      article: ArticleCardModel.fromJson(
        json['article'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SavedArticleModelToJson(_SavedArticleModel instance) =>
    <String, dynamic>{
      'savedAt': instance.savedAt.toIso8601String(),
      'collectionIds': instance.collectionIds,
      'article': instance.article.toJson(),
    };

_SavedArticlePageModel _$SavedArticlePageModelFromJson(
  Map<String, dynamic> json,
) => _SavedArticlePageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SavedArticleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SavedArticleModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$SavedArticlePageModelToJson(
  _SavedArticlePageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_CollectionModel _$CollectionModelFromJson(Map<String, dynamic> json) =>
    _CollectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CollectionModelToJson(_CollectionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'articleCount': instance.articleCount,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_CollectionNameRequest _$CollectionNameRequestFromJson(
  Map<String, dynamic> json,
) => _CollectionNameRequest(name: json['name'] as String);

Map<String, dynamic> _$CollectionNameRequestToJson(
  _CollectionNameRequest instance,
) => <String, dynamic>{'name': instance.name};
