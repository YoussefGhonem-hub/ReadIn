import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';

class ReportState extends Equatable {
  const ReportState({this.reason, this.sending = false, this.sent = false, this.failure});

  final ReportReason? reason;
  final bool sending;
  final bool sent;
  final Failure? failure;

  /// Send is enabled once a reason is chosen.
  bool get canSend => reason != null && !sending && !sent;

  @override
  List<Object?> get props => [reason, sending, sent, failure];
}

/// The report sheet (F22): one reason and optional details for an article, a comment, a user or a repost; with
/// [send]'s `alsoBlock` the author is blocked in the same step (F36).
@injectable
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._submit) : super(const ReportState());

  final SubmitReport _submit;

  void choose(ReportReason reason) {
    if (!state.sending && !state.sent) emit(ReportState(reason: reason));
  }

  Future<void> send(ModerationTargetRef target, {String? details, bool alsoBlock = false}) async {
    final reason = state.reason;
    if (reason == null || !state.canSend) return;
    emit(ReportState(reason: reason, sending: true));
    final result = await _submit(target, reason, details: details, alsoBlock: alsoBlock);
    if (isClosed) return;
    emit(ReportState(reason: reason, sent: result.isOk, failure: result.failureOrNull));
  }
}
