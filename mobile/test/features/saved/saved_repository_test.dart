import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/data/datasources/article_api.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/saved/data/datasources/saved_api.dart';
import 'package:readin/features/saved/data/models/saved_models.dart';
import 'package:readin/features/saved/data/repositories/saved_repository_impl.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';

class MockSavedApi extends Mock implements SavedApi {}

class MockArticleApi extends Mock implements ArticleApi {}

SavedArticleModel savedModel(int i, {List<String> collections = const []}) => SavedArticleModel(
      savedAt: DateTime.utc(2026, 11, 3 - i),
      collectionIds: collections,
      article: ArticleCardModel.fromJson(detailsJson(i)),
    );

void main() {
  setUpAll(() => registerFallbackValue(const CollectionNameRequest(name: '')));

  late MockSavedApi api;
  late MockArticleApi articles;
  late FakeArticleOfflineStore store;
  late SavedRepositoryImpl repository;

  setUp(() {
    api = MockSavedApi();
    articles = MockArticleApi();
    store = FakeArticleOfflineStore();
    repository = SavedRepositoryImpl(api, articles, store);
  });

  group('device copies (F13: saved articles readable offline)', () {
    test('saving from the reader keeps the details it just loaded, without another request', () async {
      store.remember(detailsModel(1));
      when(() => api.save('art-1')).thenAnswer((_) async => const SaveStateModel(isSaved: true, saveCount: 8));

      final result = await repository.save(sampleCard(1));
      await repository.offlineWork;

      expect(result.valueOrNull!.saveCount, 8);
      final copy = await store.find('article-1');
      expect(copy!.isSaved, isTrue, reason: 'the copy says saved, so the bookmark is filled offline');
      verifyNever(() => articles.getArticle(any(), any()));
    });

    test('saving from a card fetches the details in the card language', () async {
      when(() => api.save('art-2')).thenAnswer((_) async => const SaveStateModel(isSaved: true, saveCount: 1));
      when(() => articles.getArticle('article-2', 'en')).thenAnswer((_) async => detailsModel(2, language: 'en'));

      await repository.save(sampleCard(2, language: 'en'));
      await repository.offlineWork;

      expect((await store.find('article-2'))!.language, 'en');
    });

    test('a failed save keeps nothing; unsaving drops the copy', () async {
      when(() => api.save('art-1')).thenThrow(offline('/me/saved/art-1'));
      expect((await repository.save(sampleCard(1))).failureOrNull!.code, FailureCodes.networkOffline);
      await repository.offlineWork;
      expect(await store.contains('art-1'), isFalse);

      await store.put(detailsModel(1, isSaved: true));
      when(() => api.unsave('art-1')).thenAnswer((_) async => const SaveStateModel(isSaved: false, saveCount: 6));
      await repository.unsave('art-1');
      await repository.offlineWork;
      expect(await store.contains('art-1'), isFalse);
    });

    test('save then unsave in a row leaves no copy behind', () async {
      when(() => api.save('art-2')).thenAnswer((_) async => const SaveStateModel(isSaved: true, saveCount: 1));
      when(() => api.unsave('art-2')).thenAnswer((_) async => const SaveStateModel(isSaved: false, saveCount: 0));
      when(() => articles.getArticle('article-2', 'ar-EG')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return detailsModel(2);
      });

      await repository.save(sampleCard(2));
      await repository.unsave('art-2');
      await repository.offlineWork;

      expect(await store.contains('art-2'), isFalse);
    });

    test('the full saved list keeps copies of articles saved elsewhere and drops unsaved ones', () async {
      await store.put(detailsModel(3, isSaved: true));
      when(() => api.getSaved(null, null, null, null, 20))
          .thenAnswer((_) async => SavedArticlePageModel(items: [savedModel(1), savedModel(2)]));
      when(() => articles.getArticle('article-1', 'ar-EG')).thenAnswer((_) async => detailsModel(1));
      when(() => articles.getArticle('article-2', 'ar-EG')).thenThrow(offline('/articles/article-2'));

      final page = (await repository.getSaved()).valueOrNull!;
      await repository.offlineWork;

      expect(page.items.every((item) => item.article.isSaved), isTrue);
      expect(await store.contains('art-1'), isTrue);
      expect(await store.contains('art-2'), isFalse, reason: 'a failed fetch is skipped, not fatal');
      expect(await store.contains('art-3'), isFalse, reason: 'no longer saved');
    });

    test('a filtered list neither syncs nor prunes', () async {
      await store.put(detailsModel(3, isSaved: true));
      when(() => api.getSaved('dotnet', 'di', null, null, 20)).thenAnswer((_) async => SavedArticlePageModel(items: [savedModel(1)]));

      await repository.getSaved(filter: const SavedFilter(fieldSlug: 'dotnet', query: ' di '));
      await repository.offlineWork;

      expect(await store.contains('art-3'), isTrue);
      verifyNever(() => articles.getArticle(any(), any()));
    });
  });

  group('offline list (F25)', () {
    setUp(() async {
      await store.put(detailsModel(0, isSaved: true), savedAt: DateTime.utc(2026, 11, 1)); // AI: "يعني إيه Dependency Injection…"
      await store.put(detailsModel(1, isSaved: true), savedAt: DateTime.utc(2026, 11, 2)); // .NET: "إزاي تختار"
      when(() => api.getSaved(any(), any(), any(), any(), any())).thenThrow(offline('/me/saved'));
    });

    test('the device copies come back as one page, newest saved first', () async {
      final page = (await repository.getSaved()).valueOrNull!;
      expect(page.offline, isTrue);
      expect(page.hasMore, isFalse);
      expect([for (final item in page.items) item.article.id], ['art-1', 'art-0']);
      expect(page.items.first.article.isSaved, isTrue);
    });

    test('field and title filters apply on the device, ignoring hamza forms and diacritics', () async {
      final byField = (await repository.getSaved(filter: const SavedFilter(fieldSlug: 'ai'))).valueOrNull!;
      expect([for (final item in byField.items) item.article.id], ['art-0']);

      final byTitle = (await repository.getSaved(filter: const SavedFilter(query: 'ازاي تختار'))).valueOrNull!;
      expect([for (final item in byTitle.items) item.article.id], ['art-1'], reason: '"ازاي" matches "إزاي"');

      final english = (await repository.getSaved(filter: const SavedFilter(query: 'scoped'))).valueOrNull!;
      expect(english.items, hasLength(1));
    });

    test('a collection filter, a next page or nothing on the device stay offline errors', () async {
      expect((await repository.getSaved(filter: const SavedFilter(collectionId: 'c-1'))).failureOrNull!.code, FailureCodes.networkOffline);
      expect((await repository.getSaved(cursor: 'next')).failureOrNull!.code, FailureCodes.networkOffline);
      await store.retainOnly({});
      expect((await repository.getSaved()).failureOrNull!.code, FailureCodes.networkOffline);
    });
  });

  group('collections', () {
    test('create trims the name; API codes come back as failures', () async {
      when(() => api.createCollection(const CollectionNameRequest(name: 'Interview prep')))
          .thenAnswer((_) async => CollectionModel(id: 'c-9', name: 'Interview prep', createdAt: DateTime.utc(2026)));
      final created = await repository.createCollection('Interview prep');
      expect(created.valueOrNull!.id, 'c-9');

      when(() => api.createCollection(any())).thenThrow(httpError('/me/collections', 409, code: 'collection.name_taken'));
      expect((await repository.createCollection('x')).failureOrNull!.code, FailureCodes.collectionNameTaken);
    });

    test('membership calls hit the collection and the article', () async {
      when(() => api.addToCollection('c-1', 'art-1')).thenAnswer((_) async {});
      when(() => api.removeFromCollection('c-1', 'art-1')).thenThrow(httpError('/me/collections/c-1', 404, code: 'collection.not_found'));
      expect((await repository.addToCollection('c-1', 'art-1')).isOk, isTrue);
      expect((await repository.removeFromCollection('c-1', 'art-1')).failureOrNull!.code, FailureCodes.collectionNotFound);
    });
  });

  test('normalizeForSearch folds Arabic letter forms and case', () {
    expect(normalizeForSearch('  أَحمد ومَكتبة  '), 'احمد ومكتبه');
    expect(normalizeForSearch('Dependency INJECTION'), 'dependency injection');
    expect(normalizeForSearch('مستشفى'), 'مستشفي');
  });
}
