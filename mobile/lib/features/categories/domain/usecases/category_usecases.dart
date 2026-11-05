import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/writer_category.dart';
import '../repositories/categories_repository.dart';

/// A profile's Categories tab (F31): the categories with articles readers can see, and "مقالات تانية".
@injectable
class GetUserCategories {
  const GetUserCategories(this._repository);

  final CategoriesRepository _repository;

  Future<Result<WriterCategoryList>> call(String username) => _repository.getUserCategories(username);
}

/// The category page's header.
@injectable
class GetCategoryPage {
  const GetCategoryPage(this._repository);

  final CategoriesRepository _repository;

  Future<Result<WriterCategoryPage>> call(String username, String slug) => _repository.getCategoryPage(username, slug);
}

/// The category page's articles, newest first.
@injectable
class GetCategoryArticles {
  const GetCategoryArticles(this._repository);

  final CategoriesRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ArticleCard>>> call(String username, String slug, {String? cursor}) =>
      _repository.getCategoryArticles(username, slug, cursor: cursor, limit: pageSize);
}

/// The writer's own categories, empty ones included: the own Categories tab and the editor's picker.
@injectable
class GetMyCategories {
  const GetMyCategories(this._repository);

  final CategoriesRepository _repository;

  Future<Result<WriterCategoryList>> call() => _repository.getMyCategories();
}

/// Create, rename, delete and reorder the writer's categories.
@injectable
class ManageCategories {
  const ManageCategories(this._repository);

  final CategoriesRepository _repository;

  Future<Result<WriterCategory>> create(String name) => _repository.create(name);

  Future<Result<WriterCategory>> rename(String id, String name) => _repository.rename(id, name);

  Future<Result<void>> delete(String id) => _repository.delete(id);

  Future<Result<WriterCategoryList>> reorder(List<String> categoryIds) => _repository.reorder(categoryIds);
}

/// Puts an article (draft or published) in a category, or in none with null. Applies at once.
@injectable
class SetArticleCategory {
  const SetArticleCategory(this._repository);

  final CategoriesRepository _repository;

  Future<Result<void>> call(String articleId, String? categoryId) => _repository.setArticleCategory(articleId, categoryId);
}
