import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../follow/domain/entities/follow.dart';
import '../entities/explore.dart';

/// Explore and the field pages (F15), guests allowed: a Bearer fills the viewer's reaction, save and follows.
abstract interface class ExploreRepository {
  /// `GET /explore`: every section in one answer.
  Future<Result<ExploreSections>> getExplore();

  /// `GET /explore/{trending|most-saved}`: a ranking in full, best first, [limit] per page.
  Future<Result<CursorPage<ArticleCard>>> getRanking(ExploreRanking ranking, {String? cursor, int limit = 20});

  /// `GET /fields/{slug}`: the field page's header and topic chips. `404 field.not_found` for an unknown or disabled
  /// field.
  Future<Result<FieldDetails>> getField(String slug);

  /// `GET /fields/{slug}/articles?topic=`: the field's articles (or one topic's), newest first. `404 topic.not_found`
  /// for a topic that isn't one of the field's.
  Future<Result<CursorPage<ArticleCard>>> getFieldArticles(String slug, {String? topic, String? cursor, int limit = 20});

  /// `GET /fields/{slug}/writers`: "Top writers in this field", best first.
  Future<Result<List<UserSummary>>> getFieldWriters(String slug, {int limit = 10});
}
