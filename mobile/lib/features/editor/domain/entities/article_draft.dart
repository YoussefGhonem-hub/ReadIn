import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// What `POST /articles` needs (`CreateArticleRequest`).
class ArticleDraft extends Equatable {
  const ArticleDraft({
    required this.fieldId,
    required this.language,
    required this.title,
    required this.content,
    this.sources = const [],
    this.isAiAssisted = false,
  });

  static const minTitle = 5;
  static const maxTitle = 150;

  final String fieldId;

  /// `ar-EG` | `en`.
  final String language;
  final String title;

  /// RDoc JSON (shared/rdoc/rdoc.schema.json).
  final Map<String, dynamic> content;
  final List<ArticleSource> sources;
  final bool isAiAssisted;

  @override
  List<Object?> get props => [fieldId, language, title, content, sources, isAiAssisted];
}

/// `201 { id, slug }` of a newly created draft.
class CreatedArticle extends Equatable {
  const CreatedArticle({required this.id, required this.slug});

  final String id;
  final String slug;

  @override
  List<Object?> get props => [id, slug];
}
