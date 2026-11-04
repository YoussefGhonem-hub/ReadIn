import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/entities/notification_settings.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:readin/features/notifications/presentation/pages/notifications_page.dart';
import 'package:readin/features/notifications/presentation/widgets/daily_article_switch.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_text.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/notification_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

const _en = Variant(AppLocales.en, Brightness.light);
const offline = Failure(FailureCodes.networkOffline);

void main() {
  late FakeNotificationsRepository repository;
  late MockUnreadBadgeCubit badge;

  setUp(() {
    NotificationClock.now = () => notificationsNow;
    repository = FakeNotificationsRepository(items: mixedNotifications);
    badge = MockUnreadBadgeCubit()..hold(0);
  });
  tearDown(() => NotificationClock.now = DateTime.now);

  NotificationsCubit center() => NotificationsCubit(
        GetNotifications(repository),
        MarkNotificationsSeen(repository),
        MarkNotificationRead(repository),
        MarkAllNotificationsRead(repository),
        badge,
      );

  NotificationSettingsCubit settingsCubit() =>
      NotificationSettingsCubit(GetNotificationSettings(repository), UpdateNotificationSettings(repository));

  group('the sentence of every type (ICU plurals, ar + en)', () {
    late AppLocalizations en;
    late AppLocalizations ar;

    setUpAll(() async {
      en = await AppLocalizations.delegate.load(AppLocales.en);
      ar = await AppLocalizations.delegate.load(AppLocales.ar);
    });

    AppNotification row(NotificationType type, {NotificationActor? actor = ahmed, int actorCount = 1, NotificationArticle? article}) =>
        notification('n', type, actor: actor, actorCount: actorCount, article: article);

    test('aggregated rows say "X and N others"', () {
      final comments = row(NotificationType.articleComment, actorCount: 10);
      expect(notificationMessage(en, comments), 'Ahmed Samir and 9 others commented on your article');
      expect(notificationMessage(ar, comments, name: 'أحمد'), 'أحمد و9 غيره علّقوا على مقالك');
      expect(notificationMessage(en, row(NotificationType.articleComment)), 'Ahmed Samir commented on your article');
      expect(notificationMessage(en, row(NotificationType.articleComment, actorCount: 2)), 'Ahmed Samir and 1 other commented on your article');
      expect(notificationMessage(ar, row(NotificationType.articleComment, actorCount: 3), name: 'أحمد'), 'أحمد واتنين غيره علّقوا على مقالك');
      expect(notificationMessage(ar, row(NotificationType.articleComment, actorCount: 30), name: 'أحمد'), 'أحمد و29 غيره علّقوا على مقالك');

      expect(notificationMessage(en, row(NotificationType.newFollower, actorCount: 3)), 'Ahmed Samir and 2 others started following you');
      expect(notificationMessage(ar, row(NotificationType.newFollower), name: 'أحمد'), 'أحمد بدأ يتابعك');
      expect(notificationMessage(en, row(NotificationType.commentReply, actorCount: 2)), 'Ahmed Samir and 1 other replied to your comment');
      expect(notificationMessage(ar, row(NotificationType.commentReply, actorCount: 4), name: 'منى'), 'منى و3 غيره ردّوا على تعليقك');
    });

    test('a deleted actor is "Deleted user"', () {
      final mention = row(NotificationType.mention, actor: null);
      expect(notificationMessage(en, mention), 'Deleted user mentioned you in a comment');
      expect(notificationMessage(ar, mention), 'مستخدم محذوف عمل لك منشن في تعليق');
    });

    test('the other types', () {
      expect(notificationMessage(en, row(NotificationType.followedWriterArticle)), 'Ahmed Samir published a new article');
      expect(notificationMessage(en, notification('n', NotificationType.reactionsMilestone, threshold: 50)), 'Your article reached 50 reactions 🎉');
      expect(notificationMessage(ar, notification('n', NotificationType.reactionsMilestone, threshold: 10)), 'مقالك وصل لـ 10 تفاعلات 🎉');
      expect(notificationMessage(ar, notification('n', NotificationType.reactionsMilestone, threshold: 100)), 'مقالك وصل لـ 100 تفاعل 🎉');
      expect(notificationMessage(en, notification('n', NotificationType.reactionsMilestone)), 'Readers are reacting to your article 🎉');
      expect(notificationMessage(en, notification('n', NotificationType.dailyArticle)), "Today's article is ready ☕");
      expect(notificationMessage(ar, notification('n', NotificationType.dailyArticle)), 'مقال النهارده جاهز ☕');
      expect(notificationMessage(en, notification('n', NotificationType.streakReminder, streakDays: 12)), 'Read an article today to keep your 12-day streak 🔥');
      expect(notificationMessage(en, notification('n', NotificationType.streakReminder)), 'Read an article today to keep your streak 🔥');
      expect(
        notificationMessage(en, notification('n', NotificationType.securityAlert, securityChange: SecurityChange.phoneNumberChanged)),
        'Your phone number was changed',
      );
      expect(notificationMessage(ar, notification('n', NotificationType.securityAlert, securityChange: SecurityChange.passwordChanged)),
          'كلمة السر بتاعتك اتغيّرت');
      expect(notificationMessage(en, notification('n', NotificationType.securityAlert, securityChange: SecurityChange.other)),
          'There was a security change on your account');
      expect(notificationMessage(en, notification('n', NotificationType.verificationResult)), "There's an update on your verification request");
      expect(notificationMessage(en, notification('n', NotificationType.moderationNotice)), 'You received a warning from the moderation team');
      expect(notificationMessage(en, notification('n', NotificationType.moderationNotice, article: diArticle)), 'The moderators hid your article');
      expect(notificationMessage(en, notification('n', NotificationType.unknown)), 'You have a new notification');
    });

    test('every security change has its own sentence', () {
      final sentences = {for (final change in SecurityChange.values) securityChangeMessage(en, change)};
      expect(sentences.length, SecurityChange.values.length);
    });
  });

  group('notification center', () {
    Future<void> pumpView(WidgetTester tester, NotificationsCubit cubit, {Variant variant = _en}) async {
      usePhoneSurface(tester, size: const Size(390, 1400));
      await tester.pumpWidget(testApp(BlocProvider.value(value: cubit, child: const NotificationsView()), variant: variant));
      await tester.pump();
    }

    for (final variant in Variant.all) {
      testWidgets('loading, error, empty and the list ${variant.name}', (tester) async {
        final l10n = await AppLocalizations.delegate.load(variant.locale);

        repository.listFailure = offline;
        final failing = center();
        await failing.open();
        await pumpView(tester, failing, variant: variant);
        expect(find.text(l10n.errOffline), findsOneWidget);
        repository.listFailure = null;
        await tester.tap(find.text(l10n.retry));
        await tester.pumpAndSettle();
        expect(find.text(l10n.errOffline), findsNothing);
        expect(find.text(l10n.notificationsToday), findsOneWidget);
        expect(find.text(l10n.notificationsEarlier), findsOneWidget);
        expect(find.byType(NotificationTile), findsNWidgets(mixedNotifications.length));
        expect(find.byKey(NotificationTile.unreadDotKey), findsNWidgets(mixedNotifications.where((n) => !n.isRead).length));
        expect(find.textContaining(l10n.deletedUser, findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);

        repository.items = [];
        final empty = center();
        await empty.open();
        await pumpView(tester, empty, variant: variant);
        expect(find.text(l10n.notificationsEmptyTitle), findsOneWidget);
        expect(find.text(l10n.notificationsMarkAllRead), findsNothing);

        final loading = center();
        await pumpView(tester, loading, variant: variant);
        expect(find.byType(NotificationTile), findsNothing);
        expect(find.text(l10n.notificationsEmptyTitle), findsNothing);
      });
    }

    testWidgets('the article title keeps its own direction, and the comment excerpt its own', (tester) async {
      final cubit = center();
      await cubit.open();
      await pumpView(tester, cubit, variant: const Variant(AppLocales.ar, Brightness.light));
      Directionality around(String text) => tester.widget<Directionality>(
            find.ancestor(of: find.textContaining(text), matching: find.byType(Directionality)).first,
          );
      expect(around('when to use which').textDirection, TextDirection.ltr);
      expect(around('Great breakdown').textDirection, TextDirection.ltr);
      expect(around('بالبلدي').textDirection, TextDirection.rtl);
    });

    testWidgets('"Mark all read" reads every row, then turns off', (tester) async {
      final cubit = center();
      await cubit.open();
      await pumpView(tester, cubit);
      await tester.tap(find.text('Mark all read'));
      await tester.pump();
      expect(repository.calls.last, 'read-all');
      expect(find.byKey(NotificationTile.unreadDotKey), findsNothing);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Mark all read')).onPressed, isNull);
    });

    testWidgets('a failed "Mark all read" says so and the rows stay unread', (tester) async {
      repository.readAllFailure = offline;
      final cubit = center();
      await cubit.open();
      await pumpView(tester, cubit);
      await tester.tap(find.text('Mark all read'));
      await tester.pump();
      expect(find.text("You're offline. Check your connection."), findsOneWidget);
      expect(find.byKey(NotificationTile.unreadDotKey), findsNWidgets(4));
    });

    testWidgets('pull to refresh marks what arrived seen and reloads', (tester) async {
      final cubit = center();
      await cubit.open();
      await pumpView(tester, cubit);
      repository.calls.clear();
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(repository.calls, ['seen', 'list -']);
    });

    testWidgets('scrolling down loads the next page', (tester) async {
      repository.pageSize = 4;
      final cubit = center();
      await cubit.open();
      usePhoneSurface(tester, size: const Size(390, 600));
      await tester.pumpWidget(testApp(BlocProvider.value(value: cubit, child: const NotificationsView())));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('list 4'));
    });

    group('tapping a row marks it read and opens its link like its push', () {
      late GoRouter router;

      Future<void> pumpRouter(WidgetTester tester) async {
        final cubit = center();
        await cubit.open();
        router = GoRouter(
          initialLocation: '/notifications',
          routes: [
            GoRoute(path: '/notifications', builder: (_, _) => BlocProvider.value(value: cubit, child: const NotificationsView())),
            GoRoute(path: '/a/:slug', builder: (_, s) => Text('article ${s.pathParameters['slug']} #${s.uri.fragment}')),
            GoRoute(path: '/u/:username/followers', builder: (_, s) => Text('followers of ${s.pathParameters['username']}')),
            GoRoute(path: '/me/stats', builder: (_, _) => const Text('reading stats')),
            GoRoute(path: '/settings', builder: (_, s) => Text('settings ${s.uri.queryParameters['section']}')),
          ],
        );
        addTearDown(router.dispose);
        usePhoneSurface(tester, size: const Size(390, 1400));
        await tester.pumpWidget(MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(AppLocales.en),
          locale: AppLocales.en,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ));
        await tester.pumpAndSettle();
      }

      Future<void> tapRow(WidgetTester tester, String text) async {
        await tester.tap(find.textContaining(text, findRichText: true).first);
        await tester.pumpAndSettle();
      }

      testWidgets('a reply opens the article at the comment', (tester) async {
        await pumpRouter(tester);
        await tapRow(tester, 'replied to your comment');
        expect(repository.calls, contains('read n-reply'));
        expect(find.text('article di-dotnet #comment-c-7'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(NotificationTile.unreadDotKey), findsNWidgets(3), reason: 'read when it was opened');
      });

      testWidgets('several new followers open the follower list', (tester) async {
        await pumpRouter(tester);
        await tapRow(tester, 'started following you');
        expect(repository.calls.where((c) => c.startsWith('read')), isEmpty, reason: 'it was read already');
        expect(find.text('followers of reader1'), findsOneWidget);
      });

      testWidgets('the streak reminder opens the reading stats', (tester) async {
        await pumpRouter(tester);
        await tester.scrollUntilVisible(find.textContaining('12-day streak', findRichText: true), 300);
        await tapRow(tester, '12-day streak');
        expect(find.text('reading stats'), findsOneWidget);
      });

      testWidgets('a security alert opens Settings at the account', (tester) async {
        await pumpRouter(tester);
        await tester.scrollUntilVisible(find.textContaining('Your password was changed', findRichText: true), 300);
        await tapRow(tester, 'Your password was changed');
        expect(repository.calls, contains('read n-security'));
        expect(find.text('settings account'), findsOneWidget);
      });

      testWidgets('a link the app does not know only marks it read', (tester) async {
        repository.items = [notification('n-x', NotificationType.verificationResult, link: 'readin://verification/42')];
        await pumpRouter(tester);
        await tapRow(tester, 'verification request');
        expect(repository.calls, contains('read n-x'));
        expect(find.byType(NotificationsView), findsOneWidget);
      });

      testWidgets('a warning links to the center itself: marked read, no second center', (tester) async {
        repository.items = [notification('n-w', NotificationType.moderationNotice, link: 'readin://notifications')];
        await pumpRouter(tester);
        await tapRow(tester, 'You received a warning');
        expect(repository.calls, contains('read n-w'));
        expect(router.routerDelegate.currentConfiguration.matches.length, 1);
        expect(find.byType(NotificationsView), findsOneWidget);
      });
    });
  });

  group('notification settings', () {
    Future<void> pumpSettings(WidgetTester tester, NotificationSettingsCubit cubit, {Variant variant = _en}) async {
      usePhoneSurface(tester, size: const Size(390, 1400));
      await tester.pumpWidget(testApp(BlocProvider.value(value: cubit, child: const NotificationSettingsView()), variant: variant));
      await tester.pumpAndSettle();
    }

    for (final variant in Variant.all) {
      testWidgets('every configurable type, security alerts and quiet hours ${variant.name}', (tester) async {
        final l10n = await AppLocalizations.delegate.load(variant.locale);
        final cubit = settingsCubit();
        await cubit.load();
        await pumpSettings(tester, cubit, variant: variant);
        for (final type in NotificationType.configurable) {
          expect(find.text(notificationTypeLabel(l10n, type)), findsOneWidget);
        }
        expect(find.text(l10n.notificationSecurityAlerts), findsOneWidget);
        expect(find.text(l10n.quietHoursTitle), findsOneWidget);
        expect(find.text(l10n.quietHoursSwitch), findsOneWidget);
        expect(find.text('23:00'), findsOneWidget);
        expect(find.text('07:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a failed load can be retried', (tester) async {
      repository.settingsFailure = offline;
      final cubit = settingsCubit();
      await cubit.load();
      await pumpSettings(tester, cubit);
      repository.settingsFailure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('New followers'), findsOneWidget);
    });

    testWidgets('picking a mode saves it', (tester) async {
      final cubit = settingsCubit();
      await cubit.load();
      await pumpSettings(tester, cubit);
      await tester.tap(find.byKey(const ValueKey('mode-mention')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('In app only').last);
      await tester.pumpAndSettle();
      expect(repository.saved.single.modeOf(NotificationType.mention), NotificationMode.inApp);
      expect(cubit.state.modeOf(NotificationType.mention), NotificationMode.inApp);
    });

    testWidgets('turning quiet hours off saves it and disables the times', (tester) async {
      final cubit = settingsCubit();
      await cubit.load();
      await pumpSettings(tester, cubit);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(repository.saved.single.quietHours.enabled, isFalse);
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'From')).enabled, isFalse);
    });

    testWidgets('a refused save says why and puts the saved value back', (tester) async {
      repository.updateFailure = const Failure(FailureCodes.notificationModeInvalid, statusCode: 400);
      final cubit = settingsCubit();
      await cubit.load();
      await pumpSettings(tester, cubit);
      await tester.tap(find.byKey(const ValueKey('mode-daily_article')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Off').last);
      await tester.pumpAndSettle();
      expect(find.text('Pick push, in app or off.'), findsOneWidget);
      expect(cubit.state.modeOf(NotificationType.dailyArticle), NotificationMode.all);
    });

    testWidgets('quiet hours that start when they end are refused without a request', (tester) async {
      final cubit = settingsCubit();
      await cubit.load();
      await pumpSettings(tester, cubit);
      await tester.tap(find.text('From'));
      await tester.pumpAndSettle();
      // The picker opens on 23:00: switch to typing and enter 07:00, the end.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '7');
      await tester.enterText(find.byType(TextField).at(1), '00');
      await tester.tap(find.text('AM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Quiet hours need two different times.'), findsOneWidget);
      expect(repository.saved, isEmpty);
      expect(find.text('23:00'), findsOneWidget);
    });
  });

  group('onboarding daily-article switch', () {
    Future<void> pumpSwitch(WidgetTester tester, NotificationSettingsCubit cubit) async {
      await tester.pumpWidget(testApp(
        BlocProvider.value(value: cubit, child: const Scaffold(body: DailyArticleSwitch())),
        variant: _en,
      ));
      await tester.pump();
    }

    testWidgets('waits for the settings, then sets daily_article off and on', (tester) async {
      final cubit = settingsCubit();
      await pumpSwitch(tester, cubit);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged, isNull);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

      await cubit.load();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(repository.saved.last.modeOf(NotificationType.dailyArticle), NotificationMode.off);
      expect(DailyArticleSwitch.isOn(cubit.state), isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(repository.saved.last.modeOf(NotificationType.dailyArticle), NotificationMode.all);
    });

    testWidgets('reads the account: a daily_article in app only is off here', (tester) async {
      repository.settings = const NotificationSettings(types: {NotificationType.dailyArticle: NotificationMode.inApp});
      final cubit = settingsCubit();
      await cubit.load();
      await pumpSwitch(tester, cubit);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    });
  });

  group('Settings', () {
    Future<void> pumpSettingsPage(WidgetTester tester, {Me? me = sampleMe, SettingsSection? section}) async {
      usePhoneSurface(tester);
      final session = MockSessionCubit()
        ..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => SettingsView(section: section)),
          GoRoute(path: NotificationSettingsPage.path, builder: (_, _) => const Text('notification settings page')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<SettingsCubit>.value(value: MockSettingsCubit()..hold(const AppSettings())),
          BlocProvider<LinkedAccountsCubit>.value(value: MockLinkedAccountsCubit()..hold(const LinkedAccountsState())),
          BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..hold(const PrivacyState())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(AppLocales.en),
          locale: AppLocales.en,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('signed in: the Notifications card opens the notification settings', (tester) async {
      await pumpSettingsPage(tester);
      await tester.scrollUntilVisible(find.text('Notification settings'), 200);
      await tester.tap(find.text('Notification settings'));
      await tester.pumpAndSettle();
      expect(find.text('notification settings page'), findsOneWidget);
    });

    testWidgets('guests have no notification settings', (tester) async {
      await pumpSettingsPage(tester, me: null);
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('Notification settings'), findsNothing);
    });

    testWidgets('a security alert opens it at the Account card', (tester) async {
      await pumpSettingsPage(tester, section: SettingsSection.account);
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Account')).dy, lessThan(844), reason: 'on screen');
      expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, greaterThan(0));
    });
  });
}
