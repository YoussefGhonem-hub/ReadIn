import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'interests_api.freezed.dart';
part 'interests_api.g.dart';

/// `UpdateInterestsRequest`.
@freezed
abstract class UpdateInterestsRequest with _$UpdateInterestsRequest {
  const factory UpdateInterestsRequest({required List<String> fieldIds, required List<String> topicIds}) =
      _UpdateInterestsRequest;

  factory UpdateInterestsRequest.fromJson(Map<String, dynamic> json) => _$UpdateInterestsRequestFromJson(json);
}

@lazySingleton
@RestApi()
abstract class InterestsApi {
  @factoryMethod
  factory InterestsApi(Dio dio) = _InterestsApi;

  @PUT('/me/interests')
  Future<void> update(@Body() UpdateInterestsRequest body);
}
