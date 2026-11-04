import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';

enum ModerationCaseStatus { loading, ready, failure }

class ModerationCaseState extends Equatable {
  const ModerationCaseState({this.status = ModerationCaseStatus.loading, this.moderationCase, this.failure});

  final ModerationCaseStatus status;
  final ModerationCase? moderationCase;
  final Failure? failure;

  @override
  List<Object?> get props => [status, moderationCase, failure];
}

/// One case (F22): the target, its reports and its history. Reloaded after every action on it.
@injectable
class ModerationCaseCubit extends Cubit<ModerationCaseState> {
  ModerationCaseCubit(this._getCase) : super(const ModerationCaseState());

  final GetModerationCase _getCase;
  ModerationTargetRef? _target;
  int _generation = 0;

  Future<void> load(ModerationTargetRef target) async {
    _target = target;
    emit(const ModerationCaseState());
    await _fetch();
  }

  /// After an action, or to try again: the case stays on screen until the new one arrives.
  Future<void> refresh() async {
    if (_target == null) return;
    if (state.moderationCase == null) emit(const ModerationCaseState());
    await _fetch();
  }

  Future<void> _fetch() async {
    final generation = ++_generation;
    final result = await _getCase(_target!);
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) {
        // A refresh that fails keeps the case shown.
        if (state.moderationCase == null) emit(ModerationCaseState(status: ModerationCaseStatus.failure, failure: failure));
      },
      (moderationCase) => emit(ModerationCaseState(status: ModerationCaseStatus.ready, moderationCase: moderationCase)),
    );
  }
}
