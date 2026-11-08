import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../categories/data/models/category_models.dart';
import '../../../media/data/models/media_models.dart';
import '../../../tags/data/models/tag_models.dart';
import '../../domain/entities/article.dart';

part 'article_models.freezed.dart';
part 'article_models.g.dart';

@freezed
abstract class AuthorModel with _$AuthorModel {
  const AuthorModel._();

  const factory AuthorModel({
    required String id,
    required String displayName,
    required String username,
    String? avatarUrl,
    @Default(false) bool isVerified,
    // F14: the writer's title; blank is treated as none.
    String? headline,
  }) = _AuthorModel;

  factory AuthorModel.fromJson(Map<String, dynamic> json) => _$AuthorModelFromJson(json);

  Author toEntity() => Author(
        id: id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        isVerified: isVerified,
        headline: headline == null || headline!.trim().isEmpty ? null : headline!.trim(),
      );
}

/// `RepostLabelDto` (F29): `{ user, othersCount, repostedAt, caption }`.
@freezed
abstract class RepostLabelModel with _$RepostLabelModel {
  const RepostLabelModel._();

  const factory RepostLabelModel({
    required AuthorModel user,
    @Default(0) int othersCount,
    required DateTime repostedAt,
    // `user`'s thoughts on it; missing, null or blank is none.
    String? caption,
    // F22 store additions: the repost (a report target) and whether the viewer reported it.
    String? repostId,
    @Default(false) bool reportedByMe,
  }) = _RepostLabelModel;

  factory RepostLabelModel.fromJson(Map<String, dynamic> json) => _$RepostLabelModelFromJson(json);

  RepostLabel toEntity() => RepostLabel(
        user: user.toEntity(),
        othersCount: math.max(0, othersCount),
        repostedAt: repostedAt,
        caption: caption == null || caption!.trim().isEmpty ? null : caption,
        repostId: repostId,
        reportedByMe: reportedByMe,
      );
}

@freezed
abstract class FieldRefModel with _$FieldRefModel {
  const FieldRefModel._();

  const factory FieldRefModel({
    required String id,
    required String slug,
    required String nameAr,
    required String nameEn,
    String? name,
    @Default(false) bool isSensitive,
  }) = _FieldRefModel;

  factory FieldRefModel.fromJson(Map<String, dynamic> json) => _$FieldRefModelFromJson(json);

  FieldRef toEntity() => FieldRef(id: id, slug: slug, nameAr: nameAr, nameEn: nameEn, isSensitive: isSensitive);
}

/// `ReactionCountsDto` (F10).
@freezed
abstract class ReactionCountsModel with _$ReactionCountsModel {
  const ReactionCountsModel._();

  const factory ReactionCountsModel({
    @Default(0) int insightful,
    @Default(0) int love,
    @Default(0) int fire,
    @Default(0) int mindBlown,
  }) = _ReactionCountsModel;

  factory ReactionCountsModel.fromJson(Map<String, dynamic> json) => _$ReactionCountsModelFromJson(json);

  ReactionCounts toEntity() => ReactionCounts(insightful: insightful, love: love, fire: fire, mindBlown: mindBlown);
}

/// `ArticleCardDto`. The wave 1 fields (`reactions`, `saveCount`, `myReaction`, `isSaved`) and the post card's
/// (`excerpt`, `hasMore`, `isFollowingAuthor`, `tags`, `tagCount`, F34) have defaults, so an API that doesn't send them
/// yet still parses. `author` is null when the author deleted their account (SPEC §9.6). `tags` are `TagRefDto`s
/// (F32); names alone, as before F32, still parse as tags without a page.
@freezed
abstract class ArticleCardModel with _$ArticleCardModel {
  const ArticleCardModel._();

