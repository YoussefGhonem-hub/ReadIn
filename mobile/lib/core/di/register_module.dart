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

  @lazySingleton
  Dio dio(AppConfig config, IdTokenProvider tokens, CurrentLocale locale) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll([
      LanguageInterceptor(locale),
      AuthInterceptor(tokens, dio),
      if (config.flavor == Flavor.dev) LogInterceptor(requestBody: false, responseBody: false),
    ]);
    return dio;
  }
}
