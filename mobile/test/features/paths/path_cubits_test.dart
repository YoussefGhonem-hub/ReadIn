import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/paths/domain/entities/learning_path.dart';
import 'package:readin/features/paths/domain/repositories/paths_repository.dart';
import 'package:readin/features/paths/domain/usecases/path_usecases.dart';
import 'package:readin/features/paths/presentation/cubit/article_path_cubit.dart';
import 'package:readin/features/paths/presentation/cubit/path_details_cubit.dart';
import 'package:readin/features/paths/presentation/cubit/path_list_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fixtures.dart';

class MockPathsRepository extends Mock implements PathsRepository {}

void main() {
  late MockPathsRepository repository;

  setUp(() => repository = MockPathsRepository());

  const offline = Failure(FailureCodes.networkOffline);

  group('PathListCubit', () {
    final paths = samplePaths();

    AllPathsCubit all() => AllPathsCubit(GetPaths(repository));

    blocTest<AllPathsCubit, PathListState>(
      'loads the list; the chips are the fields in it, in order',
      setUp: () => when(() => repository.getPaths()).thenAnswer((_) async => Ok(paths)),
      build: all,
      act: (cubit) => cubit.load(),
      expect: () => [const PathListState(), PathListState(status: PathListStatus.ready, items: paths)],
      verify: (cubit) {
        expect(cubit.state.fields, [dotnetField, aiField]);
        expect(cubit.state.visible, paths);
      },
    );

    blocTest<AllPathsCubit, PathListState>(
      'a field chip filters locally',
      build: all,
      seed: () => PathListState(status: PathListStatus.ready, items: paths),
      act: (cubit) => cubit.selectField('dotnet'),
      expect: () => [PathListState(status: PathListStatus.ready, items: paths, fieldSlug: 'dotnet')],
      verify: (cubit) => expect(cubit.state.visible.map((p) => p.id), ['p-1', 'p-3']),
    );

    blocTest<AllPathsCubit, PathListState>(
      'a failed refresh keeps the list; a successful one drops a chip whose field left',
      setUp: () {
        var calls = 0;
        when(() => repository.getPaths()).thenAnswer((_) async => ++calls == 1 ? const Err(offline) : Ok([paths[1]]));
      },
      build: all,
      seed: () => PathListState(status: PathListStatus.ready, items: paths, fieldSlug: 'dotnet'),
      act: (cubit) async {
        await cubit.refresh();
        await cubit.refresh();
      },
      expect: () => [PathListState(status: PathListStatus.ready, items: [paths[1]])],
    );

    blocTest<AllPathsCubit, PathListState>(
      'a failed first load is a failure state',
      setUp: () => when(() => repository.getPaths()).thenAnswer((_) async => const Err(offline)),
      build: all,
      act: (cubit) => cubit.load(),
      expect: () => [const PathListState(), const PathListState(status: PathListStatus.failure, failure: offline)],
    );

    test('My paths loads once, the first time its tab is shown', () async {
      when(() => repository.getMyPaths()).thenAnswer((_) async => Ok([paths.first]));
      final cubit = MyPathsCubit(GetMyPaths(repository));
      addTearDown(cubit.close);

      await cubit.ensureLoaded();
      await cubit.ensureLoaded();

      verify(() => repository.getMyPaths()).called(1);
      expect(cubit.state.items, [paths.first]);
    });

    test("a profile's paths come from /users/{username}/paths", () async {
      when(() => repository.getUserPaths('mona_dev')).thenAnswer((_) async => const Err(Failure(FailureCodes.profileStatsPrivate, statusCode: 403)));
      final cubit = UserPathsCubit(GetUserPaths(repository), 'mona_dev');
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, PathListStatus.failure);
      expect(cubit.state.failure!.code, FailureCodes.profileStatsPrivate);
    });
  });

  group('PathDetailsCubit', () {
    PathDetailsCubit build() => PathDetailsCubit(GetPath(repository), SetPathEnrollment(repository));

    final guest = samplePathDetails();
    final notEnrolled = samplePathDetails(readCount: 1);
    final enrolledPath = samplePath(readCount: 1, enrolled: true);

    blocTest<PathDetailsCubit, PathDetailsState>(
      'loads the path',
      setUp: () => when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => Ok(guest)),
      build: build,
      act: (cubit) => cubit.load('aspnet-core-basics'),
      expect: () => [const PathDetailsState(), PathDetailsState(status: PathDetailsStatus.ready, details: guest)],
    );

    blocTest<PathDetailsCubit, PathDetailsState>(
      '404 path.not_found is the not-found state',
      setUp: () => when(() => repository.getPath('gone'))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.pathNotFound, statusCode: 404))),
      build: build,
      act: (cubit) => cubit.load('gone'),
      verify: (cubit) => expect(cubit.state.notFound, isTrue),
    );

    blocTest<PathDetailsCubit, PathDetailsState>(
      'enrolling shows the enrollment and returns the card with the next article',
      setUp: () => when(() => repository.enroll('p-1')).thenAnswer((_) async => Ok(enrolledPath)),
      build: build,
      seed: () => PathDetailsState(status: PathDetailsStatus.ready, details: notEnrolled),
      act: (cubit) async {
        final result = await cubit.enroll();
        expect(result.valueOrNull!.progress!.next!.slug, 'article-2');
      },
      expect: () => [
        PathDetailsState(status: PathDetailsStatus.ready, details: notEnrolled, busy: true),
        PathDetailsState(status: PathDetailsStatus.ready, details: notEnrolled.withPath(enrolledPath)),
      ],
    );

    blocTest<PathDetailsCubit, PathDetailsState>(
      'a failed enroll changes nothing and hands the failure back',
      setUp: () => when(() => repository.enroll('p-1')).thenAnswer((_) async => const Err(offline)),
      build: build,
      seed: () => PathDetailsState(status: PathDetailsStatus.ready, details: notEnrolled),
      act: (cubit) async => expect((await cubit.enroll()).failureOrNull, offline),
      expect: () => [
        PathDetailsState(status: PathDetailsStatus.ready, details: notEnrolled, busy: true),
        PathDetailsState(status: PathDetailsStatus.ready, details: notEnrolled),
      ],
    );

    blocTest<PathDetailsCubit, PathDetailsState>(
      'leaving drops the enrollment and keeps the progress',
      setUp: () => when(() => repository.leave('p-1')).thenAnswer((_) async => const Ok(null)),
      build: build,
      seed: () => PathDetailsState(status: PathDetailsStatus.ready, details: samplePathDetails(readCount: 1, enrolled: true)),
      act: (cubit) async => expect(await cubit.leave(), isNull),
      skip: 1,
      verify: (cubit) {
        final path = cubit.state.details!.path;
        expect(path.isEnrolled, isFalse);
        expect(path.progress!.readCount, 1);
        expect(cubit.state.busy, isFalse);
      },
    );

    blocTest<PathDetailsCubit, PathDetailsState>(
      'a failed refresh keeps the page',
      setUp: () {
        var calls = 0;
        when(() => repository.getPath('aspnet-core-basics')).thenAnswer((_) async => ++calls == 1 ? Ok(guest) : const Err(offline));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('aspnet-core-basics');
        await cubit.refresh();
      },
      expect: () => [const PathDetailsState(), PathDetailsState(status: PathDetailsStatus.ready, details: guest)],
    );
  });

  group('ArticlePathCubit', () {
    ArticlePathCubit build() => ArticlePathCubit(GetArticlePath(repository), SetPathEnrollment(repository));

    final guestBlock = sampleArticlePath();

    blocTest<ArticlePathCubit, ArticlePathState>(
      'in a path: ready',
      setUp: () => when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => Ok(guestBlock)),
      build: build,
      act: (cubit) => cubit.load('art-2'),
      expect: () => [ArticlePathState(status: ArticlePathStatus.ready, articlePath: guestBlock)],
    );

    blocTest<ArticlePathCubit, ArticlePathState>(
      '204 and failures render nothing',
      setUp: () {
        when(() => repository.getArticlePath('art-8')).thenAnswer((_) async => const Ok(null));
        when(() => repository.getArticlePath('art-9')).thenAnswer((_) async => const Err(offline));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-8');
        await cubit.load('art-9');
      },
      expect: () => [const ArticlePathState(status: ArticlePathStatus.none)],
    );

    final joined = sampleArticlePath(readCount: 1, enrolled: true);

    blocTest<ArticlePathCubit, ArticlePathState>(
      'Join path enrolls, then reloads the block',
      setUp: () {
        var calls = 0;
        when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => Ok(++calls == 1 ? guestBlock : joined));
        when(() => repository.enroll('p-1')).thenAnswer((_) async => Ok(joined.path));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-2');
        expect(await cubit.join(), isNull);
      },
      skip: 1,
      expect: () => [
        ArticlePathState(status: ArticlePathStatus.ready, articlePath: guestBlock, joining: true),
        ArticlePathState(status: ArticlePathStatus.ready, articlePath: joined),
      ],
      verify: (_) => verify(() => repository.getArticlePath('art-2')).called(2),
    );

    blocTest<ArticlePathCubit, ArticlePathState>(
      'a failed reload after joining still shows the enrollment',
      setUp: () {
        var calls = 0;
        when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => ++calls == 1 ? Ok(guestBlock) : const Err(offline));
        when(() => repository.enroll('p-1')).thenAnswer((_) async => Ok(joined.path));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-2');
        await cubit.join();
      },
      verify: (cubit) => expect(cubit.state.articlePath!.path.isEnrolled, isTrue),
    );

    blocTest<ArticlePathCubit, ArticlePathState>(
      'a failed join hands the failure back',
      setUp: () {
        when(() => repository.getArticlePath('art-2')).thenAnswer((_) async => Ok(guestBlock));
        when(() => repository.enroll('p-1')).thenAnswer((_) async => const Err(offline));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-2');
        expect(await cubit.join(), offline);
      },
      skip: 2,
      expect: () => [ArticlePathState(status: ArticlePathStatus.ready, articlePath: guestBlock)],
    );
  });

  test('PathProgress.allRead follows next', () {
    expect(samplePath(readCount: 4).progress!.allRead, isTrue);
    expect(samplePath(readCount: 3).progress!.allRead, isFalse);
    expect(const LearningPath(id: 'x', slug: 'x', title: 'x', field: dotnetField, articleCount: 0, readingTimeMinutes: 0).isEnrolled, isFalse);
  });
}
