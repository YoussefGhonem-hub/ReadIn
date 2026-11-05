import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/article/presentation/widgets/article_attachments_view.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/explore/domain/usecases/explore_usecases.dart';
import 'package:readin/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:readin/features/explore/presentation/pages/explore_page.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/features/follow/presentation/widgets/suggested_writers.dart';
import 'package:readin/features/search/data/datasources/recent_searches_store.dart';
import 'package:readin/features/search/domain/entities/search.dart';
import 'package:readin/features/search/domain/services/search_query.dart';
import 'package:readin/features/search/presentation/cubit/search_cubit.dart';
import 'package:readin/features/search/presentation/pages/search_page.dart';
import 'package:readin/features/search/presentation/widgets/search_result_rows.dart';
import 'package:readin/shared/widgets/state_views.dart';

import '../../helpers/explore_fixtures.dart' show FakeExploreRepository;
import '../../helpers/media_fixtures.dart' show samplePage;
import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/profile_fakes.dart';
import '../../helpers/search_fixtures.dart';
import '../../helpers/social_fakes.dart' show MockFollowRepository;
import '../../helpers/test_app.dart';

/// The search screen (F16): Explore's way in, recent searches, results as you type, the four tabs, the Articles
/// filters, "no results", errors, infinite scroll, and what opening a result does.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  const ar = Variant(AppLocales.ar, Brightness.light);
  late AppLocalizations l10nEn;
  late AppLocalizations l10nAr;

  setUpAll(() async {
    l10nEn = await AppLocalizations.delegate.load(AppLocales.en);
    l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
  });

  final input = find.byKey(const ValueKey('search-input'));

  Future<SearchCubit> pumpSearch(
    WidgetTester tester,
    FakeSearchRepository repo, {
    Variant variant = en,
    KeyValueStore? store,
    bool start = true,
  }) async {
    usePhoneSurface(tester);
    final cubit = searchCubit(repo, store: store);
    addTearDown(cubit.close);
    if (start) cubit.start();
    await tester.pumpWidget(testApp(
      provided([...appStores(), BlocProvider<SearchCubit>.value(value: cubit)], const SearchView()),
      variant: variant,
    ));
    await tester.pump();
    return cubit;
  }

  /// Types [text] and waits out the debounce and the answer.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(input, text);
    await tester.pump(SearchQuery.debounce);
    await tester.pump();
    await tester.pump();
  }

  testWidgets("Explore's search bar opens the search screen", (tester) async {
    final opened = <String>[];
    // Explore (F15) still loading: its search bar works already.
    final store = FollowsCubit(SetFollowing(MockFollowRepository()));
    final explore = ExploreCubit(GetExplore(FakeExploreRepository()..gate = Completer<void>()), store);
    addTearDown(explore.close);
    addTearDown(store.close);
    unawaited(explore.load());
    await pumpRouted(tester, const ExploreView(), opened: opened, providers: [BlocProvider<ExploreCubit>.value(value: explore)]);
    expect(find.text(l10nEn.searchHint), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('search-entry')));
    await tester.pumpAndSettle();
    expect(opened, ['/search']);
  });

  group('idle', () {
    testWidgets('with no recent searches: a hint', (tester) async {
      await pumpSearch(tester, FakeSearchRepository());
      expect(find.text(l10nEn.searchIdleTitle), findsOneWidget);
      expect(find.text(l10nEn.searchRecentTitle), findsNothing);
    });

    testWidgets('recent searches: tap one to search it, ✕ removes one, Clear all removes them', (tester) async {
      final store = InMemoryKeyValueStore({RecentSearchesStore.key: '["docker","الذكاء الاصطناعي","ef core"]'});
      final repo = FakeSearchRepository(articlePages: {'docker': [searchArticles(language: 'en')]});
      final cubit = await pumpSearch(tester, repo, store: store);

      expect(find.text(l10nEn.searchRecentTitle), findsOneWidget);
      // Each in its own direction.
      expect(tester.widget<Text>(find.text('الذكاء الاصطناعي')).textDirection, TextDirection.rtl);
      expect(tester.widget<Text>(find.text('docker')).textDirection, TextDirection.ltr);

      await tester.tap(find.byTooltip(l10nEn.searchRecentRemove('${String.fromCharCode(0x2068)}ef core${String.fromCharCode(0x2069)}')));
      await tester.pump();
      expect(find.text('ef core'), findsNothing);

      await tester.tap(find.text('docker'));
      await tester.pump();
      await tester.pump();
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).controller!.text, 'docker');
      expect(repo.calls, ['articles docker']);
      expect(find.byType(ArticleCardTile), findsNWidgets(3));

      // Cleared: back to the recent searches.
      await tester.tap(find.byKey(const ValueKey('search-clear')));
      await tester.pump();
      expect(cubit.state.isIdle, isTrue);
      await tester.tap(find.byKey(const ValueKey('search-recent-clear')));
      await tester.pump();
      expect(find.text(l10nEn.searchIdleTitle), findsOneWidget);
      expect(RecentSearchesStore(store).read(), isEmpty);
    });
  });

  group('results', () {
    testWidgets('as you type: the articles as compact rows, the PDF hint only where only the PDF matched', (tester) async {
      final repo = FakeSearchRepository(articlePages: {'agents': [searchArticles(language: 'en')]});
      await pumpSearch(tester, repo);
      await type(tester, 'agents');

      expect(repo.calls, ['articles agents']);
      expect(find.byType(ArticleCardTile), findsNWidgets(3));
      expect(find.byType(FoundInPdfNote), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const ValueKey('search-article-art-2')), matching: find.byType(FoundInPdfNote)),
        findsOneWidget,
      );
      expect(find.text(l10nEn.searchFoundInPdf), findsOneWidget);

      // Compact rows, like the web: no attachment pages under them; the PDF hit's thumbnail is the PDF's first page.
      expect(find.byType(ArticleAttachmentsView), findsNothing);
      final thumbnail = tester.widget<ArticleThumbnail>(
        find.descendant(of: find.byKey(const ValueKey('search-article-art-2')), matching: find.byType(ArticleThumbnail)),
      );
      expect(thumbnail.url, samplePage(1).thumbUrl);
    });

    testWidgets('an English query in the Arabic screen is laid out left to right', (tester) async {
      await pumpSearch(tester, FakeSearchRepository(), variant: ar);
      await tester.enterText(input, 'Docker');
      await tester.pump();
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).textDirection, TextDirection.ltr);
      await tester.enterText(input, 'دوكر');
      await tester.pump();
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).textDirection, TextDirection.rtl);
      await tester.pump(SearchQuery.debounce); // the search it started
    });

    testWidgets('the tabs: writers with Follow (not on your own row), topics, tags', (tester) async {
      final repo = fullSearchRepository(language: 'en');
      final cubit = await pumpSearch(tester, repo);
      await type(tester, 'agents');

      await tester.tap(find.text(l10nEn.searchTabWriters));
      await tester.pumpAndSettle();
      expect(cubit.state.type, SearchType.users);
      expect(find.byType(WriterTile), findsNWidgets(3));
      expect(find.byType(FollowButtonView), findsNWidgets(2), reason: 'none on your own row');
      expect(find.textContaining('@mona_dev'), findsOneWidget);

      await tester.tap(find.text(l10nEn.searchTabTopics));
      await tester.pumpAndSettle();
      expect(find.byType(SearchTopicRow), findsNWidgets(3));
      expect(find.text('${l10nEn.searchKindField} · ${l10nEn.tagPageArticleCount(57)}'), findsOneWidget);
      expect(find.text('AI · ${l10nEn.tagPageArticleCount(12)}'), findsOneWidget);

      await tester.tap(find.text(l10nEn.searchTabTags));
      await tester.pumpAndSettle();
      expect(find.byType(SearchTagRow), findsNWidgets(3));
      expect(find.text('#AI Agents'), findsOneWidget);
      expect(tester.widget<Text>(find.text('#الذكاء الاصطناعي')).textDirection, TextDirection.rtl);

      expect(repo.calls, ['articles agents', 'users agents', 'topics agents', 'tags agents']);
    });

    testWidgets('swiping to a tab searches it too', (tester) async {
      final repo = fullSearchRepository(language: 'en');
      await pumpSearch(tester, repo);
      await type(tester, 'agents');
      await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.byType(WriterTile), findsWidgets);
      expect(repo.calls, ['articles agents', 'users agents']);
    });

    testWidgets('no results: the query in quotes and a tip', (tester) async {
      await pumpSearch(tester, FakeSearchRepository(), variant: ar);
      await type(tester, 'zzzz');
      final empty = find.byKey(const ValueKey('search-empty'));
      expect(empty, findsOneWidget);
      expect(find.text(l10nAr.searchNoResultsTitle('${String.fromCharCode(0x2068)}zzzz${String.fromCharCode(0x2069)}')), findsOneWidget);
      expect(find.text(l10nAr.searchNoResultsTip), findsOneWidget);
      expect(l10nAr.searchNoResultsTitle('x'), 'مفيش نتايج لـ «x»');
    });

    testWidgets('an error offers retry, which searches again', (tester) async {
      final repo = FakeSearchRepository(articlePages: {'agents': [searchArticles(language: 'en')]})
        ..failure = const Failure(FailureCodes.networkOffline);
      await pumpSearch(tester, repo);
      await type(tester, 'agents');
      expect(find.byType(ErrorView), findsOneWidget);

      repo.failure = null;
      await tester.tap(find.text(l10nEn.retry));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ArticleCardTile), findsNWidgets(3));
      expect(repo.calls, ['articles agents', 'articles agents']);
    });

    testWidgets('skeleton rows while a tab loads', (tester) async {
      final repo = FakeSearchRepository()..gate = Completer<void>();
      await pumpSearch(tester, repo);
      await tester.enterText(input, 'agents');
      await tester.pump(SearchQuery.debounce);
      await tester.pump();
      expect(find.byKey(const ValueKey('search-skeleton')), findsOneWidget);
      repo.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('search-skeleton')), findsNothing);
    });

    testWidgets('scrolling to the end loads the next page', (tester) async {
      final repo = FakeSearchRepository(articlePages: {
        'agents': [
          [for (var i = 0; i < 6; i++) searchArticle(i, language: 'en')],
          [for (var i = 6; i < 9; i++) searchArticle(i, language: 'en')],
        ],
      });
      final cubit = await pumpSearch(tester, repo);
      await type(tester, 'agents');
      for (var i = 0; i < 6 && cubit.state.articles.hasMore; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump();
        await tester.pump();
      }
      expect(cubit.state.articles.items, hasLength(9));
      expect(repo.calls, ['articles agents', 'articles agents c1']);
    });
  });

  group('filters', () {
    testWidgets('a choice in its sheet searches again with it; the chip shows it; Clear filters', (tester) async {
      final repo = FakeSearchRepository(articlePages: {'agents': [searchArticles(language: 'en')]});
      final cubit = await pumpSearch(tester, repo);
      await type(tester, 'agents');

      await tester.tap(find.byKey(const ValueKey('search-filter-language')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.searchLanguageAny), findsOneWidget);
      await tester.tap(find.text(l10nEn.articleVersionEnglish));
      await tester.pumpAndSettle();
      expect(cubit.state.filters.language, 'en');

      await tester.tap(find.byKey(const ValueKey('search-filter-reading-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.searchReadingTime5To10).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('search-filter-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI').last);
      await tester.pumpAndSettle();

      expect(repo.calls, [
        'articles agents',
        'articles agents lang=en',
        'articles agents lang=en time=from5To10',
        'articles agents field=ai lang=en time=from5To10',
      ]);
      // The chips show the choices, and say them to screen readers.
      final chips = find.byKey(const ValueKey('search-filter-field'));
      expect(find.descendant(of: chips, matching: find.text('AI')), findsOneWidget);
      expect(find.bySemanticsLabel(l10nEn.searchFilterValue(l10nEn.searchFilterLanguage, l10nEn.articleVersionEnglish)), findsOneWidget);

      // Closing a sheet changes nothing.
      await tester.tap(find.byKey(const ValueKey('search-filter-language')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(cubit.state.filters.language, 'en');

      await tester.tap(find.byKey(const ValueKey('search-filter-clear')));
      await tester.pump();
      await tester.pump();
      expect(cubit.state.filters.isEmpty, isTrue);
      expect(repo.calls.last, 'articles agents');
    });

    testWidgets('no results with filters: the tip says so and offers to clear them', (tester) async {
      final repo = FakeSearchRepository(articlePages: {'agents': [searchArticles(language: 'en')]});
      final cubit = await pumpSearch(tester, repo);
      cubit.setFilters(const ArticleSearchFilters(readingTime: ReadingTimeFilter.over10));
      await type(tester, 'zzzz');
      expect(find.text(l10nEn.searchNoResultsFilteredTitle), findsOneWidget);
      expect(find.text(l10nEn.searchNoResultsFiltersTip('${String.fromCharCode(0x2068)}zzzz${String.fromCharCode(0x2069)}')), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, l10nEn.searchClearFilters));
      await tester.pump();
      await tester.pump();
      expect(cubit.state.filters.isEmpty, isTrue);
      expect(repo.calls, ['articles zzzz time=over10', 'articles zzzz']);
    });
  });

  group('opening a result', () {
    Future<(SearchCubit, List<String>)> pumpOpen(WidgetTester tester, FakeSearchRepository repo, SearchType type) async {
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit
        ..selectType(type)
        ..submit('agents');
      final opened = <String>[];
      await pumpRouted(tester, const SearchView(), opened: opened, providers: [BlocProvider<SearchCubit>.value(value: cubit)]);
      await tester.pump();
      await tester.pump();
      return (cubit, opened);
    }

    testWidgets('an article opens the reader in the version that matched', (tester) async {
      final (_, opened) = await pumpOpen(tester, fullSearchRepository(language: 'en'), SearchType.articles);
      await tester.tap(find.byKey(const ValueKey('search-article-art-1')));
      await tester.pumpAndSettle();
      expect(opened, ['/a/article-1?lang=en']);
    });

    testWidgets('a tag opens its page; the query becomes a recent search', (tester) async {
      final (cubit, opened) = await pumpOpen(tester, fullSearchRepository(language: 'en'), SearchType.tags);
      expect(cubit.state.recent, ['agents'], reason: 'submitted');
      await cubit.clearRecent();
      await tester.tap(find.byKey(const ValueKey('search-tag-ai-agents')));
      await tester.pumpAndSettle();
      expect(opened, ['/tags/ai-agents']);
      expect(cubit.state.recent, ['agents']);
    });

    testWidgets('a writer opens their profile', (tester) async {
      final (_, opened) = await pumpOpen(tester, fullSearchRepository(language: 'en'), SearchType.users);
      await tester.tap(find.text('Omar Khaled'));
      await tester.pumpAndSettle();
      expect(opened, ['/u/omar.k']);
    });

    testWidgets('opened from a link with no page under it, back goes Home', (tester) async {
      final (_, opened) = await pumpOpen(tester, fullSearchRepository(language: 'en'), SearchType.articles);
      await tester.tap(find.byKey(const ValueKey('search-home')));
      await tester.pumpAndSettle();
      expect(opened, ['/home']);
    });
  });
}
