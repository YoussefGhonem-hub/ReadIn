import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// `GET /support/attachments/{id}` (F35): a screenshot of a ticket, for its member or `support.manage`. It goes
/// through the app's Dio client, so the bearer token and its refresh apply; the bytes stay in memory only.
@lazySingleton
class SupportAttachmentDataSource {
  SupportAttachmentDataSource(this._dio);

  final Dio _dio;

  /// Throws [DioException] (its ProblemDetails come as bytes; `ApiErrorMapper` reads them).
  Future<Uint8List> download(String attachmentId) async {
    final response = await _dio.get<List<int>>(
      '/support/attachments/${Uri.encodeComponent(attachmentId)}',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }
}
