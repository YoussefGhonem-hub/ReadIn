import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/transfer.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/media.dart';
import '../../domain/repositories/media_repository.dart';
import '../datasources/document_file_data_source.dart';
import '../datasources/image_compressor.dart';
import '../datasources/media_api.dart';

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._api, this._compressor, this._files);

  final MediaApi _api;
  final ImageCompressor _compressor;
  final DocumentFileDataSource _files;

  static const _cancelled = Err<MediaAsset>(Failure(FailureCodes.requestCancelled));

  @override
  Future<Result<MediaAsset>> uploadImage(PickedMediaFile file, {TransferToken? token, TransferProgress? onProgress}) async {
    final compressed = await _compressor.compress(file.path);
    if (token?.isCancelled ?? false) return _cancelled;
    return _guard(() async {
      final part = compressed != null
          ? MultipartFile.fromBytes(compressed, filename: '${_baseName(file.name)}.jpg', contentType: DioMediaType('image', 'jpeg'))
          : await MultipartFile.fromFile(file.path, filename: file.name, contentType: imageMediaType(file.name));
      final model = await _api.uploadImage(part, 'image', onSendProgress: onProgress, cancelToken: _bridge(token));
      return model.toEntity();
    });
  }

  @override
  Future<Result<MediaAsset>> uploadDocument(
    PickedMediaFile file, {
    required String title,
    required bool allowDownload,
    TransferToken? token,
    TransferProgress? onProgress,
  }) =>
      _guard(() async {
        final part = await MultipartFile.fromFile(file.path, filename: file.name, contentType: DioMediaType('application', 'pdf'));
        final model = await _api.uploadDocument(
          part,
          title,
          allowDownload ? 'true' : 'false',
          onSendProgress: onProgress,
          cancelToken: _bridge(token),
        );
        return model.toEntity();
      });

  @override
  Future<Result<MediaAsset>> getUpload(String id) => guardApi(() async => (await _api.getUpload(id)).toEntity());

  @override
  Future<Result<void>> deleteUpload(String id) => guardApi(() => _api.deleteUpload(id));

  @override
  Future<Result<String>> downloadDocument(
    String url, {
    required String fileName,
    TransferToken? token,
    TransferProgress? onProgress,
  }) =>
      _guard(() => _files.download(url, fileName: pdfFileName(fileName), cancelToken: _bridge(token), onReceiveProgress: onProgress));

  static CancelToken? _bridge(TransferToken? token) {
    if (token == null) return null;
    final cancelToken = CancelToken();
    token.onCancel(cancelToken.cancel);
    return cancelToken;
  }

  static Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return await guardApi(call);
    } on FileSystemException catch (e) {
      return Err(Failure(FailureCodes.mediaFileRequired, message: e.message));
    }
  }

  static String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return base.isEmpty ? 'image' : base;
  }

  /// Content type for an uncompressed original (jpeg/png/webp/heic per the contract).
  static DioMediaType imageMediaType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      'heic' || 'heif' => DioMediaType('image', 'heic'),
      _ => DioMediaType('image', 'jpeg'),
    };
  }
}
