@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
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
import 'package:readin/shared/widgets/app_network_image.dart';

import '../helpers/fake_media.dart';
import '../helpers/fixtures.dart';
import '../helpers/path_fixtures.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockFollowingFeedCubit extends MockCubit<FeedState> implements FollowingFeedCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

/// [sampleMe] as every Member is: allowed to write.
const _writer = Me(
  id: 'u-1',
  phoneNumber: '+12025550110',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate],
);

/// Home ("اليوم") in the 4 mandatory variants: ar/en × light/dark (SPEC §8.2).
void main() {
  setUpAll(FakeMedia.install);
  setUp(() {
    HomeView.clock = () => DateTime(2026, 11, 2, 9);
    CommentClock.now = () => DateTime.utc(2026, 11, 2, 12); // post cards: "3 days ago"
    AppNetworkImage.providerFactory = FakeImageProvider.new;
  });
  tearDown(() {
    HomeView.clock = DateTime.now;
    CommentClock.now = DateTime.now;
    AppNetworkImage.providerFactory = NetworkImage.new;
  });

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
    final language = en ? 'en' : 'ar-EG';
    // F03: Continue reading (the first item is the hero, so the second shows) and the learning path in progress.
    // Without them, the "explore paths" prompt.
    whenListen(home, const Stream<HomeState>.empty(),
        initialState: HomeState(
          loading: false,
          today: postCard(1, language: language, reactions: const ReactionCounts(insightful: 40, love: 6, fire: 3), reactionCount: 49, commentCount: 12),
          fields: sampleFields,
          continueReading: progressCards ? [sampleContinueReading(1), sampleContinueReading(2, percent: 64)] : const [],
          activePath: progressCards
              ? samplePath(title: en ? 'ASP.NET Core basics' : 'أساسيات ASP.NET Core', readCount: 2, enrolled: true)
              : null,
        ));
    whenListen(feed, const Stream<FeedState>.empty(),
        initialState: FeedState(
          status: FeedStatus.ready,
          // Post cards (F34): mixed text with images, a short one shown whole, then one by a writer the viewer follows.
          items: [
            attachmentsPostCard(language: language),
            shortPostCard(language: language),
            postCard(4, language: language, cover: false, isFollowingAuthor: true, isSaved: true),
          ],
          nextCursor: 'c',
        ));
    whenListen(following, const Stream<FeedState>.empty(), initialState: const FeedState());
    whenListen(suggested, const Stream<SuggestedWritersState>.empty(), initialState: const SuggestedWritersState());
    // "Add to your feed" after the third card asks for the suggestions (they're still loading here).
    when(suggested.ensureLoaded).thenAnswer((_) async {});
    // A Member, who can write: the top bar's avatar and "Start a post" (LinkedIn-style layout).
    whenListen(session, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: _writer));
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

  for (final variant in Variant.golden) {
    testWidgets('home ${variant.name}', (tester) async {
      await pumpHome(tester, variant, progressCards: true);
      await expectLater(find.byType(HomeView), matchesVariantGolden(variant, 'goldens/home_${variant.name}.png'));
    });
  }

  // Live updates (F27): "new articles" banner, unread badge and a card whose counters changed.
  for (final variant in Variant.golden) {
    testWidgets('home live ${variant.name}', (tester) async {
      final engagement = await pumpHome(tester, variant, live: const LiveFeedState(hasNewArticles: true), unread: 3);
      // What the card's live subscription hands over once it is on screen: Today's article, the card in view (F34).
      engagement.applyLive(
        sampleCard(1).id,
        const LiveArticleCounts(reactions: {ReactionType.insightful: 40, ReactionType.love: 2}, commentCount: 12),
      );
      await tester.pump(); // delivers the new state
      await tester.pump(); // draws it
      await expectLater(find.byType(HomeView), matchesVariantGolden(variant, 'goldens/home_live_${variant.name}.png'));
    });
  }
}
