import '../../../../core/errors/result.dart';
import '../entities/reading.dart';

abstract interface class ReadingRepository {
  /// `PUT /articles/{id}/progress` — `404 article.not_found`, `409 reading.conflict` (send it again).
  Future<Result<ReadingProgressResult>> reportProgress(String articleId, ReadingProgressReport report);

  /// `GET /me/stats` (owner only).
  Future<Result<ReadingStats>> getStats();

  /// `GET /me/stats/heatmap?days=` — [days] 1–371.
  Future<Result<ReadingHeatmapData>> getHeatmap({int days = 365});
}
