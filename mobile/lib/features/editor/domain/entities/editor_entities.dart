import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../article/domain/entities/article.dart';
import '../../../media/domain/entities/media.dart';

/// Article languages (SPEC §14.1): every article has a source version and at most one translation.
abstract final class ArticleLanguages {
  static const ar = 'ar-EG';
  static const en = 'en';
  static const all = [ar, en];

  static String normalize(String language) => language == en ? en : ar;

  static String other(String language) => language == en ? ar : en;
}

/// The F05 limits (docs: the F05 editor contract, "DTOs").
abstract final class DraftLimits {
  static const minTitle = 5;
  static const maxTitle = 150;
  static const maxSubtitle = 250;
  static const maxTags = 5;
  static const maxTagLength = 40;
  static const maxSources = 30;
  static const maxSourceTitle = 200;
  static const maxUrl = 2048;
  static const maxVersionBadge = 30;
  static const maxBlocks = 2000;

  /// RDoc image `alt` (rdoc.schema.json).
  static const maxImageAlt = 300;

  /// RDoc `plainText` attributes: captions, cites, callout and step titles.
  static const maxPlainText = 500;
}

/// `draft → published` (`archived` has no endpoint).
enum ArticleLifecycle { draft, published }

/// One language version of the article being written (`DraftTranslation`).
class DraftTranslation extends Equatable {
  const DraftTranslation({required this.language, required this.content, this.title = '', this.subtitle});

  /// `ar-EG` | `en`; [content] has the same language.
  final String language;

  /// May be empty in a draft; 5..150 characters to publish.
  final String title;

  /// ≤ 250 characters.
  final String? subtitle;
  final RDocDocument content;

  factory DraftTranslation.empty(String language) =>
      DraftTranslation(language: language, content: RDocDocument(version: 1, language: language, blocks: const []));

  DraftTranslation copyWith({String? title, String? Function()? subtitle, RDocDocument? content}) => DraftTranslation(
        language: language,
        title: title ?? this.title,
        subtitle: subtitle != null ? subtitle() : this.subtitle,
        content: content ?? this.content,
      );

  @override
  List<Object?> get props => [language, title, subtitle, content];
}

/// Everything the editor edits (`ArticleDraftDocument`); sent whole on every autosave.
class ArticleDraftDocument extends Equatable {
  const ArticleDraftDocument({
    required this.sourceLanguage,
    required this.translations,
    this.fieldId,
    this.topicId,
    this.tags = const [],
    this.sources = const [],
    this.coverUrl,
    this.versionBadge,
    this.isAiAssisted = false,
    this.attachments = const [],
  });

  /// The first version; always one of [translations].
  final String sourceLanguage;

  /// 1 or 2, distinct languages, the source first.
  final List<DraftTranslation> translations;

  /// Required to publish.
  final String? fieldId;

  /// Belongs to [fieldId].
  final String? topicId;

  /// ≤ 5 names; new names create tags on publish.
  final List<String> tags;
  final List<ArticleSource> sources;

  /// An absolute URL from `POST /uploads/images` (purpose `cover`).
  final String? coverUrl;

  /// e.g. `.NET 10`.
  final String? versionBadge;
  final bool isAiAssisted;

  /// 1–10 images or one PDF, or none (`DraftAttachment[]`, the same shape as the old attachment items).
  final List<AttachmentItem> attachments;

  factory ArticleDraftDocument.empty(String language) {
    final source = ArticleLanguages.normalize(language);
    return ArticleDraftDocument(sourceLanguage: source, translations: [DraftTranslation.empty(source)]);
  }

  DraftTranslation get source => translation(sourceLanguage) ?? translations.first;

  DraftTranslation? translation(String language) => translations.where((t) => t.language == language).firstOrNull;

  List<String> get languages => [for (final t in translations) t.language];

  bool get hasTranslation => translations.length > 1;

