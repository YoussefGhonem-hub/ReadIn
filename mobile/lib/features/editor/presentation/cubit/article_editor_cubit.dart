import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/rdoc/editing/inline_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../article/domain/entities/article.dart';
import '../../../categories/domain/entities/writer_category.dart';
import '../../../categories/domain/usecases/category_usecases.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../../tags/domain/services/tag_names.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/editor_backup.dart';
import '../../domain/entities/editor_entities.dart';
import '../../domain/repositories/article_editor_repository.dart';
import '../../domain/services/draft_checker.dart';
import '../../domain/usecases/editor_usecases.dart';

part 'article_editor_state.dart';

/// What [ArticleEditorCubit.addTag] did with a name (F32).
enum TagAddResult {
  added,

  /// Nothing left after cleaning.
  empty,

  /// The article already has that tag (ignoring case and Arabic normalization).
  duplicate,

  /// The article has 5 tags.
  full,

  /// A new tag needs 2 to 30 characters.
  tooShort,
  tooLong,

  /// A new tag has letters, digits, spaces and `- _ . + #` only.
  invalidCharacters,

  /// A new tag needs a letter or digit (tatweel aside).
  noLetter,
}

/// The article editor (F05): one article's working copy, every language version and its settings.
///
/// * **Autosave** every [autosaveInterval] while there are unsaved edits: `POST /articles` the first time, then
///   `PUT /articles/{id}/draft` with `baseVersion`. The page also calls [flush] when the app pauses and on back.
/// * **Local backup**: every unsaved change is written to the device ([backupDelay] after the last keystroke), keyed
///   by the article id (or [EditorBackup.newArticleKey]), and dropped once the API has it. On open, a backup newer
///   than the API's copy is offered for restore; offline, the editor opens from it.
/// * **Conflicts**: `409 article.draft_conflict` stops autosave until the writer reloads the API's copy or keeps
///   theirs.
/// * **Publish / Update**, discard changes, restore a revision, delete.
/// * **Category** (F31): not part of the document; the picker applies it at once with `PUT /articles/{id}/category`.
@injectable
class ArticleEditorCubit extends Cubit<ArticleEditorState> {
  ArticleEditorCubit(
    this._create,
    this._get,
    this._save,
    this._discard,
    this._publish,
    this._restore,
    this._delete,
    this._getFields,
    this._getTopics,
    this._uploadImage,
    this._backups,
    this._getCategories,
    this._manageCategories,
    this._setCategory, {
    @ignoreParam this.autosaveInterval = const Duration(seconds: 10),
    @ignoreParam this.backupDelay = const Duration(seconds: 1),
    @ignoreParam DateTime Function() clock = DateTime.now,
  })  : _now = clock,
        super(ArticleEditorState(document: ArticleDraftDocument.empty(ArticleLanguages.ar), activeLanguage: ArticleLanguages.ar));

  final CreateArticle _create;
  final GetArticleForEdit _get;
  final SaveDraft _save;
  final DiscardChanges _discard;
  final PublishArticle _publish;
  final RestoreRevision _restore;
  final DeleteArticle _delete;
  final GetFields _getFields;
  final GetTopics _getTopics;
  final UploadImage _uploadImage;
  final EditorBackupStore _backups;
  final GetMyCategories _getCategories;
  final ManageCategories _manageCategories;
  final SetArticleCategory _setCategory;
  final DateTime Function() _now;

  final Duration autosaveInterval;
  final Duration backupDelay;

  Timer? _autosave;
  Timer? _backupTimer;
  Future<bool>? _saving;

  /// Bumped on every edit, so a save knows whether edits arrived while it ran.
  int _editSeq = 0;
  DateTime? _lastEditAt;
  int _sourceKeys = 0;
  String? _topicsFor;

  /// The category the API has for the article: where a failed change goes back to.
  String? _serverCategoryId;

  String get _backupKey => EditorBackup.keyFor(state.articleId);

  // ── Open ─────────────────────────────────────────────────

