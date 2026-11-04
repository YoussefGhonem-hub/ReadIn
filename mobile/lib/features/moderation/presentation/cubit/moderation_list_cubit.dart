import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';

enum ModerationListStatus { loading, ready, failure }

/// A paged moderation list (the queue in one status, or the log), filtered by target type.
class ModerationListState<T> extends Equatable {
  const ModerationListState({
    this.status = ModerationListStatus.loading,
    this.type,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.moreFailure,
  });

  final ModerationListStatus status;

  /// The type filter; null = all.
  final ModerationTargetType? type;
  final List<T> items;
  final String? nextCursor;
  final bool loadingMore;

  /// The first page failed.
  final Failure? failure;

  /// A later page failed; the list stays and offers to try again.
  final Failure? moreFailure;

  bool get hasMore => nextCursor != null;

  ModerationListState<T> copyWith({
    List<T>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? moreFailure,
  }) =>
      ModerationListState<T>(
        status: status,
        type: type,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure,
        moreFailure: moreFailure != null ? moreFailure() : this.moreFailure,
      );

  @override
  List<Object?> get props => [status, type, items, nextCursor, loadingMore, failure, moreFailure];
}

/// Loads a [ModerationListState] page by page (infinite scroll) and reloads when the type filter changes.
abstract class ModerationListCubit<T> extends Cubit<ModerationListState<T>> {
  ModerationListCubit() : super(ModerationListState<T>());

  // Bumped by every (re)load, so pages of an older filter are dropped.
  int _generation = 0;

  Future<Result<CursorPage<T>>> fetch(ModerationTargetType? type, String? cursor);

  /// The first page. A reload ([refresh]) keeps the shown items when it fails, and returns why.
  Future<Failure?> load() async {
    final generation = ++_generation;
    final type = state.type;
    final result = await fetch(type, null);
    if (isClosed || generation != _generation) return null;
    switch (result) {
      case Ok(value: final page):
        emit(ModerationListState<T>(
          status: ModerationListStatus.ready,
          type: type,
          items: page.items,
          nextCursor: page.nextCursor,
        ));
        return null;
      case Err(:final failure):
        if (state.items.isEmpty) {
          emit(ModerationListState<T>(status: ModerationListStatus.failure, type: type, failure: failure));
        }
        return failure;
    }
  }

  /// Pull to refresh, or back from a case; null when it worked.
  Future<Failure?> refresh() => load();

  /// Shows only [type] (null = all), from the first page.
  Future<void> setType(ModerationTargetType? type) async {
    if (type == state.type && state.status != ModerationListStatus.failure) return;
    emit(ModerationListState<T>(type: type));
    await load();
  }

  /// The next page, when the list is scrolled near its end.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.status != ModerationListStatus.ready || cursor == null || state.loadingMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, moreFailure: () => null));
    final result = await fetch(state.type, cursor);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (failure) => state.copyWith(loadingMore: false, moreFailure: () => failure),
      (page) => state.copyWith(
        loadingMore: false,
        items: [
          ...state.items,
          // A target can move between pages while reports arrive: keep the first copy.
          for (final item in page.items)
            if (!state.items.any((shown) => idOf(shown) == idOf(item))) item,
        ],
        nextCursor: () => page.nextCursor,
      ),
    ));
  }

  Object idOf(T item);
}

/// The queue of one [ReportStatus] tab: targets with reports, grouped by target.
@injectable
class ModerationQueueCubit extends ModerationListCubit<ModerationQueueItem> {
  ModerationQueueCubit(this._getQueue, @factoryParam this.status);

  final GetModerationQueue _getQueue;
  final ReportStatus status;

  @override
  Future<Result<CursorPage<ModerationQueueItem>>> fetch(ModerationTargetType? type, String? cursor) =>
      _getQueue(status, type: type, cursor: cursor);

  @override
  Object idOf(ModerationQueueItem item) => item.ref;
}

/// The moderation log ("السجل" tab), newest first.
@injectable
class ModerationLogCubit extends ModerationListCubit<ModerationLogEntry> {
  ModerationLogCubit(this._getLog);

  final GetModerationLog _getLog;

  @override
  Future<Result<CursorPage<ModerationLogEntry>>> fetch(ModerationTargetType? type, String? cursor) =>
      _getLog(targetType: type, cursor: cursor);

  @override
  Object idOf(ModerationLogEntry item) => item.id;
}
