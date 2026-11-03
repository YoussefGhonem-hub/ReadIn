import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'realtime_token_api.g.dart';

/// Firebase custom token whose `uid` is the ReadIn user id; it only grants reads of `/live/users/{id}`.
class RealtimeToken {
  const RealtimeToken(this.token);

  factory RealtimeToken.fromJson(Map<String, dynamic> json) => RealtimeToken(json['token'] as String);

  final String token;
}

@lazySingleton
@RestApi()
abstract class RealtimeTokenApi {
  @factoryMethod
  factory RealtimeTokenApi(Dio dio) = _RealtimeTokenApi;

  /// `POST /realtime/token` (SPEC §17.2).
  @POST('/realtime/token')
  Future<RealtimeToken> token();
}
