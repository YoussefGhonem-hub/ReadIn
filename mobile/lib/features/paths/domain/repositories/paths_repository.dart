import '../../../../core/errors/result.dart';
import '../entities/learning_path.dart';

abstract interface class PathsRepository {
  /// `GET /paths?field=`: published paths in editorial order (guests allowed).
  Future<Result<List<LearningPath>>> getPaths({String? fieldSlug});

  /// `GET /paths/{slug}`: `404 path.not_found` when it's unknown, unpublished or has nothing a reader can open.
  Future<Result<PathDetails>> getPath(String slug);

  /// `GET /articles/{id}/path`: null when the article is in no published path (HTTP 204).
  Future<Result<ArticlePath?>> getArticlePath(String articleId);

  /// `GET /users/{username}/paths`: `403 profile.stats_private`, `404 user.not_found`.
  Future<Result<List<LearningPath>>> getUserPaths(String username);

  /// `GET /me/paths`: in progress first (latest activity first), then completed.
  Future<Result<List<LearningPath>>> getMyPaths();

  /// `GET /me/paths/active`: null when no enrolled path is in progress (HTTP 204).
  Future<Result<LearningPath?>> getActivePath();

  /// `PUT /me/paths/{pathId}` (idempotent): the path with the viewer's enrollment and progress.
  Future<Result<LearningPath>> enroll(String pathId);

  /// `DELETE /me/paths/{pathId}` (idempotent). Reading history is kept.
  Future<Result<void>> leave(String pathId);
}
