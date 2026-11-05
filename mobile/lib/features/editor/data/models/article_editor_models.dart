import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/rdoc/editing/rdoc_codec.dart';
import '../../../article/data/models/article_models.dart';
import '../../../article/domain/entities/article.dart';
import '../../../media/data/models/media_models.dart';
import '../../../media/domain/entities/media.dart';
import '../../domain/entities/editor_entities.dart';

part 'article_editor_models.freezed.dart';
part 'article_editor_models.g.dart';

DateTime _epoch() => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

ArticleLifecycle _lifecycle(String status) => status == 'published' ? ArticleLifecycle.published : ArticleLifecycle.draft;

/// `DraftTranslation`. Nulls are sent: every autosave replaces the whole working copy.
@freezed
abstract class DraftTranslationModel with _$DraftTranslationModel {
  const DraftTranslationModel._();

  const factory DraftTranslationModel({
    required String language,
    @Default('') String title,
    @JsonKey(includeIfNull: true) String? subtitle,
    @Default(<String, dynamic>{}) Map<String, dynamic> content,
  }) = _DraftTranslationModel;

  factory DraftTranslationModel.fromJson(Map<String, dynamic> json) => _$DraftTranslationModelFromJson(json);

  factory DraftTranslationModel.fromEntity(DraftTranslation t) => DraftTranslationModel(
        language: t.language,
        title: t.title,
        subtitle: t.subtitle,
        // content.language always equals the translation's language.
        content: RDocCodec.encode(t.content, language: t.language),
      );

  DraftTranslation toEntity() => DraftTranslation(
        language: language,
        title: title,
        subtitle: subtitle,
        content: RDocCodec.decode(content, language: language),
      );
}

/// `ArticleDraftDocument`.
@freezed
abstract class ArticleDraftDocumentModel with _$ArticleDraftDocumentModel {
  const ArticleDraftDocumentModel._();

  const factory ArticleDraftDocumentModel({
    required String sourceLanguage,
    @Default(<DraftTranslationModel>[]) List<DraftTranslationModel> translations,
    @JsonKey(includeIfNull: true) String? fieldId,
    @JsonKey(includeIfNull: true) String? topicId,
    @Default(<String>[]) List<String> tags,
    @Default(<SourceModel>[]) List<SourceModel> sources,
    @JsonKey(includeIfNull: true) String? coverUrl,
    @JsonKey(includeIfNull: true) String? versionBadge,
    @Default(false) bool isAiAssisted,
    @Default(<AttachmentItemModel>[]) List<AttachmentItemModel> attachments,
  }) = _ArticleDraftDocumentModel;

  factory ArticleDraftDocumentModel.fromJson(Map<String, dynamic> json) => _$ArticleDraftDocumentModelFromJson(json);

  factory ArticleDraftDocumentModel.fromEntity(ArticleDraftDocument d) => ArticleDraftDocumentModel(
        sourceLanguage: d.sourceLanguage,
        translations: [for (final t in d.translations) DraftTranslationModel.fromEntity(t)],
        fieldId: d.fieldId,
        topicId: d.topicId,
        tags: d.tags,
        sources: [for (final s in d.sources) SourceModel(title: s.title, url: s.url)],
        coverUrl: d.coverUrl,
        versionBadge: d.versionBadge,
        isAiAssisted: d.isAiAssisted,
        attachments: SetAttachmentsRequestModel.fromEntities(d.attachments).items,
      );

  ArticleDraftDocument toEntity() {
    final versions = [for (final t in translations) t.toEntity()];
    final source = ArticleLanguages.normalize(sourceLanguage);
    return ArticleDraftDocument(
      sourceLanguage: source,
      // The source version first.
      translations: versions.isEmpty
          ? [DraftTranslation.empty(source)]
          : [...versions.where((t) => t.language == source), ...versions.where((t) => t.language != source)],
      fieldId: fieldId,
      topicId: topicId,
      tags: tags,
      sources: [for (final s in sources) ArticleSource(title: s.title, url: s.url)],
      coverUrl: coverUrl,
      versionBadge: versionBadge,
      isAiAssisted: isAiAssisted,
      attachments: [
        for (final a in [...attachments]..sort((a, b) => a.order.compareTo(b.order)))
          AttachmentItem(
            mediaAssetId: a.mediaAssetId,
            order: a.order,
            caption: a.caption,
            altText: a.altText,
            title: a.title,
            allowDownload: a.allowDownload,
          ),
      ],
    );
  }
}

