// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentBodyRequest _$CommentBodyRequestFromJson(Map<String, dynamic> json) =>
    _CommentBodyRequest(body: json['body'] as String);

Map<String, dynamic> _$CommentBodyRequestToJson(_CommentBodyRequest instance) =>
    <String, dynamic>{'body': instance.body};

_CommentMentionModel _$CommentMentionModelFromJson(Map<String, dynamic> json) =>
    _CommentMentionModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$CommentMentionModelToJson(
  _CommentMentionModel instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
};

_CommentModel _$CommentModelFromJson(Map<String, dynamic> json) =>
    _CommentModel(
      id: json['id'] as String,
      articleId: json['articleId'] as String,
      parentId: json['parentId'] as String?,
      body: json['body'] as String?,
      author: json['author'] == null
          ? null
          : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      isArticleAuthor: json['isArticleAuthor'] as bool? ?? false,
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map(
                (e) => CommentMentionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CommentMentionModel>[],
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      canEdit: json['canEdit'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
      canPin: json['canPin'] as bool? ?? false,
      canReport: json['canReport'] as bool? ?? false,
      canModerate: json['canModerate'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAuthorMuted: json['isAuthorMuted'] as bool? ?? false,
      isFollowingAuthor: json['isFollowingAuthor'] as bool? ?? false,
    );

Map<String, dynamic> _$CommentModelToJson(_CommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'articleId': instance.articleId,
      'parentId': ?instance.parentId,
      'body': ?instance.body,
      'author': ?instance.author?.toJson(),
      'isArticleAuthor': instance.isArticleAuthor,
      'mentions': instance.mentions.map((e) => e.toJson()).toList(),
      'likeCount': instance.likeCount,
      'likedByMe': instance.likedByMe,
      'replyCount': instance.replyCount,
      'isPinned': instance.isPinned,
      'createdAt': instance.createdAt.toIso8601String(),
      'editedAt': ?instance.editedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'isHidden': instance.isHidden,
      'canEdit': instance.canEdit,
      'canDelete': instance.canDelete,
      'canPin': instance.canPin,
      'canReport': instance.canReport,
      'canModerate': instance.canModerate,
      'replies': ?instance.replies?.map((e) => e.toJson()).toList(),
      'isAuthorMuted': instance.isAuthorMuted,
      'isFollowingAuthor': instance.isFollowingAuthor,
    };

_CommentPageModel _$CommentPageModelFromJson(Map<String, dynamic> json) =>
    _CommentPageModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CommentModel>[],
      nextCursor: json['nextCursor'] as String?,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CommentPageModelToJson(_CommentPageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
      'total': instance.total,
    };

_CommentRepliesPageModel _$CommentRepliesPageModelFromJson(
  Map<String, dynamic> json,
) => _CommentRepliesPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CommentModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$CommentRepliesPageModelToJson(
  _CommentRepliesPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};

_CommentLikeModel _$CommentLikeModelFromJson(Map<String, dynamic> json) =>
    _CommentLikeModel(
      likeCount: (json['likeCount'] as num).toInt(),
      liked: json['liked'] as bool,
    );

Map<String, dynamic> _$CommentLikeModelToJson(_CommentLikeModel instance) =>
    <String, dynamic>{'likeCount': instance.likeCount, 'liked': instance.liked};

_MentionCandidateModel _$MentionCandidateModelFromJson(
  Map<String, dynamic> json,
) => _MentionCandidateModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$MentionCandidateModelToJson(
  _MentionCandidateModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'username': instance.username,
  'avatarUrl': ?instance.avatarUrl,
  'isVerified': instance.isVerified,
};
