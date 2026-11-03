import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/home/domain/repositories/feed_repository.dart';
import 'package:readin/features/home/domain/usecases/feed_usecases.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';

import '../../helpers/fixtures.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository repository;

  final page1 = CursorPage(items: [sampleCard(1), sampleCard(2)], nextCursor: 'c2');
  final page2 = CursorPage(items: [sampleCard(3)]);

  setUp(() => repository = MockFeedRepository());

  FeedCubit build() => FeedCubit(GetForYouFeed(repository));

  blocTest<FeedCubit, FeedState>(
    'first page loads',
    setUp: () => when(() => repository.getForYou(fieldSlug: null, cursor: null, limit: 20)).thenAnswer((_) async => Ok(page1)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const FeedState(),
      FeedState(status: FeedStatus.ready, items: page1.items, nextCursor: 'c2'),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'loadMore appends the next page and stops at the end',
    setUp: () {
      when(() => repository.getForYou(fieldSlug: null, cursor: null, limit: 20)).thenAnswer((_) async => Ok(page1));
      when(() => repository.getForYou(fieldSlug: null, cursor: 'c2', limit: 20)).thenAnswer((_) async => Ok(page2));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore(); // no cursor left → no request
    },
    skip: 2,
    expect: () => [
      FeedState(status: FeedStatus.ready, items: page1.items, nextCursor: 'c2', loadingMore: true),
      FeedState(status: FeedStatus.ready, items: [...page1.items, ...page2.items]),
    ],
    verify: (_) => verify(() => repository.getForYou(fieldSlug: null, cursor: 'c2', limit: 20)).called(1),
  );

  blocTest<FeedCubit, FeedState>(
    'field filter resets the feed',
    setUp: () => when(() => repository.getForYou(fieldSlug: 'dotnet', cursor: null, limit: 20))
        .thenAnswer((_) async => Ok(page2)),
    build: build,
    seed: () => FeedState(status: FeedStatus.ready, items: page1.items, nextCursor: 'c2'),
    act: (cubit) => cubit.selectField('dotnet'),
    expect: () => [
      const FeedState(fieldSlug: 'dotnet'),
      FeedState(status: FeedStatus.ready, fieldSlug: 'dotnet', items: page2.items),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'first-page failure surfaces a typed failure',
    setUp: () => when(() => repository.getForYou(fieldSlug: null, cursor: null, limit: 20))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline))),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const FeedState(),
      const FeedState(status: FeedStatus.failure, failure: Failure(FailureCodes.networkOffline)),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'loadMore failure keeps items and exposes a retryable error',
    setUp: () => when(() => repository.getForYou(fieldSlug: null, cursor: 'c2', limit: 20))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.networkTimeout))),
    build: build,
    seed: () => FeedState(status: FeedStatus.ready, items: page1.items, nextCursor: 'c2'),
    act: (cubit) => cubit.loadMore(),
    expect: () => [
      FeedState(status: FeedStatus.ready, items: page1.items, nextCursor: 'c2', loadingMore: true),
      FeedState(
        status: FeedStatus.ready,
        items: page1.items,
        nextCursor: 'c2',
        loadMoreFailure: const Failure(FailureCodes.networkTimeout),
      ),
    ],
  );
}
