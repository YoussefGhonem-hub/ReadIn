import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comments_repository.dart';
import '../datasources/comments_api.dart';
import '../models/comment_models.dart';

@LazySingleton(as: CommentsRepository)
class CommentsRepositoryImpl implements CommentsRepository {
  CommentsRepositoryImpl(this._api);

  final CommentsApi _api;

  static const _comment = 'comment';

  @override
  Future<Result<CommentPage>> getComments(String articleId, {CommentSort sort = CommentSort.top, String? cursor, int limit = 20}) =>
      guardApi(() async => (await _api.getComments(articleId, sort.wire, cursor, limit)).toEntity());

  @override
  Future<Result<CursorPage<Comment>>> getReplies(String commentId, {String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.getReplies(commentId, cursor, limit);
        return CursorPage(items: [for (final c in page.items) c.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<Comment>> getComment(String commentId) => guardApi(() async => (await _api.getComment(commentId)).toEntity());

  @override
  Future<Result<Comment>> postComment(String articleId, String body) =>
      guardApi(() async => (await _api.postComment(articleId, CommentBodyRequest(body: body))).toEntity());

  @override
  Future<Result<Comment>> postReply(String commentId, String body) =>
      guardApi(() async => (await _api.postReply(commentId, CommentBodyRequest(body: body))).toEntity());

  @override
  Future<Result<Comment>> editComment(String commentId, String body) =>
      guardApi(() async => (await _api.editComment(commentId, CommentBodyRequest(body: body))).toEntity());

  @override
  Future<Result<void>> deleteComment(String commentId) => guardApi(() => _api.deleteComment(commentId));

  @override
  Future<Result<CommentLike>> setLiked(String commentId, {required bool liked}) =>
      guardApi(() async => (await (liked ? _api.like(commentId) : _api.unlike(commentId))).toEntity());

  @override
  Future<Result<Comment>> setPinned(String commentId, {required bool pinned}) =>
      guardApi(() async => (await (pinned ? _api.pin(commentId) : _api.unpin(commentId))).toEntity());

  @override
  Future<Result<List<Author>>> mentionSuggestions(String query, {int limit = 8}) =>
      guardApi(() async => [for (final m in await _api.mentionSuggestions(query, limit)) m.toEntity()]);

  @override
  Future<Result<void>> reportComment(String commentId, ReportReason reason, {String? details}) => guardApi(
        () => _api.report(ReportRequest(targetType: _comment, targetId: commentId, reason: reason.name, details: details)),
      );

  @override
  Future<Result<void>> moderateComment(String commentId, ModerationAction action) => guardApi(
        () => _api.moderate(ModerationActionRequest(action: action.name, targetType: _comment, targetId: commentId)),
      );
}
