import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/network/api_error_mapper.dart';
import 'package:readin/features/admin/data/models/admin_models.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/auth/data/datasources/account_api.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/blocks/data/datasources/blocks_api.dart';
import 'package:readin/features/blocks/data/repositories/blocks_repository_impl.dart';
import 'package:readin/features/comments/data/models/comment_models.dart';
import 'package:readin/features/legal/data/datasources/legal_api.dart';
import 'package:readin/features/legal/data/repositories/legal_repository_impl.dart';
import 'package:readin/features/legal/domain/entities/legal.dart';
import 'package:readin/features/moderation/data/datasources/moderation_api.dart';
import 'package:readin/features/moderation/data/models/moderation_models.dart';
import 'package:readin/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/notifications/data/models/notification_models.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';

import '../../helpers/fake_auth.dart';

/// The store additions against the contract (docs/api/contract-v1.md "Block (F36)", "Legal & content filter (F37)",
/// "Report additions (F22, store requirements)"): method, path, query and body of each call, every new DTO field, and
/// the problems' extensions.
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

  group('Block (F36)', () {
    BlocksRepositoryImpl repository() => BlocksRepositoryImpl(BlocksApi(dio));

    test('PUT /users/{id}/block, DELETE with restoreFollow only when asked, GET /me/blocked', () async {
      respond = (options) => switch (options.method) {
            'GET' => {
                'items': [
                  {
                    'user': {'id': 'u-9', 'displayName': 'Mona', 'username': 'mona_dev', 'avatarUrl': null, 'isVerified': true},
                    'blockedAt': '2026-11-08T09:00:00Z',
                  },
                ],
              },
            'PUT' => {'userId': 'u-9', 'isBlocked': true, 'followRemoved': true},
            _ => {'userId': 'u-9', 'isBlocked': false, 'followRemoved': false},
          };

      final blocked = (await repository().block('u-9')).valueOrNull!;
      await repository().unblock('u-9');
      await repository().unblock('u-9', restoreFollow: true);
      final list = (await repository().blocked()).valueOrNull!;

      expect(call(0), 'PUT /users/u-9/block');
      expect(blocked.isBlocked, isTrue);
      expect(blocked.followRemoved, isTrue);
      expect(call(1), 'DELETE /users/u-9/block');
      expect(requests[1].uri.queryParameters, isEmpty);
      expect(requests[2].uri.queryParameters, {'restoreFollow': 'true'});
      expect(call(3), 'GET /me/blocked');
      expect(list.single.user.username, 'mona_dev');
      expect(list.single.user.isVerified, isTrue);
      expect(list.single.blockedAt, DateTime.utc(2026, 11, 8, 9));
    });

    test('403 block.blocked carries the person; 400 block.self and block.limit are codes', () async {
      final blocked = ApiErrorMapper.fromProblem(403, {
        'code': 'block.blocked',
        'title': 'You blocked this account. Unblock it first.',
        'blockedUser': {'id': 'u-9', 'username': 'mona_dev', 'displayName': 'Mona'},
      });
      expect(blocked, isA<BlockedFailure>());
      final person = blocked as BlockedFailure;
      expect((person.blockedUserId, person.blockedUsername, person.blockedDisplayName), ('u-9', 'mona_dev', 'Mona'));
      expect(person.statusCode, 403);

      expect(ApiErrorMapper.fromProblem(400, {'code': 'block.self'}).code, FailureCodes.blockSelf);
      expect(ApiErrorMapper.fromProblem(400, {'code': 'block.limit'}).code, FailureCodes.blockLimit);
      // Without the person (an older API), a plain failure.
      expect(ApiErrorMapper.fromProblem(403, {'code': 'block.blocked'}), isNot(isA<BlockedFailure>()));
    });

    test('CommentDto.isUnavailable keeps a blocked person\'s comment as a placeholder; ArticleDetailsDto.unlinkedMentionIds', () {
      final comment = CommentModel.fromJson({
        'id': 'c-1',
        'articleId': 'a-1',
        'body': null,
        'author': null,
        'createdAt': '2026-11-08T09:00:00Z',
        'replyCount': 2,
        'isUnavailable': true,
      }).toEntity();
      expect(comment.isUnavailable, isTrue);
      expect(comment.isPlaceholder, isTrue);

      final details = ArticleDetailsModel.fromJson({
        ..._articleJson(),
        'unlinkedMentionIds': ['u-9'],
        'reportedByMe': true,
      }).toEntity();
      expect(details.unlinkedMentionIds, ['u-9']);
      expect(details.card.reportedByMe, isTrue);
    });
  });

  group('Report additions (F22)', () {
    ModerationRepositoryImpl repository() => ModerationRepositoryImpl(ModerationApi(dio));

    test('POST /reports takes a repost and alsoBlock', () async {
      respond = (_) => (204, null);

      await repository().report(const ModerationTargetRef.repost('r-1'), ReportReason.harassment, alsoBlock: true);
      await repository().report(const ModerationTargetRef.comment('c-1'), ReportReason.spam);

      expect(call(0), 'POST /reports');
      expect(requests[0].data, {'targetType': 'repost', 'targetId': 'r-1', 'reason': 'harassment', 'alsoBlock': true});
      expect((requests[1].data as Map).containsKey('alsoBlock'), isFalse, reason: 'left out unless true');
    });

    test('the cards, comments and reposts say what the viewer reported; reposts carry their id', () {
      final card = ArticleCardModel.fromJson({
        ..._articleJson(),
        'reportedByMe': true,
        'repostedBy': {
          'user': {'id': 'u-2', 'displayName': 'Ahmed', 'username': 'ahmed'},
          'repostedAt': '2026-11-08T08:00:00Z',
          'caption': 'Worth a read',
          'repostId': 'r-1',
          'reportedByMe': true,
        },
      }).toEntity();
      expect(card.reportedByMe, isTrue);
      expect(card.repostedBy!.repostId, 'r-1');
      expect(card.repostedBy!.reportedByMe, isTrue);

      final comment = CommentModel.fromJson({
        'id': 'c-1',
        'articleId': 'a-1',
        'body': 'Spam',
        'createdAt': '2026-11-08T09:00:00Z',
        'reportedByMe': true,
      }).toEntity();
      expect(comment.reportedByMe, isTrue);
      // An older API: nothing reported, nothing unavailable.
      final older = CommentModel.fromJson({'id': 'c-2', 'articleId': 'a-1', 'body': 'Hi', 'createdAt': '2026-11-08T09:00:00Z'}).toEntity();
      expect((older.reportedByMe, older.isUnavailable), (false, false));
    });

    test('the queue: case age and Urgent, repost cases; the reports of the content filter with their terms', () {
      final item = ModerationQueueItemModel.fromJson({
        'targetType': 'repost',
        'targetId': 'r-1',
        'status': 'open',
        'reportCount': 2,
        'reasons': {'spam': 2},
        'firstReportedAt': '2026-11-07T08:00:00Z',
        'lastReportedAt': '2026-11-08T08:00:00Z',
        'ageHours': 13,
        'urgent': true,
        'target': {
          'state': 'visible',
          'author': {'id': 'u-2', 'displayName': 'Ahmed', 'username': 'ahmed'},
          'body': 'Worth a read',
          'articleId': 'a-1',
          'articleSlug': 'di-dotnet',
          'articleTitle': 'DI in .NET',
        },
      }).toEntity()!;
      expect(item.targetType, ModerationTargetType.repost);
      expect((item.ageHours, item.urgent), (13, true));
      expect(item.target.body, 'Worth a read');
      expect(item.target.articleTitle, 'DI in .NET');

      final system = ModerationReportModel.fromJson({
        'id': 'rep-1',
        'reporter': null,
        'reason': 'other',
        'status': 'open',
        'createdAt': '2026-11-08T08:00:00Z',
        'isSystem': true,
        'matchedTerms': ['spam-word'],
      }).toEntity();
      expect(system.isSystem, isTrue);
      expect(system.reporter, isNull);
      expect(system.matchedTerms, ['spam-word']);

      expect(ModerationLogAction.fromWire('repost.delete'), ModerationLogAction.repostDelete);
    });

    test('the dashboard and the summary count the open reports past 24 hours', () {
      expect(const AdminSummaryModel(openReports: 4, openReportsOver24h: 1).toEntity().openReportsOver24h, 1);
      expect(DashboardCardsModel.fromJson({'openReports': 4, 'openReportsOver24h': 2}).toEntity().openReportsOver24h, 2);
      expect(DashboardCardsModel.fromJson(const {}).toEntity().openReportsOver24h, isNull, reason: 'without moderation.manage');
    });

    test('report_new and report_resolved read their data', () {
      final reportNew = NotificationModel.fromJson({
        'id': 'n-1',
        'type': 'report_new',
        'createdAt': '2026-11-08T08:00:00Z',
        'updatedAt': '2026-11-08T08:30:00Z',
        'data': {'targetType': 'comment', 'targetId': 'c-1', 'targetLabel': 'Buy now', 'reportCount': 3, 'system': true},
        'link': 'readin://admin/reports/comment/c-1',
      }).toEntity();
      expect(reportNew.type, NotificationType.reportNew);
      expect((reportNew.reportTargetType, reportNew.targetLabel, reportNew.reportCount, reportNew.systemReport), ('comment', 'Buy now', 3, true));

      final resolved = NotificationModel.fromJson({
        'id': 'n-2',
        'type': 'report_resolved',
        'createdAt': '2026-11-08T08:00:00Z',
        'updatedAt': '2026-11-08T08:00:00Z',
        'data': {'targetType': 'article', 'targetLabel': 'DI in .NET', 'outcome': 'no_violation'},
        'link': 'readin://notifications',
      }).toEntity();
      expect(resolved.type, NotificationType.reportResolved);
      expect(resolved.reportOutcome, ReportOutcome.noViolation);
      expect(resolved.actor, isNull);
    });
  });

  group('Legal & content filter (F37)', () {
    test('GET /legal: the version, what changed and the pages', () async {
      respond = (_) => {
            'termsVersion': '2026-11-08',
            'effectiveAt': '2026-11-08T00:00:00Z',
            'summary': {'ar': 'أضفنا قواعد المجتمع.', 'en': '  '},
            'pages': {'terms': '/terms', 'communityGuidelines': '/community-guidelines', 'privacy': '/privacy'},
          };

      final legal = (await LegalRepositoryImpl(LegalApi(dio)).getLegal()).valueOrNull!;

      expect(call(0), 'GET /legal');
      expect(legal.termsVersion, '2026-11-08');
      expect(legal.summaryFor('ar'), 'أضفنا قواعد المجتمع.');
      expect(legal.summaryFor('en'), isNull, reason: 'blank is none: the screen says it generically');
      expect(legal.pages, LegalPages.defaults);
    });

    test('MeDto: the accepted version and mustAcceptTerms; the guards order (password, PIN, terms, profile)', () {
      MeModel me(Map<String, dynamic> extra) =>
          MeModel.fromJson({'id': 'u-1', 'displayName': 'Mona', 'username': 'mona', 'onboardingCompleted': true, ...extra});

      final pending = me({'termsVersion': null, 'mustAcceptTerms': true}).toEntity();
      expect(pending.termsVersion, isNull);
      expect(pending.mustAcceptTerms, isTrue);
      expect(SessionState(status: SessionStatus.authenticated, me: pending).gate, AccountGate.acceptTerms);

      final pin = me({'mustAcceptTerms': true, 'mustSetRecoveryPin': true, 'isProfileComplete': false}).toEntity();
      expect(SessionState(status: SessionStatus.authenticated, me: pin).gate, AccountGate.setRecoveryPin);
      final profile = me({'mustAcceptTerms': true, 'isProfileComplete': false}).toEntity();
      expect(SessionState(status: SessionStatus.authenticated, me: profile).gate, AccountGate.acceptTerms);

      final accepted = me({'termsVersion': '2026-11-08', 'mustAcceptTerms': false}).toEntity();
      expect(SessionState(status: SessionStatus.authenticated, me: accepted).gate, isNull);
      // An older API says nothing: no terms screen (nobody is locked out).
      expect(me(const {}).toEntity().mustAcceptTerms, isFalse);
    });

    test('POST /me/terms/accept', () async {
      respond = (_) => {'id': 'u-1', 'displayName': 'Mona', 'username': 'mona', 'termsVersion': '2026-11-08'};
      await AccountApi(dio).acceptTerms();
      expect(call(0), 'POST /me/terms/accept');
    });

    test('422 content.objectionable names its field (the matched words never come); 429 content.too_many its limit', () {
      final objectionable = ApiErrorMapper.fromProblem(422, {
        'code': 'content.objectionable',
        'title': 'This text breaks our Community Guidelines.',
        'field': 'content',
        'language': 'ar-EG',
        'blockId': 'b-3',
      });
      expect(objectionable, isA<ObjectionableContentFailure>());
      final failure = objectionable as ObjectionableContentFailure;
      expect((failure.field, failure.language, failure.blockId), ('content', 'ar-EG', 'b-3'));
      // On its input in the forms that read field errors.
      expect(failure.fieldErrors, {'content': [FailureCodes.contentObjectionable]});

      final limit = ApiErrorMapper.fromProblem(429, {'code': 'content.too_many', 'limit': 'comments_per_hour'});
      expect(limit, isA<ContentLimitFailure>());
      expect((limit as ContentLimitFailure).limit, ContentLimitKind.commentsPerHour);
    });
  });
}

Map<String, dynamic> _articleJson() => {
      'id': 'a-1',
      'slug': 'di-dotnet',
      'language': 'ar-EG',
      'title': 'DI in .NET',
      'field': {'id': 'f-1', 'slug': 'dotnet', 'nameAr': 'دوت نت', 'nameEn': '.NET'},
      'author': {'id': 'u-1', 'displayName': 'Mona', 'username': 'mona_dev'},
      'publishedAt': '2026-11-01T08:00:00Z',
    };
