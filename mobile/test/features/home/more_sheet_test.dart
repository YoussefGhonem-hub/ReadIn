import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/widgets/more_sheet.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

import '../../helpers/path_fakes.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

/// A writer (every Member can write) who is neither verified nor a moderator.
const writer = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate, Permissions.reportsCreate],
);

/// A verified moderator.
const moderator = Me(
  id: 'u-9',
  displayName: 'Mona Admin',
  username: 'mona_admin',
  isVerified: true,
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate, Permissions.moderationManage, Permissions.usersSuspend],
);

/// The More sheet of the bottom bar: the user's card, the app's language and dark mode in place, the other screens,
/// and Sign out.
void main() {
  late MockSettingsCubit settings;
  late List<String> opened;
  late GoRouter router;

  setUpAll(() => registerFallbackValue(ThemePreference.system));

  setUp(() {
    opened = [];
    settings = MockSettingsCubit()..hold(const AppSettings());
    when(() => settings.setTheme(any())).thenAnswer((_) async => null);
    when(() => settings.setUiLanguage(any())).thenAnswer((_) async => null);
  });

  Future<MockSessionCubit> open(
    WidgetTester tester, {
    Me? me = writer,
    int unread = 0,
    Variant variant = const Variant(AppLocales.en, Brightness.light),
  }) async {
    usePhoneSurface(tester, size: const Size(390, 900));
    final session = MockSessionCubit()
      ..hold(
        me == null
            ? const SessionState(status: SessionStatus.guest)
            : SessionState(status: SessionStatus.authenticated, me: me),
      );
    when(session.signOut).thenAnswer((_) async {});
    final badge = MockUnreadBadgeCubit()..hold(unread);
    final (app, appRouter) = routedTestApp(
      provided(
        [BlocProvider<SessionCubit>.value(value: session), BlocProvider<SettingsCubit>.value(value: settings)],
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('open-more'),
                onPressed: () => showMoreSheet(context, unread: badge),
                child: const Text('More'),
              ),
            ),
          ),
        ),
      ),
      opened: opened,
      variant: variant,
    );
    router = appRouter;
    await tester.pumpWidget(app);
    await tester.tap(find.byKey(const ValueKey('open-more')));
    await tester.pumpAndSettle();
    expect(find.byType(MoreSheet), findsOneWidget);
    return session;
  }

  Finder tile(String id) => find.byKey(ValueKey('more-tile-$id'));

  testWidgets('signed in: the user\'s card, the language and dark mode, the screens and Sign out', (tester) async {
    await open(tester);

    expect(find.text('Youssef Hassan'), findsOneWidget);
    expect(find.textContaining('@reader1'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    for (final label in [
      'Profile',
      'Notifications',
      'My paths',
      'Reading stats',
      'Your interests',
      'Muted',
      'Writer verification',
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Moderation'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('a verified moderator: Moderation, and no verification', (tester) async {
    await open(tester, me: moderator);
    expect(find.text('Moderation'), findsOneWidget);
    expect(find.text('Writer verification'), findsNothing);
  });

  testWidgets('the card and Profile switch to the Profile tab; the other screens open over the page', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('more-profile-card')));
    await tester.pumpAndSettle();
    expect(find.byType(MoreSheet), findsNothing);
    expect(opened, ['/profile']);

    for (final (id, location) in [
      ('profile', '/profile'),
      ('notifications', '/notifications'),
      ('paths', '/paths?tab=mine'),
      ('stats', '/me/stats'),
      ('interests', '/settings/interests'),
      ('muted', '/settings/muted'),
      ('verification', '/settings/verification'),
      ('settings', '/settings'),
    ]) {
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-more')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tile(id));
      await tester.tap(tile(id));
      await tester.pumpAndSettle();
      expect(find.byType(MoreSheet), findsNothing, reason: id);
      expect(opened.last, location, reason: id);
    }
  });

  testWidgets('the language changes in place: the chosen one is selected, the other saves its code', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    expect(tester.getSemantics(find.byKey(const ValueKey('more-language-ar'))), isSemantics(isSelected: true));
    expect(tester.getSemantics(find.byKey(const ValueKey('more-language-en'))), isSemantics(isSelected: false));

    await tester.tap(find.byKey(const ValueKey('more-language-ar')));
    await tester.tap(find.byKey(const ValueKey('more-language-en')));
    await tester.pump();

    verify(() => settings.setUiLanguage('en')).called(1);
    verifyNever(() => settings.setUiLanguage('ar'));
    expect(find.byType(MoreSheet), findsOneWidget, reason: 'the sheet stays open');
    semantics.dispose();
  });

  testWidgets('dark mode: the switch shows the theme on screen and saves dark or light', (tester) async {
    await open(tester);
    expect(tester.widget<Switch>(find.byKey(const ValueKey('more-dark-mode'))).value, isFalse);
    await tester.tap(find.byKey(const ValueKey('more-dark-mode')));
    await tester.pump();
    verify(() => settings.setTheme(ThemePreference.dark)).called(1);
  });

  testWidgets('dark mode on: the switch is on and turns it back to light', (tester) async {
    await open(tester, variant: const Variant(AppLocales.en, Brightness.dark));
    expect(tester.widget<Switch>(find.byKey(const ValueKey('more-dark-mode'))).value, isTrue);
    await tester.tap(find.byKey(const ValueKey('more-dark-mode')));
    await tester.pump();
    verify(() => settings.setTheme(ThemePreference.light)).called(1);
  });

  testWidgets('Notifications shows the unread count, capped at 9+', (tester) async {
    await open(tester, unread: 12);
    expect(find.descendant(of: tile('notifications'), matching: find.text('9+')), findsOneWidget);
  });

  testWidgets('Sign out closes the sheet and ends the session', (tester) async {
    final session = await open(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('more-sign-out')));
    await tester.tap(find.byKey(const ValueKey('more-sign-out')));
    await tester.pumpAndSettle();
    verify(session.signOut).called(1);
    expect(find.byType(MoreSheet), findsNothing);
  });

  testWidgets('guests: Create account, Sign in, the language, dark mode and Settings; no Sign out', (tester) async {
    await open(tester, me: null);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(tile('settings'), findsOneWidget);
    for (final id in ['profile', 'notifications', 'paths', 'stats', 'interests', 'muted', 'verification']) {
      expect(tile(id), findsNothing, reason: id);
    }
    expect(find.text('Sign out'), findsNothing);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(opened, ['/auth/sign-in']);
  });

  testWidgets('in Arabic it reads right to left: the card\'s avatar on the right', (tester) async {
    await open(tester, variant: const Variant(AppLocales.ar, Brightness.light));
    final l10n = lookupAppLocalizations(AppLocales.ar);
    expect(find.text(l10n.moreDarkMode), findsOneWidget);
    final card = tester.getRect(find.byKey(const ValueKey('more-profile-card')));
    final name = tester.getRect(find.textContaining('Youssef Hassan'));
    expect(name.right, lessThan(card.right - 60), reason: 'the avatar comes first, on the right');
  });
}
