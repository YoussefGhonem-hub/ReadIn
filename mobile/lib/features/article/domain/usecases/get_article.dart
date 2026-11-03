import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/article.dart';
import '../repositories/article_repository.dart';

@injectable
class GetArticle {
  const GetArticle(this._repository);

  final ArticleRepository _repository;

  Future<Result<ArticleDetails>> call(String slug, {String? language}) =>
      _repository.getArticle(slug, language: language);
}
