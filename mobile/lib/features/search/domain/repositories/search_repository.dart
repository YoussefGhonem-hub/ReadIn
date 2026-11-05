import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../tags/domain/entities/tag.dart';
import '../entities/search.dart';

/// `GET /search` (F16), one tab at a time, best first, [limit] per page. Guests may search.
abstract interface class SearchRepository {
  /// `type=articles`: openable articles, filtered by [filters].
  Future<Result<CursorPage<SearchArticle>>> articles(
    String query, {
    ArticleSearchFilters filters = const ArticleSearchFilters(),
    String? cursor,
    int limit = 20,
  });

  /// `type=users`: writers and readers by display name or `@username`.
  Future<Result<CursorPage<UserSummary>>> users(String query, {String? cursor, int limit = 20});

  /// `type=topics`: fields and topics.
  Future<Result<CursorPage<SearchTopic>>> topics(String query, {String? cursor, int limit = 20});

  /// `type=tags`: tags with at least one visible article.
  Future<Result<CursorPage<ArticleTag>>> tags(String query, {String? cursor, int limit = 20});
}
