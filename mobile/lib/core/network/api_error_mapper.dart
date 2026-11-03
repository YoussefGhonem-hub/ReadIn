import 'package:dio/dio.dart';

import '../errors/failure.dart';
import '../errors/result.dart';

/// Converts transport errors and RFC 9457 ProblemDetails into [Failure]s.
abstract final class ApiErrorMapper {
  static Failure fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure(FailureCodes.networkTimeout);
      case DioExceptionType.connectionError:
        return const Failure(FailureCodes.networkOffline);
      case DioExceptionType.cancel:
        return const Failure(FailureCodes.requestCancelled);
      default:
        break;
    }
    final response = e.response;
    if (response == null) return const Failure(FailureCodes.networkOffline);
    return fromProblem(response.statusCode, response.data);
  }

  static Failure fromProblem(int? status, Object? body) {
    if (body is Map) {
      final code = body['code'] as String? ?? _codeForStatus(status);
      final errors = <String, List<String>>{};
      final raw = body['errors'];
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value is List) errors['$key'] = value.map((v) => '$v').toList();
        });
      }
      return Failure(code, statusCode: status, message: body['title'] as String?, fieldErrors: errors);
    }
    return Failure(_codeForStatus(status), statusCode: status);
  }

  static String _codeForStatus(int? status) => switch (status) {
        400 => FailureCodes.validationFailed,
        401 => FailureCodes.authUnauthorized,
        403 => FailureCodes.authForbidden,
        429 => FailureCodes.rateLimited,
        _ => FailureCodes.serverError,
      };
}

/// Runs an API call and converts any thrown error into a [Result].
Future<Result<T>> guardApi<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on DioException catch (e) {
    return Err(ApiErrorMapper.fromDio(e));
  } on FormatException catch (e) {
    return Err(Failure(FailureCodes.serverError, message: e.message));
  } on TypeError catch (e) {
    return Err(Failure(FailureCodes.serverError, message: e.toString()));
  }
}
