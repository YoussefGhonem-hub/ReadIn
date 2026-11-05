import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/explore/domain/entities/explore.dart';
import 'package:readin/features/explore/domain/usecases/explore_usecases.dart';
import 'package:readin/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:readin/features/explore/presentation/cubit/field_cubits.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/onboarding/domain/repositories/interests_repository.dart';

import '../../helpers/explore_fixtures.dart';
import '../../helpers/social_fakes.dart';

/// Explore (F15): the sections, the rankings with their paging, and the field page's header, follows, articles and
/// writers.
void main() {
  setUpAll(() => registerFallbackValue(InterestKind.field));

  FollowsCubit follows() => FollowsCubit(SetFollowing(MockFollowRepository()));

  group('ExploreCubit', () {
    test('loads every section and seeds the writers\x27 follow state', () async {
      final repo = FakeExploreRepository(explore: sampleExplore());
      final store = follows();
      final cubit = ExploreCubit(GetExplore(repo), store);
      addTearDown(cubit.close);
      addTearDown(store.close);

      expect(cubit.state.status, ExploreStatus.loading);
      await cubit.load();
      expect(cubit.state.status, ExploreStatus.ready);
      expect(cubit.state.sections, sampleExplore());
      expect(store.state.isFollowing('w-2'), isTrue, reason: 'Omar is followed in the sample');
      expect(store.state.isFollowing('w-1', fallback: true), isFalse);
    });

    test('a failure offers retry; a failed refresh keeps the sections', () async {
      final repo = FakeExploreRepository(explore: sampleExplore())..failure = const Failure(FailureCodes.networkOffline);
      final store = follows();
      final cubit = ExploreCubit(GetExplore(repo), store);
      addTearDown(cubit.close);
      addTearDown(store.close);

      await cubit.load();
      expect(cubit.state.status, ExploreStatus.failure);
      expect(cubit.state.failure?.code, FailureCodes.networkOffline);

      repo.failure = null;
      await cubit.refresh();
      expect(cubit.state.status, ExploreStatus.ready, reason: 'refreshing a failed page loads it');

      repo.failure = const Failure(FailureCodes.networkOffline);
      await cubit.refresh();
      expect(cubit.state.status, ExploreStatus.ready);
      expect(cubit.state.sections.trending, hasLength(6));
    });

    test('an older answer never replaces a newer one', () async {
      final repo = FakeExploreRepository(explore: sampleExplore());
      final store = follows();
      final cubit = ExploreCubit(GetExplore(repo), store);
      addTearDown(cubit.close);
      addTearDown(store.close);

      final gate = Completer<void>();
      repo.gate = gate;
      final first = cubit.load();
      repo
        ..gate = null
        ..explore = const ExploreSections();
      await cubit.load();
      gate.complete();
      await first;
      expect(cubit.state.sections.isEmpty, isTrue);
    });
  });

  group('ExploreRankingCubit', () {
    test('pages a ranking with its cursor, and drops a card already shown (rankings move)', () async {
      final repo = FakeExploreRepository(rankings: {
        ExploreRanking.mostSaved: [
          exploreCards(count: 3),
          [...exploreCards(first: 3, count: 2)],
          exploreCards(first: 6, count: 1),
        ],
      });
      final cubit = ExploreRankingCubit(GetExploreRanking(repo), ExploreRanking.mostSaved);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3']);
      await cubit.loadMore();
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4'], reason: 'art-3 moved down a page');
      await cubit.loadMore();
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4', 'art-6']);
      expect(cubit.state.hasMore, isFalse);
      expect(repo.calls, ['most-saved', 'most-saved c1', 'most-saved c2']);
    });
  });

  group('FieldCubit', () {
    late MockSetInterest setInterest;

    setUp(() {
      setInterest = MockSetInterest();
      when(() => setInterest(any(), any(), followed: any(named: 'followed'))).thenAnswer((_) async => const Ok(null));
    });

    Future<FieldCubit> loaded({Me? me, FieldDetails? field}) async {
      final repo = FakeExploreRepository(fields: [field ?? dotnetDetails()]);
      final cubit = FieldCubit(GetFieldDetails(repo), setInterest, sessionOf(me ?? readerWith(6)));
      addTearDown(cubit.close);
      await cubit.load('dotnet');
      return cubit;
    }

    test('loads the header; an unknown field is "not found"', () async {
      final cubit = await loaded();
      expect(cubit.state.status, FieldStatus.ready);
      expect(cubit.state.field, dotnetDetails());

      await cubit.load('nope');
      expect(cubit.state.notFound, isTrue);
    });

    test('following the field shows at once with one more follower, then saves it', () async {
      final cubit = await loaded();
      final saving = Completer<Result<void>>();
      when(() => setInterest(InterestKind.field, 'f-dotnet', followed: true)).thenAnswer((_) => saving.future);

      final done = cubit.toggleField();
      expect(cubit.state.field!.isFollowing, isTrue);
      expect(cubit.state.field!.followerCount, 130);
      expect(cubit.state.pending, {'f-dotnet'});
      expect(await cubit.toggleField(), isNull, reason: 'a second tap while saving does nothing');
      saving.complete(const Ok(null));

      expect(await done, isNull);
      expect(cubit.state.pending, isEmpty);
      expect((cubit.state.field!.isFollowing, cubit.state.field!.followerCount), (true, 130));
      verify(() => setInterest(InterestKind.field, 'f-dotnet', followed: true)).called(1);
    });

    test('unfollowing takes one follower off; a refusal goes back and says why', () async {
      final cubit = await loaded(field: dotnetDetails(isFollowing: true, followerCount: 130));
      expect(await cubit.toggleField(), isNull);
      expect((cubit.state.field!.isFollowing, cubit.state.field!.followerCount), (false, 129));

      const offline = Failure(FailureCodes.networkOffline);
      when(() => setInterest(InterestKind.field, 'f-dotnet', followed: true)).thenAnswer((_) async => const Err(offline));
      expect(await cubit.toggleField(), offline);
      expect((cubit.state.field!.isFollowing, cubit.state.field!.followerCount), (false, 129));
      expect(cubit.state.pending, isEmpty);
    });

    test('the API refusing the last 3 interests keeps the toggle on', () async {
      const minThree = Failure(FailureCodes.interestsMinThree, statusCode: 400);
      when(() => setInterest(InterestKind.field, 'f-dotnet', followed: false)).thenAnswer((_) async => const Err(minThree));
      final cubit = await loaded(field: dotnetDetails(isFollowing: true, followerCount: 130));

      expect(await cubit.toggleField(), minThree);
      expect((cubit.state.field!.isFollowing, cubit.state.field!.followerCount), (true, 130));
    });

    test('with only 3 interests left, unfollowing is refused without asking, so the toggle never flips', () async {
      final cubit = await loaded(me: readerWith(3), field: dotnetDetails(isFollowing: true));
      final states = <FieldState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      expect((await cubit.toggleField())?.code, FailureCodes.interestsMinThree);
      final topic = cubit.state.field!.topicOf('aspnet-core')!;
      expect((await cubit.toggleTopic(topic))?.code, FailureCodes.interestsMinThree);
      await Future<void>.delayed(Duration.zero);
      expect(states, isEmpty);
      verifyNever(() => setInterest(any(), any(), followed: any(named: 'followed')));

      // Following more is always fine.
      expect(await cubit.toggleTopic(cubit.state.field!.topicOf('ef-core')!), isNull);
      expect(cubit.state.field!.topicOf('ef-core')!.isFollowing, isTrue);
    });

    test('a topic follows on its own: the field and its follower count stay', () async {
      final cubit = await loaded();
      final csharp = cubit.state.field!.topicOf('csharp')!;
      expect(await cubit.toggleTopic(csharp), isNull);
      expect(cubit.state.field!.topicOf('csharp')!.isFollowing, isTrue);
      expect((cubit.state.field!.isFollowing, cubit.state.field!.followerCount), (false, 129));
      verify(() => setInterest(InterestKind.topic, 't-csharp', followed: true)).called(1);

      expect(await cubit.toggleTopic(csharp), isNull, reason: 'the stale chip still toggles the current state');
      expect(cubit.state.field!.topicOf('csharp')!.isFollowing, isFalse);
      verify(() => setInterest(InterestKind.topic, 't-csharp', followed: false)).called(1);
    });

    test('refresh keeps the header while a follow is saving', () async {
      final cubit = await loaded();
      final saving = Completer<Result<void>>();
      when(() => setInterest(InterestKind.field, 'f-dotnet', followed: true)).thenAnswer((_) => saving.future);
      final done = cubit.toggleField();
      await cubit.refresh();
      expect(cubit.state.field!.isFollowing, isTrue);
      saving.complete(const Ok(null));
      await done;
    });
  });

  group('FieldArticlesCubit', () {
    test('the whole field, then one topic, then all again; an unknown topic is topic.not_found', () async {
      final repo = FakeExploreRepository(
        fields: [dotnetDetails()],
        articlePages: {
          'dotnet': [exploreCards(count: 2)],
          'dotnet?ef-core': [exploreCards(first: 5, count: 1)],
        },
      );
      final cubit = FieldArticlesCubit(GetFieldArticles(repo), 'dotnet');
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.topic, isNull);
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2']);

      await cubit.selectTopic('ef-core');
      expect(cubit.topic, 'ef-core');
      expect(cubit.state.items.map((a) => a.id), ['art-5']);

      await cubit.selectTopic(null);
      expect(cubit.state.items, hasLength(2));

      await cubit.selectTopic('react');
      expect(cubit.state.status, FeedStatus.failure);
      expect(isTopicNotFound(cubit.state.failure), isTrue);
      expect(isFieldNotFound(cubit.state.failure), isFalse);
      expect(repo.calls, ['articles dotnet', 'articles dotnet?ef-core', 'articles dotnet', 'articles dotnet?react']);
    });
  });

  group('FieldWritersCubit', () {
    test('loads the top writers and seeds their follow state; a failed refresh keeps them', () async {
      final repo = FakeExploreRepository(fields: [dotnetDetails()], writers: {'dotnet': exploreWriters()});
      final store = follows();
      final cubit = FieldWritersCubit(GetFieldWriters(repo), store, 'dotnet');
      addTearDown(cubit.close);
      addTearDown(store.close);

      await cubit.load();
      expect(cubit.state.status, FieldWritersStatus.ready);
      expect(cubit.state.users, exploreWriters());
      expect(store.state.isFollowing('w-2'), isTrue);

      repo.failure = const Failure(FailureCodes.networkOffline);
      await cubit.refresh();
      expect(cubit.state.users, exploreWriters());

      await cubit.load();
      expect(cubit.state.status, FieldWritersStatus.failure);
    });
  });
}
