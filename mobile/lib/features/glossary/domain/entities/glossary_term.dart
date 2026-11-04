import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// A glossary term (F21, `GlossaryTermDto`): what a tap on an RDoc `term` node opens.
class GlossaryTerm extends Equatable {
  const GlossaryTerm({
    required this.slug,
    required this.term,
    required this.definitionEn,
    required this.explanationAr,
    this.articles = const [],
  });

  /// The RDoc `termId`, e.g. `dependency-injection`.
  final String slug;

  /// The English term, always shown left to right.
  final String term;
  final String definitionEn;

  /// Egyptian Arabic with English terms (SPEC §14 BiDi rules apply).
  final String explanationAr;

  /// Up to 6 published articles that use the term, best first; the reader drops the open one and shows 5.
  final List<GlossaryArticle> articles;

  @override
  List<Object?> get props => [slug, term, definitionEn, explanationAr, articles];
}

/// An article that uses a glossary term (`GlossaryArticleDto`).
class GlossaryArticle extends Equatable {
  const GlossaryArticle({
    required this.id,
    required this.slug,
    required this.language,
    required this.title,
    required this.readingTimeMinutes,
    required this.field,
  });

  final String id;
  final String slug;

  /// The language of [title]: `ar-EG` or `en`.
  final String language;
  final String title;
  final int readingTimeMinutes;
  final FieldRef field;

  @override
  List<Object?> get props => [id, slug, language, title, readingTimeMinutes, field];
}

/// A search result of the editor's term picker (`GlossaryTermSummaryDto`, `GET /glossary?q=`).
class GlossaryTermSummary extends Equatable {
  const GlossaryTermSummary({required this.slug, required this.term, required this.definitionEn});

  /// The RDoc `termId`.
  final String slug;

  /// The English term, always shown left to right.
  final String term;
  final String definitionEn;

  @override
  List<Object?> get props => [slug, term, definitionEn];
}
