import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../data/datasources/recent_searches_store.dart';
import '../../domain/entities/search.dart';
import '../../domain/services/search_query.dart';
import '../../domain/usecases/search_usecases.dart';

enum SearchResultsStatus { idle, loading, ready, failure }

/// One tab's results: the first page, then more with the cursor.
class SearchResults<T> extends Equatable {
  const SearchResults({
    this.status = SearchResultsStatus.idle,
    this.request,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final SearchResultsStatus status;

  /// What these results answer (the query, plus the filters on Articles); null before the tab was searched.
  final String? request;
  final List<T> items;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;
  bool get isEmpty => status == SearchResultsStatus.ready && items.isEmpty;

  SearchResults<T> copyWith({
    SearchResultsStatus? status,
    List<T>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
  }) =>
      SearchResults<T>(
        status: status ?? this.status,
        request: request,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure != null ? failure() : this.failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
      );

  @override
  List<Object?> get props => [status, request, items, nextCursor, loadingMore, failure, loadMoreFailure];
}

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.type = SearchType.articles,
    this.filters = const ArticleSearchFilters(),
    this.articles = const SearchResults<SearchArticle>(),
    this.users = const SearchResults<UserSummary>(),
    this.topics = const SearchResults<SearchTopic>(),
    this.tags = const SearchResults<ArticleTag>(),
    this.recent = const [],
    this.fields = const [],
  });

  /// The query the tabs show results for, as sent (`SearchQuery.clean`); '' = nothing searched yet: the recent
  /// searches show.
  final String query;

  /// The tab shown.
  final SearchType type;

  /// The Articles tab's filters.
  final ArticleSearchFilters filters;
  final SearchResults<SearchArticle> articles;
  final SearchResults<UserSummary> users;
  final SearchResults<SearchTopic> topics;
  final SearchResults<ArticleTag> tags;

  /// The device's recent searches, newest first.
  final List<String> recent;

  /// The field filter's choices.
  final List<Field> fields;

  bool get isIdle => query.isEmpty;

  SearchResults<Object?> resultsOf(SearchType type) => switch (type) {
        SearchType.articles => articles,
        SearchType.users => users,
        SearchType.topics => topics,
        SearchType.tags => tags,
      };

  /// The shown tab's results.
  SearchResults<Object?> get current => resultsOf(type);

  SearchState copyWith({
    String? query,
    SearchType? type,
    ArticleSearchFilters? filters,
    SearchResults<SearchArticle>? articles,
    SearchResults<UserSummary>? users,
    SearchResults<SearchTopic>? topics,
    SearchResults<ArticleTag>? tags,
    List<String>? recent,
    List<Field>? fields,
  }) =>
      SearchState(
        query: query ?? this.query,
        type: type ?? this.type,
        filters: filters ?? this.filters,
        articles: articles ?? this.articles,
        users: users ?? this.users,
        topics: topics ?? this.topics,
        tags: tags ?? this.tags,
        recent: recent ?? this.recent,
        fields: fields ?? this.fields,
      );

  @override
  List<Object?> get props => [query, type, filters, articles, users, topics, tags, recent, fields];
}

/// How the cubit loads one tab: its request, the API call, where its results live in [SearchState], and the key of an
/// item (a later page may repeat one: results shift while articles are published).
class _Tab<T> {
  _Tab(this.type, {required this.fetch, required this.read, required this.write, required this.id, this.onItems});

  final SearchType type;
  final Future<Result<CursorPage<T>>> Function(String query, ArticleSearchFilters filters, String? cursor) fetch;
  final SearchResults<T> Function(SearchState state) read;
  final SearchState Function(SearchState state, SearchResults<T> results) write;
  final Object Function(T item) id;
  final void Function(List<T> items)? onItems;

  /// Incremented on every new search of the tab, so answers for an older one are dropped.
  int generation = 0;
}

