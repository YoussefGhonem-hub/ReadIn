import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/reading.dart';
import '../../domain/repositories/reading_repository.dart';
import '../datasources/reading_api.dart';
import '../models/reading_models.dart';

@LazySingleton(as: ReadingRepository)
class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl(this._api);

  final ReadingApi _api;

  @override
  Future<Result<ReadingProgressResult>> reportProgress(String articleId, ReadingProgressReport report) =>
      guardApi(() async =>
          (await _api.reportProgress(articleId, ReadingProgressRequestModel.fromReport(report))).toEntity());

  @override
  Future<Result<ReadingStats>> getStats({String? username}) => guardApi(
        () async => (username == null ? await _api.getStats() : await _api.getUserStats(username)).toEntity(),
      );

  @override
  Future<Result<ReadingHeatmapData>> getHeatmap({int days = 365, String? username}) => guardApi(
        () async =>
            (username == null ? await _api.getHeatmap(days) : await _api.getUserHeatmap(username, days)).toEntity(),
      );
}
