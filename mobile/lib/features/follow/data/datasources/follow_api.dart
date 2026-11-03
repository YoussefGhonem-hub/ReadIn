import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/follow_models.dart';

part 'follow_api.g.dart';

/// Follow (F12). Writes need `follows.manage`; follower lists are public, suggestions need a session.
@lazySingleton
@RestApi()
abstract class FollowApi {
  @factoryMethod
  factory FollowApi(Dio dio) = _FollowApi;

  @PUT('/users/{id}/follow')
  Future<FollowStateModel> follow(@Path('id') String userId);

  @DELETE('/users/{id}/follow')
  Future<FollowStateModel> unfollow(@Path('id') String userId);

  @GET('/users/{id}/followers')
  Future<UserSummaryPageModel> getFollowers(
    @Path('id') String userId,
    @Query('q') String? q,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/users/{id}/following')
  Future<UserSummaryPageModel> getFollowing(
    @Path('id') String userId,
    @Query('q') String? q,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @GET('/users/suggested')
  Future<List<UserSummaryModel>> getSuggested(@Query('limit') int limit);

  @PUT('/me/interests/fields/{fieldId}')
  Future<InterestsModel> followField(@Path('fieldId') String fieldId);

  @DELETE('/me/interests/fields/{fieldId}')
  Future<InterestsModel> unfollowField(@Path('fieldId') String fieldId);

  @PUT('/me/interests/topics/{topicId}')
  Future<InterestsModel> followTopic(@Path('topicId') String topicId);

  @DELETE('/me/interests/topics/{topicId}')
  Future<InterestsModel> unfollowTopic(@Path('topicId') String topicId);
}
