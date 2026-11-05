import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../tags/domain/entities/tag.dart';
import '../entities/search.dart';
import '../repositories/search_repository.dart';

/// Search (F16): one page of one tab's results for a query.
@injectable
class SearchContent {
  const SearchContent(this._repository);

  final SearchRepository _repository;

  Future<Result<CursorPage<SearchArticle>>> articles(String query, {ArticleSearchFilters filters = const ArticleSearchFilters(), String? cursor}) =>
      _repository.articles(query, filters: filters, cursor: cursor);

  Future<Result<CursorPage<UserSummary>>> users(String query, {String? cursor}) => _repository.users(query, cursor: cursor);

  Future<Result<CursorPage<SearchTopic>>> topics(String query, {String? cursor}) => _repository.topics(query, cursor: cursor);

  Future<Result<CursorPage<ArticleTag>>> tags(String query, {String? cursor}) => _repository.tags(query, cursor: cursor);
}