/// `SaveDraftRequest`.
@freezed
abstract class SaveDraftRequestModel with _$SaveDraftRequestModel {
  const factory SaveDraftRequestModel({required int baseVersion, required ArticleDraftDocumentModel document}) =
      _SaveDraftRequestModel;

  factory SaveDraftRequestModel.fromJson(Map<String, dynamic> json) => _$SaveDraftRequestModelFromJson(json);
}

/// `{ baseVersion }` of publish and restore.
@freezed
abstract class BaseVersionRequestModel with _$BaseVersionRequestModel {
  const factory BaseVersionRequestModel({required int baseVersion}) = _BaseVersionRequestModel;

  factory BaseVersionRequestModel.fromJson(Map<String, dynamic> json) => _$BaseVersionRequestModelFromJson(json);
}

@freezed
abstract class ReadingTimeModel with _$ReadingTimeModel {
  const ReadingTimeModel._();

  const factory ReadingTimeModel({required String language, @Default(0) int minutes, @Default(0) int words}) =
      _ReadingTimeModel;

  factory ReadingTimeModel.fromJson(Map<String, dynamic> json) => _$ReadingTimeModelFromJson(json);

  ReadingTime toEntity() => ReadingTime(language: language, minutes: minutes, words: words);
}

/// `DraftProblemDto`; `tag` names the tag of a `tag.hidden` or `tag.limit` problem (F32).
@freezed
abstract class DraftProblemModel with _$DraftProblemModel {
  const DraftProblemModel._();

  const factory DraftProblemModel({
    required String code,
    String? language,
    String? blockId,
    String? mediaAssetId,
    String? tag,
  }) = _DraftProblemModel;

  factory DraftProblemModel.fromJson(Map<String, dynamic> json) => _$DraftProblemModelFromJson(json);

  DraftProblem toEntity() =>
      DraftProblem(code, language: language, blockId: blockId, mediaAssetId: mediaAssetId, tag: tag);
}

/// `DraftChecksDto`.
@freezed
abstract class DraftChecksModel with _$DraftChecksModel {
  const DraftChecksModel._();

  const factory DraftChecksModel({
    @Default(<ReadingTimeModel>[]) List<ReadingTimeModel> readingTime,
    @Default(<DraftProblemModel>[]) List<DraftProblemModel> problems,
  }) = _DraftChecksModel;

  factory DraftChecksModel.fromJson(Map<String, dynamic> json) => _$DraftChecksModelFromJson(json);

  DraftChecks toEntity() => DraftChecks(
        readingTime: [for (final r in readingTime) r.toEntity()],
        problems: [for (final p in problems) p.toEntity()],
      );
}

/// `ArticleEditDto`.
@freezed
abstract class ArticleEditModel with _$ArticleEditModel {
  const ArticleEditModel._();

  const factory ArticleEditModel({
    required String id,
    @Default('draft') String status,
    String? slug,
    DateTime? publishedAt,
    @Default(1) int version,
    DateTime? savedAt,
    @Default(false) bool hasUnpublishedChanges,
    required ArticleDraftDocumentModel document,
    @Default(<MediaAssetModel>[]) List<MediaAssetModel> media,
    @Default(DraftChecksModel()) DraftChecksModel checks,
    // F31: the writer's category, not part of the document (`PUT /articles/{id}/category`).
    String? categoryId,
  }) = _ArticleEditModel;

  factory ArticleEditModel.fromJson(Map<String, dynamic> json) => _$ArticleEditModelFromJson(json);

  ArticleEdit toEntity() => ArticleEdit(
        id: id,
        status: _lifecycle(status),
        slug: slug,
        publishedAt: publishedAt,
        version: version,
        savedAt: savedAt ?? publishedAt ?? _epoch(),
        hasUnpublishedChanges: hasUnpublishedChanges,
        document: document.toEntity(),
        media: [for (final m in media) m.toEntity()],
        checks: checks.toEntity(),
        categoryId: categoryId,
      );
}

