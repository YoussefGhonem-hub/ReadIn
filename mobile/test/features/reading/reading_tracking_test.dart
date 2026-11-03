import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/domain/repositories/reading_repository.dart';
import 'package:readin/features/reading/domain/usecases/reading_usecases.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';
import 'package:readin/features/reading/presentation/tracking/reading_tracking.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/reading_fixtures.dart';
import '../../helpers/test_app.dart';

class MockReadingRepository extends Mock implements ReadingRepository {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

/// The reader hookup (F04): starts once the article is ready, follows the reader's own vertical scroll (not nested
/// horizontal ones), hands completed reads to the streak, and sends the last report when the reader closes.
void main() {
  setUpAll(() {
    registerFallbackValue(const ReadingProgressReport(language: 'en', percent: 0, lastPosition: null, activeSecondsDelta: 0));
    registerFallbackValue(sampleStreak());
  });

  late MockReadingRepository repository;
  late MockStreakCubit streak;
  late List<ReadingProgressReport> sent;
  late ReadingProgressResult answer;

  setUp(() {
    repository = MockReadingRepository();
    streak = MockStreakCubit();
    sent = [];
    answer = const ReadingProgressResult(percent: 0, completed: false, completedNow: false);
    when(() => repository.reportProgress(any(), any())).thenAnswer((invocation) async {
      sent.add(invocation.positionalArguments[1] as ReadingProgressReport);
      return Ok(answer);
    });
    when(() => streak.apply(any())).thenReturn(null);
    getIt.registerFactory<ReportReadingProgress>(() => ReportReadingProgress(repository));
  });

  tearDown(() => getIt.unregister<ReportReadingProgress>());

  Future<void> pumpReader(WidgetTester tester, {required SessionState session}) async {
    usePhoneSurface(tester);
    final sessionCubit = MockSessionCubit();
    final articleCubit = MockArticleCubit();
    whenListen(sessionCubit, const Stream<SessionState>.empty(), initialState: session);
    whenListen(streak, const Stream<Streak?>.empty(), initialState: null);
    whenListen(
      articleCubit,
      const Stream<ArticleState>.empty(),
      initialState: ArticleState(
        status: ArticleStatus.ready,
        article: ArticleDetails(
          card: sampleCard(1),
          availableLanguages: const ['ar-EG'],
          content: const RDocDocument(version: 1, language: 'ar-EG', blocks: []),
        ),
      ),
    );

    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<StreakCubit>.value(value: streak),
          BlocProvider<ArticleCubit>.value(value: articleCubit),
        ],
        child: ReadingTracking(
          child: Scaffold(
            body: ListView(
              children: [
                SizedBox(
                  height: 120,
                  child: ListView(
                    key: const ValueKey('nested'),
                    scrollDirection: Axis.horizontal,
                    children: [for (var i = 0; i < 20; i++) const SizedBox(width: 120)],
                  ),
                ),
                for (var i = 0; i < 40; i++) const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('reports on open, then the reader scroll, and once more when it closes', (tester) async {
    answer = ReadingProgressResult(percent: 100, completed: true, completedNow: true, streak: sampleStreak(current: 13));
    await pumpReader(tester, session: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    expect(sent, [const ReadingProgressReport(language: 'ar-EG', percent: 0, lastPosition: '0.0000', activeSecondsDelta: 0)]);

    // A nested horizontal list scrolls without moving the reading position.
    await tester.drag(find.byKey(const ValueKey('nested')), const Offset(-400, 0));
    await tester.pumpAndSettle();
    // The reader itself scrolls to the end.
    await tester.fling(find.byType(Scaffold), const Offset(0, -6000), 3000);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink()); // closes the reader: the last report goes out
    await tester.pump();

    expect(sent.map((r) => (r.percent, r.lastPosition)), [(0, '0.0000'), (100, '1.0000')]);
    verify(() => streak.apply(sampleStreak(current: 13))).called(2);
  });

  testWidgets('guests read without reporting', (tester) async {
    await pumpReader(tester, session: const SessionState(status: SessionStatus.guest));
    await tester.fling(find.byType(Scaffold), const Offset(0, -6000), 3000);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    verifyNever(() => repository.reportProgress(any(), any()));
  });
}
