import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/domain/repositories/reading_repository.dart';
import 'package:readin/features/reading/domain/usecases/reading_usecases.dart';
import 'package:readin/features/reading/presentation/tracking/reading_tracker.dart';

class MockReadingRepository extends Mock implements ReadingRepository {}

const _ok = ReadingProgressResult(percent: 0, completed: false, completedNow: false);

void main() {
  setUpAll(() => registerFallbackValue(
        const ReadingProgressReport(language: 'en', percent: 0, lastPosition: null, activeSecondsDelta: 0),
      ));

  late MockReadingRepository repository;
  late List<ReadingProgressReport> sent;
  late List<FutureOr<Result<ReadingProgressResult>> Function()> answers;

  setUp(() {
    repository = MockReadingRepository();
    sent = [];
    answers = [];
    when(() => repository.reportProgress(any(), any())).thenAnswer((invocation) async {
      sent.add(invocation.positionalArguments[1] as ReadingProgressReport);
      return answers.isEmpty ? const Ok(_ok) : await answers.removeAt(0)();
    });
  });

  ReadingTracker tracker(FakeAsync async, {bool signedIn = true, void Function(ReadingProgressResult)? onResult}) =>
      ReadingTracker(
        articleId: 'art-1',
        language: 'ar-EG',
        report: ReportReadingProgress(repository),
        isSignedIn: () => signedIn,
        onResult: onResult,
        now: () => DateTime(2026, 11, 3, 9).add(async.elapsed),
      );

  List<int> seconds() => [for (final r in sent) r.activeSecondsDelta];

  test('reports at once on open, with no seconds', () {
    fakeAsync((async) {
      tracker(async).start();
      async.flushMicrotasks();

      expect(sent, [const ReadingProgressReport(language: 'ar-EG', percent: 0, lastPosition: '0.0000', activeSecondsDelta: 0)]);
      verify(() => repository.reportProgress('art-1', any())).called(1);
    });
  });

  test('counts active seconds every 15 s and stops 60 s after the last interaction', () {
    fakeAsync((async) {
      tracker(async).start();
      async.elapse(const Duration(seconds: 90));

      // Active right after opening; 60 s later nothing changed, so the next reports are skipped.
      expect(seconds(), [0, 15, 15, 15, 15]);

      final t = tracker(async);
      sent.clear();
      t.start();
      async.elapse(const Duration(seconds: 50));
      t.interact(); // at 50 s: active again until 110 s
      async.elapse(const Duration(seconds: 100));
      expect(seconds(), [0, 15, 15, 15, 15, 15, 15, 15, 5]);
    });
  });

  test('pausing the app sends its seconds at once and stops counting until it resumes', () {
    fakeAsync((async) {
      final t = tracker(async)..start();
      async.elapse(const Duration(seconds: 10));

      t.setAppResumed(false);
      async.flushMicrotasks();
      expect(seconds(), [0, 10]);

      async.elapse(const Duration(seconds: 60));
      expect(seconds(), [0, 10]);

      t.setAppResumed(true); // at 70 s; coming back counts as activity
      async.elapse(const Duration(seconds: 5));
      expect(seconds(), [0, 10, 5]);
    });
  });

  test('a covered reader does not count', () {
    fakeAsync((async) {
      final t = tracker(async)..start();
      async.elapse(const Duration(seconds: 5));
      t.setVisible(false);
      async.elapse(const Duration(seconds: 40));
      expect(seconds(), [0, 5]);

      t.setVisible(true); // at 45 s
      async.elapse(const Duration(seconds: 15));
      expect(seconds(), [0, 5, 15]);
    });
  });

  test('dispose sends the unsent seconds and stops the timer', () {
    fakeAsync((async) {
      final t = tracker(async)..start();
      async.elapse(const Duration(seconds: 20));
      t.dispose();
      async.flushMicrotasks();
      expect(seconds(), [0, 15, 5]);

      async.elapse(const Duration(minutes: 2));
      expect(seconds(), [0, 15, 5]);
    });
  });

  test('a report that fails offline or with a conflict keeps its seconds for the next one', () {
    fakeAsync((async) {
      answers = [
        () => const Ok(_ok),
        () => const Err(Failure(FailureCodes.networkOffline)),
        () => const Err(Failure(FailureCodes.readingConflict, statusCode: 409)),
        () => const Err(Failure(FailureCodes.serverError, statusCode: 503)),
      ];
      tracker(async).start();
      async.elapse(const Duration(seconds: 60));

      expect(seconds(), [0, 15, 30, 45, 60]);
    });
  });

  for (final failure in const [
    Failure(FailureCodes.articleNotFound, statusCode: 404),
    Failure(FailureCodes.authUnauthorized, statusCode: 401),
  ]) {
    test('stops after a ${failure.statusCode}', () {
      fakeAsync((async) {
        answers = [() => const Ok(_ok), () => Err(failure)];
        final t = tracker(async)..start();
        async.elapse(const Duration(seconds: 15));
        expect(seconds(), [0, 15]);

        t.interact();
        async.elapse(const Duration(seconds: 45));
        t.dispose();
        async.flushMicrotasks();
        expect(seconds(), [0, 15]);
        expect(t.isStopped, isTrue);
      });
    });
  }

  test('one report is in flight at a time; the next waits for it', () {
    fakeAsync((async) {
      final slow = Completer<Result<ReadingProgressResult>>();
      answers = [() => const Ok(_ok), () => slow.future];
      tracker(async).start();
      async.elapse(const Duration(seconds: 45)); // reports due at 15, 30 and 45 s
      expect(seconds(), [0, 15]);

      slow.complete(const Ok(_ok));
      async.flushMicrotasks();
      expect(seconds(), [0, 15, 30]);
    });
  });

  test('sends the highest percent reached, the current position and the current language', () {
    fakeAsync((async) {
      final t = tracker(async)..start();
      t
        ..updateScroll(0.8)
        ..updateScroll(0.42);
      async.elapse(const Duration(seconds: 15));
      expect(sent.last, const ReadingProgressReport(language: 'ar-EG', percent: 80, lastPosition: '0.4200', activeSecondsDelta: 15));

      // Idle, but the position moved: still reported, with no seconds.
      async.elapse(const Duration(seconds: 60));
      sent.clear();
      t
        ..language = 'en'
        ..updateScroll(0.9);
      async.elapse(const Duration(seconds: 15));
      expect(sent, [const ReadingProgressReport(language: 'en', percent: 90, lastPosition: '0.9000', activeSecondsDelta: 0)]);
    });
  });

  test('keeps reporting after the article is read and passes every result on', () {
    fakeAsync((async) {
      final streak = Streak(
        current: 7,
        longest: 7,
        readToday: true,
        freezeAvailable: true,
        freezePending: false,
        today: DateTime.utc(2026, 11, 3),
      );
      final completed = ReadingProgressResult(percent: 80, completed: true, completedNow: true, streak: streak, milestone: 7);
      answers = [() => const Ok(_ok), () => Ok(completed)];
      final results = <ReadingProgressResult>[];
      tracker(async, onResult: results.add).start();
      async.elapse(const Duration(seconds: 30));

      expect(seconds(), [0, 15, 15]);
      expect(results, [_ok, completed, _ok]);
    });
  });

  test('guests send nothing', () {
    fakeAsync((async) {
      final t = tracker(async, signedIn: false)..start();
      t
        ..interact()
        ..updateScroll(1);
      async.elapse(const Duration(minutes: 2));
      t.setAppResumed(false);
      t.dispose();
      async.flushMicrotasks();

      verifyNever(() => repository.reportProgress(any(), any()));
    });
  });
}
