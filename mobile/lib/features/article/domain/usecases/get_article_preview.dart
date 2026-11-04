import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/article.dart';
import '../repositories/article_repository.dart';

/// "Read more" on a post card (F34): the beginning of [articleId] in [language], the version the card shows.
@injectable
class GetArticlePreview {
  const GetArticlePreview(this._repository);

  final ArticleRepository _repository;

  Future<Result<ArticlePreview>> call(String articleId, {required String language}) =>
      _repository.getPreview(articleId, language: language);
}
