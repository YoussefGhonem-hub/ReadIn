import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/categories/domain/usecases/category_usecases.dart';
import 'package:readin/features/categories/presentation/cubit/category_cubits.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';

import '../../helpers/category_fixtures.dart';

/// The category page's cubits, a profile's Categories tab and the writer's own list (F31).
void main() {
  group('CategoryPageCubit + CategoryArticlesCubit', () {
    test('the header and the newest-first pages, with the cursor', () async {
      final repo = FakeCategoriesRepository(
        mine: const [efCore],
        pages: {efCore.slug: categoryPageOf(efCore)},
        articles: {
          efCore.slug: [categoryCards(first: 1), categoryCards(first: 3, count: 1)],
        },
      );
      final header = CategoryPageCubit(GetCategoryPage(repo));
      final articles = CategoryArticlesCubit(GetCategoryArticles(repo), 'mona_dev', efCore.slug);
      addTearDown(header.close);
      addTearDown(articles.close);

      await header.load('mona_dev', efCore.slug);
      await articles.load();
      expect(header.state.status, CategoryLoadStatus.ready);
      expect(header.state.page?.name, 'EF Core');
      expect(articles.state.items.map((a) => a.id), ['art-1', 'art-2']);

      await articles.loadMore();
      expect(articles.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3']);
      expect(articles.state.hasMore, isFalse);
      expect(repo.calls, ['page mona_dev ef-core', 'articles mona_dev ef-core', 'articles mona_dev ef-core c1']);
    });

    test('an unknown slug is "not found"; a deleted writer is not a missing category', () async {
      final repo = FakeCategoriesRepository();
      final header = CategoryPageCubit(GetCategoryPage(repo));
      addTearDown(header.close);
      await header.load('mona_dev', 'old-name');
      expect(header.state.notFound, isTrue);
      expect(header.state.writerNotFound, isFalse);

      repo.failure = FakeCategoriesRepository.userNotFound;
      await header.load('gone', 'x');
      expect(header.state.writerNotFound, isTrue);
      expect(header.state.notFound, isFalse);
    });

    test('a failed refresh keeps the header', () async {
      final repo = FakeCategoriesRepository(pages: {efCore.slug: categoryPageOf(efCore)});
      final header = CategoryPageCubit(GetCategoryPage(repo));
      addTearDown(header.close);
      await header.load('mona_dev', efCore.slug);
      repo.failure = const Failure(FailureCodes.networkOffline);
      await header.refresh();
      expect(header.state.status, CategoryLoadStatus.ready);
      expect(header.state.page?.slug, efCore.slug);
    });

    test('an empty category answers with its empty state', () async {
      final repo = FakeCategoriesRepository(pages: {draftsOnly.slug: categoryPageOf(draftsOnly)}, articles: {draftsOnly.slug: const [[]]});
      final articles = CategoryArticlesCubit(GetCategoryArticles(repo), 'mona_dev', draftsOnly.slug);
      addTearDown(articles.close);
      await articles.load();
      expect(articles.state.status, FeedStatus.ready);
      expect(articles.state.isEmpty, isTrue);
    });
  });

  group('ProfileCategoriesCubit', () {
    test('someone else\'s categories: the non-empty ones and the uncategorized count', () async {
      final repo = FakeCategoriesRepository(mine: const [backendTips, draftsOnly, efCore], uncategorized: 2);
      final cubit = ProfileCategoriesCubit(GetUserCategories(repo), 'mona_dev');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.items, const [backendTips, efCore]);
      expect(cubit.state.uncategorizedCount, 2);
      expect(repo.calls, ['user mona_dev']);
    });

    test('a failure offers retry; a failed refresh keeps the list', () async {
      final repo = FakeCategoriesRepository(mine: const [backendTips])..failure = const Failure(FailureCodes.networkOffline);
      final cubit = ProfileCategoriesCubit(GetUserCategories(repo), 'mona_dev');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, CategoryLoadStatus.failure);

      repo.failure = null;
      await cubit.load();
      expect(cubit.state.items, const [backendTips]);
      repo.failure = const Failure(FailureCodes.networkOffline);
      await cubit.refresh();
      expect(cubit.state.items, const [backendTips]);
    });
  });

  group('MyCategoriesCubit', () {
    late FakeCategoriesRepository repo;
    late MyCategoriesCubit cubit;

    setUp(() async {
      repo = FakeCategoriesRepository(mine: const [backendTips, efCore, careerAr, draftsOnly], uncategorized: 2);
      cubit = MyCategoriesCubit(GetMyCategories(repo), ManageCategories(repo));
      await cubit.load();
    });
    tearDown(() => cubit.close());

    test('the own list has the empty categories too', () {
      expect(cubit.state.items.map((c) => c.id), ['c-1', 'c-2', 'c-3', 'c-4']);
      expect(cubit.state.items.last.isEmpty, isTrue);
      expect(cubit.state.full, isFalse);
    });

    test('create adds it last; a taken name is refused and changes nothing', () async {
      final created = await cubit.create('Rust');
      expect(created.isOk, isTrue);
      expect(cubit.state.items.last.name, 'Rust');

      final taken = await cubit.create('ef core');
      expect(taken.failureOrNull?.code, FailureCodes.categoryNameTaken);
      expect(cubit.state.items, hasLength(5));
    });

    test('rename keeps the slug', () async {
      expect(await cubit.rename('c-2', 'EF Core 10'), isNull);
      final renamed = cubit.state.items.firstWhere((c) => c.id == 'c-2');
      expect(renamed.name, 'EF Core 10');
      expect(renamed.slug, 'ef-core');
    });

    test('delete moves its articles to "مقالات تانية"', () async {
      expect(await cubit.delete('c-1'), isNull);
      expect(cubit.state.items.map((c) => c.id), ['c-2', 'c-3', 'c-4']);
      expect(cubit.state.uncategorizedCount, 2 + backendTips.articleCount);
      expect(repo.calls.last, 'delete c-1');
    });

    test('move shows the new order at once and sends every id in it', () async {
      final done = cubit.move(3, 0);
      expect(cubit.state.items.map((c) => c.id), ['c-4', 'c-1', 'c-2', 'c-3']);
      expect(cubit.state.busy, isTrue);
      expect(await done, isNull);
      expect(repo.calls.last, 'reorder c-4,c-1,c-2,c-3');
      expect(cubit.state.items.map((c) => c.sortOrder), [1, 2, 3, 4]);
      expect(cubit.state.busy, isFalse);
    });

    test('a refused reorder puts the old order back', () async {
      repo.failures['reorder'] = const Failure(FailureCodes.networkOffline);
      final failure = await cubit.move(0, 1);
      expect(failure?.code, FailureCodes.networkOffline);
      expect(cubit.state.items.map((c) => c.id), ['c-1', 'c-2', 'c-3', 'c-4']);
      expect(cubit.state.busy, isFalse);
    });

    test('a move out of range, or while one runs, does nothing', () async {
      expect(await cubit.move(0, 0), isNull);
      expect(await cubit.move(0, 9), isNull);
      final gate = Completer<void>();
      repo.gate = gate;
      final first = cubit.move(0, 1);
      expect(await cubit.move(1, 2), isNull);
      gate.complete();
      await first;
      expect(repo.calls.where((c) => c.startsWith('reorder')), hasLength(1));
    });
  });
}
