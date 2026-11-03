import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/saved_list_cubit.dart';
import 'package:readin/features/taxonomy/domain/repositories/taxonomy_repository.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';

class MockTaxonomyRepository extends Mock implements TaxonomyRepository {}

void main() {
  late MockSavedRepository repository;
  late MockTaxonomyRepository taxonomy;
  late EngagementCubit engagement;
  late CollectionsCubit collections;

  final items = sampleSaved();

  setUpAll(() {
    registerFallbackValue(const SavedFilter());
    registerFallbackValue(sampleCard(0));
  });

  setUp(() {
    repository = MockSavedRepository();
    taxonomy = MockTaxonomyRepository();
    engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(repository));
    collections = CollectionsCubit(GetCollections(repository), ManageCollections(repository), engagement);
    when(() => taxonomy.getFields(refresh: any(named: 'refresh'))).thenAnswer((_) async => const Ok(sampleFields));
    when(() => repository.getSaved(filter: any(named: 'filter'), cursor: any(named: 'cursor'), limit: any(named: 'limit')))
        .thenAnswer((_) async => Ok(SavedArticlesPage(items: items, nextCursor: 'next')));
  });

  tearDown(() async {
    await collections.close();
    await engagement.close();
  });

  SavedListCubit build() => SavedListCubit(GetSavedArticles(repository), GetFields(taxonomy), engagement, collections);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('the first page loads with the field chips and feeds the shared stores', () async {
    final cubit = build();
    await cubit.load();
    await settle();

    expect(cubit.state.status, SavedListStatus.ready);
    expect(cubit.state.items, items);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.fields, sampleFields);
    expect(engagement.state.overlays.keys, containsAll(['art-0', 'art-1', 'art-2']));
    expect(collections.state.collectionsOf('art-0'), {'c-1'});
    await cubit.close();
  });

  test('search waits for typing to stop, then filters (debounced)', () async {
    Future<void> wait(Duration duration) => Future<void>.delayed(duration);
    const debounce = SavedListCubit.searchDebounce;
    final cubit = build();
    await cubit.load();

    cubit.search('D');
    await wait(debounce ~/ 3);
    cubit.search('DI ');
    await wait(debounce ~/ 2);
    verifyNever(() => repository.getSaved(filter: const SavedFilter(query: 'DI'), cursor: null, limit: 20));

    await wait(debounce);
    verify(() => repository.getSaved(filter: const SavedFilter(query: 'DI'), cursor: null, limit: 20)).called(1);
    verifyNever(() => repository.getSaved(filter: const SavedFilter(query: 'D'), cursor: null, limit: 20));
    expect(cubit.state.filter.query, 'DI');

    cubit.search('');
    await wait(debounce * 1.5);
    expect(cubit.state.filter, const SavedFilter());
    await cubit.close();
  });

  test('field and collection filters combine; an older response is dropped', () async {
    final cubit = build();
    await cubit.load();
    await cubit.selectField('dotnet');
    await cubit.selectCollection('c-1');
    expect(cubit.state.filter, const SavedFilter(fieldSlug: 'dotnet', collectionId: 'c-1'));
    verify(() => repository.getSaved(filter: const SavedFilter(fieldSlug: 'dotnet', collectionId: 'c-1'), cursor: null, limit: 20)).called(1);

    await cubit.selectCollection(null);
    expect(cubit.state.filter, const SavedFilter(fieldSlug: 'dotnet'));
    await cubit.close();
  });

  test('loadMore appends; offline pages are flagged and feed no stores', () async {
    when(() => repository.getSaved(filter: any(named: 'filter'), cursor: 'next', limit: 20))
        .thenAnswer((_) async => Ok(SavedArticlesPage(items: [items.first])));
    final cubit = build();
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.items, hasLength(4));
    expect(cubit.state.hasMore, isFalse);

    engagement.reset();
    when(() => repository.getSaved(filter: any(named: 'filter'), cursor: null, limit: 20))
        .thenAnswer((_) async => Ok(SavedArticlesPage(items: items, offline: true)));
    await cubit.refresh();
    expect(cubit.state.offline, isTrue);
    expect(engagement.state.overlays, isEmpty, reason: 'a device copy is older than what the app knows');
    await cubit.close();
  });

  test('an unsave anywhere removes the article; a save elsewhere reloads the list', () async {
    final cubit = build();
    await cubit.load();
    when(() => repository.unsave('art-1')).thenAnswer((_) async => const Ok(SaveState(isSaved: false, saveCount: 6)));
    await engagement.setSaved(items[1].article, saved: false);
    await settle();
    expect([for (final item in cubit.state.items) item.article.id], ['art-0', 'art-2']);

    clearInteractions(repository);
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(SaveState(isSaved: true, saveCount: 1)));
    await engagement.setSaved(sampleCard(3), saved: true);
    await settle();
    verify(() => repository.getSaved(filter: const SavedFilter(), cursor: null, limit: 20)).called(1);
    await cubit.close();
  });

  test('filtered by a collection: taking an article out removes it from the list', () async {
    final cubit = build();
    await cubit.selectCollection('c-1');
    when(() => repository.removeFromCollection('c-1', 'art-0')).thenAnswer((_) async => const Ok(null));
    await collections.remove('c-1', 'art-0');
    await settle();
    expect(cubit.state.items.map((item) => item.article.id), isNot(contains('art-0')));
    await cubit.close();
  });

  test('a failed first page is retryable; a failed refresh keeps the items', () async {
    when(() => repository.getSaved(filter: any(named: 'filter'), cursor: null, limit: 20))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.serverError)));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.status, SavedListStatus.failure);

    when(() => repository.getSaved(filter: any(named: 'filter'), cursor: null, limit: 20))
        .thenAnswer((_) async => Ok(SavedArticlesPage(items: items)));
    await cubit.load();
    when(() => repository.getSaved(filter: any(named: 'filter'), cursor: null, limit: 20))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.networkTimeout)));
    await cubit.refresh();
    expect(cubit.state.items, items);
    expect(cubit.state.loadMoreFailure!.code, FailureCodes.networkTimeout);
    await cubit.close();
  });
}
