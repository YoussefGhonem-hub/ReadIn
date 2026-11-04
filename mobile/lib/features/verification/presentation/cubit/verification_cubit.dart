import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/verification.dart';
import '../../domain/usecases/verification_usecases.dart';

enum VerificationLoad { loading, ready, failure }

/// What the verification page shows.
enum VerificationScreen {
  /// I'm a verified writer.
  approved,

  /// My request waits for a review: its date and "Withdraw".
  pending,

  /// My latest request wasn't approved: the reason and "Request again".
  rejected,

  /// The request form.
  form,

  /// Not verified, nothing pending, and no request allowed now (a suspended account).
  unavailable,
}

class VerificationState extends Equatable {
  const VerificationState({
    this.load = VerificationLoad.loading,
    this.status,
    this.failure,
    this.requestingAgain = false,
    this.draft,
    this.withdrawing = false,
  });

  final VerificationLoad load;
  final VerificationStatus? status;

  /// Why the status couldn't be loaded.
  final Failure? failure;

  /// "Request again" was pressed on a rejected request: the form shows instead.
  final bool requestingAgain;

  /// What the form starts from: the rejected request being sent again, or the request just withdrawn.
  final VerificationRequest? draft;
  final bool withdrawing;

  /// Null until the status is loaded.
  VerificationScreen? get screen {
    final status = this.status;
    if (load != VerificationLoad.ready || status == null) return null;
    if (status.isVerified) return VerificationScreen.approved;
    final request = status.request;
    if (request != null && request.isPending) return VerificationScreen.pending;
    if (request != null && request.isRejected && !requestingAgain) return VerificationScreen.rejected;
    return status.canRequest ? VerificationScreen.form : VerificationScreen.unavailable;
  }

  @override
  List<Object?> get props => [load, status, failure, requestingAgain, draft, withdrawing];
}

/// My writer verification (F19): the status (`GET /me/verification`), withdrawing a pending request and "Request
/// again" after a rejection. Settings shows the same status on its "Writer verification" row. Whenever the status
/// says I'm verified and the session doesn't (an approval since `me` was read), or the other way round, `me` is read
/// again so the badge follows.
@injectable
class VerificationCubit extends Cubit<VerificationState> {
  VerificationCubit(this._get, this._withdraw, this._session) : super(const VerificationState());

  final GetVerificationStatus _get;
  final WithdrawVerificationRequest _withdraw;
  final SessionCubit _session;

  Future<void> load() async {
    if (state.load != VerificationLoad.loading) emit(const VerificationState());
    final result = await _get();
    if (isClosed) return;
    result.fold(
      (failure) => emit(VerificationState(load: VerificationLoad.failure, failure: failure)),
      _show,
    );
  }

  void _show(VerificationStatus status, {VerificationRequest? draft}) {
    emit(VerificationState(load: VerificationLoad.ready, status: status, draft: draft));
    _syncSession(status);
  }

  void _syncSession(VerificationStatus status) {
    final session = _session.state;
    final me = session.me;
    if (session.isAuthenticated && me != null && me.isVerified != status.isVerified) unawaited(_session.refresh());
  }

  /// A rejected request is shown with "Request again": the form, starting from it.
  void requestAgain() {
    final status = state.status;
    if (state.screen != VerificationScreen.rejected || status == null || !status.canRequest) return;
    emit(VerificationState(load: VerificationLoad.ready, status: status, requestingAgain: true, draft: status.request));
  }

  /// Back from the form to the rejected request.
  void cancelRequestAgain() {
    if (!state.requestingAgain) return;
    emit(VerificationState(load: VerificationLoad.ready, status: state.status));
  }

  /// The form sent [request]: it is pending now.
  void submitted(VerificationRequest request) =>
      emit(VerificationState(load: VerificationLoad.ready, status: VerificationStatus(request: request)));

  /// Withdraws the pending request; then the form shows, starting from it. Null on success, else the failure: one that
  /// was decided meanwhile (`verification.not_found`) is shown as it is now.
  Future<Failure?> withdraw() async {
    final status = state.status;
    final pending = status?.pending;
    if (status == null || pending == null || state.withdrawing) return null;
    emit(VerificationState(load: VerificationLoad.ready, status: status, withdrawing: true));
    final result = await _withdraw();
    if (isClosed) return null;
    final failure = result.failureOrNull;
    if (failure == null) {
      _show(const VerificationStatus(canRequest: true), draft: pending);
    } else if (failure.code == FailureCodes.verificationNotFound) {
      await load();
    } else {
      emit(VerificationState(load: VerificationLoad.ready, status: status));
    }
    return failure;
  }
}