  /// The same document with [translation] replacing the version in its language.
  ArticleDraftDocument withTranslation(DraftTranslation translation) => copyWith(translations: [
        for (final t in translations) t.language == translation.language ? translation : t,
      ]);

  ArticleDraftDocument copyWith({
    String? sourceLanguage,
    List<DraftTranslation>? translations,
    String? Function()? fieldId,
    String? Function()? topicId,
    List<String>? tags,
    List<ArticleSource>? sources,
    String? Function()? coverUrl,
    String? Function()? versionBadge,
    bool? isAiAssisted,
    List<AttachmentItem>? attachments,
  }) =>
      ArticleDraftDocument(
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        translations: translations ?? this.translations,
        fieldId: fieldId != null ? fieldId() : this.fieldId,
        topicId: topicId != null ? topicId() : this.topicId,
        tags: tags ?? this.tags,
        sources: sources ?? this.sources,
        coverUrl: coverUrl != null ? coverUrl() : this.coverUrl,
        versionBadge: versionBadge != null ? versionBadge() : this.versionBadge,
        isAiAssisted: isAiAssisted ?? this.isAiAssisted,
        attachments: attachments ?? this.attachments,
      );

  @override
  List<Object?> get props =>
      [sourceLanguage, translations, fieldId, topicId, tags, sources, coverUrl, versionBadge, isAiAssisted, attachments];
}

/// The stable codes of `DraftProblemDto.code`.
abstract final class DraftProblemCodes {
  static const fieldRequired = FailureCodes.articleFieldRequired;
  static const titleLength = FailureCodes.articleTitleLength;
  static const contentEmpty = FailureCodes.articleContentEmpty;
  static const contentInvalid = FailureCodes.articleContentInvalid;
  static const imageAltRequired = FailureCodes.articleImageAltRequired;
  static const sourcesRequired = FailureCodes.articleSourcesRequired;
  static const attachmentAltRequired = FailureCodes.attachmentsAltTextRequired;
  static const attachmentTitleRequired = FailureCodes.attachmentsTitleRequired;
  static const attachmentNotReady = FailureCodes.attachmentsAssetNotReady;

  static const all = {
    fieldRequired,
    titleLength,
    contentEmpty,
    contentInvalid,
    imageAltRequired,
    sourcesRequired,
    attachmentAltRequired,
    attachmentTitleRequired,
    attachmentNotReady,
  };
}

/// Why the article can't be published yet (`DraftProblemDto`).
class DraftProblem extends Equatable {
  const DraftProblem(this.code, {this.language, this.blockId, this.mediaAssetId});

  final String code;

  /// For translation problems.
  final String? language;

  /// The RDoc block (an image without alt text).
  final String? blockId;

  /// Attachment problems.
  final String? mediaAssetId;

  @override
  List<Object?> get props => [code, language, blockId, mediaAssetId];
}

/// Reading time of one translation (SPEC §13.5).
class ReadingTime extends Equatable {
  const ReadingTime({required this.language, required this.minutes, this.words = 0});

  final String language;
  final int minutes;
  final int words;

  @override
  List<Object?> get props => [language, minutes, words];
}

/// `DraftChecksDto`: empty [problems] → can publish.
class DraftChecks extends Equatable {
  const DraftChecks({this.readingTime = const [], this.problems = const []});

  static const empty = DraftChecks();

  final List<ReadingTime> readingTime;
  final List<DraftProblem> problems;

  ReadingTime? readingTimeOf(String language) => readingTime.where((r) => r.language == language).firstOrNull;

  @override
  List<Object?> get props => [readingTime, problems];
}

/// The editor's copy of an article (`ArticleEditDto`, owner only).
class ArticleEdit extends Equatable {
  const ArticleEdit({
    required this.id,
    required this.status,
    required this.version,
    required this.savedAt,
    required this.document,
    this.slug,
    this.publishedAt,
    this.hasUnpublishedChanges = false,
    this.media = const [],
    this.checks = DraftChecks.empty,
  });

