import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/glossary/data/datasources/glossary_api.dart';
import 'package:readin/features/glossary/data/models/glossary_models.dart';
import 'package:readin/features/glossary/data/repositories/glossary_repository_impl.dart';
import 'package:readin/features/glossary/domain/repositories/glossary_repository.dart';
import 'package:readin/features/glossary/domain/usecases/get_glossary_term.dart';
import 'package:readin/features/glossary/presentation/cubit/glossary_term_cubit.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/glossary_fixtures.dart';

class MockGlossaryApi extends Mock implements GlossaryApi {}

class MockGlossaryRepository extends Mock implements GlossaryRepository {}

/// The glossary (F21): `GlossaryTermDto` parsing, the in-memory cache and the sheet's states.
void main() {
  group('GlossaryTermModel', () {
    test('parses the term, both texts and its articles', () {
      expect(GlossaryTermModel.fromJson(diTermJson()).toEntity(), diTerm);
    });

    test('a term without articles has none', () {
      final json = {...diTermJson()}..remove('articles');
      expect(GlossaryTermModel.fromJson(json).toEntity().articles, isEmpty);
    });
  });

  group('GlossaryRepositoryImpl', () {
    late MockGlossaryApi api;
    late GlossaryRepositoryImpl repository;

    setUp(() {
      api = MockGlossaryApi();
      repository = GlossaryRepositoryImpl(api);
    });

    test('a term is fetched once per article language and then served from memory', () async {
      when(() => api.getTerm('dependency-injection', any())).thenAnswer((_) async => GlossaryTermModel.fromJson(diTermJson()));

      expect((await repository.getTerm('dependency-injection', language: 'ar-EG')).valueOrNull, diTerm);
      expect((await repository.getTerm('dependency-injection', language: 'ar-EG')).valueOrNull, diTerm);
      verify(() => api.getTerm('dependency-injection', 'ar-EG')).called(1);

      // The language picks the titles of the term's articles: another request.
      await repository.getTerm('dependency-injection', language: 'en');
      verify(() => api.getTerm('dependency-injection', 'en')).called(1);
    });

    test('failures are not kept: the next tap asks again', () async {
      var calls = 0;
      when(() => api.getTerm('dependency-injection', 'en')).thenAnswer((_) async {
        if (calls++ == 0) throw offline('/glossary/dependency-injection');
        return GlossaryTermModel.fromJson(diTermJson());
      });

      expect((await repository.getTerm('dependency-injection', language: 'en')).failureOrNull!.code, FailureCodes.networkOffline);
      expect((await repository.getTerm('dependency-injection', language: 'en')).valueOrNull, diTerm);
    });

    test('404 glossary.term_not_found keeps its code', () async {
      when(() => api.getTerm('nope', 'en')).thenThrow(httpError('/glossary/nope', 404, code: 'glossary.term_not_found'));
      final failure = (await repository.getTerm('nope', language: 'en')).failureOrNull!;
      expect(failure.code, FailureCodes.glossaryTermNotFound);
      expect(failure.statusCode, 404);
    });
  });

  group('GlossaryTermCubit', () {
    late MockGlossaryRepository repository;

    setUp(() => repository = MockGlossaryRepository());

    GlossaryTermCubit build() => GlossaryTermCubit(GetGlossaryTerm(repository));

    blocTest<GlossaryTermCubit, GlossaryTermState>(
      'loads the term for the version being read',
      setUp: () => when(() => repository.getTerm('dependency-injection', language: 'ar-EG')).thenAnswer((_) async => const Ok(diTerm)),
      build: build,
      act: (cubit) => cubit.load('dependency-injection', language: 'ar-EG'),
      expect: () => const [
        GlossaryTermState(),
        GlossaryTermState(status: GlossaryTermStatus.ready, term: diTerm),
      ],
    );

    blocTest<GlossaryTermCubit, GlossaryTermState>(
      '404 glossary.term_not_found is "not in the glossary yet", not an error',
      setUp: () => when(() => repository.getTerm('nope', language: 'en')).thenAnswer(
        (_) async => const Err(Failure(FailureCodes.glossaryTermNotFound, statusCode: 404)),
      ),
      build: build,
      act: (cubit) => cubit.load('nope', language: 'en'),
      expect: () => const [GlossaryTermState(), GlossaryTermState(status: GlossaryTermStatus.notFound)],
    );

    blocTest<GlossaryTermCubit, GlossaryTermState>(
      'a term node without an id is not looked up',
      build: build,
      act: (cubit) => cubit.load(' ', language: 'en'),
      expect: () => const [GlossaryTermState(), GlossaryTermState(status: GlossaryTermStatus.notFound)],
      verify: (_) => verifyNever(() => repository.getTerm(any(), language: any(named: 'language'))),
    );

    test('another failure is an error; retry asks again with the same term and language', () async {
      var calls = 0;
      when(() => repository.getTerm('dependency-injection', language: 'en')).thenAnswer(
        (_) async => calls++ == 0 ? const Err(Failure(FailureCodes.networkOffline)) : const Ok(diTerm),
      );
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load('dependency-injection', language: 'en');
      expect(cubit.state, const GlossaryTermState(status: GlossaryTermStatus.failure, failure: Failure(FailureCodes.networkOffline)));

      await cubit.retry();
      expect(cubit.state, const GlossaryTermState(status: GlossaryTermStatus.ready, term: diTerm));
    });
  });
}
