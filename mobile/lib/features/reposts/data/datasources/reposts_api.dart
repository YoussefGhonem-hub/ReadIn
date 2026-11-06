import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/repost_models.dart';

part 'reposts_api.g.dart';

/// Reposts (F29). Writes need `reposts.create`; guests never call them (the sign-in prompt comes first).
@lazySingleton
@RestApi()
abstract class RepostsApi {
  @factoryMethod
  factory RepostsApi(Dio dio) = _RepostsApi;

  /// A quick repost: no body (no caption on a new repost, the caption unchanged on an existing one).
  @PUT('/articles/{id}/repost')
  Future<RepostStateModel> repost(@Path('id') String articleId);

  /// Reposts with [body]'s caption, or only sets the caption of the viewer's repost ("" clears it).
  @PUT('/articles/{id}/repost')
  Future<RepostStateModel> repostWithCaption(@Path('id') String articleId, @Body() RepostRequest body);

  /// The viewer's repost of it now, with its caption (prefills "Edit your thoughts").
  @GET('/articles/{id}/repost')
  Future<RepostStateModel> getRepost(@Path('id') String articleId);

  @DELETE('/articles/{id}/repost')
  Future<RepostStateModel> undoRepost(@Path('id') String articleId);
}
