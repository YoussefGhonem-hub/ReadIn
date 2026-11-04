import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/domain/repositories/article_repository.dart';
import 'package:readin/features/article/domain/usecases/get_article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/moderation/domain/entities/moderation.dart';
import 'package:readin/features/moderation/domain/usecases/moderation_usecases.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_action_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_case_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_list_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_notices_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/moderation_summary_cubit.dart';
import 'package:readin/features/moderation/presentation/cubit/report_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/moderation_fakes.dart';
import '../../helpers/social_fakes.dart';

void main() {
  late MockModerationRepository repository;

  const offline = Failure(FailureCodes.networkOffline);
  const summary = ModerationSummary(article: 1, comment: 2, total: 3);

  setUpAll(() {
    registerFallbackValue(const ModerationTargetRef.article(''));
    registerFallbackValue(ReportReason.spam);
    registerFallbackValue(ReportStatus.open);
    registerFallbackValue(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.article('')));
  });

  setUp(() => repository = MockModerationRepository());

  group('ReportCubit', () {
    const target = ModerationTargetRef.article('art-7');

    blocTest<ReportCubit, ReportState>(
      'needs a reason before it sends',
      build: () => ReportCubit(SubmitReport(repository)),
      act: (cubit) => cubit.send(target),
      expect: () => const <ReportState>[],
      verify: (_) => verifyNever(() => repository.report(any(), any(), details: any(named: 'details'))),
    );

    blocTest<ReportCubit, ReportState>(
      'sends the reason with trimmed details and ends sent',
      setUp: () => when(() => repository.report(target, ReportReason.copyright, details: 'منقول'))
          .thenAnswer((_) async => const Ok<void>(null)),
      build: () => ReportCubit(SubmitReport(repository)),
      act: (cubit) async {
        cubit.choose(ReportReason.copyright);
        await cubit.send(target, details: '  منقول \n');
      },
      expect: () => const [
        ReportState(reason: ReportReason.copyright),
        ReportState(reason: ReportReason.copyright, sending: true),
        ReportState(reason: ReportReason.copyright, sent: true),
      ],
    );

    blocTest<ReportCubit, ReportState>(
      'blank details are left out; a refusal shows and a new reason clears it',
      setUp: () => when(() => repository.report(target, ReportReason.spam, details: null))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.reportOwnContent, statusCode: 400))),
      build: () => ReportCubit(SubmitReport(repository)),
      act: (cubit) async {
        cubit.choose(ReportReason.spam);
        await cubit.send(target, details: '   ');
        cubit.choose(ReportReason.other);
      },
      expect: () => const [
        ReportState(reason: ReportReason.spam),
        ReportState(reason: ReportReason.spam, sending: true),
        ReportState(reason: ReportReason.spam, failure: Failure(FailureCodes.reportOwnContent, statusCode: 400)),
        ReportState(reason: ReportReason.other),
      ],
    );
  });

  group('ModerationActionCubit', () {
    late MockModerationSummaryCubit summaryCubit;
    const hide = ModerationCommand(ModerationActionType.hide, ModerationTargetRef.comment('c-1'), note: '  rude ');

    setUp(() {
      summaryCubit = MockModerationSummaryCubit();
      when(summaryCubit.refresh).thenAnswer((_) async {});
    });

    test('shows the action in flight, trims the note and refreshes the badge once it worked', () async {
      when(() => repository.act(any())).thenAnswer((_) async => const Ok<void>(null));
      final cubit = ModerationActionCubit(TakeModerationAction(repository), summaryCubit);
      final states = <ModerationCommand?>[];
      final sub = cubit.stream.listen(states.add);

      expect(await cubit.run(hide), isNull);
      await sub.cancel();

      expect(states, [hide, null]);
      verify(() => repository.act(const ModerationCommand(ModerationActionType.hide, ModerationTargetRef.comment('c-1'), note: 'rude')))
          .called(1);
      verify(summaryCubit.refresh).called(1);
    });

    test('a refusal comes back and leaves the badge alone; one action at a time', () async {
      final gate = Completer<Result<void>>();
      when(() => repository.act(any())).thenAnswer((_) => gate.future);
      final cubit = ModerationActionCubit(TakeModerationAction(repository), summaryCubit);

      final first = cubit.run(hide);
      expect(cubit.busy, isTrue);
      expect((await cubit.run(hide))?.code, FailureCodes.requestCancelled);
      gate.complete(const Err(Failure(FailureCodes.moderationStaffTarget, statusCode: 403)));

      expect((await first)?.code, FailureCodes.moderationStaffTarget);
      expect(cubit.busy, isFalse);
      verify(() => repository.act(any())).called(1);
      verifyNever(summaryCubit.refresh);
    });
  });

  group('ModerationSummaryCubit', () {
    blocTest<ModerationSummaryCubit, ModerationSummary?>(
      'loads the counts; a failed load keeps them',
      setUp: () {
        var calls = 0;
        when(() => repository.summary())
            .thenAnswer((_) async => calls++ == 0 ? const Ok(summary) : const Err<ModerationSummary>(offline));
      },
      build: () => ModerationSummaryCubit(GetModerationSummary(repository)),
      act: (cubit) async {
        await cubit.load();
        await cubit.refresh();
      },
      expect: () => const [summary],
      verify: (_) => verify(() => repository.summary()).called(2),
    );

    blocTest<ModerationSummaryCubit, ModerationSummary?>(
      'refresh does nothing until something loaded it',
      build: () => ModerationSummaryCubit(GetModerationSummary(repository)),
      act: (cubit) => cubit.refresh(),
      expect: () => const <ModerationSummary?>[],
      verify: (_) => verifyNever(() => repository.summary()),
    );
  });

  group('ModerationQueueCubit', () {
    final a = articleItem();
    final c = commentItem();
    final u = userItem();

    ModerationQueueCubit build() => ModerationQueueCubit(GetModerationQueue(repository), ReportStatus.open);

    void stubQueue(ModerationTargetType? type, String? cursor, Result<CursorPage<ModerationQueueItem>> result) =>
        when(() => repository.queue(ReportStatus.open, type: type, cursor: cursor, limit: 20)).thenAnswer((_) async => result);

    blocTest<ModerationQueueCubit, ModerationListState<ModerationQueueItem>>(
      'loads the first page, then the next one; a target already shown is not repeated',
      setUp: () {
        stubQueue(null, null, Ok(CursorPage(items: [a, c], nextCursor: 'p2')));
        stubQueue(null, 'p2', Ok(CursorPage(items: [c, u])));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
        await cubit.loadMore(); // the end: nothing more to ask
      },
      expect: () => [
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a, c], nextCursor: 'p2'),
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a, c], nextCursor: 'p2', loadingMore: true),
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a, c, u]),
      ],
      verify: (_) => verify(() => repository.queue(any(), type: any(named: 'type'), cursor: any(named: 'cursor'), limit: 20)).called(2),
    );

    blocTest<ModerationQueueCubit, ModerationListState<ModerationQueueItem>>(
      'the type filter reloads from the first page',
      setUp: () {
        stubQueue(null, null, Ok(CursorPage(items: [a, c, u])));
        stubQueue(ModerationTargetType.user, null, Ok(CursorPage(items: [u])));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setType(ModerationTargetType.user);
        await cubit.setType(ModerationTargetType.user); // same filter: no reload
      },
      expect: () => [
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a, c, u]),
        const ModerationListState<ModerationQueueItem>(type: ModerationTargetType.user),
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, type: ModerationTargetType.user, items: [u]),
      ],
    );

    blocTest<ModerationQueueCubit, ModerationListState<ModerationQueueItem>>(
      'a failed first page is an error; a failed later page keeps the list and offers a retry',
      setUp: () {
        var first = true;
        when(() => repository.queue(ReportStatus.open, type: null, cursor: null, limit: 20)).thenAnswer(
          (_) async => (first = !first) ? Ok(CursorPage(items: [a], nextCursor: 'p2')) : const Err(offline),
        );
        stubQueue(null, 'p2', const Err(offline));
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.load();
        await cubit.loadMore();
      },
      expect: () => [
        const ModerationListState<ModerationQueueItem>(status: ModerationListStatus.failure, failure: offline),
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a], nextCursor: 'p2'),
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a], nextCursor: 'p2', loadingMore: true),
        ModerationListState<ModerationQueueItem>(status: ModerationListStatus.ready, items: [a], nextCursor: 'p2', moreFailure: offline),
      ],
    );

    test('a refresh that fails keeps the list and says why', () async {
      var calls = 0;
      when(() => repository.queue(ReportStatus.open, type: null, cursor: null, limit: 20))
          .thenAnswer((_) async => calls++ == 0 ? Ok(CursorPage(items: [a])) : const Err(offline));
      final cubit = build();
      await cubit.load();

      expect(await cubit.refresh(), offline);
      expect(cubit.state.items, [a]);
      expect(cubit.state.status, ModerationListStatus.ready);
    });
  });

  group('ModerationLogCubit', () {
    blocTest<ModerationLogCubit, ModerationListState<ModerationLogEntry>>(
      'pages the log by type',
      setUp: () {
        when(() => repository.log(targetType: ModerationTargetType.article, cursor: null, limit: 20))
            .thenAnswer((_) async => Ok(CursorPage(items: [logEntry('l-1')], nextCursor: 'p2')));
        when(() => repository.log(targetType: ModerationTargetType.article, cursor: 'p2', limit: 20))
            .thenAnswer((_) async => Ok(CursorPage(items: [logEntry('l-1'), logEntry('l-2')])));
      },
      build: () => ModerationLogCubit(GetModerationLog(repository)),
      act: (cubit) async {
        await cubit.setType(ModerationTargetType.article);
        await cubit.loadMore();
      },
      skip: 2,
      expect: () => [
        ModerationListState<ModerationLogEntry>(
          status: ModerationListStatus.ready,
          type: ModerationTargetType.article,
          items: [logEntry('l-1')],
          nextCursor: 'p2',
          loadingMore: true,
        ),
        ModerationListState<ModerationLogEntry>(
          status: ModerationListStatus.ready,
          type: ModerationTargetType.article,
          items: [logEntry('l-1'), logEntry('l-2')],
        ),
      ],
    );
  });

  group('ModerationCaseCubit', () {
    const ref = ModerationTargetRef.article('art-7');

    blocTest<ModerationCaseCubit, ModerationCaseState>(
      'loads the case; a refresh that fails keeps it',
      setUp: () {
        var calls = 0;
        when(() => repository.getCase(ref))
            .thenAnswer((_) async => calls++ == 0 ? Ok(articleCase()) : const Err<ModerationCase>(offline));
      },
      build: () => ModerationCaseCubit(GetModerationCase(repository)),
      act: (cubit) async {
        await cubit.load(ref);
        await cubit.refresh();
      },
      expect: () => [
        const ModerationCaseState(),
        ModerationCaseState(status: ModerationCaseStatus.ready, moderationCase: articleCase()),
      ],
    );

    blocTest<ModerationCaseCubit, ModerationCaseState>(
      'an error, then retry',
      setUp: () {
        var calls = 0;
        when(() => repository.getCase(ref))
            .thenAnswer((_) async => calls++ == 0 ? const Err<ModerationCase>(offline) : Ok(articleCase()));
      },
      build: () => ModerationCaseCubit(GetModerationCase(repository)),
      act: (cubit) async {
        await cubit.load(ref);
        await cubit.refresh();
      },
      expect: () => [
        const ModerationCaseState(),
        const ModerationCaseState(status: ModerationCaseStatus.failure, failure: offline),
        const ModerationCaseState(),
        ModerationCaseState(status: ModerationCaseStatus.ready, moderationCase: articleCase()),
      ],
    );
  });

  group('ModerationNoticesCubit', () {
    late StreamController<SessionState> sessions;
    late MockSessionCubit session;

    setUp(() {
      sessions = StreamController<SessionState>.broadcast();
      session = MockSessionCubit();
      whenListen(session, sessions.stream, initialState: const SessionState());
    });

    tearDown(() => sessions.close());

    ModerationNoticesCubit build() =>
        ModerationNoticesCubit(GetModerationNotices(repository), AcknowledgeModerationNotice(repository), session);

    test('loads once the session is restored, clears on sign out, acknowledges one at a time', () async {
      when(() => repository.notices()).thenAnswer((_) async => Ok([warningNotice(), hiddenNotice()]));
      when(() => repository.acknowledge(any())).thenAnswer((_) async => const Ok<void>(null));
      final cubit = build();
      expect(cubit.state, isEmpty, reason: 'nothing before the session is known');

      sessions.add(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      await pumpEventQueue();
      expect(cubit.state, [warningNotice(), hiddenNotice()]);

      await cubit.acknowledge('n-1');
      expect(cubit.state, [hiddenNotice()]);
      verify(() => repository.acknowledge('n-1')).called(1);

      sessions.add(const SessionState(status: SessionStatus.guest));
      await pumpEventQueue();
      expect(cubit.state, isEmpty);
      verify(() => repository.notices()).called(1);
      await cubit.close();
    });

    test('guests and offline starts load nothing', () async {
      when(() => repository.notices()).thenAnswer((_) async => const Err(offline));
      final cubit = build();

      sessions.add(const SessionState(status: SessionStatus.guest));
      await pumpEventQueue();
      verifyNever(() => repository.notices());

      sessions.add(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      await pumpEventQueue();
      expect(cubit.state, isEmpty);
      await cubit.close();
    });
  });

  group('ArticleCubit (F22)', () {
    test("a moderator's hide or unhide shows at once, the rest of the article unchanged", () async {
      final articles = _MockArticleRepository();
      final article = detailsModel(1).toEntity();
      when(() => articles.getArticle('article-1', language: 'ar-EG')).thenAnswer((_) async => Ok(article));
      final cubit = ArticleCubit(GetArticle(articles));
      await cubit.load('article-1', preferredLanguage: 'ar-EG');

      final hidden = ArticleModeration(hiddenAt: moderationNow, note: 'منقول');
      cubit.setModeration(hidden);
      expect(cubit.state.article, article.withModeration(hidden));
      expect(cubit.state.article!.isHidden, isTrue);
      expect(cubit.state.article!.card, article.card);

      cubit.setModeration(null);
      expect(cubit.state.article, article);
      await cubit.close();
    });
  });
}

class _MockArticleRepository extends Mock implements ArticleRepository {}
