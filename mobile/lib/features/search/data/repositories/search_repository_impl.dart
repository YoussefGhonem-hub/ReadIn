import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../domain/entities/search.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_api.dart';

@LazySingleton(as: SearchRepository)
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._api);

  final SearchApi _api;

  @override
  Future<Result<CursorPage<SearchArticle>>> articles(
    String query, {
    ArticleSearchFilters filters = const ArticleSearchFilters(),
    String? cursor,
    int limit = 20,
  }) =>
      guardApi(() async {
        final page = await _api.searchArticles(
          query,
          SearchType.articles.name,
          filters.fieldSlug,
          filters.language,
          filters.readingTime.minMinutes,
          filters.readingTime.maxMinutes,
          cursor,
          limit,
        );
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<CursorPage<UserSummary>>> users(String query, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.searchUsers(query, SearchType.users.name, cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<CursorPage<SearchTopic>>> topics(String query, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.searchTopics(query, SearchType.topics.name, cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<CursorPage<ArticleTag>>> tags(String query, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.searchTags(query, SearchType.tags.name, cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });
}
