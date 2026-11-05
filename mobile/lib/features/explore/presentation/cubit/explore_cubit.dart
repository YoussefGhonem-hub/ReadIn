import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../domain/entities/explore.dart';
import '../../domain/usecases/explore_usecases.dart';

enum ExploreStatus { loading, ready, failure }

class ExploreState extends Equatable {
  const ExploreState({this.status = ExploreStatus.loading, this.sections = const ExploreSections(), this.failure});

  final ExploreStatus status;
  final ExploreSections sections;
  final Failure? failure;

  @override
  List<Object?> get props => [status, sections, failure];
}

/// The Explore tab (F15), guests too: `GET /explore`, every section in one answer, with pull to refresh.
@injectable
class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._getExplore, this._follows) : super(const ExploreState());

  final GetExplore _getExplore;
  final FollowsCubit _follows;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    emit(const ExploreState());
    final result = await _getExplore();
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => ExploreState(status: ExploreStatus.failure, failure: failure),
      _ready,
    ));
  }

  /// Pull to refresh: the sections stay until the new ones arrive; a failed refresh keeps them.
  Future<void> refresh() async {
    if (state.status != ExploreStatus.ready) return load();
    final generation = ++_generation;
    final result = await _getExplore();
    if (generation != _generation || isClosed) return;
    if (result case Ok(value: final sections)) emit(_ready(sections));
  }

  ExploreState _ready(ExploreSections sections) {
    // The writers' follow buttons start from what the API said (F12).
    _follows.seed({for (final user in sections.newWriters) user.id: user.isFollowing});
    return ExploreState(status: ExploreStatus.ready, sections: sections);
  }
}

/// A ranking of Explore in full ("See all", F15): the post cards with pull to refresh and infinite scroll. Rankings
/// move while people read, so a card already shown is dropped from the next pages.
@injectable
class ExploreRankingCubit extends ArticleFeedCubit {
  ExploreRankingCubit(this._getRanking, @factoryParam this.ranking);

  final GetExploreRanking _getRanking;
  final ExploreRanking ranking;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) async {
    final result = await _getRanking(ranking, cursor: cursor);
    if (cursor == null) return result;
    final shown = {for (final card in state.items) card.id};
    return result.fold(
      (failure) => Err(failure),
      (page) => Ok(CursorPage(items: [for (final card in page.items) if (!shown.contains(card.id)) card], nextCursor: page.nextCursor)),
    );
  }
}
