// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HighlightModel _$HighlightModelFromJson(Map<String, dynamic> json) =>
    _HighlightModel(
      id: json['id'] as String,
      blockId: json['blockId'] as String,
      startOffset: (json['startOffset'] as num).toInt(),
      endOffset: (json['endOffset'] as num).toInt(),
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$HighlightModelToJson(_HighlightModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'blockId': instance.blockId,
      'startOffset': instance.startOffset,
      'endOffset': instance.endOffset,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_PopularHighlightModel _$PopularHighlightModelFromJson(
  Map<String, dynamic> json,
) => _PopularHighlightModel(
  blockId: json['blockId'] as String,
  startOffset: (json['startOffset'] as num).toInt(),
  endOffset: (json['endOffset'] as num).toInt(),
  text: json['text'] as String,
  count: (json['count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PopularHighlightModelToJson(
  _PopularHighlightModel instance,
) => <String, dynamic>{
  'blockId': instance.blockId,
  'startOffset': instance.startOffset,
  'endOffset': instance.endOffset,
  'text': instance.text,
  'count': instance.count,
};

_ArticleHighlightsModel _$ArticleHighlightsModelFromJson(
  Map<String, dynamic> json,
) => _ArticleHighlightsModel(
  articleId: json['articleId'] as String,
  language: json['language'] as String,
  mine:
      (json['mine'] as List<dynamic>?)
          ?.map((e) => HighlightModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <HighlightModel>[],
  popular:
      (json['popular'] as List<dynamic>?)
          ?.map(
            (e) => PopularHighlightModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <PopularHighlightModel>[],
);

Map<String, dynamic> _$ArticleHighlightsModelToJson(
  _ArticleHighlightsModel instance,
) => <String, dynamic>{
  'articleId': instance.articleId,
  'language': instance.language,
  'mine': instance.mine.map((e) => e.toJson()).toList(),
  'popular': instance.popular.map((e) => e.toJson()).toList(),
};

_CreateHighlightRequest _$CreateHighlightRequestFromJson(
  Map<String, dynamic> json,
) => _CreateHighlightRequest(
  language: json['language'] as String,
  blockId: json['blockId'] as String,
  startOffset: (json['startOffset'] as num).toInt(),
  endOffset: (json['endOffset'] as num).toInt(),
  text: json['text'] as String,
);

Map<String, dynamic> _$CreateHighlightRequestToJson(
  _CreateHighlightRequest instance,
) => <String, dynamic>{
  'language': instance.language,
  'blockId': instance.blockId,
  'startOffset': instance.startOffset,
  'endOffset': instance.endOffset,
  'text': instance.text,
};

_HighlightCreatedModel _$HighlightCreatedModelFromJson(
  Map<String, dynamic> json,
) => _HighlightCreatedModel(
  highlight: HighlightModel.fromJson(json['highlight'] as Map<String, dynamic>),
  replacedIds:
      (json['replacedIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$HighlightCreatedModelToJson(
  _HighlightCreatedModel instance,
) => <String, dynamic>{
  'highlight': instance.highlight.toJson(),
  'replacedIds': instance.replacedIds,
};

_HighlightArticleModel _$HighlightArticleModelFromJson(
  Map<String, dynamic> json,
) => _HighlightArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  language: json['language'] as String,
  title: json['title'] as String,
  author: json['author'] == null
      ? null
      : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$HighlightArticleModelToJson(
  _HighlightArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'language': instance.language,
  'title': instance.title,
  'author': ?instance.author?.toJson(),
};

_HighlightGroupModel _$HighlightGroupModelFromJson(Map<String, dynamic> json) =>
    _HighlightGroupModel(
      article: HighlightArticleModel.fromJson(
        json['article'] as Map<String, dynamic>,
      ),
      highlights:
          (json['highlights'] as List<dynamic>?)
              ?.map((e) => HighlightModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HighlightModel>[],
      latestAt: DateTime.parse(json['latestAt'] as String),
    );

Map<String, dynamic> _$HighlightGroupModelToJson(
  _HighlightGroupModel instance,
) => <String, dynamic>{
  'article': instance.article.toJson(),
  'highlights': instance.highlights.map((e) => e.toJson()).toList(),
  'latestAt': instance.latestAt.toIso8601String(),
};

_HighlightGroupPageModel _$HighlightGroupPageModelFromJson(
  Map<String, dynamic> json,
) => _HighlightGroupPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => HighlightGroupModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <HighlightGroupModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$HighlightGroupPageModelToJson(
  _HighlightGroupPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};
