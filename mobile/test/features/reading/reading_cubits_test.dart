import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/domain/repositories/reading_repository.dart';
import 'package:readin/features/reading/domain/usecases/reading_usecases.dart';
import 'package:readin/features/reading/presentation/cubit/reading_heatmap_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/reading_fixtures.dart';

class MockReadingRepository extends Mock implements ReadingRepository {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

const _signedIn = SessionState(status: SessionStatus.authenticated, me: sampleMe);
const _guest = SessionState(status: SessionStatus.guest);

void main() {
  setUpAll(() => registerFallbackValue(sampleStreak()));

  late MockReadingRepository repository;
  late MockSessionCubit session;
  late StreamController<SessionState> sessions;

  setUp(() {
    repository = MockReadingRepository();
    session = MockSessionCubit();
    sessions = StreamController<SessionState>.broadcast();
  });

  tearDown(() => sessions.close());

  group('StreakCubit', () {
    StreakCubit build(SessionState initial) {
      whenListen(session, sessions.stream, initialState: initial);
      return StreakCubit(GetReadingStats(repository), session);
    }

    blocTest<StreakCubit, Streak?>(
      'loads the streak when a user signs in',
      setUp: () => when(() => repository.getStats()).thenAnswer((_) async => Ok(sampleStats())),
      build: () => build(const SessionState()),
      act: (_) async {
        sessions.add(_signedIn);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [sampleStreak()],
    );

    blocTest<StreakCubit, Streak?>(
      'clears the streak on sign out',
      setUp: () => when(() => repository.getStats()).thenAnswer((_) async => Ok(sampleStats())),
      build: () => build(_signedIn),
      act: (_) async {
        await Future<void>.delayed(Duration.zero);
        sessions.add(_guest);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [sampleStreak(), null],
    );

    blocTest<StreakCubit, Streak?>(
      'a completed read replaces the streak, and a slower load does not undo it',
      setUp: () {
        final slow = Completer<Result<ReadingStats>>();
        when(() => repository.getStats()).thenAnswer((_) => slow.future);
        addTearDown(() => slow.complete(Ok(sampleStats())));
      },
      build: () => build(_signedIn),
      act: (cubit) async {
        cubit.apply(sampleStreak(current: 13));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [sampleStreak(current: 13)],
    );

    blocTest<StreakCubit, Streak?>(
      'guests have no streak and ignore updates',
      build: () => build(_guest),
      act: (cubit) => cubit.apply(sampleStreak()),
      expect: () => <Streak?>[],
      verify: (_) => verifyNever(() => repository.getStats()),
    );

    blocTest<StreakCubit, Streak?>(
      'keeps no streak when loading fails',
      setUp: () => when(() => repository.getStats()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline))),
      build: () => build(_signedIn),
      act: (_) => Future<void>.delayed(Duration.zero),
      expect: () => <Streak?>[],
    );

    test('coming back to the app re-reads the streak only when it is stale', () async {
      when(() => repository.getStats()).thenAnswer((_) async => Ok(sampleStats()));
      final cubit = build(const SessionState());
      final loadedAt = DateTime(2026, 11, 3, 22, 0);

      sessions.add(_signedIn);
      await Future<void>.delayed(Duration.zero);
      await cubit.load(now: loadedAt);
      clearInteractions(repository);

      await cubit.refreshIfStale(now: loadedAt.add(const Duration(minutes: 5)));
      verifyNever(() => repository.getStats());

      await cubit.refreshIfStale(now: loadedAt.add(StreakCubit.staleAfter));
      verify(() => repository.getStats()).called(1);

      await cubit.refreshIfStale(now: DateTime(2026, 11, 4, 0, 1)); // after midnight, though only minutes later
      verify(() => repository.getStats()).called(1);

      await cubit.close();
    });
  });

  group('ReadingStatsCubit', () {
    late MockStreakCubit streak;

    setUp(() {
      streak = MockStreakCubit();
      when(() => streak.apply(any())).thenReturn(null);
    });

    blocTest<ReadingStatsCubit, ReadingStatsState>(
      'loads the stats and hands the fresh streak to the badge',
      setUp: () => when(() => repository.getStats()).thenAnswer((_) async => Ok(sampleStats())),
      build: () => ReadingStatsCubit(GetReadingStats(repository), streak),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReadingStatsState(),
        ReadingStatsState(status: ReadingLoadStatus.ready, stats: sampleStats()),
      ],
      verify: (_) => verify(() => streak.apply(sampleStreak())).called(1),
    );

    blocTest<ReadingStatsCubit, ReadingStatsState>(
      'surfaces a typed failure',
      setUp: () => when(() => repository.getStats()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline))),
      build: () => ReadingStatsCubit(GetReadingStats(repository), streak),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReadingStatsState(),
        const ReadingStatsState(status: ReadingLoadStatus.failure, failure: Failure(FailureCodes.networkOffline)),
      ],
      verify: (_) => verifyNever(() => streak.apply(any())),
    );
  });

  group('ReadingHeatmapCubit', () {
    blocTest<ReadingHeatmapCubit, ReadingHeatmapState>(
      'loads the last 365 days',
      setUp: () => when(() => repository.getHeatmap(days: 365)).thenAnswer((_) async => Ok(sampleHeatmap())),
      build: () => ReadingHeatmapCubit(GetReadingHeatmap(repository)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReadingHeatmapState(),
        ReadingHeatmapState(status: ReadingLoadStatus.ready, heatmap: sampleHeatmap()),
      ],
    );

    blocTest<ReadingHeatmapCubit, ReadingHeatmapState>(
      'surfaces a typed failure',
      setUp: () => when(() => repository.getHeatmap(days: 365))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.serverError, statusCode: 500))),
      build: () => ReadingHeatmapCubit(GetReadingHeatmap(repository)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReadingHeatmapState(),
        const ReadingHeatmapState(status: ReadingLoadStatus.failure, failure: Failure(FailureCodes.serverError, statusCode: 500)),
      ],
    );
  });
}
