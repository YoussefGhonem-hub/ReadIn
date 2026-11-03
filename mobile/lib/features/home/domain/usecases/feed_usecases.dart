import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
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
