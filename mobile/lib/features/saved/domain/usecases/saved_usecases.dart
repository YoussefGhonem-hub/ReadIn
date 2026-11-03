import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/saved.dart';
import '../repositories/saved_repository.dart';

/// Saves or unsaves an article (F13).
@injectable
class SetSaved {
  const SetSaved(this._repository);

  final SavedRepository _repository;

  Future<Result<SaveState>> call(ArticleCard article, {required bool saved}) =>
      saved ? _repository.save(article) : _repository.unsave(article.id);
}

@injectable
class GetSavedArticles {
  const GetSavedArticles(this._repository);

  final SavedRepository _repository;

  static const pageSize = 20;

  Future<Result<SavedArticlesPage>> call({SavedFilter filter = const SavedFilter(), String? cursor}) =>
      _repository.getSaved(filter: filter, cursor: cursor, limit: pageSize);
}

@injectable
class GetCollections {
  const GetCollections(this._repository);

  final SavedRepository _repository;

  Future<Result<List<ArticleCollection>>> call() => _repository.getCollections();
}

/// Create, rename and delete collections, and put articles in them or take them out.
@injectable
class ManageCollections {
  const ManageCollections(this._repository);

  final SavedRepository _repository;

  /// 1–60 characters after trimming (contract); the API checks again.
  static const maxNameLength = 60;

  Future<Result<ArticleCollection>> create(String name) => _repository.createCollection(name.trim());

  Future<Result<ArticleCollection>> rename(String id, String name) => _repository.renameCollection(id, name.trim());

  Future<Result<void>> delete(String id) => _repository.deleteCollection(id);

  Future<Result<void>> add(String collectionId, String articleId) => _repository.addToCollection(collectionId, articleId);

  Future<Result<void>> remove(String collectionId, String articleId) =>
      _repository.removeFromCollection(collectionId, articleId);
}
