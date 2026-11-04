import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/glossary_term.dart';

part 'glossary_models.freezed.dart';
part 'glossary_models.g.dart';

/// `GlossaryArticleDto`.
@freezed
abstract class GlossaryArticleModel with _$GlossaryArticleModel {
  const GlossaryArticleModel._();

  const factory GlossaryArticleModel({
    required String id,
    required String slug,
    required String language,
    required String title,
    @Default(1) int readingTimeMinutes,
    required FieldRefModel field,
  }) = _GlossaryArticleModel;

  factory GlossaryArticleModel.fromJson(Map<String, dynamic> json) => _$GlossaryArticleModelFromJson(json);

  GlossaryArticle toEntity() => GlossaryArticle(
        id: id,
        slug: slug,
        language: language,
        title: title,
        readingTimeMinutes: readingTimeMinutes,
        field: field.toEntity(),
      );
}

/// `GlossaryTermDto` (F21).
@freezed
abstract class GlossaryTermModel with _$GlossaryTermModel {
  const GlossaryTermModel._();

  const factory GlossaryTermModel({
    required String slug,
    required String term,
    @Default('') String definitionEn,
    @Default('') String explanationAr,
    @Default(<GlossaryArticleModel>[]) List<GlossaryArticleModel> articles,
  }) = _GlossaryTermModel;

  factory GlossaryTermModel.fromJson(Map<String, dynamic> json) => _$GlossaryTermModelFromJson(json);

  GlossaryTerm toEntity() => GlossaryTerm(
        slug: slug,
        term: term,
        definitionEn: definitionEn,
        explanationAr: explanationAr,
        articles: [for (final a in articles) a.toEntity()],
      );
}
