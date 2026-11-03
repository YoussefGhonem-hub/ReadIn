import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_models.dart';

part 'auth_api.g.dart';

/// Anonymous `/auth/*` endpoints (SPEC §9, docs/api/contract-v1.md "Auth"). They run on [authDioName], a client without
/// the bearer/refresh interceptor, so a refresh can never wait on itself.
@lazySingleton
@RestApi()
abstract class AuthApi {
  @factoryMethod
  factory AuthApi(@Named(authDioName) Dio dio) = _AuthApi;

  static const authDioName = 'authDio';

  @GET('/auth/config')
  Future<AuthConfigModel> config();

  @POST('/auth/register')
  Future<SessionModel> register(@Body() RegisterRequest body);

  @POST('/auth/login')
  Future<SessionModel> login(@Body() LoginRequest body);

  /// Google / Apple (ADR 0012). `404 auth.external_not_linked`: ask again with `createAccount` or `link`.
  @POST('/auth/external')
  Future<SessionModel> external(@Body() ExternalSignInRequest body);

  /// Rotates the refresh token: always keep the one in the response.
  @POST('/auth/refresh')
  Future<SessionModel> refresh(@Body() RefreshRequest body);

  /// `204` always.
  @POST('/auth/logout')
  Future<void> logout(@Body() RefreshRequest body);

  @POST('/auth/recovery/verify-pin')
  Future<ResetTokenModel> verifyPin(@Body() VerifyPinRequest body);

  @POST('/auth/recovery/reset-password')
  Future<void> resetPassword(@Body() ResetPasswordRequest body);
}
