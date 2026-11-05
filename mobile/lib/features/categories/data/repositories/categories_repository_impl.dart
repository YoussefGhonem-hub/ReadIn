import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/domain/entities/article.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../domain/entities/writer_category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_api.dart';
import '../models/category_models.dart';

@LazySingleton(as: CategoriesRepository)
class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl(this._api);

  final CategoriesApi _api;

  /// Slugs are matched ignoring case; the lower-case slug keeps one cache key per page.
  static String _slug(String slug) => slug.trim().toLowerCase();

  @override
  Future<Result<WriterCategoryList>> getUserCategories(String username) =>
      guardApi(() async => (await _api.userCategories(ProfileRepositoryImpl.handle(username))).toEntity());

  @override
  Future<Result<WriterCategoryPage>> getCategoryPage(String username, String slug) =>
      guardApi(() async => (await _api.categoryPage(ProfileRepositoryImpl.handle(username), _slug(slug))).toEntity());

  @override
  Future<Result<CursorPage<ArticleCard>>> getCategoryArticles(String username, String slug, {String? cursor, int limit = 20}) =>
      guardApi(() async {
        final page = await _api.categoryArticles(ProfileRepositoryImpl.handle(username), _slug(slug), cursor, limit);
        return CursorPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<WriterCategoryList>> getMyCategories() => guardApi(() async => (await _api.myCategories()).toEntity());

  @override
  Future<Result<WriterCategory>> create(String name) =>
      guardApi(() async => (await _api.create(CategoryNameRequest(name: name))).toEntity());

  @override
  Future<Result<WriterCategory>> rename(String id, String name) =>
      guardApi(() async => (await _api.rename(id, CategoryNameRequest(name: name))).toEntity());

  @override
  Future<Result<void>> delete(String id) => guardApi(() => _api.delete(id));

  @override
  Future<Result<WriterCategoryList>> reorder(List<String> categoryIds) =>
      guardApi(() async => (await _api.reorder(CategoryOrderRequest(categoryIds: categoryIds))).toEntity());

  @override
  Future<Result<void>> setArticleCategory(String articleId, String? categoryId) =>
      guardApi(() => _api.setArticleCategory(articleId, {'categoryId': categoryId}));
}
