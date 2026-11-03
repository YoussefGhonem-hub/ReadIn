import 'package:flutter/foundation.dart';

enum Flavor { dev, staging, prod }

/// Build-time configuration. Pass with
/// `flutter run --dart-define-from-file=config/dev.json` (or staging/prod),
/// or override single values with `--dart-define=API_BASE_URL=...`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.useFirebaseEmulator,
    required this.emulatorHost,
  });

  final Flavor flavor;
  final String apiBaseUrl;
  final bool useFirebaseEmulator;

  /// Host for local services: `10.0.2.2` from the Android emulator, `localhost` elsewhere.
  final String emulatorHost;

  static const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: true);

  factory AppConfig.fromEnvironment() {
    final flavor = Flavor.values.firstWhere((f) => f.name == _flavor, orElse: () => Flavor.dev);
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: _apiBaseUrl.isNotEmpty ? _apiBaseUrl : 'http://$host:5080/api/v1',
      useFirebaseEmulator: flavor == Flavor.dev && _useEmulator,
      emulatorHost: host,
    );
  }
}
