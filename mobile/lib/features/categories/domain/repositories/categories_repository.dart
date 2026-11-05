import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/writer_category.dart';

abstract interface class CategoriesRepository {
  /// `GET /users/{username}/categories`: the profile's Categories tab (non-empty categories only).
  Future<Result<WriterCategoryList>> getUserCategories(String username);

  /// `GET /users/{username}/categories/{slug}`: the category page's header. `404 category.not_found` for a slug the
  /// writer doesn't have, `404 user.not_found` for a deleted or suspended writer.
  Future<Result<WriterCategoryPage>> getCategoryPage(String username, String slug);

  /// `GET /users/{username}/categories/{slug}/articles`: newest first, [limit] per page. Same `404`s.
  Future<Result<CursorPage<ArticleCard>>> getCategoryArticles(String username, String slug, {String? cursor, int limit = 20});

  /// `GET /me/categories`: all your categories, empty ones included.
  Future<Result<WriterCategoryList>> getMyCategories();

  /// `POST /me/categories`. `400 category.limit`, `409 category.name_taken`, `400 validation.failed`
  /// (`errors.name: ["category.name_invalid"]`).
  Future<Result<WriterCategory>> create(String name);

  /// `PATCH /me/categories/{id}`: same errors as [create], plus `404 category.not_found` / `403 category.not_owner`.
  Future<Result<WriterCategory>> rename(String id, String name);

  /// `DELETE /me/categories/{id}` → `204`; its articles become uncategorized.
  Future<Result<void>> delete(String id);

  /// `PUT /me/categories/order` → the list as `GET /me/categories`.
  Future<Result<WriterCategoryList>> reorder(List<String> categoryIds);

  /// `PUT /articles/{id}/category` with [categoryId] (null: none) → `204`. Applies at once (no publish, no revision).
  Future<Result<void>> setArticleCategory(String articleId, String? categoryId);
}
