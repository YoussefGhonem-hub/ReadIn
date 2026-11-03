import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/comment.dart';

/// Comments and replies (F11), comment reports and moderator actions (F22 hooks), @mention suggestions.
abstract interface class CommentsRepository {
  /// `GET /articles/{id}/comments`: top-level comments, each with its first 2 replies; the pinned one first.
  Future<Result<CommentPage>> getComments(String articleId, {CommentSort sort = CommentSort.top, String? cursor, int limit = 20});

  /// `GET /comments/{id}/replies`: a thread's replies, oldest first.
  Future<Result<CursorPage<Comment>>> getReplies(String commentId, {String? cursor, int limit = 20});

  /// `GET /comments/{id}`: one comment as the viewer sees it (placeholders included). Refetched after live events.
  Future<Result<Comment>> getComment(String commentId);

  /// `POST /articles/{id}/comments`.
  Future<Result<Comment>> postComment(String articleId, String body);

  /// `POST /comments/{id}/replies`: replying to a reply joins the same thread.
  Future<Result<Comment>> postReply(String commentId, String body);

  /// `PATCH /comments/{id}` (own comments only).
  Future<Result<Comment>> editComment(String commentId, String body);

  /// `DELETE /comments/{id}` (own comments only, idempotent).
  Future<Result<void>> deleteComment(String commentId);

  /// `PUT` / `DELETE /comments/{id}/like` (idempotent).
  Future<Result<CommentLike>> setLiked(String commentId, {required bool liked});

  /// `POST` / `DELETE /comments/{id}/pin` (the article's author only).
  Future<Result<Comment>> setPinned(String commentId, {required bool pinned});

  /// `GET /users/mention-suggestions?q=`: people to mention, never the viewer.
  Future<Result<List<Author>>> mentionSuggestions(String query, {int limit = 8});

  /// `POST /reports` with `targetType: comment`. Reporting again is a no-op.
  Future<Result<void>> reportComment(String commentId, ReportReason reason, {String? details});

  /// `POST /moderation/actions` with `targetType: comment` (`moderation.manage`).
  Future<Result<void>> moderateComment(String commentId, ModerationAction action);
}
