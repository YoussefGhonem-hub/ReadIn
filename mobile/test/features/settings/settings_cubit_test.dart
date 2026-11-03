import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/current_locale.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/domain/repositories/settings_repository.dart';
import 'package:readin/features/settings/domain/usecases/settings_usecases.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late CurrentLocale locale;

  const me = Me(
    id: 'u1',
    email: 'reader1@readin.test',
    displayName: 'Reader One',
    username: 'reader1',
    uiLanguage: 'en',
    articleLanguage: 'en',
    theme: 'dark',
    reminderTime: '07:30',
    onboardingCompleted: true,
  );

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = MockSettingsRepository();
    locale = CurrentLocale();
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
    when(() => repository.pushPreferences(any())).thenAnswer((_) async => const Ok(null));
  });

  SettingsCubit build() =>
      SettingsCubit(LoadSettings(repository), SaveSettings(repository), SyncPreferences(repository), locale);

  test('starts from stored settings and publishes the UI locale', () {
    when(() => repository.load()).thenReturn(const AppSettings(uiLanguage: 'en'));
    final cubit = build();
    expect(cubit.state.uiLanguage, 'en');
    expect(locale.value, const Locale('en'));
    expect(cubit.themeMode, ThemeMode.system);
  });

  blocTest<SettingsCubit, AppSettings>(
    'guest theme change is saved locally but not pushed',
    build: build,
    act: (cubit) => cubit.setTheme(ThemePreference.dark),
    expect: () => [const AppSettings(theme: ThemePreference.dark)],
    verify: (_) {
      verify(() => repository.save(const AppSettings(theme: ThemePreference.dark))).called(1);
      verifyNever(() => repository.pushPreferences(any()));
    },
  );

  blocTest<SettingsCubit, AppSettings>(
    'existing account: profile preferences win and are not pushed back',
    build: build,
    act: (cubit) => cubit.onSessionChanged(me),
    expect: () => [
      const AppSettings(theme: ThemePreference.dark, uiLanguage: 'en', articleLanguage: 'en', reminderTime: '07:30'),
    ],
    verify: (_) {
      verifyNever(() => repository.pushPreferences(any()));
      expect(locale.value, const Locale('en'));
    },
  );

  blocTest<SettingsCubit, AppSettings>(
    'new account adopts device settings by pushing them to the profile',
    build: build,
    act: (cubit) => cubit.onSessionChanged(const Me(id: 'u2', email: 'new@readin.test', displayName: 'New', username: 'new')),
    expect: () => <AppSettings>[],
    verify: (_) => verify(() => repository.pushPreferences(const AppSettings())).called(1),
  );

  blocTest<SettingsCubit, AppSettings>(
    'signed in: language change is pushed and updates the request locale',
    build: build,
    act: (cubit) async {
      await cubit.onSessionChanged(me);
      await cubit.setUiLanguage('ar');
    },
    skip: 1,
    expect: () => [
      const AppSettings(theme: ThemePreference.dark, uiLanguage: 'ar', articleLanguage: 'en', reminderTime: '07:30'),
    ],
    verify: (_) {
      verify(() => repository.pushPreferences(any(that: isA<AppSettings>().having((s) => s.uiLanguage, 'ui', 'ar'))))
          .called(1);
      expect(locale.value, const Locale('ar'));
    },
  );

  blocTest<SettingsCubit, AppSettings>(
    'device-only settings (font size) never hit the API',
    build: build,
    act: (cubit) async {
      await cubit.onSessionChanged(me);
      await cubit.setFontSize(ArticleFontSize.xl);
    },
    skip: 1,
    expect: () => [isA<AppSettings>().having((s) => s.fontSize, 'fontSize', ArticleFontSize.xl)],
    verify: (_) => verifyNever(() => repository.pushPreferences(any())),
  );

  test('reminder time round-trips through HH:mm', () {
    expect(SettingsCubit.formatTime(const TimeOfDay(hour: 7, minute: 5)), '07:05');
    expect(SettingsCubit.parseTime('21:45'), const TimeOfDay(hour: 21, minute: 45));
    expect(SettingsCubit.parseTime('garbage'), const TimeOfDay(hour: 8, minute: 0));
  });
}
