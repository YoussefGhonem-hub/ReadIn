@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/domain/entities/comment.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/comments/presentation/widgets/comment_tile.dart';
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

import '../helpers/fixtures.dart';
import '../helpers/mute_fixtures.dart';
import '../helpers/profile_fakes.dart' show appStores, profileScreen, provided;
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

/// F28 in ar/light and en/dark (SPEC §27): the "⋯" menu on someone else's article and on your own, the confirmation
/// with Undo after muting a writer, the "كتم المواضيع" sheet, the "انت كاتم الكاتب ده" banner (alone, and on a muted
/// writer's profile with its "⋯" open), a comment's "⋯", a collapsed comment, and Settings → Muted with its empty
/// state.
void main() {
  late MockMutesRepository repository;
  MutesCubit? mutes;
  FollowsCubit? follows;

  setUp(() {
    CommentClock.now = () => DateTime.utc(2026, 11, 2, 12);
    repository = okMutesRepository();
  });

  tearDown(() async {
    CommentClock.now = DateTime.now;
    await mutes?.close();
    await follows?.close();
    mutes = null;
    follows = null;
  });

  bool isEn(Variant variant) => variant.locale.languageCode == 'en';

  /// A writer whose name reads in the variant's language.
  Author writer(Variant variant) => isEn(variant) ? omarWriter : daliaWriter;

  ArticleCard card(Variant variant, int i, {Author? author, bool isTopicMuted = false, FieldRef? topic = diTopic}) => muteCard(
        i,
        author: author ?? writer(variant),
        topic: topic,
        isTopicMuted: isTopicMuted,
        language: isEn(variant) ? 'en' : 'ar-EG',
        title: isEn(variant)
            ? ['Scoped or Transient: which one for your service?', 'Writing your first minimal API in .NET 10'][i % 2]
            : null,
      );

  Future<AppLocalizations> pump(WidgetTester tester, Variant variant, Widget body, {required double height, Me me = sampleMe}) async {
    usePhoneSurface(tester, size: Size(390, height));
    final session = MockSessionCubit();
    whenListen(session, const Stream<SessionState>.empty(), initialState: SessionState(status: SessionStatus.authenticated, me: me));
    final engagement = MockEngagementCubit();
    whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    follows = FollowsCubit(SetFollowing(MockFollowRepository()));
    mutes = mutesCubit(repository, session: session, follows: follows);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows!),
          BlocProvider<MutesCubit>.value(value: mutes!),
        ],
        child: Scaffold(body: SafeArea(child: body)),
      ),
      variant: variant,
    ));
    await tester.pump();
    return AppLocalizations.delegate.load(variant.locale);
  }

  Widget feed(List<ArticleCard> cards) => ListView(
        padding: const EdgeInsets.symmetric(vertical: postCardGap),
        children: [
          for (final card in cards)
            MuteGate(
              article: card,
              child: Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: PostCard(article: card)),
            ),
        ],
      );

  Future<void> expectGolden(WidgetTester tester, Variant variant, String name) =>
      expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/${name}_${variant.name}.png'));

  /// Lets a confirmation time out, so no timer is left.
  Future<void> finishSnackBars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
  }

  for (final variant in Variant.golden) {
    testWidgets("the menu on someone else's article ${variant.name}", (tester) async {
      final l10n = await pump(tester, variant, feed([card(variant, 1)]), height: 560);
      await tester.tap(find.byTooltip(l10n.articleMenu));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'mute_menu');
    });

    testWidgets('the menu on your own article ${variant.name}', (tester) async {
      final mine = Author(id: sampleMe.id, displayName: sampleMe.displayName, username: sampleMe.username);
      final l10n = await pump(tester, variant, feed([card(variant, 1, author: mine)]), height: 360);
      await tester.tap(find.byTooltip(l10n.articleMenu));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'mute_menu_own');
    });

    testWidgets('muted a writer: their cards fold away, Undo in the confirmation ${variant.name}', (tester) async {
      final other = isEn(variant) ? daliaWriter : omarWriter;
      final l10n = await pump(tester, variant, feed([card(variant, 1), card(variant, 2, author: other), card(variant, 3)]), height: 560);
      await tester.tap(find.byTooltip(l10n.articleMenu).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.articleMenuMuteAuthor));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'mute_undo');
      await finishSnackBars(tester);
    });

    testWidgets('the mute topics sheet ${variant.name}', (tester) async {
      final l10n = await pump(
        tester,
        variant,
        // Not behind a gate: the card stays behind the sheet with its topic muted.
        ListView(children: [PostCard(article: card(variant, 1, isTopicMuted: true))]),
        height: 560,
      );
      await tester.tap(find.byTooltip(l10n.articleMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.articleMenuMuteTopics));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'mute_topics_sheet');
    });

    testWidgets('the muted writer banner ${variant.name}', (tester) async {
      final name = writer(variant).displayName;
      await pump(
        tester,
        variant,
        Column(
          children: [
            MutedWriterBanner(
              userId: writer(variant).id,
              name: name,
              initiallyMuted: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            ),
          ],
        ),
        height: 200,
      );
      await expectGolden(tester, variant, 'mute_banner');
    });

    testWidgets("a muted writer's profile: the banner under the header, Unmute user first in the menu ${variant.name}",
        (tester) async {
      usePhoneSurface(tester, size: const Size(390, 640));
      final session = MockSessionCubit();
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      follows = FollowsCubit(SetFollowing(MockFollowRepository()));
      mutes = mutesCubit(repository, session: session, follows: follows);
      final author = writer(variant);
      final profile = UserProfile(
        id: author.id,
        displayName: author.displayName,
        username: author.username,
        bio: isEn(variant) ? 'Backend engineer, writing about .NET and SQL Server.' : 'Backend engineer بكتب عن .NET و SQL Server.',
        joinedAt: DateTime.utc(2026, 1, 10),
        stats: const ProfileStats(articles: 12, followers: 340, following: 21, totalReads: 5120),
        isMuted: true,
      );
      await tester.pumpWidget(testApp(
        provided([...appStores(), ...profileScreen(profile), BlocProvider<MutesCubit>.value(value: mutes!)], const ProfileView()),
        variant: variant,
      ));
      await tester.pump();
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await tester.tap(find.byTooltip(l10n.profileMenu));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'mute_profile_menu');
    });

    testWidgets("a comment's menu: Mute commenter right before Report ${variant.name}", (tester) async {
      final comment = Comment(
        id: 'c-1',
        articleId: 'art-1',
        body: isEn(variant) ? 'Great summary, thanks!' : 'تلخيص حلو جدًا، شكرًا!',
        author: writer(variant),
        createdAt: DateTime.utc(2026, 11, 2, 10),
        likeCount: 5,
        canReport: true,
      );
      final noop = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});
      final l10n = await pump(
        tester,
        variant,
        ListView(children: [CommentThreadView(thread: CommentThread(comment: comment), callbacks: noop)]),
        height: 360,
      );
      await tester.tap(find.byTooltip(l10n.commentsMenu));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'mute_comment_menu');
    });

    testWidgets('a muted writer\'s comment collapses; the reply stays ${variant.name}', (tester) async {
      Comment byWriter(String id, Author author, String body, {String? parentId, bool muted = false, int likes = 0}) => Comment(
            id: id,
            articleId: 'art-1',
            parentId: parentId,
            body: body,
            author: author,
            createdAt: DateTime.utc(2026, 11, 2, 10),
            likeCount: likes,
            isAuthorMuted: muted,
          );
      final en = isEn(variant);
      final muted = byWriter('c-1', omarWriter, en ? 'You are all wrong about DI.' : 'كلامكم كله غلط عن الـ DI.', muted: true, likes: 3);
      final reply = byWriter('c-2', daliaWriter, en ? 'I disagree, it saved our project.' : 'مش متفقة، ده أنقذ المشروع بتاعنا.', parentId: 'c-1');
      final other = byWriter('c-3', editorial, en ? 'Great summary, thanks!' : 'تلخيص حلو جدًا، شكرًا!', likes: 5);
      final noop = CommentCallbacks(onLike: (_) {}, onReply: (_) {}, onMenu: (_, _) {}, onMoreReplies: (_) {});
      await pump(
        tester,
        variant,
        ListView(
          children: [
            CommentThreadView(thread: CommentThread(comment: muted, replies: [reply]), callbacks: noop),
            CommentThreadView(thread: CommentThread(comment: other), callbacks: noop),
          ],
        ),
        height: 420,
      );
      await expectGolden(tester, variant, 'mute_comments');
    });

    for (final (name, data) in [('mute_settings', sampleMutes), ('mute_settings_empty', const Mutes())]) {
      testWidgets('Settings → Muted: $name ${variant.name}', (tester) async {
        when(() => repository.getMutes()).thenAnswer((_) async => Ok(data));
        usePhoneSurface(tester, size: const Size(390, 640));
        final session = MockSessionCubit();
        whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
        follows = FollowsCubit(SetFollowing(MockFollowRepository()));
        mutes = mutesCubit(repository, session: session, follows: follows);
        final list = MutedListCubit(GetMutes(repository), mutes!);
        addTearDown(list.close);
        await list.load();
        await tester.pumpWidget(testApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: session),
              BlocProvider<MutesCubit>.value(value: mutes!),
              BlocProvider<MutedListCubit>.value(value: list),
            ],
            child: const MutedView(),
          ),
          variant: variant,
        ));
        await tester.pump();
        await expectGolden(tester, variant, name);
      });
    }
  }
}