  /// Opens [articleId], or a new article in [language] when null.
  Future<void> open({String? articleId, required String language}) async {
    _autosave?.cancel();
    _autosave = Timer.periodic(autosaveInterval, (_) => _tick());
    unawaited(_loadFields());
    unawaited(loadCategories());
    final key = EditorBackup.keyFor(articleId);

    if (articleId == null) {
      final source = ArticleLanguages.normalize(language);
      final backup = await _backups.read(key);
      if (isClosed) return;
      emit(state.copyWith(
        loadStatus: EditorLoadStatus.ready,
        document: ArticleDraftDocument.empty(source),
        activeLanguage: source,
        sources: const [],
        backupOffer: () => backup,
        documentRevision: state.documentRevision + 1,
      ));
      return;
    }

    emit(state.copyWith(loadStatus: EditorLoadStatus.loading, loadFailure: () => null));
    final result = await _get(articleId);
    final backup = await _backups.read(key);
    if (isClosed) return;
    switch (result) {
      case Ok(value: final edit):
        _applyServer(edit, replaceDocument: true);
        emit(state.copyWith(loadStatus: EditorLoadStatus.ready));
        if (backup != null) {
          if (backup.editedAt.isAfter(edit.savedAt) && backup.document != edit.document) {
            emit(state.copyWith(backupOffer: () => backup));
          } else {
            await _backups.delete(key);
          }
        }
      case Err(:final failure):
        if (backup != null && _isOffline(failure)) {
          _openFromBackup(backup);
        } else {
          emit(state.copyWith(loadStatus: EditorLoadStatus.failure, loadFailure: () => failure));
        }
    }
  }

  void _openFromBackup(EditorBackup backup) {
    _lastEditAt = backup.editedAt;
    _editSeq++;
    emit(state.copyWith(
      loadStatus: EditorLoadStatus.ready,
      articleId: () => backup.articleId,
      lifecycle: backup.status,
      slug: () => backup.slug,
      version: () => backup.baseVersion,
      document: backup.document,
      activeLanguage: backup.document.sourceLanguage,
      sources: _rowsFor(backup.document.sources),
      dirty: true,
      saveStatus: SaveStatus.offline,
      documentRevision: state.documentRevision + 1,
    ));
    _loadTopicsFor(backup.document.fieldId);
  }

  /// Puts the device copy back into the editor (it saves on the next autosave).
  void restoreBackup() {
    final backup = state.backupOffer;
    if (backup == null) return;
    _lastEditAt = backup.editedAt;
    _editSeq++;
    emit(state.copyWith(
      document: backup.document,
      activeLanguage: backup.document.translation(state.activeLanguage) != null
          ? state.activeLanguage
          : backup.document.sourceLanguage,
      sources: _rowsFor(backup.document.sources),
      dirty: true,
      backupOffer: () => null,
      documentRevision: state.documentRevision + 1,
    ));
    _loadTopicsFor(backup.document.fieldId);
  }

  Future<void> dismissBackup() async {
    final backup = state.backupOffer;
    if (backup == null) return;
    emit(state.copyWith(backupOffer: () => null));
    await _backups.delete(backup.key);
  }

  void _applyServer(ArticleEdit edit, {required bool replaceDocument}) {
    final document = replaceDocument ? edit.document : state.document;
    emit(state.copyWith(
      articleId: () => edit.id,
      lifecycle: edit.status,
      slug: () => edit.slug,
      publishedAt: () => edit.publishedAt,
      version: () => edit.version,
      serverSavedAt: () => edit.savedAt,
      hasUnpublishedChanges: edit.hasUnpublishedChanges,
      media: edit.media,
      checks: edit.checks,
      checksFresh: replaceDocument,
      document: document,
      activeLanguage: replaceDocument && document.translation(state.activeLanguage) == null
          ? document.sourceLanguage
          : state.activeLanguage,
      sources: replaceDocument ? _rowsFor(document.sources) : state.sources,
      dirty: replaceDocument ? false : state.dirty,
      documentRevision: replaceDocument ? state.documentRevision + 1 : state.documentRevision,
      // A category change on its way wins over an answer that was sent before it.
      categoryId: state.categoryBusy ? null : () => edit.categoryId,
    ));
    if (!state.categoryBusy) _serverCategoryId = edit.categoryId;
    if (replaceDocument) _loadTopicsFor(document.fieldId);
  }

