import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/article_editor_models.dart';

part 'article_editor_api.g.dart';

/// The F05 editor endpoints (Bearer, permission `articles.create`): "My articles", the working copy, publish,
/// revisions and tag suggestions.
@lazySingleton
@RestApi()
abstract class ArticleEditorApi {
  @factoryMethod
  factory ArticleEditorApi(Dio dio) = _ArticleEditorApi;

  /// Drafts: never published, newest edit first. Published: newest publish first.
  @GET('/me/articles')
  Future<MyArticlePageModel> myArticles(
    @Query('status') String status, {
    @Query('cursor') String? cursor,
    @Query('limit') int limit = 20,
  });

  /// `201`: a never-published draft (lenient validation).
  @POST('/articles')
  Future<ArticleEditModel> create(@Body() ArticleDraftDocumentModel body);

  /// Owner only; anyone else gets `404 article.not_found`.
  @GET('/articles/{id}/edit')
  Future<ArticleEditModel> getForEdit(@Path('id') String id);

  /// Autosave: replaces the whole working copy. `409 article.draft_conflict` when `baseVersion` is stale.
  @PUT('/articles/{id}/draft')
  Future<ArticleEditModel> saveDraft(@Path('id') String id, @Body() SaveDraftRequestModel body);

  /// Discards a published article's unpublished changes (`409 article.not_published` on a draft).
  @DELETE('/articles/{id}/draft')
  Future<ArticleEditModel> discardChanges(@Path('id') String id);

  /// First publish, or "Update" of a published article.
  @POST('/articles/{id}/publish')
  Future<PublishedArticleModel> publish(@Path('id') String id, @Body() BaseVersionRequestModel body);

  /// Newest first, one per publish/update.
  @GET('/articles/{id}/revisions')
  Future<List<ArticleRevisionModel>> revisions(@Path('id') String id);

  @GET('/articles/{id}/revisions/{number}')
  Future<ArticleRevisionDetailsModel> revision(@Path('id') String id, @Path('number') int number);

  /// Copies the revision into the working copy (not live until Update).
  @POST('/articles/{id}/revisions/{number}/restore')
  Future<ArticleEditModel> restoreRevision(
    @Path('id') String id,
    @Path('number') int number,
    @Body() BaseVersionRequestModel body,
  );

  /// `204`: drafts are deleted at once; published articles leave the feeds.
  @DELETE('/articles/{id}')
  Future<void> deleteArticle(@Path('id') String id);

  /// Tags whose name or slug starts with [query], most used first.
  @GET('/tags')
  Future<List<TagModel>> tags(@Query('q') String query, {@Query('limit') int limit = 10});
}
