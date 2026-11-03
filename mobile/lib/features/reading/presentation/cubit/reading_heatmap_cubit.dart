import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/reading.dart';
import '../../domain/usecases/reading_usecases.dart';
import 'reading_stats_cubit.dart';

class ReadingHeatmapState extends Equatable {
  const ReadingHeatmapState({this.status = ReadingLoadStatus.loading, this.heatmap, this.failure});

  final ReadingLoadStatus status;
  final ReadingHeatmapData? heatmap;
  final Failure? failure;

  @override
  List<Object?> get props => [status, heatmap, failure];
}

/// The reading heatmap (F08, F14): `GET /me/stats/heatmap` for the last 12 months.
@injectable
class ReadingHeatmapCubit extends Cubit<ReadingHeatmapState> {
  ReadingHeatmapCubit(this._getHeatmap) : super(const ReadingHeatmapState());

  final GetReadingHeatmap _getHeatmap;

  Future<void> load() async {
    emit(const ReadingHeatmapState());
    final result = await _getHeatmap();
    if (isClosed) return;
    emit(result.fold(
      (failure) => ReadingHeatmapState(status: ReadingLoadStatus.failure, failure: failure),
      (heatmap) => ReadingHeatmapState(status: ReadingLoadStatus.ready, heatmap: heatmap),
    ));
  }
}
