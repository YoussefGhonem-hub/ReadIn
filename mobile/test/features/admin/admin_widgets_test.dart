import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/router.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/admin/domain/entities/admin_content.dart';
import 'package:readin/features/admin/domain/entities/admin_dashboard.dart';
import 'package:readin/features/admin/domain/entities/admin_user.dart';
import 'package:readin/features/admin/domain/entities/paged_list.dart';
import 'package:readin/features/admin/domain/usecases/admin_usecases.dart';
import 'package:readin/features/admin/presentation/admin_routes.dart';
import 'package:readin/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:readin/features/admin/presentation/cubit/admin_lists.dart';
import 'package:readin/features/admin/presentation/cubit/admin_user_cubit.dart';
import 'package:readin/features/admin/presentation/pages/admin_console_page.dart';
import 'package:readin/features/admin/presentation/pages/admin_content_page.dart';
import 'package:readin/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:readin/features/admin/presentation/pages/admin_user_page.dart';
import 'package:readin/features/admin/presentation/pages/admin_users_page.dart';
import 'package:readin/features/admin/presentation/widgets/admin_entry.dart';
import 'package:readin/features/admin/presentation/widgets/admin_filters.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/widgets/more_sheet.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_action_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_summary_cubit.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_dialogs.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_widgets.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/profile/presentation/widgets/profile_menu.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';
import 'package:readin/features/support/domain/entities/support.dart';
import 'package:readin/features/support/domain/usecases/support_usecases.dart';
import 'package:readin/features/support/presentation/cubit/support_cubits.dart';
import 'package:readin/features/support/presentation/pages/admin_tickets_page.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';
import 'package:readin/features/taxonomy/domain/repositories/taxonomy_repository.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

import '../../helpers/admin_fakes.dart';
import '../../helpers/moderation_fakes.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/profile_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/verification_fixtures.dart';

class _MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class _MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

class _MockTaxonomyRepository extends Mock implements TaxonomyRepository {}

const _en = Variant(AppLocales.en, Brightness.light);

