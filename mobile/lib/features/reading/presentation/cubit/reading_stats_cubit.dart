import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/reading.dart';
import '../../domain/usecases/reading_usecases.dart';
import 'streak_cubit.dart';

enum ReadingLoadStatus { loading, ready, failure }

class ReadingStatsState extends Equatable {
  const ReadingStatsState({this.status = ReadingLoadStatus.loading, this.stats, this.failure});

  final ReadingLoadStatus status;
  final ReadingStats? stats;
  final Failure? failure;

  @override
  List<Object?> get props => [status, stats, failure];
}

/// The reading stats card (F08, F14): `GET /me/stats`, or another user's public stats on their profile. The viewer's
/// own fresh streak also updates the Home badge.
@injectable
class ReadingStatsCubit extends Cubit<ReadingStatsState> {
  ReadingStatsCubit(this._getStats, this._streak) : super(const ReadingStatsState());

  final GetReadingStats _getStats;
  final StreakCubit _streak;

  /// [username] null: the viewer's own stats.
  Future<void> load({String? username}) async {
    emit(const ReadingStatsState());
    final result = await _getStats(username: username);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ReadingStatsState(status: ReadingLoadStatus.failure, failure: failure)),
      (stats) {
        if (username == null) _streak.apply(stats.streak);
        emit(ReadingStatsState(status: ReadingLoadStatus.ready, stats: stats));
      },
    );
  }
}
