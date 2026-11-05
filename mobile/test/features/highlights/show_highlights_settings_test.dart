import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/current_locale.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/domain/repositories/settings_repository.dart';
import 'package:readin/features/settings/domain/usecases/settings_usecases.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockMigrateDailyArticleSwitch extends Mock implements MigrateDailyArticleSwitch {}

/// "Hide highlights" (F30) in the app settings (F18): synced to the account when signed in, kept on the device for
/// guests, and the account's value wins when it signs in.
void main() {
  late _MockSettingsRepository repository;
  late _MockMigrateDailyArticleSwitch migrate;

  const me = Me(id: 'u1', displayName: 'Reader One', username: 'reader1', onboardingCompleted: true, showHighlights: false);

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = _MockSettingsRepository();
    migrate = _MockMigrateDailyArticleSwitch();
    when(() => migrate()).thenAnswer((_) async => true);
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
    when(() => repository.pushPreferences(any())).thenAnswer((_) async => const Ok(null));
  });

  SettingsCubit build() =>
      SettingsCubit(LoadSettings(repository), SaveSettings(repository), SyncPreferences(repository), CurrentLocale(), migrate);

  test('shown by default', () => expect(const AppSettings().showHighlights, isTrue));

  test('a guest hides them on this device only', () async {
    final cubit = build();
    addTearDown(cubit.close);
    expect(await cubit.setShowHighlights(false), isNull);
    expect(cubit.state.showHighlights, isFalse);
    verify(() => repository.save(const AppSettings(showHighlights: false))).called(1);
    verifyNever(() => repository.pushPreferences(any()));
  });

  test("signing in to an existing account takes the account's choice", () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.onSessionChanged(me);
    expect(cubit.state.showHighlights, isFalse);
    verifyNever(() => repository.pushPreferences(any()));
  });

  test('signed in: the change goes to PUT /me/preferences; a refusal puts it back and says why', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.onSessionChanged(me);

    expect(await cubit.setShowHighlights(true), isNull);
    verify(() => repository.pushPreferences(any(that: isA<AppSettings>().having((s) => s.showHighlights, 'show', true)))).called(1);

    when(() => repository.pushPreferences(any())).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
    expect((await cubit.setShowHighlights(false))?.code, FailureCodes.networkOffline);
    expect(cubit.state.showHighlights, isTrue);
  });

  test('stored on the device with the other settings', () async {
    final store = InMemoryKeyValueStore();
    final local = SettingsLocalDataSource(store);
    expect(local.read().showHighlights, isTrue);
    await local.write(const AppSettings(showHighlights: false));
    expect(store.read<bool>('settings.showHighlights'), isFalse);
    expect(local.read().showHighlights, isFalse);
  });
}
