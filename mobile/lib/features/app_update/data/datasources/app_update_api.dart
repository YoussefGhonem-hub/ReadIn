import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/update_policy_models.dart';

part 'app_update_api.g.dart';

/// `GET /app/update-policy` (anonymous). It runs on the client without the bearer/refresh interceptor (`authDio`), so
/// the check never waits on a token refresh.
@lazySingleton
@RestApi()
abstract class AppUpdateApi {
  @factoryMethod
  factory AppUpdateApi(@Named('authDio') Dio dio) = _AppUpdateApi;

  @GET('/app/update-policy')
  Future<UpdatePolicyModel> policy();
}
