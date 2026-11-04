import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/learning_path.dart';
import '../../domain/usecases/path_usecases.dart';

enum PathDetailsStatus { loading, ready, failure }

class PathDetailsState extends Equatable {
  const PathDetailsState({this.status = PathDetailsStatus.loading, this.details, this.failure, this.busy = false});

  final PathDetailsStatus status;
  final PathDetails? details;
  final Failure? failure;

  /// Enrolling or leaving is in flight.
  final bool busy;

  /// Unknown, unpublished, or nothing a reader can open (`404 path.not_found`).
  bool get notFound =>
      status == PathDetailsStatus.failure && (failure?.code == FailureCodes.pathNotFound || failure?.statusCode == 404);

  PathDetailsState copyWith({PathDetails? details, bool? busy}) =>
      PathDetailsState(status: status, details: details ?? this.details, failure: failure, busy: busy ?? this.busy);

  @override
  List<Object?> get props => [status, details, failure, busy];
}

/// The path page (F09): `GET /paths/{slug}`, enrolling (`PUT /me/paths/{id}`) and leaving (`DELETE`).
@injectable
class PathDetailsCubit extends Cubit<PathDetailsState> {
  PathDetailsCubit(this._getPath, this._enrollment) : super(const PathDetailsState());

  final GetPath _getPath;
  final SetPathEnrollment _enrollment;
  String? _slug;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load(String slug) async {
    _slug = slug;
    final generation = ++_generation;
    emit(const PathDetailsState());
    final result = await _getPath(slug);
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => PathDetailsState(status: PathDetailsStatus.failure, failure: failure),
      (details) => PathDetailsState(status: PathDetailsStatus.ready, details: details),
    ));
  }

  /// Pull to refresh, or back from an article (the read ticks change): the page stays until the new one arrives; a
  /// failed refresh keeps it.
  Future<void> refresh() async {
    final slug = _slug;
    if (slug == null) return;
    if (state.details == null) return load(slug);
    final generation = ++_generation;
    final result = await _getPath(slug);
    if (generation != _generation || isClosed) return;
    if (result case Ok(value: final details)) emit(state.copyWith(details: details));
  }

  /// "Start path": the header shows the enrollment at once. The answer carries `progress.next`, the article to open.
  Future<Result<LearningPath>> enroll() async {
    final details = state.details;
    if (details == null || state.busy) return const Err(Failure(FailureCodes.requestCancelled));
    emit(state.copyWith(busy: true));
    final result = await _enrollment.enroll(details.path.id);
    if (isClosed) return result;
    emit(switch (result) {
      Ok(value: final path) => state.copyWith(details: (state.details ?? details).withPath(path), busy: false),
      Err() => state.copyWith(busy: false),
    });
    return result;
  }

  /// "Leave path" (after the confirm dialog). The progress stays: it's the reading history. Null on success.
  Future<Failure?> leave() async {
    final details = state.details;
    if (details == null || state.busy) return null;
    emit(state.copyWith(busy: true));
    final result = await _enrollment.leave(details.path.id);
    if (isClosed) return result.failureOrNull;
    final current = state.details ?? details;
    emit(result.isOk
        ? state.copyWith(details: current.withPath(current.path.withoutEnrollment()), busy: false)
        : state.copyWith(busy: false));
    return result.failureOrNull;
  }
}
