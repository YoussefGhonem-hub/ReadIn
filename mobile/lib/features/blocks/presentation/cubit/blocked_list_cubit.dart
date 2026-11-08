import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/blocks.dart';
import '../../domain/usecases/block_usecases.dart';
import 'blocks_cubit.dart';

enum BlockedListStatus { loading, ready, failure }

class BlockedListState extends Equatable {
  const BlockedListState({this.status = BlockedListStatus.loading, this.items = const [], this.failure});

  final BlockedListStatus status;
  final List<BlockedUser> items;
  final Failure? failure;

  @override
  List<Object?> get props => [status, items, failure];
}

/// Settings → Blocked accounts (F18, F36): everyone the viewer blocked, newest first. Unblocking goes through
/// [BlocksCubit], so every screen hears of it, and takes the row out once the API agrees. Follows don't come back.
@injectable
class BlockedListCubit extends Cubit<BlockedListState> {
  BlockedListCubit(this._get, this._blocks) : super(const BlockedListState());

  final GetBlockedUsers _get;
  final BlocksCubit _blocks;

  Future<void> load() async {
    if (state.status != BlockedListStatus.loading) emit(const BlockedListState());
    final result = await _get();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => BlockedListState(status: BlockedListStatus.ready, items: value),
      Err(:final failure) => BlockedListState(status: BlockedListStatus.failure, failure: failure),
    });
  }

  /// Null once the row is gone, else why it stays.
  Future<Failure?> unblock(String userId) async {
    final failure = (await _blocks.unblock(userId)).failureOrNull;
    if (failure == null && !isClosed) {
      emit(BlockedListState(status: state.status, items: [...state.items.where((b) => b.user.id != userId)]));
    }
    return failure;
  }
}
