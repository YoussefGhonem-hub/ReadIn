import 'package:equatable/equatable.dart';

import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../categories/domain/entities/writer_category.dart';
import '../../../media/domain/entities/media.dart';
import '../../../tags/domain/entities/tag.dart';
import 'reaction_counts.dart';

export '../../../categories/domain/entities/writer_category.dart' show WriterCategoryRef;
export '../../../tags/domain/entities/tag.dart' show TagRef;
export 'reaction_counts.dart';

class Author extends Equatable {
  const Author({required this.id, required this.displayName, required this.username, this.avatarUrl, this.isVerified = false});

  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isVerified;

  @override
  List<Object?> get props => [id, displayName, username, avatarUrl, isVerified];
}

class FieldRef extends Equatable {
  const FieldRef({required this.id, required this.slug, required this.nameAr, required this.nameEn, this.isSensitive = false});

  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;

  /// Health content (medicine, public health): the reader shows the health disclaimer (SPEC F04).
  final bool isSensitive;

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [id, slug, nameAr, nameEn, isSensitive];
}

/// Feed card (`ArticleCardDto`).
class ArticleCard extends Equatable {
  const ArticleCard({
    required this.id,
    required this.slug,
    required this.language,
    required this.title,
    required this.field,
    required this.author,
    required this.readingTimeMinutes,
    required this.publishedAt,
    this.subtitle,
    this.coverUrl,
    this.isAiAssisted = false,
    this.versionBadge,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.attachments,
    this.reactions = ReactionCounts.zero,
    this.saveCount = 0,
    this.myReaction,
    this.isSaved = false,
    this.excerpt,
    this.hasMore = false,
    this.isFollowingAuthor = false,
    this.tags = const [],
    this.tagCount = 0,
  });

  /// The post card shows this many tags, then "+N" (F34).
  static const maxCardTags = 3;

  final String id;
  final String slug;

  /// Language actually served: `ar-EG` or `en`.
  final String language;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final FieldRef field;

  /// Null once the author deleted their account: the article stays up under "Deleted user", with no name, handle,
  /// photo or profile (SPEC §9.6).
  final Author? author;
  final int readingTimeMinutes;
  final bool isAiAssisted;

  /// e.g. `.NET 10`.
  final String? versionBadge;
  final DateTime publishedAt;
  /// Sum of [reactions], kept as its own field: an API without per-type counts still sends it.
  final int reactionCount;
  final int commentCount;

  /// 1–10 images or one PDF (F26); null when the post has none. Feed cards
  /// carry at most the first 10 PDF pages.
  final ArticleAttachments? attachments;

  /// Per-type counts (F10); all zero when the API doesn't send them.
  final ReactionCounts reactions;
  final int saveCount;

  /// The viewer's reaction; null for guests and when they haven't reacted.
  final ReactionType? myReaction;

  /// The viewer saved this article (F13); false for guests.
  final bool isSaved;

  /// The beginning of the served version as plain text, at most 400 characters cut at a word (F34). Null only for an
  /// article the server hasn't computed it for yet: the post card then shows the title alone.
  final String? excerpt;

  /// The article has more than [excerpt] shows: cut text, later blocks, or blocks the excerpt skips (F34).
  final bool hasMore;

  /// The viewer follows the author (F12); false for guests, their own articles and a deleted author.
  final bool isFollowingAuthor;

  /// At most [maxCardTags] tags, in the article's order (F34); each opens its tag page (F32).
  final List<TagRef> tags;

  /// All the article's tags (at most 5), for "+N".
  final int tagCount;

  /// "Read more" applies however short the excerpt is: the article goes on after it, or it has no excerpt yet.
  bool get continuesAfterExcerpt => excerpt == null || hasMore;

  /// The same card with newer counters or viewer state (optimistic actions, live counters F27).
  ArticleCard copyWithEngagement({
    ReactionCounts? reactions,
    int? reactionCount,
    int? commentCount,
    int? saveCount,
    ReactionType? Function()? myReaction,
    bool? isSaved,
  }) =>
      ArticleCard(
        id: id,
        slug: slug,
        language: language,
        title: title,
        field: field,
        author: author,
        readingTimeMinutes: readingTimeMinutes,
        publishedAt: publishedAt,
        subtitle: subtitle,
        coverUrl: coverUrl,
        isAiAssisted: isAiAssisted,
        versionBadge: versionBadge,
        reactionCount: reactionCount ?? this.reactionCount,
        commentCount: commentCount ?? this.commentCount,
        attachments: attachments,
        reactions: reactions ?? this.reactions,
        saveCount: saveCount ?? this.saveCount,
        myReaction: myReaction != null ? myReaction() : this.myReaction,
        isSaved: isSaved ?? this.isSaved,
        excerpt: excerpt,
        hasMore: hasMore,
        isFollowingAuthor: isFollowingAuthor,
        tags: tags,
        tagCount: tagCount,
      );

  @override
  List<Object?> get props => [
        id,
        slug,
        language,
        title,
        subtitle,
        coverUrl,
        field,
        author,
        readingTimeMinutes,
        isAiAssisted,
        versionBadge,
        publishedAt,
        reactionCount,
        commentCount,
        attachments,
        reactions,
        saveCount,
        myReaction,
        isSaved,
        excerpt,
        hasMore,
        isFollowingAuthor,
        tags,
        tagCount,
      ];
}