/// The search screen (F16): the query typed (searched [SearchQuery.debounce] after the last keystroke, from 2
/// characters; Enter searches at once, from 1), the four tabs loaded when shown, the Articles tab's filters, infinite
/// scroll, and the device's recent searches. Writers' follow state goes to the app-wide [FollowsCubit].
@injectable
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._search, this._recent, this._getFields, this._follows) : super(SearchState(recent: _recent.read())) {
    _articles = _Tab<SearchArticle>(
      SearchType.articles,
      fetch: (q, filters, cursor) => _search.articles(q, filters: filters, cursor: cursor),
      read: (s) => s.articles,
      write: (s, r) => s.copyWith(articles: r),
      id: (a) => a.article.id,
    );
    _users = _Tab<UserSummary>(
      SearchType.users,
      fetch: (q, _, cursor) => _search.users(q, cursor: cursor),
      read: (s) => s.users,
      write: (s, r) => s.copyWith(users: r),
      id: (u) => u.id,
      onItems: (users) => _follows.seed({for (final user in users) user.id: user.isFollowing}),
    );
    _topics = _Tab<SearchTopic>(
      SearchType.topics,
      fetch: (q, _, cursor) => _search.topics(q, cursor: cursor),
      read: (s) => s.topics,
      write: (s, r) => s.copyWith(topics: r),
      id: (t) => '${t.kind.name}:${t.id}',
    );
    _tags = _Tab<ArticleTag>(
      SearchType.tags,
      fetch: (q, _, cursor) => _search.tags(q, cursor: cursor),
      read: (s) => s.tags,
      write: (s, r) => s.copyWith(tags: r),
      id: (t) => t.slug,
    );
  }

  final SearchContent _search;
  final RecentSearchesStore _recent;
  final GetFields _getFields;
  final FollowsCubit _follows;

  late final _Tab<SearchArticle> _articles;
  late final _Tab<UserSummary> _users;
  late final _Tab<SearchTopic> _topics;
  late final _Tab<ArticleTag> _tags;

  Timer? _debounce;

  /// The screen opened: loads the field filter's choices, shows [type] and searches [query] at once (a `/search?q=`
  /// link).
  void start({String? query, SearchType? type}) {
    unawaited(_loadFields());
    if (type != null) emit(state.copyWith(type: type));
    if (query != null && SearchQuery.canSearch(query, submitted: true)) _setQuery(SearchQuery.clean(query));
  }

  /// The box changed: searches [SearchQuery.debounce] after the last keystroke, from 2 characters. Too little to
  /// search shows the recent searches again (one character waits for Enter).
  void input(String text) {
    _debounce?.cancel();
    if (!SearchQuery.canSearch(text)) {
      if (!state.isIdle) _setQuery('');
      return;
    }
    final query = SearchQuery.clean(text);
    if (query == state.query) return;
    _debounce = Timer(SearchQuery.debounce, () {
      if (!isClosed) _setQuery(query);
    });
  }

  /// Enter: searches now, from 1 character, and remembers the search. The same query again retries a failed tab.
  void submit(String text) {
    _debounce?.cancel();
    if (!SearchQuery.canSearch(text, submitted: true)) return;
    final query = SearchQuery.clean(text);
    unawaited(_remember(query));
    if (query == state.query) {
      if (state.current.status == SearchResultsStatus.failure) retry();
      return;
    }
    _setQuery(query);
  }

  /// A result was opened: the query becomes a recent search (as Enter would).
  void remember() {
    if (!state.isIdle) unawaited(_remember(state.query));
  }

  /// Shows [type]'s tab, searching it when it doesn't hold the current query's results yet.
  void selectType(SearchType type) {
    if (type == state.type) return;
    emit(state.copyWith(type: type));
    _ensureLoaded(type);
  }

  /// The Articles tab's filters changed: its results load again.
  void setFilters(ArticleSearchFilters filters) {
    if (filters == state.filters) return;
    _articles.generation++;
    emit(state.copyWith(filters: filters, articles: const SearchResults<SearchArticle>()));
    if (state.type == SearchType.articles) _ensureLoaded(SearchType.articles);
  }

  /// The shown tab's first page again (after an error).
  void retry() {
    if (!state.isIdle) unawaited(_loadFirst(state.type));
  }

  /// The shown tab's next page.
  Future<void> loadMore() async {
    if (state.isIdle) return;
    await switch (state.type) {
      SearchType.articles => _loadMore(_articles),
      SearchType.users => _loadMore(_users),
      SearchType.topics => _loadMore(_topics),
      SearchType.tags => _loadMore(_tags),
    };
  }

  Future<void> removeRecent(String query) async {
    final recent = await _recent.remove(query);
    if (!isClosed) emit(state.copyWith(recent: recent));
  }

  Future<void> clearRecent() async {
    await _recent.clear();
    if (!isClosed) emit(state.copyWith(recent: const []));
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Every tab drops what it showed; the shown one searches [query] ('' = back to idle).
  void _setQuery(String query) {
    for (final tab in [_articles, _users, _topics, _tags]) {
      tab.generation++;
    }
    emit(state.copyWith(
      query: query,
      articles: const SearchResults<SearchArticle>(),
      users: const SearchResults<UserSummary>(),
      topics: const SearchResults<SearchTopic>(),
      tags: const SearchResults<ArticleTag>(),
    ));
    if (query.isNotEmpty) _ensureLoaded(state.type);
  }

  void _ensureLoaded(SearchType type) {
    if (state.isIdle) return;
    if (state.resultsOf(type).request == _requestFor(type)) return;
    unawaited(_loadFirst(type));
  }

  String _requestFor(SearchType type) {
    if (type != SearchType.articles) return state.query;
    final f = state.filters;
    return [state.query, f.fieldSlug ?? '', f.language ?? '', f.readingTime.name].join('\u0000');
  }

  /// The tabs' generics differ: each is loaded with its own type.
  Future<void> _loadFirst(SearchType type) => switch (type) {
        SearchType.articles => _load(_articles),
        SearchType.users => _load(_users),
        SearchType.topics => _load(_topics),
        SearchType.tags => _load(_tags),
      };

  Future<void> _load<T>(_Tab<T> tab) async {
    final generation = ++tab.generation;
    final query = state.query;
    final filters = state.filters;
    emit(tab.write(state, SearchResults<T>(status: SearchResultsStatus.loading, request: _requestFor(tab.type))));
    final result = await tab.fetch(query, filters, null);
    if (isClosed || generation != tab.generation) return;
    final current = tab.read(state);
    switch (result) {
      case Ok(value: final page):
        tab.onItems?.call(page.items);
        emit(tab.write(state, current.copyWith(status: SearchResultsStatus.ready, items: page.items, nextCursor: () => page.nextCursor)));
      case Err(:final failure):
        emit(tab.write(state, current.copyWith(status: SearchResultsStatus.failure, failure: () => failure)));
    }
  }

  Future<void> _loadMore<T>(_Tab<T> tab) async {
    final current = tab.read(state);
    if (current.status != SearchResultsStatus.ready || current.loadingMore || !current.hasMore) return;
    final generation = tab.generation;
    emit(tab.write(state, current.copyWith(loadingMore: true, loadMoreFailure: () => null)));
    final result = await tab.fetch(state.query, state.filters, current.nextCursor);
    if (isClosed || generation != tab.generation) return;
    final latest = tab.read(state);
    switch (result) {
      case Ok(value: final page):
        // Results shift between pages while articles are published or counters change: one already shown stays put.
        final shown = {for (final item in latest.items) tab.id(item)};
        final fresh = [for (final item in page.items) if (shown.add(tab.id(item))) item];
        tab.onItems?.call(fresh);
        emit(tab.write(state, latest.copyWith(loadingMore: false, items: [...latest.items, ...fresh], nextCursor: () => page.nextCursor)));
      case Err(:final failure):
        emit(tab.write(state, latest.copyWith(loadingMore: false, loadMoreFailure: () => failure)));
    }
  }

  Future<void> _remember(String query) async {
    final recent = await _recent.add(query);
    if (!isClosed) emit(state.copyWith(recent: recent));
  }

  Future<void> _loadFields() async {
    final fields = (await _getFields()).valueOrNull;
    if (fields != null && !isClosed) emit(state.copyWith(fields: fields));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
