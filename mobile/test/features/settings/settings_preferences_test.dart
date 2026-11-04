import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';
import 'package:readin/features/settings/presentation/widgets/preference_tiles.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/verification_fixtures.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

const _en = Variant(AppLocales.en, Brightness.light);

/// Settings → Reading (F18): the article language and the reminder are the account's, so guests can't change them,
/// and a change the account refuses says why, as on the web.
void main() {
  late MockSettingsCubit settings;

  setUp(() => settings = MockSettingsCubit()..hold(const AppSettings()));

  Future<void> pumpSettings(WidgetTester tester, {bool guest = false}) async {
    final session = MockSessionCubit()
      ..hold(guest ? const SessionState(status: SessionStatus.guest) : const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    usePhoneSurface(tester, size: const Size(390, 1400));
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: session),
        BlocProvider<SettingsCubit>.value(value: settings),
        BlocProvider<LinkedAccountsCubit>.value(value: MockLinkedAccountsCubit()..hold(const LinkedAccountsState())),
        BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..hold(const PrivacyState())),
        verificationEntryProvider(),
      ],
      child: testApp(const SettingsView(), variant: _en),
    ));
    await tester.pumpAndSettle();
  }

  bool radioEnabled(WidgetTester tester, String value) =>
      tester.widget<RadioListTile<String>>(find.byWidgetPredicate((w) => w is RadioListTile<String> && w.value == value)).enabled ??
      true;

  testWidgets('guests: the article language and the reminder are off, with a hint to sign in; no interests', (tester) async {
    await pumpSettings(tester, guest: true);

    expect(find.text('Sign in to save these settings to your account.'), findsOneWidget);
    expect(radioEnabled(tester, 'ar-EG'), isFalse);
    expect(radioEnabled(tester, 'en'), isFalse);
    expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Daily reminder')).enabled, isFalse);
    expect(find.text('Your interests'), findsNothing);

    await tester.tap(find.text('English only'), warnIfMissed: false);
    await tester.pump();
    verifyNever(() => settings.setArticleLanguage(any()));
  });

  testWidgets('signed in: no hint; Your interests is there', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Sign in to save these settings to your account.'), findsNothing);
    expect(radioEnabled(tester, 'en'), isTrue);
    expect(find.text('Your interests'), findsOneWidget);
  });

  testWidgets('a refused article language says why', (tester) async {
    when(() => settings.setArticleLanguage('en')).thenAnswer((_) async => const Failure(FailureCodes.networkOffline));
    await pumpSettings(tester);

    await tester.tap(find.text('English only'));
    await tester.pump();

    verify(() => settings.setArticleLanguage('en')).called(1);
    expect(find.text("You're offline. Check your connection."), findsOneWidget);
  });

  testWidgets('a saved one says so', (tester) async {
    when(() => settings.setArticleLanguage('en')).thenAnswer((_) async => null);
    await pumpSettings(tester);

    await tester.tap(find.text('English only'));
    await tester.pump();

    expect(find.text('Settings saved ✓'), findsOneWidget);
  });

  testWidgets('a refused theme says why too (it stays on this device)', (tester) async {
    when(() => settings.setTheme(ThemePreference.dark)).thenAnswer((_) async => const Failure(FailureCodes.networkOffline));
    await pumpSettings(tester);

    await tester.tap(find.descendant(of: find.byType(ThemeSelector), matching: find.text('Dark')));
    await tester.pump();

    expect(find.text("You're offline. Check your connection."), findsOneWidget);
  });
}
