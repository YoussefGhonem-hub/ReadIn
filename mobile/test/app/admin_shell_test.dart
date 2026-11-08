import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/main_nav_bar.dart';
import 'package:readin/app/main_shell.dart';
import 'package:readin/app/router.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/admin/domain/entities/admin_dashboard.dart';
import 'package:readin/features/admin/presentation/admin_routes.dart';
import 'package:readin/features/admin/presentation/cubit/admin_summary_cubit.dart';
import 'package:readin/features/admin/presentation/pages/admin_notifications_tab.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/widgets/more_sheet.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

import '../helpers/admin_fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/notification_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class _MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class _MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

const _en = Variant(AppLocales.en, Brightness.light);

/// The admin's bottom bar (F23): what it shows and asks for, then inside the app's shell, with the real branches and
/// the real redirect: who gets it, where the admin starts, the permissions, reading as a member and back, and a
/// `support_ticket` notification opening the console's ticket page.
void main() {
  Finder named(String label) => find.bySemanticsLabel(label);

  group('AdminNavBar', () {
    Future<List<Object>> pumpBar(
      WidgetTester tester,
      Variant variant, {
      int current = AdminNavBar.dashboardBranch,
      bool tickets = true,
      bool users = true,
      int openTickets = 0,
      int unread = 0,
    }) async {
      usePhoneSurface(tester);
      final pressed = <Object>[];
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: AdminNavBar(
              currentIndex: current,
              onSelect: pressed.add,
              onMore: () => pressed.add('more'),
              tickets: tickets,
              users: users,
              openTickets: openTickets,
              unread: unread,
            ),
          ),
          variant: variant,
        ),
      );
      await tester.pumpAndSettle();
      return pressed;
    }

    for (final variant in Variant.all) {
      group(variant.name, () {
        final l10n = lookupAppLocalizations(variant.locale);
        final icons = [l10n.adminSectionTickets, l10n.adminSectionUsers, l10n.notifications, l10n.navMore];

        testWidgets('icons only: Tickets, Users, Notifications, More, and the mark in the middle as the Dashboard', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpBar(tester, variant);

          for (final name in [...icons, l10n.adminNavDashboard]) {
            expect(find.text(name), findsNothing, reason: 'no text in the bar: $name');
          }
          for (final name in icons) {
            expect(named(name), findsOneWidget, reason: name);
          }
          expect(named(l10n.adminNavDashboard), findsOneWidget);
          // Nothing of the members' bar: no Write, Explore, Saved or Home.
          for (final name in [l10n.navWrite, l10n.navExplore, l10n.navSaved, l10n.navHome]) {
            expect(named(name), findsNothing, reason: name);
          }
          final screen = tester.getSize(find.byType(Scaffold)).width;
          expect(tester.getCenter(named(l10n.adminNavDashboard)).dx, moreOrLessEquals(screen / 2, epsilon: 0.5));
          semantics.dispose();
        });

        testWidgets('the mark opens the Dashboard, each icon its branch, More the sheet', (tester) async {
          final semantics = tester.ensureSemantics();
          final pressed = await pumpBar(tester, variant, current: AdminNavBar.usersBranch);
          for (final name in [l10n.adminNavDashboard, ...icons]) {
            await tester.tap(named(name));
          }
          expect(pressed, [5, 6, 7, 8, 'more']);
          semantics.dispose();
        });

        testWidgets('tells screen readers which one is open', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpBar(tester, variant);
          expect(
            tester.getSemantics(named(l10n.adminNavDashboard)),
            isSemantics(label: l10n.adminNavDashboard, isButton: true, isSelected: true, hasTapAction: true),
          );
          expect(tester.getSemantics(named(l10n.adminSectionUsers)), isSemantics(isButton: true, isSelected: false));

          await pumpBar(tester, variant, current: AdminNavBar.usersBranch);
          expect(tester.getSemantics(named(l10n.adminNavDashboard)), isSemantics(isSelected: false));
          expect(tester.getSemantics(named(l10n.adminSectionUsers)), isSemantics(isSelected: true));
          expect(tester.getSemantics(named(l10n.navMore)), isSemantics(isSelected: false));
          semantics.dispose();
        });
      });
    }

    testWidgets('a tab whose permission is missing is not shown, and the mark stays in the middle', (tester) async {
      final semantics = tester.ensureSemantics();
      final l10n = lookupAppLocalizations(AppLocales.en);
      for (final (tickets, users) in [(false, true), (true, false), (false, false)]) {
        await pumpBar(tester, _en, tickets: tickets, users: users);
        expect(named(l10n.adminSectionTickets), tickets ? findsOneWidget : findsNothing);
        expect(named(l10n.adminSectionUsers), users ? findsOneWidget : findsNothing);
        expect(named(l10n.notifications), findsOneWidget);
        expect(named(l10n.navMore), findsOneWidget);
        expect(tester.getCenter(named(l10n.adminNavDashboard)).dx, moreOrLessEquals(390 / 2, epsilon: 0.5));
      }
      semantics.dispose();
    });

    testWidgets('Tickets shows the open tickets and Notifications the unread count, as red badges named for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final en = lookupAppLocalizations(AppLocales.en);
      await pumpBar(tester, _en, openTickets: 3, unread: 12);
      expect(named('Tickets, 3 open'), findsOneWidget);
      expect(named(en.notificationsUnread(12)), findsOneWidget);
      expect(find.widgetWithText(Badge, '3'), findsOneWidget);
      expect(find.widgetWithText(Badge, '9+'), findsOneWidget);
      final badge = tester.widget<Badge>(find.widgetWithText(Badge, '3'));
      expect(badge.backgroundColor, isNotNull);

      const ar = Variant(AppLocales.ar, Brightness.light);
      await pumpBar(tester, ar, openTickets: 3);
      expect(named('التذاكر، 3 مفتوحة'), findsOneWidget);

      await pumpBar(tester, _en);
      expect(find.byType(Badge), findsNothing, reason: 'nothing waiting, no badge');
      semantics.dispose();
    });

    testWidgets('in Arabic Tickets and Users are on the right of the mark; in English on the left', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final variant in [const Variant(AppLocales.ar, Brightness.light), _en]) {
        final l10n = lookupAppLocalizations(variant.locale);
        await pumpBar(tester, variant);
        double x(String name) => tester.getCenter(named(name)).dx;
        final middle = x(l10n.adminNavDashboard);
        final start = [x(l10n.adminSectionTickets), x(l10n.adminSectionUsers)];
        final end = [x(l10n.notifications), x(l10n.navMore)];
        if (variant.locale == AppLocales.ar) {
          expect(start.every((dx) => dx > middle) && end.every((dx) => dx < middle), isTrue);
        } else {
          expect(start.every((dx) => dx < middle) && end.every((dx) => dx > middle), isTrue);
        }
      }
      semantics.dispose();
    });
  });

  group('in the shell', () {
    late MockSessionCubit session;
    late _MockSettingsCubit settings;
    late _MockUnreadBadgeCubit unread;
    late MockAdminSummaryCubit summary;

    setUp(() {
      session = MockSessionCubit()..hold(const SessionState(status: SessionStatus.guest));
      settings = _MockSettingsCubit()..hold(const AppSettings(welcomeSeen: true, uiLanguage: 'en'));
      unread = _MockUnreadBadgeCubit()..hold(2);
      summary = MockAdminSummaryCubit()..hold(const AdminSummary(openReports: 5, openTickets: 4, pendingVerifications: 1, total: 10));
      when(summary.watch).thenAnswer((_) {});
      when(summary.unwatch).thenAnswer((_) {});
      when(summary.load).thenAnswer((_) async {});
      when(unread.refresh).thenAnswer((_) async {});
      getIt
        ..registerSingleton<UnreadBadgeCubit>(unread)
        ..registerSingleton<AdminSummaryCubit>(summary);
    });

    tearDown(() async {
      await getIt.unregister<UnreadBadgeCubit>();
      await getIt.unregister<AdminSummaryCubit>();
    });

    /// The app's own shell branches, in order, from [buildRouter].
    List<String> branchPaths() {
      final router = buildRouter(session: session, settings: settings);
      addTearDown(router.dispose);
      final shell = router.configuration.routes.whereType<StatefulShellRoute>().single;
      return [for (final branch in shell.branches) (branch.routes.single as GoRoute).path];
    }

    Widget page(String name) => Scaffold(body: Center(child: Text('page $name')));

    /// [MainShell] over the app's branches (each a page naming its path) with the app's redirect; [pages] replaces
    /// some of them.
    Future<GoRouter> pumpApp(
      WidgetTester tester,
      Me me, {
      String initial = '/splash?from=%2Fhome',
      Map<String, Widget> pages = const {},
    }) async {
      session.hold(SessionState(status: SessionStatus.authenticated, me: me));
      final router = GoRouter(
        initialLocation: initial,
        redirect: (_, state) => resolveRedirect(uri: state.uri, session: session.state, settings: settings.state),
        routes: [
          GoRoute(path: '/splash', builder: (_, _) => page('/splash')),
          for (final path in ['/settings', '/moderation', AdminRoutes.content, AdminRoutes.verification])
            GoRoute(path: path, builder: (_, _) => page(path)),
          GoRoute(path: '/u/:username', builder: (_, state) => page('/u/${state.pathParameters['username']}')),
          GoRoute(path: '/admin/tickets/:id', builder: (_, state) => page('ticket ${state.pathParameters['id']}')),
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => MainShell(navigationShell: shell),
            branches: [
              for (final path in branchPaths())
                StatefulShellBranch(routes: [GoRoute(path: path, builder: (_, _) => pages[path] ?? page(path))]),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      usePhoneSurface(tester);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [BlocProvider<SessionCubit>.value(value: session), BlocProvider<SettingsCubit>.value(value: settings)],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light(AppLocales.en),
            locale: AppLocales.en,
            supportedLocales: AppLocales.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    final l10n = lookupAppLocalizations(AppLocales.en);

    test("the shell's branches: the members' five, then the admin's four", () {
      expect(branchPaths(), [
        AppRoutes.home,
        AppRoutes.explore,
        AppRoutes.write,
        AppRoutes.saved,
        AppRoutes.profile,
        AdminRoutes.consoleDashboard,
        AdminRoutes.consoleTickets,
        AdminRoutes.consoleUsers,
        AdminRoutes.consoleNotifications,
      ]);
      expect(AdminNavBar.dashboardBranch, 5);
      expect(AdminNavBar.notificationsBranch, 8);
    });

    testWidgets('the admin starts on the dashboard, with the admin bar and the open tickets on Tickets', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, adminMe());

      expect(find.text('page ${AdminRoutes.consoleDashboard}'), findsOneWidget);
      expect(find.byType(AdminNavBar), findsOneWidget);
      expect(find.byType(MainNavBar), findsNothing);
      expect(named('Tickets, 4 open'), findsOneWidget);
      expect(named(l10n.notificationsUnread(2)), findsOneWidget);
      verify(summary.watch).called(greaterThanOrEqualTo(1));
      semantics.dispose();
    });

    testWidgets("a member starts on Home with the members' bar, as before; the console's tabs send them home", (tester) async {
      final router = await pumpApp(tester, sampleMe);

      expect(find.text('page /home'), findsOneWidget);
      expect(find.byType(MainNavBar), findsOneWidget);
      expect(find.byType(AdminNavBar), findsNothing);
      verifyNever(summary.watch);

      router.go(AdminRoutes.consoleUsers);
      await tester.pumpAndSettle();
      expect(find.text('page /home'), findsOneWidget);
      expect(find.byType(AdminNavBar), findsNothing);
    });

    testWidgets('each tab follows its permission: no Tickets without support.manage, no Users without users.read', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final router = await pumpApp(tester, adminMe(without: {Permissions.supportManage}));
      expect(find.byType(AdminNavBar), findsOneWidget);
      expect(named('Tickets, 4 open'), findsNothing);
      expect(named(l10n.adminSectionTickets), findsNothing);
      expect(named(l10n.adminSectionUsers), findsOneWidget);
      router.go(AdminRoutes.consoleTickets);
      await tester.pumpAndSettle();
      expect(find.text('page ${AdminRoutes.consoleDashboard}'), findsOneWidget);

      await pumpApp(tester, adminMe(without: {Permissions.usersRead}));
      expect(named(l10n.adminSectionUsers), findsNothing);
      expect(named('Tickets, 4 open'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the tabs switch branches; More holds the rest, and "View the app as a reader" opens Home and back', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, adminMe());

      await tester.tap(named(l10n.adminSectionUsers));
      await tester.pumpAndSettle();
      expect(find.text('page ${AdminRoutes.consoleUsers}'), findsOneWidget);
      await tester.tap(named(l10n.notificationsUnread(2)));
      await tester.pumpAndSettle();
      expect(find.text('page ${AdminRoutes.consoleNotifications}'), findsOneWidget);

      await tester.tap(named(l10n.navMore));
      await tester.pumpAndSettle();
      expect(find.byType(ConsoleMoreSheet), findsOneWidget);
      for (final id in ['content', 'reports', 'verification', 'profile', 'settings', 'reader']) {
        expect(find.byKey(ValueKey('more-tile-console-$id')), findsOneWidget, reason: id);
      }
      // The queues' counts on their tiles.
      expect(find.widgetWithText(Badge, '5'), findsOneWidget);
      expect(find.widgetWithText(Badge, '1'), findsOneWidget);
      expect(find.text(l10n.adminViewAsReader), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('more-tile-console-reader')));
      await tester.pumpAndSettle();
      expect(find.text('page /home'), findsOneWidget);
      expect(find.byType(MainNavBar), findsOneWidget, reason: 'Home with the members\' bar');
      expect(find.byType(AdminNavBar), findsNothing);

      // Back: the More sheet's «لوحة التحكم».
      await tester.tap(named(l10n.navMore));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('more-tile-admin')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminNavBar), findsOneWidget);
      expect(find.text('page ${AdminRoutes.consoleDashboard}'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets("the console's More: each screen behind its permission; their profile and Settings open over the console", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, adminMe(without: {Permissions.moderationManage, Permissions.verificationManage}));
      await tester.tap(named(l10n.navMore));
      await tester.pumpAndSettle();
      for (final id in ['content', 'reports', 'verification']) {
        expect(find.byKey(ValueKey('more-tile-console-$id')), findsNothing, reason: id);
      }

      await tester.tap(find.byKey(const ValueKey('more-tile-console-profile')));
      await tester.pumpAndSettle();
      expect(find.text('page /u/superadmin'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Notifications: a support_ticket row opens the console ticket page; back on the tab, it reads again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      NotificationClock.now = () => notificationsNow;
      addTearDown(() => NotificationClock.now = DateTime.now);
      final ticket = AppNotification(
        id: 'n-ticket',
        type: NotificationType.supportTicket,
        createdAt: notificationsNow.subtract(const Duration(minutes: 3)),
        updatedAt: notificationsNow.subtract(const Duration(minutes: 3)),
        actor: ahmed,
        actorCount: 1,
        ticketNumber: 12,
        subject: 'The app closes when I open an article',
        link: 'readin://admin/support/t-9',
      );
      final repository = FakeNotificationsRepository(items: [ticket]);
      final center = NotificationsCubit(
        GetNotifications(repository),
        MarkNotificationsSeen(repository),
        MarkNotificationRead(repository),
        MarkAllNotificationsRead(repository),
        unread,
      );
      addTearDown(center.close);
      final router = await pumpApp(
        tester,
        adminMe(),
        initial: AdminRoutes.consoleNotifications,
        pages: {AdminRoutes.consoleNotifications: AdminNotificationsTab(cubit: center)},
      );
      expect(find.byType(AdminNavBar), findsOneWidget);
      expect(repository.calls.where((call) => call == 'seen'), hasLength(1));

      await tester.tap(find.byType(NotificationTile));
      await tester.pumpAndSettle();
      expect(find.text('page ticket t-9'), findsOneWidget);
      expect(repository.calls, contains('read n-ticket'));

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(NotificationTile), findsOneWidget);
      expect(repository.calls.where((call) => call == 'seen'), hasLength(2), reason: 'shown again: read again, seen');

      // Another tab and back: the same.
      await tester.tap(find.bySemanticsLabel(RegExp('^${l10n.adminSectionTickets}')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^${l10n.notifications}')));
      await tester.pumpAndSettle();
      expect(repository.calls.where((call) => call == 'seen'), hasLength(3));
      semantics.dispose();
    });
  });
}
