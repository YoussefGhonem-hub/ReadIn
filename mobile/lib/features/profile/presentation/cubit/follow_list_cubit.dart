import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../follow/domain/usecases/follow_usecases.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';

enum FollowListKind { followers, following }

enum FollowListStatus { loading, ready, failure }

class FollowListState extends Equatable {
  const FollowListState({
    this.status = FollowListStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.query = '',
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final FollowListStatus status;
  final List<UserSummary> items;
  final String? nextCursor;

  /// The search the items match ('' = everyone).
  final String query;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  FollowListState copyWith({
    FollowListStatus? status,
    List<UserSummary>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
  }) =>
      FollowListState(
        status: status ?? this.status,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        query: query,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure != null ? failure() : this.failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
      );

  @override
  List<Object?> get props => [status, items, nextCursor, query, loadingMore, failure, loadMoreFailure];
}

/// A user's followers or the people they follow (F12, F14): searched by name or @username (debounced), paged. The
/// rows' follow buttons share the app-wide [FollowsCubit].
@injectable
class FollowListCubit extends Cubit<FollowListState> {
  FollowListCubit(this._lists, this._follows, @factoryParam String userId, @factoryParam FollowListKind kind)
      : _userId = userId,
        _kind = kind,
        super(const FollowListState());

  final GetFollowLists _lists;
  final FollowsCubit _follows;
  final String _userId;
  final FollowListKind _kind;

  static const searchDebounce = Duration(milliseconds: 350);

  Timer? _debounce;

  /// Incremented on every reset so answers for an older search are dropped.
  int _generation = 0;

  Future<Result<CursorPage<UserSummary>>> _fetch({String? cursor}) => switch (_kind) {
        FollowListKind.followers => _lists.followers(_userId, query: state.query, cursor: cursor),
        FollowListKind.following => _lists.following(_userId, query: state.query, cursor: cursor),
      };

  Future<void> load() async {
    _debounce?.cancel();
    final generation = ++_generation;
    emit(FollowListState(query: state.query));
    final result = await _fetch();
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: FollowListStatus.failure, failure: () => failure)),
      (page) {
        _seed(page.items);
        emit(state.copyWith(status: FollowListStatus.ready, items: page.items, nextCursor: () => page.nextCursor));
      },
    );
  }

  /// Runs [searchDebounce] after the last keystroke.
  void search(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query == state.query) return;
    _debounce = Timer(searchDebounce, () {
      if (isClosed) return;
      emit(FollowListState(query: query));
      unawaited(load());
    });
  }

  Future<void> loadMore() async {
    if (state.status != FollowListStatus.ready || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _fetch(cursor: state.nextCursor);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(loadingMore: false, loadMoreFailure: () => failure)),
      (page) {
        _seed(page.items);
        emit(state.copyWith(loadingMore: false, items: [...state.items, ...page.items], nextCursor: () => page.nextCursor));
      },
    );
  }

  void _seed(List<UserSummary> users) => _follows.seed({for (final user in users) user.id: user.isFollowing});

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
