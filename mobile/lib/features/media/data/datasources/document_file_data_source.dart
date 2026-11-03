import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads the original PDF through the app's Dio client, so the
/// `Authorization` and `Accept-Language` interceptors apply (the owner may
/// download even when `allowDownload` is off).
@lazySingleton
class DocumentFileDataSource {
  DocumentFileDataSource(this._dio);

  final Dio _dio;

  /// Saves to the temp directory as [fileName] and returns the path.
  Future<String> download(
    String url, {
    required String fileName,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final target = File('${dir.path}${Platform.pathSeparator}$fileName');
    await _dio.download(
      url,
      target.path,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      options: Options(responseType: ResponseType.bytes),
    );
    return target.path;
  }
}
