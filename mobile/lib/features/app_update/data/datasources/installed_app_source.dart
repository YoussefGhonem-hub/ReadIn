import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entities/update_policy.dart';

/// This install's version, build number and package name; tests use a fake.
abstract interface class InstalledAppSource {
  /// Null off Android and iOS, or when the platform can't say.
  Future<InstalledApp?> read();
}

@LazySingleton(as: InstalledAppSource)
class PackageInfoInstalledAppSource implements InstalledAppSource {
  Future<InstalledApp?>? _app;

  @override
  Future<InstalledApp?> read() => _app ??= _read();

  static Future<InstalledApp?> _read() async {
    final platform = kIsWeb
        ? null
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => AppPlatform.android,
            TargetPlatform.iOS => AppPlatform.ios,
            _ => null,
          };
    if (platform == null) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      return InstalledApp(
        platform: platform,
        version: info.version,
        buildNumber: info.buildNumber,
        packageName: info.packageName,
      );
    } catch (_) {
      return null;
    }
  }
}
