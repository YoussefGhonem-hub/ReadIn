import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/models/transfer.dart';
import '../../domain/entities/media.dart';
import '../../domain/usecases/media_usecases.dart';

part 'attachments_state.dart';

/// Composer attachments (SPEC F26): 1–10 images **or** one PDF, each with
/// upload progress, cancel and retry; PDFs are polled every 2 s while the
/// server renders pages. Publishing is blocked while anything is busy, has
/// failed, or an image lacks alt text ([AttachmentsState.blockers]).
@injectable
class AttachmentsCubit extends Cubit<AttachmentsState> {
  AttachmentsCubit(
    this._pickImages,
    this._pickPdf,
    this._uploadImage,
    this._uploadDocument,
    this._getUpload,
    this._deleteUpload, {
    @ignoreParam this.pollInterval = const Duration(seconds: 2),
  }) : super(const AttachmentsState());

  final PickImages _pickImages;
  final PickPdf _pickPdf;
  final UploadImage _uploadImage;
  final UploadDocument _uploadDocument;
  final GetUpload _getUpload;
  final DeleteUpload _deleteUpload;

  /// How often `GET /uploads/{id}` is polled while a PDF is processing.
  final Duration pollInterval;

  /// Consecutive status-poll errors tolerated before giving up.
  static const maxPollErrors = 5;

  final _tokens = <String, TransferToken>{};
  final _pollTimers = <String, Timer>{};
  final _pollErrors = <String, int>{};
  int _ids = 0;

  String _nextId() => 'local-${++_ids}';

  // ── Images ────────────────────────────────────────────────

  Future<void> pickImages() async {
    if (!_canAddImages()) return;
    final files = await _pickImages(limit: state.remainingImages);
    if (!isClosed) addImages(files);
  }

  void addImages(List<PickedMediaFile> files) {
    if (files.isEmpty || !_canAddImages()) return;
    final accepted = files.take(state.remainingImages).toList();
    final drafts = [for (final f in accepted) ImageDraft(localId: _nextId(), file: f)];
    final next = state.copyWith(images: [...state.images, ...drafts]);
    emit(accepted.length < files.length ? next.withNotice(const Failure(FailureCodes.attachmentsTooManyImages)) : next);
    for (final d in drafts) {
      unawaited(_uploadImageDraft(d.localId));
    }
  }

  bool _canAddImages() {
    if (state.document != null) {
      _notice(FailureCodes.attachmentsMixedKinds);
      return false;
    }
    if (state.remainingImages <= 0) {
      _notice(FailureCodes.attachmentsTooManyImages);
      return false;
    }
    return true;
  }

  void setCaption(String localId, String caption) => _updateImage(
        localId,
        (d) => d.copyWith(caption: caption.length > AttachmentLimits.maxCaption ? caption.substring(0, AttachmentLimits.maxCaption) : caption),
      );

  void setAltText(String localId, String altText) => _updateImage(
        localId,
        (d) => d.copyWith(altText: altText.length > AttachmentLimits.maxAltText ? altText.substring(0, AttachmentLimits.maxAltText) : altText),
      );

  /// Moves an image from [from] to [to] (indices in the final list).
  void reorder(int from, int to) {
    final images = [...state.images];
    if (from < 0 || from >= images.length) return;
    final target = to.clamp(0, images.length - 1);
    if (target == from) return;
    images.insert(target, images.removeAt(from));
    emit(state.copyWith(images: images));
  }

  /// Accessible alternative to drag-and-drop: move one step earlier (-1) or later (+1).
  void move(String localId, int delta) {
    final index = state.images.indexWhere((i) => i.localId == localId);
    if (index >= 0) reorder(index, index + delta);
  }

  Future<void> _uploadImageDraft(String localId) async {
    final draft = _image(localId);
    if (draft == null) return;
    final token = _startTransfer(localId);
    _updateImage(localId, (d) => d.copyWith(phase: UploadPhase.preparing, progress: () => null, failure: () => null, asset: () => null));
    final result = await _uploadImage(draft.file, token: token, onProgress: _progressListener(localId, token));
    if (!_finishTransfer(localId, token) || _image(localId) == null) return;
    result.fold(
      (failure) => _setFailed(localId, failure),
      (asset) => _applyAsset(localId, asset),
    );
  }

  // ── PDF document ──────────────────────────────────────────

