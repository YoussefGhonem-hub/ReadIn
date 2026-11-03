import '../../../../core/errors/result.dart';
import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  AppSettings load();

  Future<void> save(AppSettings settings);

  /// `PUT /me/preferences` with the device time zone.
  Future<Result<void>> pushPreferences(AppSettings settings);
}