  Future<void> _loadFields() async {
    final result = await _getFields();
    if (isClosed) return;
    if (result case Ok(value: final fields)) {
      emit(state.copyWith(fields: fields));
      _loadTopicsFor(state.document.fieldId, force: true);
    }
  }

  void _loadTopicsFor(String? fieldId, {bool force = false}) {
    if (!force && fieldId == _topicsFor) return;
    _topicsFor = fieldId;
    final field = state.fields.where((f) => f.id == fieldId).firstOrNull;
    if (field == null) {
      if (state.topics.isNotEmpty) emit(state.copyWith(topics: const []));
      return;
    }
    unawaited(() async {
      final result = await _getTopics(field.slug);
      if (isClosed || _topicsFor != fieldId) return;
      emit(state.copyWith(topics: result.valueOrNull ?? const []));
    }());
  }

  // ── Editing ──────────────────────────────────────────────

  void _edit(ArticleDraftDocument next, {List<SourceDraft>? sources, String? activeLanguage}) {
    if (!state.isReady || next == state.document && sources == null) return;
    _editSeq++;
    _lastEditAt = _now();
    emit(state.copyWith(
      document: next,
      sources: sources,
      activeLanguage: activeLanguage,
      dirty: next != state.document || state.dirty,
      saveStatus: state.saveStatus == SaveStatus.saving ? SaveStatus.saving : SaveStatus.idle,
    ));
    _backupTimer?.cancel();
    _backupTimer = Timer(backupDelay, () => unawaited(_writeBackup()));
  }

  DraftTranslation _version(String language) => state.document.translation(language) ?? DraftTranslation.empty(language);

  void setActiveLanguage(String language) {
    if (state.document.translation(language) != null) emit(state.copyWith(activeLanguage: language));
  }

  void setTitle(String language, String title) =>
      _edit(state.document.withTranslation(_version(language).copyWith(title: title)));

  void setSubtitle(String language, String subtitle) =>
      _edit(state.document.withTranslation(_version(language).copyWith(subtitle: () => subtitle.isEmpty ? null : subtitle)));

  /// The editing surface's document for [language] (its `language` is set to [language]).
  void setContent(String language, RDocDocument content) => _edit(state.document.withTranslation(
        _version(language).copyWith(content: content.language == language ? content : content.copyWith(language: language)),
      ));

  void selectField(String? fieldId) {
    final keepTopic = state.topics.any((t) => t.id == state.document.topicId && t.fieldId == fieldId);
    _edit(state.document.copyWith(fieldId: () => fieldId, topicId: keepTopic ? null : () => null));
    _loadTopicsFor(fieldId);
  }

  void selectTopic(String? topicId) => _edit(state.document.copyWith(topicId: () => topicId));

  /// Adds a tag (F32), [name] cleaned like the API cleans it (a leading `#` dropped, spaces collapsed). A repeat of a
  /// tag the article has (ignoring case and Arabic normalization) and a sixth tag are not added. A new name must
  /// follow the tag rules; an [existing] tag picked from the suggestions is added as it is, even one older than them.
  TagAddResult addTag(String name, {bool existing = false}) {
    final value = TagNames.clean(name);
    final tags = state.document.tags;
    if (value.isEmpty) return TagAddResult.empty;
    if (TagNames.containsTag(tags, value)) return TagAddResult.duplicate;
    if (tags.length >= DraftLimits.maxTags) return TagAddResult.full;
    if (!existing) {
      switch (TagNames.validate(value)) {
        case TagNameError.tooShort:
          return TagAddResult.tooShort;
        case TagNameError.tooLong:
          return TagAddResult.tooLong;
        case TagNameError.invalidCharacters:
          return TagAddResult.invalidCharacters;
        case TagNameError.noLetter:
          return TagAddResult.noLetter;
        case null:
          break;
      }
    }
    _edit(state.document.copyWith(tags: [...tags, value]));
    return TagAddResult.added;
  }

