import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/data/models/article_models.dart';
import '../../../article/domain/entities/article.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../domain/entities/explore.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_api.dart';

@LazySingleton(as: ExploreRepository)
class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl(this._api);

  final ExploreApi _api;

  static CursorPage<ArticleCard> _page(ArticleCardPageModel page) =>
      CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);

  @override
  Future<Result<ExploreSections>> getExplore() => guardApi(() async => (await _api.getExplore()).toEntity());

  @override
  Future<Result<CursorPage<ArticleCard>>> getRanking(ExploreRanking ranking, {String? cursor, int limit = 20}) =>
      guardApi(() async => _page(await _api.getRanking(ranking.path, cursor, limit)));

  @override
  Future<Result<FieldDetails>> getField(String slug) => guardApi(() async => (await _api.getField(slug)).toEntity());

  @override
  Future<Result<CursorPage<ArticleCard>>> getFieldArticles(String slug, {String? topic, String? cursor, int limit = 20}) =>
      guardApi(() async => _page(await _api.getFieldArticles(slug, topic == null || topic.isEmpty ? null : topic, cursor, limit)));

  @override
  Future<Result<List<UserSummary>>> getFieldWriters(String slug, {int limit = 10}) =>
      guardApi(() async => [for (final m in await _api.getFieldWriters(slug, limit)) m.toEntity()]);
}
