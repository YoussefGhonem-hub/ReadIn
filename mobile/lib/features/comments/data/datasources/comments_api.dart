import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../moderation/data/models/moderation_models.dart';
import '../models/comment_models.dart';

part 'comments_api.g.dart';

/// Comments and replies (F11), moderator actions on comments (F22), @mention suggestions.
/// Reads are public; writes need a session.
@lazySingleton
@RestApi()
abstract class CommentsApi {
  @factoryMethod
  factory CommentsApi(Dio dio) = _CommentsApi;

  /// `sort` = `top` | `new`.
  @GET('/articles/{id}/comments')
  Future<CommentPageModel> getComments(
    @Path('id') String articleId,
    @Query('sort') String sort,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/comments/{id}/replies')
  Future<CommentRepliesPageModel> getReplies(
    @Path('id') String commentId,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/comments/{id}')
  Future<CommentModel> getComment(@Path('id') String commentId);

  @POST('/articles/{id}/comments')
  Future<CommentModel> postComment(@Path('id') String articleId, @Body() CommentBodyRequest body);

  @POST('/comments/{id}/replies')
  Future<CommentModel> postReply(@Path('id') String commentId, @Body() CommentBodyRequest body);

  @PATCH('/comments/{id}')
  Future<CommentModel> editComment(@Path('id') String commentId, @Body() CommentBodyRequest body);

  @DELETE('/comments/{id}')
  Future<void> deleteComment(@Path('id') String commentId);

  @PUT('/comments/{id}/like')
  Future<CommentLikeModel> like(@Path('id') String commentId);

  @DELETE('/comments/{id}/like')
  Future<CommentLikeModel> unlike(@Path('id') String commentId);

  @POST('/comments/{id}/pin')
  Future<CommentModel> pin(@Path('id') String commentId);

  @DELETE('/comments/{id}/pin')
  Future<CommentModel> unpin(@Path('id') String commentId);

  @GET('/users/mention-suggestions')
  Future<List<MentionCandidateModel>> mentionSuggestions(@Query('q') String query, @Query('limit') int limit);

  @POST('/moderation/actions')
  Future<void> moderate(@Body() ModerationActionRequest body);
}
