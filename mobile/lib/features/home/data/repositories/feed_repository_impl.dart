import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/data/models/article_models.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/continue_reading.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_api.dart';

@LazySingleton(as: FeedRepository)
class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._api);

  final FeedApi _api;

  @override
  Future<Result<ArticleCard?>> getToday() => guardApi(() async {
        final response = await _api.getToday();
        final data = response.data;
        if (response.response.statusCode == 204 || data is! Map<String, dynamic>) return null;
        return ArticleCardModel.fromJson(data).toEntity();
      });

  @override
  Future<Result<CursorPage<ArticleCard>>> getForYou({String? fieldSlug, String? cursor, int limit = 20}) =>
      guardApi(() async => _page(await _api.getForYou(fieldSlug, cursor, limit)));

  @override
  Future<Result<CursorPage<ArticleCard>>> getFollowing({String? cursor, int limit = 20}) =>
      guardApi(() async => _page(await _api.getFollowing(cursor, limit)));

  @override
  Future<Result<List<ContinueReading>>> getContinueReading({int limit = 3}) =>
      guardApi(() async => [for (final m in await _api.getContinueReading(limit)) m.toEntity()]);

  static CursorPage<ArticleCard> _page(ArticleCardPageModel page) =>
      CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
}
