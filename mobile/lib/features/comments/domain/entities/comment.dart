import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// An `@username` the API resolved to a real user (`CommentDto.mentions`). Clients link exactly these handles.
class CommentMention extends Equatable {
  const CommentMention({required this.userId, required this.username});

  final String userId;
  final String username;

  @override
  List<Object?> get props => [userId, username];
}

/// `CommentDto` (F11): a top-level comment or a reply, as the viewer sees it.
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.articleId,
    required this.createdAt,
    this.parentId,
    this.body,
    this.author,
    this.isArticleAuthor = false,
    this.mentions = const [],
    this.likeCount = 0,
    this.likedByMe = false,
    this.replyCount = 0,
    this.isPinned = false,
    this.editedAt,
    this.isDeleted = false,
    this.isHidden = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canPin = false,
    this.canReport = false,
    this.canModerate = false,
    this.replies = const [],
    this.isAuthorMuted = false,
    this.isFollowingAuthor = false,
    this.reportedByMe = false,
    this.isUnavailable = false,
  });

  final String id;
  final String articleId;

  /// The thread's top-level comment; null for top-level comments.
  final String? parentId;

  /// Null for placeholders (deleted, or hidden from this viewer).
  final String? body;

  /// Null: a deleted account ("Deleted user"), or a placeholder.
  final Author? author;

  /// The viewer muted the author (F28): the comment collapses to "تعليق من شخص كتمته" with "عرض"; its replies stay.
  /// False for guests and placeholders.
  final bool isAuthorMuted;

  /// The viewer follows the author (F11, F12): the row shows "متابعة" while false (never on your own comments). False
  /// for guests, your own comments, a deleted author and placeholders. It seeds the follow store.
  final bool isFollowingAuthor;

  /// The "الكاتب" badge.
  final bool isArticleAuthor;
  final List<CommentMention> mentions;
  final int likeCount;
  final bool likedByMe;

  /// Visible replies (top-level comments).
  final int replyCount;
  final bool isPinned;
  final DateTime createdAt;

  /// "edited".
  final DateTime? editedAt;

  /// Placeholder of a deleted comment, kept for its replies.
  final bool isDeleted;

  /// Hidden by a moderator: a placeholder for others, the full text for its author and moderators.
  final bool isHidden;
  final bool canEdit;
  final bool canDelete;
  final bool canPin;
  final bool canReport;
  final bool canModerate;

  /// In lists: the first replies of a top-level comment, oldest first.
  final List<Comment> replies;

  /// The viewer reported it (F22 store additions): collapsed for them with «عرض» / "Show"; its replies stay.
  final bool reportedByMe;

  /// By someone the viewer is blocked with (F36), kept as a placeholder because others replied: «هذا التعليق غير
  /// متاح», no text, no author.
  final bool isUnavailable;

  bool get isReply => parentId != null;

  /// Deleted, or hidden from this viewer: no text, no author, no actions.
  bool get isPlaceholder => body == null;

  /// The id of the thread this comment belongs to.
  String get threadId => parentId ?? id;

  Comment copyWith({
    String? body,
    int? likeCount,
    bool? likedByMe,
    int? replyCount,
    bool? isPinned,
    bool? isHidden,
    List<Comment>? replies,
  }) =>
      Comment(
        id: id,
        articleId: articleId,
        parentId: parentId,
        body: body ?? this.body,
        author: author,
        isArticleAuthor: isArticleAuthor,
        mentions: mentions,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
        replyCount: replyCount ?? this.replyCount,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt,
        editedAt: editedAt,
        isDeleted: isDeleted,
        isHidden: isHidden ?? this.isHidden,
        canEdit: canEdit,
        canDelete: canDelete,
        canPin: canPin,
        canReport: canReport,
        canModerate: canModerate,
        replies: replies ?? this.replies,
        isAuthorMuted: isAuthorMuted,
        isFollowingAuthor: isFollowingAuthor,
        reportedByMe: reportedByMe,
        isUnavailable: isUnavailable,
      );

  /// What a deleted top-level comment with replies becomes: a placeholder that keeps its thread.
  Comment asDeletedPlaceholder() => Comment(
        id: id,
        articleId: articleId,
        parentId: parentId,
        createdAt: createdAt,
        replyCount: replyCount,
        isDeleted: true,
        replies: replies,
      );

  @override
  List<Object?> get props => [
        id,
        articleId,
        parentId,
        body,
        author,
        isArticleAuthor,
        mentions,
        likeCount,
        likedByMe,
        replyCount,
        isPinned,
        createdAt,
        editedAt,
        isDeleted,
        isHidden,
        canEdit,
        canDelete,
        canPin,
        canReport,
        canModerate,
        replies,
        isAuthorMuted,
        isFollowingAuthor,
        reportedByMe,
        isUnavailable,
      ];
}

/// `CommentPageDto`: top-level comments with their first replies; [total] is the article's comment count.
class CommentPage extends Equatable {
  const CommentPage({required this.items, this.nextCursor, required this.total});

  final List<Comment> items;
  final String? nextCursor;
  final int total;

  @override
  List<Object?> get props => [items, nextCursor, total];
}

/// `CommentLikeDto`.
class CommentLike extends Equatable {
  const CommentLike({required this.likeCount, required this.liked});

  final int likeCount;
  final bool liked;

  @override
  List<Object?> get props => [likeCount, liked];
}

/// `top` (likes + 2 × replies, then newest) or `new` (newest first).
enum CommentSort {
  top('top'),
  newest('new');

  const CommentSort(this.wire);

  final String wire;
}

/// What a moderator does to a comment (F22 hooks in F11).
enum ModerationAction { hide, unhide, delete }
