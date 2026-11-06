import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/categories/domain/usecases/category_usecases.dart';
import 'package:readin/features/categories/presentation/cubit/category_cubits.dart';
import 'package:readin/features/categories/presentation/pages/category_page.dart';
import 'package:readin/features/profile/presentation/widgets/profile_link.dart';
import 'package:readin/shared/widgets/state_views.dart';

import '../../helpers/category_fixtures.dart';
import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/test_app.dart';

/// A writer's category page (F31): its header with the writer, the post cards with infinite scroll, "مقالات أخرى",
/// the empty state, "not found" with the way to the profile, and retry.
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  const ar = Variant(AppLocales.ar, Brightness.light);
  late AppLocalizations l10nEn;
  late AppLocalizations l10nAr;

  setUpAll(() async {
    l10nEn = await AppLocalizations.delegate.load(AppLocales.en);
    l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
  });

  (CategoryPageCubit, CategoryArticlesCubit, PostCardsCubit) cubits(FakeCategoriesRepository repo, String slug) {
    final header = CategoryPageCubit(GetCategoryPage(repo));
    final articles = CategoryArticlesCubit(GetCategoryArticles(repo), 'mona_dev', slug);
    final cards = PostCardsCubit.withLoader(previewLoader());
    addTearDown(header.close);
    addTearDown(articles.close);
    addTearDown(cards.close);
    unawaited(header.load('mona_dev', slug));
    unawaited(articles.load());
    return (header, articles, cards);
  }

  List<BlocProvider> providers((CategoryPageCubit, CategoryArticlesCubit, PostCardsCubit) c) => [
        BlocProvider<CategoryPageCubit>.value(value: c.$1),
        BlocProvider<CategoryArticlesCubit>.value(value: c.$2),
        BlocProvider<PostCardsCubit>.value(value: c.$3),
      ];

  Future<(CategoryPageCubit, CategoryArticlesCubit)> pumpPage(
    WidgetTester tester,
    FakeCategoriesRepository repo,
    String slug, {
    Variant variant = en,
    bool settle = true,
  }) async {
    usePhoneSurface(tester);
    final c = cubits(repo, slug);
    await tester.pumpWidget(testApp(provided([...appStores(), ...providers(c)], const CategoryView(username: 'mona_dev')), variant: variant));
    if (settle) {
      await tester.pump();
      await tester.pump();
    }
    return (c.$1, c.$2);
  }

  testWidgets('shows the name, the count, the writer and the articles as post cards', (tester) async {
    final repo = FakeCategoriesRepository(pages: {efCore.slug: categoryPageOf(efCore)}, articles: {efCore.slug: [categoryCards(language: 'en')]});
    await pumpPage(tester, repo, efCore.slug);

    expect(tester.widget<Text>(find.byKey(const ValueKey('category-page-name'))).data, 'EF Core');
    expect(find.text(l10nEn.categoryArticleCount(3)), findsOneWidget);
    expect(find.textContaining(categoryWriter.displayName), findsWidgets);
    expect(find.byType(PostCard), findsWidgets);
    expect(repo.calls, ['page mona_dev ef-core', 'articles mona_dev ef-core']);
  });

  testWidgets('an Arabic name with English in it reads right to left, its English run isolated', (tester) async {
    final repo = FakeCategoriesRepository(pages: {backendTips.slug: categoryPageOf(backendTips)}, articles: {backendTips.slug: [categoryCards()]});
    await pumpPage(tester, repo, backendTips.slug, variant: ar);

    final name = tester.widget<Text>(find.byKey(const ValueKey('category-page-name')));
    expect(name.textDirection, TextDirection.rtl);
    expect(name.data, contains('Backend'));
    expect(find.text(l10nAr.categoryArticleCount(7)), findsOneWidget);
  });

  testWidgets('"_other" is "مقالات تانية"', (tester) async {
    final repo = FakeCategoriesRepository(pages: {'_other': otherPage(count: 2)}, articles: {'_other': [categoryCards()]});
    await pumpPage(tester, repo, '_other', variant: ar);
    expect(tester.widget<Text>(find.byKey(const ValueKey('category-page-name'))).data, l10nAr.categoriesOther);
    expect(find.text(l10nAr.categoryArticleCount(2)), findsOneWidget);
  });

  testWidgets('scrolling to the end loads the next page with the cursor', (tester) async {
    final repo = FakeCategoriesRepository(
      pages: {efCore.slug: categoryPageOf(efCore)},
      articles: {
        efCore.slug: [categoryCards(first: 1, language: 'en'), categoryCards(first: 3, language: 'en'), categoryCards(first: 5, count: 1, language: 'en')],
      },
    );
    final (_, articles) = await pumpPage(tester, repo, efCore.slug);
    for (var i = 0; i < 6 && articles.state.hasMore; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pump();
      await tester.pump();
    }
    expect(articles.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4', 'art-5']);
    expect(repo.calls, containsAllInOrder(['articles mona_dev ef-core', 'articles mona_dev ef-core c1', 'articles mona_dev ef-core c2']));
  });

  testWidgets('an empty category shows its empty state under the header', (tester) async {
    final repo = FakeCategoriesRepository(pages: {draftsOnly.slug: categoryPageOf(draftsOnly)}, articles: {draftsOnly.slug: const [[]]});
    await pumpPage(tester, repo, draftsOnly.slug);
    expect(find.text(l10nEn.categoryArticleCount(0)), findsOneWidget);
    expect(find.text(l10nEn.categoryPageEmptyTitle), findsOneWidget);
    expect(find.text(l10nEn.categoryPageEmptyBody), findsOneWidget);
    expect(find.byType(PostCard), findsNothing);
  });

  testWidgets('an empty "_other" says every article is in a category, never "this category"', (tester) async {
    final repo = FakeCategoriesRepository(pages: {'_other': otherPage(count: 0)}, articles: {'_other': const [[]]});
    await pumpPage(tester, repo, '_other');
    expect(find.text(l10nEn.categoryOtherEmptyTitle), findsOneWidget);
    expect(find.text(l10nEn.categoryOtherEmptyBody), findsOneWidget);
    expect(find.text(l10nEn.categoryPageEmptyTitle), findsNothing);
    expect(find.byType(PostCard), findsNothing);
  });

  testWidgets('an unknown slug says it does not exist and leads to the writer\'s profile', (tester) async {
    final opened = <String>[];
    final c = cubits(FakeCategoriesRepository(), 'old-name');
    await pumpRouted(tester, const CategoryView(username: 'mona_dev'), opened: opened, providers: providers(c));
    await tester.pump();
    await tester.pump();

    expect(find.text(l10nEn.categoryNotFoundTitle), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing, reason: 'nothing to retry');
    await tester.tap(find.byKey(const ValueKey('category-writer-profile')));
    await tester.pumpAndSettle();
    expect(opened, ['/u/mona_dev']);
  });

  testWidgets('a deleted writer shows the profile\'s "not available"', (tester) async {
    final repo = FakeCategoriesRepository()..failure = FakeCategoriesRepository.userNotFound;
    await pumpPage(tester, repo, 'ef-core');
    expect(find.text(l10nEn.profileNotFoundTitle), findsOneWidget);
  });

  testWidgets('the writer row opens their profile', (tester) async {
    final opened = <String>[];
    final repo = FakeCategoriesRepository(pages: {efCore.slug: categoryPageOf(efCore)}, articles: {efCore.slug: const [[]]});
    final c = cubits(repo, efCore.slug);
    await pumpRouted(tester, const CategoryView(username: 'mona_dev'), opened: opened, providers: providers(c));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(ProfileLink).first);
    await tester.pumpAndSettle();
    expect(opened, ['/u/mona_dev']);
  });

  testWidgets('skeletons while loading; an error offers retry, which loads the page', (tester) async {
    final gate = Completer<void>();
    final repo = FakeCategoriesRepository(pages: {efCore.slug: categoryPageOf(efCore)}, articles: {efCore.slug: [categoryCards(language: 'en')]})
      ..gate = gate
      ..failure = const Failure(FailureCodes.networkOffline);
    await pumpPage(tester, repo, efCore.slug, settle: false);
    await tester.pump();
    expect(find.byType(PostCardSkeleton), findsWidgets);

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);

    repo
      ..gate = null
      ..failure = null;
    await tester.tap(find.text(l10nEn.retry));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(PostCard), findsWidgets);
  });
}
