import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/widgets/reader_action_bar.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_composer.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);
const _ar = Variant(AppLocales.ar, Brightness.light);

void main() {
  final article = engagedCard(1);

  setUpAll(() {
    registerFallbackValue(viewer);
    registerFallbackValue(ReportReason.spam);
  });

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

  MockCommentsCubit comments(CommentsState state, {Stream<CommentsState> changes = const Stream.empty()}) {
    final cubit = MockCommentsCubit();
    whenListen(cubit, changes, initialState: state);
    when(() => cubit.load(any())).thenAnswer((_) async {});
    return cubit;
  }

  MockMentionSuggestionsCubit mentions([List<Author> users = const []]) {
    final cubit = MockMentionSuggestionsCubit();
    whenListen(cubit, const Stream<List<Author>>.empty(), initialState: users);
    return cubit;
  }

  CommentsState ready(List<Comment> items, {List<Comment> incoming = const []}) => CommentsState(
        status: CommentsStatus.ready,
        threads: [for (final c in items) CommentThread.of(c)],
        total: items.length,
        incoming: incoming,
      );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required MockCommentsCubit cubit,
    MockMentionSuggestionsCubit? suggestions,
    bool signedIn = true,
    Variant variant = _en,
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session(signedIn: signedIn)),
          BlocProvider<EngagementCubit>.value(value: engagement()),
          BlocProvider<CommentsCubit>.value(value: cubit),
          BlocProvider<MentionSuggestionsCubit>.value(value: suggestions ?? mentions()),
        ],
        child: Scaffold(body: child),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  testWidgets("the action bar's comment count opens the comments", (tester) async {
    final cubit = comments(ready([comment('c1', body: 'Great read')]));
    getIt
      ..registerFactory<CommentsCubit>(() => cubit)
      ..registerFactory<MentionSuggestionsCubit>(mentions);
    addTearDown(() {
      getIt
        ..unregister<CommentsCubit>()
        ..unregister<MentionSuggestionsCubit>();
    });
    final follows = MockFollowsCubit();
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());

    usePhoneSurface(tester);
    // Above the app, as in ReadInApp: the sheet is a route of its own.
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: session()),
        BlocProvider<EngagementCubit>.value(value: engagement()),
        BlocProvider<FollowsCubit>.value(value: follows),
      ],
      child: testApp(
        Scaffold(body: Align(alignment: Alignment.bottomCenter, child: ReaderActionBar(article: article))),
        variant: _en,
      ),
    ));
    await tester.tap(find.byType(CommentCount));
    await tester.pumpAndSettle();

    expect(find.text('Comments (1)'), findsOneWidget);
    expect(find.text('Great read'), findsOneWidget);
    verify(() => cubit.load(article.id)).called(1);
  });

  testWidgets('a comment is laid out in its own direction; only resolved mentions are styled', (tester) async {
    await pump(
      tester,
      CommentTile(
        comment: comment(
          'c1',
          body: 'Thanks @mona_dev and @ghost!',
          mentions: const [CommentMention(userId: 'w-1', username: 'mona_dev')],
        ),
        callbacks: CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {}),
      ),
      cubit: comments(const CommentsState()),
      variant: _ar,
    );

    final text = tester.widget<RichText>(find.descendant(of: find.byType(CommentBody), matching: find.byType(RichText)));
    expect(text.textDirection, TextDirection.ltr, reason: 'an English comment in the Arabic UI');
    final spans = <TextSpan>[];
    text.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final styled = [for (final s in spans) if (s.style?.fontWeight == FontWeight.w600) s.text!];
    expect(styled.single, contains('@mona_dev'));
    expect(spans.where((s) => s.text!.contains('@ghost')).single.style, isNull);
  });

  testWidgets('comments, the sheet chrome and the composer hold at 200% text', (tester) async {
    usePhoneSurface(tester, size: const Size(360, 640));
    final cubit = comments(CommentsState(
      status: CommentsStatus.ready,
      total: 12,
      threads: [
        CommentThread.of(comment(
          'c1',
          author: mona,
          body: 'شكراً @omar_k على السؤال! الـ Scoped lifetime بيتعمل مرة لكل request.',
          isArticleAuthor: true,
          isPinned: true,
          edited: true,
          likeCount: 120,
          replyCount: 7,
          replies: [comment('r1', parentId: 'c1', author: sara, body: 'Thanks a lot!', isHidden: true, canModerate: true)],
        )),
        CommentThread.of(comment('c2', author: null, body: 'مقال ممتاز')),
      ],
      incoming: [comment('c3')],
    ));
    await tester.pumpWidget(testApp(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: 2,
        maxScaleFactor: 2,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session()),
            BlocProvider<EngagementCubit>.value(value: engagement()),
            BlocProvider<CommentsCubit>.value(value: cubit),
            BlocProvider<MentionSuggestionsCubit>.value(value: mentions()),
          ],
          child: Scaffold(body: CommentsView(article: article)),
        ),
      ),
      variant: _ar,
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('composer', () {
    testWidgets('send stays off while empty; the counter shows only in the last 200 characters', (tester) async {
      await pump(tester, const Align(alignment: Alignment.bottomCenter, child: CommentComposer()), cubit: comments(const CommentsState()));
      IconButton send() => tester.widget<IconButton>(find.byType(IconButton).last);

      expect(send().onPressed, isNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(send().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'x' * 1799);
      await tester.pump();
      expect(find.text('1799/2000'), findsNothing);
      expect(send().onPressed, isNotNull);

      await tester.enterText(find.byType(TextField), 'x' * 1801);
      await tester.pump();
      expect(find.text('1801/2000'), findsOneWidget);
    });

    testWidgets('replying to a reply pre-fills @handle; cancelling clears it', (tester) async {
      final reply = comment('r1', parentId: 'c1', author: omar);
      final cubit = comments(
        const CommentsState(status: CommentsStatus.ready),
        changes: Stream.value(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(reply))),
      );
      await pump(tester, const Align(alignment: Alignment.bottomCenter, child: CommentComposer()), cubit: cubit);
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '@omar_k ');
      expect(find.text('Replying to Omar Khaled'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      verify(cubit.clearTarget).called(1);
    });

    testWidgets('typing @ suggests people; a tap inserts @username', (tester) async {
      final suggestions = mentions(const [mona]);
      await pump(
        tester,
        const Align(alignment: Alignment.bottomCenter, child: CommentComposer()),
        cubit: comments(const CommentsState()),
        suggestions: suggestions,
      );

      await tester.enterText(find.byType(TextField), 'شكراً @mo');
      await tester.pump();
      verify(() => suggestions.search('mo')).called(1);
      expect(find.byType(MentionSuggestionList), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(MentionSuggestionList), matching: find.byType(ListTile)));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'شكراً @mona_dev ');
    });

    for (final (code, message) in [
      (FailureCodes.commentDuplicate, 'You just posted the same comment.'),
      (FailureCodes.rateLimited, "You're commenting too fast. Wait a minute and try again."),
      (FailureCodes.commentArticleLimit, "You've commented a lot on this article. Try again later."),
    ]) {
      testWidgets('a refused comment ($code) comes back to the field and says why', (tester) async {
        final cubit = comments(const CommentsState(status: CommentsStatus.ready));
        when(() => cubit.submit(any(), author: any(named: 'author'))).thenAnswer((_) async => Failure(code));
        await pump(tester, const Align(alignment: Alignment.bottomCenter, child: CommentComposer()), cubit: cubit);

        await tester.enterText(find.byType(TextField), 'سلام');
        await tester.pump();
        await tester.tap(find.byTooltip('Send'));
        await tester.pump();

        expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'سلام');
        expect(find.text(message), findsOneWidget);
        final author = verify(() => cubit.submit('سلام', author: captureAny(named: 'author'))).captured.single as Author;
        expect(author.id, sampleMe.id);
      });
    }

    testWidgets('a refused reply to a reply comes back whole, not just its @handle', (tester) async {
      final reply = comment('r1', parentId: 'c1', author: omar);
      final replying = CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(reply));
      final changes = StreamController<CommentsState>.broadcast();
      addTearDown(changes.close);
      final cubit = comments(const CommentsState(status: CommentsStatus.ready), changes: changes.stream);
      // As the cubit does: the target goes while sending and comes back with the failure.
      when(() => cubit.submit(any(), author: any(named: 'author'))).thenAnswer((_) async {
        changes
          ..add(const CommentsState(status: CommentsStatus.ready))
          ..add(replying);
        // The listener sees the restored target before the failure comes back.
        for (var i = 0; i < 10; i++) {
          await Future<void>.value();
        }
        return const Failure(FailureCodes.commentDuplicate);
      });
      await pump(tester, const Align(alignment: Alignment.bottomCenter, child: CommentComposer()), cubit: cubit);
      changes.add(replying);
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '@omar_k ');

      await tester.enterText(find.byType(TextField), '@omar_k عندك حق');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '@omar_k عندك حق');
    });
  });

  group('the comments sheet', () {
    Future<MockCommentsCubit> pumpSheet(WidgetTester tester, CommentsState state, {bool signedIn = true}) async {
      final cubit = comments(state);
      await pump(tester, CommentsView(article: article), cubit: cubit, signedIn: signedIn);
      return cubit;
    }

    testWidgets('guests get a sign-in invitation instead of the composer, and liking asks them to sign in', (tester) async {
      final cubit = await pumpSheet(tester, ready([comment('c1', body: 'Nice')]), signedIn: false);

      expect(find.byType(CommentGuestPrompt), findsOneWidget);
      expect(find.byType(CommentComposer), findsNothing);

      await tester.tap(find.byType(CommentLikeButton));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      verifyNever(() => cubit.toggleLike(any()));
    });

    testWidgets('a like goes to the cubit; a refusal says why', (tester) async {
      final cubit = await pumpSheet(tester, ready([comment('c1', body: 'Nice')]));
      when(() => cubit.toggleLike('c1')).thenAnswer((_) async => const Failure(FailureCodes.commentNotAvailable));

      await tester.tap(find.byType(CommentLikeButton));
      await tester.pump();

      verify(() => cubit.toggleLike('c1')).called(1);
      expect(find.text('This comment was deleted or hidden.'), findsOneWidget);
    });

    testWidgets('report: a reason and details, then thanks', (tester) async {
      final cubit = await pumpSheet(tester, ready([comment('c1', body: 'Spam link')]));
      when(() => cubit.report(any(), any(), details: any(named: 'details'))).thenAnswer((_) async => null);

      await tester.tap(find.byTooltip('Comment options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Send report'), findsOneWidget);

      await tester.tap(find.text('Harassment'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'تفاصيل');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      verify(() => cubit.report('c1', ReportReason.harassment, details: 'تفاصيل')).called(1);
      expect(find.text("Thanks, we'll review it."), findsOneWidget);
    });

    testWidgets('deleting your comment asks first', (tester) async {
      final cubit = await pumpSheet(tester, ready([comment('c1', body: 'Mine', own: true)]));
      when(() => cubit.delete('c1')).thenAnswer((_) async => null);

      await tester.tap(find.byTooltip('Comment options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this comment?'), findsOneWidget);
      verifyNever(() => cubit.delete(any()));

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      verify(() => cubit.delete('c1')).called(1);
      expect(find.text('Comment deleted'), findsOneWidget);
    });

    testWidgets('only the actions a comment allows are in its menu', (tester) async {
      await pumpSheet(tester, ready([comment('c1', body: 'Mine', own: true, canModerate: true, canPin: true)]));

      await tester.tap(find.byTooltip('Comment options'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('Hide (moderator)'), findsOneWidget);
      expect(find.text('Report'), findsNothing, reason: 'your own comment');
      expect(find.text('Delete (moderator)'), findsNothing, reason: 'own delete covers it');
    });

    testWidgets('the "N new comments" pill shows them', (tester) async {
      final cubit = await pumpSheet(tester, ready([comment('c1')], incoming: [comment('c5'), comment('c6'), comment('c7')]));

      await tester.tap(find.text('3 new comments'));
      await tester.pump();

      verify(cubit.showIncoming).called(1);
    });

    testWidgets('"show N more replies" asks for the thread', (tester) async {
      final cubit = await pumpSheet(
        tester,
        ready([
          comment('c1', replyCount: 5, replies: [comment('r1', parentId: 'c1'), comment('r2', parentId: 'c1')]),
        ]),
      );
      when(() => cubit.loadMoreReplies(any())).thenAnswer((_) async {});

      await tester.tap(find.text('Show 3 more replies'));
      await tester.pump();

      verify(() => cubit.loadMoreReplies('c1')).called(1);
    });

    testWidgets("one comment count: the page's total reaches the action bar, live counts come back", (tester) async {
      final store = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(MockSavedRepository()));
      addTearDown(store.close);
      final changes = StreamController<CommentsState>.broadcast();
      addTearDown(changes.close);
      final cubit = comments(const CommentsState(), changes: changes.stream);

      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session()),
            BlocProvider<EngagementCubit>.value(value: store),
            BlocProvider<CommentsCubit>.value(value: cubit),
            BlocProvider<MentionSuggestionsCubit>.value(value: mentions()),
          ],
          child: Scaffold(body: CommentsView(article: article)),
        ),
        variant: _en,
      ));
      expect(find.text('Comments (4)'), findsOneWidget, reason: "the card's count while loading");

      changes.add(CommentsState(status: CommentsStatus.ready, threads: [CommentThread.of(comment('c1'))], total: 6));
      await tester.pump();
      expect(store.of(article).commentCount, 6);
      expect(find.text('Comments (6)'), findsOneWidget);

      store.applyLive(article.id, const LiveArticleCounts(commentCount: 9));
      await tester.pump();
      verify(() => cubit.syncTotal(9)).called(1);
    });
  });
}
