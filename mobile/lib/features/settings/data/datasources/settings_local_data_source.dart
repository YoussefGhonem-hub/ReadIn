import 'package:injectable/injectable.dart';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/app_settings.dart';

/// Persists [AppSettings] in the Hive key/value box.
@lazySingleton
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._store);

  final KeyValueStore _store;

  static const _theme = 'settings.theme';
  static const _uiLanguage = 'settings.uiLanguage';
  static const _articleLanguage = 'settings.articleLanguage';
  static const _reminderTime = 'settings.reminderTime';
  static const _fontSize = 'settings.fontSize';
  static const _welcomeSeen = 'settings.welcomeSeen';

  /// The device-only daily-article switch of earlier versions; the server's `daily_article` mode replaced it (F17).
  static const legacyDailyNotificationsKey = 'settings.dailyNotifications';

  AppSettings read() {
    const d = AppSettings();
    T byName<T extends Enum>(List<T> values, String key, T fallback) =>
        values.where((v) => v.name == _store.read<String>(key)).firstOrNull ?? fallback;
    return AppSettings(
      theme: byName(ThemePreference.values, _theme, d.theme),
      uiLanguage: _store.read<String>(_uiLanguage) ?? d.uiLanguage,
      articleLanguage: _store.read<String>(_articleLanguage) ?? d.articleLanguage,
      reminderTime: _store.read<String>(_reminderTime) ?? d.reminderTime,
      fontSize: byName(ArticleFontSize.values, _fontSize, d.fontSize),
      welcomeSeen: _store.read<bool>(_welcomeSeen) ?? d.welcomeSeen,
    );
  }

  Future<void> write(AppSettings s) async {
    await _store.write(_theme, s.theme.name);
    await _store.write(_uiLanguage, s.uiLanguage);
    await _store.write(_articleLanguage, s.articleLanguage);
    await _store.write(_reminderTime, s.reminderTime);
    await _store.write(_fontSize, s.fontSize.name);
    await _store.write(_welcomeSeen, s.welcomeSeen);
  }

  bool? legacyDailyNotifications() => _store.read<bool>(legacyDailyNotificationsKey);

  Future<void> clearLegacyDailyNotifications() => _store.delete(legacyDailyNotificationsKey);
}
