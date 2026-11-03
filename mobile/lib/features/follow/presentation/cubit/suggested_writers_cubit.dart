import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/follow.dart';
import '../../domain/usecases/follow_usecases.dart';
import 'follows_cubit.dart';

enum SuggestedWritersStatus { loading, ready, failure }

class SuggestedWritersState extends Equatable {
  const SuggestedWritersState({this.status = SuggestedWritersStatus.loading, this.users = const [], this.failure});

  final SuggestedWritersStatus status;
  final List<UserSummary> users;
  final Failure? failure;

  @override
  List<Object?> get props => [status, users, failure];
}

/// "Writers you might like" (F12): writers whose fields overlap the viewer's interests, verified first.
@injectable
class SuggestedWritersCubit extends Cubit<SuggestedWritersState> {
  SuggestedWritersCubit(this._getSuggested, this._follows) : super(const SuggestedWritersState());

  final GetSuggestedWriters _getSuggested;
  final FollowsCubit _follows;
  bool _started = false;

  /// A load was asked for (the list was shown once).
  bool get started => _started;

  Future<void> ensureLoaded() async {
    if (!_started) await load();
  }

  Future<void> load() async {
    _started = true;
    emit(const SuggestedWritersState());
    final result = await _getSuggested();
    if (isClosed) return;
    result.fold(
      (failure) => emit(SuggestedWritersState(status: SuggestedWritersStatus.failure, failure: failure)),
      (users) {
        _follows.seed({for (final user in users) user.id: user.isFollowing});
        emit(SuggestedWritersState(status: SuggestedWritersStatus.ready, users: users));
      },
    );
  }
}
