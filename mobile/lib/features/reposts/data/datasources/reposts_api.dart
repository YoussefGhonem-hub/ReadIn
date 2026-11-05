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

  @PUT('/articles/{id}/repost')
  Future<RepostStateModel> repost(@Path('id') String articleId);

  @DELETE('/articles/{id}/repost')
  Future<RepostStateModel> undoRepost(@Path('id') String articleId);
}
