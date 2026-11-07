import 'package:equatable/equatable.dart';

import 'app_version.dart';

enum AppPlatform { android, ios }

/// One platform's part of `GET /app/update-policy`.
class PlatformUpdatePolicy extends Equatable {
  const PlatformUpdatePolicy({this.minimumVersion, this.storeUrl});

  /// The oldest version still supported (`1.2.0`, `1.2.0+14`); null: every version is.
  final String? minimumVersion;

  /// Where to update; null: the app knows it (Android) or shows no button (iOS).
  final String? storeUrl;

  @override
  List<Object?> get props => [minimumVersion, storeUrl];
}

/// `GET /app/update-policy`: the oldest app version the API still serves, per platform.
class UpdatePolicy extends Equatable {
  const UpdatePolicy({this.ios = const PlatformUpdatePolicy(), this.android = const PlatformUpdatePolicy()});

  final PlatformUpdatePolicy ios;
  final PlatformUpdatePolicy android;

  PlatformUpdatePolicy of(AppPlatform platform) => switch (platform) {
        AppPlatform.android => android,
        AppPlatform.ios => ios,
      };

  @override
  List<Object?> get props => [ios, android];
}

/// This install: `PackageInfo` and the platform it runs on.
class InstalledApp extends Equatable {
  const InstalledApp({
    required this.platform,
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });

  final AppPlatform platform;

  /// `0.1.0` (pubspec `version: 0.1.0+1`).
  final String version;

  /// `1`.
  final String buildNumber;

  /// The Android application id / iOS bundle id.
  final String packageName;

  @override
  List<Object?> get props => [platform, version, buildNumber, packageName];
}

/// This version is no longer supported: the app shows only the Update page.
class UpdateRequirement extends Equatable {
  const UpdateRequirement({this.storeUrl});

  /// Where "Update now" goes; null on iOS when the policy names no store page (the page shows no button then).
  final String? storeUrl;

  /// Whether [app] must update under [policy]. On Android without a store URL, the app's Play Store page.
  static UpdateRequirement? of(UpdatePolicy policy, InstalledApp app) {
    final rule = policy.of(app.platform);
    if (!isBelowMinimum(version: app.version, buildNumber: app.buildNumber, minimum: rule.minimumVersion)) return null;
    final storeUrl = switch (rule.storeUrl?.trim()) {
      final url? when url.isNotEmpty => url,
      _ when app.platform == AppPlatform.android && app.packageName.isNotEmpty =>
        'https://play.google.com/store/apps/details?id=${app.packageName}',
      _ => null,
    };
    return UpdateRequirement(storeUrl: storeUrl);
  }

  @override
  List<Object?> get props => [storeUrl];
}
