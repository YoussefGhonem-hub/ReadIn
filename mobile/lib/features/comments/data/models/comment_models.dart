import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/comment.dart';

part 'comment_models.freezed.dart';
part 'comment_models.g.dart';

/// Body of `POST /articles/{id}/comments`, `POST /comments/{id}/replies` and `PATCH /comments/{id}`.
@freezed
abstract class CommentBodyRequest with _$CommentBodyRequest {
  const factory CommentBodyRequest({required String body}) = _CommentBodyRequest;

  factory CommentBodyRequest.fromJson(Map<String, dynamic> json) => _$CommentBodyRequestFromJson(json);
}

/// `CommentDto.mentions[]`.
@freezed
abstract class CommentMentionModel with _$CommentMentionModel {
  const CommentMentionModel._();

  const factory CommentMentionModel({required String userId, required String username}) = _CommentMentionModel;

  factory CommentMentionModel.fromJson(Map<String, dynamic> json) => _$CommentMentionModelFromJson(json);

  CommentMention toEntity() => CommentMention(userId: userId, username: username);
}

/// `CommentDto`.
@freezed
abstract class CommentModel with _$CommentModel {
  const CommentModel._();

  const factory CommentModel({
    required String id,
    required String articleId,
    String? parentId,
    String? body,
    AuthorModel? author,
    @Default(false) bool isArticleAuthor,
    @Default(<CommentMentionModel>[]) List<CommentMentionModel> mentions,
    @Default(0) int likeCount,
    @Default(false) bool likedByMe,
    @Default(0) int replyCount,
    @Default(false) bool isPinned,
    required DateTime createdAt,
    DateTime? editedAt,
    @Default(false) bool isDeleted,
    @Default(false) bool isHidden,
    @Default(false) bool canEdit,
    @Default(false) bool canDelete,
    @Default(false) bool canPin,
    @Default(false) bool canReport,
    @Default(false) bool canModerate,
    List<CommentModel>? replies,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) => _$CommentModelFromJson(json);

  Comment toEntity() => Comment(
        id: id,
        articleId: articleId,
        parentId: parentId,
        body: body,
        author: author?.toEntity(),
        isArticleAuthor: isArticleAuthor,
        mentions: [for (final m in mentions) m.toEntity()],
        likeCount: likeCount,
        likedByMe: likedByMe,
        replyCount: replyCount,
        isPinned: isPinned,
        createdAt: createdAt,
        editedAt: editedAt,
        isDeleted: isDeleted,
        isHidden: isHidden,
        canEdit: canEdit,
        canDelete: canDelete,
        canPin: canPin,
        canReport: canReport,
        canModerate: canModerate,
        replies: [for (final r in replies ?? const <CommentModel>[]) r.toEntity()],
      );
}

/// `CommentPageDto`.
@freezed
abstract class CommentPageModel with _$CommentPageModel {
  const CommentPageModel._();

  const factory CommentPageModel({
    @Default(<CommentModel>[]) List<CommentModel> items,
    String? nextCursor,
    @Default(0) int total,
  }) = _CommentPageModel;

  factory CommentPageModel.fromJson(Map<String, dynamic> json) => _$CommentPageModelFromJson(json);

  CommentPage toEntity() =>
      CommentPage(items: [for (final c in items) c.toEntity()], nextCursor: nextCursor, total: total);
}

/// `CursorPage<CommentDto>` (a thread's replies).
@freezed
abstract class CommentRepliesPageModel with _$CommentRepliesPageModel {
  const factory CommentRepliesPageModel({@Default(<CommentModel>[]) List<CommentModel> items, String? nextCursor}) =
      _CommentRepliesPageModel;

  factory CommentRepliesPageModel.fromJson(Map<String, dynamic> json) => _$CommentRepliesPageModelFromJson(json);
}

/// `CommentLikeDto`.
@freezed
abstract class CommentLikeModel with _$CommentLikeModel {
  const CommentLikeModel._();

  const factory CommentLikeModel({required int likeCount, required bool liked}) = _CommentLikeModel;

  factory CommentLikeModel.fromJson(Map<String, dynamic> json) => _$CommentLikeModelFromJson(json);

  CommentLike toEntity() => CommentLike(likeCount: likeCount, liked: liked);
}

/// `MentionCandidateDto`: the same shape as `AuthorDto`.
@freezed
abstract class MentionCandidateModel with _$MentionCandidateModel {
  const MentionCandidateModel._();

  const factory MentionCandidateModel({
    required String id,
    required String displayName,
    required String username,
    String? avatarUrl,
    @Default(false) bool isVerified,
  }) = _MentionCandidateModel;

  factory MentionCandidateModel.fromJson(Map<String, dynamic> json) => _$MentionCandidateModelFromJson(json);

  Author toEntity() =>
      Author(id: id, displayName: displayName, username: username, avatarUrl: avatarUrl, isVerified: isVerified);
}
