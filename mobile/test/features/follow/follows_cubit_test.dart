import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';

import '../../helpers/social_fakes.dart';

void main() {
  late MockFollowRepository repository;
  late FollowsCubit cubit;

  setUp(() {
    repository = MockFollowRepository();
    cubit = FollowsCubit(SetFollowing(repository));
  });

  tearDown(() => cubit.close());

  test('follow applies at once, keeps the API answer and announces it', () async {
    final answer = Completer<Result<FollowState>>();
    when(() => repository.follow('u-2')).thenAnswer((_) => answer.future);
    final changes = <FollowChange>[];
    final subscription = cubit.changes.listen(changes.add);

    final done = cubit.toggle('u-2');
    expect(cubit.state.isFollowing('u-2'), isTrue);
    expect(cubit.state.isPending('u-2'), isTrue);
    expect(await cubit.toggle('u-2'), isNull, reason: 'a second tap while pending does nothing');

    answer.complete(const Ok(FollowState(isFollowing: true, followerCount: 41)));
    expect(await done, isNull);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.users['u-2'], const FollowEntry(isFollowing: true, followerCount: 41));
    expect(changes, [const FollowChange('u-2', isFollowing: true)]);
    verify(() => repository.follow('u-2')).called(1);
    await subscription.cancel();
  });

  test('a refused unfollow rolls back to what the screen loaded', () async {
    cubit.seed({'u-2': true});
    when(() => repository.unfollow('u-2')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkTimeout)));

    final failure = await cubit.toggle('u-2');

    expect(failure!.code, FailureCodes.networkTimeout);
    expect(cubit.state.isFollowing('u-2'), isTrue);
    expect(cubit.state.isPending('u-2'), isFalse);
  });

  test('a refused follow of an unknown user leaves nothing behind', () async {
    when(() => repository.follow('u-1')).thenAnswer((_) async => const Err(Failure(FailureCodes.followSelf)));
    expect((await cubit.toggle('u-1'))!.code, FailureCodes.followSelf);
    expect(cubit.state.users, isEmpty);
  });

  test('the fallback is what the screen loaded until the store knows better', () async {
    expect(cubit.state.isFollowing('u-3', fallback: true), isTrue);
    when(() => repository.unfollow('u-3')).thenAnswer((_) async => const Ok(FollowState(isFollowing: false, followerCount: 2)));
    await cubit.toggle('u-3', fallback: true);
    verify(() => repository.unfollow('u-3')).called(1);
    expect(cubit.state.isFollowing('u-3', fallback: true), isFalse);
  });

  test('seeding skips users with a request in flight; reset forgets everyone', () async {
    final answer = Completer<Result<FollowState>>();
    when(() => repository.follow('u-2')).thenAnswer((_) => answer.future);
    final done = cubit.toggle('u-2');
    cubit.seed({'u-2': false, 'u-3': true});
    expect(cubit.state.isFollowing('u-2'), isTrue);
    expect(cubit.state.isFollowing('u-3'), isTrue);
    answer.complete(const Ok(FollowState(isFollowing: true, followerCount: 1)));
    await done;

    cubit.reset();
    expect(cubit.state.users, isEmpty);
  });

  group('suggested writers', () {
    blocTest<SuggestedWritersCubit, SuggestedWritersState>(
      'loads once and seeds the follow state',
      setUp: () => when(() => repository.getSuggested(limit: 10)).thenAnswer((_) async => const Ok(sampleWriters)),
      build: () => SuggestedWritersCubit(GetSuggestedWriters(repository), cubit),
      act: (suggested) async {
        await suggested.ensureLoaded();
        await suggested.ensureLoaded();
      },
      expect: () => [
        const SuggestedWritersState(),
        const SuggestedWritersState(status: SuggestedWritersStatus.ready, users: sampleWriters),
      ],
      verify: (_) {
        verify(() => repository.getSuggested(limit: 10)).called(1);
        expect(cubit.state.isFollowing('w-2'), isTrue);
        expect(cubit.state.isFollowing('w-1'), isFalse);
      },
    );

    blocTest<SuggestedWritersCubit, SuggestedWritersState>(
      'a failure is retryable',
      setUp: () => when(() => repository.getSuggested(limit: 10)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline))),
      build: () => SuggestedWritersCubit(GetSuggestedWriters(repository), cubit),
      act: (suggested) => suggested.load(),
      expect: () => [
        const SuggestedWritersState(),
        const SuggestedWritersState(status: SuggestedWritersStatus.failure, failure: Failure(FailureCodes.networkOffline)),
      ],
    );
  });
}
