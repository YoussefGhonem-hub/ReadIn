import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/continue_reading.dart';

abstract interface class FeedRepository {
  /// `GET /feed/today` — null when no pick is available yet (HTTP 204).
  Future<Result<ArticleCard?>> getToday();

  /// `GET /feed/for-you` — signed in: interests first; guest: latest published.
  Future<Result<CursorPage<ArticleCard>>> getForYou({String? fieldSlug, String? cursor, int limit = 20});

  /// `GET /feed/following` — articles by the writers the viewer follows (F12).
  Future<Result<CursorPage<ArticleCard>>> getFollowing({String? cursor, int limit = 20});

  /// `GET /me/continue-reading?limit=` — unfinished articles (≥ 5%, last 30 days), most recently read first.
  Future<Result<List<ContinueReading>>> getContinueReading({int limit = 3});
}