  Future<void> pickPdf() async {
    if (!_canAddDocument()) return;
    final file = await _pickPdf();
    if (file != null && !isClosed) setDocument(file);
  }

  void setDocument(PickedMediaFile file) {
    if (!_canAddDocument()) return;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      _notice(FailureCodes.mediaUnsupportedType);
      return;
    }
    if ((file.sizeBytes ?? 0) > AttachmentLimits.maxPdfBytes) {
      _notice(FailureCodes.mediaTooLarge);
      return;
    }
    final draft = DocumentDraft(localId: _nextId(), file: file, title: titleFromFileName(file.name));
    emit(state.copyWith(document: () => draft));
    unawaited(_uploadDocumentDraft(draft.localId));
  }

  bool _canAddDocument() {
    if (state.images.isNotEmpty) {
      _notice(FailureCodes.attachmentsMixedKinds);
      return false;
    }
    if (state.document != null) {
      _notice(FailureCodes.attachmentsSingleDocument);
      return false;
    }
    return true;
  }

  void setDocumentTitle(String title) {
    final doc = state.document;
    if (doc == null) return;
    final value = title.length > AttachmentLimits.maxDocumentTitle ? title.substring(0, AttachmentLimits.maxDocumentTitle) : title;
    emit(state.copyWith(document: () => doc.copyWith(title: value)));
  }

  void setAllowDownload(bool allow) {
    final doc = state.document;
    if (doc != null) emit(state.copyWith(document: () => doc.copyWith(allowDownload: allow)));
  }

  /// Pre-fills the required title: the file name without extension.
  static String titleFromFileName(String name) {
    final dot = name.lastIndexOf('.');
    final base = (dot > 0 ? name.substring(0, dot) : name).replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return base.length > AttachmentLimits.maxDocumentTitle ? base.substring(0, AttachmentLimits.maxDocumentTitle) : base;
  }

  Future<void> _uploadDocumentDraft(String localId) async {
    final draft = state.document;
    if (draft == null || draft.localId != localId) return;
    final token = _startTransfer(localId);
    _updateDocument(localId, (d) => d.copyWith(phase: UploadPhase.preparing, progress: () => null, failure: () => null, asset: () => null));
    final result = await _uploadDocument(
      draft.file,
      title: draft.title.trim().isEmpty ? titleFromFileName(draft.file.name) : draft.title.trim(),
      allowDownload: draft.allowDownload,
      token: token,
      onProgress: _progressListener(localId, token),
    );
    if (!_finishTransfer(localId, token) || state.document?.localId != localId) return;
    result.fold(
      (failure) => _setFailed(localId, failure),
      (asset) => _applyAsset(localId, asset),
    );
  }

  // ── Shared: cancel / retry / remove ───────────────────────

  /// Cancels a running upload; the tile stays with retry and remove.
  void cancel(String localId) {
    _tokens.remove(localId)?.cancel();
    if (_image(localId)?.phase case UploadPhase.preparing || UploadPhase.uploading) {
      _updateImage(localId, (d) => d.copyWith(phase: UploadPhase.cancelled, progress: () => null));
    } else if (state.document?.localId == localId &&
        (state.document!.phase == UploadPhase.preparing || state.document!.phase == UploadPhase.uploading)) {
      _updateDocument(localId, (d) => d.copyWith(phase: UploadPhase.cancelled, progress: () => null));
    }
  }

  /// Uploads the same file again after a failure, cancellation or failed processing.
  Future<void> retry(String localId) async {
    final image = _image(localId);
    final doc = state.document?.localId == localId ? state.document : null;
    final phase = image?.phase ?? doc?.phase;
    if (phase == null || !phase.isProblem) return;
    // A seeded attachment has no file on this device to upload again: remove it and add the file anew.
    if ((image?.file.path ?? doc?.file.path ?? '').isEmpty) return;
    _stopPolling(localId);
    final staleAsset = image?.asset?.id ?? doc?.asset?.id;
    if (staleAsset != null) unawaited(_deleteQuietly(staleAsset));
    if (image != null) {
      await _uploadImageDraft(localId);
    } else {
      await _uploadDocumentDraft(localId);
    }
  }

  /// Removes an attachment; an uploaded asset is deleted server-side
  /// (`DELETE /uploads/{id}`, failures ignored).
  void remove(String localId) {
    _tokens.remove(localId)?.cancel();
    _stopPolling(localId);
    final image = _image(localId);
    final doc = state.document?.localId == localId ? state.document : null;
    final assetId = image?.asset?.id ?? doc?.asset?.id;
    if (image != null) {
      emit(state.copyWith(images: [...state.images.where((i) => i.localId != localId)]));
    } else if (doc != null) {
      emit(state.copyWith(document: () => null));
    } else {
      return;
    }
    if (assetId != null) unawaited(_deleteQuietly(assetId));
  }

  /// Forgets everything after a successful publish: the assets now belong to
  /// the article, so nothing is deleted.
  void clear() {
    _cancelAll();
    emit(AttachmentsState(noticeSeq: state.noticeSeq));
  }

  /// Shows the attachments of an article being edited (F05): [items] are its `document.attachments` and [media]
  /// their uploads, already on the server. Processing PDFs are polled like fresh ones.
  void seed(List<AttachmentItem> items, List<MediaAsset> media) {
    _cancelAll();
    final byId = {for (final m in media) m.id: m};
    final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));
    final pdf = sorted.where((i) => i.title != null || byId[i.mediaAssetId]?.kind == MediaKind.document).firstOrNull;
    if (pdf != null) {
      final asset = byId[pdf.mediaAssetId] ??
          MediaAsset(id: pdf.mediaAssetId, kind: MediaKind.document, status: MediaStatus.ready, purpose: 'document');
      final name = asset.title ?? pdf.title ?? 'document.pdf';
      final draft = DocumentDraft(
        localId: _nextId(),
        file: PickedMediaFile(path: '', name: name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf', sizeBytes: asset.sizeBytes > 0 ? asset.sizeBytes : null),
        title: pdf.title ?? '',
        allowDownload: pdf.allowDownload ?? false,
        phase: _phaseOf(asset),
        asset: asset,
      );
      emit(AttachmentsState(document: draft, noticeSeq: state.noticeSeq));
    } else {
      final images = [
        for (final item in sorted.take(AttachmentLimits.maxImages))
          ImageDraft(
            localId: _nextId(),
            file: PickedMediaFile(path: '', name: item.mediaAssetId),
            asset: byId[item.mediaAssetId] ?? MediaAsset(id: item.mediaAssetId, kind: MediaKind.image, status: MediaStatus.ready),
            phase: _phaseOf(byId[item.mediaAssetId]),
            caption: item.caption ?? '',
            altText: item.altText ?? '',
          ),
      ];
      emit(AttachmentsState(images: images, noticeSeq: state.noticeSeq));
    }
    for (final (localId, asset) in [
      for (final i in state.images) (i.localId, i.asset),
      if (state.document != null) (state.document!.localId, state.document!.asset),
    ]) {
      if (asset != null && asset.isProcessing) _schedulePoll(localId, asset.id);
    }
  }

  static UploadPhase _phaseOf(MediaAsset? asset) => switch (asset?.status) {
        MediaStatus.failed => UploadPhase.failed,
        MediaStatus.uploading || MediaStatus.processing => UploadPhase.processing,
        _ => UploadPhase.ready,
      };

  // ── Internals ─────────────────────────────────────────────

  void _cancelAll() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
    for (final timer in _pollTimers.values) {
      timer.cancel();
    }
    _pollTimers.clear();
    _pollErrors.clear();
  }

  TransferToken _startTransfer(String localId) {
    _tokens.remove(localId)?.cancel();
    return _tokens[localId] = TransferToken();
  }

  /// True when the result of [token]'s transfer should still be applied.
  bool _finishTransfer(String localId, TransferToken token) {
    if (_tokens[localId] == token) _tokens.remove(localId);
    return !isClosed && !token.isCancelled;
  }

  TransferProgress _progressListener(String localId, TransferToken token) {
    var lastPercent = -1;
    return (sent, total) {
      if (isClosed || token.isCancelled || total <= 0) return;
      final value = (sent / total).clamp(0.0, 1.0);
      final percent = (value * 100).floor();
      if (percent == lastPercent) return;
      lastPercent = percent;
      if (_image(localId) != null) {
        _updateImage(localId, (d) => d.copyWith(phase: UploadPhase.uploading, progress: () => value));
      } else {
        _updateDocument(localId, (d) => d.copyWith(phase: UploadPhase.uploading, progress: () => value));
      }
    };
  }

  void _setFailed(String localId, Failure failure) {
    final phase = failure.code == FailureCodes.requestCancelled ? UploadPhase.cancelled : UploadPhase.failed;
    final keep = phase == UploadPhase.failed ? failure : null;
    if (_image(localId) != null) {
      _updateImage(localId, (d) => d.copyWith(phase: phase, progress: () => null, failure: () => keep));
    } else {
      _updateDocument(localId, (d) => d.copyWith(phase: phase, progress: () => null, failure: () => keep));
    }
  }

  void _applyAsset(String localId, MediaAsset asset) {
    final phase = switch (asset.status) {
      MediaStatus.ready => UploadPhase.ready,
      MediaStatus.failed => UploadPhase.failed,
      MediaStatus.uploading || MediaStatus.processing => UploadPhase.processing,
    };
    final failure = phase == UploadPhase.failed
        ? Failure(asset.failureReason ?? FailureCodes.mediaProcessingFailed)
        : null;
    if (_image(localId) != null) {
      _updateImage(localId, (d) => d.copyWith(phase: phase, progress: () => null, asset: () => asset, failure: () => failure));
    } else {
      _updateDocument(localId, (d) => d.copyWith(phase: phase, progress: () => null, asset: () => asset, failure: () => failure));
    }
    if (phase == UploadPhase.processing) {
      _schedulePoll(localId, asset.id);
    } else {
      _stopPolling(localId);
    }
  }

  void _schedulePoll(String localId, String assetId) {
    _pollTimers.remove(localId)?.cancel();
    _pollTimers[localId] = Timer(pollInterval, () => _poll(localId, assetId));
  }

  Future<void> _poll(String localId, String assetId) async {
    _pollTimers.remove(localId);
    if (!_isProcessing(localId, assetId)) return;
    final result = await _getUpload(assetId);
    if (!_isProcessing(localId, assetId)) return;
    result.fold(
      (failure) {
        final errors = _pollErrors[localId] = (_pollErrors[localId] ?? 0) + 1;
        if (errors >= maxPollErrors) {
          _pollErrors.remove(localId);
          _setFailed(localId, failure);
        } else {
          _schedulePoll(localId, assetId);
        }
      },
      (asset) {
        _pollErrors.remove(localId);
        _applyAsset(localId, asset);
      },
    );
  }

  bool _isProcessing(String localId, String assetId) {
    if (isClosed) return false;
    final image = _image(localId);
    final doc = state.document?.localId == localId ? state.document : null;
    final phase = image?.phase ?? doc?.phase;
    final asset = image?.asset ?? doc?.asset;
    return phase == UploadPhase.processing && asset?.id == assetId;
  }

  void _stopPolling(String localId) {
    _pollTimers.remove(localId)?.cancel();
    _pollErrors.remove(localId);
  }

  Future<void> _deleteQuietly(String assetId) async {
    try {
      await _deleteUpload(assetId);
    } on Object {
      // Ignored: an orphaned upload only counts toward the storage quota.
    }
  }

  ImageDraft? _image(String localId) {
    for (final i in state.images) {
      if (i.localId == localId) return i;
    }
    return null;
  }

  void _updateImage(String localId, ImageDraft Function(ImageDraft) update) {
    if (isClosed) return;
    final index = state.images.indexWhere((i) => i.localId == localId);
    if (index < 0) return;
    final updated = update(state.images[index]);
    if (updated == state.images[index]) return;
    final images = [...state.images];
    images[index] = updated;
    emit(state.copyWith(images: images));
  }

  void _updateDocument(String localId, DocumentDraft Function(DocumentDraft) update) {
    final doc = state.document;
    if (isClosed || doc == null || doc.localId != localId) return;
    final updated = update(doc);
    if (updated != doc) emit(state.copyWith(document: () => updated));
  }

  void _notice(String code) {
    if (!isClosed) emit(state.withNotice(Failure(code)));
  }

  /// Stops polling and cancels uploads when the composer closes.
  @override
  Future<void> close() {
    _cancelAll();
    return super.close();
  }
}

/// Upload progress as a whole percent, for labels.
int progressPercent(double? progress) => progress == null ? 0 : math.min(100, (progress * 100).round());
