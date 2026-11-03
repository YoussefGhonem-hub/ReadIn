import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockFollowingFeedCubit extends MockCubit<FeedState> implements FollowingFeedCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

void main() {
  late MockFollowingFeedCubit following;
  late MockFollowsCubit follows;
  late StreamController<FollowChange> followChanges;

  setUp(() {
    following = MockFollowingFeedCubit();
    follows = MockFollowsCubit();
    followChanges = StreamController<FollowChange>.broadcast();
    whenListen(following, const Stream<FeedState>.empty(), initialState: const FeedState(status: FeedStatus.ready));
    when(following.ensureLoaded).thenAnswer((_) async {});
    when(() => following.load(fieldSlug: any(named: 'fieldSlug'))).thenAnswer((_) async {});
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    when(() => follows.changes).thenAnswer((_) => followChanges.stream);
  });

  tearDown(() => followChanges.close());

  Future<void> pumpHome(WidgetTester tester, {required bool signedIn}) async {
    usePhoneSurface(tester, size: const Size(390, 1200));
    final home = MockHomeCubit();
    final feed = MockFeedCubit();
    final suggested = MockSuggestedWritersCubit();
    final session = MockSessionCubit();
    final engagement = MockEngagementCubit();
    final live = MockLiveFeedCubit();
    final badge = MockUnreadBadgeCubit();
    whenListen(home, const Stream<HomeState>.empty(), initialState: const HomeState(loading: false));
    whenListen(feed, const Stream<FeedState>.empty(), initialState: FeedState(status: FeedStatus.ready, items: [sampleCard(1)]));
    whenListen(
      suggested,
      const Stream<SuggestedWritersState>.empty(),
      initialState: const SuggestedWritersState(status: SuggestedWritersStatus.ready, users: sampleWriters),
    );
    when(suggested.ensureLoaded).thenAnswer((_) async {});
    whenListen(
      session,
      const Stream<SessionState>.empty(),
      initialState: signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
    );
    whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    whenListen(live, const Stream<LiveFeedState>.empty(), initialState: const LiveFeedState());
    whenListen(badge, const Stream<int>.empty(), initialState: 0);
    final streak = MockStreakCubit(); // not loaded yet (F08)
    whenListen(streak, const Stream<Streak?>.empty(), initialState: null);

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
          BlocProvider<LiveFeedCubit>.value(value: live),
          BlocProvider<UnreadBadgeCubit>.value(value: badge),
          BlocProvider<StreakCubit>.value(value: streak),
        ],
        child: const HomeView(),
      ),
      variant: const Variant(AppLocales.en, Brightness.light),
    ));
    await tester.pump();
  }

  testWidgets('the Following tab loads the first time it is shown and suggests writers when empty', (tester) async {
    await pumpHome(tester, signedIn: true);
    verifyNever(following.ensureLoaded);

    await tester.tap(find.text('Following'));
    await tester.pump();

    verify(following.ensureLoaded).called(1);
    expect(find.text('Follow writers to fill this tab'), findsOneWidget);
    expect(find.text('Writers you might like'), findsOneWidget);
    expect(find.text('Show their articles'), findsNothing);

    followChanges.add(const FollowChange('w-1', isFollowing: true));
    await tester.pump();
    await tester.tap(find.text('Show their articles'));
    await tester.pump();
    verify(() => following.load()).called(1);
  });

  testWidgets('guests see a sign-in invitation on the Following tab', (tester) async {
    await pumpHome(tester, signedIn: false);
    await tester.tap(find.text('Following'));
    await tester.pump();

    expect(find.text('Follow the writers you like'), findsOneWidget);
    verifyNever(following.ensureLoaded);
  });

  testWidgets('feed cards carry a bookmark', (tester) async {
    await pumpHome(tester, signedIn: true);
    expect(find.byTooltip('Save'), findsOneWidget);
  });
}
