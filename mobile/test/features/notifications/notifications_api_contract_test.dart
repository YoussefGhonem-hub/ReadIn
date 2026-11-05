import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/notifications/data/datasources/notifications_api.dart';
import 'package:readin/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/entities/notification_settings.dart';

import '../../helpers/fake_auth.dart';

/// Every F17 endpoint against the contract (docs/handoff/f17-notifications.md): method, path, query, body, and how
/// the answers parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late Dio dio;

  setUp(() {
    requests = [];
    respond = (_) => null;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  NotificationsRepositoryImpl repository() => NotificationsRepositoryImpl(NotificationsApi(dio));

  Map<String, dynamic> problem(String code) => {'status': 400, 'code': code, 'title': 'Bad request'};

  group('GET /me/notifications', () {
    test('sends the cursor and limit, and reads every field of NotificationDto', () async {
      respond = (_) => {
            'items': [
              {
                'id': 'n-1',
                'type': 'article_comment',
                'createdAt': '2026-11-04T08:00:00Z',
                'updatedAt': '2026-11-04T09:30:00Z',
                'isRead': false,
                'actor': {'id': 'u-1', 'displayName': 'Ahmed', 'username': 'ahmed', 'avatarUrl': 'https://cdn.test/a.webp', 'isVerified': true},
                'actorCount': 10,
                'article': {'id': 'a-1', 'slug': 'rag-vs-fine-tuning', 'title': 'RAG vs fine-tuning', 'language': 'en'},
                'comment': {'id': 'c-9', 'parentId': null, 'excerpt': 'Great breakdown'},
                'data': <String, Object?>{},
                'link': 'readin://a/rag-vs-fine-tuning#comment-c-9',
              },
              {
                'id': 'n-2',
                'type': 'security_alert',
                'createdAt': '2026-11-03T08:00:00Z',
                'updatedAt': '2026-11-03T08:00:00Z',
                'isRead': true,
                'actor': null,
                'actorCount': 0,
                'article': null,
                'comment': null,
                'data': {'securityChange': 'passwordChanged'},
                'link': 'readin://settings/account',
              },
              {
                'id': 'n-3',
                'type': 'reactions_milestone',
                'createdAt': '2026-11-02T08:00:00Z',
                'updatedAt': '2026-11-02T08:00:00Z',
                'isRead': true,
                'actor': null,
                'actorCount': 0,
                'article': {'id': 'a-2', 'slug': 'di-dotnet', 'title': 'الـ DI في .NET', 'language': 'ar-EG'},
                'comment': null,
                'data': {'threshold': 50},
                'link': 'readin://a/di-dotnet',
              },
              {
                'id': 'n-4',
                'type': 'streak_reminder',
                'createdAt': '2026-11-01T18:00:00Z',
                'updatedAt': '2026-11-01T18:00:00Z',
                'isRead': false,
                'actor': null,
                'actorCount': 0,
                'article': null,
                'comment': null,
                'data': {'streakDays': 12},
                'link': 'readin://me/stats',
              },
              {
                'id': 'n-5',
                'type': 'something_new',
                'createdAt': '2026-11-01T08:00:00Z',
                'updatedAt': '2026-11-01T08:00:00Z',
                'isRead': false,
                'actorCount': 0,
                'link': '',
              },
            ],
            'nextCursor': 'c2',
          };
      final page = (await repository().list(cursor: 'c1', limit: 20)).valueOrNull!;

      expect(call(0), 'GET /me/notifications');
      expect(requests[0].uri.queryParameters, {'cursor': 'c1', 'limit': '20'});
      expect(page.nextCursor, 'c2');

      final comments = page.items[0];
      expect(comments.type, NotificationType.articleComment);
      expect(comments.isRead, isFalse);
      expect(comments.updatedAt, DateTime.utc(2026, 11, 4, 9, 30));
      expect(comments.actor, const NotificationActor(id: 'u-1', displayName: 'Ahmed', username: 'ahmed', avatarUrl: 'https://cdn.test/a.webp', isVerified: true));
      expect((comments.actorCount, comments.otherActors), (10, 9));
      expect(comments.article, const NotificationArticle(id: 'a-1', slug: 'rag-vs-fine-tuning', title: 'RAG vs fine-tuning', language: 'en'));
      expect(comments.comment, const NotificationComment(id: 'c-9', excerpt: 'Great breakdown'));
      expect(comments.link, 'readin://a/rag-vs-fine-tuning#comment-c-9');

      final security = page.items[1];
      expect((security.type, security.actor, security.securityChange), (NotificationType.securityAlert, null, SecurityChange.passwordChanged));
      expect(page.items[2].threshold, 50);
      expect(page.items[2].article!.language, 'ar-EG');
      expect(page.items[3].streakDays, 12);
      expect(page.items[4].type, NotificationType.unknown, reason: 'a newer type still lists, with generic text');
    });

    test('a mention in an article has no comment and links to the article', () async {
      respond = (_) => {
            'items': [
              {
                'id': 'n-6',
                'type': 'mention',
                'createdAt': '2026-11-04T10:00:00Z',
                'updatedAt': '2026-11-04T10:00:00Z',
                'isRead': false,
                'actor': {'id': 'u-1', 'displayName': 'Ahmed', 'username': 'ahmed', 'avatarUrl': null, 'isVerified': false},
                'actorCount': 1,
                'article': {'id': 'a-1', 'slug': 'rag-vs-fine-tuning', 'title': 'RAG vs fine-tuning', 'language': 'en'},
                'comment': null,
                'data': <String, Object?>{},
                'link': 'readin://a/rag-vs-fine-tuning',
              },
            ],
            'nextCursor': null,
          };
      final mention = (await repository().list()).valueOrNull!.items.single;

      expect(mention.type, NotificationType.mention);
      expect(mention.comment, isNull);
      expect(mention.article?.slug, 'rag-vs-fine-tuning');
      expect(mention.actor?.username, 'ahmed');
      expect(mention.link, 'readin://a/rag-vs-fine-tuning');
    });

    test('article_reposted (F29): the latest reposter, how many, the article and its link', () async {
      respond = (_) => {
            'items': [
              {
                'id': 'n-7',
                'type': 'article_reposted',
                'createdAt': '2026-11-04T10:00:00Z',
                'updatedAt': '2026-11-04T12:00:00Z',
                'isRead': false,
                'actor': {'id': 'u-1', 'displayName': 'Ahmed', 'username': 'ahmed', 'avatarUrl': null, 'isVerified': false},
                'actorCount': 3,
                'article': {'id': 'a-1', 'slug': 'rag-vs-fine-tuning', 'title': 'RAG vs fine-tuning', 'language': 'en'},
                'comment': null,
                'data': <String, Object?>{},
                'link': 'readin://a/rag-vs-fine-tuning',
              },
            ],
            'nextCursor': null,
          };
      final reposted = (await repository().list()).valueOrNull!.items.single;

      expect(reposted.type, NotificationType.articleReposted);
      expect((reposted.actor?.username, reposted.actorCount, reposted.otherActors), ('ahmed', 3, 2));
      expect(reposted.article?.slug, 'rag-vs-fine-tuning');
      expect(reposted.comment, isNull);
      expect(reposted.link, 'readin://a/rag-vs-fine-tuning');
    });

    test('a verification result says whether it was approved (F19); without data.approved it is generic', () async {
      Map<String, Object?> result(String id, Map<String, Object?> data) => {
            'id': id,
            'type': 'verification_result',
            'createdAt': '2026-11-04T10:00:00Z',
            'updatedAt': '2026-11-04T10:00:00Z',
            'isRead': false,
            'actor': null,
            'actorCount': 0,
            'article': null,
            'comment': null,
            'data': data,
            'link': 'readin://verification',
          };
      respond = (_) => {
            'items': [
              result('n-a', {'approved': true}),
              result('n-r', {'approved': false}),
              result('n-g', <String, Object?>{}),
            ],
            'nextCursor': null,
          };
      final items = (await repository().list()).valueOrNull!.items;
      expect([for (final n in items) n.type], List.filled(3, NotificationType.verificationResult));
      expect([for (final n in items) n.approved], [true, false, null]);
      expect(items.first.actor, isNull, reason: 'the reviewers stay anonymous');
      expect(items.first.link, 'readin://verification');
    });

    test('the first page has no cursor', () async {
      respond = (_) => {'items': <Object>[], 'nextCursor': null};
      final page = (await repository().list()).valueOrNull!;
      expect(requests[0].uri.queryParameters, {'limit': '20'});
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  test('GET /me/notifications/unread-count', () async {
    respond = (_) => {'unread': 3};
    expect((await repository().unreadCount()).valueOrNull, 3);
    expect(call(0), 'GET /me/notifications/unread-count');
  });

  test('POST /me/notifications/seen, /{id}/read and /read-all answer 204', () async {
    respond = (_) => (204, null);
    final repo = repository();
    expect((await repo.markSeen()).isOk, isTrue);
    expect((await repo.markRead('n 1')).isOk, isTrue);
    expect((await repo.markAllRead()).isOk, isTrue);
    expect([for (var i = 0; i < 3; i++) call(i)], [
      'POST /me/notifications/seen',
      'POST /me/notifications/n%201/read',
      'POST /me/notifications/read-all',
    ]);
  });

  test('a notification that is gone is 404 notification.not_found', () async {
    respond = (_) => (404, {'status': 404, 'code': 'notification.not_found', 'title': 'Not found'});
    final failure = (await repository().markRead('n-x')).failureOrNull!;
    expect((failure.code, failure.statusCode), (FailureCodes.notificationNotFound, 404));
  });

  group('notification settings', () {
    test('GET reads quiet hours and the modes, skipping types and modes this app does not know', () async {
      respond = (_) => {
            'quietHours': {'enabled': false, 'start': '22:30', 'end': '06:45'},
            'types': {'mention': 'inApp', 'streak_reminder': 'off', 'daily_article': 'all', 'security_alert': 'off', 'later_type': 'all', 'new_follower': 'loud'},
          };
      final settings = (await repository().getSettings()).valueOrNull!;
      expect(call(0), 'GET /me/notification-settings');
      expect(settings.quietHours, const QuietHours(enabled: false, start: '22:30', end: '06:45'));
      expect(settings.types, {
        NotificationType.mention: NotificationMode.inApp,
        NotificationType.streakReminder: NotificationMode.off,
        NotificationType.dailyArticle: NotificationMode.all,
      });
      expect(settings.modeOf(NotificationType.newFollower), NotificationMode.all, reason: 'absent = default');
    });

    test('article_reposted (F29) is the 9th configurable type: read and sent like the others', () async {
      respond = (_) => {
            'quietHours': {'enabled': true, 'start': '23:00', 'end': '07:00'},
            'types': {'article_reposted': 'inApp'},
          };
      final settings = (await repository().getSettings()).valueOrNull!;
      expect(settings.modeOf(NotificationType.articleReposted), NotificationMode.inApp);

      respond = (_) => (204, null);
      await repository().updateSettings(settings.withMode(NotificationType.articleReposted, NotificationMode.off));
      final body = requests.last.data is String ? jsonDecode(requests.last.data as String) : requests.last.data;
      expect((body as Map)['types'], {'article_reposted': 'off'});
    });

    test('PUT sends the whole NotificationSettingsDto', () async {
      respond = (_) => (204, null);
      const settings = NotificationSettings(
        quietHours: QuietHours(start: '23:30', end: '07:15'),
        types: {NotificationType.dailyArticle: NotificationMode.off, NotificationType.mention: NotificationMode.inApp},
      );
      expect((await repository().updateSettings(settings)).isOk, isTrue);
      expect(call(0), 'PUT /me/notification-settings');
      final body = requests[0].data is String ? jsonDecode(requests[0].data as String) : requests[0].data;
      expect(body, {
        'quietHours': {'enabled': true, 'start': '23:30', 'end': '07:15'},
        'types': {'daily_article': 'off', 'mention': 'inApp'},
      });
    });

    for (final code in [
      FailureCodes.notificationTypeInvalid,
      FailureCodes.notificationModeInvalid,
      FailureCodes.notificationQuietHoursInvalid,
    ]) {
      test('PUT refused with $code', () async {
        respond = (_) => (400, problem(code));
        final failure = (await repository().updateSettings(const NotificationSettings())).failureOrNull!;
        expect((failure.code, failure.statusCode), (code, 400));
      });
    }
  });
}
