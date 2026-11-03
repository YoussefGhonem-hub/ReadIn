part of 'attachments_cubit.dart';

/// Lifecycle of one attachment in the composer.
enum UploadPhase {
  /// Compressing on the device / opening the file.
  preparing,
  uploading,

  /// Uploaded; the server is rendering PDF pages (polled every 2 s).
  processing,
  ready,
  failed,
  cancelled,
}

extension UploadPhaseX on UploadPhase {
  bool get isBusy => this == UploadPhase.preparing || this == UploadPhase.uploading || this == UploadPhase.processing;

  bool get isProblem => this == UploadPhase.failed || this == UploadPhase.cancelled;
}

class ImageDraft extends Equatable {
  const ImageDraft({
    required this.localId,
    required this.file,
    this.phase = UploadPhase.preparing,
    this.progress,
    this.asset,
    this.failure,
    this.caption = '',
    this.altText = '',
  });

  final String localId;
  final PickedMediaFile file;
  final UploadPhase phase;

  /// 0..1 while uploading; null = indeterminate.
  final double? progress;
  final MediaAsset? asset;
  final Failure? failure;
  final String caption;
  final String altText;

  bool get hasAltText => altText.trim().isNotEmpty;

  ImageDraft copyWith({
    UploadPhase? phase,
    double? Function()? progress,
    MediaAsset? Function()? asset,
    Failure? Function()? failure,
    String? caption,
    String? altText,
  }) =>
      ImageDraft(
        localId: localId,
        file: file,
        phase: phase ?? this.phase,
        progress: progress != null ? progress() : this.progress,
        asset: asset != null ? asset() : this.asset,
        failure: failure != null ? failure() : this.failure,
        caption: caption ?? this.caption,
        altText: altText ?? this.altText,
      );

  @override
  List<Object?> get props => [localId, file, phase, progress, asset, failure, caption, altText];
}

class DocumentDraft extends Equatable {
  const DocumentDraft({
    required this.localId,
    required this.file,
    required this.title,
    this.allowDownload = false,
    this.phase = UploadPhase.preparing,
    this.progress,
    this.asset,
    this.failure,
  });

  final String localId;
  final PickedMediaFile file;

  /// Required, pre-filled from the file name.
  final String title;

  /// "Allow download", off by default.
  final bool allowDownload;
  final UploadPhase phase;
  final double? progress;
  final MediaAsset? asset;
  final Failure? failure;

  int? get pageCount => asset?.pageCount;
  int get pagesReady => asset?.pagesReady ?? 0;
  List<MediaPage> get pages => asset?.pages ?? const [];
  bool get hasTitle => title.trim().isNotEmpty;

  DocumentDraft copyWith({
    String? title,
    bool? allowDownload,
    UploadPhase? phase,
    double? Function()? progress,
    MediaAsset? Function()? asset,
    Failure? Function()? failure,
  }) =>
      DocumentDraft(
        localId: localId,
        file: file,
        title: title ?? this.title,
        allowDownload: allowDownload ?? this.allowDownload,
        phase: phase ?? this.phase,
        progress: progress != null ? progress() : this.progress,
        asset: asset != null ? asset() : this.asset,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [localId, file, title, allowDownload, phase, progress, asset, failure];
}

/// Why publishing is blocked by the attachments.
enum AttachmentBlocker { busy, failed, altText, documentTitle }

class AttachmentsState extends Equatable {
  const AttachmentsState({this.images = const [], this.document, this.notice, this.noticeSeq = 0});

  final List<ImageDraft> images;
  final DocumentDraft? document;

  /// A rejected action to explain once (e.g. `attachments.mixed_kinds`);
  /// [noticeSeq] changes every time one is raised.
  final Failure? notice;
  final int noticeSeq;

  bool get isEmpty => images.isEmpty && document == null;
  int get remainingImages => AttachmentLimits.maxImages - images.length;

  /// Images and a PDF can't be mixed (SPEC F26).
  bool get canAddImages => document == null && remainingImages > 0;
  bool get canAddDocument => images.isEmpty && document == null;

  List<AttachmentBlocker> get blockers {
    final phases = [for (final i in images) i.phase, if (document != null) document!.phase];
    return [
      if (phases.any((p) => p.isBusy)) AttachmentBlocker.busy,
      if (phases.any((p) => p.isProblem)) AttachmentBlocker.failed,
      if (images.any((i) => !i.hasAltText)) AttachmentBlocker.altText,
      if (document != null && !document!.hasTitle) AttachmentBlocker.documentTitle,
    ];
  }

  bool get canPublish => blockers.isEmpty;

  /// `SetAttachmentsRequest.items` in display order (0-based `order`).
  List<AttachmentItem> get requestItems {
    final doc = document;
    if (doc != null) {
      final asset = doc.asset;
      if (asset == null || doc.phase != UploadPhase.ready) return const [];
      return [AttachmentItem(mediaAssetId: asset.id, order: 0, title: doc.title.trim(), allowDownload: doc.allowDownload)];
    }
    return [
      for (final (i, image) in images.indexed)
        if (image.asset != null && image.phase == UploadPhase.ready)
          AttachmentItem(
            mediaAssetId: image.asset!.id,
            order: i,
            caption: image.caption.trim().isEmpty ? null : image.caption.trim(),
            altText: image.altText.trim(),
          ),
    ];
  }

  AttachmentsState copyWith({List<ImageDraft>? images, DocumentDraft? Function()? document}) => AttachmentsState(
        images: images ?? this.images,
        document: document != null ? document() : this.document,
        noticeSeq: noticeSeq,
      );

  AttachmentsState withNotice(Failure notice) =>
      AttachmentsState(images: images, document: document, notice: notice, noticeSeq: noticeSeq + 1);

  @override
  List<Object?> get props => [images, document, notice, noticeSeq];
}
