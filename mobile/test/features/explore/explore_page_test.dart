import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/explore/domain/entities/explore.dart';
import 'package:readin/features/explore/domain/usecases/explore_usecases.dart';
import 'package:readin/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:readin/features/explore/presentation/pages/explore_page.dart';
import 'package:readin/features/explore/presentation/pages/explore_ranking_page.dart';
import 'package:readin/features/explore/presentation/widgets/explore_widgets.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/paths/presentation/widgets/home_path_card.dart';
import 'package:readin/features/paths/presentation/widgets/path_widgets.dart';
import 'package:readin/shared/widgets/state_views.dart';

import '../../helpers/explore_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

/// The Explore tab (F15): its sections (hidden when empty), "See all", every field and the writers' rail (as on the web),
/// names in the app's language, the links, loading, error and empty states, and the rankings in full.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  const ar = Variant(AppLocales.ar, Brightness.light);
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

  ExploreCubit exploreCubit(FakeExploreRepository repo) {
    final store = FollowsCubit(SetFollowing(MockFollowRepository()));
    final cubit = ExploreCubit(GetExplore(repo), store);
    addTearDown(cubit.close);
    addTearDown(store.close);
    return cubit;
  }

  Future<ExploreCubit> pumpExplore(
    WidgetTester tester,
    FakeExploreRepository repo, {
    Variant variant = en,
    Me? me = sampleMe,
    bool settle = true,
    Size size = const Size(390, 2600),
  }) async {
    usePhoneSurface(tester, size: size);
    final cubit = exploreCubit(repo);
    unawaited(cubit.load());
    await tester.pumpWidget(testApp(
      provided([...appStores(me: me), BlocProvider<ExploreCubit>.value(value: cubit)], const ExploreView()),
      variant: variant,
    ));
    if (settle) {
      await tester.pump();
      await tester.pump();
    }
    return cubit;
  }

  Future<List<String>> pumpExploreRouted(WidgetTester tester, FakeExploreRepository repo) async {
    final opened = <String>[];
    final cubit = exploreCubit(repo);
    unawaited(cubit.load());
    await pumpRouted(
      tester,
      const ExploreView(),
      opened: opened,
      providers: [BlocProvider<ExploreCubit>.value(value: cubit)],
      size: const Size(390, 2600),
    );
    await tester.pump();
    return opened;
  }

  testWidgets('shows every section under the search bar', (tester) async {
    final repo = FakeExploreRepository(explore: sampleExplore(lang: 'en'));
    await pumpExplore(tester, repo);

    expect(find.byKey(const ValueKey('search-entry')), findsOneWidget);
    for (final title in [l10n.exploreFields, l10n.exploreTrending, l10n.exploreMostSaved, l10n.exploreNewWriters, l10n.exploreFeaturedPaths]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.byType(FieldTile), findsNWidgets(8), reason: 'every enabled field, as on the web');
    expect(find.descendant(of: find.byKey(const ValueKey('explore-field-dotnet')), matching: find.text('.NET')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('explore-field-dotnet')), matching: find.text(l10n.fieldArticleCount(64))), findsOneWidget);
    expect(find.byType(ExploreArticleRow), findsNWidgets(ExploreView.previewCount * 2), reason: 'a few rows of each ranking');
    expect(find.byType(ArticleCardTile), findsNWidgets(6), reason: 'the compact row; See all has the post cards');
    expect(find.byType(PostCard), findsNothing);
    expect(find.byType(WriterCard), findsNWidgets(5), reason: 'every new writer the API sends, in the rail');
    expect(find.byType(PathCardTile), findsNWidgets(2));
    expect(find.byType(PathsPromptRow), findsNothing);
    expect(find.text(l10n.exploreSeeAll), findsNWidgets(3), reason: 'the two rankings and the paths');
    expect(repo.calls, ['explore']);
  });

  testWidgets('a section with nothing in it is hidden, featured paths too', (tester) async {
    final repo = FakeExploreRepository(explore: ExploreSections(fields: exploreFields(lang: 'en').take(3).toList(), mostSaved: exploreCards(count: 2)));
    await pumpExplore(tester, repo);

    expect(find.text(l10n.exploreFields), findsOneWidget);
    expect(find.text(l10n.exploreMostSaved), findsOneWidget);
    expect(find.text(l10n.exploreTrending), findsNothing);
    expect(find.text(l10n.exploreNewWriters), findsNothing);
    expect(find.text(l10n.exploreFeaturedPaths), findsNothing);
    expect(find.byType(FieldTile), findsNWidgets(3));
    expect(find.byType(ExploreArticleRow), findsNWidgets(2));
    // Changed on purpose (F15 fix): no paths row in place of an empty section; Home and the profile lead to /paths.
    expect(find.byType(PathsPromptRow), findsNothing);
    expect(find.byKey(const ValueKey('explore-see-all-paths')), findsNothing);
  });

  testWidgets('nothing at all: the empty state under the search bar', (tester) async {
    await pumpExplore(tester, FakeExploreRepository());
    expect(find.byKey(const ValueKey('search-entry')), findsOneWidget);
    expect(find.text(l10n.exploreEmptyTitle), findsOneWidget);
    expect(find.text(l10n.exploreEmptyBody), findsOneWidget);
  });

  testWidgets('skeletons while loading; an error offers retry, which loads Explore', (tester) async {
    final gate = Completer<void>();
    final repo = FakeExploreRepository(explore: sampleExplore(lang: 'en'))
      ..gate = gate
      ..failure = const Failure(FailureCodes.networkOffline);
    await pumpExplore(tester, repo, settle: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('explore-skeleton')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-entry')), findsOneWidget, reason: 'search works while Explore loads');

    gate.complete();
    repo.gate = null;
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);

    repo.failure = null;
    await tester.tap(find.text(l10n.retry));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FieldTile), findsWidgets);
    expect(repo.calls, ['explore', 'explore']);
  });

  testWidgets('every field shows at once, each name in the language the app is in, even one loaded in another', (tester) async {
    // Loaded while the app was in English, shown after switching to Arabic (the tab stays alive in the shell).
    final l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
    await pumpExplore(tester, FakeExploreRepository(explore: sampleExplore(lang: 'en')), variant: ar);
    expect(find.byType(FieldTile), findsNWidgets(8));
    Finder inTile(String slug, Finder finder) => find.descendant(of: find.byKey(ValueKey('explore-field-$slug')), matching: finder);
    expect(inTile('medicine', find.text('الطب')), findsOneWidget);
    expect(inTile('medicine', find.text('Medicine')), findsNothing);
    expect(inTile('ai-fundamentals', find.textContaining('أساسيات')), findsOneWidget);
    expect(inTile('law', find.text(l10nAr.fieldArticleCount(0))), findsOneWidget, reason: '"0 مقال", as on the web');
  });

  testWidgets('new writers: every one in a rail that scrolls sideways, with Follow; none on your own card', (tester) async {
    await pumpExplore(tester, FakeExploreRepository(explore: sampleExplore(lang: 'en')));
    final rail = find.byKey(const ValueKey('explore-new-writers'));
    expect(find.descendant(of: rail, matching: find.byType(WriterCard)), findsNWidgets(5));
    expect(tester.widget<SingleChildScrollView>(find.descendant(of: rail, matching: find.byType(SingleChildScrollView))).scrollDirection, Axis.horizontal);
    final own = find.byKey(ValueKey('explore-writer-${sampleMe.id}'));
    expect(find.descendant(of: own, matching: find.text(l10n.follow)), findsNothing);
    expect(find.descendant(of: find.byKey(const ValueKey('explore-writer-w-3')), matching: find.text(l10n.follow)), findsOneWidget);
    // The cards are as tall as each other, your own (no Follow) too.
    expect(tester.getSize(own).height, tester.getSize(find.byKey(const ValueKey('explore-writer-w-3'))).height);

    // The last card scrolls into view.
    await tester.drag(find.descendant(of: rail, matching: find.byType(SingleChildScrollView)), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(own).right, lessThanOrEqualTo(390));
  });

  testWidgets('every tile opens its page: a field, an article, See all, a path, the paths', (tester) async {
    final repo = FakeExploreRepository(explore: sampleExplore(lang: 'en'));
    final opened = await pumpExploreRouted(tester, repo);

    Future<void> openAndBack(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await openAndBack(find.byKey(const ValueKey('explore-field-dotnet')));
    await openAndBack(find.byKey(const ValueKey('explore-article-art-1')));
    await openAndBack(find.byKey(const ValueKey('explore-see-all-trending')));
    await openAndBack(find.byKey(const ValueKey('explore-see-all-most-saved')));
    await openAndBack(find.byKey(const ValueKey('explore-path-ai-agents-101')));
    await openAndBack(find.byKey(const ValueKey('explore-see-all-paths')));
    await openAndBack(find.byKey(const ValueKey('search-entry')));
    expect(opened, ['/f/dotnet', '/a/article-1', '/explore/trending', '/explore/most-saved', '/paths/ai-agents-101', '/paths', '/search']);
  });

  testWidgets('"See all" is one labelled button per section', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpExplore(tester, FakeExploreRepository(explore: sampleExplore(lang: 'en')));
    expect(find.bySemanticsLabel(l10n.exploreSeeAllSection(l10n.exploreTrending)), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.exploreSeeAllSection(l10n.exploreMostSaved)), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Arabic: the sections read right to left, names with English runs stay whole', (tester) async {
    final l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
    await pumpExplore(tester, FakeExploreRepository(explore: sampleExplore()), variant: ar);
    expect(Directionality.of(tester.element(find.byType(ExploreView))), TextDirection.rtl);
    expect(find.text(l10nAr.exploreTrending), findsOneWidget);
    expect(find.text(l10nAr.exploreSeeAll), findsNWidgets(3));
    // "Deep Learning و LLMs": the English runs are isolated in the Arabic UI (SPEC §14).
    final mixed = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('explore-field-deep-learning-llms')), matching: find.byType(Text)).first);
    expect(mixed.data, contains(Bidi.fsi));
    expect(mixed.data!.replaceAll(Bidi.fsi, '').replaceAll(Bidi.pdi, ''), 'Deep Learning و LLMs');
  });

  testWidgets('signing in or out loads Explore again (the viewer state on every section)', (tester) async {
    final sessions = StreamController<SessionState>.broadcast();
    addTearDown(sessions.close);
    final session = MockSessionCubit();
    whenListen(session, sessions.stream, initialState: const SessionState(status: SessionStatus.guest));
    final repo = FakeExploreRepository(explore: sampleExplore(lang: 'en'));
    usePhoneSurface(tester, size: const Size(390, 2600));
    final cubit = exploreCubit(repo);
    unawaited(cubit.load());
    await tester.pumpWidget(testApp(
      provided([...appStores(me: null), BlocProvider<SessionCubit>.value(value: session), BlocProvider<ExploreCubit>.value(value: cubit)], const ExploreView()),
      variant: en,
    ));
    await tester.pump();
    expect(repo.calls, ['explore']);

    sessions.add(const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    await tester.pump();
    await tester.pump();
    expect(repo.calls, ['explore', 'explore']);
  });

  group('See all', () {
    Future<ExploreRankingCubit> pumpRanking(WidgetTester tester, FakeExploreRepository repo, ExploreRanking ranking) async {
      usePhoneSurface(tester);
      final cubit = ExploreRankingCubit(GetExploreRanking(repo), ranking);
      final cards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(cubit.close);
      addTearDown(cards.close);
      unawaited(cubit.load());
      await tester.pumpWidget(testApp(
        provided(
          [...appStores(), BlocProvider<ExploreRankingCubit>.value(value: cubit), BlocProvider<PostCardsCubit>.value(value: cards)],
          const ExploreRankingView(),
        ),
        variant: en,
      ));
      await tester.pump();
      await tester.pump();
      return cubit;
    }

    testWidgets('the ranking in full as post cards, with its title and infinite scroll', (tester) async {
      final repo = FakeExploreRepository(rankings: {
        ExploreRanking.trending: [exploreCards(count: 2, language: 'en'), exploreCards(first: 3, count: 2, language: 'en')],
      });
      final cubit = await pumpRanking(tester, repo, ExploreRanking.trending);

      expect(find.widgetWithText(AppBar, l10n.exploreTrending), findsOneWidget);
      expect(find.byType(PostCard), findsWidgets);
      for (var i = 0; i < 6 && cubit.state.hasMore; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump();
        await tester.pump();
      }
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4']);
      expect(repo.calls, ['trending', 'trending c1']);
    });

    testWidgets('most saved: its title, and the empty state when nobody saved anything', (tester) async {
      await pumpRanking(tester, FakeExploreRepository(), ExploreRanking.mostSaved);
      expect(find.widgetWithText(AppBar, l10n.exploreMostSaved), findsOneWidget);
      expect(find.text(l10n.exploreMostSavedEmptyTitle), findsOneWidget);
      expect(find.text(l10n.exploreRankingEmptyBody), findsOneWidget);
    });

    testWidgets('an error offers retry', (tester) async {
      final repo = FakeExploreRepository(rankings: {ExploreRanking.trending: [exploreCards(count: 1, language: 'en')]})
        ..failure = const Failure(FailureCodes.networkOffline);
      await pumpRanking(tester, repo, ExploreRanking.trending);
      expect(find.byType(ErrorView), findsOneWidget);
      repo.failure = null;
      await tester.tap(find.text(l10n.retry));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PostCard), findsOneWidget);
    });
  });
}
