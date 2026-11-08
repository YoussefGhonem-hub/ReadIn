import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/push/push_links.dart';
import 'package:readin/features/admin/domain/entities/admin_dashboard.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/blocks/domain/repositories/blocks_repository.dart';
import 'package:readin/features/blocks/domain/usecases/block_usecases.dart';
import 'package:readin/features/blocks/presentation/cubit/blocks_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/moderation/domain/usecases/moderation_usecases.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_action_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_case_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/report_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/reported_content_cubit.dart';
import 'package:readin/features/moderation/presentation/pages/moderation_case_page.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_widgets.dart';
import 'package:readin/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_text.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/moderation_fakes.dart';
import '../../helpers/mute_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _MockBlocksRepository extends Mock implements BlocksRepository {}

const _en = Variant(AppLocales.en, Brightness.light);

/// F22's store additions: report and block in one step, reported content collapsed for the reporter, the console's
/// 24-hour target (age, Urgent), the content filter's reports, repost cases, and the two new notifications.
void main() {
  late AppLocalizations l10n;
  late MockSessionCubit session;
  late ReportedContentCubit reported;
  late BlocksCubit blocks;
  late FollowsCubit follows;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(AppLocales.en);
    registerFallbackValue(const ModerationTargetRef.article(''));
    registerFallbackValue(ReportReason.spam);
    registerFallbackValue(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.article('')));
  });

  setUp(() {
    ModerationClock.now = () => moderationNow;
    session = MockSessionCubit()..hold(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    reported = ReportedContentCubit(session);
    follows = FollowsCubit(SetFollowing(MockFollowRepository()));
    blocks = BlocksCubit(SetUserBlocked(_MockBlocksRepository()), session, follows);
  });

  tearDown(() async {
    ModerationClock.now = DateTime.now;
    await reported.close();
    await blocks.close();
    await follows.close();
  });

  Future<void> pump(WidgetTester tester, Widget child, {Me? me, List<BlocProvider> providers = const [], Size size = const Size(390, 844)}) async {
    usePhoneSurface(tester, size: size);
    if (me != null) session.hold(SessionState(status: SessionStatus.authenticated, me: me));
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<BlocksCubit>.value(value: blocks),
          BlocProvider<ReportedContentCubit>.value(value: reported),
          ...providers,
        ],
        child: Scaffold(body: child),
      ),
      variant: _en,
    ));
    await tester.pump();
  }

  group('the report sheet', () {
    late MockModerationRepository repository;

    setUp(() {
      repository = MockModerationRepository();
      when(() => repository.report(any(), any(), details: any(named: 'details'), alsoBlock: any(named: 'alsoBlock')))
          .thenAnswer((_) async => const Ok<void>(null));
    });

    Future<void> open(WidgetTester tester, ModerationTargetRef target, {ReportAuthor? author}) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showReportSheet(context, target: target, author: author, cubit: () => ReportCubit(SubmitReport(repository))),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Also block @username" (off by default) blocks the author in the same step; the report collapses it', (tester) async {
      await open(tester, const ModerationTargetRef.comment('c-1'), author: const ReportAuthor('u-9', 'omar_dev'));
      final box = find.byKey(const ValueKey('report-also-block'));
      expect(box, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(box).value, isFalse);
      expect(find.textContaining('Also block'), findsOneWidget);

      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(box);
      await tester.pump();
      await tester.tap(find.text(l10n.reportSubmit));
      await tester.pumpAndSettle();

      verify(() => repository.report(const ModerationTargetRef.comment('c-1'), ReportReason.spam, details: null, alsoBlock: true)).called(1);
      expect(blocks.state.isBlocked('u-9'), isTrue, reason: 'the API blocked them with the report');
      expect(reported.isReported(ModerationTargetType.comment, 'c-1'), isTrue);
      expect(find.textContaining('is blocked'), findsOneWidget);
    });

    testWidgets('left unticked, the report goes alone; no checkbox without an author or on yourself', (tester) async {
      await open(tester, const ModerationTargetRef.article('a-1'), author: const ReportAuthor('u-9', 'omar_dev'));
      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text(l10n.reportSubmit));
      await tester.pumpAndSettle();
      verify(() => repository.report(const ModerationTargetRef.article('a-1'), ReportReason.spam, details: null, alsoBlock: false)).called(1);
      expect(blocks.state.users, isEmpty);
      expect(find.text(l10n.reportThanks), findsOneWidget);

      await open(tester, const ModerationTargetRef.article('a-2'));
      expect(find.byKey(const ValueKey('report-also-block')), findsNothing);
      Navigator.of(tester.element(find.text(l10n.reportSubmit))).pop();
      await tester.pumpAndSettle();

      await open(tester, const ModerationTargetRef.article('a-3'), author: ReportAuthor(sampleMe.id, sampleMe.username));
      expect(find.byKey(const ValueKey('report-also-block')), findsNothing, reason: 'your own content');
    });

    testWidgets('a repost is reported as a repost', (tester) async {
      await open(tester, const ModerationTargetRef.repost('r-1'), author: const ReportAuthor('u-2', 'ahmed'));
      expect(find.text(l10n.reportTitleRepost), findsOneWidget);
      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text(l10n.reportSubmit));
      await tester.pumpAndSettle();
      verify(() => repository.report(const ModerationTargetRef.repost('r-1'), ReportReason.spam, details: null, alsoBlock: false)).called(1);
      expect(reported.isReported(ModerationTargetType.repost, 'r-1'), isTrue);
    });
  });

  group('hidden for the reporter', () {
    testWidgets('a card reported before (reportedByMe) or now folds to a line with Show; others never', (tester) async {
      final before = muteCard(1, title: 'Reported before');
      final card = ArticleCard(
        id: before.id,
        slug: before.slug,
        language: 'en',
        title: 'Reported before',
        field: before.field,
        author: before.author,
        readingTimeMinutes: 3,
        publishedAt: before.publishedAt,
        reportedByMe: true,
      );
      final now = muteCard(2, title: 'Reported now', language: 'en');
      await pump(
        tester,
        ListView(children: [
          ArticleCardTile(article: card, onTap: () {}),
          ArticleCardTile(article: now, onTap: () {}),
        ]),
      );
      expect(find.text('Reported before'), findsNothing);
      expect(find.text(l10n.reportedHidden), findsOneWidget);
      expect(find.text('Reported now'), findsOneWidget);

      reported.markReported(ModerationTargetRef.article(now.id));
      await tester.pumpAndSettle();
      expect(find.text(l10n.reportedHidden), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('reported-show')).first);
      await tester.pump();
      expect(find.text('Reported before'), findsOneWidget, reason: 'shown here only');
      expect(find.text(l10n.reportedHidden), findsOneWidget);

      reported.markReported(const ModerationTargetRef.user('u-9'));
      expect(reported.state.length, 1, reason: 'a reported user stays visible');
    });

    testWidgets('a reported comment collapses with Show; its thread stays', (tester) async {
      final callbacks = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});
      await pump(
        tester,
        CommentTile(
          comment: Comment(id: 'c-1', articleId: 'a-1', body: 'Words', author: omarWriter, createdAt: DateTime.utc(2026), reportedByMe: true),
          callbacks: callbacks,
        ),
      );
      expect(find.text('Words'), findsNothing);
      expect(find.text(l10n.reportedHidden), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reported-comment-show')));
      await tester.pump();
      expect(find.text('Words'), findsOneWidget);
    });

    test('signing in as someone else forgets what was reported', () async {
      final other = MockSessionCubit();
      final controller = StreamController<SessionState>();
      whenListen(other, controller.stream, initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      final cubit = ReportedContentCubit(other)..markReported(const ModerationTargetRef.article('a-1'));
      controller.add(SessionState(status: SessionStatus.authenticated, me: moderatorMe()));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isEmpty);
      await controller.close();
      await cubit.close();
    });
  });

  group('the console', () {
    testWidgets('a case shows its age, and «Urgent» after 12 hours', (tester) async {
      final base = commentItem();
      ModerationQueueItem aged(int hours) => ModerationQueueItem(
            targetType: base.targetType,
            targetId: base.targetId,
            status: ReportStatus.open,
            reportCount: base.reportCount,
            firstReportedAt: base.firstReportedAt,
            lastReportedAt: base.lastReportedAt,
            target: base.target,
            ageHours: hours,
            urgent: hours >= ModerationQueueItem.urgentAfterHours,
          );
      await pump(tester, ListView(children: [ModerationQueueTile(item: aged(3)), ModerationQueueTile(item: aged(13))]));
      expect(find.text('Waiting 3 hours'), findsOneWidget);
      expect(find.text('Waiting 13 hours'), findsOneWidget);
      expect(find.byKey(const ValueKey('moderation-urgent')), findsOneWidget);
      expect(find.text(l10n.moderationUrgent), findsOneWidget);
    });

    testWidgets('a report of the content filter reads «Content filter» with the matched terms', (tester) async {
      await pump(
        tester,
        ModerationReportTile(
          report: ModerationReport(
            id: 'rp-1',
            reason: ReportReason.other,
            status: ReportStatus.open,
            createdAt: moderationNow,
            isSystem: true,
            matchedTerms: const ['badword', 'spam link'],
          ),
        ),
      );
      expect(find.byKey(const ValueKey('moderation-report-system')), findsOneWidget);
      expect(find.text(l10n.moderationContentFilter), findsOneWidget);
      expect(find.textContaining('badword'), findsOneWidget);
    });

    testWidgets('a repost case: the caption and the article; Delete repost and Dismiss', (tester) async {
      final item = ModerationQueueItem(
        targetType: ModerationTargetType.repost,
        targetId: 'r-1',
        status: ReportStatus.open,
        reportCount: 1,
        firstReportedAt: moderationNow,
        lastReportedAt: moderationNow,
        target: const ModerationTarget(
          state: ModerationTargetState.visible,
          author: modAuthorEn,
          body: 'Read this scam',
          articleId: 'a-1',
          articleSlug: 'di-dotnet',
          articleTitle: 'DI in .NET',
        ),
      );
      final caseCubit = MockModerationCaseCubit()
        ..hold(ModerationCaseState(status: ModerationCaseStatus.ready, moderationCase: ModerationCase(item: item, reports: [report('rp-1')])));
      when(caseCubit.refresh).thenAnswer((_) async {});
      final actions = MockModerationActionCubit()..hold(null);
      when(() => actions.run(any())).thenAnswer((_) async => null);
      await pump(
        tester,
        const ModerationCaseView(type: ModerationTargetType.repost),
        me: moderatorMe(),
        providers: [BlocProvider<ModerationCaseCubit>.value(value: caseCubit), BlocProvider<ModerationActionCubit>.value(value: actions)],
        size: const Size(390, 1600),
      );
      expect(find.text('Read this scam'), findsOneWidget);
      expect(find.textContaining('DI in .NET'), findsOneWidget);
      expect(find.text(l10n.moderationDismiss), findsOneWidget);
      expect(find.text(l10n.articleMenuHide), findsNothing, reason: 'a repost is deleted, not hidden');
      expect(find.text(l10n.moderationWarnAuthor), findsNothing, reason: 'the reposter is warned from their own case');

      await tester.tap(find.text(l10n.moderationDeleteRepost));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(l10n.moderationDeleteRepost)));
      await tester.pumpAndSettle();
      verify(() => actions.run(const ModerationCommand(ModerationActionType.delete, ModerationTargetRef.repost('r-1')))).called(1);
    });

    test('the console summary carries the open reports past 24 hours', () {
      const summary = AdminSummary(openReports: 4, openReportsOver24h: 1, total: 4);
      expect(summary.openReportsOver24h, 1);
    });
  });

  group('notifications', () {
    AppNotification row(NotificationType type, {String? target, ReportOutcome? outcome, bool system = false, String? label}) =>
        AppNotification(
          id: 'n-1',
          type: type,
          createdAt: moderationNow,
          updatedAt: moderationNow,
          reportTargetType: target,
          reportOutcome: outcome,
          systemReport: system,
          targetLabel: label,
        );

    test('report_new: "New report: comment", the label under it, "Caught by the content filter" for the filter', () {
      final n = row(NotificationType.reportNew, target: 'comment', label: 'Buy now', system: true);
      expect(notificationMessage(l10n, n), 'New report: comment');
      expect(notificationMessage(l10n, row(NotificationType.reportNew, target: 'user')), 'New report: account');
      expect(notificationMessage(l10n, row(NotificationType.reportNew, target: 'repost')), 'New report: repost');
      expect(notificationDetail(n), 'Buy now');
      expect(notificationSource(l10n, n), l10n.notifReportSystem);
      expect(notificationSource(l10n, row(NotificationType.reportNew, target: 'article')), isNull);
      expect(NotificationType.reportNew.isConfigurable, isTrue);
      expect(NotificationType.listedWhenSent, contains(NotificationType.reportNew));
    });

    test('report_resolved never says who acted, nor what was done to a user; it is not configurable', () {
      expect(notificationMessage(l10n, row(NotificationType.reportResolved, target: 'article', outcome: ReportOutcome.actioned)),
          l10n.notifReportResolvedRemoved);
      expect(notificationMessage(l10n, row(NotificationType.reportResolved, target: 'user', outcome: ReportOutcome.actioned)),
          l10n.notifReportResolvedUser);
      expect(notificationMessage(l10n, row(NotificationType.reportResolved, target: 'comment', outcome: ReportOutcome.noViolation)),
          l10n.notifReportResolvedNoViolation);
      expect(NotificationType.reportResolved.isConfigurable, isFalse);
    });

    test('readin://admin/reports/{type}/{id} opens the console case; anything else there is unknown', () {
      const id = '0a1b2c3d-0000-0000-0000-000000000001';
      expect(pushLinkToPath('readin://admin/reports/comment/$id'), '/moderation/comment/$id');
      expect(pushLinkToPath('readin://admin/reports/repost/$id'), '/moderation/repost/$id');
      expect(pushLinkToPath('readin://admin/reports/tag/$id'), isNull);
      expect(pushLinkToPath('readin://notifications'), '/notifications');
    });
  });
}
