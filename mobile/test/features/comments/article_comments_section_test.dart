import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/domain/usecases/comment_usecases.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/article_comments_section.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_composer.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/comments/presentation/widgets/comments_sheet.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

/// The comments under the article in the reader (F11): first 5 threads, "Show more comments", the composer at the top
/// (or the guest invitation), empty / error states, new comments, and Reply bringing the composer back into view.
void main() {
  final article = engagedCard(1);

  setUpAll(() => registerFallbackValue(comment('fallback')));
  setUp(() => CommentClock.now = () => commentsNow);
  tearDown(() => CommentClock.now = DateTime.now);

  MockSessionCubit session({bool signedIn = true}) {
    final cubit = MockSessionCubit();
    whenListen(
      cubit,
      const Stream<SessionState>.empty(),
      initialState: signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
    );
    return cubit;
  }

  MockEngagementCubit engagement() {
    final cubit = MockEngagementCubit();
    whenListen(cubit, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    return cubit;
  }

  MockMentionSuggestionsCubit mentions() {
    final cubit = MockMentionSuggestionsCubit();
    whenListen(cubit, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    return cubit;
  }

  MockCommentsCubit comments(CommentsState state, {Stream<CommentsState> changes = const Stream.empty()}) {
    final cubit = MockCommentsCubit();
    whenListen(cubit, changes, initialState: state);
    when(() => cubit.load(any())).thenAnswer((_) async {});
    when(cubit.loadMore).thenAnswer((_) async {});
    when(cubit.retry).thenAnswer((_) async {});
    return cubit;
  }

  List<Comment> numbered(int from, int to) => [for (var i = from; i < to; i++) comment('c$i', body: 'Comment $i', minutesAgo: 60 + i)];

  CommentsState ready(List<Comment> items, {String? next, int? total, List<Comment> incoming = const []}) => CommentsState(
        status: CommentsStatus.ready,
        threads: [for (final c in items) CommentThread.of(c)],
        nextCursor: next,
        total: total ?? items.length,
        incoming: incoming,
      );

  /// The section as the reader shows it: a sliver of the reader's scroll view, [above] standing for the article and
  /// [below] for the sections after it.
  Future<void> pump(
    WidgetTester tester,
    CommentsCubit cubit, {
    bool signedIn = true,
    double above = 0,
    double below = 0,
    Size size = const Size(390, 844),
    Variant variant = const Variant(AppLocales.en, Brightness.light),
    double textScale = 1,
  }) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session(signedIn: signedIn)),
            BlocProvider<EngagementCubit>.value(value: engagement()),
          ],
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: above)),
                ArticleCommentsSection(article: article, comments: () => cubit, mentions: mentions),
                SliverToBoxAdapter(child: SizedBox(height: below)),
              ],
            ),
          ),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  Finder threads() => find.byType(CommentThreadView, skipOffstage: false);

  group('pages', () {
    late MockCommentsRepository repository;
    late MockRealtimeService realtime;

    setUp(() {
      repository = MockCommentsRepository();
      realtime = MockRealtimeService();
      stubNoCommentEvents(realtime);
    });

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

    testWidgets('the first 5 threads, then "Show more comments" adds 10 more a tap', (tester) async {
      when(() => repository.getComments('art-1', sort: CommentSort.top, cursor: null, limit: 5))
          .thenAnswer((_) async => Ok(CommentPage(items: numbered(0, 5), nextCursor: 'p2', total: 30)));
      when(() => repository.getComments('art-1', sort: CommentSort.top, cursor: 'p2', limit: 10))
          .thenAnswer((_) async => Ok(CommentPage(items: numbered(5, 15), nextCursor: 'p3', total: 30)));
      final cubit = build();

      await pump(tester, cubit, size: const Size(390, 4000));
      await tester.pump();

      expect(find.text('Comments (30)'), findsOneWidget);
      expect(threads(), findsNWidgets(5));
      expect(find.text('Comment 4'), findsOneWidget);
      final more = find.widgetWithText(OutlinedButton, 'Show more comments');
      expect(more, findsOneWidget);
      expect(tester.getSize(more).width, 390 - 2 * 16, reason: 'full width, inside the gutters');

      await tester.tap(more);
      await tester.pump();
      await tester.pump();

      expect(threads(), findsNWidgets(15));
      expect(find.text('Comment 14'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Comment 5')).dy,
        greaterThan(tester.getTopLeft(find.text('Comment 4')).dy),
        reason: 'appended under the first page',
      );
      expect(more, findsOneWidget, reason: 'there are more');
      verify(() => repository.getComments('art-1', sort: CommentSort.top, cursor: null, limit: 5)).called(1);
      verify(() => repository.getComments('art-1', sort: CommentSort.top, cursor: 'p2', limit: 10)).called(1);
    });

    testWidgets('the last page: no "Show more comments"', (tester) async {
      when(() => repository.getComments('art-1', sort: CommentSort.top, cursor: null, limit: 5))
          .thenAnswer((_) async => Ok(CommentPage(items: numbered(0, 3), total: 3)));
      await pump(tester, build());
      await tester.pump();

      expect(threads(), findsNWidgets(3));
      expect(find.text('Show more comments'), findsNothing);
    });
  });

  testWidgets('"Show more comments" spins while the page loads, then says why it failed and offers to try again',
      (tester) async {
    final changes = StreamController<CommentsState>.broadcast();
    addTearDown(changes.close);
    final first = ready(numbered(0, 5), next: 'p2', total: 30);
    final cubit = comments(first, changes: changes.stream);
    await pump(tester, cubit);

    changes.add(first.copyWith(loadingMore: true));
    await tester.pump();
    await tester.pump();
    final button = find.byType(OutlinedButton);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull, reason: 'one page at a time');
    expect(find.descendant(of: button, matching: find.byType(CircularProgressIndicator)), findsOneWidget);

    changes.add(first.copyWith(loadMoreFailure: () => const Failure(FailureCodes.networkOffline)));
    await tester.pump();
    await tester.pump();
    expect(find.text("You're offline. Check your connection."), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Try again'));
    await tester.pump();
    verify(cubit.loadMore).called(1);
  });

  testWidgets('signed in: the composer at the top of the section, above the threads, under the heading and the sort',
      (tester) async {
    await pump(tester, comments(ready([comment('c1', body: 'First')])));

    expect(find.byType(CommentComposer), findsOneWidget);
    expect(find.byType(CommentGuestPrompt), findsNothing);
    final heading = tester.getTopLeft(find.text('Comments (1)')).dy;
    final composer = tester.getTopLeft(find.byType(CommentComposer)).dy;
    expect(heading, lessThan(composer));
    expect(tester.getTopLeft(find.text('Newest')).dy, lessThan(composer));
    expect(composer, lessThan(tester.getTopLeft(find.text('First')).dy));
  });

  testWidgets('guests get the sign-in invitation in place of the composer', (tester) async {
    await pump(tester, comments(ready([comment('c1', body: 'First')])), signedIn: false);

    expect(find.byType(CommentGuestPrompt), findsOneWidget);
    expect(find.byType(CommentComposer), findsNothing);
    expect(find.text('Sign in to join the conversation.'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(CommentGuestPrompt)).dy, lessThan(tester.getTopLeft(find.text('First')).dy));
  });

  testWidgets('no comments yet: a short empty state under the composer, nothing to show more', (tester) async {
    await pump(tester, comments(ready(const [], total: 0)));

    expect(find.text('Comments (0)'), findsOneWidget);
    expect(find.text('No comments yet'), findsOneWidget);
    expect(find.text('Be the first to share what you think.'), findsOneWidget);
    expect(find.byType(CommentComposer), findsOneWidget);
    expect(find.text('Show more comments'), findsNothing);
  });

  testWidgets('loading: the skeleton, with the count the reader already knows', (tester) async {
    await pump(tester, comments(const CommentsState()));

    expect(find.byType(CommentsSkeleton), findsOneWidget);
    expect(find.text('Comments (4)'), findsOneWidget, reason: "the card's count while loading");
  });

  testWidgets('a first page that failed: the error with "Try again", which asks again', (tester) async {
    final cubit = comments(const CommentsState(status: CommentsStatus.failure, failure: Failure(FailureCodes.networkOffline)));
    await pump(tester, cubit);

    expect(find.text("You're offline. Check your connection."), findsOneWidget);
    expect(threads(), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    verify(cubit.retry).called(1);
  });

  testWidgets('"N new comments" sits at the top of the list, no floating pill; a tap shows them', (tester) async {
    final cubit = comments(ready([comment('c1', body: 'First')], incoming: [comment('c8'), comment('c9')]));
    await pump(tester, cubit);

    final button = find.text('2 new comments');
    expect(button, findsOneWidget);
    expect(tester.getTopLeft(button).dy, greaterThan(tester.getTopLeft(find.byType(CommentComposer)).dy));
    expect(tester.getTopLeft(button).dy, lessThan(tester.getTopLeft(find.text('First')).dy));
    await tester.tap(button);
    await tester.pump();
    verify(cubit.showIncoming).called(1);
  });

  testWidgets("new comments go straight in only while the list's top is on screen (setNearTop)", (tester) async {
    final cubit = comments(ready(numbered(0, 5)));
    // The article above it is two screens long; the related articles under it too.
    await pump(tester, cubit, above: 1600, below: 1600);
    await tester.pump();
    verify(() => cubit.setNearTop(false)).called(greaterThanOrEqualTo(1));
    verifyNever(() => cubit.setNearTop(true));

    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -1500));
    await tester.pump();
    expect(find.text('Comments (5)'), findsOneWidget, reason: 'the section is on screen');
    verify(() => cubit.setNearTop(true)).called(greaterThanOrEqualTo(1));

    await tester.drag(scrollable, const Offset(0, -1200));
    await tester.pump();
    verify(() => cubit.setNearTop(false)).called(greaterThanOrEqualTo(1));
  });

  testWidgets('Reply on a comment further down brings the composer back into view and focuses it', (tester) async {
    final changes = StreamController<CommentsState>.broadcast();
    addTearDown(changes.close);
    final state = ready(numbered(0, 12));
    final cubit = comments(state, changes: changes.stream);
    when(() => cubit.startReply(any())).thenAnswer((invocation) {
      changes.add(state.copyWith(target: () => ComposerTarget.reply(invocation.positionalArguments.single as Comment)));
    });
    await pump(tester, cubit, below: 400);

    final last = find.text('Comment 11');
    await tester.scrollUntilVisible(last, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final composer = find.byType(CommentComposer, skipOffstage: false);
    expect(tester.getRect(composer).bottom, lessThanOrEqualTo(0), reason: 'scrolled away, above the screen');

    final tile = find.ancestor(of: last, matching: find.byType(CommentTile));
    await tester.tap(find.descendant(of: tile, matching: find.text('Reply')));
    await tester.pumpAndSettle();

    verify(() => cubit.startReply(any(that: isA<Comment>().having((c) => c.id, 'id', 'c11')))).called(1);
    expect(tester.getRect(composer).top, greaterThanOrEqualTo(0), reason: 'back on screen');
    expect(tester.getRect(composer).bottom, lessThanOrEqualTo(844));
    expect(find.text('Replying to Omar Khaled'), findsOneWidget);
    final field = tester.widget<TextField>(find.descendant(of: composer, matching: find.byType(TextField)));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.text, '@omar_k ');
  });

  for (final variant in Variant.all) {
    testWidgets('the section holds at 200% text ${variant.name}', (tester) async {
      await pump(
        tester,
        comments(ready(numbered(0, 5), next: 'p2', total: 1234, incoming: [comment('c9')])),
        size: const Size(360, 2400),
        variant: variant,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(variant.locale == AppLocales.en ? 'Show more comments' : 'عرض مزيد من التعليقات'), findsOneWidget);
    });
  }
}
