import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/article/presentation/widgets/post_card_text.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/tags/presentation/widgets/tag_chip.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart' show routedTestApp;
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

/// The post card (F34): the excerpt with "Read more", expanding into the preview, the header's follow, tags, counts and
/// the action bar.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));
  setUp(() => CommentClock.now = () => DateTime.utc(2026, 11, 2, 12));
  tearDown(() => CommentClock.now = DateTime.now);

  String readMore() => PostExcerpt.moreLabel(l10n.postReadMore);

  group('PostExcerpt.fit', () {
    const style = TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 16, height: 1.7);
    const moreStyle = TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 16, height: 1.7, fontWeight: FontWeight.w600);

    String? fit(String text, {required bool continues, double width = 358}) => PostExcerpt.fit(
          text: text,
          more: readMore(),
          style: style,
          moreStyle: moreStyle,
          maxWidth: width,
          direction: TextDirection.ltr,
          continues: continues,
        );

    test('a short article shown whole has no button', () {
      expect(fit(shortEnExcerpt, continues: false), isNull);
    });

    test('a short excerpt of a longer article shows whole, then "… Read more"', () {
      expect(fit(shortEnExcerpt, continues: true), shortEnExcerpt);
    });

    test('a long excerpt is cut at the end of a word, leaving room for "… Read more" on the 4th line', () {
      final shown = fit(enExcerpt, continues: false)!;
      expect(enExcerpt.startsWith(shown), isTrue);
      expect(shown.length, lessThan(enExcerpt.length));
      expect(enExcerpt[shown.length], ' ', reason: 'cut at a word');
      expect(shown.endsWith(' '), isFalse);
      final painter = TextPainter(
        text: TextSpan(style: style, children: [TextSpan(text: shown), TextSpan(text: readMore(), style: moreStyle)]),
        textDirection: TextDirection.ltr,
        maxLines: PostExcerpt.maxLines,
      )..layout(maxWidth: 358);
      expect(painter.didExceedMaxLines, isFalse);
      painter.dispose();
    });

    test('an Arabic excerpt with English runs is cut before isolating, so no isolate stays open', () {
      final shown = PostExcerpt.fit(
        text: mixedExcerpt * 2,
        more: readMore(),
        style: style,
        moreStyle: moreStyle,
        maxWidth: 358,
        direction: TextDirection.rtl,
        continues: true,
      )!;
      expect((mixedExcerpt * 2).startsWith(shown), isTrue);
      final isolated = Bidi.isolateOppositeRuns(shown, TextDirection.rtl);
      expect(Bidi.fsi.allMatches(isolated).length, Bidi.pdi.allMatches(isolated).length);
    });
  });

  group('PostCardsCubit', () {
    test('the first expansion loads the preview in the card\'s language; later ones reuse it', () async {
      final calls = <String>[];
      final cubit = PostCardsCubit.withLoader(previewLoader(calls: calls));
      addTearDown(cubit.close);
      final card = postCard(1, language: 'en');

      await cubit.expand(card);
      expect(cubit.state.of(card.id).expanded, isTrue);
      expect(cubit.state.of(card.id).status, PreviewStatus.ready);
      cubit.collapse(card.id);
      expect(cubit.state.of(card.id).expanded, isFalse);
      expect(cubit.state.of(card.id).preview, isNotNull, reason: 'kept for the next expansion');
      await cubit.expand(card);

      expect(calls, ['art-1/en']);
    });

    test('a failed preview shows its failure and loads again on retry', () async {
      var fail = true;
      final cubit = PostCardsCubit.withLoader((id, {required language}) async {
        if (fail) return const Err(Failure(FailureCodes.networkOffline));
        return Ok(samplePreview(id, language: language));
      });
      addTearDown(cubit.close);
      final card = postCard(2);

      await cubit.expand(card);
      expect(cubit.state.of(card.id).status, PreviewStatus.failure);
      expect(cubit.state.of(card.id).failure?.code, FailureCodes.networkOffline);

      fail = false;
      await cubit.retry(card);
      expect(cubit.state.of(card.id).status, PreviewStatus.ready);
      expect(cubit.state.of(card.id).failure, isNull);
    });

    test('pull to refresh collapses every card and drops a preview still on its way', () async {
      final answer = Completer<Result<ArticlePreview>>();
      final cubit = PostCardsCubit.withLoader((id, {required language}) => answer.future);
      addTearDown(cubit.close);
      final card = postCard(3);

      final expanding = cubit.expand(card);
      cubit.reset();
      answer.complete(Ok(samplePreview(card.id)));
      await expanding;

      expect(cubit.state.cards, isEmpty);
    });
  });

  group('PostCard', () {
    Future<void> pump(
      WidgetTester tester,
      ArticleCard card, {
      PostCardsCubit? postCards,
      SessionState session = const SessionState(status: SessionStatus.authenticated, me: sampleMe),
      EngagementCubit? engagement,
      VoidCallback? onOpen,
      String? label,
    }) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        withCardStores(
          Scaffold(body: ListView(children: [PostCard(article: card, onOpen: onOpen, label: label)])),
          session: session,
          engagement: engagement,
          postCards: postCards,
        ),
        variant: en,
      ));
      await tester.pump();
    }

    testWidgets('a long excerpt ends with "… Read more"; a tap expands the preview in place', (tester) async {
      final calls = <String>[];
      final postCards = PostCardsCubit.withLoader(previewLoader(calls: calls));
      addTearDown(postCards.close);
      final semantics = tester.ensureSemantics();
      await pump(tester, postCard(1, language: 'en', cover: false), postCards: postCards);

      expect(find.textContaining(readMore(), findRichText: true), findsOneWidget);
      expect(
        tester.getSemantics(find.textContaining(readMore(), findRichText: true)),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false, hasTapAction: true),
      );

      await tester.tap(find.textContaining(readMore(), findRichText: true));
      await tester.pumpAndSettle();

      expect(calls, ['art-1/en']);
      expect(find.text('Program.cs'), findsOneWidget, reason: "the reader's own renderer draws the preview");
      expect(find.text(l10n.postReadFullArticle), findsOneWidget);
      expect(find.text(l10n.postShowLess), findsOneWidget);
      expect(find.textContaining(readMore(), findRichText: true), findsNothing);

      await tester.tap(find.text(l10n.postShowLess));
      await tester.pumpAndSettle();
      expect(find.text('Program.cs'), findsNothing);
      expect(find.textContaining(readMore(), findRichText: true), findsOneWidget);

      await tester.tap(find.textContaining(readMore(), findRichText: true));
      await tester.pumpAndSettle();
      expect(calls, hasLength(1), reason: 'the preview loaded once');
      semantics.dispose();
    });

    testWidgets('"Read the full article" opens the reader; a whole article has no such link', (tester) async {
      var opened = 0;
      final postCards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(postCards.close);
      await pump(tester, postCard(1, language: 'en', cover: false), postCards: postCards, onOpen: () => opened++);
      await tester.tap(find.textContaining(readMore(), findRichText: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.postReadFullArticle));
      expect(opened, 1);

      final whole = PostCardsCubit.withLoader(previewLoader(isComplete: true));
      addTearDown(whole.close);
      await pump(tester, postCard(2, language: 'en', cover: false), postCards: whole);
      await tester.tap(find.textContaining(readMore(), findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('Program.cs'), findsOneWidget);
      expect(find.text(l10n.postReadFullArticle), findsNothing);
      expect(find.text(l10n.postShowLess), findsOneWidget);
    });

    testWidgets('the title opens the reader; the text expands and never opens it', (tester) async {
      var opened = 0;
      final postCards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(postCards.close);
      final card = postCard(1, language: 'en', cover: false);
      await pump(tester, card, postCards: postCards, onOpen: () => opened++);

      await tester.tap(find.text(card.title));
      expect(opened, 1);
      await tester.tap(find.textContaining('Dependency Injection everywhere', findRichText: true));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(postCards.state.of(card.id).expanded, isTrue);
    });

    testWidgets('a short article shown whole has no "Read more", and its text does nothing', (tester) async {
      final calls = <String>[];
      final postCards = PostCardsCubit.withLoader(previewLoader(calls: calls));
      addTearDown(postCards.close);
      await pump(tester, shortPostCard(language: 'en'), postCards: postCards);

      expect(find.text(shortEnExcerpt), findsOneWidget);
      expect(find.textContaining(readMore(), findRichText: true), findsNothing);
      await tester.tap(find.text(shortEnExcerpt));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('no excerpt yet: the title alone, and "Read more" loads the beginning', (tester) async {
      final calls = <String>[];
      final postCards = PostCardsCubit.withLoader(previewLoader(calls: calls));
      addTearDown(postCards.close);
      await pump(tester, sampleCard(1, language: 'en'), postCards: postCards);

      await tester.tap(find.text(l10n.postReadMore));
      await tester.pumpAndSettle();
      expect(calls, ['art-1/en']);
      expect(find.text('Program.cs'), findsOneWidget);
    });

    testWidgets('a failed preview says why and tries again', (tester) async {
      var fail = true;
      final postCards = PostCardsCubit.withLoader((id, {required language}) async =>
          fail ? const Err(Failure(FailureCodes.networkOffline)) : Ok(samplePreview(id, language: language)));
      addTearDown(postCards.close);
      await pump(tester, postCard(1, language: 'en', cover: false), postCards: postCards);
      await tester.tap(find.textContaining(readMore(), findRichText: true));
      await tester.pumpAndSettle();

      expect(find.text(l10n.retry), findsOneWidget);
      expect(find.text(enExcerpt), findsOneWidget, reason: 'the whole excerpt stays while it failed');
      fail = false;
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();
      expect(find.text('Program.cs'), findsOneWidget);
    });

    testWidgets('collapsing brings the card back into view when its top scrolled off', (tester) async {
      final postCards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(postCards.close);
      final card = postCard(1, language: 'en', cover: false);
      usePhoneSurface(tester, size: const Size(390, 600));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(testApp(
        withCardStores(
          Scaffold(
            body: ListView(
              controller: controller,
              children: [const SizedBox(height: 300), PostCard(article: card), const SizedBox(height: 1200)],
            ),
          ),
          postCards: postCards,
        ),
        variant: en,
      ));
      await tester.tap(find.textContaining(readMore(), findRichText: true));
      await tester.pumpAndSettle();
      expect(controller.offset, 0, reason: 'expanding moves nothing');

      controller.jumpTo(500);
      await tester.pump();
      await tester.ensureVisible(find.text(l10n.postShowLess));
      await tester.pumpAndSettle();
      final cardTop = tester.getTopLeft(find.byType(PostCard)).dy;
      expect(cardTop, lessThan(0), reason: "the card's top is above the screen");

      await tester.tap(find.text(l10n.postShowLess));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(PostCard)).dy, greaterThanOrEqualTo(0));
    });

    testWidgets('header: the writer, field · time · reading time, and Follow while not following', (tester) async {
      await pump(tester, postCard(1, language: 'en'));

      expect(find.text('ReadIn Editorial'), findsOneWidget);
      expect(find.textContaining('3 days ago'), findsOneWidget);
      expect(find.byType(FollowButton), findsOneWidget);
      expect(find.text(l10n.follow), findsOneWidget);
    });

    testWidgets('no Follow for a writer you follow, your own article or a deleted user', (tester) async {
      await pump(tester, postCard(1, language: 'en', isFollowingAuthor: true));
      expect(find.byType(FollowButton), findsNothing);

      await pump(tester, postCard(1, language: 'en', author: const Author(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1')));
      expect(find.byType(FollowButton), findsNothing);

      await pump(tester, postCard(1, language: 'en', authorDeleted: true));
      expect(find.byType(FollowButton), findsNothing);
      expect(find.text(l10n.deletedUser), findsOneWidget);
    });

    testWidgets('guests see Follow and get the sign-in prompt', (tester) async {
      await pump(tester, postCard(1, language: 'en'), session: const SessionState(status: SessionStatus.guest));

      await tester.tap(find.text(l10n.follow));
      await tester.pumpAndSettle();
      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
    });

    testWidgets('up to three tags, each a link to its tag page, then a plain +N (F32)', (tester) async {
      final semantics = tester.ensureSemantics();
      final opened = <String>[];
      usePhoneSurface(tester);
      final (app, _) = routedTestApp(
        withCardStores(Scaffold(body: ListView(children: [PostCard(article: postCard(1, language: 'en', cover: false))]))),
        opened: opened,
      );
      await tester.pumpWidget(app);
      await tester.pump();

      expect(find.textContaining('#C#'), findsOneWidget);
      expect(find.textContaining('#Dependency Injection'), findsOneWidget);
      expect(find.textContaining('#ASP.NET Core'), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.postMoreTags(2)), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tag-link-csharp'))),
        isSemantics(label: '#C#', hint: l10n.tagOpenHint, isLink: true, hasTapAction: true),
      );

      await tester.tap(find.byKey(const ValueKey('tag-link-csharp')));
      await tester.pumpAndSettle();
      expect(opened, ['/tags/csharp']);
      semantics.dispose();
    });

    testWidgets('an Arabic tag opens its page with the slug percent-encoded', (tester) async {
      final opened = <String>[];
      usePhoneSurface(tester);
      const tag = TagRef(slug: 'الذكاء-الاصطناعي', name: 'الذكاء الاصطناعي');
      final (app, _) = routedTestApp(
        withCardStores(Scaffold(body: ListView(children: [PostCard(article: postCard(1, tags: const [tag], tagCount: 1))]))),
        opened: opened,
        variant: const Variant(AppLocales.ar, Brightness.light),
      );
      await tester.pumpWidget(app);
      await tester.pump();

      expect(find.byType(TagMoreChip), findsNothing, reason: 'no +N when every tag shows');
      await tester.tap(find.byKey(ValueKey('tag-link-${tag.slug}')));
      await tester.pumpAndSettle();
      expect(opened, ['/tags/${Uri.encodeComponent(tag.slug)}']);
    });

    testWidgets('the label, the reaction total and "12 comments"; none of them while both are 0', (tester) async {
      await pump(
        tester,
        postCard(1, language: 'en', cover: false, reactions: const ReactionCounts(insightful: 4, love: 1), reactionCount: 5, commentCount: 12),
        label: "Today's article",
      );
      expect(find.text("Today's article"), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text(l10n.commentsCount(12)), findsOneWidget);

      await pump(tester, postCard(2, language: 'en', cover: false));
      expect(find.text(l10n.commentsCount(0)), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('the action bar: React, Comment and Share, always shown', (tester) async {
      await pump(tester, shortPostCard(language: 'en'));
      expect(find.text(l10n.postReact), findsOneWidget);
      expect(find.text(l10n.postComment), findsOneWidget);
      expect(find.text(l10n.share), findsOneWidget);
    });

    testWidgets('a tap on React gives 💡 at once', (tester) async {
      final reactions = MockReactionsRepository();
      final engagement = EngagementCubit(SetReaction(reactions), SetSaved(MockSavedRepository()));
      addTearDown(engagement.close);
      when(() => reactions.react('art-7', ReactionType.insightful)).thenAnswer((_) async =>
          const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 1), total: 1, myReaction: ReactionType.insightful)));
      await pump(tester, shortPostCard(language: 'en'), engagement: engagement);

      await tester.tap(find.text(l10n.postReact));
      await tester.pump();
      expect(find.text(l10n.reactionInsightful), findsOneWidget);
      await tester.pumpAndSettle();
      verify(() => reactions.react('art-7', ReactionType.insightful)).called(1);
    });

    testWidgets('guests get the sign-in prompt instead of reacting', (tester) async {
      await pump(tester, shortPostCard(language: 'en'), session: const SessionState(status: SessionStatus.guest));
      await tester.tap(find.text(l10n.postReact));
      await tester.pumpAndSettle();
      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
    });

    testWidgets('Comment opens the comments in a sheet, and again after a profile opened from them', (tester) async {
      final comments = MockCommentsCubit();
      whenListen(
        comments,
        const Stream<CommentsState>.empty(),
        initialState: CommentsState(status: CommentsStatus.ready, threads: [CommentThread.of(comment('c1', body: 'Great read'))], total: 1),
      );
      when(() => comments.load(any())).thenAnswer((_) async {});
      final mentions = MockMentionSuggestionsCubit();
      whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
      getIt
        ..registerFactory<CommentsCubit>(() => comments)
        ..registerFactory<MentionSuggestionsCubit>(() => mentions);
      addTearDown(() => getIt
        ..unregister<CommentsCubit>()
        ..unregister<MentionSuggestionsCubit>());
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => Scaffold(body: ListView(children: [PostCard(article: shortPostCard(language: 'en'))]))),
          GoRoute(path: '/u/:username', builder: (_, state) => Scaffold(body: Text('profile ${state.pathParameters['username']}'))),
        ],
      );
      addTearDown(router.dispose);
      usePhoneSurface(tester);
      // Above the app, as in ReadInApp: the sheet is a route of its own.
      await tester.pumpWidget(withCardStores(MaterialApp.router(
        theme: AppTheme.light(AppLocales.en),
        locale: AppLocales.en,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.postComment));
      await tester.pumpAndSettle();
      expect(find.text('Great read'), findsOneWidget);

      await tester.tap(find.text(omar.displayName));
      await tester.pumpAndSettle();
      expect(find.text('profile ${omar.username}'), findsOneWidget);
      expect(find.text('Great read'), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Great read'), findsOneWidget, reason: 'the comments are open again');
      verify(() => comments.load('art-7')).called(2);
    });

    testWidgets('every action has a label for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, postCard(1, language: 'en'));

      expect(find.bySemanticsLabel(l10n.reactAction), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.postComment), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.share), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.postCoverImage), findsOneWidget);
      expect(find.byTooltip(l10n.saveArticle), findsOneWidget);
      expect(find.byTooltip(l10n.articleMenu), findsOneWidget);
      expect(
        tester.getSemantics(find.text(postCard(1, language: 'en').title)),
        isSemantics(isLink: true, hasTapAction: true, hint: l10n.postOpenArticleHint),
      );
      semantics.dispose();
    });
  });
}

