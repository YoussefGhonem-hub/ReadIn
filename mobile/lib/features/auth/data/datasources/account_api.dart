import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_models.dart';

part 'account_api.g.dart';

/// The signed-in account (docs/api/contract-v1.md "Me"). Bearer calls on the main client.
@lazySingleton
@RestApi()
abstract class AccountApi {
  @factoryMethod
  factory AccountApi(Dio dio) = _AccountApi;

  @GET('/me')
  Future<MeModel> getMe();

  /// `200 SessionDto` for this device; every other session ends.
  @POST('/auth/logout-all')
  Future<SessionModel> logoutAll();

  /// Your own handle counts as available.
  @GET('/users/username-available')
  Future<UsernameAvailabilityModel> usernameAvailable(@Query('u') String username);

  @PUT('/me/profile/complete')
  Future<MeModel> completeProfile(@Body() CompleteProfileRequest body);

  @POST('/me/recovery-pin')
  Future<MeModel> setRecoveryPin(@Body() SetRecoveryPinRequest body);

  @PUT('/me/recovery-pin')
  Future<void> changeRecoveryPin(@Body() ChangeRecoveryPinRequest body);

  @PUT('/me/password')
  Future<SessionModel> changePassword(@Body() ChangePasswordRequest body);

  @PUT('/me/phone')
  Future<SessionModel> changePhone(@Body() ChangePhoneRequest body);

  /// `DELETE /me` with a JSON body.
  @DELETE('/me')
  Future<void> deleteAccount(@Body() DeleteAccountRequest body);
}
