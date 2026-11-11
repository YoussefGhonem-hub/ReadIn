import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/devotion_models.dart';

part 'duas_api.g.dart';

/// The account's own du'as (F38). Every route needs a session and `devotions.access` (only the SuperAdmin).
@lazySingleton
@RestApi()
abstract class DuasApi {
  @factoryMethod
  factory DuasApi(Dio dio) = _DuasApi;

  @GET('/me/duas')
  Future<List<PersonalDuaModel>> list();

  @POST('/me/duas')
  Future<PersonalDuaModel> create(@Body() DuaBody body);

  @PATCH('/me/duas/{id}')
  Future<PersonalDuaModel> update(@Path('id') String id, @Body() DuaBody body);

  @DELETE('/me/duas/{id}')
  Future<void> delete(@Path('id') String id);
}
