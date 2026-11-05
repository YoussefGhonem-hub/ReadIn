import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/highlight.dart';

part 'highlight_models.freezed.dart';
part 'highlight_models.g.dart';

/// `HighlightDto` (docs/api/contract-v1.md, "Highlights (F30)").
@freezed
abstract class HighlightModel with _$HighlightModel {
  const HighlightModel._();

  const factory HighlightModel({
    required String id,
    required String blockId,
    required int startOffset,
    required int endOffset,
    required String text,
    required DateTime createdAt,
  }) = _HighlightModel;

  factory HighlightModel.fromJson(Map<String, dynamic> json) => _$HighlightModelFromJson(json);

  Highlight toEntity() => Highlight(
        id: id,
        blockId: blockId,
        startOffset: startOffset,
        endOffset: endOffset,
        text: text,
        createdAt: createdAt,
      );
}

/// `PopularHighlightDto`.
@freezed
abstract class PopularHighlightModel with _$PopularHighlightModel {
  const PopularHighlightModel._();

  const factory PopularHighlightModel({
    required String blockId,
    required int startOffset,
    required int endOffset,
    required String text,
    @Default(0) int count,
  }) = _PopularHighlightModel;

  factory PopularHighlightModel.fromJson(Map<String, dynamic> json) => _$PopularHighlightModelFromJson(json);

  PopularHighlight toEntity() => PopularHighlight(
        blockId: blockId,
        startOffset: startOffset,
        endOffset: endOffset,
        text: text,
        count: math.max(0, count),
      );
}

/// `ArticleHighlightsDto`.
@freezed
abstract class ArticleHighlightsModel with _$ArticleHighlightsModel {
  const ArticleHighlightsModel._();

  const factory ArticleHighlightsModel({
    required String articleId,
    required String language,
    @Default(<HighlightModel>[]) List<HighlightModel> mine,
    @Default(<PopularHighlightModel>[]) List<PopularHighlightModel> popular,
  }) = _ArticleHighlightsModel;

  factory ArticleHighlightsModel.fromJson(Map<String, dynamic> json) => _$ArticleHighlightsModelFromJson(json);

  ArticleHighlights toEntity() => ArticleHighlights(
        articleId: articleId,
        language: language,
        mine: [for (final h in mine) h.toEntity()],
        popular: [for (final p in popular) p.toEntity()],
      );
}

/// `CreateHighlightRequest`: offsets in the block's plain text, `text` exactly the text between them.
@freezed
abstract class CreateHighlightRequest with _$CreateHighlightRequest {
  const factory CreateHighlightRequest({
    required String language,
    required String blockId,
    required int startOffset,
    required int endOffset,
    required String text,
  }) = _CreateHighlightRequest;

  factory CreateHighlightRequest.fromJson(Map<String, dynamic> json) => _$CreateHighlightRequestFromJson(json);
}

/// `HighlightCreatedDto`.
@freezed
abstract class HighlightCreatedModel with _$HighlightCreatedModel {
  const HighlightCreatedModel._();

  const factory HighlightCreatedModel({
    required HighlightModel highlight,
    @Default(<String>[]) List<String> replacedIds,
  }) = _HighlightCreatedModel;

  factory HighlightCreatedModel.fromJson(Map<String, dynamic> json) => _$HighlightCreatedModelFromJson(json);

  HighlightCreated toEntity() => HighlightCreated(highlight: highlight.toEntity(), replacedIds: replacedIds);
}

/// `HighlightArticleDto`: `author` is null for a deleted account.
@freezed
abstract class HighlightArticleModel with _$HighlightArticleModel {
  const HighlightArticleModel._();

  const factory HighlightArticleModel({
    required String id,
    required String slug,
    required String language,
    required String title,
    AuthorModel? author,
  }) = _HighlightArticleModel;

  factory HighlightArticleModel.fromJson(Map<String, dynamic> json) => _$HighlightArticleModelFromJson(json);

  HighlightArticle toEntity() =>
      HighlightArticle(id: id, slug: slug, language: language, title: title, author: author?.toEntity());
}

/// `HighlightGroupDto`.
@freezed
abstract class HighlightGroupModel with _$HighlightGroupModel {
  const HighlightGroupModel._();

  const factory HighlightGroupModel({
    required HighlightArticleModel article,
    @Default(<HighlightModel>[]) List<HighlightModel> highlights,
    required DateTime latestAt,
  }) = _HighlightGroupModel;

  factory HighlightGroupModel.fromJson(Map<String, dynamic> json) => _$HighlightGroupModelFromJson(json);

  HighlightGroup toEntity() => HighlightGroup(
        article: article.toEntity(),
        highlights: [for (final h in highlights) h.toEntity()],
        latestAt: latestAt,
      );
}

/// `CursorPage<HighlightGroupDto>`.
@freezed
abstract class HighlightGroupPageModel with _$HighlightGroupPageModel {
  const factory HighlightGroupPageModel({
    @Default(<HighlightGroupModel>[]) List<HighlightGroupModel> items,
    String? nextCursor,
  }) = _HighlightGroupPageModel;

  factory HighlightGroupPageModel.fromJson(Map<String, dynamic> json) => _$HighlightGroupPageModelFromJson(json);
}
