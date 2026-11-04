import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/reactions.dart';
import '../../domain/usecases/reaction_usecases.dart';

enum ReactorsStatus { loading, ready, failure }

class ReactorsState extends Equatable {
  const ReactorsState({
    this.status = ReactorsStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final ReactorsStatus status;
  final List<Reactor> items;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, failure, loadMoreFailure];
}

/// One tab of "who reacted" (F10): everyone, or one reaction type, newest first, paged.
@injectable
class ReactorsCubit extends Cubit<ReactorsState> {
  ReactorsCubit(this._getReactors) : super(const ReactorsState());

  final GetReactors _getReactors;
  String? _articleId;
  ReactionType? _type;

  /// Bumped by every [load]: an answer to an older load (or to a page of it) is dropped, so a slow first answer can't
  /// replace a newer list, and a page can't be appended to the list of a newer load.
  int _generation = 0;

  Future<void> load(String articleId, {ReactionType? type}) async {
    _articleId = articleId;
    _type = type;
    final generation = ++_generation;
    emit(const ReactorsState());
    final result = await _getReactors(articleId, type: type);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (failure) => ReactorsState(status: ReactorsStatus.failure, failure: failure),
      (page) => ReactorsState(status: ReactorsStatus.ready, items: page.items, nextCursor: page.nextCursor),
    ));
  }

  Future<void> retry() async {
    if (_articleId != null) await load(_articleId!, type: _type);
  }

  Future<void> loadMore() async {
    final articleId = _articleId;
    if (articleId == null || state.status != ReactorsStatus.ready || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    emit(ReactorsState(status: state.status, items: state.items, nextCursor: state.nextCursor, loadingMore: true));
    final result = await _getReactors(articleId, type: _type, cursor: state.nextCursor);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (failure) => ReactorsState(status: state.status, items: state.items, nextCursor: state.nextCursor, loadMoreFailure: failure),
      (page) => ReactorsState(status: state.status, items: [...state.items, ...page.items], nextCursor: page.nextCursor),
    ));
  }
}
