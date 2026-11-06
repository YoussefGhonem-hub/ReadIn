import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/domain/usecases/comment_usecases.dart';
import 'package:readin/features/comments/presentation/cubit/comment_drafts.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_composer.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

/// Unsent comments (F34): the text typed in an article's comments stays while the sheet is closed, until it is sent,
/// and belongs to the account that typed it.
void main() {
  late StreamController<SessionState> sessions;
  late MockSessionCubit session;

  setUp(() {
    sessions = StreamController<SessionState>.broadcast();
    session = MockSessionCubit();
    whenListen(session, sessions.stream, initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
  });

  tearDown(() => sessions.close());

  test('keeps the text per article; blank text forgets it', () async {
    final drafts = CommentDrafts(session);
    addTearDown(drafts.dispose);

    drafts
      ..put('art-1', 'لسه بكتب @mona_dev')
      ..put('art-2', 'Draft two');
    expect(drafts.of('art-1'), 'لسه بكتب @mona_dev');
    expect(drafts.of('art-2'), 'Draft two');
    expect(drafts.of('art-3'), '');

    drafts.put('art-2', '   ');
    expect(drafts.of('art-2'), '');
  });

  test('another account, or signing out, starts with none', () async {
    final drafts = CommentDrafts(session);
    addTearDown(drafts.dispose);
    drafts.put('art-1', 'mine');

    sessions.add(const SessionState(status: SessionStatus.authenticated, me: sampleMe)); // same account: kept
    await Future<void>.delayed(Duration.zero);
    expect(drafts.of('art-1'), 'mine');

    sessions.add(const SessionState(status: SessionStatus.authenticated, me: Me(id: 'u-2', phoneNumber: '+12025550111', displayName: 'Other', username: 'other', onboardingCompleted: true)));
    await Future<void>.delayed(Duration.zero);
    expect(drafts.of('art-1'), '');
  });

  test("the comments cubit reads and keeps its article's draft", () async {
    final drafts = CommentDrafts(session);
    addTearDown(drafts.dispose);
    final repository = MockCommentsRepository();
    final realtime = MockRealtimeService();
    when(() => realtime.commentEvents('art-1')).thenAnswer((_) => const Stream<CommentEvent>.empty());
    when(() => repository.getComments('art-1', sort: CommentSort.top, cursor: null, limit: 5))
        .thenAnswer((_) async => const Ok(CommentPage(items: [], total: 0)));
    CommentsCubit build() => CommentsCubit(
          GetComments(repository),
          PostComment(repository),
          EditComment(repository),
          DeleteComment(repository),
          SetCommentLiked(repository),
          SetCommentPinned(repository),
          ModerateComment(repository),
          realtime,
          drafts: drafts,
        );

    final first = build();
    await first.load('art-1');
    first.saveDraft('half a thought');
    await first.close();

    final second = build();
    addTearDown(second.close);
    await second.load('art-1');
    expect(second.draft, 'half a thought');
  });

  testWidgets('the composer opens with the unsent text and keeps what is typed', (tester) async {
    final comments = MockCommentsCubit();
    whenListen(comments, const Stream<CommentsState>.empty(), initialState: const CommentsState(status: CommentsStatus.ready));
    when(() => comments.draft).thenReturn('Unsent words');
    final mentions = MockMentionSuggestionsCubit();
    whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    when(() => mentions.search(any())).thenReturn(null);

    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<CommentsCubit>.value(value: comments),
          BlocProvider<MentionSuggestionsCubit>.value(value: mentions),
        ],
        child: const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: CommentComposer())),
      ),
      variant: const Variant(AppLocales.en, Brightness.light),
    ));

    expect(find.text('Unsent words'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Unsent words, and more');
    verify(() => comments.saveDraft('Unsent words, and more')).called(greaterThanOrEqualTo(1));
  });
}
