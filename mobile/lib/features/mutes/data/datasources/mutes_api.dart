import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/mute_models.dart';

part 'mutes_api.g.dart';

/// Mute & feedback (F28). Every route needs a session; writes need `follows.manage`.
@lazySingleton
@RestApi()
abstract class MutesApi {
  @factoryMethod
  factory MutesApi(Dio dio) = _MutesApi;

  @PUT('/users/{id}/mute')
  Future<UserMuteStateModel> muteUser(@Path('id') String userId);

  /// [restoreFollow] is left out (null) unless it is true.
  @DELETE('/users/{id}/mute')
  Future<UserMuteStateModel> unmuteUser(@Path('id') String userId, @Query('restoreFollow') bool? restoreFollow);

  @PUT('/me/mutes/fields/{id}')
  Future<ContentMutesModel> muteField(@Path('id') String fieldId);

  @DELETE('/me/mutes/fields/{id}')
  Future<ContentMutesModel> unmuteField(@Path('id') String fieldId);

  @PUT('/me/mutes/topics/{id}')
  Future<ContentMutesModel> muteTopic(@Path('id') String topicId);

  @DELETE('/me/mutes/topics/{id}')
  Future<ContentMutesModel> unmuteTopic(@Path('id') String topicId);

  @GET('/me/mutes')
  Future<MutesModel> getMutes();

  @PUT('/articles/{id}/show-less')
  Future<void> showLess(@Path('id') String articleId);

  @DELETE('/articles/{id}/show-less')
  Future<void> undoShowLess(@Path('id') String articleId);
}
