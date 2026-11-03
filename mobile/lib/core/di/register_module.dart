import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import '../firebase/firebase_bootstrap.dart';
import '../l10n/current_locale.dart';
import '../network/interceptors.dart';
import '../network/request_context.dart';
import '../storage/key_value_store.dart';

@module
abstract class RegisterModule {
  @singleton
  AppConfig get config => AppConfig.fromEnvironment();

  @preResolve
  @singleton
  Future<FirebaseStatus> firebase(AppConfig config) => FirebaseBootstrap.init(config);

  @preResolve
  @singleton
  Future<KeyValueStore> keyValueStore() => HiveKeyValueStore.open();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// The API client: bearer token, single-flight refresh on `401` and retry (SPEC §9.3).
  @lazySingleton
  Dio dio(AppConfig config, SessionTokenProvider session, CurrentLocale locale, DeviceNameProvider device) {
    final dio = _apiClient(config);
    dio.interceptors.addAll([
      LanguageInterceptor(locale),
      DeviceNameInterceptor(device),
      AuthInterceptor(session, dio),
      if (config.flavor == Flavor.dev) LogInterceptor(requestBody: false, responseBody: false),
    ]);
    return dio;
  }

  /// For the anonymous `/auth/*` calls (sign in, refresh, recovery): no bearer token and no refresh, so refreshing
  /// never waits on its own queue.
  @Named('authDio')
  @lazySingleton
  Dio authDio(AppConfig config, CurrentLocale locale, DeviceNameProvider device) => _apiClient(config)
    ..interceptors.addAll([
      LanguageInterceptor(locale),
      DeviceNameInterceptor(device),
      if (config.flavor == Flavor.dev) LogInterceptor(requestBody: false, responseBody: false),
    ]);
}

Dio _apiClient(AppConfig config) => Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