  const factory ArticleCardModel({
    required String id,
    required String slug,
    required String language,
    required String title,
    String? subtitle,
    String? coverUrl,
    required FieldRefModel field,
    required AuthorModel? author,
    @Default(1) int readingTimeMinutes,
    @Default(false) bool isAiAssisted,
    String? versionBadge,
    required DateTime publishedAt,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,
    ArticleAttachmentsModel? attachments,
    ReactionCountsModel? reactions,
    @Default(0) int saveCount,
    String? myReaction,
    @Default(false) bool isSaved,
    String? excerpt,
    @Default(false) bool hasMore,
    @Default(false) bool isFollowingAuthor,
    @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) @Default(<TagRefModel>[]) List<TagRefModel> tags,
    @Default(0) int tagCount,
    // F28: the card's topic and the viewer's mutes.
    FieldRefModel? topic,
    @Default(false) bool isAuthorMuted,
    @Default(false) bool isFieldMuted,
    @Default(false) bool isTopicMuted,
    // F29: reposts, and the label on Following-feed cards a repost placed and on a profile's Reposts tab.
    @Default(0) int repostCount,
    @Default(false) bool isReposted,
    RepostLabelModel? repostedBy,
    // F22 store additions: the viewer reported it (collapsed for them).
    @Default(false) bool reportedByMe,
  }) = _ArticleCardModel;

  factory ArticleCardModel.fromJson(Map<String, dynamic> json) => _$ArticleCardModelFromJson(json);

  ArticleCard toEntity() => ArticleCard(
        id: id,
        slug: slug,
        language: language,
        title: title,
        subtitle: subtitle,
        coverUrl: coverUrl,
        field: field.toEntity(),
        author: author?.toEntity(),
        readingTimeMinutes: readingTimeMinutes,
        isAiAssisted: isAiAssisted,
        versionBadge: versionBadge,
        publishedAt: publishedAt,
        reactionCount: reactions?.toEntity().total ?? reactionCount,
        commentCount: commentCount,
        attachments: attachments?.toEntity(),
        reactions: reactions?.toEntity() ?? ReactionCounts.zero,
        saveCount: saveCount,
        myReaction: reactionTypeFromWire(myReaction),
        isSaved: isSaved,
        excerpt: excerpt == null || excerpt!.trim().isEmpty ? null : excerpt,
        hasMore: hasMore,
        isFollowingAuthor: isFollowingAuthor,
        tags: [for (final t in tags.take(ArticleCard.maxCardTags)) t.toEntity()],
        tagCount: math.max(tagCount, tags.length),
        topic: topic?.toEntity(),
        isAuthorMuted: isAuthorMuted,
        isFieldMuted: isFieldMuted,
        isTopicMuted: isTopicMuted,
        repostCount: math.max(0, repostCount),
        isReposted: isReposted,
        repostedBy: repostedBy?.toEntity(),
        reportedByMe: reportedByMe,
      );
}

/// `ArticlePreviewDto` (F34): `content` stays raw JSON here and is parsed into [RDocDocument] for the entity.
@freezed
abstract class ArticlePreviewModel with _$ArticlePreviewModel {
  const ArticlePreviewModel._();

  const factory ArticlePreviewModel({
    required String id,
    required String language,
    @Default(<String, dynamic>{}) Map<String, dynamic> content,
    @Default(false) bool isComplete,
  }) = _ArticlePreviewModel;

  factory ArticlePreviewModel.fromJson(Map<String, dynamic> json) => _$ArticlePreviewModelFromJson(json);

  ArticlePreview toEntity() => ArticlePreview(
        id: id,
        language: language,
        content: content.isEmpty ? RDocDocument.empty : RDocDocument.fromJson(content),
        isComplete: isComplete,
      );
}

/// `CursorPage<ArticleCardDto>`.
@freezed
abstract class ArticleCardPageModel with _$ArticleCardPageModel {
  const factory ArticleCardPageModel({
    @Default(<ArticleCardModel>[]) List<ArticleCardModel> items,
    String? nextCursor,
  }) = _ArticleCardPageModel;

  factory ArticleCardPageModel.fromJson(Map<String, dynamic> json) => _$ArticleCardPageModelFromJson(json);
}

@freezed
abstract class SourceModel with _$SourceModel {
  const factory SourceModel({required String title, required String url}) = _SourceModel;

  factory SourceModel.fromJson(Map<String, dynamic> json) => _$SourceModelFromJson(json);
}

/// `MyProgressDto`: the viewer's reading progress, for the reader's resume (F04).
@freezed
abstract class MyProgressModel with _$MyProgressModel {
  const MyProgressModel._();

  const factory MyProgressModel({
    required String language,
    @Default(0) int percent,
    String? lastPosition,
    DateTime? completedAt,
  }) = _MyProgressModel;

  factory MyProgressModel.fromJson(Map<String, dynamic> json) => _$MyProgressModelFromJson(json);

  MyProgress toEntity() =>
      MyProgress(language: language, percent: percent, lastPosition: lastPosition, completedAt: completedAt);
}

/// `ArticleDetailsDto.moderation` (F22): `{ hiddenAt, note }` while moderators keep the article hidden.
@freezed
abstract class ArticleModerationModel with _$ArticleModerationModel {
  const ArticleModerationModel._();

  const factory ArticleModerationModel({required DateTime hiddenAt, String? note}) = _ArticleModerationModel;

  factory ArticleModerationModel.fromJson(Map<String, dynamic> json) => _$ArticleModerationModelFromJson(json);

  ArticleModeration toEntity() => ArticleModeration(hiddenAt: hiddenAt, note: note);
}