/// `PublishedArticleDto`.
@freezed
abstract class PublishedArticleModel with _$PublishedArticleModel {
  const PublishedArticleModel._();

  const factory PublishedArticleModel({
    required String id,
    required String slug,
    required DateTime publishedAt,
    @Default(1) int revision,
    @Default(false) bool firstPublish,
  }) = _PublishedArticleModel;

  factory PublishedArticleModel.fromJson(Map<String, dynamic> json) => _$PublishedArticleModelFromJson(json);

  PublishedArticle toEntity() =>
      PublishedArticle(id: id, slug: slug, publishedAt: publishedAt, revision: revision, firstPublish: firstPublish);
}

/// `ArticleRevisionDto`.
@freezed
abstract class ArticleRevisionModel with _$ArticleRevisionModel {
  const ArticleRevisionModel._();

  const factory ArticleRevisionModel({
    required int number,
    required DateTime createdAt,
    @Default('') String title,
    @Default(<String>[]) List<String> languages,
  }) = _ArticleRevisionModel;

  factory ArticleRevisionModel.fromJson(Map<String, dynamic> json) => _$ArticleRevisionModelFromJson(json);

  ArticleRevision toEntity() => ArticleRevision(number: number, createdAt: createdAt, title: title, languages: languages);
}

/// `ArticleRevisionDetailsDto`.
@freezed
abstract class ArticleRevisionDetailsModel with _$ArticleRevisionDetailsModel {
  const ArticleRevisionDetailsModel._();

  const factory ArticleRevisionDetailsModel({
    required int number,
    required DateTime createdAt,
    @Default('') String title,
    @Default(<String>[]) List<String> languages,
    required ArticleDraftDocumentModel document,
    @Default(<MediaAssetModel>[]) List<MediaAssetModel> media,
  }) = _ArticleRevisionDetailsModel;

  factory ArticleRevisionDetailsModel.fromJson(Map<String, dynamic> json) => _$ArticleRevisionDetailsModelFromJson(json);

  ArticleRevisionDetails toEntity() => ArticleRevisionDetails(
        revision: ArticleRevision(number: number, createdAt: createdAt, title: title, languages: languages),
        document: document.toEntity(),
        media: [for (final m in media) m.toEntity()],
      );
}

/// `MyArticleDto`.
@freezed
abstract class MyArticleModel with _$MyArticleModel {
  const MyArticleModel._();

  const factory MyArticleModel({
    required String id,
    @Default('draft') String status,
    String? slug,
    @Default('ar-EG') String language,
    @Default('') String title,
    String? coverUrl,
    FieldRefModel? field,
    @Default(0) int readingTimeMinutes,
    DateTime? savedAt,
    DateTime? publishedAt,
    @Default(false) bool hasUnpublishedChanges,
    @Default(0) int reactionCount,
    @Default(0) int commentCount,
    @Default(0) int readCount,
  }) = _MyArticleModel;

  factory MyArticleModel.fromJson(Map<String, dynamic> json) => _$MyArticleModelFromJson(json);

  MyArticle toEntity() => MyArticle(
        id: id,
        status: _lifecycle(status),
        slug: slug,
        language: language,
        title: title,
        coverUrl: coverUrl,
        field: field?.toEntity(),
        readingTimeMinutes: readingTimeMinutes,
        savedAt: savedAt ?? publishedAt ?? _epoch(),
        publishedAt: publishedAt,
        hasUnpublishedChanges: hasUnpublishedChanges,
        reactionCount: reactionCount,
        commentCount: commentCount,
        readCount: readCount,
      );
}

/// `CursorPage<MyArticleDto>`.
@freezed
abstract class MyArticlePageModel with _$MyArticlePageModel {
  const factory MyArticlePageModel({
    @Default(<MyArticleModel>[]) List<MyArticleModel> items,
    String? nextCursor,
  }) = _MyArticlePageModel;

  factory MyArticlePageModel.fromJson(Map<String, dynamic> json) => _$MyArticlePageModelFromJson(json);
}
