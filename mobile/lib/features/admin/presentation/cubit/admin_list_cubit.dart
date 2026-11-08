import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/paged_list.dart';

enum AdminListStatus { loading, ready, failure }

/// An admin table as a compact list (F23), one offset page at a time (`?page=&pageSize=`, SPEC §17.1): the page
/// controls go to the previous or next page; a new [query] starts again from page 1.
class AdminListState<T, Q> extends Equatable {
  const AdminListState({
    required this.query,
    this.status = AdminListStatus.loading,
    this.items = const [],
    this.page = 0,
    this.pageSize = 0,
    this.totalCount = 0,
    this.totalPages = 0,
    this.changingPage = false,
    this.failure,
  });

  final AdminListStatus status;
  final Q query;

  /// The rows of [page] only.
  final List<T> items;

  /// The page shown (1-based; 0 before the first).
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  /// Another page is loading; the rows shown stay until it arrives.
  final bool changingPage;

  /// The first page failed.
  final Failure? failure;

  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  /// The 1-based position of the first row shown, 0 when there is none ("1–50 of 1,234").
  int get firstRow => items.isEmpty ? 0 : (page - 1) * pageSize + 1;

  /// The position of the last row shown.
  int get lastRow => items.isEmpty ? 0 : firstRow + items.length - 1;

  AdminListState<T, Q> copyWith({List<T>? items, int? totalCount, bool? changingPage}) => AdminListState<T, Q>(
        query: query,
        status: status,
        items: items ?? this.items,
        page: page,
        pageSize: pageSize,
        totalCount: totalCount ?? this.totalCount,
        totalPages: totalPages,
        changingPage: changingPage ?? this.changingPage,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, query, items, page, pageSize, totalCount, totalPages, changingPage, failure];
}

/// Loads an [AdminListState] page by page. An older answer never replaces a newer query's or page's.
abstract class AdminListCubit<T, Q> extends Cubit<AdminListState<T, Q>> {
  AdminListCubit(Q query) : super(AdminListState<T, Q>(query: query));

  int _generation = 0;

  Future<Result<PagedList<T>>> fetch(Q query, int page);

  Object idOf(T item);

  /// The first page.
  Future<Failure?> load() => _show(1);

  /// Pull to refresh, or back from a detail page: the page shown, read again. A failure keeps the rows on screen and
  /// is returned; null when it worked.
  Future<Failure?> refresh() => _show(state.page < 1 ? 1 : state.page);

  /// Shows [query] from page 1 (a search, a filter or a sort).
  Future<void> setQuery(Q query) async {
    if (query == state.query && state.status != AdminListStatus.failure) return;
    emit(AdminListState<T, Q>(query: query));
    await load();
  }

  /// Another page: within 1..totalPages; the rows shown stay until it arrives. Null when it worked (or there was
  /// nothing to do).
  Future<Failure?> goToPage(int page) async {
    if (state.status != AdminListStatus.ready || page < 1 || page > state.totalPages || page == state.page) return null;
    emit(state.copyWith(changingPage: true));
    return _show(page);
  }

  Future<Failure?> nextPage() => goToPage(state.page + 1);

  Future<Failure?> previousPage() => goToPage(state.page - 1);

  Future<Failure?> _show(int page) async {
    final generation = ++_generation;
    final query = state.query;
    var result = await fetch(query, page);
    if (isClosed || generation != _generation) return null;
    // Rows went away since (a page past the end has no items and the real total): show the last page instead.
    if (result case Ok(value: final empty) when empty.items.isEmpty && page > 1 && empty.totalPages >= 1 && page > empty.totalPages) {
      result = await fetch(query, empty.totalPages);
      if (isClosed || generation != _generation) return null;
    }
    switch (result) {
      case Ok(value: final list):
        emit(AdminListState<T, Q>(
          query: query,
          status: AdminListStatus.ready,
          items: list.items,
          page: list.page < 1 ? 1 : list.page,
          pageSize: list.pageSize,
          totalCount: list.totalCount,
          totalPages: list.totalPages,
        ));
        return null;
      case Err(:final failure):
        if (state.status == AdminListStatus.ready) {
          emit(state.copyWith(changingPage: false));
        } else {
          emit(AdminListState<T, Q>(query: query, status: AdminListStatus.failure, failure: failure));
        }
        return failure;
    }
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
