import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/router.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/related_articles_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/article/presentation/widgets/related_articles_section.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
import 'package:readin/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/mutes/domain/entities/mutes.dart';
import 'package:readin/features/mutes/domain/usecases/mute_usecases.dart';
import 'package:readin/features/mutes/presentation/cubit/muted_list_cubit.dart';
import 'package:readin/features/mutes/presentation/cubit/mutes_cubit.dart';
import 'package:readin/features/mutes/presentation/pages/muted_page.dart';
import 'package:readin/features/mutes/presentation/widgets/mute_gate.dart';
import 'package:readin/features/mutes/presentation/widgets/muted_writer_banner.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/profile/presentation/widgets/profile_header.dart';
import 'package:readin/features/profile/presentation/widgets/profile_menu.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';

import '../../helpers/comment_fixtures.dart' show MockCommentsCubit, MockMentionSuggestionsCubit;
import '../../helpers/fixtures.dart';
import '../../helpers/mute_fixtures.dart';
import '../../helpers/profile_fakes.dart' show appStores, profileScreen, provided;
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockRelatedArticlesCubit extends MockCubit<List<ArticleCard>> implements RelatedArticlesCubit {}

/// F28 on screen: the "⋯" menu (others', own, a deleted author's, guests), Show less and Mute author with Undo, the
/// "كتم المواضيع" sheet, the "لقد كتمت هذا الكاتب" banner, Mute on a profile's and a comment's "⋯", collapsed comments
/// and Settings → Muted.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  late AppLocalizations l10n;
  late MockMutesRepository repository;
  MutesCubit? created;
  MutesCubit mutes() => created!;
  late FollowsCubit follows;
  late MockSessionCubit session;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

  setUp(() {
    CommentClock.now = () => DateTime.utc(2026, 11, 2, 12);
    repository = okMutesRepository();
    follows = FollowsCubit(SetFollowing(MockFollowRepository()));
  });

  tearDown(() async {
    CommentClock.now = DateTime.now;
    await created?.close();
    created = null;
    await follows.close();
  });

  Future<void> pump(WidgetTester tester, Widget child, {Me? me = sampleMe, bool reduceMotion = false}) async {
    usePhoneSurface(tester, size: const Size(390, 1600));
    session = MockSessionCubit();
    whenListen(
      session,
      const Stream<SessionState>.empty(),
      initialState: me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me),
    );
    // A second pump in one test replaces the cubit; the old one closes after the test, not here. Its close awaits a
    // stream cancel that completes outside the test's fake clock, so awaiting it in the test body never returns.
    final previous = created;
    if (previous != null) addTearDown(previous.close);
    created = mutesCubit(repository, session: session, follows: follows);
    final engagement = MockEngagementCubit();
    whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    await tester.pumpWidget(testApp(
      MediaQuery(
        data: MediaQueryData(size: const Size(390, 1600), disableAnimations: reduceMotion),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<EngagementCubit>.value(value: engagement),
            BlocProvider<FollowsCubit>.value(value: follows),
            BlocProvider<MutesCubit>.value(value: mutes()),
          ],
          child: Scaffold(body: child),
        ),
      ),
      variant: en,
    ));
    await tester.pump();
  }

  /// A card with a plain English title, so the finders match it whole.
  ArticleCard post(int i, {Author? author = omarWriter, FieldRef? topic = diTopic, bool isFieldMuted = false}) =>
      muteCard(i, author: author, topic: topic, isFieldMuted: isFieldMuted, language: 'en', title: 'Post number $i');

  /// A list that applies mutes: each card behind its [MuteGate], like Home.
  Widget feed(List<ArticleCard> cards) => ListView(
        children: [
          for (final card in cards)
            MuteGate(
              key: ValueKey('gate-${card.id}'),
              article: card,
              child: Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: PostCard(article: card)),
            ),
        ],
      );

  Future<void> openMenu(WidgetTester tester, {int index = 0}) async {
    await tester.tap(find.byTooltip(l10n.articleMenu).at(index));
    await tester.pumpAndSettle();
  }

  /// Lets the confirmation time out, so no timer is left.
  Future<void> finishSnackBars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
  }

  group('the menu', () {
    // Changed on purpose (F36): Block author comes right under Mute author.
    test("items: someone else's article, your own, a deleted author's; moderators add theirs last", () {
      expect(articleMenuItems(own: false, moderator: false, hidden: false), [
        ArticleMenuItem.showLess,
        ArticleMenuItem.follow,
        ArticleMenuItem.muteAuthor,
        ArticleMenuItem.blockAuthor,
        ArticleMenuItem.muteTopics,
        ArticleMenuItem.report,
      ]);
      expect(articleMenuItems(own: true, moderator: false, hidden: false), [ArticleMenuItem.muteTopics]);
      expect(articleMenuItems(own: false, moderator: false, hidden: false, hasAuthor: false), [
        ArticleMenuItem.showLess,
        ArticleMenuItem.muteTopics,
        ArticleMenuItem.report,
      ]);
      expect(articleMenuItems(own: true, moderator: true, hidden: true), [ArticleMenuItem.muteTopics, ArticleMenuItem.unhide]);
      // The reader's menu (pdf) adds "تنزيل PDF" on every article, before Report (F33, any member since 2026-11-06).
      expect(articleMenuItems(own: true, moderator: false, hidden: false, pdf: true), [ArticleMenuItem.muteTopics, ArticleMenuItem.downloadPdf]);
      expect(articleMenuItems(own: false, moderator: false, hidden: false, pdf: true), [
        ArticleMenuItem.showLess,
        ArticleMenuItem.follow,
        ArticleMenuItem.muteAuthor,
        ArticleMenuItem.blockAuthor,
        ArticleMenuItem.muteTopics,
        ArticleMenuItem.downloadPdf,
        ArticleMenuItem.report,
      ]);
      expect(articleMenuItems(own: false, moderator: false, hidden: false, hasAuthor: false, pdf: true), [
        ArticleMenuItem.showLess,
        ArticleMenuItem.muteTopics,
        ArticleMenuItem.downloadPdf,
        ArticleMenuItem.report,
      ]);
    });

    testWidgets("someone else's article: the SPEC order, Report in the error color", (tester) async {
      await pump(tester, feed([post(1)]));
      await openMenu(tester);

      final labels = [
        l10n.articleMenuShowLess,
        l10n.articleMenuFollow,
        l10n.articleMenuMuteAuthor,
        l10n.articleMenuMuteTopics,
        l10n.articleMenuReport,
      ];
      final tops = [for (final label in labels) tester.getTopLeft(find.text(label)).dy];
      expect(tops, orderedEquals([...tops]..sort()));
      final report = tester.widget<Text>(find.text(l10n.articleMenuReport));
      expect(report.style?.color, isNot(tester.widget<Text>(find.text(l10n.articleMenuShowLess)).style?.color));
    });

    testWidgets('your own article offers Mute topics only', (tester) async {
      const me = Me(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev', onboardingCompleted: true);
      await pump(tester, feed([post(1)]), me: me);
      await openMenu(tester);

      expect(find.text(l10n.articleMenuMuteTopics), findsOneWidget);
      for (final label in [l10n.articleMenuShowLess, l10n.articleMenuFollow, l10n.articleMenuMuteAuthor, l10n.articleMenuReport]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('a followed writer reads "Unfollow author"; a following from the menu goes through FollowsCubit',
        (tester) async {
      follows.seed({'u-9': true});
      await pump(tester, feed([post(1)]));
      await openMenu(tester);

      expect(find.text(l10n.articleMenuUnfollow), findsOneWidget);
      expect(find.text(l10n.articleMenuFollow), findsNothing);
    });

    testWidgets('guests get the sign-in prompt for every item, and nothing is sent', (tester) async {
      await pump(tester, feed([post(1)]), me: null);
      for (final label in [l10n.articleMenuShowLess, l10n.articleMenuMuteAuthor, l10n.articleMenuMuteTopics]) {
        await openMenu(tester);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(l10n.signInPromptTitle), findsOneWidget, reason: label);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }
      verifyZeroInteractions(repository);
    });
  });

  group('show less and mute author', () {
    testWidgets('Show less folds that card away; Undo brings it back in place', (tester) async {
      await pump(tester, feed([post(1), post(2)]));
      final title = post(1).title;
      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuShowLess));
      await tester.pumpAndSettle();

      expect(find.text(title), findsNothing);
      expect(find.text(post(2).title), findsOneWidget);
      expect(find.text(l10n.showLessDone), findsOneWidget);
      verify(() => repository.setShowLess('art-1', showLess: true)).called(1);

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(tester.getTopLeft(find.text(title)).dy, lessThan(tester.getTopLeft(find.text(post(2).title)).dy));
      verify(() => repository.setShowLess('art-1', showLess: false)).called(1);
      await finishSnackBars(tester);
    });

    testWidgets("Mute author folds all the writer's cards; Undo unmutes and follows again", (tester) async {
      await pump(tester, feed([post(1), post(2, author: daliaWriter), post(3)]));
      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuMuteAuthor));
      await tester.pumpAndSettle();

      expect(find.text(post(1).title), findsNothing);
      expect(find.text(post(3).title), findsNothing);
      expect(find.text(post(2, author: daliaWriter).title), findsOneWidget);
      expect(find.textContaining('You muted'), findsOneWidget);
      expect(follows.state.isFollowing('u-9', fallback: true), isFalse, reason: 'a mute ends the follow');

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();
      verify(() => repository.unmuteUser('u-9', restoreFollow: true)).called(1);
      expect(find.text(post(1).title), findsOneWidget);
      expect(find.text(post(3).title), findsOneWidget);
      expect(follows.state.isFollowing('u-9'), isTrue);
      await finishSnackBars(tester);
    });

    testWidgets('a refused mute says why and the cards stay', (tester) async {
      when(() => repository.muteUser(any()))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.muteSystemAccount, statusCode: 400)));
      await pump(tester, feed([post(1)]));
      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuMuteAuthor));
      await tester.pumpAndSettle();

      expect(find.text(post(1).title), findsOneWidget);
      expect(find.text(l10n.errMuteSystemAccount), findsOneWidget);
      await finishSnackBars(tester);
    });

    testWidgets('Related: once every card folds away, its heading goes too; unmuting brings them back', (tester) async {
      final related = MockRelatedArticlesCubit();
      whenListen(related, const Stream<List<ArticleCard>>.empty(), initialState: [post(2), post(3)]);
      when(() => related.load(any(), language: any(named: 'language'))).thenAnswer((_) async {});
      await pump(
        tester,
        CustomScrollView(slivers: [RelatedArticlesSection(article: post(1, author: daliaWriter), cubit: () => related)]),
      );
      expect(find.text(l10n.relatedArticles), findsOneWidget);

      await mutes().muteUser('u-9');
      await tester.pumpAndSettle();
      expect(find.text(l10n.relatedArticles), findsNothing);
      expect(find.text(post(2).title), findsNothing);

      await mutes().unmuteUser('u-9');
      await tester.pumpAndSettle();
      expect(find.text(l10n.relatedArticles), findsOneWidget);
      expect(find.text(post(2).title), findsOneWidget);
    });

    testWidgets('Related: a section with one card left keeps its heading', (tester) async {
      final related = MockRelatedArticlesCubit();
      whenListen(related, const Stream<List<ArticleCard>>.empty(), initialState: [post(2), post(3, author: daliaWriter)]);
      when(() => related.load(any(), language: any(named: 'language'))).thenAnswer((_) async {});
      await pump(tester, CustomScrollView(slivers: [RelatedArticlesSection(article: post(1), cubit: () => related)]));

      await mutes().muteUser('u-9');
      await tester.pumpAndSettle();
      expect(find.text(l10n.relatedArticles), findsOneWidget);
      expect(find.text(post(3, author: daliaWriter).title), findsOneWidget);
    });

    testWidgets('with reduce motion the card folds at once', (tester) async {
      await pump(tester, feed([post(1)]), reduceMotion: true);
      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuShowLess));
      await tester.pump();
      await tester.pump();

      expect(find.text(post(1).title), findsNothing);
      await finishSnackBars(tester);
    });
  });

  group('mute topics', () {
    testWidgets('the sheet has the field and the topic; a toggle folds the cards in it, and back', (tester) async {
      final other = post(2, topic: promptsTopic);
      await pump(tester, feed([post(1), other]));
      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuMuteTopics));
      await tester.pumpAndSettle();

      expect(find.text(l10n.muteTopicsTitle), findsWidgets);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(find.text(l10n.muteTopicsField), findsOneWidget);
      expect(find.text(l10n.muteTopicsTopic), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile).last);
      await tester.pumpAndSettle();
      verify(() => repository.setTopicMuted('t-di', muted: true)).called(1);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile).last).value, isTrue);

      // Behind the sheet: the card in the topic is gone, the other stays.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text(post(1).title), findsNothing);
      expect(find.text(other.title), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.articleMenu).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.articleMenuMuteTopics));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      verify(() => repository.setFieldMuted('f-dotnet', muted: true)).called(1);
    });

    testWidgets('without a topic only the field row shows; the loaded flags set the switches', (tester) async {
      // A muted field's card is left out of lists: the reader's menu, then.
      await pump(tester, ArticleMenuView(card: post(1, topic: null, isFieldMuted: true), hidden: false, onModerated: (_) {}));
      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuMuteTopics));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    });
  });

  group('the muted writer banner', () {
    testWidgets('shows on a muted writer and unmutes without following again', (tester) async {
      await pump(tester, const MutedWriterBanner(userId: 'u-9', name: 'Omar Khaled', initiallyMuted: true));

      expect(find.text(l10n.muteBannerTitle), findsOneWidget);
      await tester.tap(find.text(l10n.muteUnmute));
      await tester.pumpAndSettle();

      verify(() => repository.unmuteUser('u-9', restoreFollow: false)).called(1);
      expect(find.text(l10n.muteBannerTitle), findsNothing);
      expect(find.textContaining('You unmuted'), findsOneWidget);
      await finishSnackBars(tester);
    });

    testWidgets("muting from the reader's menu shows it there and then", (tester) async {
      final card = post(1);
      await pump(
        tester,
        Column(
          children: [
            const MutedWriterBanner(userId: 'u-9', name: 'Omar Khaled', initiallyMuted: false),
            ArticleMenuView(card: card, hidden: false, onModerated: (_) {}),
          ],
        ),
      );
      expect(find.text(l10n.muteBannerTitle), findsNothing);

      await openMenu(tester);
      await tester.tap(find.text(l10n.articleMenuMuteAuthor));
      await tester.pumpAndSettle();
      expect(find.text(l10n.muteBannerTitle), findsOneWidget);

      // The menu now offers to unmute.
      await openMenu(tester);
      expect(find.text(l10n.articleMenuUnmuteAuthor), findsOneWidget);
      await tester.tap(find.text(l10n.articleMenuUnmuteAuthor));
      await tester.pumpAndSettle();
      expect(find.text(l10n.muteBannerTitle), findsNothing);
      await finishSnackBars(tester);
    });

    testWidgets("on a muted writer's profile it sits under the profile header, as on the web", (tester) async {
      usePhoneSurface(tester, size: const Size(390, 1600));
      const muted = UserProfile(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev', isMuted: true);
      await tester.pumpWidget(testApp(provided([...appStores(), ...profileScreen(muted)], const ProfileView()), variant: en));
      await tester.pump();

      expect(find.text(l10n.muteBannerTitle), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('profile-muted-banner'))).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(ProfileHeader)).dy),
      );
    });
  });

  group("a profile's menu", () {
    const omarProfile = UserProfile(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev');

    Future<void> openProfileMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip(l10n.profileMenu));
      await tester.pumpAndSettle();
    }

    // Changed on purpose (F36): Block comes under Mute, on the official account too (it can't be muted).
    test('Mute comes first; never on your own profile or the official account; moderators add theirs', () {
      expect(profileMenuItems(moderator: false, canSuspend: false), [ProfileMenuItem.mute, ProfileMenuItem.block, ProfileMenuItem.report]);
      expect(profileMenuItems(moderator: false, canSuspend: false, own: true), [ProfileMenuItem.report]);
      expect(profileMenuItems(moderator: false, canSuspend: false, systemAccount: true), [ProfileMenuItem.block, ProfileMenuItem.report]);
      expect(profileMenuItems(moderator: true, canSuspend: true), [
        ProfileMenuItem.mute,
        ProfileMenuItem.block,
        ProfileMenuItem.report,
        ProfileMenuItem.warn,
        ProfileMenuItem.suspend,
      ]);
    });

    testWidgets("someone else's profile: Mute user before Report; it mutes, ends the follow, and Undo follows again",
        (tester) async {
      follows.seed({'u-9': true});
      await pump(tester, const ProfileMenuButton(profile: omarProfile));
      await openProfileMenu(tester);
      expect(
        tester.getTopLeft(find.text(l10n.muteMenuUser)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.profileMenuReport)).dy),
      );

      await tester.tap(find.text(l10n.muteMenuUser));
      await tester.pumpAndSettle();
      verify(() => repository.muteUser('u-9')).called(1);
      expect(mutes().state.isUserMuted('u-9'), isTrue);
      expect(follows.state.isFollowing('u-9', fallback: true), isFalse, reason: 'a mute ends the follow');
      expect(find.textContaining('You muted'), findsOneWidget);

      await openProfileMenu(tester);
      expect(find.text(l10n.muteMenuUnmuteUser), findsOneWidget, reason: 'the item now unmutes');
      // Closes the menu: a tap on the barrier, away from the menu (top) and the confirmation (bottom).
      await tester.tapAt(const Offset(200, 800));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();
      verify(() => repository.unmuteUser('u-9', restoreFollow: true)).called(1);
      expect(mutes().state.isUserMuted('u-9'), isFalse);
      expect(follows.state.isFollowing('u-9'), isTrue);
      await finishSnackBars(tester);
    });

    testWidgets('a muted profile reads "Unmute user", which unmutes without following again', (tester) async {
      await pump(
        tester,
        const ProfileMenuButton(profile: UserProfile(id: 'u-9', displayName: 'Omar Khaled', username: 'omar_dev', isMuted: true)),
      );
      await openProfileMenu(tester);
      expect(find.text(l10n.muteMenuUser), findsNothing);

      await tester.tap(find.text(l10n.muteMenuUnmuteUser));
      await tester.pumpAndSettle();
      verify(() => repository.unmuteUser('u-9', restoreFollow: false)).called(1);
      expect(find.textContaining('You unmuted'), findsOneWidget);
      await finishSnackBars(tester);
    });

    testWidgets('the official ReadIn account has no Mute', (tester) async {
      await pump(
        tester,
        const ProfileMenuButton(
          profile: UserProfile(id: 'u-readin', displayName: 'ReadIn', username: 'readin', isSystemAccount: true),
        ),
      );
      await openProfileMenu(tester);

      expect(find.text(l10n.profileMenuReport), findsOneWidget);
      expect(find.text(l10n.muteMenuUser), findsNothing);
      expect(find.text(l10n.muteMenuUnmuteUser), findsNothing);
    });

    testWidgets('your own profile has no menu at all', (tester) async {
      const own = UserProfile(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1', isMe: true);
      await tester.pumpWidget(testApp(provided([...appStores(), ...profileScreen(own)], const ProfileView()), variant: en));
      await tester.pump();

      expect(find.byTooltip(l10n.profileMenu), findsNothing);
      expect(find.text(l10n.muteMenuUser), findsNothing);
    });

    testWidgets('guests see Mute user and get the sign-in prompt; nothing is sent', (tester) async {
      await pump(tester, const ProfileMenuButton(profile: omarProfile), me: null);
      await openProfileMenu(tester);
      await tester.tap(find.text(l10n.muteMenuUser));
      await tester.pumpAndSettle();

      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
      verifyZeroInteractions(repository);
    });
  });

  group("a comment's menu", () {
    Comment byWriter(String id, Author? author, {bool own = false, bool muted = false, bool signedIn = true}) => Comment(
          id: id,
          articleId: 'art-1',
          body: 'Words of $id',
          author: author,
          createdAt: DateTime.utc(2026, 11, 2, 11),
          isAuthorMuted: muted,
          canEdit: own,
          canDelete: own,
          // As the API answers: false for guests and on your own comments.
          canReport: signedIn && !own,
        );

    Future<void> pumpComments(WidgetTester tester, List<Comment> items, {Me? me = sampleMe}) async {
      final comments = MockCommentsCubit();
      whenListen(
        comments,
        const Stream<CommentsState>.empty(),
        initialState: CommentsState(
          status: CommentsStatus.ready,
          threads: [for (final comment in items) CommentThread.of(comment)],
          total: items.length,
        ),
      );
      final suggestions = MockMentionSuggestionsCubit();
      whenListen(suggestions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
      await pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<CommentsCubit>.value(value: comments),
            BlocProvider<MentionSuggestionsCubit>.value(value: suggestions),
          ],
          child: CommentsView(article: post(1)),
        ),
        me: me,
      );
    }

    Future<void> openCommentMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip(l10n.commentsMenu));
      await tester.pumpAndSettle();
    }

    testWidgets('Mute commenter right before Report: it collapses their comments, and Undo follows again', (tester) async {
      follows.seed({'u-9': true});
      await pumpComments(tester, [byWriter('c-1', omarWriter)]);
      await openCommentMenu(tester);
      expect(
        tester.getTopLeft(find.text(l10n.muteMenuCommenter)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.commentsReport)).dy),
      );

      await tester.tap(find.text(l10n.muteMenuCommenter));
      await tester.pumpAndSettle();
      verify(() => repository.muteUser('u-9')).called(1);
      expect(find.text(l10n.muteCommentCollapsed), findsOneWidget);
      expect(follows.state.isFollowing('u-9', fallback: true), isFalse, reason: 'a mute ends the follow');
      expect(find.textContaining('You muted'), findsOneWidget);

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();
      verify(() => repository.unmuteUser('u-9', restoreFollow: true)).called(1);
      expect(find.text(l10n.muteCommentCollapsed), findsNothing);
      expect(follows.state.isFollowing('u-9'), isTrue);
      await finishSnackBars(tester);
    });

    testWidgets('a muted commenter\'s menu reads "Unmute commenter", which unmutes', (tester) async {
      await pumpComments(tester, [byWriter('c-1', omarWriter, muted: true)]);
      await tester.tap(find.text(l10n.muteCommentShow));
      await tester.pumpAndSettle();
      await openCommentMenu(tester);
      expect(find.text(l10n.muteMenuCommenter), findsNothing);

      await tester.tap(find.text(l10n.muteMenuUnmuteCommenter));
      await tester.pumpAndSettle();
      verify(() => repository.unmuteUser('u-9', restoreFollow: false)).called(1);
      expect(find.textContaining('You unmuted'), findsOneWidget);
      await finishSnackBars(tester);
    });

    testWidgets('not on your own comment, nor on a deleted account\'s', (tester) async {
      final mine = Author(id: sampleMe.id, displayName: sampleMe.displayName, username: sampleMe.username);
      await pumpComments(tester, [byWriter('c-1', mine, own: true)]);
      await openCommentMenu(tester);
      expect(find.text(l10n.edit), findsOneWidget);
      expect(find.text(l10n.muteMenuCommenter), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await pumpComments(tester, [byWriter('c-2', null)]);
      await openCommentMenu(tester);
      expect(find.text(l10n.commentsReport), findsOneWidget);
      expect(find.text(l10n.muteMenuCommenter), findsNothing);
    });

    testWidgets('guests see Mute commenter and get the sign-in prompt; nothing is sent', (tester) async {
      await pumpComments(tester, [byWriter('c-1', omarWriter, signedIn: false)], me: null);
      await openCommentMenu(tester);
      await tester.tap(find.text(l10n.muteMenuCommenter));
      await tester.pumpAndSettle();

      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
      verifyZeroInteractions(repository);
    });
  });

  group('comments', () {
    final noop = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});

    Comment byWriter(String id, Author author, String body, {String? parentId, bool muted = false}) => Comment(
          id: id,
          articleId: 'art-1',
          parentId: parentId,
          body: body,
          author: author,
          createdAt: DateTime.utc(2026, 11, 2, 11),
          isAuthorMuted: muted,
        );

    testWidgets('a muted writer\'s comment collapses with "Show"; replies under it stay', (tester) async {
      final thread = CommentThread(
        comment: byWriter('c-1', omarWriter, 'Muted words', muted: true),
        replies: [byWriter('c-2', daliaWriter, 'A reply that stays', parentId: 'c-1')],
      );
      await pump(tester, CommentThreadView(thread: thread, callbacks: noop));

      expect(find.text(l10n.muteCommentCollapsed), findsOneWidget);
      expect(find.textContaining('Muted words'), findsNothing);
      expect(find.textContaining('A reply that stays'), findsOneWidget);

      await tester.tap(find.text(l10n.muteCommentShow));
      await tester.pumpAndSettle();
      expect(find.textContaining('Muted words'), findsOneWidget);
      expect(find.text(l10n.muteCommentCollapsed), findsNothing);
    });

    testWidgets('a writer muted in this session collapses too', (tester) async {
      final thread = CommentThread(comment: byWriter('c-1', omarWriter, 'Hello there'));
      await pump(tester, CommentThreadView(thread: thread, callbacks: noop));
      expect(find.textContaining('Hello there'), findsOneWidget);

      await mutes().muteUser('u-9');
      await tester.pumpAndSettle();
      expect(find.text(l10n.muteCommentCollapsed), findsOneWidget);
    });
  });

  group('Settings → Muted', () {
    Future<MutedListCubit> pumpPage(WidgetTester tester) async {
      await pump(tester, const SizedBox.shrink());
      final list = MutedListCubit(GetMutes(repository), mutes());
      addTearDown(list.close);
      await list.load();
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<MutesCubit>.value(value: mutes()),
            BlocProvider<MutedListCubit>.value(value: list),
          ],
          child: const MutedView(),
        ),
        variant: en,
      ));
      await tester.pump();
      return list;
    }

    testWidgets('writers, fields and topics, each with Unmute', (tester) async {
      await pumpPage(tester);

      expect(find.text(l10n.mutePageWriters), findsOneWidget);
      expect(find.text(l10n.mutePageFields), findsOneWidget);
      expect(find.text(l10n.mutePageTopics), findsOneWidget);
      expect(find.text(l10n.muteUnmute), findsNWidgets(4));

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('muted-user-u-9')), matching: find.text(l10n.muteUnmute)));
      await tester.pumpAndSettle();
      verify(() => repository.unmuteUser('u-9', restoreFollow: false)).called(1);
      expect(find.byKey(const ValueKey('muted-user-u-9')), findsNothing);
      expect(find.text(l10n.muteUnmute), findsNWidgets(3));

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('muted-topic-t-orm')), matching: find.text(l10n.muteUnmute)));
      await tester.pumpAndSettle();
      verify(() => repository.setTopicMuted('t-orm', muted: false)).called(1);
      expect(find.byKey(const ValueKey('muted-topic-t-orm')), findsNothing);
      expect(find.text(l10n.mutePageTopics), findsNothing);
      await finishSnackBars(tester);
    });

    testWidgets('nothing muted: the empty state', (tester) async {
      when(() => repository.getMutes()).thenAnswer((_) async => const Ok(Mutes()));
      await pumpPage(tester);

      expect(find.text(l10n.mutePageEmptyTitle), findsOneWidget);
      expect(find.text(l10n.mutePageEmptyBody), findsOneWidget);
    });

    test("lives at the web's /settings/muted; guests are sent away, members stay", () {
      expect(MutedPage.path, '/settings/muted');
      expect(
        resolveRedirect(
          uri: Uri.parse(MutedPage.path),
          session: const SessionState(status: SessionStatus.guest),
          settings: const AppSettings(welcomeSeen: true),
        ),
        AppRoutes.home,
      );
      expect(
        resolveRedirect(
          uri: Uri.parse(MutedPage.path),
          session: const SessionState(status: SessionStatus.authenticated, me: sampleMe),
          settings: const AppSettings(welcomeSeen: true),
        ),
        isNull,
      );
    });

    testWidgets('the subtitle says what a mute does, under the title', (tester) async {
      await pumpPage(tester);

      expect(find.text(l10n.mutePageSubtitle), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(l10n.mutePageSubtitle)).dy,
        greaterThan(tester.getTopLeft(find.text(l10n.mutePageTitle)).dy),
      );
      expect(
        tester.getTopLeft(find.text(l10n.mutePageSubtitle)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.mutePageWriters)).dy),
      );
    });
  });
}
