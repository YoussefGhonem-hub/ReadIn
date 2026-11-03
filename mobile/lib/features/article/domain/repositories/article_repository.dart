import '../../../../core/errors/result.dart';
import '../entities/article.dart';

abstract interface class ArticleRepository {
  /// `GET /articles/{slug}?lang=` — falls back to the source language server-side.
  Future<Result<ArticleDetails>> getArticle(String slug, {String? language});
}
