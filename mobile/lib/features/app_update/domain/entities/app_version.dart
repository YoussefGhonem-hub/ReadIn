import 'package:equatable/equatable.dart';

/// An app version as `GET /app/update-policy` writes it: `major[.minor[.patch]][+build]`, missing parts being 0.
class AppVersion extends Equatable {
  const AppVersion(this.major, [this.minor = 0, this.patch = 0, this.build]);

  final int major;
  final int minor;
  final int patch;

  /// The build number after `+`, when the version names one.
  final int? build;

  static final _pattern = RegExp(r'^\d+(\.\d+){0,2}(\+\d+)?$');

  /// Null for anything that doesn't match the pattern, or numbers too large to compare.
  static AppVersion? tryParse(String? text) {
    if (text == null || !_pattern.hasMatch(text)) return null;
    final plus = text.indexOf('+');
    final core = (plus < 0 ? text : text.substring(0, plus)).split('.').map(int.tryParse).toList();
    final build = plus < 0 ? null : int.tryParse(text.substring(plus + 1));
    if (core.contains(null) || (plus >= 0 && build == null)) return null;
    return AppVersion(core[0]!, core.length > 1 ? core[1]! : 0, core.length > 2 ? core[2]! : 0, build);
  }

  /// Compares major.minor.patch only.
  int compareRelease(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  List<Object?> get props => [major, minor, patch, build];

  @override
  String toString() => '$major.$minor.$patch${build == null ? '' : '+$build'}';
}

/// Whether the installed [version] (`PackageInfo.version`, e.g. `0.1.0`) with [buildNumber] (`PackageInfo.buildNumber`)
/// is older than [minimum]: major.minor.patch first; when those are equal and [minimum] names a build, a lower build.
/// Anything that can't be parsed means no update is required.
bool isBelowMinimum({required String version, required String buildNumber, required String? minimum}) {
  final floor = AppVersion.tryParse(minimum);
  final current = AppVersion.tryParse(version);
  if (floor == null || current == null) return false;
  final release = current.compareRelease(floor);
  if (release != 0) return release < 0;
  final floorBuild = floor.build;
  if (floorBuild == null) return false;
  final currentBuild = buildNumber.isEmpty ? current.build : int.tryParse(buildNumber);
  return currentBuild != null && currentBuild < floorBuild;
}
