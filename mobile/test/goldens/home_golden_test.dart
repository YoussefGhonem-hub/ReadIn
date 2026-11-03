@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

/// Home ("النهارده") in the 4 mandatory variants: ar/en × light/dark (SPEC §8.2).
void main() {
  setUp(() => HomeView.clock = () => DateTime(2026, 11, 2, 9));
  tearDown(() => HomeView.clock = DateTime.now);

  Future<void> pumpHome(WidgetTester tester, Variant variant, {LiveFeedState live = const LiveFeedState(), int unread = 0}) async {
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
    final liveFeed = MockLiveFeedCubit();
    final badge = MockUnreadBadgeCubit();
    whenListen(liveFeed, const Stream<LiveFeedState>.empty(), initialState: live);
    whenListen(badge, const Stream<int>.empty(), initialState: unread);

    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<HomeCubit>.value(value: home),
          BlocProvider<FeedCubit>.value(value: feed),
          BlocProvider<LiveFeedCubit>.value(value: liveFeed),
          BlocProvider<UnreadBadgeCubit>.value(value: badge),
        ],
        child: const HomeView(),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.all) {
    testWidgets('home ${variant.name}', (tester) async {
      await pumpHome(tester, variant);
      await expectLater(find.byType(HomeView), matchesGoldenFile('goldens/home_${variant.name}.png'));
    });
  }

  // Live updates (F27): "new articles" banner, unread badge and a card whose counters changed.
  for (final variant in Variant.all) {
    testWidgets('home live ${variant.name}', (tester) async {
      await pumpHome(
        tester,
        variant,
        live: LiveFeedState(
          hasNewArticles: true,
          counts: {sampleCard(2).id: const LiveArticleCounts(reactions: {ReactionType.insightful: 40, ReactionType.love: 2}, commentCount: 12)},
        ),
        unread: 3,
      );
      await expectLater(find.byType(HomeView), matchesGoldenFile('goldens/home_live_${variant.name}.png'));
    });
  }
}
