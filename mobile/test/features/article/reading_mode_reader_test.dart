import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/current_locale.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/reader_action_bar.dart';
import 'package:readin/features/article/presentation/widgets/reader_widgets.dart';
import 'package:readin/features/article/presentation/widgets/reading_mode.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/paths/presentation/cubit/article_path_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/domain/repositories/settings_repository.dart';
import 'package:readin/features/settings/domain/usecases/settings_usecases.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockArticleLiveCubit extends MockCubit<LiveArticleCounts?> implements ArticleLiveCubit {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockMigrateDailyArticleSwitch extends Mock implements MigrateDailyArticleSwitch {}

/// Reading mode in the real reader (F04): its button in the top bar next to the font size, the bars that hide, the
/// progress bar and the article that stay, and the way out.
void main() {
  late _MockSettingsRepository repository;

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    repository = _MockSettingsRepository();
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
    when(() => repository.pushPreferences(any())).thenAnswer((_) async => const Ok(null));
  });

  Future<SettingsCubit> pumpReader(
    WidgetTester tester, {
    Variant variant = const Variant(AppLocales.en, Brightness.light),
    Size size = const Size(390, 844),
    List<String> languages = const ['en'],
  }) async {
    registerNoRelatedArticles();
    registerReaderComments();
    getIt.registerFactory<ArticlePathCubit>(noPathCubit);
    addTearDown(() => getIt.unregister<ArticlePathCubit>());
    usePhoneSurface(tester, size: size);

    final language = variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';
    final article = ArticleDetails(
      card: engagedCard(1, language: language),
      availableLanguages: languages.contains(language) ? languages : [language],
      content: RDocDocument.fromJson(detailsJson(1, language: language)['content'] as Map<String, dynamic>),
      isFollowingAuthor: false,
    );
    final articleCubit = MockArticleCubit();
    final live = MockArticleLiveCubit();
    final session = MockSessionCubit();
    final engagement = MockEngagementCubit();
    final follows = MockFollowsCubit();
    final collections = MockCollectionsCubit();
    whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
    whenListen(live, const Stream<LiveArticleCounts?>.empty(), initialState: null);
    whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    when(() => follows.changes).thenAnswer((_) => const Stream.empty());
    whenListen(collections, const Stream<CollectionsState>.empty(), initialState: const CollectionsState());
    when(() => collections.load(force: any(named: 'force'))).thenAnswer((_) async {});

    final migrate = _MockMigrateDailyArticleSwitch();
    when(() => migrate()).thenAnswer((_) async => true);
    final settings =
        SettingsCubit(LoadSettings(repository), SaveSettings(repository), SyncPreferences(repository), CurrentLocale(), migrate);
    addTearDown(settings.close);

    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<CollectionsCubit>.value(value: collections),
          BlocProvider<ArticleCubit>.value(value: articleCubit),
          BlocProvider<ArticleLiveCubit>.value(value: live),
          BlocProvider<SettingsCubit>.value(value: settings),
        ],
        child: const ArticleView(),
      ),
      variant: variant,
    ));
    await tester.pump();
    return settings;
  }

  testWidgets('the button next to the font size hides the top bar and the action bar; the progress and the article stay',
      (tester) async {
    final settings = await pumpReader(tester);
    final toggle = find.byKey(ReadingModeToggle.buttonKey);
    expect(toggle, findsOneWidget);
    final fontSize = find.byTooltip('Font size');
    expect((tester.getCenter(toggle).dx - tester.getCenter(fontSize).dx).abs(), lessThan(60), reason: 'side by side');
    expect(find.byType(ReaderActionBar), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.state.readingMode, isTrue);
    expect(find.byTooltip('Font size'), findsNothing, reason: 'the top bar is gone');
    expect(find.byTooltip(const DefaultMaterialLocalizations().backButtonTooltip), findsNothing);
    expect(find.byType(ReaderActionBar), findsNothing);
    expect(find.byType(ReadingProgressBar), findsOneWidget);
    expect(find.byType(ReaderBody), findsOneWidget);
    expect(find.byKey(ReadingModeExitButton.exitKey), findsOneWidget);

    await tester.tap(find.byKey(ReadingModeExitButton.exitKey));
    await tester.pumpAndSettle();
    expect(settings.state.readingMode, isFalse);
    expect(find.byTooltip('Font size'), findsOneWidget);
    expect(find.byType(ReaderActionBar), findsOneWidget);
    expect(find.byKey(ReadingModeExitButton.exitKey), findsNothing);
  });

  testWidgets('system back leaves reading mode first', (tester) async {
    final settings = await pumpReader(tester, variant: const Variant(AppLocales.ar, Brightness.dark));
    await tester.tap(find.byTooltip('وضع القراءة'));
    await tester.pumpAndSettle();
    expect(find.text('الخروج من وضع القراءة'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(settings.state.readingMode, isFalse);
    expect(find.byType(ArticleView), findsOneWidget);
    expect(find.byType(ReaderActionBar), findsOneWidget);
  });

  for (final variant in Variant.all) {
    testWidgets('the top bar still fits a 360 px phone with both languages ${variant.name}', (tester) async {
      await pumpReader(tester, variant: variant, size: const Size(360, 740), languages: const ['ar-EG', 'en']);
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
      expect(find.byKey(ReadingModeToggle.buttonKey), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      // The language toggle gives up a little size rather than push the buttons off: drawn at 95% or more.
      final drawn = tester.getRect(find.byType(SegmentedButton<String>)).width;
      final natural = tester.renderObject<RenderBox>(find.byType(SegmentedButton<String>)).size.width;
      expect(drawn / natural, greaterThan(0.95));
    });
  }

  testWidgets('on a 390 px phone the language toggle keeps its size', (tester) async {
    await pumpReader(tester, languages: const ['ar-EG', 'en']);
    final drawn = tester.getRect(find.byType(SegmentedButton<String>)).width;
    final natural = tester.renderObject<RenderBox>(find.byType(SegmentedButton<String>)).size.width;
    expect(drawn, moreOrLessEquals(natural));
  });
}
