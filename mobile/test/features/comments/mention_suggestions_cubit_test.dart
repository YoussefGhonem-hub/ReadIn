import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/comments/domain/usecases/comment_usecases.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';

import '../../helpers/comment_fixtures.dart';

void main() {
  late MockCommentsRepository repository;

  setUp(() => repository = MockCommentsRepository());

  test('asks once typing pauses for 250 ms, for the last query only', () {
    fakeAsync((async) {
      when(() => repository.mentionSuggestions('mo', limit: 8)).thenAnswer((_) async => const Ok([mona]));
      final cubit = MentionSuggestionsCubit(SuggestMentions(repository));

      cubit.search('m');
      async.elapse(const Duration(milliseconds: 100));
      cubit.search('mo');
      async.elapse(const Duration(milliseconds: 249));
      verifyNever(() => repository.mentionSuggestions(any(), limit: any(named: 'limit')));

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(cubit.state, [mona]);
      verify(() => repository.mentionSuggestions('mo', limit: 8)).called(1);
      verifyNever(() => repository.mentionSuggestions('m', limit: 8));

      cubit.search(null);
      expect(cubit.state, isEmpty);
      cubit.close();
    });
  });

  test('an answer for an older query is dropped; a failure shows nothing', () {
    fakeAsync((async) {
      final cubit = MentionSuggestionsCubit(SuggestMentions(repository));
      when(() => repository.mentionSuggestions('om', limit: 8)).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 1), () => const Ok([omar])),
      );
      when(() => repository.mentionSuggestions('mo', limit: 8)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));

      cubit.search('om');
      async.elapse(const Duration(milliseconds: 300)); // asked; the answer takes a second
      cubit.search('mo');
      async.elapse(const Duration(seconds: 2));

      expect(cubit.state, isEmpty);
      cubit.close();
    });
  });
}
