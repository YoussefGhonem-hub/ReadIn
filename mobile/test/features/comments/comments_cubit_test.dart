import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/domain/usecases/comment_usecases.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/social_fakes.dart';

void main() {
  late MockCommentsRepository repository;
  late MockRealtimeService realtime;
  late StreamController<CommentEvent> events;

  CommentsCubit build() => CommentsCubit(
        GetComments(repository),
        PostComment(repository),
        EditComment(repository),
        DeleteComment(repository),
        SetCommentLiked(repository),
        SetCommentPinned(repository),
        ModerateComment(repository),
        realtime,
        clock: () => commentsNow,
      );

  setUp(() {
    repository = MockCommentsRepository();
    realtime = MockRealtimeService();
    events = StreamController<CommentEvent>.broadcast();
    when(() => realtime.commentEvents('art-1')).thenAnswer((_) => events.stream);
  });

  tearDown(() => events.close());

  /// A page of top-level comments: the first one (no [cursor]) is asked for with [GetComments.firstPageSize], the next
  /// ones with [GetComments.pageSize].
  void stubPage(
    List<Comment> items, {
    CommentSort sort = CommentSort.top,
    String? cursor,
    String? next,
    int total = 10,
  }) =>
      when(() => repository.getComments('art-1', sort: sort, cursor: cursor, limit: cursor == null ? 5 : 10))
          .thenAnswer((_) async => Ok(CommentPage(items: items, nextCursor: next, total: total)));

  void stubComment(Comment comment) => when(() => repository.getComment(comment.id)).thenAnswer((_) async => Ok(comment));

  CommentEvent event(CommentEventType type, String commentId, {String? parentId, String id = 'e1'}) =>
      CommentEvent(id: id, type: type, commentId: commentId, parentId: parentId, at: 1);

  /// Lets the live event handlers (and their refetches) finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<String> ids(CommentsState state) => [for (final t in state.threads) t.id];

  final r1 = comment('r1', parentId: 'c1', minutesAgo: 20);
  final r2 = comment('r2', parentId: 'c1', minutesAgo: 10);

  group('loading (F11)', () {
    blocTest<CommentsCubit, CommentsState>(
      'the first page: threads with their first replies and the total; live events are followed',
      setUp: () => stubPage([comment('c1', replyCount: 3, replies: [r1, r2]), comment('c2')], next: 'p2', total: 7),
      build: build,
      act: (cubit) => cubit.load('art-1'),
      expect: () => [
        isA<CommentsState>().having((s) => s.status, 'status', CommentsStatus.loading),
        isA<CommentsState>()
            .having((s) => s.status, 'status', CommentsStatus.ready)
            .having(ids, 'threads', ['c1', 'c2'])
            .having((s) => s.threads.first.replies, 'replies', [r1, r2])
            .having((s) => s.threads.first.comment.replies, 'replies moved to the thread', isEmpty)
            .having((s) => s.threads.first.visibleReplies, 'only the first reply shows', [r1])
            .having((s) => s.threads.first.moreReplies, 'show 2 more replies: r2 and the one not loaded', 2)
            .having((s) => s.total, 'total', 7)
            .having((s) => s.hasMore, 'hasMore', isTrue),
      ],
      verify: (_) => verify(() => realtime.commentEvents('art-1')).called(1),
    );

    blocTest<CommentsCubit, CommentsState>(
      'pages: the next page is appended, comments already shown are skipped, the end has no more',
      setUp: () {
        stubPage([comment('c1'), comment('c2')], next: 'p2');
        stubPage([comment('c2'), comment('c3')], cursor: 'p2');
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-1');
        await cubit.loadMore();
        await cubit.loadMore();
      },
      verify: (cubit) {
        expect(ids(cubit.state), ['c1', 'c2', 'c3']);
        expect(cubit.state.hasMore, isFalse);
        verify(() => repository.getComments('art-1', sort: CommentSort.top, cursor: 'p2', limit: 10)).called(1);
      },
    );

    test('page sizes, as on the web: the first page asks for 5 threads, "show more" for 10 more', () async {
      expect((GetComments.firstPageSize, GetComments.pageSize), (5, 10));
      // Any limit works with the cursor (the next index): a page holds as many threads as were asked for.
      for (final sort in CommentSort.values) {
        when(() => repository.getComments('art-1', sort: sort, cursor: any(named: 'cursor'), limit: any(named: 'limit')))
            .thenAnswer((invocation) async {
          final cursor = invocation.namedArguments[#cursor] as String?;
          final limit = invocation.namedArguments[#limit] as int;
          final start = cursor == null ? 0 : int.parse(cursor);
          return Ok(CommentPage(
            items: [for (var i = start; i < start + limit; i++) comment('c$i')],
            nextCursor: '${start + limit}',
            total: 40,
          ));
        });
      }
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load('art-1');
      expect(cubit.state.threads, hasLength(5));
      await cubit.loadMore();
      expect(ids(cubit.state), [for (var i = 0; i < 15; i++) 'c$i']);
      await cubit.changeSort(CommentSort.newest);
      await cubit.refresh();

      verifyInOrder([
        () => repository.getComments('art-1', sort: CommentSort.top, cursor: null, limit: 5),
        () => repository.getComments('art-1', sort: CommentSort.top, cursor: '5', limit: 10),
        () => repository.getComments('art-1', sort: CommentSort.newest, cursor: null, limit: 5),
        () => repository.getComments('art-1', sort: CommentSort.newest, cursor: null, limit: 5),
      ]);
    });

    blocTest<CommentsCubit, CommentsState>(
      'Top / Newest: switching reloads with sort=new; the same sort again does nothing',
      setUp: () {
        stubPage([comment('c1'), comment('c2')]);
        stubPage([comment('c2'), comment('c1')], sort: CommentSort.newest);
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-1');
        await cubit.changeSort(CommentSort.newest);
        await cubit.changeSort(CommentSort.newest);
      },
      expect: () => [
        isA<CommentsState>().having((s) => s.status, 'status', CommentsStatus.loading),
        isA<CommentsState>().having(ids, 'top', ['c1', 'c2']),
        isA<CommentsState>()
            .having((s) => s.status, 'status', CommentsStatus.loading)
            .having((s) => s.sort, 'sort', CommentSort.newest),
        isA<CommentsState>().having(ids, 'newest', ['c2', 'c1']).having((s) => s.sort, 'sort', CommentSort.newest),
      ],
    );

    blocTest<CommentsCubit, CommentsState>(
      'a failed first page, then a retry',
      setUp: () {
        var calls = 0;
        when(() => repository.getComments('art-1', sort: CommentSort.top, cursor: null, limit: 5)).thenAnswer((_) async {
          calls++;
          return calls == 1 ? const Err(Failure(FailureCodes.networkOffline)) : Ok(CommentPage(items: [comment('c1')], total: 1));
        });
      },
      build: build,
      act: (cubit) async {
        await cubit.load('art-1');
        await cubit.retry();
      },
      expect: () => [
        isA<CommentsState>().having((s) => s.status, 'status', CommentsStatus.loading),
        isA<CommentsState>()
            .having((s) => s.status, 'status', CommentsStatus.failure)
            .having((s) => s.failure?.code, 'failure', FailureCodes.networkOffline),
        isA<CommentsState>().having((s) => s.status, 'status', CommentsStatus.loading),
        isA<CommentsState>().having(ids, 'threads', ['c1']),
      ],
    );

    test('"show N more replies" loads the rest of the thread without duplicates', () async {
      stubPage([comment('c1', replyCount: 4, replies: [r1, r2])]);
      final r3 = comment('r3', parentId: 'c1', minutesAgo: 5);
      final r4 = comment('r4', parentId: 'c1', minutesAgo: 1);
      when(() => repository.getReplies('c1', cursor: null, limit: 5))
          .thenAnswer((_) async => Ok(CursorPage(items: [r1, r2, r3, r4])));
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load('art-1');
      expect(cubit.state.threads.single.hasMoreReplies, isTrue);
      await cubit.loadMoreReplies('c1');

      final thread = cubit.state.threads.single;
      expect(thread.replies, [r1, r2, r3, r4]);
      expect(thread.visibleReplies, [r1, r2, r3, r4]);
      expect(thread.hasMoreReplies, isFalse);
    });
  });

  group('reply paging (Facebook / LinkedIn style)', () {
    late CommentsCubit cubit;

    setUp(() => cubit = build());
    tearDown(() => cubit.close());

    /// Reply [n] of thread c1, oldest first.
    Comment reply(int n) => comment('r$n', parentId: 'c1', minutesAgo: 100 - n);
    List<String> visible() => [for (final r in cubit.state.threads.single.visibleReplies) r.id];
    CommentThread thread() => cubit.state.threads.single;

    void stubReplies(String? cursor, List<int> numbers, {String? next}) => when(() => repository.getReplies('c1', cursor: cursor, limit: 5))
        .thenAnswer((_) async => Ok(CursorPage(items: [for (final n in numbers) reply(n)], nextCursor: next)));

    test('only the first reply shows; N counts every reply not on screen, loaded or not', () async {
      stubPage([
        comment('c1', replyCount: 4, replies: [reply(1), reply(2)]),
        comment('c2', replyCount: 3),
        comment('c3', replyCount: 1, replies: [comment('r9', parentId: 'c3')]),
      ]);
      await cubit.load('art-1');

      final [withTwo, noneIncluded, single] = cubit.state.threads;
      expect(withTwo.visibleReplies.map((r) => r.id), ['r1']);
      expect(withTwo.moreReplies, 3);
      expect(withTwo.hasMoreReplies, isTrue);
      expect(withTwo.canHideReplies, isFalse);
      expect(noneIncluded.visibleReplies, isEmpty, reason: 'replies but none included');
      expect(noneIncluded.moreReplies, 3);
      expect(noneIncluded.hasMoreReplies, isTrue, reason: 'the button shows straight away');
      expect(single.visibleReplies.map((r) => r.id), ['r9']);
      expect(single.hasMoreReplies, isFalse);
      expect(single.moreReplies, 0);
    });

    test('a tap shows the included ones from memory without a request', () async {
      stubPage([comment('c1', replyCount: 2, replies: [reply(1), reply(2)])]);
      await cubit.load('art-1');

      await cubit.loadMoreReplies('c1');

      expect(visible(), ['r1', 'r2']);
      expect(thread().hasMoreReplies, isFalse);
      expect(thread().canHideReplies, isTrue);
      verifyNever(() => repository.getReplies(any(), cursor: any(named: 'cursor'), limit: any(named: 'limit')));
    });

    test('each tap shows up to 5 more: memory first, then pages of 5 (the first without a cursor, its 2 included '
        'replies deduped), until all show', () async {
      stubPage([comment('c1', replyCount: 12, replies: [reply(1), reply(2)])]);
      stubReplies(null, [1, 2, 3, 4, 5], next: 'p2');
      stubReplies('p2', [6, 7, 8, 9, 10], next: 'p3');
      stubReplies('p3', [11, 12]);
      await cubit.load('art-1');

      final first = cubit.loadMoreReplies('c1');
      expect(visible(), ['r1', 'r2'], reason: 'the loaded one shows at once, while the page loads');
      expect(thread().loadingReplies, isTrue);
      await first;
      expect(visible(), ['r1', 'r2', 'r3', 'r4', 'r5']);
      expect(thread().replies.map((r) => r.id), ['r1', 'r2', 'r3', 'r4', 'r5'], reason: 'r1 and r2 once each');
      expect(thread().moreReplies, 7);

      await cubit.loadMoreReplies('c1');
      expect(visible(), [for (var n = 1; n <= 10; n++) 'r$n']);
      expect(thread().moreReplies, 2);

      await cubit.loadMoreReplies('c1');
      expect(visible(), [for (var n = 1; n <= 12; n++) 'r$n']);
      expect(thread().moreReplies, 0);
      expect(thread().hasMoreReplies, isFalse);

      verify(() => repository.getReplies('c1', cursor: null, limit: 5)).called(1);
      verify(() => repository.getReplies('c1', cursor: 'p2', limit: 5)).called(1);
      verify(() => repository.getReplies('c1', cursor: 'p3', limit: 5)).called(1);
    });

    test('Hide replies goes back to the first one; loaded replies stay, and show again 5 at a time without a request',
        () async {
      stubPage([comment('c1', replyCount: 7, replies: [reply(1), reply(2)])]);
      stubReplies(null, [1, 2, 3, 4, 5], next: 'p2');
      stubReplies('p2', [6, 7]);
      await cubit.load('art-1');
      await cubit.loadMoreReplies('c1');
      await cubit.loadMoreReplies('c1');
      expect(visible(), hasLength(7));

      cubit.hideReplies('c1');
      expect(visible(), ['r1']);
      expect(thread().replies, hasLength(7));
      expect(thread().moreReplies, 6);
      expect(thread().canHideReplies, isFalse);

      await cubit.loadMoreReplies('c1');
      expect(visible(), ['r1', 'r2', 'r3', 'r4', 'r5', 'r6']);
      await cubit.loadMoreReplies('c1');
      expect(visible(), hasLength(7));
      verify(() => repository.getReplies('c1', cursor: null, limit: 5)).called(1);
      verify(() => repository.getReplies('c1', cursor: 'p2', limit: 5)).called(1);
    });

    test('new replies show at once while the thread is collapsed, at its end; N never counts them', () async {
      stubPage([comment('c1', replyCount: 4, replies: [reply(1), reply(2)])]);
      final answer = Completer<Result<Comment>>();
      when(() => repository.postReply('c1', 'رد جديد')).thenAnswer((_) => answer.future);
      final mine = comment('r20', parentId: 'c1', body: 'رد جديد', author: viewer, own: true, minutesAgo: 2);
      final live = comment('r21', parentId: 'c1', author: mona, minutesAgo: 1);
      stubComment(live);
      await cubit.load('art-1');
      expect(thread().moreReplies, 3);

      // The viewer's own reply: pending, then the API's.
      cubit.startReply(thread().comment);
      final done = cubit.submit('رد جديد', author: viewer);
      final pendingId = cubit.state.pendingIds.single;
      expect(visible(), ['r1', pendingId]);
      expect(thread().moreReplies, 3, reason: 'r2 and the two not loaded; not the visible new reply');
      answer.complete(Ok(mine));
      await done;
      expect(visible(), ['r1', 'r20']);
      expect(thread().moreReplies, 3);

      // A live reply.
      events.add(event(CommentEventType.replyCreated, 'r21', parentId: 'c1'));
      await settle();
      expect(visible(), ['r1', 'r20', 'r21']);
      expect(thread().comment.replyCount, 6);
      expect(thread().moreReplies, 3);
      expect(thread().canHideReplies, isTrue);

      // Showing the rest puts them in order; the new ones already shown don't show twice.
      when(() => repository.getReplies('c1', cursor: null, limit: 5)).thenAnswer(
        (_) async => Ok(CursorPage(items: [reply(1), reply(2), reply(3), reply(4), mine])),
      );
      await cubit.loadMoreReplies('c1');
      expect(visible(), ['r1', 'r2', 'r3', 'r4', 'r20', 'r21']);
      expect(thread().moreReplies, 0);
      expect(thread().hasMoreReplies, isFalse);

      // Hide replies: back to the first one, the new ones too.
      cubit.hideReplies('c1');
      expect(visible(), ['r1']);
      expect(thread().moreReplies, 5);
    });

    test('a failed page keeps what showed and says so; retry asks for the same page', () async {
      stubPage([comment('c1', replyCount: 3)]);
      var calls = 0;
      when(() => repository.getReplies('c1', cursor: null, limit: 5)).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Err(Failure(FailureCodes.networkOffline)) : Ok(CursorPage(items: [reply(1), reply(2), reply(3)]));
      });
      await cubit.load('art-1');

      await cubit.loadMoreReplies('c1');
      expect(thread().repliesFailure?.code, FailureCodes.networkOffline);
      expect(thread().loadingReplies, isFalse);
      expect(visible(), isEmpty);

      await cubit.loadMoreReplies('c1');
      expect(thread().repliesFailure, isNull);
      expect(visible(), ['r1', 'r2', 'r3']);
    });
  });

  group("the viewer's own actions", () {
    late CommentsCubit cubit;

    setUp(() => cubit = build());
    tearDown(() => cubit.close());

    test('a like counts at once, then takes the API numbers', () async {
      stubPage([comment('c1', likeCount: 2)]);
      final answer = Completer<Result<CommentLike>>();
      when(() => repository.setLiked('c1', liked: true)).thenAnswer((_) => answer.future);
      await cubit.load('art-1');

      final done = cubit.toggleLike('c1');
      expect(cubit.find('c1')!.likedByMe, isTrue);
      expect(cubit.find('c1')!.likeCount, 3);
      expect(await cubit.toggleLike('c1'), isNull, reason: 'a second tap while in flight is ignored');

      answer.complete(const Ok(CommentLike(likeCount: 5, liked: true)));
      expect(await done, isNull);
      expect(cubit.find('c1')!.likeCount, 5);
      verify(() => repository.setLiked('c1', liked: true)).called(1);
    });

    test('a refused like rolls back and returns the failure', () async {
      stubPage([comment('c1', likeCount: 2, likedByMe: true)]);
      when(() => repository.setLiked('c1', liked: false)).thenAnswer((_) async => const Err(Failure(FailureCodes.commentNotAvailable)));
      await cubit.load('art-1');

      final failure = await cubit.toggleLike('c1');

      expect(failure?.code, FailureCodes.commentNotAvailable);
      expect(cubit.find('c1')!.likedByMe, isTrue);
      expect(cubit.find('c1')!.likeCount, 2);
    });

    test('a new comment shows at once as pending below the pinned one; the API comment replaces it', () async {
      stubPage([comment('c0', isPinned: true), comment('c1')], total: 2);
      final answer = Completer<Result<Comment>>();
      when(() => repository.postComment('art-1', 'أول تعليق ليا')).thenAnswer((_) => answer.future);
      await cubit.load('art-1');

      final done = cubit.submit('  أول تعليق ليا  ', author: viewer);
      final pending = cubit.state.threads[1].comment;
      expect(cubit.state.pendingIds, {pending.id});
      expect(pending.body, 'أول تعليق ليا');
      expect(pending.author, viewer);
      expect(cubit.state.total, 3);

      final mine = comment('c9', body: 'أول تعليق ليا', author: viewer, own: true, minutesAgo: 0);
      answer.complete(Ok(mine));
      expect(await done, isNull);
      expect(ids(cubit.state), ['c0', 'c9', 'c1']);
      expect(cubit.state.threads[1].comment, mine);
      expect(cubit.state.pendingIds, isEmpty);
      expect(cubit.state.total, 3);
    });

    test('replying to a reply posts to the reply and joins its thread', () async {
      stubPage([comment('c1', replyCount: 1, replies: [r1])]);
      final answer = Completer<Result<Comment>>();
      when(() => repository.postReply('r1', '@omar_k تمام')).thenAnswer((_) => answer.future);
      await cubit.load('art-1');

      cubit.startReply(r1);
      expect(cubit.state.target, ComposerTarget.reply(r1));
      final done = cubit.submit('@omar_k تمام', author: viewer);
      expect(cubit.state.target, isNull);
      expect(cubit.state.threads.single.replies.length, 2);
      expect(cubit.state.threads.single.comment.replyCount, 2);

      final reply = comment('r9', parentId: 'c1', body: '@omar_k تمام', author: viewer, own: true, minutesAgo: 0);
      answer.complete(Ok(reply));
      await done;
      expect(cubit.state.threads.single.replies, [r1, reply]);
      expect(cubit.state.threads.single.comment.replyCount, 2);
    });

    test('a refused comment leaves the list, and the reply target comes back for another try', () async {
      final c1 = comment('c1');
      stubPage([c1], total: 1);
      when(() => repository.postReply('c1', 'رد')).thenAnswer((_) async => const Err(Failure(FailureCodes.commentDuplicate, statusCode: 409)));
      await cubit.load('art-1');

      cubit.startReply(c1);
      final failure = await cubit.submit('رد', author: viewer);

      expect(failure?.code, FailureCodes.commentDuplicate);
      expect(cubit.state.threads.single.replies, isEmpty);
      expect(cubit.state.threads.single.comment.replyCount, 0);
      expect(cubit.state.total, 1);
      expect(cubit.state.pendingIds, isEmpty);
      expect(cubit.state.target, ComposerTarget.reply(c1));
    });

    test('empty text is refused without a request', () async {
      stubPage([]);
      await cubit.load('art-1');

      expect((await cubit.submit(' \n ', author: viewer))?.code, FailureCodes.commentEmpty);
      verifyNever(() => repository.postComment(any(), any()));
    });

    test('an edit replaces the comment once the API saved it', () async {
      final mine = comment('c1', own: true, body: 'قبل');
      stubPage([mine]);
      final edited = comment('c1', own: true, body: 'بعد', edited: true);
      when(() => repository.editComment('c1', 'بعد')).thenAnswer((_) async => Ok(edited));
      await cubit.load('art-1');

      cubit.startEdit(mine);
      expect(await cubit.submit('بعد', author: viewer), isNull);

      expect(cubit.find('c1'), edited);
      expect(cubit.state.target, isNull);
      expect(cubit.state.sending, isFalse);
    });

    test('delete: alone it leaves, with replies it becomes a placeholder, refused it comes back', () async {
      stubPage([comment('c1', own: true), comment('c2', own: true, replyCount: 1, replies: [comment('r1', parentId: 'c2')])], total: 3);
      when(() => repository.deleteComment('c1')).thenAnswer((_) async => const Ok<void>(null));
      when(() => repository.deleteComment('c2')).thenAnswer((_) async => const Ok<void>(null));
      when(() => repository.deleteComment('r1')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await cubit.load('art-1');

      expect(await cubit.delete('c1'), isNull);
      expect(ids(cubit.state), ['c2']);
      expect(cubit.state.total, 2);

      expect(await cubit.delete('c2'), isNull);
      final thread = cubit.state.threads.single;
      expect(thread.comment.isDeleted, isTrue);
      expect(thread.comment.isPlaceholder, isTrue);
      expect(thread.replies.map((r) => r.id), ['r1']);
      expect(cubit.state.total, 1);

      expect((await cubit.delete('r1'))?.code, FailureCodes.networkOffline);
      expect(cubit.state.threads.single.replies.map((r) => r.id), ['r1']);
      expect(cubit.state.total, 1);
    });

    test('pinning moves the comment to the top and unpins the previous one', () async {
      stubPage([comment('c1', isPinned: true, canPin: true), comment('c2', canPin: true)]);
      when(() => repository.setPinned('c2', pinned: true)).thenAnswer((_) async => Ok(comment('c2', isPinned: true, canPin: true)));
      await cubit.load('art-1');

      expect(await cubit.setPinned('c2', pinned: true), isNull);

      expect(ids(cubit.state), ['c2', 'c1']);
      expect(cubit.find('c2')!.isPinned, isTrue);
      expect(cubit.find('c1')!.isPinned, isFalse);
    });

    test('moderators hide a comment: they still see it, marked hidden; it no longer counts', () async {
      stubPage([comment('c1', canModerate: true)], total: 1);
      when(() => repository.moderateComment('c1', ModerationAction.hide)).thenAnswer((_) async => const Ok<void>(null));
      await cubit.load('art-1');

      expect(await cubit.moderate('c1', ModerationAction.hide), isNull);

      expect(cubit.find('c1')!.isHidden, isTrue);
      expect(cubit.find('c1')!.body, isNotNull);
      expect(cubit.state.total, 0);
    });
  });

  group('live (F27)', () {
    late CommentsCubit cubit;

    setUp(() => cubit = build());
    tearDown(() => cubit.close());

    Future<void> loadNewest(List<Comment> items) async {
      stubPage(items);
      stubPage(items, sort: CommentSort.newest);
      await cubit.load('art-1');
      await cubit.changeSort(CommentSort.newest);
    }

    test('Newest, near the top: a new comment goes to the top, highlighted; a repeated event fetches once', () async {
      stubComment(comment('c5', minutesAgo: 0));
      await loadNewest([comment('c1')]);

      events
        ..add(event(CommentEventType.created, 'c5'))
        ..add(event(CommentEventType.created, 'c5', id: 'e2'));
      await settle();

      expect(ids(cubit.state), ['c5', 'c1']);
      expect(cubit.state.highlighted, {'c5'});
      expect(cubit.state.incoming, isEmpty);
      verify(() => repository.getComment('c5')).called(1);
    });

    test('in Top, or scrolled away: new comments wait behind the pill, then go to the top on tap', () async {
      stubPage([comment('c1')]);
      stubComment(comment('c5', minutesAgo: 2));
      stubComment(comment('c6', minutesAgo: 1));
      await cubit.load('art-1');

      events
        ..add(event(CommentEventType.created, 'c5'))
        ..add(event(CommentEventType.created, 'c6', id: 'e2'));
      await settle();
      expect(ids(cubit.state), ['c1']);
      expect(cubit.state.incoming.map((c) => c.id), ['c6', 'c5']);

      cubit.showIncoming();
      expect(ids(cubit.state), ['c6', 'c5', 'c1']);
      expect(cubit.state.incoming, isEmpty);
      expect(cubit.state.highlighted, {'c5', 'c6'});
    });

    test('Newest but scrolled away: the pill too', () async {
      stubComment(comment('c5', minutesAgo: 0));
      await loadNewest([comment('c1')]);
      cubit.setNearTop(false);

      events.add(event(CommentEventType.created, 'c5'));
      await settle();

      expect(ids(cubit.state), ['c1']);
      expect(cubit.state.incoming.map((c) => c.id), ['c5']);
    });

    test('a new reply goes into its thread', () async {
      stubPage([comment('c1', replyCount: 1, replies: [r1])]);
      stubComment(r2);
      await cubit.load('art-1');

      events.add(event(CommentEventType.replyCreated, 'r2', parentId: 'c1'));
      await settle();

      final thread = cubit.state.threads.single;
      expect(thread.replies, [r1, r2]);
      expect(thread.comment.replyCount, 2);
      expect(cubit.state.highlighted, {'r2'});
    });

    test('edits, likes and deletes are refetched and replaced in place; unknown comments are skipped', () async {
      stubPage([comment('c1', likeCount: 1), comment('c2'), comment('c3', replyCount: 1, replies: [comment('r3', parentId: 'c3')])]);
      final c1 = comment('c1', likeCount: 4, body: 'متعدّل', edited: true);
      stubComment(c1);
      stubComment(placeholder('c2'));
      stubComment(placeholder('c3', replyCount: 1));
      await cubit.load('art-1');

      events
        ..add(event(CommentEventType.liked, 'c1'))
        ..add(event(CommentEventType.deleted, 'c2', id: 'e2'))
        ..add(event(CommentEventType.deleted, 'c3', id: 'e3'))
        ..add(event(CommentEventType.updated, 'zz', id: 'e4'));
      await settle();

      expect(ids(cubit.state), ['c1', 'c3'], reason: 'a placeholder without replies is left out');
      expect(cubit.find('c1'), c1);
      expect(cubit.find('c3')!.isPlaceholder, isTrue);
      expect(cubit.state.threads.last.replies.map((r) => r.id), ['r3']);
      verifyNever(() => repository.getComment('zz'));
    });

    test("an event for the viewer's own in-flight like is skipped", () async {
      stubPage([comment('c1', likeCount: 1)]);
      final answer = Completer<Result<CommentLike>>();
      when(() => repository.setLiked('c1', liked: true)).thenAnswer((_) => answer.future);
      await cubit.load('art-1');

      final done = cubit.toggleLike('c1');
      events.add(event(CommentEventType.liked, 'c1'));
      await settle();
      verifyNever(() => repository.getComment('c1'));

      answer.complete(const Ok(CommentLike(likeCount: 2, liked: true)));
      await done;
      expect(cubit.find('c1')!.likeCount, 2);
    });

    test("the viewer's own new comment shows once, even when its event beats the POST answer", () async {
      final answer = Completer<Result<Comment>>();
      final mine = comment('c9', body: 'سلام', author: viewer, own: true, minutesAgo: 0);
      when(() => repository.postComment('art-1', 'سلام')).thenAnswer((_) => answer.future);
      stubComment(mine);
      await loadNewest([comment('c1')]);

      final done = cubit.submit('سلام', author: viewer);
      events.add(event(CommentEventType.created, 'c9'));
      await settle();
      expect(cubit.state.threads.length, 2, reason: 'the pending comment and c1');
      expect(cubit.find('c9'), isNull);
      expect(cubit.state.incoming, isEmpty);

      answer.complete(Ok(mine));
      await done;
      events.add(event(CommentEventType.created, 'c9', id: 'e2'));
      await settle();

      expect(ids(cubit.state), ['c9', 'c1']);
      expect(cubit.state.incoming, isEmpty);
    });

    test('live counts replace the total', () async {
      stubPage([comment('c1')], total: 1);
      await cubit.load('art-1');

      cubit.syncTotal(4);
      expect(cubit.state.total, 4);
    });

    test('closing stops the live events', () async {
      var cancelled = false;
      final controller = StreamController<CommentEvent>(onCancel: () => cancelled = true);
      when(() => realtime.commentEvents('art-1')).thenAnswer((_) => controller.stream);
      stubPage([]);
      final other = build();
      await other.load('art-1');

      await other.close();
      expect(cancelled, isTrue);
    });
  });
}