  final String id;
  final ArticleLifecycle status;

  /// Null until the first publish; never changes afterwards.
  final String? slug;
  final DateTime? publishedAt;

  /// The working copy's version: sent back as `baseVersion`.
  final int version;
  final DateTime savedAt;

  /// Published articles: the working copy differs from what readers see.
  final bool hasUnpublishedChanges;
  final ArticleDraftDocument document;

  /// The attachments' assets (the cover and image blocks are plain URLs).
  final List<MediaAsset> media;
  final DraftChecks checks;

  bool get isPublished => status == ArticleLifecycle.published;

  @override
  List<Object?> get props => [id, status, slug, publishedAt, version, savedAt, hasUnpublishedChanges, document, media, checks];
}

/// `PublishedArticleDto`.
class PublishedArticle extends Equatable {
  const PublishedArticle({
    required this.id,
    required this.slug,
    required this.publishedAt,
    required this.revision,
    required this.firstPublish,
  });

  final String id;
  final String slug;
  final DateTime publishedAt;
  final int revision;
  final bool firstPublish;

  @override
  List<Object?> get props => [id, slug, publishedAt, revision, firstPublish];
}

/// One publish or update (`ArticleRevisionDto`), newest first.
class ArticleRevision extends Equatable {
  const ArticleRevision({required this.number, required this.createdAt, required this.title, this.languages = const []});

  /// 1 = the first publish.
  final int number;
  final DateTime createdAt;

  /// The source-language title at that time.
  final String title;
  final List<String> languages;

  @override
  List<Object?> get props => [number, createdAt, title, languages];
}

/// `ArticleRevisionDetailsDto`: a revision with its document, for the preview.
class ArticleRevisionDetails extends Equatable {
  const ArticleRevisionDetails({required this.revision, required this.document, this.media = const []});

  final ArticleRevision revision;
  final ArticleDraftDocument document;

  /// The attachments' assets.
  final List<MediaAsset> media;

  @override
  List<Object?> get props => [revision, document, media];
}

/// A row of "My articles" (`MyArticleDto`).
class MyArticle extends Equatable {
  const MyArticle({
    required this.id,
    required this.status,
    required this.language,
    required this.title,
    required this.savedAt,
    this.slug,
    this.coverUrl,
    this.field,
    this.readingTimeMinutes = 0,
    this.publishedAt,
    this.hasUnpublishedChanges = false,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.readCount = 0,
  });

  final String id;
  final ArticleLifecycle status;
  final String? slug;

  /// The source language.
  final String language;

  /// The source-language title; empty → "Untitled".
  final String title;
  final String? coverUrl;
  final FieldRef? field;
  final int readingTimeMinutes;

  /// The last edit.
  final DateTime savedAt;
  final DateTime? publishedAt;
  final bool hasUnpublishedChanges;
  final int reactionCount;
  final int commentCount;
  final int readCount;

  bool get isPublished => status == ArticleLifecycle.published;

  @override
  List<Object?> get props => [
        id,
        status,
        slug,
        language,
        title,
        coverUrl,
        field,
        readingTimeMinutes,
        savedAt,
        publishedAt,
        hasUnpublishedChanges,
        reactionCount,
        commentCount,
        readCount,
      ];
}

/// `TagDto`: a tag suggestion.
class ArticleTag extends Equatable {
  const ArticleTag({required this.slug, required this.name, this.articleCount = 0});

  final String slug;
  final String name;
  final int articleCount;

  @override
  List<Object?> get props => [slug, name, articleCount];
}

/// A publish refused with `400`: the first problem's code, and all of them (the ProblemDetails `problems` member).
class DraftProblemsFailure extends Failure {
  const DraftProblemsFailure(super.code, {required this.problems, super.statusCode, super.message});

  final List<DraftProblem> problems;

  @override
  List<Object?> get props => [...super.props, problems];
}
