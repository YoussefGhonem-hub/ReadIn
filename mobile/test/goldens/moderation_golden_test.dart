@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/core/theme/tokens.g.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_action_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_case_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_list_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/report_cubit.dart';
import 'package:readin/features/moderation/presentation/pages/moderation_case_page.dart';
import 'package:readin/features/moderation/presentation/pages/moderation_page.dart';
import 'package:readin/features/moderation/presentation/widgets/moderation_widgets.dart';
import 'package:readin/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:readin/features/paths/presentation/cubit/article_path_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../helpers/comment_fixtures.dart';
import '../helpers/moderation_fakes.dart';
import '../helpers/path_fakes.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockArticleLiveCubit extends MockCubit<LiveArticleCounts?> implements ArticleLiveCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

/// Reporting & moderation (F22) in ar/en × light/dark (SPEC §8.2): the shared report sheet, the queue, a case, and a
/// hidden article in the reader as a moderator sees it (banner and "⋯").
void main() {
  setUp(() => ModerationClock.now = () => moderationNow);
  tearDown(() => ModerationClock.now = DateTime.now);

  String languageOf(Variant variant) => variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';

  Future<void> pump(WidgetTester tester, Variant variant, Widget child, {required Size size, List<BlocProvider> providers = const []}) async {
    usePhoneSurface(tester, size: size);
    final session = MockSessionCubit()..hold(SessionState(status: SessionStatus.authenticated, me: moderatorMe()));
    final engagement = MockEngagementCubit()..hold(const EngagementState());
    final follows = MockFollowsCubit()..hold(const FollowsState());
    when(() => follows.changes).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          ...providers,
        ],
        child: child,
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    testWidgets('report sheet ${variant.name}', (tester) async {
      final cubit = MockReportCubit()..hold(const ReportState(reason: ReportReason.harassment));
      await pump(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: context.colors.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(ReadInRadius.sheet))),
                child: Padding(
                  padding: const EdgeInsets.only(top: ReadInSpace.s5),
                  child: BlocProvider<ReportCubit>.value(
                    value: cubit,
                    child: const ReportSheetView(target: ModerationTargetRef.comment('c-42')),
                  ),
                ),
              ),
            ),
          ),
        ),
        size: const Size(390, 760),
      );
      await tester.enterText(find.byType(TextField), 'بيشتم الكاتب في كل تعليق وبيحط links لكورسات مدفوعة');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/moderation_report_sheet_${variant.name}.png'));
    });

    testWidgets('moderation queue ${variant.name}', (tester) async {
      final queue = MockModerationQueueCubit()
        ..hold(ModerationListState(
          status: ModerationListStatus.ready,
          items: [articleItem(), commentItem(state: ModerationTargetState.hidden), userItem(suspended: true)],
        ));
      when(queue.load).thenAnswer((_) async => null);
      final log = MockModerationLogCubit()..hold(const ModerationListState(status: ModerationListStatus.ready));
      when(log.load).thenAnswer((_) async => null);
      await pump(
        tester,
        variant,
        ModerationPage(queueCubit: (_) => queue, logCubit: () => log),
        size: const Size(390, 1180),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(ModerationPage), matchesVariantGolden(variant, 'goldens/moderation_queue_${variant.name}.png'));
    });

    testWidgets('moderation case ${variant.name}', (tester) async {
      final caseCubit = MockModerationCaseCubit()
        ..hold(ModerationCaseState(status: ModerationCaseStatus.ready, moderationCase: articleCase()));
      final actions = MockModerationActionCubit()..hold(null);
      await pump(
        tester,
        variant,
        const ModerationCaseView(type: ModerationTargetType.article),
        size: const Size(390, 1500),
        providers: [
          BlocProvider<ModerationCaseCubit>.value(value: caseCubit),
          BlocProvider<ModerationActionCubit>.value(value: actions),
        ],
      );
      await expectLater(find.byType(ModerationCaseView), matchesVariantGolden(variant, 'goldens/moderation_case_${variant.name}.png'));
    });

    testWidgets('moderation user case with title and links ${variant.name}', (tester) async {
      final caseCubit = MockModerationCaseCubit()
        ..hold(ModerationCaseState(
          status: ModerationCaseStatus.ready,
          moderationCase: ModerationCase(
            item: userItem(headline: spammerHeadline, links: spammerLinks),
            reports: [report('rp-8', reason: ReportReason.spam)],
          ),
        ));
      final actions = MockModerationActionCubit()..hold(null);
      await pump(
        tester,
        variant,
        const ModerationCaseView(type: ModerationTargetType.user),
        size: const Size(390, 1500),
        providers: [
          BlocProvider<ModerationCaseCubit>.value(value: caseCubit),
          BlocProvider<ModerationActionCubit>.value(value: actions),
        ],
      );
      await expectLater(find.byType(ModerationCaseView), matchesVariantGolden(variant, 'goldens/moderation_user_case_${variant.name}.png'));
    });

    testWidgets('hidden article ${variant.name}', (tester) async {
      final language = languageOf(variant);
      final article = ArticleDetails(
        card: engagedCard(1, language: language),
        availableLanguages: [language],
        content: RDocDocument.fromJson(detailsJson(1, language: language)['content'] as Map<String, dynamic>),
        moderation: ArticleModeration(hiddenAt: moderationNow, note: 'منقول من blog من غير ما يذكر المصدر.'),
      );
      final articleCubit = MockArticleCubit()..hold(ArticleState(status: ArticleStatus.ready, article: article));
      final live = MockArticleLiveCubit()..hold(null);
      final settings = MockSettingsCubit()..hold(const AppSettings());
      final collections = MockCollectionsCubit()..hold(const CollectionsState());
      when(() => collections.load(force: any(named: 'force'))).thenAnswer((_) async {});
      // The reader's trailing sections find nothing here: related articles (F04) and Next in path (F09); the comments
      // (F11) are loading.
      registerNoRelatedArticles();
      registerReaderComments();
      getIt.registerFactory<ArticlePathCubit>(noPathCubit);
      addTearDown(() => getIt.unregister<ArticlePathCubit>());

      await pump(
        tester,
        variant,
        const ArticleView(),
        size: const Size(390, 640),
        providers: [
          BlocProvider<ArticleCubit>.value(value: articleCubit),
          BlocProvider<ArticleLiveCubit>.value(value: live),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<CollectionsCubit>.value(value: collections),
        ],
      );
      await expectLater(find.byType(ArticleView), matchesVariantGolden(variant, 'goldens/moderation_hidden_article_${variant.name}.png'));
    });
  }
}
