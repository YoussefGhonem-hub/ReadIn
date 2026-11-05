import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/search/data/datasources/recent_searches_store.dart';
import 'package:readin/features/search/domain/entities/search.dart';
import 'package:readin/features/search/domain/services/search_query.dart';
import 'package:readin/features/search/presentation/cubit/search_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/search_fixtures.dart';
import '../../helpers/social_fakes.dart';

/// The search screen's logic (F16): debounced as-you-type from 2 characters, Enter from 1, tabs loaded when shown,
/// the Articles filters, paging without repeats, stale answers dropped, errors and retry, and recent searches.
void main() {
  /// Lets the fake repository's answers through.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('typing', () {
    test('searches 300 ms after the last keystroke, from 2 characters', () {
      fakeAsync((async) {
        final repo = FakeSearchRepository(articlePages: {'dock': [searchArticles()]});
        final cubit = searchCubit(repo);

        cubit.input('d');
        async.elapse(const Duration(seconds: 1));
        expect(repo.calls, isEmpty, reason: 'one character waits for Enter');

        cubit.input('do');
        async.elapse(const Duration(milliseconds: 200));
        cubit.input('doc');
        async.elapse(const Duration(milliseconds: 200));
        cubit.input('dock');
        async.elapse(const Duration(milliseconds: 299));
        expect(repo.calls, isEmpty);
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();

        expect(repo.calls, ['articles dock']);
        expect(cubit.state.query, 'dock');
        expect(cubit.state.articles.status, SearchResultsStatus.ready);
        expect(cubit.state.articles.items, hasLength(3));
        expect(cubit.state.recent, isEmpty, reason: 'typing alone is not a recent search');
        unawaited(cubit.close());
      });
    });

    test('a cleaned query equal to the current one searches nothing new', () {
      fakeAsync((async) {
        final repo = FakeSearchRepository();
        final cubit = searchCubit(repo);
        cubit.input('docker');
        async.elapse(SearchQuery.debounce);
        async.flushMicrotasks();
        cubit.input('docker  ');
        cubit.input('  docker');
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(repo.calls, ['articles docker']);
        unawaited(cubit.close());
      });
    });

    test('clearing the box (or too little to search) shows the recent searches again', () async {
      final repo = FakeSearchRepository(articlePages: {'docker': [searchArticles()]});
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('docker');
      await settle();
      expect(cubit.state.isIdle, isFalse);

      cubit.input('d');
      expect(cubit.state.isIdle, isTrue);
      expect(cubit.state.articles, const SearchResults<SearchArticle>());
      cubit.input('');
      expect(cubit.state.isIdle, isTrue);
    });
  });

  group('Enter', () {
    test('searches at once from 1 character and remembers the search', () async {
      final store = InMemoryKeyValueStore();
      final repo = FakeSearchRepository(articlePages: {'C': [searchArticles(language: 'en')]});
      final cubit = searchCubit(repo, store: store);
      addTearDown(cubit.close);

      cubit.submit('C');
      expect(cubit.state.articles.status, SearchResultsStatus.loading);
      await settle();
      expect(repo.calls, ['articles C']);
      expect(cubit.state.articles.items, hasLength(3));
      await settle();
      expect(cubit.state.recent, ['C']);
      expect(RecentSearchesStore(store).read(), ['C']);
    });

    test('a query the API would refuse is not sent', () async {
      final repo = FakeSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('##');
      cubit.submit('@');
      cubit.submit('   ');
      await settle();
      expect(repo.calls, isEmpty);
      expect(cubit.state.recent, isEmpty);
    });

    test('cancels the pending as-you-type search', () {
      fakeAsync((async) {
        final repo = FakeSearchRepository();
        final cubit = searchCubit(repo);
        cubit.input('dock');
        cubit.submit('docker');
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(repo.calls, ['articles docker']);
        unawaited(cubit.close());
      });
    });
  });

  group('tabs', () {
    test('only the shown tab searches; another tab loads when shown, once per query', () async {
      final repo = fullSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      final q = searchQueryFor('ar');

      cubit.submit(q);
      await settle();
      expect(repo.calls, ['articles $q']);

      cubit.selectType(SearchType.users);
      await settle();
      cubit.selectType(SearchType.topics);
      await settle();
      cubit.selectType(SearchType.tags);
      await settle();
      cubit.selectType(SearchType.articles);
      cubit.selectType(SearchType.users);
      await settle();
      expect(repo.calls, ['articles $q', 'users $q', 'topics $q', 'tags $q'], reason: 'nothing loads twice');
      expect(cubit.state.users.items, searchWriters());
      expect(cubit.state.topics.items, hasLength(3));
      expect(cubit.state.tags.items, searchTags());
    });

    test('a new query drops every tab; the shown one searches it', () async {
      final repo = fullSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('first');
      await settle();
      cubit.selectType(SearchType.tags);
      await settle();

      cubit.submit('second');
      expect(cubit.state.articles.status, SearchResultsStatus.idle);
      expect(cubit.state.tags.status, SearchResultsStatus.loading);
      await settle();
      cubit.selectType(SearchType.articles);
      await settle();
      expect(repo.calls, ['articles first', 'tags first', 'tags second', 'articles second']);
    });

    test('a tab chosen before typing is the one searched', () async {
      final repo = fullSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.selectType(SearchType.users);
      await settle();
      expect(repo.calls, isEmpty, reason: 'nothing to search yet');
      cubit.submit('mona');
      await settle();
      expect(repo.calls, ['users mona']);
    });

    test('start: a /search?q=&type= link searches its tab at once and loads the fields', () async {
      final repo = fullSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.start(query: ' mona ', type: SearchType.users);
      await settle();
      expect(cubit.state.type, SearchType.users);
      expect(cubit.state.query, 'mona');
      expect(repo.calls, ['users mona']);
      expect(cubit.state.fields, sampleFields);
      expect(cubit.state.recent, isEmpty, reason: 'a link is not a search the user typed');
    });

    test("writers' follow state goes to the app-wide store", () async {
      final repo = FakeSearchRepository(userPages: {'mona': [searchWriters()]});
      final follows = FollowsCubit(SetFollowing(MockFollowRepository()));
      addTearDown(follows.close);
      final cubit = searchCubit(repo, follows: follows);
      addTearDown(cubit.close);
      cubit.selectType(SearchType.users);
      cubit.submit('mona');
      await settle();
      expect(follows.state.users['w-2']?.isFollowing, isTrue);
      expect(follows.state.users['w-1']?.isFollowing, isFalse);
    });
  });

  group('filters', () {
    test('changing them searches the Articles tab again with them; clearing goes back', () async {
      final repo = FakeSearchRepository(articlePages: {'docker': [searchArticles()]});
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('docker');
      await settle();

      cubit.setFilters(const ArticleSearchFilters(fieldSlug: 'ai'));
      await settle();
      cubit.setFilters(cubit.state.filters.copyWith(language: () => 'en', readingTime: ReadingTimeFilter.upTo5));
      await settle();
      cubit.setFilters(cubit.state.filters);
      cubit.setFilters(const ArticleSearchFilters());
      await settle();
      expect(repo.calls, [
        'articles docker',
        'articles docker field=ai',
        'articles docker field=ai lang=en time=upTo5',
        'articles docker',
      ]);
    });

    test('set before a query, they apply to the first search; other tabs ignore them', () async {
      final repo = fullSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.setFilters(const ArticleSearchFilters(readingTime: ReadingTimeFilter.over10));
      await settle();
      expect(repo.calls, isEmpty);
      cubit.submit('docker');
      await settle();
      cubit.selectType(SearchType.topics);
      await settle();
      expect(repo.calls, ['articles docker time=over10', 'topics docker']);
    });
  });

  group('paging', () {
    test('loads the next pages with the cursor and drops a result already shown', () async {
      final repo = FakeSearchRepository(articlePages: {
        'docker': [
          searchArticles(),
          [searchArticle(2), searchArticle(3), searchArticle(4)], // art-2 moved down a page
          [searchArticle(5)],
        ],
      });
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('docker');
      await settle();
      expect(cubit.state.articles.hasMore, isTrue);

      await cubit.loadMore();
      await cubit.loadMore();
      expect(cubit.state.articles.items.map((r) => r.article.id), ['art-0', 'art-1', 'art-2', 'art-3', 'art-4', 'art-5']);
      expect(cubit.state.articles.hasMore, isFalse);
      await cubit.loadMore();
      expect(repo.calls, ['articles docker', 'articles docker c1', 'articles docker c2']);
    });

    test('a failed page keeps what is shown and can be retried', () async {
      final repo = FakeSearchRepository(tagPages: {
        'ai': [
          [searchTags().first],
          [searchTags().last],
        ],
      });
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.selectType(SearchType.tags);
      cubit.submit('ai');
      await settle();

      repo.failure = const Failure(FailureCodes.networkOffline);
      await cubit.loadMore();
      expect(cubit.state.tags.items, hasLength(1));
      expect(cubit.state.tags.loadMoreFailure?.code, FailureCodes.networkOffline);

      repo.failure = null;
      await cubit.loadMore();
      expect(cubit.state.tags.items, hasLength(2));
      expect(cubit.state.tags.loadMoreFailure, isNull);
    });
  });

  group('answers and errors', () {
    test('an answer for an older query is dropped', () async {
      final gate = Completer<void>();
      final repo = FakeSearchRepository(articlePages: {
        'old': [[searchArticle(0)]],
        'new': [[searchArticle(1)]],
      })..gate = gate;
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);

      cubit.submit('old');
      await settle();
      repo.gate = null;
      cubit.submit('new');
      await settle();
      gate.complete();
      await settle();
      expect(cubit.state.query, 'new');
      expect(cubit.state.articles.items.single.article.id, 'art-1');
    });

    test('an error, then retry (or Enter on the same query) loads the tab again', () async {
      final repo = FakeSearchRepository(articlePages: {'docker': [searchArticles()]})
        ..failure = const Failure(FailureCodes.rateLimited, statusCode: 429);
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('docker');
      await settle();
      expect(cubit.state.articles.status, SearchResultsStatus.failure);
      expect(cubit.state.current.failure?.code, FailureCodes.rateLimited);

      cubit.retry();
      await settle();
      expect(cubit.state.articles.status, SearchResultsStatus.failure);

      repo.failure = null;
      cubit.submit('docker');
      await settle();
      expect(cubit.state.articles.status, SearchResultsStatus.ready);
      expect(repo.calls, ['articles docker', 'articles docker', 'articles docker']);
    });

    test('no results is ready and empty', () async {
      final repo = FakeSearchRepository();
      final cubit = searchCubit(repo);
      addTearDown(cubit.close);
      cubit.submit('zzzz');
      await settle();
      expect(cubit.state.articles.isEmpty, isTrue);
    });
  });

  group('recent searches', () {
    test('read at start; opening a result remembers the query; remove one; clear all', () async {
      final store = InMemoryKeyValueStore({RecentSearchesStore.key: '["ef core","أحمد"]'});
      final repo = FakeSearchRepository();
      final cubit = searchCubit(repo, store: store);
      addTearDown(cubit.close);
      expect(cubit.state.recent, ['ef core', 'أحمد']);

      cubit.remember();
      await settle();
      expect(cubit.state.recent, ['ef core', 'أحمد'], reason: 'nothing searched yet');

      cubit.input('docker');
      await Future<void>.delayed(SearchQuery.debounce + const Duration(milliseconds: 20));
      cubit.remember();
      await settle();
      expect(cubit.state.recent, ['docker', 'ef core', 'أحمد']);

      await cubit.removeRecent('EF Core');
      expect(cubit.state.recent, ['docker', 'أحمد']);
      await cubit.clearRecent();
      expect(cubit.state.recent, isEmpty);
      expect(RecentSearchesStore(store).read(), isEmpty);
    });
  });

  test('the shown tab and its results', () {
    const state = SearchState(type: SearchType.users, users: SearchResults<UserSummary>(status: SearchResultsStatus.ready));
    expect(state.current.status, SearchResultsStatus.ready);
    expect(state.current.isEmpty, isTrue);
    expect(state.resultsOf(SearchType.articles).status, SearchResultsStatus.idle);
    expect(state.isIdle, isTrue);
  });
}
