import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/quote_card.dart';

/// `POST /articles/{id}/quote-card` (SPEC F24) through the app's Dio client: the bearer token when signed in (guests
/// need none), the refresh on `401` and `Accept-Language` apply. The PNG stays in memory for the sheet's preview; Share
/// writes it to `<temp>/quote-card/{name}` (no storage permission; the OS empties it).
@lazySingleton
class QuoteCardDataSource {
  QuoteCardDataSource(this._dio, {@ignoreParam Future<Directory> Function()? temporaryDirectory})
      : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final Dio _dio;
  final Future<Directory> Function() _temporaryDirectory;

  /// The API waits up to 10 s for a build slot and then draws for up to 20 s; the contract asks for at least 40 s.
  static const receiveTimeout = Duration(seconds: 45);

  static const folder = 'quote-card';

  /// Throws [DioException] (its ProblemDetails come as bytes; `ApiErrorMapper` reads them) or [FormatException] when
  /// the answer isn't a PNG.
  Future<QuoteCardImage> make(QuoteCardRequest request) async {
    final response = await _dio.post<List<int>>(
      '/articles/${Uri.encodeComponent(request.articleId)}/quote-card',
      data: request.toJson(),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: receiveTimeout,
        // Errors stay ProblemDetails JSON.
        headers: {Headers.acceptHeader: 'image/png, application/problem+json'},
      ),
    );
    final bytes = response.data ?? const <int>[];
    if (!isPng(bytes)) throw const FormatException('The answer is not a PNG.');
    return QuoteCardImage(
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      fileName: QuoteCardFileName.fromContentDisposition(response.headers.map['content-disposition']?.firstOrNull),
    );
  }

  /// Writes [image] to `<temp>/quote-card/{fileName}` and returns the path. Throws [FileSystemException].
  Future<String> temporaryFile(QuoteCardImage image) async {
    final directory = Directory('${(await _temporaryDirectory()).path}${Platform.pathSeparator}$folder');
    await directory.create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}${image.fileName}');
    await file.writeAsBytes(image.bytes, flush: true);
    return file.path;
  }

  /// A PNG starts with `89 50 4E 47 0D 0A 1A 0A`.
  static bool isPng(List<int> bytes) =>
      bytes.length > 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
}
