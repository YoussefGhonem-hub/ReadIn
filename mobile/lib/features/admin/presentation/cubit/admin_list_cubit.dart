import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/paged_list.dart';

enum AdminListStatus { loading, ready, failure }

/// An admin table as a compact list (F23): offset pages (`?page=`) loaded one after another as the list scrolls,
/// filtered by [query].
class AdminListState<T, Q> extends Equatable {
  const AdminListState({
    required this.query,
    this.status = AdminListStatus.loading,
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.totalPages = 0,
    this.loadingMore = false,
    this.failure,
    this.moreFailure,
  });

  final AdminListStatus status;
  final Q query;
  final List<T> items;

  /// The last page loaded (1-based; 0 before the first).
  final int page;
  final int totalCount;
  final int totalPages;
  final bool loadingMore;

  /// The first page failed.
  final Failure? failure;

  /// A later page failed; the list stays and offers to try again.
  final Failure? moreFailure;

  bool get hasMore => page < totalPages;

  AdminListState<T, Q> copyWith({
    AdminListStatus? status,
    List<T>? items,
    int? page,
    int? totalCount,
    int? totalPages,
    bool? loadingMore,
    Failure? Function()? moreFailure,
  }) =>
      AdminListState<T, Q>(
        query: query,
        status: status ?? this.status,
        items: items ?? this.items,
        page: page ?? this.page,
        totalCount: totalCount ?? this.totalCount,
        totalPages: totalPages ?? this.totalPages,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure,
        moreFailure: moreFailure != null ? moreFailure() : this.moreFailure,
      );

  @override
  List<Object?> get props => [status, query, items, page, totalCount, totalPages, loadingMore, failure, moreFailure];
}

/// Loads an [AdminListState] page by page and reloads from the first page when the query changes. An older answer
/// never replaces a newer query's.
abstract class AdminListCubit<T, Q> extends Cubit<AdminListState<T, Q>> {
  AdminListCubit(Q query) : super(AdminListState<T, Q>(query: query));

  int _generation = 0;

  Future<Result<PagedList<T>>> fetch(Q query, int page);

  Object idOf(T item);

  /// The first page. A reload ([refresh]) keeps the shown items when it fails, and returns why.
  Future<Failure?> load() async {
    final generation = ++_generation;
    final query = state.query;
    final result = await fetch(query, 1);
    if (isClosed || generation != _generation) return null;
    switch (result) {
      case Ok(value: final page):
        emit(AdminListState<T, Q>(
          query: query,
          status: AdminListStatus.ready,
          items: page.items,
          page: page.page < 1 ? 1 : page.page,
          totalCount: page.totalCount,
          totalPages: page.totalPages,
        ));
        return null;
      case Err(:final failure):
        if (state.items.isEmpty) {
          emit(AdminListState<T, Q>(query: query, status: AdminListStatus.failure, failure: failure));
        }
        return failure;
    }
  }

  /// Pull to refresh, or back from a detail page; null when it worked.
  Future<Failure?> refresh() => load();

  /// Shows [query] from its first page.
  Future<void> setQuery(Q query) async {
    if (query == state.query && state.status != AdminListStatus.failure) return;
    emit(AdminListState<T, Q>(query: query));
    await load();
  }

  /// The next page, when the list is scrolled near its end.
  Future<void> loadMore() async {
    if (state.status != AdminListStatus.ready || !state.hasMore || state.loadingMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, moreFailure: () => null));
    final result = await fetch(state.query, state.page + 1);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (failure) => state.copyWith(loadingMore: false, moreFailure: () => failure),
      (page) => state.copyWith(
        loadingMore: false,
        // Rows can move between pages while the list changes: keep the first copy.
        items: [
          ...state.items,
          for (final item in page.items)
            if (!state.items.any((shown) => idOf(shown) == idOf(item))) item,
        ],
        page: page.page,
        totalCount: page.totalCount,
        totalPages: page.totalPages,
      ),
    ));
  }

  /// A row changed in place (hidden, featured, …).
  void replace(T item) {
    final id = idOf(item);
    if (!state.items.any((shown) => idOf(shown) == id)) return;
    emit(state.copyWith(items: [for (final shown in state.items) idOf(shown) == id ? item : shown]));
  }

  /// A row left the list (deleted).
  void remove(Object id) {
    if (!state.items.any((shown) => idOf(shown) == id)) return;
    emit(state.copyWith(
      items: [for (final shown in state.items) if (idOf(shown) != id) shown],
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
    ));
  }
}