  void removeTag(String tag) => _edit(state.document.copyWith(tags: [...state.document.tags.where((t) => t != tag)]));

  void setVersionBadge(String badge) {
    final value = badge.trim();
    _edit(state.document.copyWith(versionBadge: () => value.isEmpty ? null : value));
  }

  void setAiAssisted(bool value) => _edit(state.document.copyWith(isAiAssisted: value));

  void setCover(String? url) => _edit(state.document.copyWith(coverUrl: () => url));

  // Sources: rows in the form, complete ones in the document.

  void addSource() {
    if (state.sources.length >= DraftLimits.maxSources) return;
    _setSources([...state.sources, SourceDraft(key: ++_sourceKeys)]);
  }

  void updateSource(int key, {String? title, String? url}) =>
      _setSources([for (final s in state.sources) s.key == key ? s.copyWith(title: title, url: url) : s]);

  void removeSource(int key) => _setSources([...state.sources.where((s) => s.key != key)]);

  void _setSources(List<SourceDraft> rows) => _edit(
        state.document.copyWith(sources: [
          for (final s in rows)
            if (s.isComplete) ArticleSource(title: s.title.trim(), url: s.url.trim()),
        ]),
        sources: rows,
      );

  List<SourceDraft> _rowsFor(List<ArticleSource> sources) =>
      [for (final s in sources) SourceDraft(key: ++_sourceKeys, title: s.title, url: s.url)];

  /// The attachment bar's items (1–10 images or one PDF), from the attachments cubit.
  void setAttachments(List<AttachmentItem> items, {required bool busy, required Map<String, MediaAsset> assets}) {
    if (busy != state.attachmentsBusy || assets != state.attachmentAssets) {
      emit(state.copyWith(attachmentsBusy: busy, attachmentAssets: assets));
    }
    if (items.length != state.document.attachments.length || !_sameItems(items, state.document.attachments)) {
      _edit(state.document.copyWith(attachments: items));
    }
  }

