import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/verification_models.dart';

part 'verification_api.g.dart';

/// Writer verification, the requester's side (F19). Bearer only; the request uses the `writes` rate limit.
@lazySingleton
@RestApi()
abstract class VerificationApi {
  @factoryMethod
  factory VerificationApi(Dio dio) = _VerificationApi;

  @GET('/me/verification')
  Future<VerificationStatusModel> status();

  /// `multipart/form-data`: `fieldId`, `jobTitle`, `proofUrl?`, `note?`, `proof?` (the file). Parts left null are not
  /// sent. `201 MyVerificationRequestDto`.
  @POST('/verification-requests')
  @MultiPart()
  Future<MyVerificationRequestModel> submit(
    @Part(name: 'fieldId') String fieldId,
    @Part(name: 'jobTitle') String jobTitle, {
    @Part(name: 'proofUrl') String? proofUrl,
    @Part(name: 'note') String? note,
    @Part(name: 'proof') MultipartFile? proof,
  });

  @DELETE('/me/verification')
  Future<void> withdraw();
}
