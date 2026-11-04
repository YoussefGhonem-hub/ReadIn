import 'package:equatable/equatable.dart';

import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../media/domain/entities/media.dart';
import 'reaction_counts.dart';

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
  const FieldRef({required this.id, required this.slug, required this.nameAr, required this.nameEn});

  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [id, slug, nameAr, nameEn];
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
  });

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
      ];
}

class ArticleSource extends Equatable {
  const ArticleSource({required this.title, required this.url});

  final String title;
  final String url;

  @override
  List<Object?> get props => [title, url];
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
    this.isOfflineCopy = false,
  });

  final ArticleCard card;
  final List<String> availableLanguages;

  /// Plain-text TL;DR (shown only when the RDoc has no `summary` block).
  final String? summary;
  final RDocDocument content;
  final FieldRef? topic;
  final List<String> tags;
  final List<ArticleSource> sources;
  final int readCount;

  /// The viewer follows the author (F12); false for guests and on your own articles.
  final bool isFollowingAuthor;

  /// The viewer's collections that hold this article, oldest addition first (F13); empty for guests and for
  /// articles that aren't saved.
  final List<String> collectionIds;

  /// Served from the copy kept on this device for a saved article, because the API was unreachable (F13, F25).
  final bool isOfflineCopy;

  /// `saveCount` moved up to the card in wave 1 (still on `ArticleDetailsDto` through inheritance).
  int get saveCount => card.saveCount;

  bool get hasBothLanguages => availableLanguages.contains('ar-EG') && availableLanguages.contains('en');

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
        isOfflineCopy,
      ];
}