  static bool _sameItems(List<AttachmentItem> a, List<AttachmentItem> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Language versions (SPEC F05: a second language of the same article).

  /// Adds the other language as a second, empty version and shows it.
  void addTranslation() {
    if (state.document.hasTranslation) return;
    final language = ArticleLanguages.other(state.document.sourceLanguage);
    _edit(
      state.document.copyWith(translations: [...state.document.translations, DraftTranslation.empty(language)]),
      activeLanguage: language,
    );
  }

  void removeTranslation(String language) {
    if (language == state.document.sourceLanguage || state.document.translation(language) == null) return;
    _edit(
      state.document.copyWith(translations: [...state.document.translations.where((t) => t.language != language)]),
      activeLanguage: state.document.sourceLanguage,
    );
    emit(state.copyWith(documentRevision: state.documentRevision + 1));
  }

  /// Changes the language of the only version (before a translation is added).
  void setSourceLanguage(String language) {
    final target = ArticleLanguages.normalize(language);
    if (state.document.hasTranslation || target == state.document.sourceLanguage) return;
    final only = state.document.source;
    final moved = DraftTranslation(
      language: target,
      title: only.title,
      subtitle: only.subtitle,
      content: only.content.copyWith(language: target),
    );
    _edit(state.document.copyWith(sourceLanguage: target, translations: [moved]), activeLanguage: target);
    emit(state.copyWith(documentRevision: state.documentRevision + 1));
  }

  // ── Category (F31) ───────────────────────────────────────

  /// The writer's categories for the picker (`GET /me/categories`), loaded on open; again to retry.
  Future<void> loadCategories() async {
    emit(state.copyWith(categoriesStatus: EditorLoadStatus.loading));
    final result = await _getCategories();
    if (isClosed) return;
    emit(result.fold(
      (_) => state.copyWith(categoriesStatus: EditorLoadStatus.failure),
      (list) => state.copyWith(categoriesStatus: EditorLoadStatus.ready, categories: list.items),
    ));
  }

  /// "＋ قسم جديد": `POST /me/categories`, added last to the picker. The picker then puts the article in it.
  Future<Result<WriterCategory>> createCategory(String name) async {
    final result = await _manageCategories.create(name);
    if (isClosed) return result;
    if (result case Ok(value: final category)) {
      emit(state.copyWith(categories: [...state.categories, category], categoriesStatus: EditorLoadStatus.ready));
    }
    return result;
  }

  /// Puts the article in [categoryId] (null: none) at once, with `PUT /articles/{id}/category`: no publish, no
  /// revision, and the working copy's version stays. A new article is saved first (`POST /articles`). The picker shows
  /// the choice right away and goes back to the API's category (with a notice) when it fails. Null when it worked.
  Future<Failure?> setCategory(String? categoryId) async {
    if (!state.isReady || state.categoryBusy || categoryId == state.categoryId) return null;
    emit(state.copyWith(categoryId: () => categoryId, categoryBusy: true));
    if (state.isNew) {
      final saved = await save();
      if (isClosed) return null;
      if (!saved || state.articleId == null) {
        final failure = state.saveFailure ?? const Failure(FailureCodes.serverError);
        emit(state.copyWith(categoryId: () => _serverCategoryId, categoryBusy: false, notice: failure));
        return failure;
      }
    }
    final result = await _setCategory(state.articleId!, categoryId);
    if (isClosed) return result.failureOrNull;
    switch (result) {
      case Ok():
        _serverCategoryId = categoryId;
        emit(state.copyWith(categoryBusy: false));
        return null;
      case Err(:final failure):
        emit(state.copyWith(categoryId: () => _serverCategoryId, categoryBusy: false, notice: failure));
        // Deleted on another device: the picker catches up.
        if (failure.code == FailureCodes.categoryNotFound) unawaited(loadCategories());
        return failure;
    }
  }

  // ── Uploads ──────────────────────────────────────────────

  /// Uploads a cover (`purpose=cover`, compressed on the device) and sets it.
  Future<void> uploadCover(PickedMediaFile file) async {
    final asset = await uploadImage(file, purpose: 'cover');
    if (asset != null && !isClosed) setCover(imageUrlOf(asset));
  }

  /// Uploads an image for an image block or the cover; null (and a notice) when it fails.
  Future<MediaAsset?> uploadImage(PickedMediaFile file, {String purpose = 'image'}) async {
    emit(state.copyWith(uploads: state.uploads + 1));
    final result = await _uploadImage(file, purpose: purpose);
    if (isClosed) return result.valueOrNull;
    emit(state.copyWith(uploads: state.uploads - 1));
    if (result case Err(:final failure)) {
      if (failure.code != FailureCodes.requestCancelled) emit(state.copyWith(notice: failure));
      return null;
    }
    return result.valueOrNull;
  }

  /// The URL an uploaded image is referenced by: its largest variant.
  static String? imageUrlOf(MediaAsset asset) => asset.variants.isEmpty ? null : asset.variants.last.url;

  // ── Saving ───────────────────────────────────────────────

  void _tick() {
    if (state.isReady && state.dirty && !state.conflicted && state.busy == EditorBusy.none && _saving == null) {
      unawaited(save());
    }
  }

  /// Saves now (autosave, back, app pause, before publishing). True when the API has the document.
  Future<bool> save() {
    final running = _saving;
    // One save at a time; edits made meanwhile go in a second one.
    if (running != null) return running.then((ok) => ok && state.dirty ? save() : Future.value(ok));
    if (!state.isReady || state.conflicted) return Future.value(false);
    final future = _doSave();
    _saving = future;
    return future.whenComplete(() => _saving = null);
  }

  Future<bool> _doSave() async {
    final document = state.document;
    final seq = _editSeq;
    final wasNew = state.isNew;
    emit(state.copyWith(saveStatus: SaveStatus.saving, saveFailure: () => null));
    final result = wasNew
        ? await _create(document)
        : await _save(state.articleId!, baseVersion: state.version ?? 1, document: document);
    if (isClosed) return result.isOk;
    switch (result) {
      case Ok(value: final edit):
        final clean = seq == _editSeq;
        _applyServer(edit, replaceDocument: false);
        emit(state.copyWith(dirty: !clean, checksFresh: clean, saveStatus: SaveStatus.saved));
        if (wasNew) await _backups.delete(EditorBackup.newArticleKey);
        if (clean) {
          _backupTimer?.cancel();
          await _backups.delete(EditorBackup.keyFor(edit.id));
        } else {
          await _writeBackup();
        }
        return true;
      case Err(:final failure):
        if (failure.code == FailureCodes.articleDraftConflict) {
          await _enterConflict();
        } else {
          await _writeBackup();
          if (!isClosed) {
            emit(state.copyWith(
              saveStatus: _isOffline(failure) ? SaveStatus.offline : SaveStatus.failed,
              saveFailure: () => failure,
            ));
          }
        }
        return false;
    }
  }

  /// Writes the backup now and saves when there's something to save.
  Future<void> flush() async {
    _backupTimer?.cancel();
    if (!state.dirty) return;
    await _writeBackup();
    if (!state.conflicted) await save();
  }

  Future<void> _writeBackup() async {
    if (!state.dirty || !state.isReady) return;
    await _backups.write(EditorBackup(
      key: _backupKey,
      articleId: state.articleId,
      baseVersion: state.version,
      status: state.lifecycle,
      slug: state.slug,
      document: state.document,
      editedAt: _lastEditAt ?? _now(),
    ));
  }

  static bool _isOffline(Failure failure) =>
      failure.code == FailureCodes.networkOffline || failure.code == FailureCodes.networkTimeout;

  // ── Conflicts ────────────────────────────────────────────

  Future<void> _enterConflict() async {
    await _writeBackup();
    if (isClosed) return;
    emit(state.copyWith(conflicted: true, saveStatus: SaveStatus.failed, saveFailure: () => const Failure(FailureCodes.articleDraftConflict)));
    final id = state.articleId;
    if (id == null) return;
    final server = await _get(id);
    if (!isClosed && state.conflicted) emit(state.copyWith(conflictCopy: () => server.valueOrNull));
  }

  /// Drops this device's changes and loads the API's copy.
  Future<void> reloadServerCopy() async {
    final id = state.articleId;
    if (id == null) return;
    var copy = state.conflictCopy;
    if (copy == null) {
      final result = await _get(id);
      if (isClosed) return;
      if (result case Err(:final failure)) return emit(state.copyWith(notice: failure));
      copy = result.valueOrNull;
    }
    _backupTimer?.cancel();
    _editSeq++;
    _applyServer(copy!, replaceDocument: true);
    emit(state.copyWith(conflicted: false, conflictCopy: () => null, saveStatus: SaveStatus.saved, saveFailure: () => null));
    await _backups.delete(_backupKey);
  }

  /// Keeps this device's document: saves it over the API's copy.
  Future<void> keepMine() async {
    final id = state.articleId;
    if (id == null) return;
    var version = state.conflictCopy?.version;
    if (version == null) {
      final result = await _get(id);
      if (isClosed) return;
      if (result case Err(:final failure)) return emit(state.copyWith(notice: failure));
      version = result.valueOrNull!.version;
    }
    emit(state.copyWith(version: () => version, conflicted: false, conflictCopy: () => null, dirty: true));
    await save();
  }

  // ── Actions ──────────────────────────────────────────────

  /// Publish (first time) or Update: saves pending edits, then `POST /articles/{id}/publish`.
  Future<void> publish() async {
    if (!state.canPublish) return;
    final firstPublish = !state.isPublished;
    emit(state.copyWith(busy: EditorBusy.publishing));
    if (state.dirty || state.isNew) {
      final saved = await save();
      if (isClosed) return;
      if (!saved) return emit(state.copyWith(busy: EditorBusy.none));
      if (state.problems.isNotEmpty) return emit(state.copyWith(busy: EditorBusy.none));
    }
    final result = await _publish(state.articleId!, baseVersion: state.version ?? 1);
    if (isClosed) return;
    switch (result) {
      case Ok(value: final published):
        await _backups.delete(_backupKey);
        if (isClosed) return;
        emit(state.copyWith(
          busy: EditorBusy.none,
          lifecycle: ArticleLifecycle.published,
          slug: () => published.slug,
          publishedAt: () => published.publishedAt,
          hasUnpublishedChanges: state.dirty,
          publishedSlug: () => published.slug,
          event: firstPublish ? EditorEvent.published : EditorEvent.updated,
        ));
      case Err(:final failure):
        if (failure is DraftProblemsFailure) {
          emit(state.copyWith(
            busy: EditorBusy.none,
            checks: DraftChecks(readingTime: state.checks.readingTime, problems: failure.problems),
            checksFresh: true,
            notice: failure,
          ));
        } else if (failure is ObjectionableContentFailure) {
          // F37: the content filter refused a text; the checks point at the title or the block, like a publish check.
          emit(state.copyWith(
            busy: EditorBusy.none,
            checks: DraftChecks(
              readingTime: state.checks.readingTime,
              problems: [
                DraftProblem(
                  FailureCodes.contentObjectionable,
                  language: failure.language,
                  blockId: failure.blockId,
                  field: failure.field,
                ),
              ],
            ),
            checksFresh: true,
            notice: failure,
          ));
        } else if (failure.code == FailureCodes.articleDraftConflict) {
          emit(state.copyWith(busy: EditorBusy.none));
          await _enterConflict();
        } else {
          emit(state.copyWith(busy: EditorBusy.none, notice: failure));
        }
    }
  }

  /// Back to what readers see (published articles with unpublished changes).
  Future<void> discardChanges() async {
    final id = state.articleId;
    if (id == null || !state.isPublished || state.busy != EditorBusy.none) return;
    emit(state.copyWith(busy: EditorBusy.discarding));
    final result = await _discard(id);
    if (isClosed) return;
    switch (result) {
      case Ok(value: final edit):
        _backupTimer?.cancel();
        _editSeq++;
        _applyServer(edit, replaceDocument: true);
        emit(state.copyWith(busy: EditorBusy.none, conflicted: false, saveStatus: SaveStatus.saved, event: EditorEvent.discarded));
        await _backups.delete(_backupKey);
      case Err(:final failure):
        emit(state.copyWith(busy: EditorBusy.none, notice: failure));
    }
  }

  /// Copies revision [number] into the working copy (live after Update).
  Future<bool> restoreRevision(int number) async {
    final id = state.articleId;
    if (id == null || state.busy != EditorBusy.none) return false;
    emit(state.copyWith(busy: EditorBusy.restoring));
    final result = await _restore(id, number, baseVersion: state.version ?? 1);
    if (isClosed) return result.isOk;
    switch (result) {
      case Ok(value: final edit):
        _backupTimer?.cancel();
        _editSeq++;
        _applyServer(edit, replaceDocument: true);
        emit(state.copyWith(busy: EditorBusy.none, saveStatus: SaveStatus.saved, event: EditorEvent.restored));
        await _backups.delete(_backupKey);
        return true;
      case Err(:final failure):
        emit(state.copyWith(busy: EditorBusy.none));
        if (failure.code == FailureCodes.articleDraftConflict) {
          await _enterConflict();
        } else {
          emit(state.copyWith(notice: failure));
        }
        return false;
    }
  }

  /// Deletes the article (a new one that was never saved only loses its device copy).
  Future<void> delete() async {
    if (state.busy != EditorBusy.none) return;
    _autosave?.cancel();
    _backupTimer?.cancel();
    final id = state.articleId;
    if (id == null) {
      await _backups.delete(EditorBackup.newArticleKey);
      if (!isClosed) emit(state.copyWith(dirty: false, event: EditorEvent.deleted));
      return;
    }
    emit(state.copyWith(busy: EditorBusy.deleting));
    final result = await _delete(id);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      _autosave = Timer.periodic(autosaveInterval, (_) => _tick());
      return emit(state.copyWith(busy: EditorBusy.none, notice: failure));
    }
    await _backups.delete(EditorBackup.keyFor(id));
    if (!isClosed) emit(state.copyWith(busy: EditorBusy.none, dirty: false, event: EditorEvent.deleted));
  }

  @override
  Future<void> close() {
    _autosave?.cancel();
    _backupTimer?.cancel();
    return super.close();
  }
}
