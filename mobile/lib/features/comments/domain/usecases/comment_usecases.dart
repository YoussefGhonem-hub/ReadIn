import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../entities/comment.dart';
import '../repositories/comments_repository.dart';

/// Reads an article's comments, a thread's replies and single comments (F11). Public, guests too.
@injectable
class GetComments {
  const GetComments(this._repository);

  final CommentsRepository _repository;

  static const pageSize = 20;

  /// "Show N more replies" loads the rest of a thread, up to the API's page maximum at a time.
  static const repliesPageSize = 50;

  Future<Result<CommentPage>> call(String articleId, {CommentSort sort = CommentSort.top, String? cursor}) =>
      _repository.getComments(articleId, sort: sort, cursor: cursor, limit: pageSize);

  Future<Result<CursorPage<Comment>>> replies(String commentId, {String? cursor}) =>
      _repository.getReplies(commentId, cursor: cursor, limit: repliesPageSize);

  Future<Result<Comment>> one(String commentId) => _repository.getComment(commentId);
}

/// Posts a comment, or a reply when [replyToId] is set (a top-level comment or a reply: the API joins the thread).
@injectable
class PostComment {
  const PostComment(this._repository);

  final CommentsRepository _repository;

  Future<Result<Comment>> call(String articleId, String body, {String? replyToId}) =>
      replyToId == null ? _repository.postComment(articleId, body) : _repository.postReply(replyToId, body);
}

@injectable
class EditComment {
  const EditComment(this._repository);

  final CommentsRepository _repository;

  Future<Result<Comment>> call(String commentId, String body) => _repository.editComment(commentId, body);
}

@injectable
class DeleteComment {
  const DeleteComment(this._repository);

  final CommentsRepository _repository;

  Future<Result<void>> call(String commentId) => _repository.deleteComment(commentId);
}

@injectable
class SetCommentLiked {
  const SetCommentLiked(this._repository);

  final CommentsRepository _repository;

  Future<Result<CommentLike>> call(String commentId, {required bool liked}) =>
      _repository.setLiked(commentId, liked: liked);
}

@injectable
class SetCommentPinned {
  const SetCommentPinned(this._repository);

  final CommentsRepository _repository;

  Future<Result<Comment>> call(String commentId, {required bool pinned}) =>
      _repository.setPinned(commentId, pinned: pinned);
}

@injectable
class SuggestMentions {
  const SuggestMentions(this._repository);

  final CommentsRepository _repository;

  static const limit = 8;

  Future<Result<List<Author>>> call(String query) => _repository.mentionSuggestions(query, limit: limit);
}

@injectable
class ReportComment {
  const ReportComment(this._repository);

  final CommentsRepository _repository;

  static const maxDetailsLength = 500;

  Future<Result<void>> call(String commentId, ReportReason reason, {String? details}) {
    final trimmed = details?.trim();
    return _repository.reportComment(commentId, reason, details: trimmed == null || trimmed.isEmpty ? null : trimmed);
  }
}

@injectable
class ModerateComment {
  const ModerateComment(this._repository);

  final CommentsRepository _repository;

  Future<Result<void>> call(String commentId, ModerationAction action) => _repository.moderateComment(commentId, action);
}
