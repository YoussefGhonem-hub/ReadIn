import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/article_pdf.dart';

/// `GET /articles/{id}/pdf?lang=` (SPEC F33) through the app's Dio client, so the bearer token, the refresh on `401`
/// and `Accept-Language` apply. The bytes go to `<temp>/article-pdf/{name}`: no storage permission, and the OS (or
/// deleting the account) empties it.
@lazySingleton
class ArticlePdfDataSource {
  ArticlePdfDataSource(this._dio, {@ignoreParam Future<Directory> Function()? temporaryDirectory})
      : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final Dio _dio;
  final Future<Directory> Function() _temporaryDirectory;

  /// The API may wait 30 s for a build slot and then build for up to 60 s; the contract asks for at least 100 s.
  static const receiveTimeout = Duration(seconds: 110);

  static const folder = 'article-pdf';

  /// Throws [DioException] (its ProblemDetails come as bytes; `ApiErrorMapper` reads them), [FormatException] when
  /// the answer isn't a PDF, or [FileSystemException].
  Future<ArticlePdf> download(String articleId, {required String language}) async {
    final response = await _dio.get<List<int>>(
      '/articles/${Uri.encodeComponent(articleId)}/pdf',
      queryParameters: {'lang': language},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: receiveTimeout,
        // Errors stay ProblemDetails JSON.
        headers: {Headers.acceptHeader: 'application/pdf, application/problem+json'},
      ),
    );
    final bytes = response.data ?? const <int>[];
    if (!_isPdf(bytes)) throw const FormatException('The answer is not a PDF.');
    final name = ArticlePdfFileName.fromContentDisposition(response.headers.map['content-disposition']?.firstOrNull);
    final directory = Directory('${(await _temporaryDirectory()).path}${Platform.pathSeparator}$folder');
    await directory.create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return ArticlePdf(path: file.path, fileName: name);
  }

  /// A PDF starts with `%PDF-`.
  static bool _isPdf(List<int> bytes) =>
      bytes.length > 5 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46 && bytes[4] == 0x2D;
}
