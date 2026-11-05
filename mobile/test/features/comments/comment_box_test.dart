import 'package:bloc_test/bloc_test.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/data/models/comment_models.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_composer.dart';
import 'package:readin/features/comments/presentation/widgets/comment_emoji_picker.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/shared/widgets/badges.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);
const _ar = Variant(AppLocales.ar, Brightness.light);

/// The comment box and rows (F11, user decisions 2026-11-05): avatar + rounded field with the emoji button and the send
/// icon inside it, the emoji picker, the reply box with its ✕ and the @mention with the caret after it; rows with the
/// writer's title instead of @username, "Follow" and "⋯", and one row of actions.
void main() {
  late MockFollowRepository followRepository;
  late FollowsCubit follows;

  setUpAll(() => registerFallbackValue(viewer));

  setUp(() {
    CommentClock.now = () => commentsNow;
    SharedPreferences.setMockInitialValues({});
    followRepository = MockFollowRepository();
    follows = FollowsCubit(SetFollowing(followRepository));
  });
  tearDown(() {
    CommentClock.now = DateTime.now;
    return follows.close();
  });

  MockCommentsCubit comments(CommentsState state, {Stream<CommentsState> changes = const Stream.empty()}) {
    final cubit = MockCommentsCubit();
    whenListen(cubit, changes, initialState: state);
    when(() => cubit.load(any())).thenAnswer((_) async {});
    return cubit;
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required MockCommentsCubit cubit,
    bool signedIn = true,
    Variant variant = _en,
  }) async {
    usePhoneSurface(tester);
    final session = MockSessionCubit();
    whenListen(
      session,
      const Stream<SessionState>.empty(),
      initialState:
          signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
    );
    final engagement = MockEngagementCubit();
    whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    final mentions = MockMentionSuggestionsCubit();
    whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<CommentsCubit>.value(value: cubit),
          BlocProvider<MentionSuggestionsCubit>.value(value: mentions),
        ],
        child: Scaffold(body: child),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  Widget box() => const Align(alignment: Alignment.bottomCenter, child: CommentComposer());
  TextField field(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField));
  IconButton send(WidgetTester tester) => tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded));

  group('the comment box', () {
    testWidgets('your avatar, the rounded field, and the emoji and send icons inside it; send is off until there is text',
        (tester) async {
      await pump(tester, box(), cubit: comments(const CommentsState()));

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text('Add a comment…'), findsOneWidget);
      expect(find.byTooltip('Emoji'), findsOneWidget);
      expect(find.byTooltip('Send'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Post'), findsNothing, reason: 'no text button');
      // Both icons sit inside the field's outline, after the text.
      final fieldRect = tester.getRect(find.ancestor(of: find.byType(TextField), matching: find.byType(DecoratedBox)).first);
      for (final icon in [Icons.emoji_emotions_outlined, Icons.send_rounded]) {
        expect(fieldRect.contains(tester.getCenter(find.byIcon(icon))), isTrue, reason: '$icon');
      }
      expect(tester.getCenter(find.byType(UserAvatar)).dx, lessThan(fieldRect.left), reason: 'the avatar comes first (LTR)');

      expect(send(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '  ');
      await tester.pump();
      expect(send(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '👍');
      await tester.pump();
      expect(send(tester).onPressed, isNotNull, reason: 'an emoji alone is a comment');
    });

    testWidgets('the emoji button opens the picker instead of the keyboard; an emoji goes in at the caret', (tester) async {
      await pump(tester, box(), cubit: comments(const CommentsState()));
      await tester.enterText(find.byType(TextField), 'Great read');
      field(tester).controller!.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await tester.tap(find.byTooltip('Emoji'));
      await tester.pumpAndSettle();
      expect(find.byType(CommentEmojiPicker), findsOneWidget);
      expect(find.byType(EmojiPicker), findsOneWidget);
      expect(field(tester).focusNode!.hasFocus, isFalse, reason: 'the keyboard went away');
      expect(find.byTooltip('Back to the keyboard'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tag_faces));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀').first);
      await tester.pump();
      expect(field(tester).controller!.text, 'Great😀 read');
      expect(send(tester).onPressed, isNotNull);

      await tester.tap(find.byTooltip('Back to the keyboard'));
      await tester.pumpAndSettle();
      expect(find.byType(EmojiPicker), findsNothing);
      expect(field(tester).focusNode!.hasFocus, isTrue);
    });

    testWidgets('back closes the emoji picker first; tapping the field brings the keyboard back', (tester) async {
      await pump(tester, box(), cubit: comments(const CommentsState()));
      await tester.tap(find.byTooltip('Emoji'));
      await tester.pumpAndSettle();
      expect(find.byType(EmojiPicker), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EmojiPicker), findsNothing);
      expect(find.byType(CommentComposer), findsOneWidget);

      await tester.tap(find.byTooltip('Emoji'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(EmojiPicker), findsNothing);
    });

    testWidgets("reply: @username of the person replied to with the caret after it; the box's ✕ cancels the reply",
        (tester) async {
      final semantics = tester.ensureSemantics();
      final top = comment('c1', author: omarTitled);
      final cubit = comments(
        const CommentsState(status: CommentsStatus.ready),
        changes: Stream.value(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(top))),
      );
      await pump(tester, box(), cubit: cubit);
      await tester.pump();

      final controller = field(tester).controller!;
      expect(controller.text, '@omar_k ', reason: 'a reply to a top-level comment mentions its writer too');
      expect(controller.selection, const TextSelection.collapsed(offset: 8), reason: 'the caret right after it');
      expect(field(tester).focusNode!.hasFocus, isTrue);
      expect(tester.getSemantics(find.byIcon(Icons.close_rounded)), isSemantics(tooltip: 'Cancel reply', isButton: true, hasTapAction: true));
      expect(find.byTooltip('Cancel reply'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel reply'));
      await tester.pump();
      expect(controller.text, isEmpty);
      verify(cubit.clearTarget).called(1);
      semantics.dispose();
    });

    testWidgets('replying to yourself puts no mention', (tester) async {
      final mine = comment('c1', author: viewer, own: true);
      await pump(
        tester,
        box(),
        cubit: comments(
          const CommentsState(status: CommentsStatus.ready),
          changes: Stream.value(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(mine))),
        ),
      );
      await tester.pump();
      expect(field(tester).controller!.text, isEmpty);
      expect(find.text('Add a reply…'), findsOneWidget);
    });

    testWidgets('editing: the ✕ is "Cancel editing"', (tester) async {
      final mine = comment('c1', author: viewer, own: true, body: 'My comment');
      await pump(
        tester,
        box(),
        cubit: comments(
          const CommentsState(status: CommentsStatus.ready),
          changes: Stream.value(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.edit(mine))),
        ),
      );
      await tester.pump();
      expect(field(tester).controller!.text, 'My comment');
      expect(find.byTooltip('Cancel editing'), findsOneWidget);
      expect(find.byTooltip('Save'), findsOneWidget);
    });

    testWidgets('Arabic: "اكتب تعليق…", "إيموجي" and "إلغاء الرد"', (tester) async {
      final top = comment('c1', author: omar);
      await pump(tester, box(), cubit: comments(const CommentsState()), variant: _ar);
      expect(find.text('اكتب تعليق…'), findsOneWidget);
      expect(find.byTooltip('إيموجي'), findsOneWidget);
      await pump(
        tester,
        box(),
        cubit: comments(
          const CommentsState(status: CommentsStatus.ready),
          changes: Stream.value(CommentsState(status: CommentsStatus.ready, target: ComposerTarget.reply(top))),
        ),
        variant: _ar,
      );
      await tester.pump();
      expect(find.byTooltip('إلغاء الرد'), findsOneWidget);
      // RTL: the avatar is on the right.
      final fieldRect = tester.getRect(find.ancestor(of: find.byType(TextField), matching: find.byType(DecoratedBox)).first);
      expect(tester.getCenter(find.byType(UserAvatar)).dx, greaterThan(fieldRect.right));
    });
  });

  test("CommentDto: isFollowingAuthor and the author's headline", () {
    final parsed = CommentModel.fromJson({
      'id': 'c1',
      'articleId': 'a1',
      'body': 'Nice',
      'createdAt': '2026-11-02T10:00:00Z',
      'author': {'id': 'w-2', 'displayName': 'Omar', 'username': 'omar_k', 'headline': 'Backend | .NET'},
      'isFollowingAuthor': true,
    }).toEntity();
    expect(parsed.isFollowingAuthor, isTrue);
    expect(parsed.author!.headline, 'Backend | .NET');
    final old = CommentModel.fromJson({'id': 'c1', 'articleId': 'a1', 'createdAt': '2026-11-02T10:00:00Z'}).toEntity();
    expect(old.isFollowingAuthor, isFalse);
  });

  group('the comment row', () {
    final callbacks = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});

    testWidgets("the writer's title under the name instead of @username; like, reply and the time in one row", (tester) async {
      await pump(tester, CommentTile(comment: comment('c1', author: omarTitled, likeCount: 3), callbacks: callbacks), cubit: comments(const CommentsState()));

      expect(find.text(omarTitled.headline!), findsOneWidget);
      final title = tester.widget<Text>(find.text(omarTitled.headline!));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.textContaining('@omar_k'), findsNothing);
      expect(tester.getRect(find.text(omarTitled.headline!)).top, greaterThanOrEqualTo(tester.getRect(find.text('Omar Khaled')).bottom - 1));

      final like = tester.getCenter(find.byType(CommentLikeButton));
      final reply = tester.getCenter(find.text('Reply'));
      final time = tester.getCenter(find.text('30 min ago'));
      expect((like.dy - reply.dy).abs(), lessThan(2));
      expect((reply.dy - time.dy).abs(), lessThan(2));
      expect(like.dx < reply.dx && reply.dx < time.dx, isTrue);

      await pump(tester, CommentTile(comment: comment('c2', author: omar), callbacks: callbacks), cubit: comments(const CommentsState()));
      expect(find.textContaining('@omar_k'), findsNothing, reason: 'no title: nothing in its place');
    });

    testWidgets('Follow while you don\'t follow them, never on your own comment; following updates every row', (tester) async {
      when(() => followRepository.follow('w-2')).thenAnswer((_) async => const Ok(FollowState(isFollowing: true, followerCount: 10)));
      await pump(
        tester,
        ListView(children: [
          CommentTile(comment: comment('c1', author: omarTitled), callbacks: callbacks),
          CommentTile(comment: comment('c2', author: omar), callbacks: callbacks),
          CommentTile(comment: comment('c3', author: viewer, own: true), callbacks: callbacks),
          CommentTile(comment: comment('c4', author: mona, isFollowingAuthor: true), callbacks: callbacks),
        ]),
        cubit: comments(const CommentsState()),
      );
      expect(find.byType(FollowButton), findsNWidgets(2), reason: "Omar's two rows; not yours, not Mona (followed)");
      expect(find.text('Follow'), findsNWidgets(2));
      // The follow sits on the name's line, before "⋯".
      final follow = tester.getCenter(find.byType(FollowButton).first);
      expect((follow.dy - tester.getCenter(find.text('Omar Khaled').first).dy).abs(), lessThan(14));

      await tester.tap(find.text('Follow').first);
      await tester.pump();
      await tester.pump();
      verify(() => followRepository.follow('w-2')).called(1);
      expect(find.text('Following'), findsNWidgets(2), reason: 'every row of that writer');
    });

    testWidgets('guests see Follow and get the sign-in prompt', (tester) async {
      await pump(tester, CommentTile(comment: comment('c1', author: omar), callbacks: callbacks), cubit: comments(const CommentsState()), signedIn: false);
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      verifyNever(() => followRepository.follow(any()));
    });

    testWidgets('Arabic: "متابعة"', (tester) async {
      await pump(tester, CommentTile(comment: comment('c1', author: monaTitled), callbacks: callbacks), cubit: comments(const CommentsState()), variant: _ar);
      expect(find.text('متابعة'), findsOneWidget);
      expect(find.textContaining('ASP.NET Core'), findsOneWidget);
    });

    testWidgets('the sheet hands each new comment\'s follow state to the follow store', (tester) async {
      final cubit = comments(CommentsState(
        status: CommentsStatus.ready,
        total: 2,
        threads: [
          CommentThread.of(comment('c1', author: mona, isFollowingAuthor: true, replies: [comment('r1', parentId: 'c1', author: omar)])),
        ],
      ));
      await pump(tester, CommentsView(article: engagedCard(1)), cubit: cubit);
      expect(follows.state.isFollowing('w-1'), isTrue);
      expect(follows.state.users['w-2']?.isFollowing, isFalse);
      expect(follows.state.users.containsKey(viewer.id), isFalse);
      expect(find.text('Follow'), findsOneWidget, reason: 'Omar only');
    });
  });
}
