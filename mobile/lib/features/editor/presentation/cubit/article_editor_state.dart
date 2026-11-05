part of 'article_editor_cubit.dart';

enum EditorLoadStatus { loading, ready, failure }

/// The autosave indicator: جاري الحفظ… / اتحفظ / offline, saved on the device.
enum SaveStatus { idle, saving, saved, offline, failed }

/// A long action that blocks the editor's buttons.
enum EditorBusy { none, publishing, discarding, restoring, deleting }

/// One-shot outcomes the page reacts to (navigation, snack bars).
enum EditorEvent { published, updated, discarded, restored, deleted }

/// One editable row of the sources list; only complete rows go into the document.
class SourceDraft extends Equatable {
  const SourceDraft({required this.key, this.title = '', this.url = ''});

  /// Stable id for list keys.
  final int key;
  final String title;
  final String url;

  bool get isBlank => title.trim().isEmpty && url.trim().isEmpty;
  bool get isComplete => title.trim().isNotEmpty && isValidUrl;
  bool get isValidUrl => InlineEditing.isHttpUrl(url);

  SourceDraft copyWith({String? title, String? url}) => SourceDraft(key: key, title: title ?? this.title, url: url ?? this.url);

  @override
  List<Object?> get props => [key, title, url];
}

class ArticleEditorState extends Equatable {
  const ArticleEditorState({
    required this.document,
    required this.activeLanguage,
    this.loadStatus = EditorLoadStatus.loading,
    this.loadFailure,
    this.articleId,
    this.lifecycle = ArticleLifecycle.draft,
    this.slug,
    this.publishedAt,
    this.version,
    this.serverSavedAt,
    this.hasUnpublishedChanges = false,
    this.media = const [],
    this.checks = DraftChecks.empty,
    this.checksFresh = false,
    this.dirty = false,
    this.saveStatus = SaveStatus.idle,
    this.saveFailure,
    this.conflicted = false,
    this.conflictCopy,
    this.backupOffer,
    this.uploads = 0,
    this.attachmentsBusy = false,
    this.attachmentAssets = const {},
    this.sources = const [],
    this.busy = EditorBusy.none,
    this.notice,
    this.noticeSeq = 0,
    this.event,
    this.eventSeq = 0,
    this.publishedSlug,
    this.documentRevision = 0,
    this.fields = const [],
    this.topics = const [],
    this.categoryId,
    this.categories = const [],
    this.categoriesStatus = EditorLoadStatus.ready,
    this.categoryBusy = false,
  });

  final EditorLoadStatus loadStatus;
  final Failure? loadFailure;

  /// What the writer is editing (the source of truth for autosave).
  final ArticleDraftDocument document;

  /// The language version shown in the editor.
  final String activeLanguage;

  /// Null until the first autosave creates the article.
  final String? articleId;
  final ArticleLifecycle lifecycle;
  final String? slug;
  final DateTime? publishedAt;

  /// The working copy's version the next save is based on.
  final int? version;
  final DateTime? serverSavedAt;
  final bool hasUnpublishedChanges;

  /// The attachments' uploads from the API.
  final List<MediaAsset> media;

  /// The API's checks from the last save; [checksFresh] while they describe [document].
  final DraftChecks checks;
  final bool checksFresh;

  /// Edits the API doesn't have yet.
  final bool dirty;
  final SaveStatus saveStatus;
  final Failure? saveFailure;

  /// A save hit `409 article.draft_conflict`; [conflictCopy] is the API's version (when it could be fetched).
  final bool conflicted;
  final ArticleEdit? conflictCopy;

  /// Unsaved changes found on the device, newer than the API's copy.
  final EditorBackup? backupOffer;

  /// Cover and image-block uploads in flight.
  final int uploads;

  /// The attachment bar has something uploading or processing.
  final bool attachmentsBusy;
  final Map<String, MediaAsset> attachmentAssets;

  final List<SourceDraft> sources;
  final EditorBusy busy;

  /// A failure to explain once; [noticeSeq] changes with every one.
  final Failure? notice;
  final int noticeSeq;

  final EditorEvent? event;
  final int eventSeq;

  /// After a publish: the reader opens `/a/{slug}`.
  final String? publishedSlug;

  /// Changes whenever [document] is replaced from outside the editing surface (open, reload, restore, discard), so
  /// the surface reloads.
  final int documentRevision;

  final List<Field> fields;

  /// Topics of the selected field.
  final List<Topic> topics;

  /// The article's writer category (F31), null for none. Not part of [document]: the picker sets it at once with
  /// `PUT /articles/{id}/category`.
  final String? categoryId;

  /// The writer's categories for the picker (`GET /me/categories`, empty ones included), in their order.
  final List<WriterCategory> categories;
  final EditorLoadStatus categoriesStatus;

  /// A category change is on its way to the API.
  final bool categoryBusy;

  /// [categoryId] as one of [categories]; null for none, or while the list hasn't loaded.
  WriterCategory? get category => categories.where((c) => c.id == categoryId).firstOrNull;

  bool get isNew => articleId == null;
  bool get isPublished => lifecycle == ArticleLifecycle.published;
  bool get isReady => loadStatus == EditorLoadStatus.ready;

  Field? get field => fields.where((f) => f.id == document.fieldId).firstOrNull;

  DraftTranslation get activeTranslation => document.translation(activeLanguage) ?? document.source;

  /// Something is still uploading or processing: publishing waits for it.
  bool get uploading => uploads > 0 || attachmentsBusy;

