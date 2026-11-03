@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

/// Home ("النهارده") in the 4 mandatory variants: ar/en × light/dark (SPEC §8.2).
void main() {
  setUp(() => HomeView.clock = () => DateTime(2026, 11, 2, 9));
  tearDown(() => HomeView.clock = DateTime.now);

  for (final variant in Variant.all) {
    testWidgets('home ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      final home = MockHomeCubit();
      final feed = MockFeedCubit();
      final session = MockSessionCubit();
      whenListen(home, const Stream<HomeState>.empty(),
          initialState: HomeState(loading: false, today: sampleCard(1), fields: sampleFields));
      whenListen(feed, const Stream<FeedState>.empty(),
          initialState: FeedState(status: FeedStatus.ready, items: [sampleCard(2), sampleCard(3), sampleCard(4)], nextCursor: 'c'));
      whenListen(session, const Stream<SessionState>.empty(),
          initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      when(feed.loadMore).thenAnswer((_) async {});

      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<HomeCubit>.value(value: home),
            BlocProvider<FeedCubit>.value(value: feed),
          ],
          child: const HomeView(),
        ),
        variant: variant,
      ));
      await tester.pump();

      await expectLater(find.byType(HomeView), matchesGoldenFile('goldens/home_${variant.name}.png'));
    });
  }
}
