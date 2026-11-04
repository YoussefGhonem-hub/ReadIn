@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';

import '../helpers/fixtures.dart';
import '../helpers/path_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockFollowingFeedCubit extends MockCubit<FeedState> implements FollowingFeedCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

/// Home ("النهارده") in the 4 mandatory variants: ar/en × light/dark (SPEC §8.2).
void main() {
  setUp(() => HomeView.clock = () => DateTime(2026, 11, 2, 9));
  tearDown(() => HomeView.clock = DateTime.now);

  Future<EngagementCubit> pumpHome(
    WidgetTester tester,
    Variant variant, {
    LiveFeedState live = const LiveFeedState(),
    int unread = 0,
    bool progressCards = false,
  }) async {
    usePhoneSurface(tester);
    final home = MockHomeCubit();
    final feed = MockFeedCubit();
    final following = MockFollowingFeedCubit();
    final suggested = MockSuggestedWritersCubit();
    final session = MockSessionCubit();
    final follows = MockFollowsCubit();
    final en = variant.locale.languageCode == 'en';
    // F03: Continue reading (the first item is the hero, so the second shows) and the learning path in progress.
    // Without them, the "explore paths" prompt.
    whenListen(home, const Stream<HomeState>.empty(),
        initialState: HomeState(
          loading: false,
          today: sampleCard(1),
          fields: sampleFields,
          continueReading: progressCards ? [sampleContinueReading(1), sampleContinueReading(2, percent: 64)] : const [],
          activePath: progressCards
              ? samplePath(title: en ? 'ASP.NET Core basics' : 'أساسيات ASP.NET Core', readCount: 2, enrolled: true)
              : null,
        ));
    whenListen(feed, const Stream<FeedState>.empty(),
        initialState: FeedState(
          status: FeedStatus.ready,
          items: [sampleCard(2), sampleCard(3).copyWithEngagement(isSaved: true), sampleCard(4)],
          nextCursor: 'c',
        ));
    whenListen(following, const Stream<FeedState>.empty(), initialState: const FeedState());
    whenListen(suggested, const Stream<SuggestedWritersState>.empty(), initialState: const SuggestedWritersState());
    whenListen(session, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    when(() => follows.changes).thenAnswer((_) => const Stream.empty());
    when(feed.loadMore).thenAnswer((_) async {});
    final liveFeed = MockLiveFeedCubit();
    final badge = MockUnreadBadgeCubit();
    whenListen(liveFeed, const Stream<LiveFeedState>.empty(), initialState: live);
    whenListen(badge, const Stream<int>.empty(), initialState: unread);
    final streak = MockStreakCubit(); // not loaded yet: the badge looks as it did before F08
    whenListen(streak, const Stream<Streak?>.empty(), initialState: null);
    final engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(MockSavedRepository()));
    addTearDown(engagement.close);

    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<HomeCubit>.value(value: home),
          BlocProvider<FeedCubit>.value(value: feed),
          BlocProvider<FollowingFeedCubit>.value(value: following),
          BlocProvider<SuggestedWritersCubit>.value(value: suggested),
          BlocProvider<LiveFeedCubit>.value(value: liveFeed),
          BlocProvider<UnreadBadgeCubit>.value(value: badge),
          BlocProvider<StreakCubit>.value(value: streak),
        ],
        child: const HomeView(),
      ),
      variant: variant,
    ));
    await tester.pump();
    return engagement;
  }

  for (final variant in Variant.all) {
    testWidgets('home ${variant.name}', (tester) async {
      await pumpHome(tester, variant, progressCards: true);
      await expectLater(find.byType(HomeView), matchesVariantGolden(variant, 'goldens/home_${variant.name}.png'));
    });
  }

  // Live updates (F27): "new articles" banner, unread badge and a card whose counters changed.
  for (final variant in Variant.all) {
    testWidgets('home live ${variant.name}', (tester) async {
      final engagement = await pumpHome(tester, variant, live: const LiveFeedState(hasNewArticles: true), unread: 3);
      // What the card's live subscription hands over once the feed is on screen.
      engagement.applyLive(
        sampleCard(2).id,
        const LiveArticleCounts(reactions: {ReactionType.insightful: 40, ReactionType.love: 2}, commentCount: 12),
      );
      await tester.pump(); // delivers the new state
      await tester.pump(); // draws it
      await expectLater(find.byType(HomeView), matchesVariantGolden(variant, 'goldens/home_live_${variant.name}.png'));
    });
  }
}
