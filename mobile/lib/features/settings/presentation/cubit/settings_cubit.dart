import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/l10n/current_locale.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../auth/domain/entities/me.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/settings_usecases.dart';

/// App-wide preferences: theme, UI/article language, reminder time and reader
/// font size. Persisted locally; when signed in, profile-backed fields are
/// pushed to `PUT /me/preferences` so they follow the user across devices.
@lazySingleton
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(LoadSettings load, this._save, this._sync, this._locale) : super(load()) {
    _locale.value = AppLocales.fromCode(state.uiLanguage);
  }

  final SaveSettings _save;
  final SyncPreferences _sync;
  final CurrentLocale _locale;
  bool _signedIn = false;

  Locale get locale => AppLocales.fromCode(state.uiLanguage);

  ThemeMode get themeMode => switch (state.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      };

  Future<void> setTheme(ThemePreference theme) => _update(state.copyWith(theme: theme));

  Future<void> setUiLanguage(String code) => _update(state.copyWith(uiLanguage: code == 'en' ? 'en' : 'ar'));

  Future<void> setArticleLanguage(String language) =>
      _update(state.copyWith(articleLanguage: language == 'en' ? 'en' : 'ar-EG'));

  Future<void> setReminderTime(TimeOfDay time) => _update(state.copyWith(reminderTime: formatTime(time)));

  Future<void> setFontSize(ArticleFontSize size) => _update(state.copyWith(fontSize: size));

  Future<void> setDailyNotifications(bool enabled) => _update(state.copyWith(dailyNotifications: enabled));

  Future<void> markWelcomeSeen() => _update(state.copyWith(welcomeSeen: true));

  /// Called when the session changes. For an existing account the profile is
  /// the source of truth; a brand-new account (onboarding not completed)
  /// adopts the choices the user already made on this device instead.
  Future<void> onSessionChanged(Me? me) async {
    _signedIn = me != null;
    if (me == null) return;
    if (!me.onboardingCompleted) {
      unawaited(_sync(state));
      return;
    }
    final fromProfile = state.copyWith(
      theme: ThemePreference.values.where((t) => t.name == me.theme).firstOrNull ?? state.theme,
      uiLanguage: me.uiLanguage,
      articleLanguage: me.articleLanguage,
      reminderTime: me.reminderTime,
    );
    await _apply(fromProfile, push: false);
  }

  Future<void> _update(AppSettings next) => _apply(next, push: true);

  Future<void> _apply(AppSettings next, {required bool push}) async {
    if (next == state) return;
    final shouldPush = push && _signedIn && next.syncedFieldsDiffer(state);
    emit(next);
    _locale.value = AppLocales.fromCode(next.uiLanguage);
    await _save(next);
    if (shouldPush) unawaited(_sync(next));
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay parseTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }
}
