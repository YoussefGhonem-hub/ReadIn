import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/reading.dart';
import '../repositories/reading_repository.dart';

/// Reports the reader's scroll and active seconds (SPEC F04, ADR 0013).
@injectable
class ReportReadingProgress {
  const ReportReadingProgress(this._repository);

  final ReadingRepository _repository;

  Future<Result<ReadingProgressResult>> call(String articleId, ReadingProgressReport report) =>
      _repository.reportProgress(articleId, report);
}

@injectable
class GetReadingStats {
  const GetReadingStats(this._repository);

  final ReadingRepository _repository;

  /// The viewer's own stats, or with [username] that user's public stats (F14).
  Future<Result<ReadingStats>> call({String? username}) => _repository.getStats(username: username);
}

@injectable
class GetReadingHeatmap {
  const GetReadingHeatmap(this._repository);

  final ReadingRepository _repository;

  /// The last 12 months (SPEC F08).
  static const days = 365;

  Future<Result<ReadingHeatmapData>> call({String? username}) => _repository.getHeatmap(days: days, username: username);
}
