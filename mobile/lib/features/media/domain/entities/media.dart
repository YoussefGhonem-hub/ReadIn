import 'package:equatable/equatable.dart';

/// Post attachment rules (SPEC F26, docs/api/contract-v1.md "Media").
abstract final class AttachmentLimits {
  static const maxImages = 10;
  static const maxPdfBytes = 20 * 1024 * 1024;
  // Same limits as the API (Article.MaxCaptionLength / MaxAltTextLength, MediaAsset.MaxTitleLength).
  static const maxCaption = 5000;
  static const maxAltText = 5000;
  static const maxDocumentTitle = 5000;

  /// The character counter of these fields appears only this close to the limit.
  static const counterWithin = 500;
}

enum MediaKind { image, document }

enum MediaStatus { uploading, processing, ready, failed }

/// One responsive WebP rendition (`MediaVariantDto`). URLs are absolute.
class MediaVariant extends Equatable {
  const MediaVariant({required this.width, required this.height, required this.url, this.bytes = 0});

  final int width;
  final int height;
  final String url;
  final int bytes;

  @override
  List<Object?> get props => [width, height, url, bytes];
}

/// A rendered PDF page (`MediaPageDto`): a 400 px thumb and a 1080 px view.
class MediaPage extends Equatable {
  const MediaPage({
    required this.pageNo,
    required this.width,
    required this.height,
    required this.thumbUrl,
    required this.viewUrl,
    this.blurHash,
  });

  static const thumbWidth = 400;

  final int pageNo;

  /// Size of the view rendition.
  final int width;
  final int height;
  final String? blurHash;
  final String thumbUrl;
  final String viewUrl;

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1 / 1.414;

  @override
  List<Object?> get props => [pageNo, width, height, blurHash, thumbUrl, viewUrl];
}

/// An uploaded file (`MediaAssetDto`).
class MediaAsset extends Equatable {
  const MediaAsset({
    required this.id,
    required this.kind,
    required this.status,
    this.purpose = 'image',
    this.failureReason,
    this.width,
    this.height,
    this.blurHash,
    this.sizeBytes = 0,
    this.variants = const [],
    this.title,
    this.pageCount,
    this.pagesReady = 0,
    this.pages = const [],
    this.allowDownload = false,
  });

  final String id;
  final MediaKind kind;
  final String purpose;
  final MediaStatus status;

  /// Stable error code when [status] is failed, e.g. `media.processing_timeout`.
  final String? failureReason;
  final int? width;
  final int? height;
  final String? blurHash;
  final int sizeBytes;

  /// Images, ascending width.
  final List<MediaVariant> variants;
  final String? title;
  final int? pageCount;
  final int pagesReady;
  final List<MediaPage> pages;
  final bool allowDownload;

  bool get isProcessing => status == MediaStatus.processing || status == MediaStatus.uploading;

  @override
  List<Object?> get props => [
        id,
        kind,
        purpose,
        status,
        failureReason,
        width,
        height,
        blurHash,
        sizeBytes,
        variants,
        title,
        pageCount,
        pagesReady,
        pages,
        allowDownload,
      ];
}

/// `ImageAttachmentDto`.
class ImageAttachment extends Equatable {
  const ImageAttachment({
    required this.assetId,
    required this.altText,
    required this.width,
    required this.height,
    required this.variants,
    this.order = 0,
    this.caption,
    this.blurHash,
  });

  final String assetId;
  final int order;

  /// ≤ 5000 characters, rendered with `dir="auto"`.
  final String? caption;
  final String altText;
  final int width;
  final int height;
  final String? blurHash;
  final List<MediaVariant> variants;

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1;

  @override
  List<Object?> get props => [assetId, order, caption, altText, width, height, blurHash, variants];
}

/// `DocumentAttachmentDto`.
class DocumentAttachment extends Equatable {
  const DocumentAttachment({
    required this.assetId,
    required this.title,
    required this.pageCount,
    required this.downloadUrl,
    required this.pages,
    this.allowDownload = false,
    this.canDownload = false,
  });

  final String assetId;
  final String title;
  final int pageCount;

  /// The author's setting.
  final bool allowDownload;

  /// For the current caller: [allowDownload], or owner / moderator.
  final bool canDownload;

  /// `GET /documents/{assetId}/download` (absolute).
  final String downloadUrl;

  /// Rendered pages in order. Feed cards carry at most the first 10.
  final List<MediaPage> pages;

  bool get hasAllPages => pages.length >= pageCount;

  DocumentAttachment copyWith({List<MediaPage>? pages, bool? canDownload}) => DocumentAttachment(
        assetId: assetId,
        title: title,
        pageCount: pageCount,
        downloadUrl: downloadUrl,
        pages: pages ?? this.pages,
        allowDownload: allowDownload,
        canDownload: canDownload ?? this.canDownload,
      );

  @override
  List<Object?> get props => [assetId, title, pageCount, allowDownload, canDownload, downloadUrl, pages];
}

enum AttachmentsKind { images, document }

/// `ArticleAttachmentsDto`: either 1–10 images or exactly one PDF, never both.
class ArticleAttachments extends Equatable {
  const ArticleAttachments({required this.kind, this.images = const [], this.document});

  final AttachmentsKind kind;
  final List<ImageAttachment> images;
  final DocumentAttachment? document;

  bool get isEmpty => kind == AttachmentsKind.images ? images.isEmpty : document == null;

  @override
  List<Object?> get props => [kind, images, document];
}

/// One `SetAttachmentsRequest` item.
class AttachmentItem extends Equatable {
  const AttachmentItem({
    required this.mediaAssetId,
    required this.order,
    this.caption,
    this.altText,
    this.title,
    this.allowDownload,
  });

  final String mediaAssetId;
  final int order;
  final String? caption;
  final String? altText;
  final String? title;
  final bool? allowDownload;

  @override
  List<Object?> get props => [mediaAssetId, order, caption, altText, title, allowDownload];
}

/// A safe local file name for a downloaded PDF: keeps letters (any script),
/// digits, spaces, `.`, `-`, `_`; always ends in `.pdf`.
String pdfFileName(String title) {
  var base = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
  if (base.toLowerCase().endsWith('.pdf')) base = base.substring(0, base.length - 4);
  if (base.isEmpty) base = 'document';
  if (base.length > 80) base = base.substring(0, 80);
  return '$base.pdf';
}

/// A file chosen on the device, before upload.
class PickedMediaFile extends Equatable {
  const PickedMediaFile({required this.path, required this.name, this.sizeBytes});

  final String path;

  /// File name with extension, e.g. `slides.pdf`.
  final String name;
  final int? sizeBytes;

  @override
  List<Object?> get props => [path, name, sizeBytes];
}
