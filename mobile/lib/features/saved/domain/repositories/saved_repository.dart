import '../../../../core/errors/result.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/saved.dart';

abstract interface class SavedRepository {
  /// `PUT /me/saved/{id}` (idempotent), then keeps a copy on this device for offline reading.
  Future<Result<SaveState>> save(ArticleCard article);

  /// `DELETE /me/saved/{id}` (idempotent; also leaves every collection), then drops the device copy.
  Future<Result<SaveState>> unsave(String articleId);

  /// `GET /me/saved`, newest saved first. When the API is unreachable, the device copies (filtered here by field and
  /// title) come back as one page with `offline: true`.
  Future<Result<SavedArticlesPage>> getSaved({SavedFilter filter = const SavedFilter(), String? cursor, int limit = 20});

  /// `GET /me/collections`, in name order.
  Future<Result<List<ArticleCollection>>> getCollections();

  /// `POST /me/collections`: `409 collection.name_taken`, `400 collection.limit`.
  Future<Result<ArticleCollection>> createCollection(String name);

  /// `PATCH /me/collections/{id}`.
  Future<Result<ArticleCollection>> renameCollection(String id, String name);

  /// `DELETE /me/collections/{id}`: the articles stay saved.
  Future<Result<void>> deleteCollection(String id);

  /// `PUT /me/collections/{id}/articles/{articleId}`: saves the article first if needed.
  Future<Result<void>> addToCollection(String collectionId, String articleId);

  /// `DELETE /me/collections/{id}/articles/{articleId}`: stays saved.
  Future<Result<void>> removeFromCollection(String collectionId, String articleId);
}
