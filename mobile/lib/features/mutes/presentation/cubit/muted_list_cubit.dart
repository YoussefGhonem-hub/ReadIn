import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/mutes.dart';
import '../../domain/usecases/mute_usecases.dart';
import 'mutes_cubit.dart';

enum MutedListStatus { loading, ready, failure }

class MutedListState extends Equatable {
  const MutedListState({this.status = MutedListStatus.loading, this.mutes = const Mutes(), this.failure});

  final MutedListStatus status;
  final Mutes mutes;
  final Failure? failure;

  MutedListState copyWith({MutedListStatus? status, Mutes? mutes, Failure? Function()? failure}) => MutedListState(
        status: status ?? this.status,
        mutes: mutes ?? this.mutes,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [status, mutes, failure];
}

/// Settings → Muted (F18, F28): one list of the writers, fields and topics the viewer muted. Unmuting goes through
/// [MutesCubit], so every screen hears of it, and takes the row out once the API agrees.
@injectable
class MutedListCubit extends Cubit<MutedListState> {
  MutedListCubit(this._getMutes, this._mutes) : super(const MutedListState());

  final GetMutes _getMutes;
  final MutesCubit _mutes;

  Future<void> load() async {
    emit(state.copyWith(status: MutedListStatus.loading, failure: () => null));
    final result = await _getMutes();
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(MutedListState(status: MutedListStatus.ready, mutes: value));
      case Err(:final failure):
        emit(state.copyWith(status: MutedListStatus.failure, failure: () => failure));
    }
  }

  /// Null once the writer's row is gone, else why it stays.
  Future<Failure?> unmuteUser(String userId) async {
    final failure = (await _mutes.unmuteUser(userId)).failureOrNull;
    if (failure == null && !isClosed) {
      emit(state.copyWith(mutes: state.mutes.copyWith(users: [...state.mutes.users.where((u) => u.id != userId)])));
    }
    return failure;
  }

  Future<Failure?> unmuteField(String fieldId) async {
    final failure = await _mutes.setFieldMuted(fieldId, muted: false);
    if (failure == null && !isClosed) {
      emit(state.copyWith(mutes: state.mutes.copyWith(fields: [...state.mutes.fields.where((f) => f.id != fieldId)])));
    }
    return failure;
  }

  Future<Failure?> unmuteTopic(String topicId) async {
    final failure = await _mutes.setTopicMuted(topicId, muted: false);
    if (failure == null && !isClosed) {
      emit(state.copyWith(mutes: state.mutes.copyWith(topics: [...state.mutes.topics.where((t) => t.id != topicId)])));
    }
    return failure;
  }
}
