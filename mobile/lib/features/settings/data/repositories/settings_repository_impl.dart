import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/platform/time_zone_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/preferences_api.dart';
import '../datasources/settings_local_data_source.dart';
import '../models/update_preferences_request.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local, this._api, this._timeZone);

  final SettingsLocalDataSource _local;
  final PreferencesApi _api;
  final TimeZoneService _timeZone;

  @override
  AppSettings load() => _local.read();

  @override
  Future<void> save(AppSettings settings) => _local.write(settings);

  @override
  Future<Result<void>> pushPreferences(AppSettings settings) async {
    final timeZone = await _timeZone.current();
    return guardApi(() => _api.update(UpdatePreferencesRequest(
          uiLanguage: settings.uiLanguage,
          articleLanguage: settings.articleLanguage,
          theme: settings.theme.name,
          timeZone: timeZone,
          reminderTime: settings.reminderTime,
        )));
  }

  @override
  bool? legacyDailyNotifications() => _local.legacyDailyNotifications();

  @override
  Future<void> clearLegacyDailyNotifications() => _local.clearLegacyDailyNotifications();
}
