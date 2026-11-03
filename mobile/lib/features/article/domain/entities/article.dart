import 'package:equatable/equatable.dart';

import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../media/domain/entities/media.dart';

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
    this.isReviewed = false,
    this.isAiAssisted = false,
    this.versionBadge,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.attachments,
  });

  final String id;
  final String slug;

  /// Language actually served: `ar-EG` or `en`.
  final String language;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final FieldRef field;
  final Author author;
  final int readingTimeMinutes;
  final bool isReviewed;
  final bool isAiAssisted;

  /// e.g. `.NET 10`.
  final String? versionBadge;
  final DateTime publishedAt;
  final int reactionCount;
  final int commentCount;

  /// 1–10 images or one PDF (F26); null when the post has none. Feed cards
  /// carry at most the first 10 PDF pages.
  final ArticleAttachments? attachments;

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
        isReviewed,
        isAiAssisted,
        versionBadge,
        publishedAt,
        reactionCount,
        commentCount,
        attachments,
      ];
}

class ArticleSource extends Equatable {
  const ArticleSource({required this.title, required this.url});

  final String title;
  final String url;

  @override
  List<Object?> get props => [title, url];
}

class ReviewerRef extends Equatable {
  const ReviewerRef({required this.displayName, required this.username});

  final String displayName;
  final String username;

  @override
  List<Object?> get props => [displayName, username];
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
    this.reviewedBy,
    this.lastReviewedAt,
    this.saveCount = 0,
    this.readCount = 0,
  });

  final ArticleCard card;
  final List<String> availableLanguages;

  /// Plain-text TL;DR (shown only when the RDoc has no `summary` block).
  final String? summary;
  final RDocDocument content;
  final FieldRef? topic;
  final List<String> tags;
  final List<ArticleSource> sources;
  final ReviewerRef? reviewedBy;
  final DateTime? lastReviewedAt;
  final int saveCount;
  final int readCount;

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
        reviewedBy,
        lastReviewedAt,
        saveCount,
        readCount,
      ];
}
