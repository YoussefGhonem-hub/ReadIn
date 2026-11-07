import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../verification/domain/entities/verification.dart';
import '../../domain/entities/admin_verification.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_list_cubit.dart' show AdminListStatus;
import 'admin_user_cubit.dart' show AdminPageStatus;

/// One tab of the verification queue (F19): pending (oldest first), approved or rejected (latest decision first).
class VerificationQueueState extends Equatable {
  const VerificationQueueState({
    this.status = AdminListStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.moreFailure,
  });

  final AdminListStatus status;
  final List<AdminVerificationRequest> items;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? moreFailure;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, failure, moreFailure];
}

@injectable
class VerificationQueueCubit extends Cubit<VerificationQueueState> {
  VerificationQueueCubit(this._get, @factoryParam this.status) : super(const VerificationQueueState());

  final GetVerificationQueue _get;
  final VerificationRequestStatus status;
  int _generation = 0;

  Future<Failure?> load() async {
    final generation = ++_generation;
    final result = await _get(status);
    if (isClosed || generation != _generation) return null;
    switch (result) {
      case Ok(value: final page):
        emit(VerificationQueueState(status: AdminListStatus.ready, items: page.items, nextCursor: page.nextCursor));
        return null;
      case Err(:final failure):
        if (state.items.isEmpty) emit(VerificationQueueState(status: AdminListStatus.failure, failure: failure));
        return failure;
    }
  }

  Future<Failure?> refresh() => load();

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.status != AdminListStatus.ready || cursor == null || state.loadingMore) return;
    final generation = _generation;
    emit(VerificationQueueState(status: state.status, items: state.items, nextCursor: cursor, loadingMore: true));
    final result = await _get(status, cursor: cursor);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (failure) => VerificationQueueState(status: state.status, items: state.items, nextCursor: cursor, moreFailure: failure),
      (page) => VerificationQueueState(
        status: state.status,
        items: [
          ...state.items,
          for (final item in page.items)
            if (!state.items.any((shown) => shown.id == item.id)) item,
        ],
        nextCursor: page.nextCursor,
      ),
    ));
  }
}

/// What the request page is doing.
enum VerificationReviewCommand { approve, reject, proof, removeBadge }

class VerificationRequestState extends Equatable {
  const VerificationRequestState({this.status = AdminPageStatus.loading, this.request, this.failure, this.busy});

  final AdminPageStatus status;
  final AdminVerificationRequest? request;
  final Failure? failure;
  final VerificationReviewCommand? busy;

  VerificationRequestState copyWith({AdminVerificationRequest? request, VerificationReviewCommand? Function()? busy}) =>
      VerificationRequestState(
        status: status,
        request: request ?? this.request,
        failure: failure,
        busy: busy != null ? busy() : this.busy,
      );

  @override
  List<Object?> get props => [status, request, failure, busy];
}

/// One verification request (F19): approve, reject with a reason, save the proof file, remove the badge later.
@injectable
class VerificationRequestCubit extends Cubit<VerificationRequestState> {
  VerificationRequestCubit(this._review, @factoryParam this.requestId) : super(const VerificationRequestState());

  final VerificationReview _review;
  final String requestId;

  Future<Failure?> load() async {
    final result = await _review.get(requestId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (state.request == null) emit(VerificationRequestState(status: AdminPageStatus.failure, failure: failure));
        return failure;
      },
      (request) {
        emit(VerificationRequestState(status: AdminPageStatus.ready, request: request));
        return null;
      },
    );
  }

  /// Approve: the badge shows at once. `409 verification.already_decided` reads the request again.
  Future<Failure?> approve() => _run(VerificationReviewCommand.approve, () => _review.approve(requestId), reload: true);

  /// Reject with a reason (5–500) the requester sees on their verification page.
  Future<Failure?> reject(String reason) =>
      _run(VerificationReviewCommand.reject, () => _review.reject(requestId, reason), reload: true);

  /// Remove the badge of an approved request's user; `409 verification.not_verified` also reads it again.
  Future<Failure?> removeBadge() async {
    final userId = state.request?.user.id;
    if (userId == null) return const Failure(FailureCodes.requestCancelled);
    return _run(VerificationReviewCommand.removeBadge, () => _review.removeBadge(userId), reload: true);
  }

  /// The proof file's bytes.
  Future<({Uint8List? bytes, Failure? failure})> proof() async {
    Uint8List? bytes;
    final failure = await _run(VerificationReviewCommand.proof, () async {
      final result = await _review.proof(requestId);
      bytes = result.valueOrNull;
      return result;
    });
    return (bytes: bytes, failure: failure);
  }

  Future<Failure?> _run<T>(VerificationReviewCommand command, Future<Result<T>> Function() call, {bool reload = false}) async {
    if (state.busy != null) return const Failure(FailureCodes.requestCancelled);
    emit(state.copyWith(busy: () => command));
    final result = await call();
    final failure = result.failureOrNull;
    final decided = failure?.code == FailureCodes.verificationAlreadyDecided ||
        failure?.code == FailureCodes.verificationNotVerified;
    if (reload && (failure == null || decided) && !isClosed) await load();
    if (!isClosed) emit(state.copyWith(busy: () => null));
    return failure;
  }
}
