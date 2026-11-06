@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_composer.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/comment_fixtures.dart';
import '../helpers/fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

/// Comments (F11) in ar/light and en/dark (SPEC §27): every comment state (compact bubbles with the writer's title,
/// "· Follow", the time and "⋯"; replies paged with "show N more replies" and "Hide replies"), the comment box (empty,
/// a reply with its @mention and ✕, near its limit, the emoji picker), the empty sheet, and the sheet with the
/// "N new comments" pill as a guest sees it.
void main() {
  setUp(() {
    CommentClock.now = () => commentsNow;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => CommentClock.now = DateTime.now);

  final noop = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});

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

  MockCommentsCubit comments(CommentsState state) {
    final cubit = MockCommentsCubit();
    whenListen(cubit, const Stream<CommentsState>.empty(), initialState: state);
    return cubit;
  }

  MockFollowsCubit follows() {
    final cubit = MockFollowsCubit();
    whenListen(cubit, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    return cubit;
  }

  MockMentionSuggestionsCubit mentions() {
    final cubit = MockMentionSuggestionsCubit();
    whenListen(cubit, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    return cubit;
  }

  Future<void> pump(
    WidgetTester tester,
    Variant variant,
    Widget child, {
    required Size size,
    CommentsState state = const CommentsState(status: CommentsStatus.ready),
    bool signedIn = true,
  }) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session(signedIn: signedIn)),
          BlocProvider<EngagementCubit>.value(value: engagement()),
          BlocProvider<FollowsCubit>.value(value: follows()),
          BlocProvider<CommentsCubit>.value(value: comments(state)),
          BlocProvider<MentionSuggestionsCubit>.value(value: mentions()),
        ],
        child: child,
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  const monaMention = CommentMention(userId: 'w-1', username: 'mona_dev');
  const saraMention = CommentMention(userId: 'w-3', username: 'sara_net');

  final states = <(CommentThread, Set<String>)>[
    // Normal: a resolved mention, an unresolved @word, English inside Arabic, line breaks.
    (
      CommentThread.of(comment(
        'c1',
        author: omarTitled,
        body: 'شكراً @mona_dev على الشرح! الـ Dependency Injection في .NET بقى واضح.\nبس @ghost سأل عن Scoped.',
        mentions: const [monaMention],
        likeCount: 3,
        minutesAgo: 120,
      )),
      const <String>{},
    ),
    // The writer: "الكاتب", pinned, edited, liked; an English comment in its own direction.
    (
      CommentThread.of(comment(
        'c2',
        author: monaTitled,
        body: "Thanks everyone! I'll write a follow-up about Scoped vs Transient.",
        isArticleAuthor: true,
        isPinned: true,
        edited: true,
        likedByMe: true,
        likeCount: 12,
        minutesAgo: 60 * 26,
      )),
      const <String>{},
    ),
    // With replies: the first one, and one that just arrived (highlighted, shown although older ones are hidden);
    // "show 2 more replies" and "Hide replies".
    (
      CommentThread.of(comment(
        'c3',
        author: sara,
        isFollowingAuthor: true,
        body: 'حد جرّب الكلام ده مع EF Core؟',
        replyCount: 4,
        likeCount: 1,
        minutesAgo: 300,
        replies: [
          comment('r1', parentId: 'c3', author: omar, body: '@sara_net أيوه، شغال تمام.', mentions: const [saraMention], minutesAgo: 240),
          comment('r2', parentId: 'c3', author: mona, isArticleAuthor: true, body: 'Yes, with AddDbContext it is Scoped by default.', minutesAgo: 3),
        ],
      )).copyWith(alwaysShown: const {'r2'}),
      const {'r2'},
    ),
    // A deleted comment kept for its replies.
    (
      CommentThread.of(placeholder('c4', replyCount: 1, replies: [comment('r3', parentId: 'c4', body: 'كان سؤال حلو.', minutesAgo: 90)])),
      const <String>{},
    ),
    // Hidden by moderators (a reader sees the placeholder).
    (CommentThread.of(placeholder('c5', deleted: false)), const <String>{}),
    // Hidden, seen by its author or a moderator: the full text with a notice.
    (CommentThread.of(comment('c6', author: sara, body: 'تعليق اتبلّغ عنه كذا مرة.', isHidden: true, canModerate: true, minutesAgo: 600)), const <String>{}),
    // A deleted account.
    (CommentThread.of(comment('c7', author: null, body: 'مقال ممتاز، شكراً.', likeCount: 2, minutesAgo: 60 * 24 * 10)), const <String>{}),
    // The viewer's comment on its way.
    (CommentThread.of(comment('c8', author: viewer, body: 'لسه باعته دلوقتي', minutesAgo: 0)), const <String>{}),
  ];

  String longText() {
    const sentence = 'الكود ده بيشتغل كويس مع Clean Architecture وكمان مع CQRS. ';
    return (sentence * 40).substring(0, 1850);
  }

  for (final variant in Variant.golden) {
    testWidgets('comment items ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(
          // On the comments sheet's surface, as in the app.
          body: Builder(
            builder: (context) => ColoredBox(
              color: context.colors.surface,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final (thread, highlighted) in states)
                    CommentThreadView(thread: thread, callbacks: noop, highlighted: highlighted, pendingIds: const {'c8'}),
                ],
              ),
            ),
          ),
        ),
        size: const Size(390, 1480),
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/comment_items_${variant.name}.png'));
    });

    testWidgets('comment composer ${variant.name}', (tester) async {
      final reply = comment('r1', parentId: 'c3', author: omar);
      final top = comment('c1', author: omarTitled);
      await pump(
        tester,
        variant,
        Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const CommentComposer(),
              const SizedBox(height: 24),
              // A reply: "@omar_k " is already in the box (F11), with the ✕ that cancels the reply.
              BlocProvider<CommentsCubit>.value(
                value: comments(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(top))),
                child: const CommentComposer(initialText: '@omar_k '),
              ),
              const SizedBox(height: 24),
              BlocProvider<CommentsCubit>.value(
                value: comments(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(reply))),
                child: CommentComposer(initialText: longText()),
              ),
              const SizedBox(height: 24),
              const CommentGuestPrompt(),
            ],
          ),
        ),
        size: const Size(390, 600),
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/comment_composer_${variant.name}.png'));
    });

    testWidgets('comment box with the emoji picker ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: CommentComposer(initialText: 'تمام 👍'))),
        size: const Size(390, 520),
      );
      await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tag_faces));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/comment_emoji_picker_${variant.name}.png'));
    });

    testWidgets('comments empty ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(body: SafeArea(child: CommentsView(article: engagedCard(1)))),
        state: const CommentsState(status: CommentsStatus.ready, total: 0),
        size: const Size(390, 640),
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/comments_empty_${variant.name}.png'));
    });

    testWidgets('comments sheet with new comments ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(body: SafeArea(child: CommentsView(article: engagedCard(1)))),
        state: CommentsState(
          status: CommentsStatus.ready,
          sort: CommentSort.newest,
          threads: [states[0].$1, states[2].$1],
          total: 7,
          incoming: [comment('c9', minutesAgo: 0), comment('c10', minutesAgo: 0)],
        ),
        signedIn: false,
        size: const Size(390, 844),
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/comments_sheet_${variant.name}.png'));
    });
  }
}
