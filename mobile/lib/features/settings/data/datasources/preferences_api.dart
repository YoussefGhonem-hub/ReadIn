import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/update_preferences_request.dart';

part 'preferences_api.g.dart';

@lazySingleton
@RestApi()
abstract class PreferencesApi {
  @factoryMethod
  factory PreferencesApi(Dio dio) = _PreferencesApi;

  @PUT('/me/preferences')
  Future<void> update(@Body() UpdatePreferencesRequest body);
}
