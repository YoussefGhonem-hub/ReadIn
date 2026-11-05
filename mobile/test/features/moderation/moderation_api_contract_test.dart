import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/network/api_error_mapper.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/moderation/data/datasources/moderation_api.dart';
import 'package:readin/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/social_fakes.dart';

/// Every F22 endpoint against the contract (f22-contract.md): method, path, query, body, and how the answers parse.
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

  ModerationRepositoryImpl repository() => ModerationRepositoryImpl(ModerationApi(dio));

  const author = {'id': 'w-1', 'displayName': 'منى', 'username': 'mona_dev', 'avatarUrl': null, 'isVerified': true};
  const reporter = {'id': 'r-1', 'displayName': 'Sara', 'username': 'sara', 'avatarUrl': null, 'isVerified': false};

  Map<String, dynamic> queueItemJson({
    String targetType = 'article',
    String targetId = 'art-7',
    String status = 'open',
    Map<String, Object?>? target,
  }) =>
      {
        'targetType': targetType,
        'targetId': targetId,
        'status': status,
        'reportCount': 4,
        'reasons': {'copyright': 1, 'misinformation': 3, 'bogus': 2},
        'firstReportedAt': '2026-10-30T10:00:00Z',
        'lastReportedAt': '2026-11-02T09:00:00Z',
        'closedAt': null,
        'target': target ??
            {
              'state': 'hidden',
              'author': author,
              'title': 'DI في .NET',
              'slug': 'di-dotnet',
              'language': 'ar-EG',
            },
      };

  Map<String, dynamic> actionJson(String id, {String action = 'user.suspend', String targetType = 'user'}) => {
        'id': id,
        'action': action,
        'targetType': targetType,
        'targetId': 'w-1',
        'targetLabel': '@mona_dev',
        'targetUser': reporter,
        'moderator': null,
        'note': 'Spam links',
        'suspendedUntil': '2026-11-09T12:00:00Z',
        'reportsClosed': 3,
        'createdAt': '2026-11-02T12:00:00Z',
      };

  group('POST /reports', () {
    test('sends the target, the reason and the trimmed details; empty details are left out', () async {
      respond = (_) => (204, null);

      await repository().report(const ModerationTargetRef.article('art-7'), ReportReason.copyright, details: 'منقول من blog');
      await repository().report(const ModerationTargetRef.user('w-9'), ReportReason.spam);

      expect(call(0), 'POST /reports');
      expect(requests[0].data, {'targetType': 'article', 'targetId': 'art-7', 'reason': 'copyright', 'details': 'منقول من blog'});
      expect(requests[1].data, {'targetType': 'user', 'targetId': 'w-9', 'reason': 'spam'});
    });

    test('a refusal keeps its code', () async {
      respond = (_) => (400, {'status': 400, 'code': 'report.own_content'});

      final result = await repository().report(const ModerationTargetRef.comment('c-1'), ReportReason.other);

      expect(result.failureOrNull?.code, FailureCodes.reportOwnContent);
    });
  });

  test('GET /moderation/summary parses the open counts', () async {
    respond = (_) => {
          'open': {'article': 2, 'comment': 5, 'user': 1, 'total': 8},
        };

    final summary = (await repository().summary()).valueOrNull;

    expect(call(0), 'GET /moderation/summary');
    expect(summary, const ModerationSummary(article: 2, comment: 5, user: 1, total: 8));
  });

  group('GET /moderation/reports', () {
    test('status, type, cursor and limit go in the query; items parse, unknown ones are skipped', () async {
      respond = (_) => {
            'items': [
              queueItemJson(),
              queueItemJson(
                targetType: 'comment',
                targetId: 'c-42',
                target: {
                  'state': 'visible',
                  'author': null,
                  'body': 'Rude',
                  'articleId': 'art-3',
                  'articleSlug': 'scoped',
                  'articleTitle': 'Scoped vs Transient',
                },
              ),
              queueItemJson(
                targetType: 'user',
                targetId: 'w-9',
                target: {'state': 'suspended', 'author': author, 'suspendedUntil': null, 'warningCount': 2},
              ),
              queueItemJson(targetType: 'path'),
            ],
            'nextCursor': 'next',
          };

      final page = (await repository().queue(ReportStatus.open, type: ModerationTargetType.comment, cursor: 'c1')).valueOrNull!;

      expect(call(0), 'GET /moderation/reports');
      expect(requests[0].queryParameters, {'status': 'open', 'type': 'comment', 'cursor': 'c1', 'limit': 20});
      expect(page.nextCursor, 'next');
      expect(page.items.map((i) => i.targetType), [ModerationTargetType.article, ModerationTargetType.comment, ModerationTargetType.user]);

      final article = page.items[0];
      expect(article.ref, const ModerationTargetRef.article('art-7'));
      expect(article.status, ReportStatus.open);
      expect(article.reportCount, 4);
      expect(article.reasons, {ReportReason.misinformation: 3, ReportReason.copyright: 1}, reason: 'most first; unknown dropped');
      expect(article.reasons.keys.first, ReportReason.misinformation);
      expect(article.lastReportedAt, DateTime.utc(2026, 11, 2, 9));
      expect(article.target.state, ModerationTargetState.hidden);
      expect(article.target.author, const Author(id: 'w-1', displayName: 'منى', username: 'mona_dev', isVerified: true));
      expect((article.target.title, article.target.slug, article.target.language), ('DI في .NET', 'di-dotnet', 'ar-EG'));

      final comment = page.items[1].target;
      expect(comment.author, isNull, reason: 'a deleted account');
      expect((comment.body, comment.articleSlug, comment.articleTitle), ('Rude', 'scoped', 'Scoped vs Transient'));

      final user = page.items[2].target;
      expect(user.isSuspended, isTrue);
      expect(user.suspendedUntil, isNull, reason: 'permanent');
      expect(user.warningCount, 2);
    });

    test('all types: no type in the query', () async {
      respond = (_) => {'items': <Object>[]};

      await repository().queue(ReportStatus.dismissed);

      expect(requests[0].queryParameters, {'status': 'dismissed', 'limit': 20});
    });
  });

  test('GET /moderation/reports/{targetType}/{targetId} parses the case: reports and history', () async {
    respond = (_) => {
          'item': queueItemJson(),
          'reports': [
            {
              'id': 'rp-1',
              'reporter': reporter,
              'reason': 'misinformation',
              'details': 'غلط',
              'status': 'open',
              'createdAt': '2026-11-02T09:00:00Z',
              'closedAt': null,
              'closedBy': null,
            },
            {
              'id': 'rp-2',
              'reporter': null,
              'reason': 'spam',
              'details': null,
              'status': 'dismissed',
              'createdAt': '2026-10-30T10:00:00Z',
              'closedAt': '2026-10-31T10:00:00Z',
              'closedBy': reporter,
            },
          ],
          'history': [actionJson('a-1'), actionJson('a-2', action: 'something.new'), actionJson('a-3', targetType: 'path')],
        };

    final c = (await repository().getCase(const ModerationTargetRef.article('art-7'))).valueOrNull!;

    expect(call(0), 'GET /moderation/reports/article/art-7');
    expect(c.item.targetId, 'art-7');
    expect(c.reports.map((r) => r.id), ['rp-1', 'rp-2']);
    expect(c.reports[0].reporter, const UserSummary(id: 'r-1', displayName: 'Sara', username: 'sara'));
    expect((c.reports[0].reason, c.reports[0].details, c.reports[0].status), (ReportReason.misinformation, 'غلط', ReportStatus.open));
    expect(c.reports[1].reporter, isNull);
    expect((c.reports[1].status, c.reports[1].closedAt, c.reports[1].closedBy?.id), (ReportStatus.dismissed, DateTime.utc(2026, 10, 31, 10), 'r-1'));
    expect(c.openReports, 1);
    expect(c.history.map((h) => h.action), [ModerationLogAction.userSuspend, ModerationLogAction.unknown]);
  });

  test('a user case carries their writer categories (F31), empty ones included; content cases have none', () async {
    respond = (_) => {
          'item': queueItemJson(),
          'reports': <Object>[],
          'history': [actionJson('a-1', action: 'user.clear_category')],
          'categories': [
            {'id': 'c-1', 'slug': 'شتيمة', 'name': 'اسم وحش', 'articleCount': 2, 'sortOrder': 1},
            {'id': 'c-2', 'slug': 'ef-core', 'name': 'EF Core', 'articleCount': 0, 'sortOrder': 2},
          ],
        };
    final c = (await repository().getCase(const ModerationTargetRef.user('w-9'))).valueOrNull!;
    expect(c.categories?.map((x) => (x.id, x.name, x.articleCount)), [('c-1', 'اسم وحش', 2), ('c-2', 'EF Core', 0)]);
    expect(c.history.single.action, ModerationLogAction.userClearCategory);

    respond = (_) => {'item': queueItemJson(), 'reports': <Object>[], 'history': <Object>[], 'categories': <Object>[]};
    expect((await repository().getCase(const ModerationTargetRef.article('art-7'))).valueOrNull!.categories, isEmpty);
    // An API from before F31 sends none.
    respond = (_) => {'item': queueItemJson(), 'reports': <Object>[], 'history': <Object>[]};
    expect((await repository().getCase(const ModerationTargetRef.article('art-7'))).valueOrNull!.categories, isNull);
  });

  group('POST /moderation/actions', () {
    setUp(() => respond = (_) => (204, null));

    test('hide with a note; unhide and dismiss without one', () async {
      await repository().act(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.article('art-7'), note: 'منقول'));
      await repository().act(const ModerationCommand(ModerationActionType.unhide, ModerationTargetRef.comment('c-1')));
      await repository().act(const ModerationCommand(ModerationActionType.dismiss, ModerationTargetRef.user('w-9')));

      expect(call(0), 'POST /moderation/actions');
      expect(requests[0].data, {'action': 'hide', 'targetType': 'article', 'targetId': 'art-7', 'note': 'منقول'});
      expect(requests[1].data, {'action': 'unhide', 'targetType': 'comment', 'targetId': 'c-1'});
      expect(requests[2].data, {'action': 'dismiss', 'targetType': 'user', 'targetId': 'w-9'});
    });

    test('warn and suspend the author, closing the reports of the content; a permanent suspension has no duration', () async {
      await repository().act(const ModerationCommand(
        ModerationActionType.suspend,
        ModerationTargetRef.user('w-1'),
        note: 'Spam',
        durationDays: 7,
        resolveReportsOf: ModerationTargetRef.comment('c-1'),
      ));
      await repository().act(const ModerationCommand(ModerationActionType.suspend, ModerationTargetRef.user('w-1'), note: 'Again'));
      await repository().act(const ModerationCommand(
        ModerationActionType.warn,
        ModerationTargetRef.user('w-1'),
        note: 'Be kind',
        resolveReportsOf: ModerationTargetRef.article('art-7'),
      ));
      await repository().act(const ModerationCommand(ModerationActionType.unsuspend, ModerationTargetRef.user('w-1')));
      await repository().act(const ModerationCommand(ModerationActionType.delete, ModerationTargetRef.comment('c-1')));

      expect(requests[0].data, {
        'action': 'suspend',
        'targetType': 'user',
        'targetId': 'w-1',
        'note': 'Spam',
        'durationDays': 7,
        'resolveReportsOf': {'targetType': 'comment', 'targetId': 'c-1'},
      });
      expect(requests[1].data, {'action': 'suspend', 'targetType': 'user', 'targetId': 'w-1', 'note': 'Again'});
      expect(requests[2].data, {
        'action': 'warn',
        'targetType': 'user',
        'targetId': 'w-1',
        'note': 'Be kind',
        'resolveReportsOf': {'targetType': 'article', 'targetId': 'art-7'},
      });
      expect(requests[3].data, {'action': 'unsuspend', 'targetType': 'user', 'targetId': 'w-1'});
      expect(requests[4].data, {'action': 'delete', 'targetType': 'comment', 'targetId': 'c-1'});
    });

    test('clear_category (F31) sends the user and the category', () async {
      await repository().act(const ModerationCommand(ModerationActionType.clearCategory, ModerationTargetRef.user('w-9'), categoryId: 'c-1'));
      expect(requests[0].data, {'action': 'clear_category', 'targetType': 'user', 'targetId': 'w-9', 'categoryId': 'c-1'});
    });

    test('refusals keep their codes', () async {
      respond = (_) => (403, {'status': 403, 'code': 'moderation.staff_target'});

      final result = await repository().act(const ModerationCommand(ModerationActionType.warn, ModerationTargetRef.user('w-1'), note: 'x'));

      expect(result.failureOrNull, const Failure(FailureCodes.moderationStaffTarget, statusCode: 403));
    });
  });

  test('GET /moderation/actions: filters in the query, the log parses newest first as sent', () async {
    respond = (_) => {
          'items': [actionJson('a-1'), actionJson('a-2', action: 'comment.delete', targetType: 'comment')],
          'nextCursor': null,
        };

    final page = (await repository().log(targetType: ModerationTargetType.user, targetUserId: 'w-1', cursor: 'p2')).valueOrNull!;

    expect(call(0), 'GET /moderation/actions');
    expect(requests[0].queryParameters, {'targetUserId': 'w-1', 'targetType': 'user', 'cursor': 'p2', 'limit': 20});
    expect(page.hasMore, isFalse);
    final entry = page.items.first;
    expect(entry.action, ModerationLogAction.userSuspend);
    expect(entry.ref, const ModerationTargetRef.user('w-1'));
    expect((entry.targetLabel, entry.note, entry.reportsClosed), ('@mona_dev', 'Spam links', 3));
    expect(entry.moderator, isNull, reason: 'the moderator deleted their account');
    expect(entry.targetUser?.username, 'sara');
    expect(entry.suspendedUntil, DateTime.utc(2026, 11, 9, 12));
    expect(page.items[1].action, ModerationLogAction.commentDelete);
  });

  group('notices', () {
    test('GET /me/moderation-notices parses both kinds and skips unknown ones', () async {
      respond = (_) => {
            'items': [
              {'id': 'n-1', 'kind': 'warning', 'note': 'Stop', 'article': null, 'createdAt': '2026-11-01T10:00:00Z'},
              {
                'id': 'n-2',
                'kind': 'article_hidden',
                'note': null,
                'article': {'id': 'art-7', 'slug': 'di', 'title': 'DI'},
                'createdAt': '2026-11-02T10:00:00Z',
              },
              {'id': 'n-3', 'kind': 'badge', 'note': null, 'article': null, 'createdAt': '2026-11-02T11:00:00Z'},
            ],
          };

      final notices = (await repository().notices()).valueOrNull!;

      expect(call(0), 'GET /me/moderation-notices');
      expect(notices, [
        ModerationNotice(id: 'n-1', kind: ModerationNoticeKind.warning, note: 'Stop', createdAt: DateTime.utc(2026, 11, 1, 10)),
        ModerationNotice(
          id: 'n-2',
          kind: ModerationNoticeKind.articleHidden,
          article: const ModerationNoticeArticle(id: 'art-7', slug: 'di', title: 'DI'),
          createdAt: DateTime.utc(2026, 11, 2, 10),
        ),
      ]);
    });

    test('POST /me/moderation-notices/{id}/acknowledge', () async {
      respond = (_) => (204, null);

      final result = await repository().acknowledge('n-1');

      expect(call(0), 'POST /me/moderation-notices/n-1/acknowledge');
      expect(result.isOk, isTrue);
    });
  });

  group('ArticleDetailsDto.moderation', () {
    test('parses while the article is hidden; null otherwise', () {
      final hidden = ArticleDetailsModel.fromJson({
        ...detailsJson(1),
        'moderation': {'hiddenAt': '2026-11-02T08:00:00Z', 'note': 'نقل من غير مصدر'},
      }).toEntity();
      final visible = ArticleDetailsModel.fromJson({...detailsJson(1), 'moderation': null}).toEntity();

      expect(hidden.moderation, ArticleModeration(hiddenAt: DateTime.utc(2026, 11, 2, 8), note: 'نقل من غير مصدر'));
      expect(hidden.isHidden, isTrue);
      expect(visible.moderation, isNull);
      expect(visible.isHidden, isFalse);
      expect(hidden.withModeration(null).isHidden, isFalse);
    });
  });

  group('user.suspended', () {
    test('carries suspendedUntil; null is permanent', () {
      final until = ApiErrorMapper.fromProblem(403, {'status': 403, 'code': 'user.suspended', 'suspendedUntil': '2026-11-09T12:00:00Z'});
      final forever = ApiErrorMapper.fromProblem(403, {'status': 403, 'code': 'user.suspended', 'suspendedUntil': null});
      final other = ApiErrorMapper.fromProblem(403, {'status': 403, 'code': 'auth.forbidden', 'suspendedUntil': '2026-11-09T12:00:00Z'});

      expect(until, Failure(FailureCodes.userSuspended, statusCode: 403, suspendedUntil: DateTime.utc(2026, 11, 9, 12)));
      expect(forever.suspendedUntil, isNull);
      expect(forever.code, FailureCodes.userSuspended);
      expect(other.suspendedUntil, isNull, reason: 'only user.suspended carries it');
    });

    test('a failed call keeps it through the repository', () async {
      respond = (_) => (403, {'status': 403, 'code': 'user.suspended', 'suspendedUntil': '2026-11-09T12:00:00Z'});

      final failure = (await repository().summary()).failureOrNull!;

      expect(failure.suspendedUntil, DateTime.utc(2026, 11, 9, 12));
    });
  });
}
