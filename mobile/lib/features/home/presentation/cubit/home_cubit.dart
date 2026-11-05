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
  const HomeState({
    this.loading = true,
    this.today,
    this.fields = const [],
    this.continueReading = const [],
    this.activePath,
    this.suggestedPath,
  });

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

  /// "Suggested path" (F09): the first published path (`GET /paths`, editorial order) the viewer hasn't joined; for
  /// guests the first path. Null when every path is joined, there is none, or on failure.
  final LearningPath? suggestedPath;

  /// The Continue reading card: the first article that isn't [today] (that one already is the hero). Null hides it.
  ContinueReading? get resume {
    final heroId = today?.id;
    return continueReading.where((item) => item.article.id != heroId).firstOrNull;
  }

  @override
  List<Object?> get props => [loading, today, fields, continueReading, activePath, suggestedPath];
}

/// Header data for Home (F03): Today's article, the Continue reading and learning path cards, the suggested path and
/// the field filter chips. The two progress cards need a session; everything loads in parallel with Today's article.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getToday, this._getFields, this._getContinueReading, this._getActivePath, this._getPaths, this._session)
      : super(const HomeState());

  final GetTodayArticle _getToday;
  final GetFields _getFields;
  final GetContinueReading _getContinueReading;
  final GetActivePath _getActivePath;
  final GetPaths _getPaths;
  final SessionCubit _session;

  // Incremented by every load (and every card refresh), so an older answer is dropped.
  int _generation = 0;
  int _cardsGeneration = 0;

  Future<void> load({bool refresh = false}) async {
    if (!refresh) emit(const HomeState());
    final generation = ++_generation;
    ++_cardsGeneration;
    final (today, fields, (resume, path, suggested)) = await (_getToday(), _getFields(refresh: refresh), _cards()).wait;
    if (generation != _generation || isClosed) return;
    emit(HomeState(
      loading: false,
      today: today.valueOrNull,
      fields: fields.valueOrNull ?? state.fields,
      continueReading: resume,
      activePath: path,
      suggestedPath: suggested,
    ));
  }

  /// Back on Home from the reader or a path: only the Continue reading, learning path and suggested path cards (cheap
  /// calls; joining a path changes the suggestion).
  Future<void> refreshProgress() async {
    if (state.loading) return;
    final generation = ++_cardsGeneration;
    final (resume, path, suggested) = await _cards();
    if (generation != _cardsGeneration || isClosed || state.loading) return;
    emit(HomeState(
      loading: false,
      today: state.today,
      fields: state.fields,
      continueReading: resume,
      activePath: path,
      suggestedPath: suggested,
    ));
  }

  Future<(List<ContinueReading>, LearningPath?, LearningPath?)> _cards() async {
    if (!_session.state.isAuthenticated) return (const <ContinueReading>[], null, _suggest((await _getPaths()).valueOrNull, null));
    final (resume, path, paths) = await (_getContinueReading(), _getActivePath(), _getPaths()).wait;
    final active = path.valueOrNull;
    return (resume.valueOrNull ?? const <ContinueReading>[], active, _suggest(paths.valueOrNull, active));
  }

  /// The first of [paths] not joined and not [active]; a failed list only hides the card.
  static LearningPath? _suggest(List<LearningPath>? paths, LearningPath? active) =>
      paths?.where((p) => !p.isEnrolled && p.id != active?.id).firstOrNull;
}
