import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/domain/repositories/article_repository.dart';
import 'package:readin/features/article/domain/usecases/get_related_articles.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/related_articles_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/reader_resume.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/domain/repositories/reading_repository.dart';
import 'package:readin/features/reading/domain/usecases/reading_usecases.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';
import 'package:readin/features/reading/presentation/tracking/reading_tracking.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

class MockReadingRepository extends Mock implements ReadingRepository {}

class MockArticleRepository extends Mock implements ArticleRepository {}

const _en = Variant(AppLocales.en, Brightness.light);

/// Resume (F04, docs/api/contract-v1.md "Resume (F04)"): when the reader scrolls back, and that it lands where the
/// reading tracker measures the position, without the tracker ever seeing more than that.
void main() {
  group('the rules', () {
    const progress = MyProgress(language: 'ar-EG', percent: 45, lastPosition: '0.4523');

    test('an unfinished article resumes on the version it was read in', () {
      expect(progress.resumeFractionFor('ar-EG'), 0.4523);
    });

    test('not on the other version', () => expect(progress.resumeFractionFor('en'), isNull));

    test('not once the article counts as read', () {
      final read = MyProgress(language: 'ar-EG', percent: 100, lastPosition: '0.4523', completedAt: DateTime.utc(2026, 11, 1));
      expect(read.resumeFractionFor('ar-EG'), isNull);
    });

    test('only between 0.05 and 0.95', () {
      double? at(String position) => MyProgress(language: 'en', lastPosition: position).resumeFractionFor('en');
      expect(at('0.0499'), isNull);
      expect(at('0.0500'), 0.05);
      expect(at('0.9500'), 0.95);
      expect(at('0.9501'), isNull);
      expect(at('1.0000'), isNull);
    });

    test('no position, or one that is not a number', () {
      expect(const MyProgress(language: 'en').resumeFractionFor('en'), isNull);
      expect(const MyProgress(language: 'en', lastPosition: 'top').resumeFractionFor('en'), isNull);
    });

    test('ArticleDetails resumes the version it shows; guests and unopened articles have no progress', () {
      ArticleDetails details(String language, MyProgress? progress) => ArticleDetails(
            card: sampleCard(1, language: language),
            availableLanguages: const ['ar-EG', 'en'],
            content: RDocDocument.empty,
            myProgress: progress,
          );
      expect(details('ar-EG', progress).resumeFraction, 0.4523);
      expect(details('en', progress).resumeFraction, isNull);
      expect(details('ar-EG', null).resumeFraction, isNull);
    });
  });

  group('MyProgressDto', () {
    test('parses with the article details, and is null when absent', () {
      final json = {
        ...detailsJson(1),
        'myProgress': {'language': 'ar-EG', 'percent': 45, 'lastPosition': '0.4523', 'completedAt': null},
      };
      expect(
        ArticleDetailsModel.fromJson(json).toEntity().myProgress,
        const MyProgress(language: 'ar-EG', percent: 45, lastPosition: '0.4523'),
      );
      expect(ArticleDetailsModel.fromJson(detailsJson(1)).toEntity().myProgress, isNull);

      final read = {
        ...detailsJson(1),
        'myProgress': {'language': 'en', 'percent': 100, 'lastPosition': null, 'completedAt': '2026-11-01T10:00:00Z'},
      };
      expect(ArticleDetailsModel.fromJson(read).toEntity().myProgress!.completedAt, DateTime.utc(2026, 11, 1, 10));
    });
  });

  group('ReaderResume', () {
    late ScrollController controller;
    late ValueNotifier<double> tail;
    late List<double> tracked;
    ReaderResume? resume;

    setUp(() {
      controller = ScrollController();
      tail = ValueNotifier(0);
      tracked = [];
      resume = null;
    });

    tearDown(() {
      resume?.cancel();
      controller.dispose();
      tail.dispose();
    });

    double fractionOf(ScrollMetrics m) => m.maxScrollExtent <= 0 ? 1 : m.pixels / m.maxScrollExtent;
    double current() => fractionOf(controller.position);

    const trackedKey = ValueKey('tracked');

    /// The reader's lazily built article ([RDocSliver]) with short paragraphs first and much longer ones after, so
    /// `maxScrollExtent` starts far too low; a box at the end ([tail]) stands for a section that loads later. The
    /// outer listener reads the position exactly like `ReadingTracking`.
    Future<void> pumpList(WidgetTester tester, {int blocks = 150}) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        NotificationListener<Notification>(
          onNotification: (notification) {
            final metrics = switch (notification) {
              ScrollNotification(depth: 0, :final metrics) => metrics,
              ScrollMetricsNotification(depth: 0, :final metrics) => metrics,
              _ => null,
            };
            if (metrics != null) tracked.add(fractionOf(metrics));
            return false;
          },
          child: Builder(
            key: trackedKey,
            builder: (context) => NotificationListener<Notification>(
              onNotification: (notification) => resume?.onNotification(notification) ?? false,
              child: RDocScope(
                baseDirection: TextDirection.ltr,
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    RDocSliver(unevenDocument(blocks)),
                    SliverToBoxAdapter(
                      child: ValueListenableBuilder<double>(valueListenable: tail, builder: (_, height, _) => SizedBox(height: height)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        variant: _en,
      ));
      await tester.pump();
    }

    Future<bool> start(WidgetTester tester, double fraction) async {
      final context = tester.element(find.byKey(trackedKey));
      final moved = (resume = ReaderResume(
        controller: controller,
        fraction: fraction,
        onSettled: (metrics) => ScrollMetricsNotification(metrics: metrics.copyWith(), context: context).dispatch(context),
      ))
          .start();
      await tester.pumpAndSettle();
      return moved;
    }

    testWidgets('lands where the tracker measures, though the first range was a poor estimate', (tester) async {
      await pumpList(tester);
      final estimate = controller.position.maxScrollExtent;

      expect(await start(tester, 0.4523), isTrue);

      expect(controller.position.maxScrollExtent, greaterThan(estimate * 2), reason: 'the estimate was far off');
      expect(current(), closeTo(0.4523, 0.00005));
      expect(tracked.last, closeTo(0.4523, 0.00005), reason: 'the settled position reaches the tracker');
      expect(tracked.every((f) => f <= 0.4523 + 0.00005), isTrue, reason: 'no overshoot ever counts as a higher percent');
      resume!.cancel();
    });

    testWidgets('a section that arrives later is followed until the user scrolls', (tester) async {
      await pumpList(tester);
      await start(tester, 0.6);

      tail.value = 1500;
      await tester.pumpAndSettle();
      expect(current(), closeTo(0.6, 0.00005));
      expect(tracked.last, closeTo(0.6, 0.00005));
      expect(tracked.every((f) => f <= 0.6 + 0.00005), isTrue);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(resume!.isActive, isFalse);
      final offset = controller.offset;
      tail.value = 3000;
      await tester.pumpAndSettle();
      expect(controller.offset, offset, reason: 'the user took over');
    });

    testWidgets('changes after the hold are left alone', (tester) async {
      await pumpList(tester);
      await start(tester, 0.3);
      await tester.pump(const Duration(seconds: 3));
      expect(resume!.isActive, isFalse);

      final offset = controller.offset;
      tail.value = 2000;
      await tester.pumpAndSettle();
      expect(controller.offset, offset);
    });

    testWidgets('cancelled before it settles, or nothing to scroll: it reports no move', (tester) async {
      await pumpList(tester);
      final moved = (resume = ReaderResume(controller: controller, fraction: 0.5, onSettled: (_) {})).start();
      resume!.cancel();
      await tester.pumpAndSettle();
      expect(await moved, isFalse);

      await pumpList(tester, blocks: 3);
      expect(await start(tester, 0.5), isFalse, reason: 'the article fits the screen');
    });
  });

  group('the reader', () {
    late MockReadingRepository reading;
    late MockArticleRepository articles;
    late MockSavedRepository saved;
    late EngagementCubit engagement;
    late FollowsCubit follows;
    late CollectionsCubit collections;
    late List<ReadingProgressReport> sent;
    late Future<Result<List<ArticleCard>>> Function() relatedAnswer;

    setUpAll(() => registerFallbackValue(const ReadingProgressReport(language: 'en', percent: 0, lastPosition: null, activeSecondsDelta: 0)));

    setUp(() {
      reading = MockReadingRepository();
      articles = MockArticleRepository();
      saved = MockSavedRepository();
      engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(saved));
      follows = FollowsCubit(SetFollowing(MockFollowRepository()));
      collections = CollectionsCubit(GetCollections(saved), ManageCollections(saved), engagement);
      sent = [];
      relatedAnswer = () async => const Ok([]);
      when(() => reading.reportProgress(any(), any())).thenAnswer((invocation) async {
        sent.add(invocation.positionalArguments[1] as ReadingProgressReport);
        return const Ok(ReadingProgressResult(percent: 0, completed: false, completedNow: false));
      });
      when(() => articles.getRelated(any(), language: any(named: 'language'), limit: any(named: 'limit')))
          .thenAnswer((_) => relatedAnswer());
      getIt
        ..registerFactory<ReportReadingProgress>(() => ReportReadingProgress(reading))
        ..registerFactory<RelatedArticlesCubit>(() => RelatedArticlesCubit(GetRelatedArticles(articles)));
    });

    tearDown(() async {
      getIt
        ..unregister<ReportReadingProgress>()
        ..unregister<RelatedArticlesCubit>();
      await collections.close();
      await follows.close();
      await engagement.close();
    });

    ArticleDetails article({MyProgress? progress}) => ArticleDetails(
          card: engagedCard(1, language: 'en'),
          availableLanguages: const ['en'],
          content: unevenDocument(120),
          myProgress: progress,
        );

    const leftOff = MyProgress(language: 'en', percent: 45, lastPosition: '0.4523');

    Future<void> pumpReader(WidgetTester tester, ArticleDetails details, {String? anchor}) async {
      usePhoneSurface(tester);
      final articleCubit = MockArticleCubit();
      final settings = MockSettingsCubit();
      final session = MockSessionCubit();
      final streak = MockStreakCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: details));
      whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings(articleLanguage: 'en'));
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      whenListen(streak, const Stream<Streak?>.empty(), initialState: null);
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<StreakCubit>.value(value: streak),
            BlocProvider<EngagementCubit>.value(value: engagement),
            BlocProvider<FollowsCubit>.value(value: follows),
            BlocProvider<CollectionsCubit>.value(value: collections),
            BlocProvider<ArticleCubit>.value(value: articleCubit),
            BlocProvider<ArticleLiveCubit>(create: (_) => _QuietLiveCubit()),
            BlocProvider<SettingsCubit>.value(value: settings),
          ],
          child: ReadingTracking(child: ArticleView(anchor: anchor)),
        ),
        variant: _en,
      ));
      await tester.pumpAndSettle();
    }

    ScrollPosition reader(WidgetTester tester) =>
        tester.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position;

    double fraction(WidgetTester tester) => reader(tester).pixels / reader(tester).maxScrollExtent;

    testWidgets('opens where the reader left off, says so, and the tracker reports that same position', (tester) async {
      await pumpReader(tester, article(progress: leftOff));

      expect(fraction(tester), closeTo(0.4523, 0.00005));
      expect(find.text('Picked up where you left off'), findsOneWidget);
      expect(find.text('Start over'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink()); // closes the reader: the last report goes out
      await tester.pump();
      expect(sent.first.lastPosition, '0.0000', reason: 'the report on open');
      expect((sent.last.percent, sent.last.lastPosition), (45, '0.4523'));
      expect(sent.every((r) => r.percent <= 45), isTrue);
    });

    testWidgets('"Start over" scrolls back to the top', (tester) async {
      await pumpReader(tester, article(progress: leftOff));

      await tester.tap(find.text('Start over'));
      await tester.pumpAndSettle();
      expect(reader(tester).pixels, 0);
    });

    testWidgets('related articles that load later keep the reader on the same position', (tester) async {
      final pending = Completer<Result<List<ArticleCard>>>();
      relatedAnswer = () => pending.future;
      await pumpReader(tester, article(progress: leftOff));
      expect(find.text('Related articles', skipOffstage: false), findsNothing);

      pending.complete(Ok([for (var i = 2; i < 6; i++) engagedCard(i, language: 'en')]));
      await tester.pumpAndSettle();

      expect(find.text('Related articles', skipOffstage: false), findsOneWidget, reason: 'the section added height at the end');
      expect(fraction(tester), closeTo(0.4523, 0.00005));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(sent.last.lastPosition, '0.4523');
    });

    final stays = <String, (MyProgress?, String?)>{
      'a link to a block': (leftOff, 'b-p40'),
      'a read article': (MyProgress(language: 'en', percent: 100, lastPosition: '0.4523', completedAt: DateTime.utc(2026, 11)), null),
      'progress on the other version': (const MyProgress(language: 'ar-EG', percent: 45, lastPosition: '0.4523'), null),
      'a guest (no progress)': (null, null),
      'a position near the top': (const MyProgress(language: 'en', percent: 3, lastPosition: '0.0300'), null),
    };
    for (final MapEntry(key: name, value: (progress, anchor)) in stays.entries) {
      testWidgets('stays at the top for $name', (tester) async {
        await pumpReader(tester, article(progress: progress), anchor: anchor);
        expect(reader(tester).pixels, 0);
        expect(find.text('Picked up where you left off'), findsNothing);
      });
    }
  });
}

/// [blocks] paragraphs: a dozen one-liners, then paragraphs of very different lengths, so a lazy list that guesses
/// from the first blocks starts with a range far too short.
RDocDocument unevenDocument(int blocks) => RDocDocument.fromJson({
      'version': 1,
      'language': 'en',
      'blocks': [
        for (var i = 0; i < blocks; i++)
          {
            'type': 'paragraph',
            'id': 'p$i',
            'content': [
              {'type': 'text', 'text': List.filled(i < 12 ? 1 : 1 + (i % 9) * 3, 'Scoped services live for one request.').join(' ')},
            ],
          },
      ],
    });

class _QuietLiveCubit extends Cubit<LiveArticleCounts?> implements ArticleLiveCubit {
  _QuietLiveCubit() : super(null);

  @override
  void watch(String articleId) {}

  @override
  Future<void> pause() async {}

  @override
  void resume() {}
}
