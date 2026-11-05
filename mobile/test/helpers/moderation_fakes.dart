import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_action_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_case_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_list_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_notices_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_summary_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/report_cubit.dart';
import 'package:readin/features/profile/domain/entities/profile_link.dart';

class MockModerationRepository extends Mock implements ModerationRepository {}

class MockReportCubit extends MockCubit<ReportState> implements ReportCubit {}

class MockModerationActionCubit extends MockCubit<ModerationCommand?> implements ModerationActionCubit {}

class MockModerationSummaryCubit extends MockCubit<ModerationSummary?> implements ModerationSummaryCubit {}

class MockModerationQueueCubit extends MockCubit<ModerationListState<ModerationQueueItem>> implements ModerationQueueCubit {}

class MockModerationLogCubit extends MockCubit<ModerationListState<ModerationLogEntry>> implements ModerationLogCubit {}

class MockModerationCaseCubit extends MockCubit<ModerationCaseState> implements ModerationCaseCubit {}

class MockModerationNoticesCubit extends MockCubit<List<ModerationNotice>> implements ModerationNoticesCubit {}

/// "Now" for moderation times in tests and goldens: 2026-11-02 12:00 UTC.
final moderationNow = DateTime.utc(2026, 11, 2, 12);

/// What a Member holds (SPEC §10.2): reading, writing, interacting, reporting. No moderation.
const memberPermissions = [
  'articles.read',
  Permissions.articlesCreate,
  'articles.export_pdf',
  'comments.create',
  'reactions.create',
  'follows.manage',
  'saved.manage',
  Permissions.reportsCreate,
];

/// What the SuperAdmin holds (SPEC §10.2): everything.
const superAdminPermissions = [
  ...memberPermissions,
  'articles.feature',
  Permissions.moderationManage,
  Permissions.usersSuspend,
  'users.reset_password',
  'users.read.pii',
  'verification.manage',
  'taxonomy.manage',
  'paths.manage',
  'system.settings',
];

/// The viewer who moderates: the SuperAdmin (`+12025550101`), the only holder of `moderation.manage` today (SPEC §10).
/// [canSuspend] false drops `users.suspend`, as a later staff role might: the app gates on permissions, never on the
/// role name, so the role stays `SuperAdmin` here.
Me moderatorMe({bool canSuspend = true}) => Me(
      id: 'u-super',
      phoneNumber: '+12025550101',
      displayName: 'Super Admin',
      username: 'superadmin',
      onboardingCompleted: true,
      roles: const ['SuperAdmin'],
      permissions: [
        for (final permission in superAdminPermissions)
          if (canSuspend || permission != Permissions.usersSuspend) permission,
      ],
    );

/// A Member with the Verified badge (`isVerified`): every Member permission and none of the moderation ones. The
/// badge isn't a role and opens nothing.
Me verifiedMemberMe() => const Me(
      id: 'u-104',
      phoneNumber: '+12025550104',
      displayName: '.NET Writer',
      username: 'dotnet_writer',
      onboardingCompleted: true,
      isVerified: true,
      roles: ['Member'],
      permissions: memberPermissions,
    );

const modAuthorAr = Author(id: 'w-1', displayName: 'منى عبد الله', username: 'mona_dev', isVerified: true);
const modAuthorEn = Author(id: 'w-2', displayName: 'Omar Khaled', username: 'omar_k');
const spammer = Author(id: 'w-9', displayName: 'Free Crypto Deals', username: 'crypto_deals');

const reporterA = UserSummary(id: 'r-1', displayName: 'سارة (.NET)', username: 'sara_net');
const reporterB = UserSummary(id: 'r-2', displayName: 'Youssef Hassan', username: 'reader1');
const moderatorSummary = UserSummary(id: 'u-super', displayName: 'Super Admin', username: 'superadmin');

DateTime _ago(Duration d) => moderationNow.subtract(d);

/// An article with open reports: an Arabic title with English terms.
ModerationQueueItem articleItem({
  ReportStatus status = ReportStatus.open,
  ModerationTargetState state = ModerationTargetState.visible,
  String id = 'art-7',
}) =>
    ModerationQueueItem(
      targetType: ModerationTargetType.article,
      targetId: id,
      status: status,
      reportCount: 4,
      reasons: const {ReportReason.misinformation: 3, ReportReason.copyright: 1},
      firstReportedAt: _ago(const Duration(days: 2)),
      lastReportedAt: _ago(const Duration(hours: 3)),
      closedAt: status == ReportStatus.open ? null : _ago(const Duration(hours: 1)),
      target: ModerationTarget(
        state: state,
        author: modAuthorAr,
        title: 'إزاي تعمل Dependency Injection في .NET 10 من غير مكتبات',
        slug: 'di-dotnet-10',
        language: 'ar-EG',
      ),
    );

