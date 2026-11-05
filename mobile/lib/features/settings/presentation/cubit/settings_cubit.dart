import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/current_locale.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../notifications/domain/usecases/notification_usecases.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/settings_usecases.dart';

/// App-wide preferences: theme, UI/article language, reminder time and reader
/// font size. Persisted locally; when signed in, profile-backed fields are
/// pushed to `PUT /me/preferences` so they follow the user across devices.
@lazySingleton
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(LoadSettings load, this._save, this._sync, this._locale, this._migrateDailySwitch) : super(load()) {
    _locale.value = AppLocales.fromCode(state.uiLanguage);
  }

  final SaveSettings _save;
  final SyncPreferences _sync;
  final CurrentLocale _locale;
  final MigrateDailyArticleSwitch _migrateDailySwitch;
  bool _signedIn = false;
  bool _dailySwitchMoved = false;
  Future<void>? _movingDailySwitch;

  Locale get locale => AppLocales.fromCode(state.uiLanguage);

  ThemeMode get themeMode => switch (state.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      };

  /// The setters complete with null, or with the failure of saving the change to the account (`PUT /me/preferences`)
  /// for the screen to show. The theme and the UI language stay applied on this device even then; the account-only
  /// preferences (article language, reminder time) go back to what the account has, as on the web.
  Future<Failure?> setTheme(ThemePreference theme) => _update(state.copyWith(theme: theme));

  Future<Failure?> setUiLanguage(String code) => _update(state.copyWith(uiLanguage: code == 'en' ? 'en' : 'ar'));

  Future<Failure?> setArticleLanguage(String language) {
    final previous = state.articleLanguage;
    return _update(
      state.copyWith(articleLanguage: language == 'en' ? 'en' : 'ar-EG'),
      revert: (current) => current.copyWith(articleLanguage: previous),
    );
  }

  Future<Failure?> setReminderTime(TimeOfDay time) {
    final previous = state.reminderTime;
    return _update(
      state.copyWith(reminderTime: formatTime(time)),
      revert: (current) => current.copyWith(reminderTime: previous),
    );
  }

  Future<Failure?> setFontSize(ArticleFontSize size) => _update(state.copyWith(fontSize: size));

  /// "Hide highlights" / "Show highlights" (F30): the reader's "⋯" item and Settings. Saved to the account when signed in
  /// (going back to what the account has when that fails); a guest's choice stays on this device.
  Future<Failure?> setShowHighlights(bool show) {
    final previous = state.showHighlights;
    return _update(
      state.copyWith(showHighlights: show),
      revert: (current) => current.copyWith(showHighlights: previous),
    );
  }

  Future<void> markWelcomeSeen() => _update(state.copyWith(welcomeSeen: true));

  /// Called when the session changes. For an existing account the profile is
  /// the source of truth; a brand-new account (onboarding not completed)
  /// adopts the choices the user already made on this device instead.
  Future<void> onSessionChanged(Me? me) async {
    _signedIn = me != null;
    if (me == null) return;
    unawaited(_moveDailySwitch());
    if (!me.onboardingCompleted) {
      unawaited(_sync(state));
      return;
    }
    final fromProfile = state.copyWith(
      theme: ThemePreference.values.where((t) => t.name == me.theme).firstOrNull ?? state.theme,
      uiLanguage: me.uiLanguage,
      articleLanguage: me.articleLanguage,
      reminderTime: me.reminderTime,
      showHighlights: me.showHighlights,
    );
    await _apply(fromProfile, push: false);
  }

  /// Moves the device-only daily-article switch of earlier versions to the signed-in account (F17): once, and again on
  /// the next session change while it fails (offline).
  Future<void> _moveDailySwitch() {
    if (_dailySwitchMoved) return Future.value();
    return _movingDailySwitch ??= _migrateDailySwitch().then((done) => _dailySwitchMoved = done).whenComplete(
          () => _movingDailySwitch = null,
        );
  }

  /// Applies [next] and, when signed in, saves it to the account. When that fails, [revert] (if given) undoes the
  /// change on this device, unless another change replaced it meanwhile.
  Future<Failure?> _update(AppSettings next, {AppSettings Function(AppSettings current)? revert}) async {
    final failure = await _apply(next, push: true);
    if (failure != null && revert != null && !isClosed && state == next) await _apply(revert(state), push: false);
    return failure;
  }

  Future<Failure?> _apply(AppSettings next, {required bool push}) async {
    if (next == state) return null;
    final shouldPush = push && _signedIn && next.syncedFieldsDiffer(state);
    emit(next);
    _locale.value = AppLocales.fromCode(next.uiLanguage);
    await _save(next);
    if (!shouldPush) return null;
    return (await _sync(next)).failureOrNull;
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
