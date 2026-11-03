import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../network/request_context.dart';

/// The device model ("Google Pixel 8", "iPhone 15 Pro"), never the user-chosen device name. Sent as `X-Device-Name`
/// so "sign out of all devices" and the session list can tell devices apart (SPEC §9.3).
@LazySingleton(as: DeviceNameProvider)
class DeviceNameService implements DeviceNameProvider {
  Future<String?>? _name;

  @override
  Future<String?> deviceName() => _name ??= _read();

  static Future<String?> _read() async {
    try {
      final info = DeviceInfoPlugin();
      final name = switch (defaultTargetPlatform) {
        TargetPlatform.android => await info.androidInfo.then((a) => _join(a.manufacturer, a.model)),
        TargetPlatform.iOS => await info.iosInfo.then((i) => i.modelName.isNotEmpty ? i.modelName : i.model),
        _ => null,
      };
      return name == null ? null : headerSafe(name);
    } catch (_) {
      return null;
    }
  }

  /// "Google" + "Pixel 8" → "Google Pixel 8"; "samsung" + "SM-S921B" stays as both words.
  static String _join(String manufacturer, String model) {
    final brand = manufacturer.trim();
    final m = model.trim();
    if (brand.isEmpty || m.toLowerCase().startsWith(brand.toLowerCase())) return m;
    return '${brand[0].toUpperCase()}${brand.substring(1)} $m';
  }

  /// HTTP header values must be printable ASCII; the API keeps 200 characters.
  @visibleForTesting
  static String? headerSafe(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.length > 100 ? cleaned.substring(0, 100) : cleaned;
  }
}