/// A reported comment, in English, on an Arabic article.
ModerationQueueItem commentItem({ReportStatus status = ReportStatus.open, ModerationTargetState state = ModerationTargetState.visible}) =>
    ModerationQueueItem(
      targetType: ModerationTargetType.comment,
      targetId: 'c-42',
      status: status,
      reportCount: 2,
      reasons: const {ReportReason.harassment: 2},
      firstReportedAt: _ago(const Duration(hours: 30)),
      lastReportedAt: _ago(const Duration(minutes: 20)),
      closedAt: status == ReportStatus.open ? null : _ago(const Duration(minutes: 5)),
      target: ModerationTarget(
        state: state,
        author: modAuthorEn,
        body: 'This is the worst article I have ever read. The author clearly has no idea what Scoped means.',
        articleId: 'art-3',
        articleSlug: 'scoped-vs-transient',
        articleTitle: 'إزاي تختار بين Transient و Scoped؟',
      ),
    );

/// The spammer's abusive title and links (F14), as a user case shows them.
const spammerHeadline = 'Crypto expert | اكسب 1000\$ في يوم';
const spammerLinks = [
  ProfileLink(platform: LinkPlatform.telegram, url: 'https://t.me/free_crypto_deals'),
  ProfileLink(platform: LinkPlatform.other, url: 'https://free-crypto.example/join?ref=readin', label: 'Free coins'),
];

/// A reported user (spam), suspended or not; with [headline] and [links] (F14) when given.
ModerationQueueItem userItem({
  ReportStatus status = ReportStatus.open,
  bool suspended = false,
  DateTime? until,
  String? headline,
  List<ProfileLink>? links = const [],
}) =>
    ModerationQueueItem(
      targetType: ModerationTargetType.user,
      targetId: spammer.id,
      status: status,
      reportCount: 7,
      reasons: const {ReportReason.spam: 6, ReportReason.other: 1},
      firstReportedAt: _ago(const Duration(days: 9)),
      lastReportedAt: _ago(const Duration(days: 8)),
      closedAt: status == ReportStatus.open ? null : _ago(const Duration(days: 1)),
      target: ModerationTarget(
        state: suspended ? ModerationTargetState.suspended : ModerationTargetState.active,
        author: headline == null
            ? spammer
            : Author(id: spammer.id, displayName: spammer.displayName, username: spammer.username, headline: headline),
        suspendedUntil: until,
        warningCount: 2,
        links: links,
      ),
    );

ModerationReport report(
  String id, {
  UserSummary? reporter = reporterA,
  ReportReason reason = ReportReason.misinformation,
  String? details,
  ReportStatus status = ReportStatus.open,
  Duration ago = const Duration(hours: 3),
  UserSummary? closedBy,
}) =>
    ModerationReport(
      id: id,
      reporter: reporter,
      reason: reason,
      details: details,
      status: status,
      createdAt: _ago(ago),
      closedAt: status == ReportStatus.open ? null : _ago(const Duration(hours: 1)),
      closedBy: closedBy,
    );

ModerationLogEntry logEntry(
  String id, {
  ModerationLogAction action = ModerationLogAction.articleHide,
  ModerationTargetType targetType = ModerationTargetType.article,
  String targetId = 'art-7',
  String? targetLabel = 'إزاي تعمل Dependency Injection في .NET 10 من غير مكتبات',
  UserSummary? targetUser,
  UserSummary? moderator = moderatorSummary,
  String? note,
  DateTime? suspendedUntil,
  int reportsClosed = 0,
  Duration ago = const Duration(days: 1),
}) =>
    ModerationLogEntry(
      id: id,
      action: action,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      targetUser: targetUser,
      moderator: moderator,
      note: note,
      suspendedUntil: suspendedUntil,
      reportsClosed: reportsClosed,
      createdAt: _ago(ago),
    );

/// The article case: three reports (one with mixed details, one from a deleted account) and a history.
ModerationCase articleCase({ModerationTargetState state = ModerationTargetState.visible}) => ModerationCase(
      item: articleItem(state: state),
      reports: [
        report('rp-1', details: 'المقال بيقول إن الـ Singleton أسرع دايمًا، وده مش صح خالص.'),
        report('rp-2', reporter: reporterB, reason: ReportReason.copyright, details: 'Copied from a Microsoft Learn page.', ago: const Duration(hours: 20)),
        report('rp-3', reporter: null, ago: const Duration(days: 2)),
      ],
      history: [
        logEntry(
          'h-1',
          action: ModerationLogAction.userWarn,
          targetType: ModerationTargetType.user,
          targetId: modAuthorAr.id,
          targetLabel: '@mona_dev',
          note: 'راجعي المصادر قبل النشر.',
          ago: const Duration(days: 30),
        ),
      ],
    );

ModerationNotice warningNotice({String id = 'n-1', String? note = 'Please stop posting links to paid courses in comments.'}) =>
    ModerationNotice(id: id, kind: ModerationNoticeKind.warning, note: note, createdAt: _ago(const Duration(hours: 2)));

ModerationNotice hiddenNotice({String id = 'n-2'}) => ModerationNotice(
      id: id,
      kind: ModerationNoticeKind.articleHidden,
      note: 'المقال فيه معلومات غلط عن الـ EF Core.',
      article: const ModerationNoticeArticle(id: 'art-7', slug: 'ef-core', title: 'EF Core بسرعة'),
      createdAt: _ago(const Duration(hours: 1)),
    );