/// `ArticlePreviewDto` (F34): the beginning of an article as RDoc, for "Read more" on a post card.
class ArticlePreview extends Equatable {
  const ArticlePreview({required this.id, required this.language, required this.content, required this.isComplete});

  final String id;

  /// The version served: the one asked for, else the source language.
  final String language;

  /// The article's first blocks, in order, until about 300 words: never a cut block, at least one.
  final RDocDocument content;

  /// [content] is the whole article.
  final bool isComplete;

  @override
  List<Object?> get props => [id, language, content, isComplete];
}

class ArticleSource extends Equatable {
  const ArticleSource({required this.title, required this.url});

  final String title;
  final String url;

  @override
  List<Object?> get props => [title, url];
}

/// The viewer's reading progress on an article (`MyProgressDto`, F04 resume).
class MyProgress extends Equatable {
  const MyProgress({required this.language, this.percent = 0, this.lastPosition, this.completedAt});

  /// The reader scrolls back only to a position inside this range (docs/api/contract-v1.md "Resume (F04)").
  static const minResume = 0.05;
  static const maxResume = 0.95;

  /// The version the progress was recorded on: `ar-EG` or `en`.
  final String language;

  /// Highest percent reached, 0–100.
  final int percent;

  /// The scroll position as the reader sent it: a fraction of the scrollable range with four decimals (`"0.4523"`).
  final String? lastPosition;

  /// Set once the article counts as read.
  final DateTime? completedAt;

  /// Where the reader showing [shownLanguage] scrolls back to on open: [lastPosition] when the article isn't read
  /// yet, the progress was recorded on that version and the position is between [minResume] and [maxResume];
  /// otherwise null. The reader also checks that the link has no block anchor and the user hasn't scrolled yet.
  double? resumeFractionFor(String shownLanguage) {
    if (completedAt != null || language != shownLanguage) return null;
    final value = double.tryParse(lastPosition ?? '');
    if (value == null || value.isNaN || value < minResume || value > maxResume) return null;
    return value;
  }

  @override
  List<Object?> get props => [language, percent, lastPosition, completedAt];
}

/// `ArticleDetailsDto.moderation` (F22): set only while the article is hidden by moderators. Only its author and
/// moderators can open it then, and the reader says so.
class ArticleModeration extends Equatable {
  const ArticleModeration({required this.hiddenAt, this.note});

  final DateTime hiddenAt;

  /// The moderator's note, if any.
  final String? note;

  @override
  List<Object?> get props => [hiddenAt, note];
}

/// Reader payload (`ArticleDetailsDto`).
class ArticleDetails extends Equatable {
  const ArticleDetails({
    required this.card,
    required this.availableLanguages,
    required this.content,
    this.summary,
    this.topic,
    this.tags = const [],
    this.sources = const [],
    this.readCount = 0,
    this.isFollowingAuthor = false,
    this.collectionIds = const [],
    this.myProgress,
    this.isOfflineCopy = false,
    this.moderation,
    this.category,
  });

  final ArticleCard card;
  final List<String> availableLanguages;

  /// Plain-text TL;DR (shown only when the RDoc has no `summary` block).
  final String? summary;
  final RDocDocument content;
  final FieldRef? topic;

  /// All the article's tags (at most 5), in the writer's order (F32).
  final List<TagRef> tags;
  final List<ArticleSource> sources;
  final int readCount;

  /// The viewer follows the author (F12); false for guests and on your own articles.
  final bool isFollowingAuthor;

  /// The viewer's collections that hold this article, oldest addition first (F13); empty for guests and for
  /// articles that aren't saved.
  final List<String> collectionIds;

  /// The viewer's reading progress (F04 resume); null for guests and articles they haven't opened.
  final MyProgress? myProgress;

  /// Served from the copy kept on this device for a saved article, because the API was unreachable (F13, F25).
  final bool isOfflineCopy;

  /// Hidden by moderators (F22); null while the article is visible.
  final ArticleModeration? moderation;

  /// The writer's category of the article (F31): the author row's "في قسم {name}" link. Null for none.
  final WriterCategoryRef? category;

  /// `saveCount` moved up to the card in wave 1 (still on `ArticleDetailsDto` through inheritance).
  int get saveCount => card.saveCount;

  bool get hasBothLanguages => availableLanguages.contains('ar-EG') && availableLanguages.contains('en');

  /// Where the reader scrolls back to when it opens this version ([MyProgress.resumeFractionFor]).
  double? get resumeFraction => myProgress?.resumeFractionFor(card.language);

  bool get isHidden => moderation != null;

  /// The same article, hidden ([moderation]) or visible again (null), after a moderator's action.
  ArticleDetails withModeration(ArticleModeration? moderation) => ArticleDetails(
        card: card,
        availableLanguages: availableLanguages,
        content: content,
        summary: summary,
        topic: topic,
        tags: tags,
        sources: sources,
        readCount: readCount,
        isFollowingAuthor: isFollowingAuthor,
        collectionIds: collectionIds,
        isOfflineCopy: isOfflineCopy,
        myProgress: myProgress,
        moderation: moderation,
        category: category,
      );

  @override
  List<Object?> get props => [
        card,
        availableLanguages,
        summary,
        content,
        topic,
        tags,
        sources,
        readCount,
        isFollowingAuthor,
        collectionIds,
        myProgress,
        isOfflineCopy,
        moderation,
        category,
      ];
}
