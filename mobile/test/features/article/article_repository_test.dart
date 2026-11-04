import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/data/datasources/article_api.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/data/repositories/article_repository_impl.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/social_fakes.dart';

class MockArticleApi extends Mock implements ArticleApi {}

void main() {
  late MockArticleApi api;
  late FakeArticleOfflineStore store;
  late ArticleRepositoryImpl repository;

  setUp(() {
    api = MockArticleApi();
    store = FakeArticleOfflineStore();
    repository = ArticleRepositoryImpl(api, store);
  });

  test('online: the article is remembered, and a saved one refreshes its device copy', () async {
    when(() => api.getArticle('article-1', 'ar-EG')).thenAnswer((_) async => detailsModel(1, isSaved: true));

    final result = await repository.getArticle('article-1', language: 'ar-EG');

    expect(result.valueOrNull!.isOfflineCopy, isFalse);
    expect(store.recent('art-1'), isNotNull);
    expect(await store.contains('art-1'), isTrue);
  });

  test('online: an article that is not saved gets no device copy', () async {
    when(() => api.getArticle('article-1', null)).thenAnswer((_) async => detailsModel(1));
    await repository.getArticle('article-1');
    expect(await store.contains('art-1'), isFalse);
  });

  test('offline: a saved article opens from its device copy', () async {
    await store.put(detailsModel(1, isSaved: true));
    when(() => api.getArticle('article-1', 'en')).thenThrow(offline('/articles/article-1'));

    final article = (await repository.getArticle('article-1', language: 'en')).valueOrNull!;

    expect(article.isOfflineCopy, isTrue);
    expect(article.card.language, 'ar-EG', reason: 'the language kept on the device');
    expect(article.content.blocks, isNotEmpty);
  });

  test('the preview (F34) asks for the version the card shows; a hidden article is not found', () async {
    when(() => api.getPreview('art-1', 'en')).thenAnswer(
      (_) async => ArticlePreviewModel.fromJson({
        'id': 'art-1',
        'language': 'en',
        'isComplete': false,
        'content': {'version': 1, 'language': 'en', 'blocks': <Object>[]},
      }),
    );
    final preview = (await repository.getPreview('art-1', language: 'en')).valueOrNull!;
    expect((preview.id, preview.language, preview.isComplete), ('art-1', 'en', false));

    when(() => api.getPreview('art-2', 'ar-EG')).thenThrow(httpError('/articles/art-2/preview', 404, code: 'article.not_found'));
    expect((await repository.getPreview('art-2', language: 'ar-EG')).failureOrNull!.code, FailureCodes.articleNotFound);
  });

  test('offline without a copy, or any other error, stays a failure', () async {
    when(() => api.getArticle('article-2', null)).thenThrow(offline('/articles/article-2'));
    expect((await repository.getArticle('article-2')).failureOrNull!.code, FailureCodes.networkOffline);

    await store.put(detailsModel(1, isSaved: true));
    when(() => api.getArticle('article-1', null)).thenThrow(httpError('/articles/article-1', 404, code: 'article.not_found'));
    expect((await repository.getArticle('article-1')).failureOrNull!.code, FailureCodes.articleNotFound);
  });
}
