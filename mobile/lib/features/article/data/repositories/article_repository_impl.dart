import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/article_api.dart';
import '../datasources/article_offline_store.dart';

@LazySingleton(as: ArticleRepository)
class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl(this._api, this._offline);

  final ArticleApi _api;
  final ArticleOfflineStore _offline;

  /// Failures that mean "no connection", where a saved article's device copy is shown instead (F25).
  static bool isUnreachable(Failure failure) =>
      failure.code == FailureCodes.networkOffline || failure.code == FailureCodes.networkTimeout;

  @override
  Future<Result<ArticleDetails>> getArticle(String slug, {String? language}) async {
    final result = await guardApi(() => _api.getArticle(slug, language));
    switch (result) {
      case Ok(value: final model):
        _offline.remember(model);
        // A saved article's device copy follows the newest version the user opened.
        if (model.isSaved) await _offline.put(model).catchError((Object _) {});
        return Ok(model.toEntity());
      case Err(:final failure):
        if (!isUnreachable(failure)) return Err(failure);
        final copy = await _offline.find(slug, language: language).catchError((Object _) => null);
        return copy == null ? Err(failure) : Ok(copy.toEntity(offline: true));
    }
  }
}
