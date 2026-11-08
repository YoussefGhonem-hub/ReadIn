import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/blocks/domain/entities/blocks.dart';
import 'package:readin/features/blocks/domain/repositories/blocks_repository.dart';
import 'package:readin/features/blocks/domain/usecases/block_usecases.dart';
import 'package:readin/features/blocks/presentation/cubit/blocked_list_cubit.dart';
import 'package:readin/features/blocks/presentation/cubit/blocks_cubit.dart';
import 'package:readin/features/blocks/presentation/pages/blocked_page.dart';
import 'package:readin/features/blocks/presentation/widgets/block_actions.dart';
import 'package:readin/features/blocks/presentation/widgets/blocked_notice.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/mutes/presentation/widgets/mute_gate.dart';
import 'package:readin/features/profile/presentation/widgets/profile_menu.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mute_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _MockBlocksRepository extends Mock implements BlocksRepository {}

const _en = Variant(AppLocales.en, Brightness.light);

/// Block (F36): the session's blocks and their Undo, the confirmation and toast, Settings → Blocked accounts, the
/// "isn't available" notice, and what leaves the screen at once (cards, comments); the menus' items.
void main() {
  late AppLocalizations l10n;
  late _MockBlocksRepository repository;
  late FollowsCubit follows;
  late MockSessionCubit session;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

  setUp(() {
    repository = _MockBlocksRepository();
    when(() => repository.block(any()))
        .thenAnswer((i) async => Ok(UserBlockState(userId: i.positionalArguments.first as String, isBlocked: true, followRemoved: true)));
    when(() => repository.unblock(any(), restoreFollow: any(named: 'restoreFollow')))
        .thenAnswer((i) async => Ok(UserBlockState(userId: i.positionalArguments.first as String, isBlocked: false)));
    follows = FollowsCubit(SetFollowing(MockFollowRepository()));
    session = MockSessionCubit()..hold(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
  });

  tearDown(() => follows.close());

  BlocksCubit blocks() {
    final cubit = BlocksCubit(SetUserBlocked(repository), session, follows);
    addTearDown(cubit.close);
    return cubit;
  }

  group('BlocksCubit', () {
    test('a block shows at once, ends the follow, and its Undo follows again', () async {
      follows.seed({'u-9': true});
      final cubit = blocks();

      final result = await cubit.block('u-9');
      expect(result.valueOrNull?.followRemoved, isTrue);
      expect(cubit.state.isBlocked('u-9'), isTrue);
      expect(follows.state.isFollowing('u-9', fallback: true), isFalse);

      await cubit.unblock('u-9', restoreFollow: true);
      verify(() => repository.unblock('u-9', restoreFollow: true)).called(1);
      expect(cubit.state.isBlocked('u-9'), isFalse);
      expect(follows.state.isFollowing('u-9'), isTrue);
    });

    test('a refused block rolls back and says why', () async {
      when(() => repository.block('u-9')).thenAnswer((_) async => const Err(Failure(FailureCodes.blockLimit)));
      final cubit = blocks();

      final result = await cubit.block('u-9');

      expect(result.failureOrNull?.code, FailureCodes.blockLimit);
      expect(cubit.state.users.containsKey('u-9'), isFalse);
    });

    test("hides the blocked writer's cards and those only a blocked reposter placed", () async {
      final cubit = blocks()..markBlocked('u-9');
      final reposted = ArticleCard(
        id: 'a-2',
        slug: 'x',
        language: 'en',
        title: 'X',
        field: dotnetField,
        author: daliaWriter,
        readingTimeMinutes: 3,
        publishedAt: DateTime.utc(2026, 11),
        repostedBy: RepostLabel(user: omarWriter, repostedAt: DateTime.utc(2026, 11, 2)),
      );
      expect(cubit.state.hides(muteCard(1)), isTrue);
      expect(cubit.state.hides(muteCard(2, author: daliaWriter)), isFalse);
      expect(cubit.state.hides(reposted), isTrue);
      expect(follows.state.isFollowing('u-9', fallback: true), isFalse, reason: 'markBlocked ends the follow too');
    });
  });

  group('the menus', () {
    test('Block comes under Mute on a profile, never your own; the official account and staff too', () {
      expect(profileMenuItems(moderator: false, canSuspend: false), [ProfileMenuItem.mute, ProfileMenuItem.block, ProfileMenuItem.report]);
      expect(profileMenuItems(moderator: false, canSuspend: false, systemAccount: true), [ProfileMenuItem.block, ProfileMenuItem.report]);
      expect(profileMenuItems(moderator: false, canSuspend: false, own: true), [ProfileMenuItem.report]);
    });

    test('the article "⋯": Block author under Mute author; a card a repost placed reports the repost too', () {
      expect(
        articleMenuItems(own: false, moderator: false, hidden: false),
        [
          ArticleMenuItem.showLess,
          ArticleMenuItem.follow,
          ArticleMenuItem.muteAuthor,
          ArticleMenuItem.blockAuthor,
          ArticleMenuItem.muteTopics,
          ArticleMenuItem.report,
        ],
      );
      expect(articleMenuItems(own: false, moderator: false, hidden: false, hasAuthor: false), isNot(contains(ArticleMenuItem.blockAuthor)));
      expect(articleMenuItems(own: true, moderator: false, hidden: false), isNot(contains(ArticleMenuItem.blockAuthor)));
      expect(
        articleMenuItems(own: false, moderator: false, hidden: false, repost: true),
        containsAllInOrder([ArticleMenuItem.report, ArticleMenuItem.reportRepost]),
      );
    });

    test("a comment's \"⋯\": Block the commenter under Mute; not on your own comment nor a placeholder", () {
      final other = Comment(id: 'c-1', articleId: 'a-1', body: 'Hi', author: omarWriter, createdAt: DateTime.utc(2026), canReport: true);
      expect(
        commentMenuActions(other),
        [CommentMenuAction.mute, CommentMenuAction.block, CommentMenuAction.report],
      );
      final own = Comment(id: 'c-2', articleId: 'a-1', body: 'Hi', author: omarWriter, createdAt: DateTime.utc(2026), canEdit: true, canDelete: true);
      expect(commentMenuActions(own), isNot(contains(CommentMenuAction.block)));
      final gone = Comment(id: 'c-3', articleId: 'a-1', createdAt: DateTime.utc(2026), canReport: true, isUnavailable: true);
      expect(commentMenuActions(gone), isNot(contains(CommentMenuAction.block)));
    });
  });

  group('screens', () {
    late BlocksCubit cubit;

    Future<void> pump(WidgetTester tester, Widget child, {Me? me = sampleMe, BlocksCubit? using}) async {
      usePhoneSurface(tester);
      session.hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));
      cubit = using ?? blocks();
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<FollowsCubit>.value(value: follows),
            BlocProvider<BlocksCubit>.value(value: cubit),
          ],
          child: Scaffold(body: child),
        ),
        variant: _en,
      ));
      await tester.pump();
    }

    Widget blockButton() => Builder(
          builder: (context) => TextButton(
            onPressed: () => BlockActions.block(context, userId: 'u-9', username: 'omar_dev'),
            child: const Text('block'),
          ),
        );

    testWidgets('the confirmation says what a block does; Block in the error color; Undo unblocks and follows again', (tester) async {
      follows.seed({'u-9': true});
      await pump(tester, blockButton());

      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('block-confirm')), findsOneWidget);
      expect(find.textContaining('Block'), findsWidgets);
      expect(find.text(l10n.blockConfirmBody), findsOneWidget);
      expect(find.textContaining("They won't be notified"), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('block-confirm-ok')));
      await tester.pumpAndSettle();
      verify(() => repository.block('u-9')).called(1);
      expect(cubit.state.isBlocked('u-9'), isTrue);
      expect(find.textContaining('blocked'), findsOneWidget);

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();
      verify(() => repository.unblock('u-9', restoreFollow: true)).called(1);
      expect(cubit.state.isBlocked('u-9'), isFalse);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
    });

    testWidgets('Cancel blocks nothing; guests get the sign-in prompt', (tester) async {
      await pump(tester, blockButton());
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      verifyNever(() => repository.block(any()));

      await pump(tester, blockButton(), me: null);
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('block-confirm')), findsNothing);
      verifyNever(() => repository.block(any()));
    });

    testWidgets("a blocked writer's cards fold away on a list at once", (tester) async {
      await pump(
        tester,
        ListView(children: [
          for (final card in [muteCard(1), muteCard(2, author: daliaWriter)])
            MuteGate(article: card, child: SizedBox(height: 100, child: Text('card ${card.id}'))),
        ]),
      );
      final first = muteCard(1).id;
      expect(find.text('card $first').hitTestable(), findsOneWidget);

      await cubit.block('u-9');
      await tester.pumpAndSettle();
      expect(find.text('card $first').hitTestable(), findsNothing);
      expect(find.text('card ${muteCard(2).id}').hitTestable(), findsOneWidget);
    });

    testWidgets("a blocked person's comment reads «This comment isn't available»; so does the API's placeholder", (tester) async {
      final callbacks = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});
      final comment = Comment(id: 'c-1', articleId: 'a-1', body: 'Words', author: omarWriter, createdAt: DateTime.utc(2026), canReport: true);
      await pump(
        tester,
        Column(children: [
          CommentTile(comment: comment, callbacks: callbacks),
          CommentTile(
            comment: Comment(id: 'c-2', articleId: 'a-1', createdAt: DateTime.utc(2026), isUnavailable: true),
            callbacks: callbacks,
          ),
        ]),
      );
      expect(find.text('Words'), findsOneWidget);
      expect(find.text(l10n.blockCommentUnavailable), findsOneWidget);

      cubit.markBlocked('u-9');
      await tester.pumpAndSettle();
      expect(find.text('Words'), findsNothing);
      expect(find.text(l10n.blockCommentUnavailable), findsNWidgets(2));
    });

    testWidgets('the "isn\'t available" notice: account or content, with Unblock', (tester) async {
      var unblocked = 0;
      await pump(
        tester,
        BlockedNotice(
          person: const BlockedPerson(id: 'u-9', username: 'omar_dev', displayName: 'Omar'),
          account: true,
          onUnblocked: () => unblocked++,
        ),
      );
      expect(find.text(l10n.blockAccountUnavailable), findsOneWidget);
      expect(find.textContaining('You blocked'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('blocked-notice-unblock')));
      await tester.pumpAndSettle();
      verify(() => repository.unblock('u-9', restoreFollow: false)).called(1);
      expect(unblocked, 1);

      expect(
        BlockedNotice.personOf(const BlockedFailure(blockedUserId: 'u-9', blockedUsername: 'omar_dev')),
        const BlockedPerson(id: 'u-9', username: 'omar_dev', displayName: ''),
      );
      expect(BlockedNotice.personOf(const Failure(FailureCodes.articleNotFound)), isNull);
    });

    testWidgets('Settings → Blocked accounts: newest first, each with Unblock; the row leaves once unblocked', (tester) async {
      when(() => repository.blocked()).thenAnswer(
        (_) async => Ok([
          BlockedUser(
            user: const UserSummary(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev'),
            blockedAt: DateTime.utc(2026, 11, 8),
          ),
          BlockedUser(user: const UserSummary(id: 'u-7', displayName: 'Dalia', username: 'dalia'), blockedAt: DateTime.utc(2026, 11, 1)),
        ]),
      );
      final shared = blocks();
      // The page's BlocProvider owns it and closes it.
      final list = BlockedListCubit(GetBlockedUsers(repository), shared);
      await pump(tester, BlockedPage(cubit: list), using: shared);
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      expect(find.text(l10n.blockedTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('blocked-u-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('blocked-u-7')), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(const ValueKey('blocked-u-9'))).dy, lessThan(tester.getTopLeft(find.byKey(const ValueKey('blocked-u-7'))).dy));

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('blocked-u-9')), matching: find.text(l10n.blockUnblock)));
      await tester.pumpAndSettle();
      verify(() => repository.unblock('u-9', restoreFollow: false)).called(1);
      expect(find.byKey(const ValueKey('blocked-u-9')), findsNothing);
      expect(find.text(l10n.blockedFollowsNote), findsOneWidget);
    });

    testWidgets('nobody blocked: the empty state', (tester) async {
      when(() => repository.blocked()).thenAnswer((_) async => const Ok(<BlockedUser>[]));
      final shared = blocks();
      // The page's BlocProvider owns it and closes it.
      final list = BlockedListCubit(GetBlockedUsers(repository), shared);
      await pump(tester, BlockedPage(cubit: list), using: shared);
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
      expect(find.text(l10n.blockedEmptyTitle), findsOneWidget);
    });
  });
}
