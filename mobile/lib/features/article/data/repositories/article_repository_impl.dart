import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/article_api.dart';

@LazySingleton(as: ArticleRepository)
class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl(this._api);

  final ArticleApi _api;

  @override
  Future<Result<ArticleDetails>> getArticle(String slug, {String? language}) =>
      guardApi(() async => (await _api.getArticle(slug, language)).toEntity());
}
