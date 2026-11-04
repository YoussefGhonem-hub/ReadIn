import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/continue_reading.dart';
import '../repositories/feed_repository.dart';

@injectable
class GetTodayArticle {
  const GetTodayArticle(this._repository);

  final FeedRepository _repository;

  Future<Result<ArticleCard?>> call() => _repository.getToday();
}

@injectable
class GetForYouFeed {
  const GetForYouFeed(this._repository);

  final FeedRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ArticleCard>>> call({String? fieldSlug, String? cursor}) =>
      _repository.getForYou(fieldSlug: fieldSlug, cursor: cursor, limit: pageSize);
}

/// The "Following" tab (F03, F12).
@injectable
class GetFollowingFeed {
  const GetFollowingFeed(this._repository);

  final FeedRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ArticleCard>>> call({String? cursor}) => _repository.getFollowing(cursor: cursor, limit: pageSize);
}

/// The Home "Continue reading" card (F03): a few candidates, so one that is also today's article can be skipped.
@injectable
class GetContinueReading {
  const GetContinueReading(this._repository);

  final FeedRepository _repository;

  static const limit = 3;

  Future<Result<List<ContinueReading>>> call() => _repository.getContinueReading(limit: limit);
}
