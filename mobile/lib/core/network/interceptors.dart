import 'package:dio/dio.dart';

import '../l10n/current_locale.dart';
import 'request_context.dart';

/// Adds `Authorization: Bearer <Firebase ID token>` when signed in, and retries
/// once with a refreshed token on 401 (SPEC §9.2, §24).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokens, this._dio);

  final IdTokenProvider _tokens;
  final Dio _dio;
  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.idToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    final token = await _tokens.idToken(forceRefresh: true);
    if (token == null) return handler.next(err);
    try {
      options
        ..headers['Authorization'] = 'Bearer $token'
        ..extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// `Accept-Language: ar|en` controls error messages and taxonomy names (SPEC §17.1).
class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this._locale);

  final CurrentLocale _locale;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _locale.languageCode;
    handler.next(options);
  }
}
