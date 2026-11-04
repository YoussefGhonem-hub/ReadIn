import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/article.dart';
import '../repositories/article_repository.dart';

/// "Related articles" at the end of the reader (F04), for the version being read.
@injectable
class GetRelatedArticles {
  const GetRelatedArticles(this._repository);

  final ArticleRepository _repository;

  static const limit = 4;

  Future<Result<List<ArticleCard>>> call(String articleId, {required String language}) =>
      _repository.getRelated(articleId, language: language, limit: limit);
}
