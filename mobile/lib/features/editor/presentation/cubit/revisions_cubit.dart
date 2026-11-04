import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/editor_entities.dart';
import '../../domain/usecases/editor_usecases.dart';

enum RevisionsStatus { loading, ready, failure }

class RevisionsState extends Equatable {
  const RevisionsState({
    this.status = RevisionsStatus.loading,
    this.revisions = const [],
    this.failure,
    this.details = const {},
    this.loadingDetails = const {},
    this.detailsFailure,
  });

  final RevisionsStatus status;

  /// Newest first.
  final List<ArticleRevision> revisions;
  final Failure? failure;

  /// Loaded previews by revision number.
  final Map<int, ArticleRevisionDetails> details;
  final Set<int> loadingDetails;
  final Failure? detailsFailure;

  RevisionsState copyWith({
    RevisionsStatus? status,
    List<ArticleRevision>? revisions,
    Failure? Function()? failure,
    Map<int, ArticleRevisionDetails>? details,
    Set<int>? loadingDetails,
    Failure? Function()? detailsFailure,
  }) =>
      RevisionsState(
        status: status ?? this.status,
        revisions: revisions ?? this.revisions,
        failure: failure != null ? failure() : this.failure,
        details: details ?? this.details,
        loadingDetails: loadingDetails ?? this.loadingDetails,
        detailsFailure: detailsFailure != null ? detailsFailure() : this.detailsFailure,
      );

  @override
  List<Object?> get props => [status, revisions, failure, details, loadingDetails, detailsFailure];
}

/// Revision history of a published article (F05): one revision per publish or update, each with a preview. Restoring
/// goes through the editor, which owns the working copy's version.
@injectable
class RevisionsCubit extends Cubit<RevisionsState> {
  RevisionsCubit(this._list, this._get, @factoryParam String articleId)
      : _articleId = articleId,
        super(const RevisionsState());

  final GetRevisions _list;
  final GetRevision _get;
  final String _articleId;

  Future<void> load() async {
    emit(state.copyWith(status: RevisionsStatus.loading, failure: () => null));
    final result = await _list(_articleId);
    if (isClosed) return;
    emit(result.fold(
      (failure) => state.copyWith(status: RevisionsStatus.failure, failure: () => failure),
      (revisions) => state.copyWith(status: RevisionsStatus.ready, revisions: revisions),
    ));
  }

  /// Loads revision [number]'s document for its preview (once).
  Future<ArticleRevisionDetails?> loadDetails(int number) async {
    final known = state.details[number];
    if (known != null || state.loadingDetails.contains(number)) return known;
    emit(state.copyWith(loadingDetails: {...state.loadingDetails, number}, detailsFailure: () => null));
    final result = await _get(_articleId, number);
    if (isClosed) return result.valueOrNull;
    final loading = {...state.loadingDetails}..remove(number);
    switch (result) {
      case Ok(value: final details):
        emit(state.copyWith(loadingDetails: loading, details: {...state.details, number: details}));
        return details;
      case Err(:final failure):
        emit(state.copyWith(loadingDetails: loading, detailsFailure: () => failure));
        return null;
    }
  }
}
