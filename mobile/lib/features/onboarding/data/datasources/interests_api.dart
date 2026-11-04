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

  /// Follows one field or topic after onboarding (F02, F12): `200 InterestsDto` (idempotent); the app re-reads `/me`.
  /// [kind] is `fields` or `topics`.
  @PUT('/me/interests/{kind}/{id}')
  Future<void> follow(@Path('kind') String kind, @Path('id') String id);

  /// `400 user.interests.min_three` when fewer than 3 interests would remain.
  @DELETE('/me/interests/{kind}/{id}')
  Future<void> unfollow(@Path('kind') String kind, @Path('id') String id);
}
