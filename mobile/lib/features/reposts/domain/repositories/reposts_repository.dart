import '../../../../core/errors/result.dart';
import '../entities/repost_state.dart';

abstract interface class RepostsRepository {
  /// `PUT /articles/{id}/repost` (idempotent). `400 repost.own_article` on the viewer's own article.
  Future<Result<RepostState>> repost(String articleId);

  /// `DELETE /articles/{id}/repost` (idempotent).
  Future<Result<RepostState>> undoRepost(String articleId);
}
