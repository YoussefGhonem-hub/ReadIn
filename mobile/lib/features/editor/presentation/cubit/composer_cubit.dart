import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/rdoc/rdoc_builder.dart';
import '../../../article/domain/entities/article.dart';
import '../../../media/domain/entities/media.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/article_draft.dart';
import '../../domain/usecases/publish_usecases.dart';

/// One editable row of the sources list.
class SourceDraft extends Equatable {
  const SourceDraft({required this.key, this.title = '', this.url = ''});

  /// Stable id for list keys.
  final int key;
  final String title;
  final String url;

  bool get isBlank => title.trim().isEmpty && url.trim().isEmpty;
  bool get isComplete => title.trim().isNotEmpty && isValidUrl;

  bool get isValidUrl {
    final uri = Uri.tryParse(url.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  SourceDraft copyWith({String? title, String? url}) => SourceDraft(key: key, title: title ?? this.title, url: url ?? this.url);

  @override
  List<Object?> get props => [key, title, url];
}

/// Why the composer can't publish yet (the attachment reasons live in
/// `AttachmentsState.blockers`).
enum ComposerBlocker { field, title, body, sources, incompleteSource }

enum PublishStatus { idle, publishing, success, failure }

class ComposerState extends Equatable {
  const ComposerState({
    this.fieldsLoading = true,
    this.fields = const [],
    this.fieldsFailure,
    this.fieldId,
    this.language = 'ar-EG',
    this.title = '',
    this.body = '',
    this.sources = const [],
    this.publishStatus = PublishStatus.idle,
    this.publishFailure,
    this.publishedSlug,
  });

  final bool fieldsLoading;
  final List<Field> fields;
  final Failure? fieldsFailure;
  final String? fieldId;

  /// Article language: `ar-EG` | `en`.
  final String language;
  final String title;
  final String body;
  final List<SourceDraft> sources;
  final PublishStatus publishStatus;
  final Failure? publishFailure;

  /// Set once published: the page opens `/a/{slug}`.
  final String? publishedSlug;

  Field? get selectedField => fields.where((f) => f.id == fieldId).firstOrNull;
  bool get publishing => publishStatus == PublishStatus.publishing;
  bool get requiresSources => selectedField?.requiresSources ?? false;
  List<SourceDraft> get completeSources => sources.where((s) => s.isComplete).toList();

  bool get titleValid {
    final length = title.trim().length;
    return length >= ArticleDraft.minTitle && length <= ArticleDraft.maxTitle;
  }

  /// [hasAttachments]: a post with images or a PDF may have no body text.
  List<ComposerBlocker> blockers({required bool hasAttachments}) => [
        if (fieldId == null) ComposerBlocker.field,
        if (!titleValid) ComposerBlocker.title,
        if (!hasAttachments && RDocBuilder.paragraphsOf(body).isEmpty) ComposerBlocker.body,
        if (requiresSources && completeSources.isEmpty) ComposerBlocker.sources,
        if (sources.any((s) => !s.isBlank && !s.isComplete)) ComposerBlocker.incompleteSource,
      ];

  ArticleDraft toDraft() => ArticleDraft(
        fieldId: fieldId ?? '',
        language: language,
        title: title.trim(),
        content: RDocBuilder.fromPlainText(body, language: language),
        sources: [for (final s in completeSources) ArticleSource(title: s.title.trim(), url: s.url.trim())],
      );

  ComposerState copyWith({
    bool? fieldsLoading,
    List<Field>? fields,
    Failure? Function()? fieldsFailure,
    String? Function()? fieldId,
    String? language,
    String? title,
    String? body,
    List<SourceDraft>? sources,
    PublishStatus? publishStatus,
    Failure? Function()? publishFailure,
    String? Function()? publishedSlug,
  }) =>
      ComposerState(
        fieldsLoading: fieldsLoading ?? this.fieldsLoading,
        fields: fields ?? this.fields,
        fieldsFailure: fieldsFailure != null ? fieldsFailure() : this.fieldsFailure,
        fieldId: fieldId != null ? fieldId() : this.fieldId,
        language: language ?? this.language,
        title: title ?? this.title,
        body: body ?? this.body,
        sources: sources ?? this.sources,
        publishStatus: publishStatus ?? this.publishStatus,
        publishFailure: publishFailure != null ? publishFailure() : this.publishFailure,
        publishedSlug: publishedSlug != null ? publishedSlug() : this.publishedSlug,
      );

  @override
  List<Object?> get props => [
        fieldsLoading,
        fields,
        fieldsFailure,
        fieldId,
        language,
        title,
        body,
        sources,
        publishStatus,
        publishFailure,
        publishedSlug,
      ];
}

/// Minimal post composer (F05/F26): field, article language, title, plain
/// body (→ RDoc paragraphs), sources. Publishing runs
/// `POST /articles` → `PUT /articles/{id}/attachments` → `POST /articles/{id}/publish`.
/// A retry after a later step failed reuses the created draft unless the
/// content changed since (the contract has no draft update endpoint).
@injectable
class ComposerCubit extends Cubit<ComposerState> {
  ComposerCubit(this._getFields, this._create, this._setAttachments, this._publish) : super(const ComposerState());

  final GetFields _getFields;
  final CreateArticleDraft _create;
  final SetArticleAttachments _setAttachments;
  final PublishArticle _publish;

  CreatedArticle? _created;
  ArticleDraft? _createdFrom;
  bool _attachmentsSent = false;
  int _sourceKeys = 0;

  Future<void> start({required String language}) async {
    emit(state.copyWith(language: language == 'en' ? 'en' : 'ar-EG'));
    await loadFields();
  }

  Future<void> loadFields() async {
    emit(state.copyWith(fieldsLoading: true, fieldsFailure: () => null));
    final result = await _getFields();
    if (isClosed) return;
    emit(result.fold(
      (failure) => state.copyWith(fieldsLoading: false, fieldsFailure: () => failure),
      (fields) => state.copyWith(fieldsLoading: false, fields: fields),
    ));
  }

  void selectField(String? fieldId) => _edit(state.copyWith(fieldId: () => fieldId));

  void setLanguage(String language) => _edit(state.copyWith(language: language == 'en' ? 'en' : 'ar-EG'));

  void setTitle(String title) => _edit(state.copyWith(title: title));

  void setBody(String body) => _edit(state.copyWith(body: body));

  void addSource() => _edit(state.copyWith(sources: [...state.sources, SourceDraft(key: ++_sourceKeys)]));

  void updateSource(int key, {String? title, String? url}) => _edit(state.copyWith(sources: [
        for (final s in state.sources) s.key == key ? s.copyWith(title: title, url: url) : s,
      ]));

  void removeSource(int key) => _edit(state.copyWith(sources: [...state.sources.where((s) => s.key != key)]));

  void _edit(ComposerState next) {
    if (state.publishing) return;
    emit(next.publishStatus == PublishStatus.failure
        ? next.copyWith(publishStatus: PublishStatus.idle, publishFailure: () => null)
        : next);
  }

  /// [attachments] come from the attachments cubit, already validated
  /// (alt text, nothing uploading/processing).
  Future<void> publish({required List<AttachmentItem> attachments}) async {
    if (state.publishing || state.blockers(hasAttachments: attachments.isNotEmpty).isNotEmpty) return;
    emit(state.copyWith(publishStatus: PublishStatus.publishing, publishFailure: () => null));

    final draft = state.toDraft();
    if (_created == null || _createdFrom != draft) {
      final created = await _create(draft);
      if (isClosed) return;
      if (created case Err(:final failure)) return _fail(failure);
      _created = created.valueOrNull;
      _createdFrom = draft;
      _attachmentsSent = false;
    }
    final article = _created!;

    if (attachments.isNotEmpty || _attachmentsSent) {
      final set = await _setAttachments(article.id, attachments);
      if (isClosed) return;
      if (set case Err(:final failure)) return _fail(failure);
      _attachmentsSent = attachments.isNotEmpty;
    }

    final published = await _publish(article.id);
    if (isClosed) return;
    if (published case Err(:final failure)) return _fail(failure);

    emit(state.copyWith(publishStatus: PublishStatus.success, publishedSlug: () => article.slug));
  }

  void _fail(Failure failure) => emit(state.copyWith(publishStatus: PublishStatus.failure, publishFailure: () => failure));

  /// Clears the form after a successful publish (keeps fields and language).
  void reset() {
    _created = null;
    _createdFrom = null;
    _attachmentsSent = false;
    emit(ComposerState(fieldsLoading: false, fields: state.fields, language: state.language));
  }
}
