import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/mutes/presentation/cubit/mutes_cubit.dart';
import 'package:readin/features/tags/domain/entities/tag.dart';
import 'package:readin/features/tags/domain/usecases/tag_usecases.dart';
import 'package:readin/features/tags/presentation/cubit/tag_cubits.dart';
import 'package:readin/features/tags/presentation/pages/tag_page.dart';
import 'package:readin/shared/widgets/state_views.dart';

import '../../helpers/fixtures.dart' show sampleMe;
import '../../helpers/mute_fixtures.dart' show mutesCubit, okMutesRepository;
import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart' show MockSessionCubit;
import '../../helpers/tag_fixtures.dart';
import '../../helpers/test_app.dart';

/// The tag page (F32): its header, the post cards with infinite scroll, the empty state, "not found" and retry.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  const ar = Variant(AppLocales.ar, Brightness.light);
  late AppLocalizations l10nEn;
  late AppLocalizations l10nAr;

  setUpAll(() async {
    l10nEn = await AppLocalizations.delegate.load(AppLocales.en);
    l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
  });

  Future<(TagCubit, TagArticlesCubit)> pumpPage(
    WidgetTester tester,
    FakeTagsRepository repo,
    String slug, {
    Variant variant = en,
    bool settle = true,
    List<BlocProvider> extra = const [],
  }) async {
    usePhoneSurface(tester);
    final header = TagCubit(GetTag(repo));
    final articles = TagArticlesCubit(GetTagArticles(repo), slug);
    final cards = PostCardsCubit.withLoader(previewLoader());
    addTearDown(header.close);
    addTearDown(articles.close);
    addTearDown(cards.close);
    unawaited(header.load(slug));
    unawaited(articles.load());
    await tester.pumpWidget(testApp(
      provided(
        [
          ...appStores(),
          BlocProvider<TagCubit>.value(value: header),
          BlocProvider<TagArticlesCubit>.value(value: articles),
          BlocProvider<PostCardsCubit>.value(value: cards),
          ...extra,
        ],
        const TagView(),
      ),
      variant: variant,
    ));
    if (settle) {
      await tester.pump();
      await tester.pump();
    }
    return (header, articles);
  }

  testWidgets('shows #name, the article count and the articles as post cards', (tester) async {
    final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': [tagPageCards(csharpTag, language: 'en')]});
    await pumpPage(tester, repo, 'csharp');

    expect(find.byKey(const ValueKey('tag-page-name')), findsOneWidget);
    expect(find.text('#C#'), findsWidgets);
    expect(find.text(l10nEn.tagPageArticleCount(42)), findsOneWidget);
    expect(find.byType(PostCard), findsWidgets);
    expect(repo.calls, ['tag csharp', 'articles csharp']);
  });

  // F28: a list that applies mutes counts only the cards it still shows.
  testWidgets('every card folded away by "show less": the next page loads by itself, then the empty state', (tester) async {
    final first = tagPageCards(csharpTag);
    final second = tagPageCards(csharpTag, first: 3);
    final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': [first, second]});
    final session = MockSessionCubit()..hold(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    final mutes = mutesCubit(okMutesRepository(), session: session);
    addTearDown(mutes.close);
    for (final card in [...first, ...second]) {
      expect(await mutes.showLess(card.id), isNull);
    }

    await pumpPage(tester, repo, 'csharp', extra: [BlocProvider<MutesCubit>.value(value: mutes)]);
    await tester.pumpAndSettle();

    expect(repo.calls, ['tag csharp', 'articles csharp', 'articles csharp c1']);
    expect(find.text(l10nEn.tagPageEmptyTitle), findsOneWidget);

    // Undo brings a card back, and the list with it.
    expect(await mutes.undoShowLess(second.first.id), isNull);
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.tagPageEmptyTitle), findsNothing);
    // The other three stay folded away (offstage).
    expect(find.byType(PostCard), findsOneWidget);
  });

  testWidgets('an Arabic tag reads right to left with its #', (tester) async {
    final repo = FakeTagsRepository(tags: const [aiArTag], pages: {aiArTag.slug: [tagPageCards(aiArTag)]});
    await pumpPage(tester, repo, aiArTag.slug, variant: ar);

    final name = tester.widget<Text>(find.byKey(const ValueKey('tag-page-name')));
    expect(name.data, '#الذكاء الاصطناعي');
    expect(name.textDirection, TextDirection.rtl);
    expect(find.text(l10nAr.tagPageArticleCount(31)), findsOneWidget);
  });

  testWidgets('an English tag in the Arabic UI keeps its own direction', (tester) async {
    final repo = FakeTagsRepository(tags: const [cppTag], pages: {'cplusplus': [tagPageCards(cppTag)]});
    await pumpPage(tester, repo, 'cplusplus', variant: ar);
    expect(tester.widget<Text>(find.byKey(const ValueKey('tag-page-name'))).textDirection, TextDirection.ltr);
  });

  testWidgets('scrolling to the end loads the next page with the cursor', (tester) async {
    final pages = [
      tagPageCards(csharpTag, first: 1, language: 'en'),
      tagPageCards(csharpTag, first: 3, language: 'en'),
      tagPageCards(csharpTag, first: 5, count: 1, language: 'en'),
    ];
    final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': pages});
    final (_, articles) = await pumpPage(tester, repo, 'csharp');
    expect(articles.state.items, hasLength(2));

    for (var i = 0; i < 6 && articles.state.hasMore; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pump();
      await tester.pump();
    }
    expect(articles.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4', 'art-5']);
    expect(repo.calls, containsAllInOrder(['articles csharp', 'articles csharp c1', 'articles csharp c2']));
  });

  testWidgets('an empty tag shows the empty state under its header', (tester) async {
    final repo = FakeTagsRepository(tags: const [emptyTag], pages: {'zig': const [[]]});
    await pumpPage(tester, repo, 'zig');

    expect(find.text('#Zig'), findsOneWidget);
    expect(find.text(l10nEn.tagPageArticleCount(0)), findsOneWidget);
    expect(find.text(l10nEn.tagPageEmptyTitle), findsOneWidget);
    expect(find.byType(PostCard), findsNothing);
  });

  testWidgets('an unknown or hidden tag says it does not exist', (tester) async {
    final repo = FakeTagsRepository();
    await pumpPage(tester, repo, missingTagSlug);

    expect(find.text(l10nEn.tagNotFoundTitle), findsOneWidget);
    expect(find.text(l10nEn.tagNotFoundBody), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing, reason: 'nothing to retry');
  });

  testWidgets('skeletons while loading; an error offers retry, which loads the page', (tester) async {
    final gate = Completer<void>();
    final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': [tagPageCards(csharpTag, language: 'en')]})
      ..gate = gate
      ..failure = const Failure(FailureCodes.networkOffline);
    await pumpPage(tester, repo, 'csharp', settle: false);
    await tester.pump();
    expect(find.byType(PostCardSkeleton), findsWidgets);

    gate.complete();
    repo.gate = null;
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);

    repo.failure = null;
    await tester.tap(find.text(l10nEn.retry));
    await tester.pump();
    await tester.pump();
    expect(find.text(l10nEn.tagPageArticleCount(42)), findsOneWidget);
    expect(find.byType(PostCard), findsWidgets);
  });

  testWidgets('opened from a link with no page under it, back goes Home', (tester) async {
    final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': [tagPageCards(csharpTag, language: 'en')]});
    final header = TagCubit(GetTag(repo));
    final articles = TagArticlesCubit(GetTagArticles(repo), 'csharp');
    final cards = PostCardsCubit.withLoader(previewLoader());
    addTearDown(header.close);
    addTearDown(articles.close);
    addTearDown(cards.close);
    unawaited(header.load('csharp'));
    unawaited(articles.load());
    final opened = <String>[];
    await pumpRouted(
      tester,
      const TagView(),
      opened: opened,
      providers: [
        BlocProvider<TagCubit>.value(value: header),
        BlocProvider<TagArticlesCubit>.value(value: articles),
        BlocProvider<PostCardsCubit>.value(value: cards),
      ],
    );
    await tester.pump();

    final home = find.byKey(const ValueKey('tag-page-home'));
    expect(home, findsOneWidget);
    expect(tester.widget<IconButton>(home).tooltip, const DefaultMaterialLocalizations().backButtonTooltip,
        reason: 'a labelled button, like the usual back button');
    await tester.tap(home);
    await tester.pumpAndSettle();
    expect(opened, ['/home']);
  });

  testWidgets('opened from the app, the usual back button goes back', (tester) async {
    final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': [tagPageCards(csharpTag, language: 'en')]});
    final header = TagCubit(GetTag(repo));
    final articles = TagArticlesCubit(GetTagArticles(repo), 'csharp');
    final cards = PostCardsCubit.withLoader(previewLoader());
    addTearDown(header.close);
    addTearDown(articles.close);
    addTearDown(cards.close);
    unawaited(header.load('csharp'));
    unawaited(articles.load());
    usePhoneSurface(tester);
    Widget page() => provided(
          [
            ...appStores(),
            BlocProvider<TagCubit>.value(value: header),
            BlocProvider<TagArticlesCubit>.value(value: articles),
            BlocProvider<PostCardsCubit>.value(value: cards),
          ],
          const TagView(),
        );
    await tester.pumpWidget(testApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page())),
          child: const Text('open tag'),
        ),
      ),
      variant: en,
    ));
    await tester.tap(find.text('open tag'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tag-page-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('tag-page-home')), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('open tag'), findsOneWidget);
  });

  test('the header and the list share "not found"', () {
    expect(isTagNotFound(FakeTagsRepository.notFound), isTrue);
    expect(isTagNotFound(const Failure('route.not_found', statusCode: 404)), isTrue);
    expect(isTagNotFound(const Failure(FailureCodes.networkOffline)), isFalse);
    expect(const ArticleTag(slug: 'csharp', name: 'C#').ref, const TagRef(slug: 'csharp', name: 'C#'));
  });
}
