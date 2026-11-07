import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/admin/data/datasources/admin_api.dart';
import 'package:readin/features/admin/data/datasources/verification_proof_data_source.dart';
import 'package:readin/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:readin/features/admin/domain/entities/admin_content.dart';
import 'package:readin/features/admin/domain/entities/admin_dashboard.dart';
import 'package:readin/features/admin/domain/entities/admin_user.dart';
import 'package:readin/features/moderation/data/datasources/moderation_api.dart';
import 'package:readin/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/verification/domain/entities/verification.dart';

import '../../helpers/fake_auth.dart';

/// The admin console's endpoints (F23, docs/api/contract-v1.md "Admin console"): method, path, query, body, and how
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
  Map<String, String> query(int i) => requests[i].uri.queryParameters;

  AdminRepositoryImpl repository() => AdminRepositoryImpl(AdminApi(dio), VerificationProofDataSource(dio));

  const author = {'id': 'w-1', 'displayName': 'منى', 'username': 'mona_dev', 'avatarUrl': null, 'isVerified': true, 'headline': null};
  const field = {'id': 'f-1', 'slug': 'software', 'name': 'Software', 'nameAr': 'البرمجيات', 'nameEn': 'Software', 'isSensitive': false};

  test('GET /admin/summary: the parts the caller may see and the total', () async {
    respond = (_) => {'openReports': 3, 'openTickets': null, 'pendingVerifications': 2, 'total': 5};

    final summary = (await repository().summary()).valueOrNull;

    expect(call(0), 'GET /admin/summary');
    expect(summary, const AdminSummary(openReports: 3, pendingVerifications: 2, total: 5));
  });

  test('GET /admin/dashboard: the period on the wire; cards, charts, lists and the pipeline parse', () async {
    respond = (_) => {
          'period': '7d',
          'timeZone': 'Africa/Cairo',
          'from': '2026-11-01T22:00:00Z',
          'to': '2026-11-07T12:00:00Z',
          'fromDate': '2026-11-02',
          'toDate': '2026-11-07',
          'generatedAt': '2026-11-07T12:00:00Z',
          'cards': {
            'articlesPublished': {'value': 12, 'previous': 9},
            'newUsers': {'value': 30, 'previous': 40, 'phone': 20, 'google': 8, 'apple': 2},
            'activeReaders': {'value': 100, 'previous': 100},
            'reads': {'value': 900, 'previous': 800},
            'comments': {'value': 40, 'previous': 50},
            'reactions': {'value': 70, 'previous': 60},
            'reposts': {'value': 5, 'previous': 1},
            'openReports': 3,
            'openTickets': null,
            'pendingVerifications': 1,
            'suspendedNow': 2,
          },
          'charts': [
            {'date': '2026-11-06', 'newUsers': 3, 'activeReaders': 10, 'articlesPublished': 1},
            {'date': '2026-11-07', 'newUsers': 4, 'activeReaders': 12, 'articlesPublished': 2},
          ],
          'topArticles': [
            {
              'id': 'a-1',
              'slug': 'rag',
              'title': 'RAG',
              'language': 'en',
              'author': author,
              'field': field,
              'publishedAt': '2026-11-03T10:00:00Z',
              'reads': 50,
            },
          ],
          'topWriters': [
            {'writer': author, 'reads': 70, 'articles': 3},
          ],
          'missedSearches': [
            {'query': 'kubernetes', 'language': 'en', 'count': 7},
          ],
          'streakRetention': {'cohort': 40, 'kept': 10, 'rate': 0.25},
          'contentPipeline': {'folders': 300, 'seeded': 300, 'published': 280, 'lastSeedRunAt': '2026-11-01T00:00:00Z'},
        };

    final dashboard = (await repository().dashboard(AdminPeriod.days7)).valueOrNull!;

    expect(call(0), 'GET /admin/dashboard');
    expect(query(0), {'period': '7d'});
    expect(dashboard.period, AdminPeriod.days7);
    expect(dashboard.fromDate, '2026-11-02');
    expect(dashboard.cards.articlesPublished.change, 3);
    expect(dashboard.cards.newUsers.google, 8);
    expect(dashboard.cards.comments.change, -10);
    expect(dashboard.cards.openTickets, isNull, reason: 'without support.manage');
    expect(dashboard.cards.suspendedNow, 2);
    expect([for (final d in dashboard.charts) d.newUsers], [3, 4]);
    expect(dashboard.topArticles.single.author?.username, 'mona_dev');
    expect(dashboard.topWriters.single.articles, 3);
    expect(dashboard.missedSearches.single.count, 7);
    expect(dashboard.streakRetention.rate, 0.25);
    expect(dashboard.contentPipeline.published, 280);
  });

  group('users', () {
    Map<String, Object?> rowJson({String status = 'active'}) => {
          'id': 'w-9',
          'displayName': 'Free Crypto',
          'username': 'crypto',
          'avatarUrl': null,
          'isVerified': false,
          'isSystemAccount': false,
          'roles': ['Member'],
          'signInMethods': ['phone', 'google', 'facebook'],
          'phoneMasked': '+20***1234',
          'joinedAt': '2026-10-01T00:00:00Z',
          'lastSeenAt': null,
          'publishedArticles': 2,
          'followers': 5,
          'status': status,
          'suspendedUntil': status == 'suspended' ? '2026-11-10T00:00:00Z' : null,
          'openReports': 4,
        };

    test('GET /admin/users: search, filters, sort and page in the query; rows parse (unknown methods skipped)', () async {
      respond = (_) => {
            'items': [rowJson(), rowJson(status: 'suspended')],
            'page': 2,
            'pageSize': 50,
            'totalCount': 52,
            'totalPages': 2,
          };

      final page = (await repository().users(
        const AdminUserQuery(
          q: ' +201001234567 ',
          status: AdminUserStatusFilter.suspended,
          verified: true,
          method: SignInMethod.google,
          hasReports: true,
          sort: AdminUserSort.openReports,
          ascending: true,
        ),
        page: 2,
      ))
          .valueOrNull!;

      expect(call(0), 'GET /admin/users');
      expect(query(0), {
        'q': '+201001234567',
        'status': 'suspended',
        'verified': 'true',
        'method': 'google',
        'hasReports': 'true',
        'sort': 'openReports',
        'dir': 'asc',
        'page': '2',
        'pageSize': '50',
      });
      expect(requests[0].uri.query, contains('q=%2B201001234567'), reason: 'clients send + as %2B');
      expect(page.totalCount, 52);
      expect(page.hasNext, isFalse);
      expect(page.items.first.signInMethods, [SignInMethod.phone, SignInMethod.google]);
      expect(page.items.last.suspended, isTrue);
      expect(page.items.last.suspendedUntil, DateTime.utc(2026, 11, 10));
    });

    test('joined in a period: joinedFrom and joinedTo as local dates', () async {
      respond = (_) => {'items': <Object>[], 'page': 1, 'pageSize': 50, 'totalCount': 0, 'totalPages': 0};

      await repository().users(const AdminUserQuery(joinedFrom: '2026-10-01', joinedTo: '2026-10-31'));

      expect(query(0), {
        'joinedFrom': '2026-10-01',
        'joinedTo': '2026-10-31',
        'sort': 'joined',
        'dir': 'desc',
        'page': '1',
        'pageSize': '50',
      });
    });

    test('the default list: newest first, no filters', () async {
      respond = (_) => {'items': <Object>[], 'page': 1, 'pageSize': 50, 'totalCount': 0, 'totalPages': 0};

      await repository().users(const AdminUserQuery());

      expect(query(0), {'sort': 'joined', 'dir': 'desc', 'page': '1', 'pageSize': '50'});
    });

    test("GET /admin/users/{id}: a user's page with its sections and actions; sections without permission are null", () async {
      respond = (_) => {
            ...rowJson(),
            'headline': 'Crypto expert',
            'bio': null,
            'links': [
              {'platform': 'telegram', 'url': 'https://t.me/x', 'label': null},
            ],
            'uiLanguage': 'en',
            'signUpMethod': 'google',
            'isStaff': false,
            'stats': {'drafts': 1, 'comments': 9, 'following': 3, 'totalReads': 40, 'articlesRead': 7, 'currentStreak': 2, 'longestStreak': 5},
            'access': {
              'activeSessions': 2,
              'hasRecoveryPin': true,
              'recoveryDisabled': false,
              'mustChangePassword': false,
              'mustSetRecoveryPin': false,
              'lockedOutUntil': null,
            },
            'actions': {
              'canSuspend': true,
              'canWarn': true,
              'canLogoutAll': true,
              'canResetPassword': true,
              'canRemoveBadge': false,
              'canClearProfile': true,
              'canRestoreContent': true,
              'canRevealPhone': true,
            },
            'moderation': {
              'warnings': 2,
              'suspensions': 1,
              'hiddenArticles': 3,
              'hiddenComments': 4,
              'hiddenWithAccount': 5,
              'history': [
                {
                  'id': 'h-1',
                  'action': 'user.hide_content',
                  'targetType': 'user',
                  'targetId': 'w-9',
                  'targetLabel': '@crypto',
                  'targetUser': null,
                  'moderator': null,
                  'note': null,
                  'suspendedUntil': null,
                  'reportsClosed': 2,
                  'createdAt': '2026-11-01T00:00:00Z',
                },
              ],
              'historyTotal': 1,
            },
            'reports': {
              'against': [
                {
                  'id': 'r-1',
                  'targetType': 'article',
                  'targetId': 'a-1',
                  'targetLabel': 'Free coins',
                  'reason': 'spam',
                  'details': null,
                  'status': 'open',
                  'createdAt': '2026-11-01T00:00:00Z',
                  'reporter': {'id': 'u-2', 'displayName': 'Sara', 'username': 'sara'},
                },
              ],
              'againstTotal': 1,
              'filed': <Object>[],
              'filedTotal': 0,
            },
            'verification': null,
            'tickets': {
              'items': [
                {
                  'id': 't-1',
                  'number': 4,
                  'category': 'account',
                  'subject': 'Locked out',
                  'status': 'open',
                  'user': author,
                  'createdAt': '2026-11-01T00:00:00Z',
                  'waitingSince': '2026-11-01T00:00:00Z',
                  'lastMessage': {'fromSupport': false, 'isInternalNote': false, 'excerpt': 'help', 'createdAt': '2026-11-01T00:00:00Z'},
                  'closedAt': null,
                },
              ],
              'total': 1,
            },
            'audit': null,
          };

      final user = (await repository().user('w-9')).valueOrNull!;

      expect(call(0), 'GET /admin/users/w-9');
      expect(user.signUpMethod, SignInMethod.google);
      expect(user.links.single.url, 'https://t.me/x');
      expect(user.stats.longestStreak, 5);
      expect(user.access.activeSessions, 2);
      expect(user.actions.canRestoreContent, isTrue);
      expect(user.actions.canRemoveBadge, isFalse);
      expect(user.moderation!.hiddenWithAccount, 5);
      expect(user.moderation!.history.single.action, ModerationLogAction.userHideContent);
      expect(user.reportsAgainst!.items.single.reason, ReportReason.spam);
      expect(user.reportsFiled!.total, 0);
      expect(user.verification, isNull);
      expect(user.tickets!.items.single.number, 4);
      expect(user.audit, isNull);
    });

    test('phone, sign out of all devices, reset password and remove badge call their routes', () async {
      respond = (options) => switch (options.path) {
            '/admin/users/w-9/phone' => {'phoneNumber': '+201001234567'},
            '/admin/users/w-9/reset-password' => {'temporaryPassword': 'Tmp-1234-abcd'},
            _ => (204, null),
          };

      final phone = (await repository().revealPhone('w-9')).valueOrNull;
      await repository().logoutAll('w-9');
      final password = (await repository().resetPassword('w-9')).valueOrNull;
      await repository().removeBadge('w-9');

      expect([for (var i = 0; i < 4; i++) call(i)], [
        'GET /admin/users/w-9/phone',
        'POST /admin/users/w-9/logout-all',
        'POST /admin/users/w-9/reset-password',
        'DELETE /admin/users/w-9/verification',
      ]);
      expect(phone, '+201001234567');
      expect(password, 'Tmp-1234-abcd');
    });

    test('a protected account keeps its code', () async {
      respond = (_) => (403, {'status': 403, 'code': 'moderation.staff_target'});

      final result = await repository().logoutAll('u-super');

      expect(result.failureOrNull?.code, FailureCodes.moderationStaffTarget);
    });
  });

  group('content', () {
    Map<String, Object?> articleJson() => {
          'id': 'a-1',
          'slug': 'rag',
          'status': 'archived',
          'title': 'RAG',
          'language': 'en',
          'author': author,
          'field': field,
          'topic': null,
          'publishedAt': '2026-11-03T10:00:00Z',
          'readCount': 50,
          'reactionCount': 4,
          'commentCount': 2,
          'hiddenAt': null,
          'featuredAt': '2026-11-05T10:00:00Z',
          'openReports': 1,
          'reportCount': 2,
        };

    test('GET /admin/articles: the period, filters and the featured order in the query', () async {
      respond = (_) => {
            'items': [articleJson()],
            'page': 1,
            'pageSize': 50,
            'totalCount': 1,
            'totalPages': 1,
          };

      final page = (await repository().articles(
        const AdminArticleQuery(from: '2026-11-02', to: '2026-11-07', q: 'rag', hidden: false, featured: true, reported: true, featuredOrder: true),
      ))
          .valueOrNull!;

      expect(call(0), 'GET /admin/articles');
      expect(query(0), {
        'from': '2026-11-02',
        'to': '2026-11-07',
        'q': 'rag',
        'hidden': 'false',
        'featured': 'true',
        'reported': 'true',
        'sort': 'featured',
        'page': '1',
        'pageSize': '50',
      });
      final article = page.items.single;
      expect(article.archived, isTrue);
      expect(article.isFeatured, isTrue);
      expect(article.isHidden, isFalse);
    });

    test('a field, one of its topics and a writer go as ids; their chip labels are never sent', () async {
      respond = (_) => {'items': <Object>[], 'page': 1, 'pageSize': 50, 'totalCount': 0, 'totalPages': 0};

      final filters = const AdminArticleQuery()
          .withField('f-1', label: '.NET')
          .withTopic('t-3', label: 'EF Core')
          .withWriter('w-1', label: '@mona_dev');
      await repository().articles(filters);
      // A new field drops the topic, which belonged to the old one.
      await repository().articles(filters.withField('f-2', label: 'AI'));

      expect(query(0), {'field': 'f-1', 'topic': 't-3', 'writer': 'w-1', 'sort': 'published', 'page': '1', 'pageSize': '50'});
      expect(query(1), {'field': 'f-2', 'writer': 'w-1', 'sort': 'published', 'page': '1', 'pageSize': '50'});
    });

    test("the route's query: a writer from a user's page, and dates; anything malformed is dropped", () {
      expect(
        AdminArticleQuery.fromUri(Uri.parse('/admin/content?writer=w-1&writerName=%40mona_dev')),
        const AdminArticleQuery(writer: 'w-1', writerLabel: '@mona_dev'),
      );
      expect(
        AdminArticleQuery.fromUri(Uri.parse('/admin/content?from=2026-11-01&to=nov&writer=..%2Fx')),
        const AdminArticleQuery(from: '2026-11-01'),
      );
    });

    test('GET /admin/articles/{id} and GET /admin/comments', () async {
      respond = (options) => options.path.startsWith('/admin/articles/')
          ? articleJson()
          : {
              'items': [
                {
                  'id': 'c-1',
                  'body': 'Spam link',
                  'author': author,
                  'article': {'id': 'a-1', 'slug': 'rag', 'title': 'RAG', 'language': 'en'},
                  'parentId': 'c-0',
                  'createdAt': '2026-11-07T10:00:00Z',
                  'editedAt': null,
                  'hiddenAt': '2026-11-07T11:00:00Z',
                  'likeCount': 0,
                  'replyCount': 0,
                  'openReports': 0,
                  'reportCount': 0,
                },
              ],
              'page': 1,
              'pageSize': 50,
              'totalCount': 1,
              'totalPages': 1,
            };

      final article = (await repository().article('a-1')).valueOrNull!;
      final comments = (await repository().comments(const AdminCommentQuery(hidden: true))).valueOrNull!;

      expect(call(0), 'GET /admin/articles/a-1');
      expect(article.slug, 'rag');
      expect(call(1), 'GET /admin/comments');
      expect(query(1), {'hidden': 'true', 'page': '1', 'pageSize': '50'});
      expect(comments.items.single.isHidden, isTrue);
      expect(comments.items.single.parentId, 'c-0');
    });

    test('featuring: PUT to feature, DELETE to stop', () async {
      respond = (_) => (204, null);

      await repository().setFeatured('a-1', featured: true);
      await repository().setFeatured('a-1', featured: false);

      expect(call(0), 'PUT /admin/articles/a-1/featured');
      expect(call(1), 'DELETE /admin/articles/a-1/featured');
    });

    // As built: an unknown or deleted article is 404 on DELETE too.
    test('unfeaturing an unknown article keeps its code', () async {
      respond = (_) => (404, {'status': 404, 'code': 'article.not_found'});

      final result = await repository().setFeatured('gone', featured: false);

      expect(result.failureOrNull?.code, FailureCodes.articleNotFound);
    });

    // As built: an archived article that was never published has no publishedAt.
    test('an article never published parses with no date', () async {
      respond = (_) => {...articleJson(), 'publishedAt': null};

      final article = (await repository().article('a-1')).valueOrNull!;

      expect(article.publishedAt, isNull);
      expect(article.archived, isTrue);
    });
  });

  group('verification queue (F19)', () {
    Map<String, Object?> requestJson({String status = 'pending'}) => {
          'id': 'v-1',
          'status': status,
          'user': {...author, 'headline': 'Senior .NET'},
          'field': {'id': 'f-1', 'slug': 'software', 'name': 'Software'},
          'jobTitle': 'Engineer',
          'proofUrl': 'https://github.com/mona',
          'proof': {'fileName': 'cv.pdf', 'contentType': 'application/pdf', 'sizeBytes': 2048},
          'note': null,
          'submittedAt': '2026-11-01T00:00:00Z',
          'decidedAt': null,
          'decidedBy': null,
          'rejectionReason': null,
        };

    test('the queue by status and cursor; one request; approve; reject with a trimmed reason', () async {
      respond = (options) => switch (options.path) {
            '/admin/verification-requests' => {
                'items': [requestJson()],
                'nextCursor': 'n2',
              },
            '/admin/verification-requests/v-1' => requestJson(status: 'approved'),
            _ => (204, null),
          };

      final page = (await repository().verificationRequests(VerificationRequestStatus.pending, cursor: 'c1')).valueOrNull!;
      final request = (await repository().verificationRequest('v-1')).valueOrNull!;
      await repository().approve('v-1');
      await repository().reject('v-1', '  Not enough proof  ');

      expect(call(0), 'GET /admin/verification-requests');
      expect(query(0), {'status': 'pending', 'cursor': 'c1', 'limit': '20'});
      expect(page.items.single.proof?.fileName, 'cv.pdf');
      expect(page.nextCursor, 'n2');
      expect(request.status, VerificationRequestStatus.approved);
      expect(call(2), 'POST /admin/verification-requests/v-1/approve');
      expect(call(3), 'POST /admin/verification-requests/v-1/reject');
      expect(requests[3].data, {'reason': 'Not enough proof'});
    });

    test('already decided keeps its code', () async {
      respond = (_) => (409, {'status': 409, 'code': 'verification.already_decided'});

      final result = await repository().approve('v-1');

      expect(result.failureOrNull?.code, FailureCodes.verificationAlreadyDecided);
    });
  });

  group('POST /moderation/actions (F23 additions)', () {
    ModerationRepositoryImpl moderation() => ModerationRepositoryImpl(ModerationApi(dio));

    test('suspend with hideContent sends it; without, the key is left out', () async {
      respond = (_) => (204, null);

      await moderation().act(const ModerationCommand(
        ModerationActionType.suspend,
        ModerationTargetRef.user('w-9'),
        note: 'Spam account',
        durationDays: 3,
        hideContent: true,
      ));
      await moderation().act(const ModerationCommand(ModerationActionType.suspend, ModerationTargetRef.user('w-9'), note: 'Spam'));

      expect(requests[0].data, {
        'action': 'suspend',
        'targetType': 'user',
        'targetId': 'w-9',
        'note': 'Spam account',
        'durationDays': 3,
        'hideContent': true,
      });
      expect(requests[1].data, {'action': 'suspend', 'targetType': 'user', 'targetId': 'w-9', 'note': 'Spam'});
    });

    test('hide_content and unhide_content on a user', () async {
      respond = (_) => (204, null);

      await moderation().act(const ModerationCommand(ModerationActionType.hideContent, ModerationTargetRef.user('w-9')));
      await moderation().act(const ModerationCommand(ModerationActionType.unhideContent, ModerationTargetRef.user('w-9')));

      expect(requests[0].data, {'action': 'hide_content', 'targetType': 'user', 'targetId': 'w-9'});
      expect(requests[1].data, {'action': 'unhide_content', 'targetType': 'user', 'targetId': 'w-9'});
    });
  });
}
