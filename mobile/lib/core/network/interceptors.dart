import 'package:dio/dio.dart';

import '../l10n/current_locale.dart';
import 'request_context.dart';

/// `/auth/*` calls sign in, refresh or sign out themselves, so they never get a bearer token and a `401` from them is
/// an answer (wrong password, expired refresh token), not a reason to refresh. `logout-all` is the exception: it
/// needs the bearer token.
bool isAnonymousAuthCall(String path) => path.startsWith('/auth/') && path != '/auth/logout-all';

/// Calls whose response is a new session; they carry `X-Device-Name` so the session list can name this device.
bool issuesSession(String path) => path.startsWith('/auth/') || path == '/me/password' || path == '/me/phone';

/// Adds `Authorization: Bearer <access token>` and, on a `401` from any other call, refreshes once (single-flight,
/// see [SessionTokenProvider]) and retries the call (SPEC §9.3). Queued, so calls wait while a refresh runs.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._session, this._dio);

  final SessionTokenProvider _session;
  final Dio _dio;
  static const _retriedKey = 'auth.retried';
  static const _tokenKey = 'auth.token';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!isAnonymousAuthCall(options.path)) {
      final token = await _session.accessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_tokenKey] = token;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final rejected = options.extra[_tokenKey];
    if (err.response?.statusCode != 401 ||
        isAnonymousAuthCall(options.path) ||
        options.extra[_retriedKey] == true ||
        rejected is! String) {
      return handler.next(err);
    }
    final token = await _session.refreshAfterRejection(rejected);
    if (token == null) return handler.next(err);
    try {
      options
        ..headers['Authorization'] = 'Bearer $token'
        ..extra[_tokenKey] = token
        ..extra[_retriedKey] = true;
      // A multipart body is finalized once sent; uploads need a fresh copy.
      final data = options.data;
      if (data is FormData) options.data = data.clone();
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// `X-Device-Name: Pixel 8` on calls that issue a session (SPEC §9.3).
class DeviceNameInterceptor extends Interceptor {
  DeviceNameInterceptor(this._device);

  final DeviceNameProvider _device;
  static const header = 'X-Device-Name';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (issuesSession(options.path)) {
      final name = await _device.deviceName();
      if (name != null && name.isNotEmpty) options.headers[header] = name;
    }
    handler.next(options);
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
