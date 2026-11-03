import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'devices_api.g.dart';

/// `RegisterDeviceRequest` (docs/api/contract-v1.md).
class RegisterDeviceRequest {
  const RegisterDeviceRequest({required this.token, required this.platform});

  final String token;

  /// `android` or `ios`.
  final String platform;

  Map<String, dynamic> toJson() => {'token': token, 'platform': platform};
}

@lazySingleton
@RestApi()
abstract class DevicesApi {
  @factoryMethod
  factory DevicesApi(Dio dio) = _DevicesApi;

  /// Upserts this device's FCM token for the signed-in user.
  @POST('/me/devices')
  Future<void> register(@Body() RegisterDeviceRequest body);
}