  /// The publish checks: the API's while they describe the document, else the device's, plus what only the API can
  /// tell: `content_invalid`, and the `tag.hidden` / `tag.limit` of the tags the document still has (F32).
  List<DraftProblem> get problems {
    if (checksFresh && !dirty) return checks.problems;
    return [
      ...DraftChecker.problems(document, field: field, assets: attachmentAssets),
      ...checks.problems.where((p) =>
          p.code == DraftProblemCodes.contentInvalid ||
          (DraftProblemCodes.tagProblems.contains(p.code) && p.tag != null && TagNames.containsTag(document.tags, p.tag!))),
    ];
  }

  /// The API's `tag.hidden` / `tag.limit` problem of the tag [name], if any (F32).
  DraftProblem? tagProblemOf(String name) => problems
      .where((p) => DraftProblemCodes.tagProblems.contains(p.code) && p.tag != null && TagNames.same(p.tag!, name))
      .firstOrNull;

  ReadingTime? get readingTime => checks.readingTimeOf(activeLanguage);

  /// A published article with nothing new has nothing to update.
  bool get hasChangesToPublish => !isPublished || hasUnpublishedChanges || dirty;

  bool get canPublish =>
      isReady && busy == EditorBusy.none && !conflicted && !uploading && problems.isEmpty && hasChangesToPublish;

  ArticleEditorState copyWith({
    EditorLoadStatus? loadStatus,
    Failure? Function()? loadFailure,
    ArticleDraftDocument? document,
    String? activeLanguage,
    String? Function()? articleId,
    ArticleLifecycle? lifecycle,
    String? Function()? slug,
    DateTime? Function()? publishedAt,
    int? Function()? version,
    DateTime? Function()? serverSavedAt,
    bool? hasUnpublishedChanges,
    List<MediaAsset>? media,
    DraftChecks? checks,
    bool? checksFresh,
    bool? dirty,
    SaveStatus? saveStatus,
    Failure? Function()? saveFailure,
    bool? conflicted,
    ArticleEdit? Function()? conflictCopy,
    EditorBackup? Function()? backupOffer,
    int? uploads,
    bool? attachmentsBusy,
    Map<String, MediaAsset>? attachmentAssets,
    List<SourceDraft>? sources,
    EditorBusy? busy,
    Failure? notice,
    EditorEvent? event,
    String? Function()? publishedSlug,
    int? documentRevision,
    List<Field>? fields,
    List<Topic>? topics,
    String? Function()? categoryId,
    List<WriterCategory>? categories,
    EditorLoadStatus? categoriesStatus,
    bool? categoryBusy,
  }) =>
      ArticleEditorState(
        loadStatus: loadStatus ?? this.loadStatus,
        loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
        document: document ?? this.document,
        activeLanguage: activeLanguage ?? this.activeLanguage,
        articleId: articleId != null ? articleId() : this.articleId,
        lifecycle: lifecycle ?? this.lifecycle,
        slug: slug != null ? slug() : this.slug,
        publishedAt: publishedAt != null ? publishedAt() : this.publishedAt,
        version: version != null ? version() : this.version,
        serverSavedAt: serverSavedAt != null ? serverSavedAt() : this.serverSavedAt,
        hasUnpublishedChanges: hasUnpublishedChanges ?? this.hasUnpublishedChanges,
        media: media ?? this.media,
        checks: checks ?? this.checks,
        checksFresh: checksFresh ?? this.checksFresh,
        dirty: dirty ?? this.dirty,
        saveStatus: saveStatus ?? this.saveStatus,
        saveFailure: saveFailure != null ? saveFailure() : this.saveFailure,
        conflicted: conflicted ?? this.conflicted,
        conflictCopy: conflictCopy != null ? conflictCopy() : this.conflictCopy,
        backupOffer: backupOffer != null ? backupOffer() : this.backupOffer,
        uploads: uploads ?? this.uploads,
        attachmentsBusy: attachmentsBusy ?? this.attachmentsBusy,
        attachmentAssets: attachmentAssets ?? this.attachmentAssets,
        sources: sources ?? this.sources,
        busy: busy ?? this.busy,
        notice: notice ?? this.notice,
        noticeSeq: notice != null ? noticeSeq + 1 : noticeSeq,
        event: event ?? this.event,
        eventSeq: event != null ? eventSeq + 1 : eventSeq,
        publishedSlug: publishedSlug != null ? publishedSlug() : this.publishedSlug,
        documentRevision: documentRevision ?? this.documentRevision,
        fields: fields ?? this.fields,
        topics: topics ?? this.topics,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        categories: categories ?? this.categories,
        categoriesStatus: categoriesStatus ?? this.categoriesStatus,
        categoryBusy: categoryBusy ?? this.categoryBusy,
      );

  @override
  List<Object?> get props => [
        loadStatus,
        loadFailure,
        document,
        activeLanguage,
        articleId,
        lifecycle,
        slug,
        publishedAt,
        version,
        serverSavedAt,
        hasUnpublishedChanges,
        media,
        checks,
        checksFresh,
        dirty,
        saveStatus,
        saveFailure,
        conflicted,
        conflictCopy,
        backupOffer,
        uploads,
        attachmentsBusy,
        attachmentAssets,
        sources,
        busy,
        notice,
        noticeSeq,
        event,
        eventSeq,
        publishedSlug,
        documentRevision,
        fields,
        topics,
        categoryId,
        categories,
        categoriesStatus,
        categoryBusy,
      ];
}
