import '../../../../core/errors/result.dart';
import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  AppSettings load();

  Future<void> save(AppSettings settings);

  /// `PUT /me/preferences` with the device time zone.
  Future<Result<void>> pushPreferences(AppSettings settings);

  /// The device-only "daily article notification" switch of earlier versions, or null once it was moved to the
  /// server's `daily_article` mode (F17) or was never changed.
  bool? legacyDailyNotifications();

  /// Forgets [legacyDailyNotifications] once it was moved.
  Future<void> clearLegacyDailyNotifications();
}
