import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/highlight.dart';
import '../../domain/usecases/highlight_usecases.dart';

enum MyHighlightsStatus { loading, ready, failure }

class MyHighlightsState extends Equatable {
  const MyHighlightsState({
    this.status = MyHighlightsStatus.loading,
    this.groups = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final MyHighlightsStatus status;

  /// One per article version, newest first.
  final List<HighlightGroup> groups;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [status, groups, nextCursor, loadingMore, failure, loadMoreFailure];
}

/// Saved → Highlights (F30, F14): `GET /me/highlights`, your highlights grouped by article version, newest first, paged
/// by cursor. A new highlight moves its group to the top, so a later page may bring a group already shown: it is
/// dropped. Making or removing a highlight anywhere in the app loads the list again (like pull to refresh), so it is
/// up to date when you come back to it.
@injectable
class MyHighlightsCubit extends Cubit<MyHighlightsState> {
  MyHighlightsCubit(this._get) : super(const MyHighlightsState()) {
    _changes = _get.changes.listen((_) => unawaited(refresh()));
  }

  final GetMyHighlights _get;
  late final StreamSubscription<void> _changes;

  /// The newest first-page request: an older answer arriving later is dropped.
  int _loads = 0;

  static const pageSize = 20;

  Future<void> load() async {
    emit(const MyHighlightsState());
    await _first();
  }

  /// Pull to refresh: keeps the list on screen until the first page arrives.
  Future<void> refresh() => _first(keepOnFailure: true);

  Future<void> _first({bool keepOnFailure = false}) async {
    final serial = ++_loads;
    final result = await _get(limit: pageSize);
    if (isClosed || serial != _loads) return;
    result.fold(
      (failure) {
        if (keepOnFailure && state.status == MyHighlightsStatus.ready) return;
        emit(MyHighlightsState(status: MyHighlightsStatus.failure, failure: failure));
      },
      (page) => emit(MyHighlightsState(status: MyHighlightsStatus.ready, groups: page.items, nextCursor: page.nextCursor)),
    );
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.status != MyHighlightsStatus.ready || state.loadingMore || cursor == null) return;
    emit(MyHighlightsState(status: state.status, groups: state.groups, nextCursor: cursor, loadingMore: true));
    final result = await _get(cursor: cursor, limit: pageSize);
    if (isClosed) return;
    emit(result.fold(
      (failure) => MyHighlightsState(status: state.status, groups: state.groups, nextCursor: cursor, loadMoreFailure: failure),
      (page) {
        final shown = {for (final g in state.groups) g.key};
        return MyHighlightsState(
          status: MyHighlightsStatus.ready,
          groups: [...state.groups, ...page.items.where((g) => !shown.contains(g.key))],
          nextCursor: page.nextCursor,
        );
      },
    ));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
