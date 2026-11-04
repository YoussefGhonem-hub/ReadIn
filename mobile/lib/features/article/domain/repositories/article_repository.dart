import '../../../../core/errors/result.dart';
import '../entities/article.dart';

abstract interface class ArticleRepository {
  /// `GET /articles/{slug}?lang=` — falls back to the source language server-side.
  Future<Result<ArticleDetails>> getArticle(String slug, {String? language});

  /// `GET /articles/{id}/related?lang=&limit=` (F04): up to [limit] cards for the end of the reader, in [language]
  /// when they have that version.
  Future<Result<List<ArticleCard>>> getRelated(String articleId, {String? language, int limit = 4});

  /// `GET /articles/{id}/preview?lang=` (F34): the article's first blocks, about 300 words, for a post card's
  /// "Read more". `404 article.not_found` wherever the article itself would be.
  Future<Result<ArticlePreview>> getPreview(String articleId, {String? language});
}
