import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/l10n/current_locale.dart';
import '../../../app_update/data/datasources/installed_app_source.dart';
import '../../domain/entities/support.dart';

/// What the app adds to a ticket (F35): the platform, the OS version, the app's version and build, the UI language and
/// the screen it came from. No device identifier. Anything the platform can't say is left out.
abstract interface class SupportDeviceSource {
  Future<SupportDevice> read({String? screen});
}

@LazySingleton(as: SupportDeviceSource)
class PlatformSupportDeviceSource implements SupportDeviceSource {
  PlatformSupportDeviceSource(this._app, this._locale);

  final InstalledAppSource _app;
  final CurrentLocale _locale;

  Future<String?>? _os;

  @override
  Future<SupportDevice> read({String? screen}) async {
    final app = await _app.read();
    final language = _locale.languageCode;
    return SupportDevice(
      platform: app?.platform.name ?? _platform(),
      osVersion: await (_os ??= _readOs()),
      appVersion: app == null ? null : app.buildNumber.isEmpty ? app.version : '${app.version}+${app.buildNumber}',
      language: language == 'ar' || language == 'en' ? language : null,
      screen: screen == null || screen.isEmpty ? null : screen,
    );
  }

  static String? _platform() => kIsWeb
      ? null
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => null,
        };

  /// "Android 15", "iOS 18.1".
  static Future<String?> _readOs() async {
    if (kIsWeb) return null;
    try {
      final info = DeviceInfoPlugin();
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => await info.androidInfo.then((a) => 'Android ${a.version.release}'),
        TargetPlatform.iOS => await info.iosInfo.then((i) => '${i.systemName} ${i.systemVersion}'),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}
