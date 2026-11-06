import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/push/push_links.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/notifications/data/models/notification_models.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/notifications/presentation/pages/notifications_page.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_text.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_tile.dart';

import '../../helpers/notification_fixtures.dart';
import '../../helpers/test_app.dart';

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

/// The official @readin account's articles, grouped per day (F17, docs/api/contract-v1.md "Notifications"): the type
/// stays `followed_writer_article`, `data.articleCount` says how many; from 2 the row says so with the newest title
/// under it and opens the account's profile.
void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(AppLocales.en);
    ar = await AppLocalizations.delegate.load(AppLocales.ar);
  });

  Map<String, dynamic> dto({Map<String, Object?> data = const {}, String link = 'readin://u/readin'}) => {
        'id': 'n-readin',
        'type': 'followed_writer_article',
        'createdAt': '2026-11-04T08:00:00Z',
        'updatedAt': '2026-11-04T17:40:00Z',
        'isRead': false,
        'actor': {'id': 'u-readin', 'displayName': 'ReadIn', 'username': 'readin', 'avatarUrl': null, 'isVerified': true},
        'actorCount': 1,
        'article': {'id': 'a-1', 'slug': 'di-dotnet', 'title': 'الـ DI في .NET', 'language': 'ar-EG'},
        'comment': null,
        'data': data,
        'link': link,
      };

  group('NotificationDto.data.articleCount', () {
    test('is read on @readin day entries', () {
      final entry = NotificationModel.fromJson(dto(data: {'articleCount': 3})).toEntity();
      expect(entry.type, NotificationType.followedWriterArticle);
      expect(entry.articleCount, 3);
      expect(entry.article!.slug, 'di-dotnet', reason: 'the newest article');
      expect(entry.link, 'readin://u/readin');
    });

    test('is null for every other writer (no key)', () {
      expect(NotificationModel.fromJson(dto(link: 'readin://a/di-dotnet')).toEntity().articleCount, isNull);
    });

    test('survives copyWith (marking it read)', () {
      expect(readinDay(4).copyWith(isRead: true).articleCount, 4);
    });
  });

  group('the sentence', () {
    test('Arabic: verb first, the CLDR plural of n', () {
      String say(int? count) => notificationMessage(ar, count == null ? readinDay(1) : readinDay(count));
      expect(say(1), 'نشر ReadIn مقالًا جديدًا');
      expect(say(2), 'نشر ReadIn مقالين جديدين');
      expect(say(3), 'نشر ReadIn 3 مقالات جديدة');
      expect(say(10), 'نشر ReadIn 10 مقالات جديدة');
      expect(say(11), 'نشر ReadIn 11 مقالًا جديدًا');
      expect(say(99), 'نشر ReadIn 99 مقالًا جديدًا');
      expect(say(100), 'نشر ReadIn 100 مقال جديد');
      expect(say(101), 'نشر ReadIn 101 مقال جديد');
    });

    test('English', () {
      expect(notificationMessage(en, readinDay(1)), 'ReadIn published a new article');
      expect(notificationMessage(en, readinDay(2)), 'ReadIn published 2 new articles');
      expect(notificationMessage(en, readinDay(12)), 'ReadIn published 12 new articles');
    });

    test('without articleCount (any other writer) the single-article sentence, as before', () {
      final other = notification('n', NotificationType.followedWriterArticle, actor: mona, actorCount: 1, article: diArticle);
      expect(notificationMessage(en, other), 'منى عادل published a new article');
      expect(notificationMessage(ar, other), 'نشر منى عادل مقالًا جديدًا');
    });

    test("2 or more open the account's profile; one opens the article", () {
      expect(pushLinkToPath(readinDay(3).link), '/u/readin');
      expect(pushLinkToPath(readinDay(1).link), '/a/di-dotnet');
    });
  });

  group('the row', () {
    setUp(() => NotificationClock.now = () => notificationsNow);
    tearDown(() => NotificationClock.now = DateTime.now);

    for (final variant in Variant.all) {
      testWidgets('the count, then the newest title ${variant.name}', (tester) async {
        usePhoneSurface(tester);
        await tester.pumpWidget(testApp(
          Material(child: NotificationTile(notification: readinDay(5), onTap: () {})),
          variant: variant,
        ));
        final english = variant.locale == AppLocales.en;
        expect(find.textContaining(english ? 'published 5 new articles' : '5 مقالات جديدة', findRichText: true), findsOneWidget);
        expect(find.textContaining('ReadIn', findRichText: true), findsOneWidget);
        expect(find.textContaining('Dependency Injection', findRichText: true), findsOneWidget, reason: 'the newest title');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets("tapping it marks it read and opens @readin's profile", (tester) async {
      final repository = FakeNotificationsRepository(items: [readinDay(3), ...mixedNotifications]);
      final badge = MockUnreadBadgeCubit();
      whenListen(badge, const Stream<int>.empty(), initialState: 0);
      final cubit = NotificationsCubit(
        GetNotifications(repository),
        MarkNotificationsSeen(repository),
        MarkNotificationRead(repository),
        MarkAllNotificationsRead(repository),
        badge,
      );
      addTearDown(cubit.close);
      await cubit.open();
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(path: '/notifications', builder: (_, _) => BlocProvider.value(value: cubit, child: const NotificationsView())),
          GoRoute(path: '/u/:username', builder: (_, s) => Text('profile of ${s.pathParameters['username']}')),
          GoRoute(path: '/a/:slug', builder: (_, s) => Text('article ${s.pathParameters['slug']}')),
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

      await tester.tap(find.textContaining('published 3 new articles', findRichText: true));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('read n-readin'));
      expect(find.text('profile of readin'), findsOneWidget);
    });
  });
}
