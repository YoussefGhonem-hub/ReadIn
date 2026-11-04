import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';
import 'moderation_summary_cubit.dart';

/// Runs a moderator's action (F22) from the reader, a profile or a case. The state is the action in flight (null when
/// idle), so its button can show progress and the others wait.
@injectable
class ModerationActionCubit extends Cubit<ModerationCommand?> {
  ModerationActionCubit(this._act, this._summary) : super(null);

  final TakeModerationAction _act;
  final ModerationSummaryCubit _summary;

  bool get busy => state != null;

  /// Null when it worked. One action at a time: a second one while [busy] is ignored.
  Future<Failure?> run(ModerationCommand command) async {
    if (busy) return const Failure(FailureCodes.requestCancelled);
    emit(command);
    final result = await _act(command);
    if (isClosed) return result.failureOrNull;
    emit(null);
    if (result.isOk) await _summary.refresh();
    return result.failureOrNull;
  }
}
