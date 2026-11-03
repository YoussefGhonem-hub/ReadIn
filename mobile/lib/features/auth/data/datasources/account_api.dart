import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/me_model.dart';

part 'account_api.g.dart';

@lazySingleton
@RestApi()
abstract class AccountApi {
  @factoryMethod
  factory AccountApi(Dio dio) = _AccountApi;

  @POST('/auth/sync')
  Future<MeModel> sync(@Body() SyncUserRequest body);

  @GET('/me')
  Future<MeModel> getMe();
}
