import '../../../../core/errors/result.dart';
import '../entities/reading.dart';

abstract interface class ReadingRepository {
  /// `PUT /articles/{id}/progress` — `404 article.not_found`, `409 reading.conflict` (send it again).
  Future<Result<ReadingProgressResult>> reportProgress(String articleId, ReadingProgressReport report);

  /// `GET /me/stats` (owner only), or with [username] `GET /users/{username}/stats` (F14, guests allowed;
  /// `403 profile.stats_private` when that user keeps them private).
  Future<Result<ReadingStats>> getStats({String? username});

  /// `GET /me/stats/heatmap?days=` — [days] 1–371. With [username]: `GET /users/{username}/stats/heatmap`.
  Future<Result<ReadingHeatmapData>> getHeatmap({int days = 365, String? username});
}
