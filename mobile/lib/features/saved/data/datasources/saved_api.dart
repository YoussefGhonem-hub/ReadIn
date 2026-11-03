import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/saved_models.dart';

part 'saved_api.g.dart';

/// Saved articles and collections (F13, permission `saved.manage`).
@lazySingleton
@RestApi()
abstract class SavedApi {
  @factoryMethod
  factory SavedApi(Dio dio) = _SavedApi;

  @PUT('/me/saved/{articleId}')
  Future<SaveStateModel> save(@Path('articleId') String articleId);

  @DELETE('/me/saved/{articleId}')
  Future<SaveStateModel> unsave(@Path('articleId') String articleId);

  /// `field` = field slug, `q` = title search, `collection` = collection id.
  @GET('/me/saved')
  Future<SavedArticlePageModel> getSaved(
    @Query('field') String? field,
    @Query('q') String? q,
    @Query('collection') String? collection,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/me/collections')
  Future<List<CollectionModel>> getCollections();

  @POST('/me/collections')
  Future<CollectionModel> createCollection(@Body() CollectionNameRequest body);

  @PATCH('/me/collections/{id}')
  Future<CollectionModel> renameCollection(@Path('id') String id, @Body() CollectionNameRequest body);

  @DELETE('/me/collections/{id}')
  Future<void> deleteCollection(@Path('id') String id);

  @PUT('/me/collections/{id}/articles/{articleId}')
  Future<void> addToCollection(@Path('id') String id, @Path('articleId') String articleId);

  @DELETE('/me/collections/{id}/articles/{articleId}')
  Future<void> removeFromCollection(@Path('id') String id, @Path('articleId') String articleId);
}