/// `ArticleDetailsDto` — card fields plus reader-only fields. `content` stays
/// raw JSON here and is parsed into [RDocDocument] when mapping to the entity.
/// [toJson] is what the offline copy of a saved article keeps (F13, F25).
@freezed
abstract class ArticleDetailsModel with _$ArticleDetailsModel {
  const ArticleDetailsModel._();

  const factory ArticleDetailsModel({
    required String id,
    required String slug,
    required String language,
    required String title,
    String? subtitle,
    String? coverUrl,
    required FieldRefModel field,
    required AuthorModel? author,
    @Default(1) int readingTimeMinutes,
    @Default(false) bool isAiAssisted,
    String? versionBadge,
    required DateTime publishedAt,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,
    ArticleAttachmentsModel? attachments,
    ReactionCountsModel? reactions,
    String? myReaction,
    @Default(false) bool isSaved,
    @Default(<String>[]) List<String> availableLanguages,
    String? summary,
    @Default(<String, dynamic>{}) Map<String, dynamic> content,
    FieldRefModel? topic,
    @JsonKey(fromJson: tagRefsFromJson, toJson: tagRefsToJson) @Default(<TagRefModel>[]) List<TagRefModel> tags,
    @Default(<SourceModel>[]) List<SourceModel> sources,
    @Default(0) int saveCount,
    @Default(0) int readCount,
    @Default(false) bool isFollowingAuthor,
    @Default(<String>[]) List<String> collectionIds,
    MyProgressModel? myProgress,
    ArticleModerationModel? moderation,
    // F31: the writer's category of the article, { slug, name } or null.
    WriterCategoryRefModel? category,
    // F28: the viewer's mutes ("انت كاتم الكاتب ده" and the "كتم المواضيع" sheet).
    @Default(false) bool isAuthorMuted,
    @Default(false) bool isFieldMuted,
    @Default(false) bool isTopicMuted,
    // F29: the reader's Repost button.
    @Default(0) int repostCount,
    @Default(false) bool isReposted,
    // F23: featured on Explore (the "⋯" offers Feature / Unfeature with `articles.feature`).
    @Default(false) bool isFeatured,
    // F22 store additions and F36: the viewer reported it; people they're blocked with (mentions as plain text).
    @Default(false) bool reportedByMe,
    @Default(<String>[]) List<String> unlinkedMentionIds,
  }) = _ArticleDetailsModel;

  factory ArticleDetailsModel.fromJson(Map<String, dynamic> json) => _$ArticleDetailsModelFromJson(json);

  ArticleCard toCard() => ArticleCard(
        id: id,
        slug: slug,
        language: language,
        title: title,
        subtitle: subtitle,
        coverUrl: coverUrl,
        field: field.toEntity(),
        author: author?.toEntity(),
        readingTimeMinutes: readingTimeMinutes,
        isAiAssisted: isAiAssisted,
        versionBadge: versionBadge,
        publishedAt: publishedAt,
        reactionCount: reactions?.toEntity().total ?? reactionCount,
        commentCount: commentCount,
        attachments: attachments?.toEntity(),
        reactions: reactions?.toEntity() ?? ReactionCounts.zero,
        saveCount: saveCount,
        myReaction: reactionTypeFromWire(myReaction),
        isSaved: isSaved,
        isFollowingAuthor: isFollowingAuthor,
        tags: [for (final t in tags.take(ArticleCard.maxCardTags)) t.toEntity()],
        tagCount: tags.length,
        topic: topic?.toEntity(),
        isAuthorMuted: isAuthorMuted,
        isFieldMuted: isFieldMuted,
        isTopicMuted: isTopicMuted,
        repostCount: math.max(0, repostCount),
        isReposted: isReposted,
        reportedByMe: reportedByMe,
      );

  ArticleDetails toEntity({bool offline = false}) => ArticleDetails(
        card: toCard(),
        availableLanguages: availableLanguages.isEmpty ? [language] : availableLanguages,
        summary: summary,
        content: content.isEmpty ? RDocDocument.empty : RDocDocument.fromJson(content),
        topic: topic?.toEntity(),
        tags: [for (final t in tags) t.toEntity()],
        sources: [for (final s in sources) ArticleSource(title: s.title, url: s.url)],
        readCount: readCount,
        isFollowingAuthor: isFollowingAuthor,
        collectionIds: collectionIds,
        myProgress: myProgress?.toEntity(),
        isOfflineCopy: offline,
        moderation: moderation?.toEntity(),
        category: category?.toEntity(),
        isFeatured: isFeatured,
        unlinkedMentionIds: unlinkedMentionIds,
      );
}
