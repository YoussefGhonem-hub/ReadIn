import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// `GET /admin/verification-requests/{id}/proof` (F19, `verification.manage`) through the app's Dio client, so the
/// bearer token and its refresh apply. The file is private: it is read into memory and handed to the system's "Save
/// as" dialog, never cached.
@lazySingleton
class VerificationProofDataSource {
  VerificationProofDataSource(this._dio);

  final Dio _dio;

  /// Throws [DioException] (its ProblemDetails come as bytes; `ApiErrorMapper` reads them).
  Future<Uint8List> download(String requestId) async {
    final response = await _dio.get<List<int>>(
      '/admin/verification-requests/${Uri.encodeComponent(requestId)}/proof',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }
}
