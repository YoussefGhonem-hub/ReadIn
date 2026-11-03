import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/reaction_models.dart';

part 'reactions_api.g.dart';

/// Reactions (F10). Writes need `reactions.create`; the list is public.
@lazySingleton
@RestApi()
abstract class ReactionsApi {
  @factoryMethod
  factory ReactionsApi(Dio dio) = _ReactionsApi;

  @PUT('/articles/{id}/reaction')
  Future<ArticleReactionsModel> react(@Path('id') String articleId, @Body() SetReactionRequest body);

  @DELETE('/articles/{id}/reaction')
  Future<ArticleReactionsModel> removeReaction(@Path('id') String articleId);

  @GET('/articles/{id}/reactions')
  Future<ReactorPageModel> getReactors(
    @Path('id') String articleId,
    @Query('type') String? type,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );
}
