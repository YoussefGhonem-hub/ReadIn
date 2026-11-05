import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../follow/domain/entities/follow.dart';
import '../entities/explore.dart';
import '../repositories/explore_repository.dart';

/// Explore's sections (F15): fields, the first of each ranking, new writers and featured paths.
@injectable
class GetExplore {
  const GetExplore(this._repository);

  final ExploreRepository _repository;

  Future<Result<ExploreSections>> call() => _repository.getExplore();
}

/// A ranking in full ("See all"), 20 per page.
@injectable
class GetExploreRanking {
  const GetExploreRanking(this._repository);

  final ExploreRepository _repository;

  Future<Result<CursorPage<ArticleCard>>> call(ExploreRanking ranking, {String? cursor}) =>
      _repository.getRanking(ranking, cursor: cursor);
}

/// A field page's header and topic chips.
@injectable
class GetFieldDetails {
  const GetFieldDetails(this._repository);

  final ExploreRepository _repository;

  Future<Result<FieldDetails>> call(String slug) => _repository.getField(slug);
}

/// A field's articles, or one topic's, newest first.
@injectable
class GetFieldArticles {
  const GetFieldArticles(this._repository);

  final ExploreRepository _repository;

  Future<Result<CursorPage<ArticleCard>>> call(String slug, {String? topic, String? cursor}) =>
      _repository.getFieldArticles(slug, topic: topic, cursor: cursor);
}

/// "Top writers in this field" (≤ 10).
@injectable
class GetFieldWriters {
  const GetFieldWriters(this._repository);

  final ExploreRepository _repository;

  static const limit = 10;

  Future<Result<List<UserSummary>>> call(String slug) => _repository.getFieldWriters(slug, limit: limit);
}
