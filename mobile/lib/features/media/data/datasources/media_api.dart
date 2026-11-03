import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/media_models.dart';

part 'media_api.g.dart';

/// Media endpoints (docs/api/contract-v1.md "Media", ADR 0011).
@lazySingleton
@RestApi()
abstract class MediaApi {
  @factoryMethod
  factory MediaApi(Dio dio) = _MediaApi;

  /// `201 MediaAssetDto` with `status: ready` (images are processed in the request).
  @POST('/uploads/images')
  @MultiPart()
  Future<MediaAssetModel> uploadImage(
    @Part(name: 'file') MultipartFile file,
    @Part(name: 'purpose') String purpose, {
    @SendProgress() ProgressCallback? onSendProgress,
    @CancelRequest() CancelToken? cancelToken,
  });

  /// `202 MediaAssetDto` with `status: processing` and `pageCount` set.
  @POST('/uploads/documents')
  @MultiPart()
  Future<MediaAssetModel> uploadDocument(
    @Part(name: 'file') MultipartFile file,
    @Part(name: 'title') String title,
    @Part(name: 'allowDownload') String allowDownload, {
    @SendProgress() ProgressCallback? onSendProgress,
    @CancelRequest() CancelToken? cancelToken,
  });

  @GET('/uploads/{id}')
  Future<MediaAssetModel> getUpload(@Path('id') String id);

  @DELETE('/uploads/{id}')
  Future<void> deleteUpload(@Path('id') String id);
}
