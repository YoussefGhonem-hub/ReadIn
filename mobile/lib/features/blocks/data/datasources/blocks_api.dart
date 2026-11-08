import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/block_models.dart';

part 'blocks_api.g.dart';

/// Block (F36). Every route needs a session; writes need `users.block`.
@lazySingleton
@RestApi()
abstract class BlocksApi {
  @factoryMethod
  factory BlocksApi(Dio dio) = _BlocksApi;

  @PUT('/users/{id}/block')
  Future<UserBlockStateModel> block(@Path('id') String userId);

  /// [restoreFollow] is left out (null) unless it is true.
  @DELETE('/users/{id}/block')
  Future<UserBlockStateModel> unblock(@Path('id') String userId, @Query('restoreFollow') bool? restoreFollow);

  @GET('/me/blocked')
  Future<BlockedUsersModel> blocked();
}
