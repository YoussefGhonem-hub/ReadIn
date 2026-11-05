import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
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
class FeedCubit extends ArticleFeedCubit {
  FeedCubit(this._getFeed);

  final GetForYouFeed _getFeed;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) =>
      _getFeed(fieldSlug: fieldSlug, cursor: cursor);
}

/// "Following" tab (F03, F12): articles by the writers the viewer follows. No field filter; loads the first time the
/// tab is shown.
@injectable
class FollowingFeedCubit extends ArticleFeedCubit {
  FollowingFeedCubit(this._getFeed);

  final GetFollowingFeed _getFeed;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) => _getFeed(cursor: cursor);
}

/// A paged article feed: first page, field filter, pull to refresh and infinite scroll.
abstract class ArticleFeedCubit extends Cubit<FeedState> {
  ArticleFeedCubit() : super(const FeedState());

  /// Incremented on every reset so responses for an older filter are dropped.
  int _generation = 0;
  bool _started = false;

  @protected
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor});

  /// Loads the first page unless a load already started (a tab shown for the first time).
  Future<void> ensureLoaded() async {
    if (!_started) await load();
  }

  Future<void> load({String? fieldSlug}) async {
    _started = true;
    final generation = ++_generation;
    emit(FeedState(fieldSlug: fieldSlug));
    final result = await fetch(fieldSlug: fieldSlug);
    if (generation != _generation || isClosed) return;
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
    _started = true;
    final generation = ++_generation;
    final result = await fetch(fieldSlug: state.fieldSlug);
    if (generation != _generation || isClosed) return;
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

  /// The next page, after the cards already shown. A card already in the list is dropped: a "show less" mid-scroll
  /// (F28) moves the other articles of that topic to For you's last tier, where they come again, and so can an Undo
  /// while paging in that tier (contract, "Show less").
  Future<void> loadMore() async {
    if (state.status != FeedStatus.ready || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await fetch(fieldSlug: state.fieldSlug, cursor: state.nextCursor);
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => state.copyWith(loadingMore: false, loadMoreFailure: () => failure),
      (page) {
        final seen = {for (final item in state.items) item.id};
        return state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items.where((item) => seen.add(item.id))],
          nextCursor: () => page.nextCursor,
        );
      },
    ));
  }
}
