import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/social_session_bridge.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/home/domain/repositories/feed_repository.dart';
import 'package:readin/features/home/domain/usecases/feed_usecases.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reactions/presentation/cubit/reactors_cubit.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';

import '../helpers/fixtures.dart';
import '../helpers/social_fakes.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  group('who reacted (F10)', () {
    late MockReactionsRepository repository;

    setUp(() => repository = MockReactionsRepository());

    blocTest<ReactorsCubit, ReactorsState>(
      'one type, paged; the end has no more pages',
      setUp: () {
        when(() => repository.getReactors('a-1', type: ReactionType.love, cursor: null, limit: 20))
            .thenAnswer((_) async => Ok(CursorPage(items: sampleReactors.take(2).toList(), nextCursor: 'c2')));
        when(() => repository.getReactors('a-1', type: ReactionType.love, cursor: 'c2', limit: 20))
            .thenAnswer((_) async => Ok(CursorPage(items: sampleReactors.skip(2).toList())));
      },
      build: () => ReactorsCubit(GetReactors(repository)),
      act: (cubit) async {
        await cubit.load('a-1', type: ReactionType.love);
        await cubit.loadMore();
        await cubit.loadMore();
      },
      expect: () => [
        const ReactorsState(),
        ReactorsState(status: ReactorsStatus.ready, items: sampleReactors.take(2).toList(), nextCursor: 'c2'),
        ReactorsState(status: ReactorsStatus.ready, items: sampleReactors.take(2).toList(), nextCursor: 'c2', loadingMore: true),
        ReactorsState(status: ReactorsStatus.ready, items: sampleReactors),
      ],
    );

    blocTest<ReactorsCubit, ReactorsState>(
      'a failure, then a retry',
      setUp: () {
        var calls = 0;
        when(() => repository.getReactors('a-1', type: null, cursor: null, limit: 20)).thenAnswer(
          (_) async => calls++ == 0 ? const Err(Failure(FailureCodes.networkOffline)) : Ok(CursorPage(items: sampleReactors)),
        );
      },
      build: () => ReactorsCubit(GetReactors(repository)),
      act: (cubit) async {
        await cubit.load('a-1');
        await cubit.retry();
      },
      expect: () => [
        const ReactorsState(),
        const ReactorsState(status: ReactorsStatus.failure, failure: Failure(FailureCodes.networkOffline)),
        const ReactorsState(),
        ReactorsState(status: ReactorsStatus.ready, items: sampleReactors),
      ],
    );

    test('a slow answer to an older load never replaces the newer list, nor gets its page appended', () async {
      final slowFirst = Completer<Result<CursorPage<Reactor>>>();
      final slowPage = Completer<Result<CursorPage<Reactor>>>();
      var firstLoads = 0;
      when(() => repository.getReactors('a-1', type: null, cursor: null, limit: 20)).thenAnswer((_) {
        if (firstLoads++ == 0) return slowFirst.future;
        return Future.value(Ok(CursorPage(items: sampleReactors.take(1).toList(), nextCursor: 'c2')));
      });
      when(() => repository.getReactors('a-1', type: null, cursor: 'c2', limit: 20)).thenAnswer((_) => slowPage.future);
      final cubit = ReactorsCubit(GetReactors(repository));
      addTearDown(cubit.close);

      final first = cubit.load('a-1');
      await cubit.retry(); // the newer load answers first
      final fresh = ReactorsState(status: ReactorsStatus.ready, items: sampleReactors.take(1).toList(), nextCursor: 'c2');
      expect(cubit.state, fresh);
      slowFirst.complete(Ok(CursorPage(items: sampleReactors)));
      await first;
      expect(cubit.state, fresh);

      // A page asked for, then a reload: the old page is dropped.
      final more = cubit.loadMore();
      await cubit.retry();
      slowPage.complete(Ok(CursorPage(items: sampleReactors.skip(1).toList())));
      await more;
      expect(cubit.state, fresh);
    });
  });

  group('Following feed (F03, F12)', () {
    test('loads once when the tab is first shown, then pages like For you', () async {
      final repository = MockFeedRepository();
      when(() => repository.getFollowing(cursor: null, limit: 20)).thenAnswer((_) async => Ok(CursorPage(items: [sampleCard(1)], nextCursor: 'n')));
      when(() => repository.getFollowing(cursor: 'n', limit: 20)).thenAnswer((_) async => Ok(CursorPage(items: [sampleCard(2)])));
      final cubit = FollowingFeedCubit(GetFollowingFeed(repository));

      await cubit.ensureLoaded();
      await cubit.ensureLoaded();
      await cubit.loadMore();

      expect(cubit.state.items, [sampleCard(1), sampleCard(2)]);
      verify(() => repository.getFollowing(cursor: null, limit: 20)).called(1);
      verifyNever(() => repository.getForYou(fieldSlug: any(named: 'fieldSlug'), cursor: any(named: 'cursor'), limit: any(named: 'limit')));
      await cubit.close();
    });
  });

  group('reader live counters (F27)', () {
    late MockRealtimeService realtime;
    late StreamController<LiveArticleCounts> live;
    var listens = 0;

    setUp(() {
      realtime = MockRealtimeService();
      listens = 0;
      live = StreamController<LiveArticleCounts>.broadcast(onListen: () => listens++);
      when(() => realtime.watchArticle('a-1')).thenAnswer((_) => live.stream);
    });

    test('values arrive while open; paused in the background; cancelled in close()', () async {
      final cubit = ArticleLiveCubit(realtime)..watch('a-1');
      live.add(const LiveArticleCounts(commentCount: 3));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, const LiveArticleCounts(commentCount: 3));

      await cubit.pause();
      expect(live.hasListener, isFalse);
      cubit.watch('a-1'); // a language switch while paused: still paused
      expect(live.hasListener, isFalse);

      cubit.resume();
      expect(live.hasListener, isTrue);
      expect(listens, 2);

      await cubit.close();
      expect(live.hasListener, isFalse);
    });

    test('watching the same article twice keeps one listener', () async {
      final cubit = ArticleLiveCubit(realtime)
        ..watch('a-1')
        ..watch('a-1');
      expect(listens, 1);
      await cubit.close();
    });
  });

  group('the session owns the viewer data (F10, F12, F13, F25)', () {
    late StreamController<SessionState> sessions;
    late MockSessionCubit session;
    late FakeArticleOfflineStore offline;
    late MockSavedRepository saved;
    late EngagementCubit engagement;
    late FollowsCubit follows;
    late CollectionsCubit collections;
    late SocialSessionBridge bridge;

    setUp(() {
      sessions = StreamController<SessionState>.broadcast();
      session = MockSessionCubit();
      when(() => session.state).thenReturn(const SessionState());
      when(() => session.stream).thenAnswer((_) => sessions.stream);
      offline = FakeArticleOfflineStore();
      saved = MockSavedRepository();
      engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(saved));
      follows = FollowsCubit(SetFollowing(MockFollowRepository()));
      collections = CollectionsCubit(GetCollections(saved), ManageCollections(saved), engagement);
      bridge = SocialSessionBridge(session, engagement, follows, collections, offline)..start();
    });

    tearDown(() async {
      await bridge.dispose();
      await sessions.close();
    });

    Future<void> emit(SessionState state) async {
      sessions.add(state);
      await Future<void>.delayed(Duration.zero);
      await bridge.lastClaim;
    }

    test('the first known user claims the device copies; the same user keeps everything', () async {
      await emit(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      expect(offline.owner, 'u-1');
      follows.seed({'w-1': true});
      await offline.put(detailsModel(1, isSaved: true));

      await emit(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      expect(follows.state.users, isNotEmpty);
      expect(await offline.contains('art-1'), isTrue);
    });

    test('restored offline (account unknown) keeps the copies for offline reading', () async {
      await emit(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      await offline.put(detailsModel(1, isSaved: true));
      await emit(const SessionState(status: SessionStatus.authenticated, failure: Failure(FailureCodes.networkOffline)));
      expect(await offline.contains('art-1'), isTrue);
      expect(offline.claims, 1);
    });

    test('signing out forgets the viewer state and the device copies', () async {
      await emit(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      await offline.put(detailsModel(1, isSaved: true));
      follows.seed({'w-1': true});
      engagement.applyLive('art-1', const LiveArticleCounts(commentCount: 1));
      collections.seedMembership([SavedArticle(savedAt: DateTime.utc(2026), article: sampleCard(1))]);

      await emit(const SessionState(status: SessionStatus.guest));

      expect(await offline.contains('art-1'), isFalse);
      expect(follows.state.users, isEmpty);
      expect(engagement.state.overlays, isEmpty);
      expect(collections.state.membership, isEmpty);
    });
  });
}
