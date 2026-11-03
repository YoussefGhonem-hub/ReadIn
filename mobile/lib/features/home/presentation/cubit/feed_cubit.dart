import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/usecases/feed_usecases.dart';

enum FeedStatus { loading, ready, failure }

class FeedState extends Equatable {
  const FeedState({
    this.status = FeedStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.fieldSlug,
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final FeedStatus status;
  final List<ArticleCard> items;
  final String? nextCursor;

  /// Selected field chip; null = "All".
  final String? fieldSlug;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;
  bool get isEmpty => status == FeedStatus.ready && items.isEmpty;

  FeedState copyWith({
    FeedStatus? status,
    List<ArticleCard>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
  }) =>
      FeedState(
        status: status ?? this.status,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        fieldSlug: fieldSlug,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure != null ? failure() : this.failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
      );

  @override
  List<Object?> get props => [status, items, nextCursor, fieldSlug, loadingMore, failure, loadMoreFailure];
}

/// "For you" feed with cursor pagination and field filter (F03).
@injectable
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._getFeed) : super(const FeedState());

  final GetForYouFeed _getFeed;

  /// Incremented on every reset so responses for an older filter are dropped.
  int _generation = 0;

  Future<void> load({String? fieldSlug}) async {
    final generation = ++_generation;
    emit(FeedState(fieldSlug: fieldSlug));
    final result = await _getFeed(fieldSlug: fieldSlug);
    if (generation != _generation) return;
    emit(result.fold(
      (failure) => FeedState(status: FeedStatus.failure, fieldSlug: fieldSlug, failure: failure),
      (page) => FeedState(status: FeedStatus.ready, fieldSlug: fieldSlug, items: page.items, nextCursor: page.nextCursor),
    ));
  }

  Future<void> selectField(String? fieldSlug) async {
    if (fieldSlug == state.fieldSlug && state.status != FeedStatus.failure) return;
    await load(fieldSlug: fieldSlug);
  }

  /// Pull-to-refresh: keeps the current items visible until the new page arrives.
  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getFeed(fieldSlug: state.fieldSlug);
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(state.items.isEmpty
          ? state.copyWith(status: FeedStatus.failure, failure: () => failure)
          : state.copyWith(loadMoreFailure: () => failure)),
      (page) => emit(FeedState(
        status: FeedStatus.ready,
        fieldSlug: state.fieldSlug,
        items: page.items,
        nextCursor: page.nextCursor,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state.status != FeedStatus.ready || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _getFeed(fieldSlug: state.fieldSlug, cursor: state.nextCursor);
    if (generation != _generation) return;
    emit(result.fold(
      (failure) => state.copyWith(loadingMore: false, loadMoreFailure: () => failure),
      (page) => state.copyWith(
        loadingMore: false,
        items: [...state.items, ...page.items],
        nextCursor: () => page.nextCursor,
      ),
    ));
  }
}
