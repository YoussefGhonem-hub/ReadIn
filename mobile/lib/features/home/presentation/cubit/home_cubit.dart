import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../paths/domain/entities/learning_path.dart';
import '../../../paths/domain/usecases/path_usecases.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/continue_reading.dart';
import '../../domain/usecases/feed_usecases.dart';

class HomeState extends Equatable {
  const HomeState({this.loading = true, this.today, this.fields = const [], this.continueReading = const [], this.activePath});

  final bool loading;

  /// Today's article (F07); null when there is no pick yet or it failed —
  /// the hero simply hides, the feed stays usable.
  final ArticleCard? today;
  final List<Field> fields;

  /// `GET /me/continue-reading` as it came (signed in; empty for guests and on failure).
  final List<ContinueReading> continueReading;

  /// The enrolled path in progress (F09); null for guests, when there is none (204) or on failure: Home then shows
  /// the "explore paths" prompt.
  final LearningPath? activePath;

  /// The Continue reading card: the first article that isn't [today] (that one already is the hero). Null hides it.
  ContinueReading? get resume {
    final heroId = today?.id;
    return continueReading.where((item) => item.article.id != heroId).firstOrNull;
  }

  @override
  List<Object?> get props => [loading, today, fields, continueReading, activePath];
}

/// Header data for Home (F03): Today's article, the Continue reading and learning path cards, and the field filter
/// chips. The two cards need a session; they load in parallel with Today's article.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getToday, this._getFields, this._getContinueReading, this._getActivePath, this._session)
      : super(const HomeState());

  final GetTodayArticle _getToday;
  final GetFields _getFields;
  final GetContinueReading _getContinueReading;
  final GetActivePath _getActivePath;
  final SessionCubit _session;

  // Incremented by every load (and every card refresh), so an older answer is dropped.
  int _generation = 0;
  int _cardsGeneration = 0;

  Future<void> load({bool refresh = false}) async {
    if (!refresh) emit(const HomeState());
    final generation = ++_generation;
    ++_cardsGeneration;
    final (today, fields, (resume, path)) = await (_getToday(), _getFields(refresh: refresh), _cards()).wait;
    if (generation != _generation || isClosed) return;
    emit(HomeState(
      loading: false,
      today: today.valueOrNull,
      fields: fields.valueOrNull ?? state.fields,
      continueReading: resume,
      activePath: path,
    ));
  }

  /// Back on Home from the reader or a path: only the Continue reading and learning path cards (cheap calls).
  Future<void> refreshProgress() async {
    if (state.loading) return;
    final generation = ++_cardsGeneration;
    final (resume, path) = await _cards();
    if (generation != _cardsGeneration || isClosed || state.loading) return;
    emit(HomeState(loading: false, today: state.today, fields: state.fields, continueReading: resume, activePath: path));
  }

  Future<(List<ContinueReading>, LearningPath?)> _cards() async {
    if (!_session.state.isAuthenticated) return (const <ContinueReading>[], null);
    final (resume, path) = await (_getContinueReading(), _getActivePath()).wait;
    return (resume.valueOrNull ?? const <ContinueReading>[], path.valueOrNull);
  }
}
