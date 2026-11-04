import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/failure_messages.dart';
import 'package:readin/core/l10n/formatters.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/auth/presentation/session/suspended_session_listener.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/moderation/domain/usecases/moderation_usecases.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_action_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_case_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_list_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_notices_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_summary_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/report_cubit.dart';
import 'package:readin/features/moderation/presentation/pages/moderation_case_page.dart';
import 'package:readin/features/moderation/presentation/pages/moderation_page.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_notices_host.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_widgets.dart';
import 'package:readin/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/moderation_fakes.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/profile_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/verification_fixtures.dart';

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

const _en = Variant(AppLocales.en, Brightness.light);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(AppLocales.en);
    registerFallbackValue(const ModerationTargetRef.article(''));
    registerFallbackValue(ReportReason.spam);
    registerFallbackValue(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.article('')));
  });

  setUp(() => ModerationClock.now = () => moderationNow);
  tearDown(() => ModerationClock.now = DateTime.now);

  MockSessionCubit sessionOf(Me? me) =>
      MockSessionCubit()..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Me? me = sampleMe,
    List<BlocProvider> providers = const [],
    Size size = const Size(390, 844),
  }) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(providers: [BlocProvider<SessionCubit>.value(value: sessionOf(me)), ...providers], child: child),
      variant: _en,
    ));
    await tester.pump();
  }

  MockModerationActionCubit actionCubit({Failure? result}) {
    final cubit = MockModerationActionCubit()..hold(null);
    when(() => cubit.run(any())).thenAnswer((_) async => result);
    return cubit;
  }

  group('report sheet (one for articles, comments and users)', () {
    late MockModerationRepository repository;

    setUp(() => repository = MockModerationRepository());

    Future<void> open(WidgetTester tester, ModerationTargetRef target, {Me? me = sampleMe}) async {
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showReportSheet(context, target: target, cubit: () => ReportCubit(SubmitReport(repository))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        me: me,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    for (final (target, title) in const [
      (ModerationTargetRef.article('art-7'), 'Report article'),
      (ModerationTargetRef.comment('c-42'), 'Report comment'),
      (ModerationTargetRef.user('w-9'), 'Report user'),
    ]) {
      testWidgets('${target.type.name}: a reason, then sent and thanked', (tester) async {
        when(() => repository.report(any(), any(), details: any(named: 'details'))).thenAnswer((_) async => const Ok<void>(null));
        await open(tester, target);

        expect(find.text(title), findsOneWidget);
        expect(find.byType(RadioListTile<ReportReason>), findsNWidgets(5));
        await tester.tap(find.text('Spam'));
        await tester.pump();
        await tester.tap(find.text('Send report'));
        await tester.pumpAndSettle();

        verify(() => repository.report(target, ReportReason.spam, details: null)).called(1);
        expect(find.text(title), findsNothing, reason: 'the sheet closed');
        expect(find.text("Thanks, we'll review it."), findsOneWidget);
      });
    }

    testWidgets('Send waits for a reason; details stop at 500 characters with a counter', (tester) async {
      await open(tester, const ModerationTargetRef.article('art-7'));

      FilledButton send() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report'));
      expect(send().onPressed, isNull);
      expect(find.text('0/500'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'x' * 600);
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, hasLength(500));
      expect(find.text('500/500'), findsOneWidget);
      expect(send().onPressed, isNull, reason: 'still no reason');

      await tester.tap(find.text('Copyright'));
      await tester.pump();
      expect(send().onPressed, isNotNull);
    });

    testWidgets('a refusal shows in the sheet, which stays open with what was typed', (tester) async {
      when(() => repository.report(any(), any(), details: any(named: 'details')))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.reportOwnContent, statusCode: 400)));
      await open(tester, const ModerationTargetRef.user('w-9'));

      await tester.tap(find.text('Harassment'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'شتيمة في الـ bio');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      verify(() => repository.report(const ModerationTargetRef.user('w-9'), ReportReason.harassment, details: 'شتيمة في الـ bio')).called(1);
      expect(find.text("You can't report yourself or your own content."), findsOneWidget);
      expect(find.text('Report user'), findsOneWidget);
      expect(find.text("Thanks, we'll review it."), findsNothing);
    });

    testWidgets('guests get the sign-in prompt instead', (tester) async {
      await open(tester, const ModerationTargetRef.article('art-7'), me: null);

      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
      expect(find.text('Report article'), findsNothing);
    });
  });

  group('reader menu', () {
    late MockArticleCubit article;
    late MockModerationActionCubit actions;

    ArticleDetails details({bool hidden = false}) => ArticleDetails(
          card: sampleCard(1, language: 'en'),
          availableLanguages: const ['en'],
          content: RDocDocument.empty,
          moderation: hidden ? ArticleModeration(hiddenAt: moderationNow, note: 'Copied') : null,
        );

    Future<void> pumpMenu(WidgetTester tester, {Me? me = sampleMe, bool hidden = false, Failure? result}) async {
      article = MockArticleCubit()..hold(ArticleState(status: ArticleStatus.ready, article: details(hidden: hidden)));
      actions = actionCubit(result: result);
      await pump(
        tester,
        Scaffold(body: Center(child: ArticleMenuButton(article: details(hidden: hidden)))),
        me: me,
        providers: [BlocProvider<ArticleCubit>.value(value: article), BlocProvider<ModerationActionCubit>.value(value: actions)],
      );
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Article options'));
      await tester.pumpAndSettle();
    }

    const editorialMe = Me(id: 'a-1', displayName: 'ReadIn Editorial', username: 'editorial');

    test('items: report unless it is yours; moderators hide or unhide', () {
      expect(articleMenuItems(own: false, moderator: false, hidden: false), [ArticleMenuItem.report]);
      expect(articleMenuItems(own: true, moderator: false, hidden: false), isEmpty);
      expect(articleMenuItems(own: false, moderator: true, hidden: false), [ArticleMenuItem.report, ArticleMenuItem.hide]);
      expect(articleMenuItems(own: true, moderator: true, hidden: true), [ArticleMenuItem.unhide]);
    });

    testWidgets('a reader can report, in the error color; nothing else', (tester) async {
      await pumpMenu(tester);
      await openMenu(tester);

      final label = tester.widget<Text>(find.text('Report article'));
      final context = tester.element(find.text('Report article'));
      expect(label.style?.color, context.colors.error);
      expect(find.text('Hide article'), findsNothing);
    });

    testWidgets('your own article has no menu (until F28 adds items)', (tester) async {
      await pumpMenu(tester, me: editorialMe);

      expect(find.byTooltip('Article options'), findsNothing);
    });

    testWidgets('guests get the sign-in prompt', (tester) async {
      await pumpMenu(tester, me: null);
      await openMenu(tester);
      await tester.tap(find.text('Report article'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
    });

    testWidgets('report opens the shared sheet for the article', (tester) async {
      final repository = MockModerationRepository();
      getIt.registerFactory<ReportCubit>(() => ReportCubit(SubmitReport(repository)));
      addTearDown(() => getIt.unregister<ReportCubit>());
      await pumpMenu(tester);
      await openMenu(tester);
      await tester.tap(find.text('Report article'));
      await tester.pumpAndSettle();

      expect(find.text('Send report'), findsOneWidget);
      expect(find.text(l10n.reportBody), findsOneWidget);
    });

    testWidgets('a moderator hides it with a note: the reader shows it hidden', (tester) async {
      await pumpMenu(tester, me: moderatorMe());
      await openMenu(tester);
      expect(find.text('Report article'), findsOneWidget);
      await tester.tap(find.text('Hide article'));
      await tester.pumpAndSettle();

      expect(find.text('Hide this article?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'منقول من غير مصدر');
      await tester.tap(find.widgetWithText(FilledButton, 'Hide article'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.article('art-1'), note: 'منقول من غير مصدر')))
          .called(1);
      final moderation = verify(() => article.setModeration(captureAny())).captured.single as ArticleModeration?;
      expect(moderation?.note, 'منقول من غير مصدر', reason: 'the banner shows the note at once');
      expect(find.text('Article hidden'), findsOneWidget);
    });

    testWidgets('cancelling the hide does nothing', (tester) async {
      await pumpMenu(tester, me: moderatorMe());
      await openMenu(tester);
      await tester.tap(find.text('Hide article'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => actions.run(any()));
    });

    testWidgets('a moderator unhides a hidden article', (tester) async {
      await pumpMenu(tester, me: moderatorMe(), hidden: true);
      await openMenu(tester);
      await tester.tap(find.text('Unhide article'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.unhide, ModerationTargetRef.article('art-1')))).called(1);
      verify(() => article.setModeration(null)).called(1);
      expect(find.text('Article visible again'), findsOneWidget);
    });

    testWidgets('a refusal says why and leaves the article as it was', (tester) async {
      await pumpMenu(tester, me: moderatorMe(), hidden: true, result: const Failure(FailureCodes.moderationActionInvalid, statusCode: 400));
      await openMenu(tester);
      await tester.tap(find.text('Unhide article'));
      await tester.pumpAndSettle();

      verifyNever(() => article.setModeration(any()));
      expect(find.text("This action isn't available here."), findsOneWidget);
    });

    testWidgets('the hidden banner shows the note', (tester) async {
      await pump(
        tester,
        Scaffold(body: HiddenArticleBanner(moderation: ArticleModeration(hiddenAt: moderationNow, note: 'Copied from a blog'))),
      );

      expect(find.text('Hidden by moderators'), findsOneWidget);
      expect(find.text('Only its author and moderators can see it.'), findsOneWidget);
      expect(find.text("Moderator's note"), findsOneWidget);
      expect(find.text('Copied from a blog'), findsOneWidget);
    });
  });

  group('profile menu', () {
    late MockModerationActionCubit actions;

    Future<void> pumpProfile(WidgetTester tester, {Me? me = sampleMe, bool own = false}) async {
      actions = actionCubit();
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        provided(
          [
            ...appStores(me: me),
            ...profileScreen(own ? ownProfile : otherProfile),
            BlocProvider<ModerationActionCubit>.value(value: actions),
          ],
          const ProfileView(),
        ),
        variant: _en,
      ));
      await tester.pump();
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
    }

    testWidgets('a reader can only report the user; your own profile has no menu', (tester) async {
      await pumpProfile(tester);
      await openMenu(tester);
      expect(find.text('Report user'), findsOneWidget);
      expect(find.text('Warn'), findsNothing);
      expect(find.text('Suspend account'), findsNothing);

      await pumpProfile(tester, own: true);
      expect(find.byTooltip('More options'), findsNothing);
    });

    testWidgets('guests get the sign-in prompt', (tester) async {
      await pumpProfile(tester, me: null);
      await openMenu(tester);
      await tester.tap(find.text('Report user'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
    });

    testWidgets('moderators warn with a required note; suspend needs users.suspend', (tester) async {
      await pumpProfile(tester, me: moderatorMe(canSuspend: false));
      await openMenu(tester);
      expect(find.text('Suspend account'), findsNothing);
      await tester.tap(find.text('Warn'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Warn '), findsOneWidget);
      FilledButton send() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send warning'));
      expect(send().onPressed, isNull, reason: 'a warning needs a note');
      await tester.enterText(find.byType(TextField), '  Please keep it civil  ');
      await tester.pump();
      await tester.tap(find.text('Send warning'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.warn, ModerationTargetRef.user('u-mona'), note: 'Please keep it civil')))
          .called(1);
      expect(find.text('Warning sent'), findsOneWidget);
    });

    testWidgets('suspend: 1, 7 or 30 days or permanently, with a note', (tester) async {
      await pumpProfile(tester, me: moderatorMe());
      await openMenu(tester);
      await tester.tap(find.text('Suspend account'));
      await tester.pumpAndSettle();

      for (final label in ['1 day', '7 days', '30 days', 'Permanently']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('7 days'));
      await tester.enterText(find.byType(TextField), 'Spam links');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();
      verify(() => actions.run(const ModerationCommand(ModerationActionType.suspend, ModerationTargetRef.user('u-mona'), note: 'Spam links', durationDays: 7)))
          .called(1);
      expect(find.text('Account suspended'), findsOneWidget);

      await openMenu(tester);
      await tester.tap(find.text('Suspend account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permanently'));
      await tester.enterText(find.byType(TextField), 'Again');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();
      verify(() => actions.run(const ModerationCommand(ModerationActionType.suspend, ModerationTargetRef.user('u-mona'), note: 'Again')))
          .called(1);
    });
  });

  group('moderation page', () {
    late Map<ReportStatus, MockModerationQueueCubit> queues;
    late MockModerationLogCubit log;

    MockModerationQueueCubit queue(ModerationListState<ModerationQueueItem> state) {
      final cubit = MockModerationQueueCubit()..hold(state);
      when(cubit.load).thenAnswer((_) async => null);
      when(cubit.refresh).thenAnswer((_) async => null);
      when(cubit.loadMore).thenAnswer((_) async {});
      when(() => cubit.setType(any())).thenAnswer((_) async {});
      return cubit;
    }

    setUp(() {
      queues = {
        ReportStatus.open: queue(ModerationListState(status: ModerationListStatus.ready, items: [articleItem(), commentItem(), userItem()])),
        ReportStatus.resolved: queue(const ModerationListState(status: ModerationListStatus.ready)),
        ReportStatus.dismissed: queue(const ModerationListState(
          status: ModerationListStatus.failure,
          failure: Failure(FailureCodes.networkOffline),
        )),
      };
      log = MockModerationLogCubit()
        ..hold(ModerationListState(status: ModerationListStatus.ready, items: [
          logEntry('l-1', note: 'نقل من غير مصدر', reportsClosed: 4),
          logEntry(
            'l-2',
            action: ModerationLogAction.userSuspend,
            targetType: ModerationTargetType.user,
            targetId: 'w-9',
            targetLabel: '@crypto_deals',
            suspendedUntil: null,
          ),
        ]));
      when(log.load).thenAnswer((_) async => null);
    });

    Widget page() => ModerationPage(queueCubit: (status) => queues[status]!, logCubit: () => log);

    testWidgets('only moderators get in', (tester) async {
      await pump(tester, page());

      expect(find.text('This page is for moderators'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('tabs: open cases with their counts, an empty tab, an error tab with retry, and the log', (tester) async {
      await pump(tester, page(), me: moderatorMe());

      for (final tab in ['Open', 'Resolved', 'Dismissed', 'Log']) {
        expect(find.widgetWithText(Tab, tab), findsOneWidget);
      }
      verify(queues[ReportStatus.open]!.load).called(1);
      expect(find.textContaining('Dependency Injection'), findsOneWidget);
      expect(find.text('4 reports'), findsOneWidget);
      expect(find.text('Misinformation 3'), findsOneWidget);
      expect(find.text('Last report: 3 hrs ago'), findsOneWidget);
      expect(find.text('7 reports'), findsOneWidget);
      expect(find.text('2 warnings'), findsOneWidget);

      await tester.tap(find.widgetWithText(Tab, 'Resolved'));
      await tester.pumpAndSettle();
      expect(find.text('No resolved reports'), findsOneWidget);

      await tester.tap(find.widgetWithText(Tab, 'Dismissed'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.errOffline), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(queues[ReportStatus.dismissed]!.load).called(2);

      await tester.tap(find.widgetWithText(Tab, 'Log'));
      await tester.pumpAndSettle();
      expect(find.text('Hid an article'), findsOneWidget);
      expect(find.textContaining('Closed 4 reports'), findsOneWidget);
      expect(find.text('Suspended an account'), findsOneWidget);
      expect(find.textContaining('Permanently'), findsOneWidget);
    });

    testWidgets('the type filter reloads the tab', (tester) async {
      await pump(tester, page(), me: moderatorMe());

      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Comments'));
      verify(() => queues[ReportStatus.open]!.setType(ModerationTargetType.comment)).called(1);
    });

    testWidgets('scrolling near the end loads the next page; a failed page offers a retry', (tester) async {
      final many = [for (var i = 0; i < 8; i++) articleItem(id: 'art-$i')];
      queues[ReportStatus.open] = queue(ModerationListState(status: ModerationListStatus.ready, items: many, nextCursor: 'p2'));
      await pump(tester, page(), me: moderatorMe());

      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pump();
      verify(queues[ReportStatus.open]!.loadMore).called(greaterThan(0));

      queues[ReportStatus.open] = queue(ModerationListState(
        status: ModerationListStatus.ready,
        items: many,
        nextCursor: 'p2',
        moreFailure: const Failure(FailureCodes.networkOffline),
      ));
      await tester.pumpWidget(const SizedBox());
      await pump(tester, page(), me: moderatorMe());
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pump();
      expect(find.text("Couldn't load more."), findsOneWidget);
    });

    testWidgets('a case opens from the queue; back from it the queue reloads', (tester) async {
      usePhoneSurface(tester);
      final router = GoRouter(
        initialLocation: '/moderation',
        routes: [
          GoRoute(
            path: '/moderation',
            builder: (_, _) => page(),
            routes: [GoRoute(path: ':type/:id', builder: (_, state) => Scaffold(body: Text('case ${state.pathParameters['id']}')))],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(BlocProvider<SessionCubit>.value(
        value: sessionOf(moderatorMe()),
        child: MaterialApp.router(
          theme: AppTheme.light(AppLocales.en),
          locale: AppLocales.en,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('7 reports'));
      await tester.pumpAndSettle();
      expect(find.text('case w-9'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      verify(queues[ReportStatus.open]!.refresh).called(1);
    });
  });

  group('case page', () {
    late MockModerationCaseCubit caseCubit;
    late MockModerationActionCubit actions;

    Future<void> pumpCase(WidgetTester tester, ModerationCase c, {Me? me}) async {
      caseCubit = MockModerationCaseCubit()..hold(ModerationCaseState(status: ModerationCaseStatus.ready, moderationCase: c));
      when(caseCubit.refresh).thenAnswer((_) async {});
      actions = actionCubit();
      await pump(
        tester,
        ModerationCaseView(type: c.item.targetType),
        me: me ?? moderatorMe(),
        providers: [BlocProvider<ModerationCaseCubit>.value(value: caseCubit), BlocProvider<ModerationActionCubit>.value(value: actions)],
        size: const Size(390, 1800),
      );
    }

    ModerationCase commentCase({ModerationTargetState state = ModerationTargetState.visible}) =>
        ModerationCase(item: commentItem(state: state), reports: [report('rp-9', reason: ReportReason.harassment)]);

    ModerationCase userCase({bool suspended = false}) =>
        ModerationCase(item: userItem(suspended: suspended), reports: [report('rp-8', reason: ReportReason.spam)]);

    testWidgets('the target with a link, its reports and its history', (tester) async {
      await pumpCase(tester, articleCase());

      expect(find.text('Reported article'), findsOneWidget);
      expect(find.textContaining('Dependency Injection'), findsOneWidget);
      expect(find.text('Open article'), findsOneWidget);
      expect(find.text('4 reports'), findsOneWidget);
      expect(find.text('Reports (3)'), findsOneWidget);
      expect(find.textContaining('Singleton'), findsOneWidget);
      expect(find.text('Copied from a Microsoft Learn page.'), findsOneWidget);
      expect(find.text('Deleted user'), findsOneWidget, reason: 'a reporter who deleted their account');
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Warned a user'), findsOneWidget);
      for (final action in ['Hide article', 'Warn author', 'Suspend author', 'Dismiss reports']) {
        expect(find.widgetWithText(OutlinedButton, action), findsOneWidget);
      }
    });

    testWidgets('hide asks first; cancel does nothing, confirming runs it and reloads the case', (tester) async {
      await pumpCase(tester, articleCase());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Hide article'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => actions.run(any()));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Hide article'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hide article'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.article('art-7'), note: ''))).called(1);
      verify(caseCubit.refresh).called(1);
      expect(find.text('Article hidden'), findsOneWidget);
    });

    testWidgets("warning the author also closes the article's reports", (tester) async {
      await pumpCase(tester, articleCase());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Warn author'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Check your sources');
      await tester.pump();
      await tester.tap(find.text('Send warning'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(
            ModerationActionType.warn,
            ModerationTargetRef.user('w-1'),
            note: 'Check your sources',
            resolveReportsOf: ModerationTargetRef.article('art-7'),
          ))).called(1);
    });

    testWidgets('dismiss asks first', (tester) async {
      await pumpCase(tester, articleCase());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Dismiss reports'));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss these reports?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Dismiss reports'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.dismiss, ModerationTargetRef.article('art-7')))).called(1);
      expect(find.text('Reports dismissed'), findsOneWidget);
    });

    testWidgets('a hidden article can be unhidden', (tester) async {
      await pumpCase(tester, articleCase(state: ModerationTargetState.hidden));

      expect(find.text('Hidden'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Unhide article'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.unhide, ModerationTargetRef.article('art-7')))).called(1);
    });

    testWidgets('comment: delete asks first; a deleted comment can only be dismissed or its author dealt with', (tester) async {
      await pumpCase(tester, commentCase());

      expect(find.textContaining('On “'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete comment'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.commentsModDeleteTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete comment'));
      await tester.pumpAndSettle();
      verify(() => actions.run(const ModerationCommand(ModerationActionType.delete, ModerationTargetRef.comment('c-42')))).called(1);

      await pumpCase(tester, commentCase(state: ModerationTargetState.deleted));
      expect(find.widgetWithText(OutlinedButton, 'Delete comment'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Hide comment'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Warn author'), findsOneWidget);
    });

    testWidgets('user: suspend with a length and a note', (tester) async {
      await pumpCase(tester, userCase());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Suspend account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 days'));
      await tester.enterText(find.byType(TextField), 'Spam');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();

      verify(() => actions.run(const ModerationCommand(ModerationActionType.suspend, ModerationTargetRef.user('w-9'), note: 'Spam', durationDays: 30)))
          .called(1);
    });

    testWidgets('user: a suspended account can be lifted; without users.suspend neither shows', (tester) async {
      await pumpCase(tester, userCase(suspended: true));

      expect(find.textContaining('Permanently suspended'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Lift suspension'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Lift suspension'));
      await tester.pumpAndSettle();
      verify(() => actions.run(const ModerationCommand(ModerationActionType.unsuspend, ModerationTargetRef.user('w-9')))).called(1);

      await pumpCase(tester, userCase(suspended: true), me: moderatorMe(canSuspend: false));
      expect(find.widgetWithText(OutlinedButton, 'Lift suspension'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Suspend account'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Warn'), findsOneWidget);
    });

    testWidgets('a refusal says why and keeps the case', (tester) async {
      await pumpCase(tester, userCase());
      when(() => actions.run(any())).thenAnswer((_) async => const Failure(FailureCodes.moderationStaffTarget, statusCode: 403));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Warn'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump();
      await tester.tap(find.text('Send warning'));
      await tester.pumpAndSettle();

      expect(find.text("You can't warn or suspend a member of the moderation team."), findsOneWidget);
      verifyNever(caseCubit.refresh);
    });

    testWidgets('only moderators; a failed load can be retried', (tester) async {
      await pumpCase(tester, articleCase(), me: sampleMe);
      expect(find.text('This page is for moderators'), findsOneWidget);

      caseCubit = MockModerationCaseCubit()
        ..hold(const ModerationCaseState(status: ModerationCaseStatus.failure, failure: Failure(FailureCodes.networkOffline)));
      when(caseCubit.refresh).thenAnswer((_) async {});
      await pump(
        tester,
        const ModerationCaseView(type: ModerationTargetType.user),
        me: moderatorMe(),
        providers: [BlocProvider<ModerationCaseCubit>.value(value: caseCubit), BlocProvider<ModerationActionCubit>.value(value: actionCubit())],
      );
      await tester.tap(find.text('Try again'));
      verify(caseCubit.refresh).called(1);
    });
  });

  group('settings', () {
    Future<MockModerationSummaryCubit> pumpSettings(WidgetTester tester, Me me) async {
      final summary = MockModerationSummaryCubit()..hold(const ModerationSummary(article: 1, comment: 2, total: 3));
      when(summary.load).thenAnswer((_) async {});
      final settings = MockSettingsCubit()..hold(const AppSettings());
      await pump(
        tester,
        const SettingsView(),
        me: me,
        size: const Size(390, 2400),
        providers: [
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<LinkedAccountsCubit>.value(value: MockLinkedAccountsCubit()..hold(const LinkedAccountsState())),
          BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..hold(const PrivacyState())),
          BlocProvider<ModerationSummaryCubit>.value(value: summary),
          verificationEntryProvider(),
        ],
      );
      return summary;
    }

    testWidgets('Moderation with the open count, for moderation.manage only', (tester) async {
      final summary = await pumpSettings(tester, moderatorMe());

      expect(find.text('Moderation'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('3 items waiting for review'), findsOneWidget);
      expect(find.widgetWithText(Badge, '3'), findsOneWidget);
      verify(summary.load).called(1);

      final readerSummary = await pumpSettings(tester, sampleMe);
      expect(find.text('Moderation'), findsNothing);
      verifyNever(readerSummary.load);
    });
  });

  group('notices', () {
    late StreamController<List<ModerationNotice>> changes;
    late MockModerationNoticesCubit cubit;
    final key = GlobalKey<NavigatorState>();

    setUp(() {
      changes = StreamController<List<ModerationNotice>>.broadcast();
      cubit = MockModerationNoticesCubit();
      whenListen(cubit, changes.stream, initialState: [warningNotice(), hiddenNotice()]);
      when(() => cubit.acknowledge(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.single as String;
        changes.add([for (final n in cubit.state) if (n.id != id) n]);
      });
    });

    tearDown(() => changes.close());

    Future<void> pumpHost(WidgetTester tester, {bool Function()? canShow, Listenable? readyChanges}) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        theme: AppTheme.light(AppLocales.en),
        locale: AppLocales.en,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => BlocProvider<ModerationNoticesCubit>.value(
          value: cubit,
          child: ModerationNoticesHost(navigatorKey: key, canShow: canShow, changes: readyChanges, child: child!),
        ),
        home: const Scaffold(body: Text('home')),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('each notice is a dialog until "Got it", which acknowledges it; then the next one', (tester) async {
      await pumpHost(tester);

      expect(find.text('You received a warning from the moderation team'), findsOneWidget);
      expect(find.text('Please stop posting links to paid courses in comments.'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // the barrier doesn't close it
      await tester.pumpAndSettle();
      expect(find.text('You received a warning from the moderation team'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      verify(() => cubit.acknowledge('n-1')).called(1);
      expect(find.textContaining('was hidden'), findsOneWidget);
      expect(find.textContaining('بسرعة'), findsOneWidget);
      expect(find.textContaining('معلومات غلط'), findsOneWidget, reason: 'the note');
      expect(find.text("Moderator's note"), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      verify(() => cubit.acknowledge('n-2')).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('waits while the app is not ready (the splash)', (tester) async {
      var ready = false;
      final readyChanges = ValueNotifier(0);
      addTearDown(readyChanges.dispose);
      await pumpHost(tester, canShow: () => ready, readyChanges: readyChanges);
      expect(find.byType(AlertDialog), findsNothing);

      ready = true;
      readyChanges.value++;
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('suspended message', () {
    test('says until when, or that it is permanent', () {
      final until = DateTime.utc(2026, 11, 9, 12);

      expect(
        localizeFailure(l10n, Failure(FailureCodes.userSuspended, statusCode: 403, suspendedUntil: until)),
        'This account is suspended until ${formatDateTime(until, 'en')}. Contact support.',
      );
      expect(
        localizeFailure(l10n, const Failure(FailureCodes.userSuspended, statusCode: 403)),
        'This account is permanently suspended. Contact support.',
      );
      expect(localizeErrorCode(l10n, FailureCodes.moderationNoteRequired), 'Write a note first.');
      expect(localizeErrorCode(l10n, FailureCodes.reportTargetNotFound), "What you're reporting doesn't exist anymore.");
    });

    testWidgets('the app hears when a session ends for a suspended account, once', (tester) async {
      final states = StreamController<SessionState>();
      addTearDown(states.close);
      final session = MockSessionCubit();
      whenListen(session, states.stream, initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      final heard = <Failure>[];
      await tester.pumpWidget(BlocProvider<SessionCubit>.value(
        value: session,
        child: SuspendedSessionListener(onSuspended: heard.add, child: const SizedBox()),
      ));

      const reason = Failure(FailureCodes.userSuspended, statusCode: 403);
      states
        ..add(const SessionState(status: SessionStatus.guest, failure: reason))
        ..add(const SessionState(status: SessionStatus.guest, failure: reason))
        ..add(const SessionState(status: SessionStatus.guest));
      await tester.pump();

      expect(heard, [reason]);
    });
  });
}
