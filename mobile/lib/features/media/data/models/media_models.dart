import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/media.dart';

part 'media_models.freezed.dart';
part 'media_models.g.dart';

/// `MediaVariantDto`.
@freezed
abstract class MediaVariantModel with _$MediaVariantModel {
  const MediaVariantModel._();

  const factory MediaVariantModel({
    required int width,
    required int height,
    required String url,
    @Default(0) int bytes,
  }) = _MediaVariantModel;

  factory MediaVariantModel.fromJson(Map<String, dynamic> json) => _$MediaVariantModelFromJson(json);

  MediaVariant toEntity() => MediaVariant(width: width, height: height, url: url, bytes: bytes);
}

/// `MediaPageDto`.
@freezed
abstract class MediaPageModel with _$MediaPageModel {
  const MediaPageModel._();

  const factory MediaPageModel({
    required int pageNo,
    required int width,
    required int height,
    String? blurHash,
    required String thumbUrl,
    required String viewUrl,
  }) = _MediaPageModel;

  factory MediaPageModel.fromJson(Map<String, dynamic> json) => _$MediaPageModelFromJson(json);

  MediaPage toEntity() => MediaPage(
        pageNo: pageNo,
        width: width,
        height: height,
        blurHash: blurHash,
        thumbUrl: thumbUrl,
        viewUrl: viewUrl,
      );
}

/// `MediaAssetDto`.
@freezed
abstract class MediaAssetModel with _$MediaAssetModel {
  const MediaAssetModel._();

  const factory MediaAssetModel({
    required String id,
    @Default('image') String kind,
    @Default('image') String purpose,
    @Default('processing') String status,
    String? failureReason,
    int? width,
    int? height,
    String? blurHash,
    @Default(0) int sizeBytes,
    @Default(<MediaVariantModel>[]) List<MediaVariantModel> variants,
    String? title,
    int? pageCount,
    @Default(0) int pagesReady,
    @Default(<MediaPageModel>[]) List<MediaPageModel> pages,
    @Default(false) bool allowDownload,
    DateTime? createdAt,
  }) = _MediaAssetModel;

  factory MediaAssetModel.fromJson(Map<String, dynamic> json) => _$MediaAssetModelFromJson(json);

  MediaAsset toEntity() => MediaAsset(
        id: id,
        kind: kind == 'document' ? MediaKind.document : MediaKind.image,
        purpose: purpose,
        status: switch (status) {
          'uploading' => MediaStatus.uploading,
          'processing' => MediaStatus.processing,
          'ready' => MediaStatus.ready,
          _ => MediaStatus.failed,
        },
        failureReason: failureReason,
        width: width,
        height: height,
        blurHash: blurHash,
        sizeBytes: sizeBytes,
        variants: [for (final v in variants) v.toEntity()]..sort((a, b) => a.width.compareTo(b.width)),
        title: title,
        pageCount: pageCount,
        pagesReady: pagesReady,
        pages: [for (final p in pages) p.toEntity()],
        allowDownload: allowDownload,
      );
}

/// `ImageAttachmentDto`.
@freezed
abstract class ImageAttachmentModel with _$ImageAttachmentModel {
  const ImageAttachmentModel._();

  const factory ImageAttachmentModel({
    required String assetId,
    @Default(0) int order,
    String? caption,
    @Default('') String altText,
    @Default(0) int width,
    @Default(0) int height,
    String? blurHash,
    @Default(<MediaVariantModel>[]) List<MediaVariantModel> variants,
  }) = _ImageAttachmentModel;

  factory ImageAttachmentModel.fromJson(Map<String, dynamic> json) => _$ImageAttachmentModelFromJson(json);

  ImageAttachment toEntity() => ImageAttachment(
        assetId: assetId,
        order: order,
        caption: caption,
        altText: altText,
        width: width,
        height: height,
        blurHash: blurHash,
        variants: [for (final v in variants) v.toEntity()]..sort((a, b) => a.width.compareTo(b.width)),
      );
}

/// `DocumentAttachmentDto`.
@freezed
abstract class DocumentAttachmentModel with _$DocumentAttachmentModel {
  const DocumentAttachmentModel._();

  const factory DocumentAttachmentModel({
    required String assetId,
    required String title,
    @Default(0) int pageCount,
    @Default(false) bool allowDownload,
    @Default(false) bool canDownload,
    @Default('') String downloadUrl,
    @Default(<MediaPageModel>[]) List<MediaPageModel> pages,
  }) = _DocumentAttachmentModel;

  factory DocumentAttachmentModel.fromJson(Map<String, dynamic> json) => _$DocumentAttachmentModelFromJson(json);

  DocumentAttachment toEntity() => DocumentAttachment(
        assetId: assetId,
        title: title,
        pageCount: pageCount < pages.length ? pages.length : pageCount,
        allowDownload: allowDownload,
        canDownload: canDownload,
        downloadUrl: downloadUrl,
        pages: [for (final p in pages) p.toEntity()],
      );
}

/// `ArticleAttachmentsDto`.
@freezed
abstract class ArticleAttachmentsModel with _$ArticleAttachmentsModel {
  const ArticleAttachmentsModel._();

  const factory ArticleAttachmentsModel({
    @Default('images') String kind,
    @Default(<ImageAttachmentModel>[]) List<ImageAttachmentModel> images,
    DocumentAttachmentModel? document,
  }) = _ArticleAttachmentsModel;

  factory ArticleAttachmentsModel.fromJson(Map<String, dynamic> json) => _$ArticleAttachmentsModelFromJson(json);

  /// Null when the set is empty, so cards without attachments stay unchanged.
  ArticleAttachments? toEntity() {
    final entity = kind == 'document'
        ? ArticleAttachments(kind: AttachmentsKind.document, document: document?.toEntity())
        : ArticleAttachments(
            kind: AttachmentsKind.images,
            images: [for (final i in images) i.toEntity()]..sort((a, b) => a.order.compareTo(b.order)),
          );
    return entity.isEmpty ? null : entity;
  }
}

/// `SetAttachmentsRequest`.
@freezed
abstract class SetAttachmentsRequestModel with _$SetAttachmentsRequestModel {
  const factory SetAttachmentsRequestModel({required List<AttachmentItemModel> items}) = _SetAttachmentsRequestModel;

  factory SetAttachmentsRequestModel.fromJson(Map<String, dynamic> json) => _$SetAttachmentsRequestModelFromJson(json);

  factory SetAttachmentsRequestModel.fromEntities(List<AttachmentItem> items) => SetAttachmentsRequestModel(
        items: [
          for (final i in items)
            AttachmentItemModel(
              mediaAssetId: i.mediaAssetId,
              order: i.order,
              caption: i.caption,
              altText: i.altText,
              title: i.title,
              allowDownload: i.allowDownload,
            ),
        ],
      );
}

@freezed
abstract class AttachmentItemModel with _$AttachmentItemModel {
  const factory AttachmentItemModel({
    required String mediaAssetId,
    required int order,
    String? caption,
    String? altText,
    String? title,
    bool? allowDownload,
  }) = _AttachmentItemModel;

  factory AttachmentItemModel.fromJson(Map<String, dynamic> json) => _$AttachmentItemModelFromJson(json);
}
