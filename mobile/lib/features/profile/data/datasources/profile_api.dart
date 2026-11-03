import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../article/data/models/article_models.dart';
import '../models/profile_models.dart';

part 'profile_api.g.dart';

/// Profiles (F14). Reads are public (guests allowed); `PATCH /me` and `PUT /me/privacy` need a session.
@lazySingleton
@RestApi()
abstract class ProfileApi {
  @factoryMethod
  factory ProfileApi(Dio dio) = _ProfileApi;

  @GET('/users/{username}')
  Future<ProfileModel> getProfile(@Path('username') String username);

  @GET('/users/{username}/articles')
  Future<ArticleCardPageModel> getArticles(
    @Path('username') String username,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @PATCH('/me')
  Future<void> updateProfile(@Body() UpdateProfileRequest body);

  @PUT('/me/privacy')
  Future<void> setPrivacy(@Body() PrivacyRequest body);
}