void main() {
  late MockAdminRepository repository;
  late _MockTaxonomyRepository taxonomyRepository;

  AdminTaxonomyChoices taxonomyChoices() => AdminTaxonomyChoices(GetFields(taxonomyRepository), GetTopics(taxonomyRepository));

  setUpAll(() {
    registerFallbackValue(const AdminUserQuery());
    registerFallbackValue(const AdminArticleQuery());
    registerFallbackValue(const AdminCommentQuery());
    registerFallbackValue(AdminPeriod.today);
  });

  setUp(() {
    repository = MockAdminRepository();
    taxonomyRepository = _MockTaxonomyRepository();
    when(() => taxonomyRepository.getFields(refresh: any(named: 'refresh'))).thenAnswer(
      (_) async => const Ok([
        Field(id: 'f-1', slug: 'dotnet', nameAr: 'دوت نت', nameEn: '.NET'),
        Field(id: 'f-2', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI'),
      ]),
    );
    when(() => taxonomyRepository.getTopics('dotnet')).thenAnswer(
      (_) async => const Ok([Topic(id: 't-3', fieldId: 'f-1', slug: 'ef-core', nameAr: 'EF Core', nameEn: 'EF Core')]),
    );
    ModerationClock.now = () => adminNow;
  });

  tearDown(() => ModerationClock.now = DateTime.now);

  MockSessionCubit sessionOf(Me? me) =>
      MockSessionCubit()..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Me? me,
    List<BlocProvider> providers = const [],
    Variant variant = _en,
    Size size = const Size(390, 844),
  }) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(providers: [BlocProvider<SessionCubit>.value(value: sessionOf(me ?? adminMe())), ...providers], child: child),
      variant: variant,
    ));
    await tester.pump();
  }

  MockAdminSummaryCubit summaryCubit(AdminSummary? summary) {
    final cubit = MockAdminSummaryCubit()..hold(summary);
    when(cubit.watch).thenAnswer((_) {});
    when(cubit.unwatch).thenAnswer((_) {});
    when(cubit.refresh).thenAnswer((_) async {});
    when(cubit.load).thenAnswer((_) async {});
    return cubit;
  }

  group('the console', () {
    const summary = AdminSummary(openReports: 3, openTickets: 2, pendingVerifications: 1, total: 6);

    testWidgets('the SuperAdmin gets the six mobile sections, the queues with their counts', (tester) async {
      final cubit = summaryCubit(summary);
      await pump(tester, AdminConsolePage(summary: cubit));

      for (final section in AdminConsoleSection.values) {
        expect(find.byKey(ValueKey('admin-section-${section.name}')), findsOneWidget);
      }
      expect(find.widgetWithText(Badge, '3'), findsOneWidget);
      expect(find.widgetWithText(Badge, '2'), findsOneWidget);
      expect(find.widgetWithText(Badge, '1'), findsOneWidget);
      expect(find.textContaining('on the web console'), findsOneWidget);
      verify(cubit.watch).called(1);
    });

    testWidgets('each section follows its own permission, never the role', (tester) async {
      await pump(
        tester,
        AdminConsolePage(summary: summaryCubit(summary)),
        me: adminMe(without: {Permissions.supportManage, Permissions.usersRead}),
      );

      expect(find.byKey(const ValueKey('admin-section-tickets')), findsNothing);
      expect(find.byKey(const ValueKey('admin-section-users')), findsNothing);
      expect(find.byKey(const ValueKey('admin-section-reports')), findsOneWidget);
    });

    testWidgets('a Member gets the no-access page and nothing is asked', (tester) async {
      final cubit = summaryCubit(null);
      await pump(tester, AdminConsolePage(summary: cubit), me: supportMemberMe);

      expect(find.text('This page is for the admin'), findsOneWidget);
      verifyNever(cubit.watch);
    });

    testWidgets('the Settings entry shows the badge and how many items wait', (tester) async {
      await pump(tester, Scaffold(body: AdminConsoleEntryTile(cubit: summaryCubit(summary))));

      expect(find.text('Admin console'), findsOneWidget);
      expect(find.text('6 items waiting'), findsOneWidget);
      expect(find.widgetWithText(Badge, '6'), findsOneWidget);
    });
  });

  group('Settings', () {
    Future<void> pumpSettings(WidgetTester tester, Me me) async {
      final moderation = MockModerationSummaryCubit()..hold(const ModerationSummary(total: 3));
      when(moderation.load).thenAnswer((_) async {});
      await pump(
        tester,
        const SettingsView(),
        me: me,
        size: const Size(390, 2600),
        providers: [
          BlocProvider<SettingsCubit>.value(value: _MockSettingsCubit()..hold(const AppSettings())),
          BlocProvider<LinkedAccountsCubit>.value(value: _MockLinkedAccountsCubit()..hold(const LinkedAccountsState())),
          BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..hold(const PrivacyState())),
          BlocProvider<ModerationSummaryCubit>.value(value: moderation),
          verificationEntryProvider(),
        ],
      );
    }

    testWidgets('the console replaces Moderation for admin.access; Help & support for every member', (tester) async {
      await pumpSettings(tester, adminMe());

      expect(find.byKey(const ValueKey('settings-admin-console')), findsOneWidget);
      expect(find.text('Moderation'), findsNothing);
      expect(find.byKey(const ValueKey('settings-support')), findsOneWidget);
    });

    testWidgets('a moderator without the console keeps Moderation; a member sees no console', (tester) async {
      await pumpSettings(tester, moderatorMe());
      expect(find.text('Moderation'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-admin-console')), findsNothing);

      await pumpSettings(tester, supportMemberMe);
      expect(find.byKey(const ValueKey('settings-admin-console')), findsNothing);
      expect(find.byKey(const ValueKey('settings-support')), findsOneWidget);
    });

    testWidgets("the More sheet: the console is the first screen for admin.access, in Moderation's place", (tester) async {
      Future<void> openSheet(Me me) => pump(
            tester,
            const Scaffold(body: MoreSheet()),
            me: me,
            size: const Size(390, 1200),
            providers: [BlocProvider<SettingsCubit>.value(value: _MockSettingsCubit()..hold(const AppSettings()))],
          );

      await openSheet(adminMe());
      final tiles = tester.widgetList<InkWell>(find.byWidgetPredicate((w) => w is InkWell && '${w.key}'.contains('more-tile-')));
      expect('${tiles.first.key}', contains('more-tile-admin'));
      expect(find.byKey(const ValueKey('more-tile-moderation')), findsNothing);

      await openSheet(moderatorMe());
      expect(find.byKey(const ValueKey('more-tile-admin')), findsNothing);
      expect(find.byKey(const ValueKey('more-tile-moderation')), findsOneWidget);
    });
  });

  group('admin actions in the normal menus', () {
    test("a profile's ⋯: no Warn or Suspend for staff; Unsuspend while suspended; Remove badge and Open in console", () {
      expect(profileMenuItems(moderator: true, canSuspend: true, staff: true), [ProfileMenuItem.mute, ProfileMenuItem.report]);
      expect(profileMenuItems(moderator: true, canSuspend: true, suspended: true), [
        ProfileMenuItem.mute,
        ProfileMenuItem.report,
        ProfileMenuItem.warn,
        ProfileMenuItem.unsuspend,
      ]);
      expect(profileMenuItems(moderator: false, canSuspend: false, canRemoveBadge: true, console: true), [
        ProfileMenuItem.mute,
        ProfileMenuItem.report,
        ProfileMenuItem.removeBadge,
        ProfileMenuItem.openInConsole,
      ]);
    });

    test("an article's ⋯: Feature or Unfeature in the reader, never feature a hidden one; Open in console", () {
      expect(
        articleMenuItems(own: false, moderator: true, hidden: false, hasAuthor: false, featured: false, console: true),
        [ArticleMenuItem.showLess, ArticleMenuItem.muteTopics, ArticleMenuItem.report, ArticleMenuItem.hide, ArticleMenuItem.feature, ArticleMenuItem.openInConsole],
      );
      expect(articleMenuItems(own: true, moderator: true, hidden: true, featured: true), [
        ArticleMenuItem.muteTopics,
        ArticleMenuItem.unhide,
        ArticleMenuItem.unfeature,
      ]);
      expect(articleMenuItems(own: true, moderator: true, hidden: true, featured: false), [ArticleMenuItem.muteTopics, ArticleMenuItem.unhide]);
    });
  });

  group("the console's suspend form", () {
    Future<SuspensionChoice?> Function() open(WidgetTester tester) {
      SuspensionChoice? result;
      var done = false;
      return () async {
        await pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showSuspendDialog(context, name: 'Free Crypto');
                  done = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        return done ? result : null;
      };
    }

    testWidgets('1, 3, 7 or 30 days, custom or permanent; a reason of 5+ characters; optionally hide everything', (tester) async {
      SuspensionChoice? result;
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showSuspendDialog(context, name: 'Free Crypto'),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (final label in ['1 day', '3 days', '7 days', '30 days', 'Custom…', 'Permanently']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      FilledButton confirm() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Suspend'));

      await tester.enterText(find.byKey(const ValueKey('suspend-reason')).first, 'Spam');
      await tester.pump();
      expect(confirm().onPressed, isNull, reason: 'a reason of 4 characters is too short');

      await tester.enterText(find.byKey(const ValueKey('suspend-reason')).first, 'Spam links');
      await tester.tap(find.byKey(const ValueKey('suspend-days--1')));
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('suspend-custom-days')), '400');
      await tester.pump();
      expect(find.text('Enter a number from 1 to 365.'), findsOneWidget);
      expect(confirm().onPressed, isNull);

      await tester.enterText(find.byKey(const ValueKey('suspend-custom-days')), '14');
      await tester.tap(find.byKey(const ValueKey('suspend-hide-content')));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();

      expect(result, (days: 14, note: 'Spam links', hideContent: true));
    });

    testWidgets('permanently sends no length', (tester) async {
      final run = open(tester);
      await run();
      await tester.tap(find.byKey(const ValueKey('suspend-days-forever')));
      await tester.enterText(find.byKey(const ValueKey('suspend-reason')).first, 'Repeated abuse');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
      await tester.pumpAndSettle();
      // The dialog closed with a permanent suspension.
      expect(find.byType(SuspendDialog), findsNothing);
    });
  });

  group('screens in every language, direction and theme', () {
    AdminDashboard dashboard() => AdminDashboard(
          period: AdminPeriod.today,
          fromDate: '2026-11-07',
          toDate: '2026-11-07',
          generatedAt: adminNow,
          cards: const DashboardCards(
            articlesPublished: DashboardValue(value: 12, previous: 9),
            newUsers: NewUsersValue(value: 1204, previous: 1300, phone: 900, google: 250, apple: 54),
            reads: DashboardValue(value: 12480, previous: 12480),
            openReports: 3,
            openTickets: 2,
            pendingVerifications: 1,
            suspendedNow: 4,
          ),
          charts: [for (var i = 0; i < 30; i++) DashboardDay(date: '2026-10-${i + 1}', newUsers: i, activeReaders: 30 - i, articlesPublished: i % 4)],
          topArticles: [
            DashboardArticle(
              id: 'a-1',
              slug: 'di',
              title: 'إزاي تعمل Dependency Injection في .NET 10 من غير مكتبات',
              language: 'ar-EG',
              field: const FieldRef(id: 'f', slug: 's', nameAr: 'البرمجيات', nameEn: 'Software'),
              publishedAt: adminNow,
              author: modAuthorAr,
              reads: 340,
            ),
          ],
          topWriters: const [DashboardWriter(writer: modAuthorEn, reads: 900, articles: 4)],
          missedSearches: const [MissedSearch(query: 'kubernetes operators', count: 7), MissedSearch(query: 'تعلم الآلة', language: 'ar', count: 2)],
          streakRetention: const StreakRetention(cohort: 40, kept: 10, rate: 0.25),
        );

    for (final variant in Variant.all) {
      testWidgets('dashboard ${variant.name}', (tester) async {
        when(() => repository.dashboard(any())).thenAnswer((_) async => Ok(dashboard()));
        await pump(
          tester,
          BlocProvider(create: (_) => AdminDashboardCubit(GetAdminDashboard(repository))..load(), child: const AdminDashboardView()),
          variant: variant,
          size: const Size(390, 3000),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('card-articles')), findsOneWidget);
      });

      testWidgets("users list and a user's page ${variant.name}", (tester) async {
        when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer(
          (_) async => Ok(PagedList(items: [userRow(openReports: 2), userRow(id: 'w-2', suspended: true)], totalCount: 2, totalPages: 1)),
        );
        await pump(
          tester,
          BlocProvider(create: (_) => AdminUsersCubit(GetAdminUsers(repository))..load(), child: const AdminUsersView()),
          variant: variant,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(AdminUserTile), findsNWidgets(2));

        final user = AdminUser(
          row: userRow(openReports: 2),
          headline: 'Crypto expert | اكسب 1000\$ في يوم',
          stats: const AdminUserStats(drafts: 1, totalReads: 40, currentStreak: 2, longestStreak: 9),
          access: const AdminUserAccess(activeSessions: 2, hasRecoveryPin: true),
          actions: const AdminUserActions(
            canSuspend: true,
            canWarn: true,
            canLogoutAll: true,
            canResetPassword: true,
            canRestoreContent: true,
            canRevealPhone: true,
          ),
          moderation: AdminUserModeration(
            warnings: 2,
            hiddenWithAccount: 5,
            history: [logEntry('h-1', action: ModerationLogAction.userHideContent, targetType: ModerationTargetType.user, targetId: 'w-9')],
            historyTotal: 1,
          ),
          tickets: AdminSection(items: [adminTicketRow()], total: 1),
        );
        when(() => repository.user('w-9')).thenAnswer((_) async => Ok(user));
        final actions = MockModerationActionCubit()..hold(null);
        await pump(
          tester,
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9')..load()),
              BlocProvider<ModerationActionCubit>.value(value: actions),
            ],
            child: const AdminUserView(),
          ),
          variant: variant,
          size: const Size(390, 3200),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('admin-user-suspend')), findsOneWidget);
        expect(find.byKey(const ValueKey('admin-user-restore-content')), findsOneWidget);
        expect(find.byKey(const ValueKey('admin-user-remove-badge')), findsNothing, reason: 'not in actions');
      });

      testWidgets('content: articles and the latest comments ${variant.name}', (tester) async {
        when(() => repository.articles(any(), page: 1, pageSize: 50)).thenAnswer(
          (_) async => Ok(PagedList(items: [adminArticle(featuredAt: adminNow), adminArticle(hiddenAt: adminNow)], totalCount: 2, totalPages: 1)),
        );
        when(() => repository.comments(any(), page: 1, pageSize: 50)).thenAnswer(
          (_) async => Ok(PagedList(
            items: [
              AdminCommentRow(
                id: 'c-1',
                body: 'This is spam: buy now https://spam.example',
                author: modAuthorEn,
                article: const AdminCommentArticle(id: 'a', slug: 'a', title: 'Scoped vs Transient'),
                createdAt: adminNow,
                openReports: 2,
              ),
            ],
            totalCount: 1,
            totalPages: 1,
          )),
        );
        await pump(
          tester,
          AdminContentPage(
            query: const AdminArticleQuery(from: '2026-11-01', to: '2026-11-07'),
            articlesCubit: AdminArticlesCubit(GetAdminArticles(repository), const AdminArticleQuery(from: '2026-11-01', to: '2026-11-07')),
            commentsCubit: AdminCommentsCubit(GetAdminComments(repository)),
            actions: MockModerationActionCubit()..hold(null),
            taxonomy: taxonomyChoices(),
          ),
          variant: variant,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(AdminArticleTile), findsNWidgets(2));
        expect(find.byKey(const ValueKey('admin-articles-period')), findsOneWidget);
        verify(() => repository.articles(const AdminArticleQuery(from: '2026-11-01', to: '2026-11-07'), page: 1, pageSize: 50)).called(1);
      });
    }
  });

  group('filters', () {
    final pickRange = AdminDatePicker.pickRange;
    tearDown(() => AdminDatePicker.pickRange = pickRange);

    testWidgets('Users: joined in a period, picked as a date range, shown on its chip and cleared with ✕', (tester) async {
      when(() => repository.users(any(), page: 1, pageSize: 50))
          .thenAnswer((_) async => Ok(PagedList(items: [userRow()], totalCount: 1, totalPages: 1)));
      DateTimeRange? opened;
      AdminDatePicker.pickRange = (_, initial) async {
        opened = initial;
        return DateTimeRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31));
      };
      final cubit = AdminUsersCubit(GetAdminUsers(repository));
      await pump(tester, BlocProvider.value(value: cubit, child: const AdminUsersView()));
      await cubit.load();
      await tester.pump();

      await tester.tap(find.text('Joined…'));
      await tester.pump();
      await tester.pump();

      expect(opened, isNull, reason: 'nothing chosen yet');
      expect(cubit.state.query.joinedFrom, '2026-10-01');
      expect(cubit.state.query.joinedTo, '2026-10-31');
      verify(() => repository.users(const AdminUserQuery(joinedFrom: '2026-10-01', joinedTo: '2026-10-31'), page: 1, pageSize: 50)).called(1);
      expect(find.textContaining('2026-10-01'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove filter'));
      await tester.pump();
      expect(cubit.state.query.hasJoinedPeriod, isFalse);
      await cubit.close();
    });

    testWidgets('Content: a field from the taxonomy, then one of its topics; a new field drops the topic', (tester) async {
      when(() => repository.articles(any(), page: 1, pageSize: 50))
          .thenAnswer((_) async => Ok(PagedList(items: [adminArticle()], totalCount: 1, totalPages: 1)));
      final cubit = AdminArticlesCubit(GetAdminArticles(repository), null);
      await pump(tester, BlocProvider.value(value: cubit, child: AdminArticlesView(taxonomy: taxonomyChoices())));
      await cubit.load();
      await tester.pump();
      expect(find.text('Topic…'), findsNothing, reason: 'a topic needs its field first');

      await tester.tap(find.text('Field…'));
      await tester.pumpAndSettle();
      expect(find.text('All fields'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('admin-choice-f-1')));
      await tester.pumpAndSettle();

      expect(cubit.state.query.field, 'f-1');
      expect(find.text('.NET'), findsOneWidget, reason: 'the chip names the field');

      await tester.tap(find.text('Topic…'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-choice-t-3')));
      await tester.pumpAndSettle();
      expect(cubit.state.query.topic, 't-3');
      verify(() => taxonomyRepository.getTopics('dotnet')).called(1);

      await tester.tap(find.text('.NET'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-choice-f-2')));
      await tester.pumpAndSettle();
      expect(cubit.state.query.field, 'f-2');
      expect(cubit.state.query.topic, isNull);

      await tester.tap(find.text('AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-choice-all')));
      await tester.pumpAndSettle();
      expect(cubit.state.query.field, isNull);
      await cubit.close();
    });

    testWidgets("Content: a writer from a user's page is a chip that clears; the published period is picked too", (tester) async {
      when(() => repository.articles(any(), page: 1, pageSize: 50))
          .thenAnswer((_) async => const Ok(PagedList<AdminArticleRow>(items: [])));
      AdminDatePicker.pickRange = (_, _) async => DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 7));
      final cubit = AdminArticlesCubit(GetAdminArticles(repository), AdminArticleQuery.fromUri(Uri.parse('/admin/content?writer=w-1&writerName=%40mona_dev')));
      await pump(tester, BlocProvider.value(value: cubit, child: AdminArticlesView(taxonomy: taxonomyChoices())));
      await cubit.load();
      await tester.pump();
      verify(() => repository.articles(const AdminArticleQuery(writer: 'w-1', writerLabel: '@mona_dev'), page: 1, pageSize: 50)).called(1);
      expect(find.textContaining('mona_dev'), findsOneWidget);

      await tester.tap(find.text('Published…'));
      await tester.pump();
      await tester.pump();
      expect(cubit.state.query.from, '2026-11-01');
      expect(cubit.state.query.to, '2026-11-07');
      expect(cubit.state.query.writer, 'w-1', reason: 'the other filters stay');

      final clearWriter = find.descendant(of: find.byKey(const ValueKey('admin-articles-writer')), matching: find.byTooltip('Remove filter'));
      await tester.ensureVisible(clearWriter);
      await tester.pumpAndSettle();
      await tester.tap(clearWriter);
      await tester.pump();
      expect(cubit.state.query.writer, isNull);
      await cubit.close();
    });

    testWidgets("a user's page leads to their articles with moderation.manage", (tester) async {
      final user = AdminUser(row: userRow());
      when(() => repository.user('w-9')).thenAnswer((_) async => Ok(user));
      await pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9')..load()),
            BlocProvider<ModerationActionCubit>.value(value: MockModerationActionCubit()..hold(null)),
          ],
          child: const AdminUserView(),
        ),
        size: const Size(390, 2000),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('admin-user-articles')), findsOneWidget);
      expect(AdminRoutes.contentForWriter('w-9', label: '@crypto_deals'), '/admin/content?writer=w-9&writerName=%40crypto_deals');

      await pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AdminUserCubit(GetAdminUser(repository), AdminUserCommands(repository), 'w-9')..load()),
            BlocProvider<ModerationActionCubit>.value(value: MockModerationActionCubit()..hold(null)),
          ],
          child: const AdminUserView(),
        ),
        me: adminMe(without: {Permissions.moderationManage}),
        size: const Size(390, 2000),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('admin-user-articles')), findsNothing);
    });
  });

  group('as built', () {
    Future<void> pumpProfile(WidgetTester tester, UserProfile profile, Me me) async {
      usePhoneSurface(tester, size: const Size(390, 1200));
      final actions = MockModerationActionCubit()..hold(null);
      await tester.pumpWidget(testApp(
        provided(
          [...appStores(me: me), ...profileScreen(profile), BlocProvider<ModerationActionCubit>.value(value: actions)],
          const ProfileView(),
        ),
        variant: _en,
      ));
      await tester.pump();
    }

    testWidgets("an admin on a suspended account's profile: the banner, and Unsuspend in the ⋯", (tester) async {
      final suspended = otherProfile.copyWith(admin: ProfileAdmin(isSuspended: true, suspendedUntil: DateTime.utc(2026, 12, 1)));
      await pumpProfile(tester, suspended, adminMe());

      expect(find.byKey(const ValueKey('profile-suspended-banner')), findsOneWidget);
      expect(find.textContaining('Suspended until'), findsOneWidget);

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Lift suspension'), findsOneWidget);
      expect(find.text('Suspend account'), findsNothing);
      expect(find.text('Open in console'), findsNWidgets(2), reason: 'in the banner and in the menu');
    });

    testWidgets('no banner for an active account, nor for anyone the API gives no admin state', (tester) async {
      await pumpProfile(tester, otherProfile.copyWith(admin: const ProfileAdmin()), adminMe());
      expect(find.byKey(const ValueKey('profile-suspended-banner')), findsNothing);

      await pumpProfile(tester, otherProfile, supportMemberMe);
      expect(find.byKey(const ValueKey('profile-suspended-banner')), findsNothing);
    });

    testWidgets('an archived article never published says so instead of a date', (tester) async {
      const archived = AdminArticleRow(
        id: 'a-9',
        slug: 'draft-ish',
        title: 'Never published',
        language: 'en',
        archived: true,
        field: FieldRef(id: 'f', slug: 's', nameAr: 'البرمجيات', nameEn: 'Software'),
      );
      await pump(tester, const Scaffold(body: AdminArticleTile(article: archived)));

      expect(find.textContaining('Never published'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('pages (the offset-paged console lists)', () {
    List<AdminUserRow> users(int first, int count) => [for (var i = 0; i < count; i++) userRow(id: 'u-${first + i}')];
    PagedList<AdminUserRow> usersPage(int page, int count, {int total = 120, int pages = 3}) =>
        PagedList(items: users((page - 1) * 50 + 1, count), page: page, totalCount: total, totalPages: pages);
    String text(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(ValueKey(key))).data!;
    VoidCallback? button(WidgetTester tester, String key) => tester.widget<IconButton>(find.byKey(ValueKey(key))).onPressed;

    testWidgets('Users: previous and next at the bottom, "1–50 of 120" and "Page 1 of 3"; disabled at the edges', (tester) async {
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => Ok(usersPage(1, 50)));
      when(() => repository.users(any(), page: 2, pageSize: 50)).thenAnswer((_) async => Ok(usersPage(2, 50)));
      when(() => repository.users(any(), page: 3, pageSize: 50)).thenAnswer((_) async => Ok(usersPage(3, 20)));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));
      await pump(tester, BlocProvider.value(value: cubit, child: const AdminUsersView()));
      await cubit.load();
      await tester.pumpAndSettle();

      expect(text(tester, 'admin-page-rows'), '1–50 of 120');
      expect(text(tester, 'admin-page-of'), 'Page 1 of 3');
      expect(button(tester, 'admin-page-previous'), isNull, reason: 'the first page');
      expect(button(tester, 'admin-page-next'), isNotNull);
      final pager = tester.getRect(find.byKey(const ValueKey('admin-pager')));
      expect(pager.bottom, 844, reason: 'at the bottom, under the rows');
      expect(pager.top, greaterThanOrEqualTo(tester.getRect(find.byKey(const PageStorageKey('admin-page-1'))).bottom));

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '51–100 of 120');
      expect(text(tester, 'admin-page-of'), 'Page 2 of 3');
      expect(tester.widget<AdminUserTile>(find.byType(AdminUserTile).first).user.id, 'u-51', reason: 'the rows of page 2 only');
      expect(cubit.state.items, hasLength(50));

      await tester.tap(find.byKey(const ValueKey('admin-page-next')));
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '101–120 of 120');
      expect(text(tester, 'admin-page-of'), 'Page 3 of 3');
      expect(button(tester, 'admin-page-next'), isNull, reason: 'the last page');
      expect(button(tester, 'admin-page-previous'), isNotNull);

      // No more rows load as the list scrolls: only the buttons change the page.
      await tester.drag(find.byKey(const PageStorageKey('admin-page-3')), const Offset(0, -4000));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-of'), 'Page 2 of 3');
      verify(() => repository.users(any(), page: 1, pageSize: 50)).called(1);
      verify(() => repository.users(any(), page: 2, pageSize: 50)).called(2);
      verify(() => repository.users(any(), page: 3, pageSize: 50)).called(1);
      await cubit.close();
    });

    testWidgets('a filter, a search or a sort starts again from page 1', (tester) async {
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => Ok(usersPage(1, 50)));
      when(() => repository.users(any(), page: 2, pageSize: 50)).thenAnswer((_) async => Ok(usersPage(2, 50)));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));
      await pump(tester, BlocProvider.value(value: cubit, child: const AdminUsersView()));
      await cubit.load();
      await tester.pumpAndSettle();
      Future<void> toPage2() async {
        await tester.tap(find.byKey(const ValueKey('admin-page-next')));
        await tester.pumpAndSettle();
        expect(text(tester, 'admin-page-of'), 'Page 2 of 3');
      }

      await toPage2();
      await tester.ensureVisible(find.text('Has reports'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Has reports'));
      await tester.pumpAndSettle();
      expect(cubit.state.query.hasReports, isTrue);
      expect(text(tester, 'admin-page-of'), 'Page 1 of 3');
      expect(text(tester, 'admin-page-rows'), '1–50 of 120');

      await toPage2();
      await tester.enterText(find.byType(TextField), 'crypto');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(cubit.state.query.q, 'crypto');
      expect(text(tester, 'admin-page-of'), 'Page 1 of 3');

      await toPage2();
      await tester.tap(find.byKey(const ValueKey('admin-users-sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckedPopupMenuItem<AdminUserSort>).last);
      await tester.pumpAndSettle();
      expect(cubit.state.query.sort, AdminUserSort.values.last);
      expect(text(tester, 'admin-page-of'), 'Page 1 of 3');
      verify(() => repository.users(cubit.state.query, page: 1, pageSize: 50)).called(1);
      await cubit.close();
    });

    testWidgets('big numbers are grouped, in Arabic too: "1–50 من 1,234", "الصفحة 1 من 25"', (tester) async {
      when(() => repository.users(any(), page: 1, pageSize: 50))
          .thenAnswer((_) async => Ok(usersPage(1, 50, total: 1234, pages: 25)));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));
      await pump(tester, BlocProvider.value(value: cubit, child: const AdminUsersView()));
      await cubit.load();
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '1–50 of 1,234');
      expect(text(tester, 'admin-page-of'), 'Page 1 of 25');

      await pump(tester, BlocProvider.value(value: cubit, child: const AdminUsersView()), variant: const Variant(AppLocales.ar, Brightness.light));
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '1–50 من 1,234');
      expect(text(tester, 'admin-page-of'), 'الصفحة 1 من 25');
      expect(find.byTooltip('الصفحة التالية'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('no pager for an empty list; a single page has both buttons off', (tester) async {
      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => const Ok(PagedList(items: <AdminUserRow>[])));
      final cubit = AdminUsersCubit(GetAdminUsers(repository));
      await pump(tester, BlocProvider.value(value: cubit, child: const AdminUsersView()));
      await cubit.load();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('admin-pager')), findsNothing);

      when(() => repository.users(any(), page: 1, pageSize: 50)).thenAnswer((_) async => Ok(usersPage(1, 7, total: 7, pages: 1)));
      await cubit.refresh();
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '1–7 of 7');
      expect(button(tester, 'admin-page-previous'), isNull);
      expect(button(tester, 'admin-page-next'), isNull);
      await cubit.close();
    });

    testWidgets('Content (articles and the latest comments) and the ticket queue page the same way', (tester) async {
      when(() => repository.articles(any(), page: any(named: 'page'), pageSize: 50)).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int;
        return Ok(PagedList(items: [adminArticle()], page: page, totalCount: 51, totalPages: 2));
      });
      when(() => repository.comments(any(), page: 1, pageSize: 50)).thenAnswer(
        (_) async => Ok(PagedList(
          items: [
            AdminCommentRow(id: 'c-1', body: 'Spam', article: const AdminCommentArticle(id: 'a', slug: 'a', title: 'A'), createdAt: adminNow),
          ],
          totalCount: 60,
          totalPages: 2,
        )),
      );
      await pump(
        tester,
        AdminContentPage(
          articlesCubit: AdminArticlesCubit(GetAdminArticles(repository), null),
          commentsCubit: AdminCommentsCubit(GetAdminComments(repository)),
          actions: MockModerationActionCubit()..hold(null),
          taxonomy: taxonomyChoices(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Page 1 of 2').hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('admin-page-next')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('51–51 of 51').hitTestable(), findsOneWidget);
      verify(() => repository.articles(any(), page: 2, pageSize: 50)).called(1);

      await tester.tap(find.text('Latest comments'));
      await tester.pumpAndSettle();
      expect(find.text('1–1 of 60').hitTestable(), findsOneWidget);

      registerFallbackValue(const AdminTicketQuery());
      final support = MockSupportRepository();
      when(() => support.adminTickets(any(), page: any(named: 'page'), pageSize: 50)).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int;
        return Ok(PagedList(items: [adminTicketRow(id: 't-$page')], page: page, pageSize: 1, totalCount: 2, totalPages: 2));
      });
      final tickets = AdminTicketsCubit(GetAdminTickets(support), null);
      await pump(tester, BlocProvider.value(value: tickets, child: const AdminTicketsView()));
      await tickets.load();
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '1–1 of 2');
      await tester.tap(find.byKey(const ValueKey('admin-page-next')));
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-rows'), '2–2 of 2');
      expect(text(tester, 'admin-page-of'), 'Page 2 of 2');

      // A status tab is a new query: page 1 again.
      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();
      expect(text(tester, 'admin-page-of'), 'Page 1 of 2');
      verify(() => support.adminTickets(const AdminTicketQuery(status: SupportStatus.closed), page: 1, pageSize: 50)).called(1);
      await tickets.close();
    });
  });

  group('routes', () {
    test('console routes need an account; a console ticket without support.manage opens the notification center', () {
      const settings = AppSettings(welcomeSeen: true);
      String? redirect(String path, Me? me) => resolveRedirect(
            uri: Uri.parse(path),
            session: me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me),
            settings: settings,
          );

      expect(redirect('/admin', null), AppRoutes.home);
      expect(redirect('/settings/support', null), AppRoutes.home);
      expect(redirect('/admin/tickets/t-1', supportMemberMe), AppRoutes.notifications);
      expect(redirect('/admin/tickets/t-1', adminMe()), isNull);
      expect(redirect('/admin/users/w-9', supportMemberMe), isNull, reason: 'the page itself says it is for the admin');
      expect(redirect('/settings/support/tickets/t-1', supportMemberMe), isNull);
    });
  });

  test('support categories keep their order and wire names', () {
    expect([for (final c in SupportCategory.values) c.wire], ['app_problem', 'account', 'content', 'verification', 'suggestion', 'other']);
  });
}
