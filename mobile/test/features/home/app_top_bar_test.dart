import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/widgets/app_top_bar.dart';
import 'package:readin/features/home/presentation/widgets/me_sheet.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/widgets/theme_toggle_button.dart';

import '../../helpers/path_fakes.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/reading_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockReadingStatsCubit extends MockCubit<ReadingStatsState> implements ReadingStatsCubit {}

/// A writer (every Member can write) who is neither verified nor a moderator.
const writer = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  bio: 'بكتب عن Flutter',
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

/// The tabs' top bar and the Me sheet (LinkedIn-style layout): the avatar opens "Me", the sun / moon flips the
/// resolved theme and saves it, the bell shows the unread count.
void main() {
  late MockSettingsCubit settings;
  late MockReadingStatsCubit stats;
  late List<String> opened;
  late GoRouter router;

  setUp(() {
    opened = [];
    settings = MockSettingsCubit()..hold(const AppSettings());
    when(() => settings.setTheme(any())).thenAnswer((_) async => null);
    stats = MockReadingStatsCubit()..hold(ReadingStatsState(status: ReadingLoadStatus.ready, stats: sampleStats()));
    when(() => stats.load(username: any(named: 'username'))).thenAnswer((_) async {});
    getIt.registerFactory<ReadingStatsCubit>(() => stats);
  });

  tearDown(() => getIt.unregister<ReadingStatsCubit>());

  setUpAll(() => registerFallbackValue(ThemePreference.system));

  Widget bar() => const Scaffold(appBar: AppTopBar(), body: SizedBox.expand());

  Future<MockSessionCubit> pump(
    WidgetTester tester, {
    Me? me = writer,
    int unread = 0,
    Variant variant = const Variant(AppLocales.en, Brightness.light),
  }) async {
    usePhoneSurface(tester);
    final session = MockSessionCubit()
      ..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));
    when(session.signOut).thenAnswer((_) async {});
    final (app, appRouter) = routedTestApp(
      provided([
        BlocProvider<SessionCubit>.value(value: session),
        BlocProvider<SettingsCubit>.value(value: settings),
        BlocProvider<UnreadBadgeCubit>.value(value: MockUnreadBadgeCubit()..hold(unread)),
      ], bar()),
      opened: opened,
      variant: variant,
    );
    router = appRouter;
    await tester.pumpWidget(app);
    await tester.pump();
    return session;
  }

  group('theme toggle', () {
    test('flips the theme on screen: light → dark, dark → light', () {
      expect(toggledTheme(Brightness.light), ThemePreference.dark);
      expect(toggledTheme(Brightness.dark), ThemePreference.light);
    });

    testWidgets('light: a moon that switches to dark and saves it', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(find.byTooltip('Switch to dark mode'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('theme-toggle')));
      await tester.pump();
      verify(() => settings.setTheme(ThemePreference.dark)).called(1);
    });

    testWidgets('dark: a sun that switches to light; the button reports it is on', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, variant: const Variant(AppLocales.en, Brightness.dark));
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('theme-toggle'))),
        isSemantics(isButton: true, hasToggledState: true, isToggled: true, tooltip: 'Switch to light mode'),
      );

      await tester.tap(find.byKey(const ValueKey('theme-toggle')));
      await tester.pump();
      verify(() => settings.setTheme(ThemePreference.light)).called(1);
      semantics.dispose();
    });

    testWidgets('system resolves to the platform brightness first, then flips', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      usePhoneSurface(tester);
      await tester.pumpWidget(provided(
        [
          BlocProvider<SessionCubit>.value(
            value: MockSessionCubit()..hold(const SessionState(status: SessionStatus.authenticated, me: writer)),
          ),
          BlocProvider<SettingsCubit>.value(value: settings),
        ],
        MaterialApp(
          theme: AppTheme.light(AppLocales.ar),
          darkTheme: AppTheme.dark(AppLocales.ar),
          themeMode: ThemeMode.system, // what the app does for ThemePreference.system
          locale: AppLocales.ar,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: bar(),
        ),
      ));
      await tester.pump();

      expect(find.byTooltip('حوّل للوضع الفاتح'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('theme-toggle')));
      await tester.pump();
      verify(() => settings.setTheme(ThemePreference.light)).called(1);
    });
  });

  group('bell', () {
    testWidgets('the unread count, capped at 9+', (tester) async {
      await pump(tester, unread: 12);
      expect(find.text('9+'), findsOneWidget);
      expect(find.byTooltip('Notifications, 12 new'), findsOneWidget);
    });

    testWidgets('opens the notification center', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('notifications-bell')));
      await tester.pumpAndSettle();
      expect(opened, ['/notifications']);
    });

    testWidgets('guests get the sign-in prompt', (tester) async {
      await pump(tester, me: null);
      await tester.tap(find.byKey(const ValueKey('notifications-bell')));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
      expect(find.text('Create account'), findsOneWidget);
    });
  });

  testWidgets('the search pill opens search', (tester) async {
    await pump(tester);
    expect(find.text('Search articles, writers…'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('search-entry')));
    await tester.pumpAndSettle();
    expect(opened, ['/search']);
  });

  group('Me sheet', () {
    Future<MockSessionCubit> openSheet(WidgetTester tester, {Me? me = writer}) async {
      final session = await pump(tester, me: me);
      await tester.tap(find.byKey(const ValueKey('me-button')));
      await tester.pumpAndSettle();
      expect(find.byType(MeSheet), findsOneWidget);
      return session;
    }

    testWidgets('the avatar opens it: who is signed in, this week\'s reading and the writer\'s items', (tester) async {
      await openSheet(tester);
      expect(find.byTooltip('Me'), findsOneWidget);
      expect(find.text('Youssef Hassan'), findsWidgets);
      expect(find.textContaining('@reader1'), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);
      // GET /me/stats: the streak, then this week's articles and minutes.
      verify(() => stats.load()).called(1);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('Articles this week'), findsOneWidget);
      // Every Member writes; not verified yet; no moderation.
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('My paths'), findsOneWidget);
      expect(find.text('My articles'), findsOneWidget);
      expect(find.text('Writer verification'), findsOneWidget);
      expect(find.text('Moderation'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('a verified moderator: Moderation, no verification entry', (tester) async {
      await openSheet(tester, me: moderator);
      await tester.scrollUntilVisible(find.text('Moderation'), 100, scrollable: find.byType(Scrollable).last);
      expect(find.text('Moderation'), findsOneWidget);
      expect(find.text('Writer verification'), findsNothing);
    });

    testWidgets('items close the sheet and open their screen; My articles switches to the Write tab', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();
      expect(find.byType(MeSheet), findsNothing);
      expect(opened, ['/u/reader1']);

      for (final (label, location) in [('Settings', '/settings'), ('My paths', '/paths?tab=mine'), ('My articles', '/write')]) {
        router.go('/'); // back to the bar
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('me-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(opened.last, location);
      }
    });

    testWidgets('the reading row opens Reading stats', (tester) async {
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('reading-summary')));
      await tester.pumpAndSettle();
      expect(opened, ['/me/stats']);
    });

    testWidgets('Appearance: the segmented button saves the theme', (tester) async {
      await openSheet(tester);
      await tester.scrollUntilVisible(find.text('Dark'), 100, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Dark'));
      await tester.pump();
      verify(() => settings.setTheme(ThemePreference.dark)).called(1);
    });

    testWidgets('Sign out closes the sheet and ends the session', (tester) async {
      final session = await openSheet(tester);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('me-sign-out')), 100, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(const ValueKey('me-sign-out')));
      await tester.pumpAndSettle();
      verify(session.signOut).called(1);
      expect(find.byType(MeSheet), findsNothing);
    });

    testWidgets('guests: the ReadIn mark opens Create account, Sign in, Settings and Appearance', (tester) async {
      await openSheet(tester, me: null);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('me-appearance')), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.byKey(const ValueKey('reading-summary')), findsNothing);
      verifyNever(() => stats.load(username: any(named: 'username')));

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(opened, ['/auth/sign-in']);
    });
  });
}
