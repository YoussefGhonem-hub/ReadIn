import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/home/domain/repositories/feed_repository.dart';
import 'package:readin/features/home/domain/usecases/feed_usecases.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/paths/domain/repositories/paths_repository.dart';
import 'package:readin/features/paths/domain/usecases/path_usecases.dart';
import 'package:readin/features/taxonomy/domain/repositories/taxonomy_repository.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fixtures.dart';
import '../../helpers/social_fakes.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockTaxonomyRepository extends Mock implements TaxonomyRepository {}

class MockPathsRepository extends Mock implements PathsRepository {}

/// Home's header data (F03): Today's article, then the Continue reading and learning path cards (signed in only), and
/// the suggested path (F09).
void main() {
  late MockFeedRepository feed;
  late MockTaxonomyRepository taxonomy;
  late MockPathsRepository paths;
  late MockSessionCubit session;

  final today = sampleCard(1);
  final active = samplePath(readCount: 2, enrolled: true);
  final joined = samplePath(id: 'p-2', slug: 'clean-code', title: 'Clean Code', readCount: 4, completed: true);
  final open = samplePath(id: 'p-3', slug: 'flutter-basics', title: 'Flutter basics', readCount: 0);

  setUp(() {
    feed = MockFeedRepository();
    taxonomy = MockTaxonomyRepository();
    paths = MockPathsRepository();
    session = MockSessionCubit();
    when(() => feed.getToday()).thenAnswer((_) async => Ok(today));
    when(() => taxonomy.getFields(refresh: any(named: 'refresh'))).thenAnswer((_) async => const Ok(sampleFields));
    when(() => feed.getContinueReading(limit: 3)).thenAnswer((_) async => Ok([sampleContinueReading(1), sampleContinueReading(2)]));
    when(() => paths.getActivePath()).thenAnswer((_) async => Ok(active));
    // Editorial order: the path in progress, a completed one, then one not joined.
    when(() => paths.getPaths(fieldSlug: any(named: 'fieldSlug'))).thenAnswer((_) async => Ok([active, joined, open]));
  });

  void signedIn(bool value) => whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState: value ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
      );

  HomeCubit build() => HomeCubit(
        GetTodayArticle(feed),
        GetFields(taxonomy),
        GetContinueReading(feed),
        GetActivePath(paths),
        GetPaths(paths),
        session,
      );

  blocTest<HomeCubit, HomeState>(
    'signed in: the cards load with Today; Continue reading skips the hero article',
    setUp: () => signedIn(true),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const HomeState(),
      HomeState(
        loading: false,
        today: today,
        fields: sampleFields,
        continueReading: [sampleContinueReading(1), sampleContinueReading(2)],
        activePath: active,
        suggestedPath: open,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.resume!.article.id, 'art-2', reason: 'art-1 is already the hero');
      verify(() => feed.getContinueReading(limit: 3)).called(1);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'guests: no card calls, no Continue reading, the paths prompt',
    setUp: () => signedIn(false),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.resume, isNull);
      expect(cubit.state.activePath, isNull);
      verifyNever(() => feed.getContinueReading(limit: any(named: 'limit')));
      verifyNever(() => paths.getActivePath());
    },
  );

  blocTest<HomeCubit, HomeState>(
    'failures hide the cards and keep Today',
    setUp: () {
      signedIn(true);
      when(() => feed.getContinueReading(limit: 3)).thenAnswer((_) async => const Err(Failure(FailureCodes.serverError)));
      when(() => paths.getActivePath()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkTimeout)));
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.today, today);
      expect(cubit.state.continueReading, isEmpty);
      expect(cubit.state.activePath, isNull);
    },
  );

  test('only the hero left: no Continue reading card', () {
    final state = HomeState(loading: false, today: today, continueReading: [sampleContinueReading(1)]);
    expect(state.resume, isNull);
  });

  blocTest<HomeCubit, HomeState>(
    'back from the reader: only the two cards and the suggested path reload',
    setUp: () {
      signedIn(true);
      when(() => paths.getActivePath()).thenAnswer((_) async => const Ok(null));
    },
    build: build,
    seed: () => HomeState(loading: false, today: today, fields: sampleFields, continueReading: [sampleContinueReading(3)], activePath: active),
    act: (cubit) => cubit.refreshProgress(),
    expect: () => [
      HomeState(
        loading: false,
        today: today,
        fields: sampleFields,
        continueReading: [sampleContinueReading(1), sampleContinueReading(2)],
        suggestedPath: open,
      ),
    ],
    verify: (_) {
      verifyNever(() => feed.getToday());
      verifyNever(() => taxonomy.getFields(refresh: any(named: 'refresh')));
    },
  );

  group('suggested path', () {
    blocTest<HomeCubit, HomeState>(
      'the first path not joined, in editorial order (joined and completed ones are skipped)',
      setUp: () => signedIn(true),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.suggestedPath, open);
        verify(() => paths.getPaths()).called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'guests: the first published path',
      setUp: () {
        signedIn(false);
        // Guests get no enrollment on the cards.
        when(() => paths.getPaths(fieldSlug: any(named: 'fieldSlug'))).thenAnswer((_) async => Ok([samplePath(), open]));
      },
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.suggestedPath, samplePath()),
    );

    blocTest<HomeCubit, HomeState>(
      'every path joined, or the list failed: no suggestion, the rest of Home stays',
      setUp: () {
        signedIn(true);
        when(() => paths.getPaths(fieldSlug: any(named: 'fieldSlug'))).thenAnswer((_) async => Ok([active, joined]));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        expect(cubit.state.suggestedPath, isNull);
        when(() => paths.getPaths(fieldSlug: any(named: 'fieldSlug')))
            .thenAnswer((_) async => const Err(Failure(FailureCodes.networkTimeout)));
        await cubit.refreshProgress();
      },
      verify: (cubit) {
        expect(cubit.state.suggestedPath, isNull);
        expect(cubit.state.activePath, active);
        expect(cubit.state.today, today);
      },
    );
  });
}
