import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../article/data/models/article_models.dart';
import '../models/category_models.dart';

part 'categories_api.g.dart';

/// Writer categories (F31). The reads are public (guests allowed; a Bearer fills the viewer's reaction, save and follow
/// on the cards); `/me/categories` and `PUT /articles/{id}/category` need a session (`articles.create`).
@lazySingleton
@RestApi()
abstract class CategoriesApi {
  @factoryMethod
  factory CategoriesApi(Dio dio) = _CategoriesApi;

  /// A profile's Categories tab: the categories with articles readers can see, in the writer's order, and the
  /// uncategorized count. `404 user.not_found`.
  @GET('/users/{username}/categories')
  Future<WriterCategoryListModel> userCategories(@Path('username') String username);

  /// The category page's header (`_other`: the uncategorized list). `404 category.not_found` / `user.not_found`.
  @GET('/users/{username}/categories/{slug}')
  Future<WriterCategoryPageModel> categoryPage(@Path('username') String username, @Path('slug') String slug);

  /// The category's articles, newest first. Same `404`s.
  @GET('/users/{username}/categories/{slug}/articles')
  Future<ArticleCardPageModel> categoryArticles(
    @Path('username') String username,
    @Path('slug') String slug,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// All your categories, empty ones included, in your order.
  @GET('/me/categories')
  Future<WriterCategoryListModel> myCategories();

  /// `201`, added last. `400 category.limit`, `409 category.name_taken`, `400 validation.failed` (`category.name_invalid`).
  @POST('/me/categories')
  Future<WriterCategoryModel> create(@Body() CategoryNameRequest body);

  /// Renames; the slug stays.
  @PATCH('/me/categories/{id}')
  Future<WriterCategoryModel> rename(@Path('id') String id, @Body() CategoryNameRequest body);

  /// `204`: its articles stay published and become uncategorized.
  @DELETE('/me/categories/{id}')
  Future<void> delete(@Path('id') String id);

  /// Your categories in the order sent → the list as `GET /me/categories`.
  @PUT('/me/categories/order')
  Future<WriterCategoryListModel> reorder(@Body() CategoryOrderRequest body);

  /// `{ categoryId: string | null }` → `204`. A map, so `null` (no category) is sent rather than left out.
  @PUT('/articles/{id}/category')
  Future<void> setArticleCategory(@Path('id') String articleId, @Body() Map<String, dynamic> body);
}
