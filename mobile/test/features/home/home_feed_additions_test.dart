import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';
import 'package:readin/features/home/presentation/widgets/home_side_column.dart';
import 'package:readin/features/home/presentation/widgets/start_post_card.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart';
import '../../helpers/path_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/reading_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockFollowingFeedCubit extends MockCubit<FeedState> implements FollowingFeedCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

class MockReadingStatsCubit extends MockCubit<ReadingStatsState> implements ReadingStatsCubit {}

/// Every Member writes (`articles.create`).
const writer = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate],
);

/// Home's LinkedIn-style additions: Start a post, "Add to your feed" after the third card of For you, the suggested
/// path, and two columns on tablets.
void main() {
  late MockHomeCubit home;
  late MockSuggestedWritersCubit suggested;
  late MockFollowsCubit follows;
  late List<String> opened;
  late GoRouter router;

  final open = samplePath(id: 'p-3', slug: 'flutter-basics', title: 'Flutter basics', readCount: 0);

  setUp(() {
    opened = [];
    home = MockHomeCubit();
    when(home.refreshProgress).thenAnswer((_) async {});
    suggested = MockSuggestedWritersCubit()
      ..hold(const SuggestedWritersState(status: SuggestedWritersStatus.ready, users: sampleWriters));
    when(suggested.ensureLoaded).thenAnswer((_) async {});
    follows = MockFollowsCubit()..hold(const FollowsState());
    when(() => follows.changes).thenAnswer((_) => const Stream.empty());
    when(() => follows.toggle(any(), fallback: any(named: 'fallback'))).thenAnswer((_) async => null);
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    Me? me = writer,
    HomeState state = const HomeState(loading: false),
    int cards = 9,
    Size size = const Size(390, 1400),
  }) async {
    usePhoneSurface(tester, size: size);
    home.hold(state);
    final feed = MockFeedCubit()
      ..hold(FeedState(status: FeedStatus.ready, items: [for (var i = 1; i <= cards; i++) sampleCard(i)]));
    when(feed.loadMore).thenAnswer((_) async {});
    final collections = MockCollectionsCubit()..hold(const CollectionsState());
    when(() => collections.load(force: any(named: 'force'))).thenAnswer((_) async {});
    final (app, appRouter) = routedTestApp(
      provided(
        [
          BlocProvider<SessionCubit>.value(
            value: MockSessionCubit()
              ..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me)),
          ),
          BlocProvider<EngagementCubit>.value(value: MockEngagementCubit()..hold(const EngagementState())),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<CollectionsCubit>.value(value: collections),
          BlocProvider<HomeCubit>.value(value: home),
          BlocProvider<FeedCubit>.value(value: feed),
          BlocProvider<FollowingFeedCubit>.value(value: MockFollowingFeedCubit()..hold(const FeedState())),
          BlocProvider<SuggestedWritersCubit>.value(value: suggested),
          BlocProvider<LiveFeedCubit>.value(value: MockLiveFeedCubit()..hold(const LiveFeedState())),
          BlocProvider<UnreadBadgeCubit>.value(value: MockUnreadBadgeCubit()..hold(0)),
          BlocProvider<StreakCubit>.value(value: MockStreakCubit()..hold(null)),
        ],
        const HomeView(),
      ),
      opened: opened,
    );
    router = appRouter;
    await tester.pumpWidget(app);
    await tester.pump();
  }

  Finder feedScroll() => find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;

  group('Start a post', () {
    testWidgets('writers: the pill and Photo / PDF / Article open the editor', (tester) async {
      await pumpHome(tester);
      expect(find.byType(StartPostCard), findsOneWidget);
      expect(find.text('Start a post…'), findsOneWidget);

      for (final key in ['start-post-pill', 'start-post-photo', 'start-post-pdf', 'start-post-article']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(opened.last, '/write/new', reason: key);
        Navigator.of(tester.element(find.text('opened /write/new'))).pop();
        await tester.pumpAndSettle();
      }
      expect(opened, hasLength(4));
    });

    testWidgets('guests and accounts that can\'t write: none', (tester) async {
      await pumpHome(tester, me: null);
      expect(find.byType(StartPostCard), findsNothing);

      await pumpHome(tester, me: sampleMe); // no articles.create
      expect(find.byType(StartPostCard), findsNothing);
    });
  });

  group('Add to your feed', () {
    testWidgets('after the third card of For you: writers with Follow, and See all opens Explore', (tester) async {
      await pumpHome(tester);
      verify(suggested.ensureLoaded).called(1);
      final carousel = find.byKey(const ValueKey('feed-suggested-writers'));
      await tester.scrollUntilVisible(carousel, 300, scrollable: feedScroll());
      expect(find.text('Add to your feed'), findsOneWidget);
      // Right after the third card, before the fourth.
      expect(tester.getTopLeft(carousel).dy, greaterThan(tester.getTopLeft(find.byKey(const ValueKey('feed-art-3'))).dy));
      expect(find.byKey(const ValueKey('feed-art-4'), skipOffstage: false), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('feed-art-4'), skipOffstage: false)).dy,
        greaterThan(tester.getTopLeft(carousel).dy),
      );

      // Mona isn't followed yet: Follow applies at once through the app's follow store.
      final follow = find.descendant(of: find.byKey(const ValueKey('feed-writer-w-1')), matching: find.text('Follow'));
      await tester.ensureVisible(follow);
      await tester.pumpAndSettle();
      await tester.tap(follow);
      await tester.pump();
      verify(() => follows.toggle('w-1', fallback: false)).called(1);

      await tester.ensureVisible(find.byKey(const ValueKey('feed-suggested-writers-see-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feed-suggested-writers-see-all')));
      await tester.pumpAndSettle();
      expect(opened, ['/explore']);
    });

    testWidgets('guests: none, and nothing loads', (tester) async {
      await pumpHome(tester, me: null);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('feed-art-5')), 300, scrollable: feedScroll());
      expect(find.byKey(const ValueKey('feed-suggested-writers')), findsNothing);
      verifyNever(suggested.ensureLoaded);
    });

    testWidgets('no suggestions: nothing between the cards', (tester) async {
      suggested.hold(const SuggestedWritersState(status: SuggestedWritersStatus.ready));
      await pumpHome(tester);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('feed-art-5')), 300, scrollable: feedScroll());
      expect(find.text('Add to your feed'), findsNothing);
    });
  });

  group('suggested path', () {
    testWidgets('no path in progress: it takes the paths prompt\'s place; Start path opens it', (tester) async {
      await pumpHome(tester, state: HomeState(loading: false, today: sampleCard(20), suggestedPath: open));
      expect(find.text('Suggested path'), findsOneWidget);
      expect(find.text('Learn step by step with learning paths'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('suggested-path-start')));
      await tester.pumpAndSettle();
      expect(opened, ['/paths/flutter-basics']);

      // Back on Home (joining changes the suggestion), the cards refresh.
      router.pop();
      await tester.pumpAndSettle();
      verify(home.refreshProgress).called(1);
    });

    testWidgets('with a path in progress: after the eighth card of For you', (tester) async {
      await pumpHome(
        tester,
        state: HomeState(loading: false, activePath: samplePath(readCount: 2, enrolled: true), suggestedPath: open),
      );
      expect(find.text('2/4'), findsOneWidget, reason: 'the path in progress keeps its place');
      final card = find.byKey(const ValueKey('feed-suggested-path'));
      await tester.scrollUntilVisible(card, 300, scrollable: feedScroll());
      expect(tester.getTopLeft(card).dy, greaterThan(tester.getTopLeft(find.byKey(const ValueKey('feed-art-8'))).dy));

      final seeAll = find.descendant(of: card, matching: find.text('See all'));
      await tester.ensureVisible(seeAll);
      await tester.pumpAndSettle();
      await tester.tap(seeAll);
      await tester.pumpAndSettle();
      expect(opened, ['/paths']);
    });
  });

  testWidgets('tablets: two columns, with the profile card, this week\'s reading and suggestions beside the feed',
      (tester) async {
    final stats = MockReadingStatsCubit()..hold(ReadingStatsState(status: ReadingLoadStatus.ready, stats: sampleStats()));
    when(() => stats.load(username: any(named: 'username'))).thenAnswer((_) async {});
    getIt.registerFactory<ReadingStatsCubit>(() => stats);
    addTearDown(() => getIt.unregister<ReadingStatsCubit>());

    await pumpHome(tester, size: const Size(1024, 1366));
    final side = find.byType(HomeSideColumn);
    expect(side, findsOneWidget);
    expect(find.descendant(of: side, matching: find.text('View profile')), findsOneWidget);
    expect(find.descendant(of: side, matching: find.text('Articles this week')), findsOneWidget);
    expect(find.descendant(of: side, matching: find.text('Writers you might like')), findsOneWidget);
    // The suggestions live in the side column: none in the feed.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('feed-art-5')), 300, scrollable: feedScroll());
    expect(find.byKey(const ValueKey('feed-suggested-writers')), findsNothing);

    await tester.tap(find.descendant(of: side, matching: find.text('View profile')));
    await tester.pumpAndSettle();
    expect(opened, ['/u/reader1']);
  });

  testWidgets('phones: one column', (tester) async {
    await pumpHome(tester);
    expect(find.byType(HomeSideColumn), findsNothing);
  });
}
