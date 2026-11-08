import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/legal_models.dart';

part 'legal_api.g.dart';

/// Legal (F37): `GET /legal` is public.
@lazySingleton
@RestApi()
abstract class LegalApi {
  @factoryMethod
  factory LegalApi(Dio dio) = _LegalApi;

  @GET('/legal')
  Future<LegalModel> getLegal();
}
