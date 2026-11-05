import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/tag.dart';

abstract interface class TagsRepository {
  /// `GET /tags/{slug}`: the tag page's header. `404 tag.not_found` for an unknown or hidden tag.
  Future<Result<ArticleTag>> getTag(String slug);

  /// `GET /tags/{slug}/articles`: published articles with the tag, newest first, [limit] per page.
  Future<Result<CursorPage<ArticleCard>>> getArticles(String slug, {String? cursor, int limit = 20});
}
