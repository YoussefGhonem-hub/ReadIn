import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';

/// Device IANA time zone (e.g. `Africa/Cairo`), used for the daily article and
/// streak calculations (SPEC §11 F07/F08).
@lazySingleton
class TimeZoneService {
  String? _cached;

  Future<String> current() async {
    if (_cached != null) return _cached!;
    try {
      _cached = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      _cached = 'UTC';
    }
    return _cached!;
  }
}
