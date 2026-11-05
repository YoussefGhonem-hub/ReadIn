@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/explore/presentation/pages/explore_page.dart';
import 'package:readin/features/search/data/datasources/recent_searches_store.dart';
import 'package:readin/features/search/domain/entities/search.dart';
import 'package:readin/features/search/presentation/cubit/search_cubit.dart';
import 'package:readin/features/search/presentation/pages/search_page.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

import '../helpers/fake_media.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/search_fixtures.dart';
import '../helpers/test_app.dart';

/// Search (F16) in ar/light and en/dark (SPEC §27): Explore's search bar, the recent searches, article results as
/// compact rows with a filter set and the "found in the attached PDF" hint (that row's thumbnail is the PDF's first
/// page, with no pages under it), writers with Follow, topics, tags, and "no results". Images come from [FakeMedia].
void main() {
  setUpAll(() async {
    await FakeMedia.install();
    AppNetworkImage.providerFactory = FakeImageProvider.new;
  });
  tearDownAll(() => AppNetworkImage.providerFactory = NetworkImage.new);

  bool isEn(Variant variant) => variant.locale.languageCode == 'en';
  String languageOf(Variant variant) => isEn(variant) ? 'en' : 'ar-EG';

  Future<void> pumpSearch(
    WidgetTester tester,
    Variant variant, {
    required FakeSearchRepository repo,
    String? query,
    SearchType type = SearchType.articles,
    ArticleSearchFilters filters = const ArticleSearchFilters(),
    KeyValueStore? store,
  }) async {
    usePhoneSurface(tester);
    final cubit = searchCubit(repo, store: store);
    addTearDown(cubit.close);
    cubit
      ..start(type: type)
      ..setFilters(filters);
    if (query != null) cubit.input(query);
    await tester.pumpWidget(testApp(
      provided([...appStores(), BlocProvider<SearchCubit>.value(value: cubit)], SearchView(initialQuery: query)),
      variant: variant,
    ));
    // The debounce, the answer, and the tab bar's indicator.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  for (final variant in Variant.golden) {
    final en = isEn(variant);
    final query = searchQueryFor(en ? 'en' : 'ar');

    testWidgets('search explore entry ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(const ExplorePage(), variant: variant));
      await tester.pump();
      await expectLater(find.byType(ExplorePage), matchesVariantGolden(variant, 'goldens/search_explore_${variant.name}.png'));
    });

    testWidgets('search recent ${variant.name}', (tester) async {
      final store = InMemoryKeyValueStore({
        RecentSearchesStore.key: en
            ? '["agents","EF Core migrations","الذكاء الاصطناعي","@mona_dev"]'
            : '["ذكاء","Dependency Injection","إزاي أبدأ في الـ AI","@mona_dev"]',
      });
      await pumpSearch(tester, variant, repo: FakeSearchRepository(), store: store);
      await expectLater(find.byType(SearchView), matchesVariantGolden(variant, 'goldens/search_recent_${variant.name}.png'));
    });

    testWidgets('search articles ${variant.name}', (tester) async {
      await pumpSearch(
        tester,
        variant,
        repo: fullSearchRepository(language: languageOf(variant)),
        query: query,
        filters: const ArticleSearchFilters(readingTime: ReadingTimeFilter.upTo5),
      );
      await expectLater(find.byType(SearchView), matchesVariantGolden(variant, 'goldens/search_articles_${variant.name}.png'));
    });

    testWidgets('search writers ${variant.name}', (tester) async {
      await pumpSearch(tester, variant, repo: fullSearchRepository(language: languageOf(variant)), query: query, type: SearchType.users);
      await expectLater(find.byType(SearchView), matchesVariantGolden(variant, 'goldens/search_writers_${variant.name}.png'));
    });

    testWidgets('search topics ${variant.name}', (tester) async {
      await pumpSearch(tester, variant, repo: fullSearchRepository(language: languageOf(variant)), query: query, type: SearchType.topics);
      await expectLater(find.byType(SearchView), matchesVariantGolden(variant, 'goldens/search_topics_${variant.name}.png'));
    });

    testWidgets('search tags ${variant.name}', (tester) async {
      await pumpSearch(tester, variant, repo: fullSearchRepository(language: languageOf(variant)), query: query, type: SearchType.tags);
      await expectLater(find.byType(SearchView), matchesVariantGolden(variant, 'goldens/search_tags_${variant.name}.png'));
    });

    testWidgets('search empty ${variant.name}', (tester) async {
      await pumpSearch(tester, variant, repo: FakeSearchRepository(), query: en ? 'kubernetes operators' : 'كوبرنيتس');
      await expectLater(find.byType(SearchView), matchesVariantGolden(variant, 'goldens/search_empty_${variant.name}.png'));
    });
  }
}
