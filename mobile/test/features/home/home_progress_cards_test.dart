import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart';
import '../../helpers/path_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockFollowingFeedCubit extends MockCubit<FeedState> implements FollowingFeedCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

/// Home's Continue reading and learning path cards (F03, F09).
void main() {
  late MockHomeCubit home;
  late List<String> opened;

  setUp(() {
    home = MockHomeCubit();
    opened = [];
    when(home.refreshProgress).thenAnswer((_) async {});
  });

  Future<GoRouterPop> pumpHome(WidgetTester tester, HomeState state, {Me? me = sampleMe}) async {
    usePhoneSurface(tester, size: const Size(390, 1400));
    home.hold(state);
    final feed = MockFeedCubit()..hold(FeedState(status: FeedStatus.ready, items: [sampleCard(3)]));
    when(feed.loadMore).thenAnswer((_) async {});
    final (app, router) = routedTestApp(
      provided(
        [
          ...appStores(me: me),
          BlocProvider<HomeCubit>.value(value: home),
          BlocProvider<FeedCubit>.value(value: feed),
          BlocProvider<FollowingFeedCubit>.value(value: MockFollowingFeedCubit()..hold(const FeedState())),
          BlocProvider<SuggestedWritersCubit>.value(value: MockSuggestedWritersCubit()..hold(const SuggestedWritersState())),
          BlocProvider<LiveFeedCubit>.value(value: MockLiveFeedCubit()..hold(const LiveFeedState())),
          BlocProvider<UnreadBadgeCubit>.value(value: MockUnreadBadgeCubit()..hold(0)),
          BlocProvider<StreakCubit>.value(value: MockStreakCubit()..hold(null)),
        ],
        const HomeView(),
      ),
      opened: opened,
    );
    await tester.pumpWidget(app);
    await tester.pump();
    return () => router.pop();
  }

  final today = sampleCard(1);

  testWidgets('Continue reading skips the hero article and opens the version being read', (tester) async {
    final pop = await pumpHome(
      tester,
      HomeState(
        loading: false,
        today: today,
        continueReading: [sampleContinueReading(1), sampleContinueReading(2, percent: 64, language: 'en')],
        activePath: samplePath(readCount: 2, enrolled: true),
      ),
    );

    expect(find.text('Continue reading'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);

    await tester.tap(find.text('Continue reading'));
    await tester.pumpAndSettle();
    expect(opened, ['/a/article-2?lang=en']);

    // Back on Home, the two cards refresh.
    pop();
    await tester.pumpAndSettle();
    verify(home.refreshProgress).called(1);
  });

  testWidgets('no Continue reading card when the only one is the hero', (tester) async {
    await pumpHome(tester, HomeState(loading: false, today: today, continueReading: [sampleContinueReading(1)]));
    expect(find.text('Continue reading'), findsNothing);
  });

  testWidgets('the path in progress: "{readCount}/{total}", the next article, and the path page', (tester) async {
    final pop = await pumpHome(tester, HomeState(loading: false, today: today, activePath: samplePath(readCount: 2, enrolled: true)));

    expect(find.text('2/4'), findsOneWidget);
    expect(find.textContaining('Next: '), findsOneWidget);
    expect(find.text('Learn step by step with learning paths'), findsNothing);

    await tester.tap(find.textContaining('Next: '));
    await tester.pumpAndSettle();
    expect(opened.last, '/a/article-3');
    pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('2/4'));
    await tester.pumpAndSettle();
    expect(opened.last, '/paths/aspnet-core-basics');
  });

  testWidgets('no path in progress (204) or a guest: the slim prompt to /paths', (tester) async {
    await pumpHome(tester, HomeState(loading: false, today: today), me: null);

    expect(find.text('Continue reading'), findsNothing);
    await tester.tap(find.text('Learn step by step with learning paths'));
    await tester.pumpAndSettle();
    expect(opened, ['/paths']);
  });

  testWidgets('nothing while Home loads', (tester) async {
    await pumpHome(tester, const HomeState());
    expect(find.text('Learn step by step with learning paths'), findsNothing);
  });
}

typedef GoRouterPop = void Function();
