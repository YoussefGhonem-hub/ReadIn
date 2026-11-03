import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/article_draft.dart';

part 'editor_models.freezed.dart';
part 'editor_models.g.dart';

@freezed
abstract class SourceRequestModel with _$SourceRequestModel {
  const factory SourceRequestModel({required String title, required String url}) = _SourceRequestModel;

  factory SourceRequestModel.fromJson(Map<String, dynamic> json) => _$SourceRequestModelFromJson(json);
}

/// `CreateArticleRequest` (docs/api/contract-v1.md).
@freezed
abstract class CreateArticleRequestModel with _$CreateArticleRequestModel {
  const factory CreateArticleRequestModel({
    required String fieldId,
    String? topicId,
    required String language,
    required String title,
    String? subtitle,
    required Map<String, dynamic> content,
    List<String>? tags,
    List<SourceRequestModel>? sources,
    String? coverUrl,
    String? versionBadge,
    required bool isAiAssisted,
  }) = _CreateArticleRequestModel;

  factory CreateArticleRequestModel.fromJson(Map<String, dynamic> json) => _$CreateArticleRequestModelFromJson(json);

  factory CreateArticleRequestModel.fromDraft(ArticleDraft draft) => CreateArticleRequestModel(
        fieldId: draft.fieldId,
        language: draft.language,
        title: draft.title,
        content: draft.content,
        sources: draft.sources.isEmpty
            ? null
            : [for (final s in draft.sources) SourceRequestModel(title: s.title, url: s.url)],
        isAiAssisted: draft.isAiAssisted,
      );
}

/// `201 { id, slug }`.
@freezed
abstract class CreatedArticleModel with _$CreatedArticleModel {
  const CreatedArticleModel._();

  const factory CreatedArticleModel({required String id, required String slug}) = _CreatedArticleModel;

  factory CreatedArticleModel.fromJson(Map<String, dynamic> json) => _$CreatedArticleModelFromJson(json);

  CreatedArticle toEntity() => CreatedArticle(id: id, slug: slug);
}
