import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';

void main() {
  late MockSavedRepository repository;
  late EngagementCubit engagement;
  late CollectionsCubit cubit;

  setUpAll(() => registerFallbackValue(sampleCard(0)));

  setUp(() {
    repository = MockSavedRepository();
    engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(repository));
    cubit = CollectionsCubit(GetCollections(repository), ManageCollections(repository), engagement);
    when(() => repository.getCollections()).thenAnswer((_) async => Ok(sampleCollections));
  });

  tearDown(() async {
    await cubit.close();
    await engagement.close();
  });

  ArticleCollection byId(String id) => cubit.state.byId(id)!;

  test('loads once; force reloads', () async {
    await cubit.load();
    await cubit.load();
    expect(cubit.state.status, CollectionsStatus.ready);
    expect(cubit.state.items, sampleCollections);
    await cubit.load(force: true);
    verify(() => repository.getCollections()).called(2);
  });

  test('a failed first load is a failure; a failed reload keeps the list', () async {
    when(() => repository.getCollections()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
    await cubit.load();
    expect(cubit.state.status, CollectionsStatus.failure);

    when(() => repository.getCollections()).thenAnswer((_) async => Ok(sampleCollections));
    await cubit.load(force: true);
    when(() => repository.getCollections()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
    await cubit.load(force: true);
    expect(cubit.state.status, CollectionsStatus.ready);
    expect(cubit.state.items, hasLength(3));
  });

  test('create and rename keep name order; API codes come back', () async {
    await cubit.load();
    when(() => repository.createCollection('Backend')).thenAnswer(
      (_) async => Ok(ArticleCollection(id: 'c-4', name: 'Backend', articleCount: 0, createdAt: DateTime.utc(2026))),
    );
    await cubit.create('  Backend  ');
    expect([for (final c in cubit.state.items) c.name], ['AI agents', 'Backend', 'Weekend reads', 'تحضير الإنترفيو']);

    when(() => repository.renameCollection('c-4', 'Zed')).thenAnswer(
      (_) async => Ok(ArticleCollection(id: 'c-4', name: 'Zed', articleCount: 0, createdAt: DateTime.utc(2026))),
    );
    expect(await cubit.rename('c-4', 'Zed'), isNull);
    expect(cubit.state.items[2].name, 'Zed');

    when(() => repository.createCollection('AI agents')).thenAnswer((_) async => const Err(Failure(FailureCodes.collectionNameTaken)));
    expect((await cubit.create('AI agents')).failureOrNull!.code, FailureCodes.collectionNameTaken);
    expect(cubit.state.items, hasLength(4));
  });

  test('delete is optimistic and comes back when refused', () async {
    await cubit.load();
    cubit.seedMembership([SavedArticle(savedAt: DateTime.utc(2026), article: sampleCard(0), collectionIds: const ['c-1'])]);

    when(() => repository.deleteCollection('c-1')).thenAnswer((_) async => const Err(Failure(FailureCodes.serverError)));
    expect((await cubit.delete('c-1'))!.code, FailureCodes.serverError);
    expect(cubit.state.byId('c-1'), isNotNull);
    expect(cubit.state.collectionsOf('art-0'), {'c-1'});

    when(() => repository.deleteCollection('c-1')).thenAnswer((_) async => const Ok(null));
    expect(await cubit.delete('c-1'), isNull);
    expect(cubit.state.byId('c-1'), isNull);
    expect(cubit.state.collectionsOf('art-0'), isEmpty);
  });

  test('add and remove an article: optimistic membership and counts, rollback, no double submits', () async {
    await cubit.load();
    final changes = <MembershipChange>[];
    final subscription = cubit.changes.listen(changes.add);
    final answer = Completer<Result<void>>();
    when(() => repository.addToCollection('c-2', 'art-0')).thenAnswer((_) => answer.future);

    final adding = cubit.add('c-2', 'art-0');
    expect(cubit.state.collectionsOf('art-0'), {'c-2'});
    expect(byId('c-2').articleCount, 2);
    expect(cubit.state.isBusy('c-2', 'art-0'), isTrue);
    expect(await cubit.add('c-2', 'art-0'), isNull);
    answer.complete(const Ok(null));
    await adding;
    await Future<void>.delayed(Duration.zero);
    expect(changes, [const MembershipChange(collectionId: 'c-2', articleId: 'art-0', added: true)]);
    verify(() => repository.addToCollection('c-2', 'art-0')).called(1);

    when(() => repository.removeFromCollection('c-2', 'art-0')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
    expect((await cubit.remove('c-2', 'art-0'))!.code, FailureCodes.networkOffline);
    expect(cubit.state.collectionsOf('art-0'), {'c-2'});
    expect(byId('c-2').articleCount, 2);
    await subscription.cancel();
  });

  test("the reader seeds an article's collections in order, except while a change is in flight", () async {
    await cubit.load();
    cubit.seedArticle('art-0', ['c-2', 'c-1']);
    expect(cubit.state.collectionsOf('art-0').toList(), ['c-2', 'c-1']);

    final answer = Completer<Result<void>>();
    when(() => repository.addToCollection('c-3', 'art-0')).thenAnswer((_) => answer.future);
    final adding = cubit.add('c-3', 'art-0');
    cubit.seedArticle('art-0', ['c-2', 'c-1']); // a reload that started before the add
    expect(cubit.state.collectionsOf('art-0').toList(), ['c-2', 'c-1', 'c-3'], reason: 'the optimistic add stays, last');

    answer.complete(const Err(Failure(FailureCodes.networkOffline)));
    await adding;
    expect(cubit.state.collectionsOf('art-0').toList(), ['c-2', 'c-1'], reason: 'rolled back');
    expect(byId('c-3').articleCount, 0);
  });

  test('collection.not_found: the collection leaves the list', () async {
    await cubit.load();
    when(() => repository.addToCollection('c-3', 'art-0')).thenAnswer((_) async => const Err(Failure(FailureCodes.collectionNotFound)));
    expect((await cubit.add('c-3', 'art-0'))!.code, FailureCodes.collectionNotFound);
    expect(cubit.state.byId('c-3'), isNull);
  });

  test('unsaving takes the article out of every collection', () async {
    await cubit.load();
    final card = sampleCard(0).copyWithEngagement(isSaved: true);
    cubit.seedMembership([SavedArticle(savedAt: DateTime.utc(2026), article: card, collectionIds: const ['c-1', 'c-2'])]);
    when(() => repository.unsave('art-0')).thenAnswer((_) async => const Ok(SaveState(isSaved: false, saveCount: 0)));

    await engagement.setSaved(card, saved: false);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.collectionsOf('art-0'), isEmpty);
    expect(byId('c-1').articleCount, 2);
    expect(byId('c-2').articleCount, 0);
  });
}
