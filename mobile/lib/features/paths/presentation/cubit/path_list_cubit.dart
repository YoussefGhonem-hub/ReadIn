import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/learning_path.dart';
import '../../domain/usecases/path_usecases.dart';

enum PathListStatus { loading, ready, failure }

class PathListState extends Equatable {
  const PathListState({this.status = PathListStatus.loading, this.items = const [], this.fieldSlug, this.failure});

  final PathListStatus status;
  final List<LearningPath> items;

  /// The selected field chip; null = all. The list is filtered here, not by the API.
  final String? fieldSlug;
  final Failure? failure;

  /// The fields present in the list, in the order they first appear: the filter chips.
  List<FieldRef> get fields {
    final seen = <String>{};
    return [for (final path in items) if (seen.add(path.field.slug)) path.field];
  }

  /// The paths of the selected field.
  List<LearningPath> get visible => fieldSlug == null ? items : [for (final p in items) if (p.field.slug == fieldSlug) p];

  @override
  List<Object?> get props => [status, items, fieldSlug, failure];
}

/// A list of learning path cards (F09) with local field chips, pull to refresh and a refresh when the viewer comes
/// back from a path (enrolling or reading changes the progress). The lists are short, so they come in one page.
abstract class PathListCubit extends Cubit<PathListState> {
  PathListCubit() : super(const PathListState());

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;
  bool _started = false;

  @protected
  Future<Result<List<LearningPath>>> fetch();

  /// Loads the list unless a load already started (a tab shown for the first time).
  Future<void> ensureLoaded() async {
    if (!_started) await load();
  }

  Future<void> load() async {
    _started = true;
    final generation = ++_generation;
    emit(PathListState(fieldSlug: state.fieldSlug));
    final result = await fetch();
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => PathListState(status: PathListStatus.failure, fieldSlug: state.fieldSlug, failure: failure),
      _ready,
    ));
  }

  /// Keeps the list on screen until the new one arrives; a failed refresh keeps what is shown.
  Future<void> refresh() async {
    if (state.status != PathListStatus.ready) return load();
    final generation = ++_generation;
    final result = await fetch();
    if (generation != _generation || isClosed) return;
    if (result case Ok(:final value)) emit(_ready(value));
  }

  void selectField(String? fieldSlug) {
    if (fieldSlug == state.fieldSlug) return;
    emit(PathListState(status: state.status, items: state.items, fieldSlug: fieldSlug, failure: state.failure));
  }

  /// A chip whose field left the list falls back to "All".
  PathListState _ready(List<LearningPath> items) {
    final slug = state.fieldSlug;
    final keep = slug != null && items.any((p) => p.field.slug == slug);
    return PathListState(status: PathListStatus.ready, items: items, fieldSlug: keep ? slug : null);
  }
}

/// `/paths` "All paths": every published path, in editorial order.
@injectable
class AllPathsCubit extends PathListCubit {
  AllPathsCubit(this._getPaths);

  final GetPaths _getPaths;

  @override
  Future<Result<List<LearningPath>>> fetch() => _getPaths();
}

/// `/paths` "My paths" (signed in): in progress first, then completed.
@injectable
class MyPathsCubit extends PathListCubit {
  MyPathsCubit(this._getMyPaths);

  final GetMyPaths _getMyPaths;

  @override
  Future<Result<List<LearningPath>>> fetch() => _getMyPaths();
}

/// The Paths tab of a profile (F14): that user's enrolled paths, when their reading stats are visible.
@injectable
class UserPathsCubit extends PathListCubit {
  UserPathsCubit(this._getUserPaths, @factoryParam String username) : _username = username;

  final GetUserPaths _getUserPaths;
  final String _username;

  @override
  Future<Result<List<LearningPath>>> fetch() => _getUserPaths(_username);
}
