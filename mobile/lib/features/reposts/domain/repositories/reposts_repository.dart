import '../../../../core/errors/result.dart';
import '../entities/repost_state.dart';

abstract interface class RepostsRepository {
  /// `PUT /articles/{id}/repost` (idempotent). With no [caption] there is no body: no caption on a new repost, the
  /// caption unchanged on an existing one. A [caption] sets it ("" clears it). `400 repost.own_article` on the viewer's
  /// own article, `400 validation.failed` with `caption: ["repost.caption_too_long"]` over 500 characters.
  Future<Result<RepostState>> repost(String articleId, {String? caption});

  /// `GET /articles/{id}/repost`: the viewer's repost now, with its caption.
  Future<Result<RepostState>> getRepost(String articleId);

  /// `DELETE /articles/{id}/repost` (idempotent). The caption goes with the repost.
  Future<Result<RepostState>> undoRepost(String articleId);
}
