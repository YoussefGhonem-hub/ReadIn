import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../article/data/models/article_models.dart';

part 'feed_api.g.dart';

@lazySingleton
@RestApi()
abstract class FeedApi {
  @factoryMethod
  factory FeedApi(Dio dio) = _FeedApi;

  /// 200 with an `ArticleCardDto`, or 204 when there is no pick yet — so the
  /// raw response is returned and decoded by the repository.
  @GET('/feed/today')
  Future<HttpResponse<dynamic>> getToday();

  @GET('/feed/for-you')
  Future<ArticleCardPageModel> getForYou(
    @Query('field') String? field,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// Published articles by the people the viewer follows, newest first (F12; needs a session).
  @GET('/feed/following')
  Future<ArticleCardPageModel> getFollowing(@Query('cursor') String? cursor, @Query('limit') int limit);
}
