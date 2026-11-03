// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaVariantModel _$MediaVariantModelFromJson(Map<String, dynamic> json) =>
    _MediaVariantModel(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      url: json['url'] as String,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MediaVariantModelToJson(_MediaVariantModel instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'url': instance.url,
      'bytes': instance.bytes,
    };

_MediaPageModel _$MediaPageModelFromJson(Map<String, dynamic> json) =>
    _MediaPageModel(
      pageNo: (json['pageNo'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      blurHash: json['blurHash'] as String?,
      thumbUrl: json['thumbUrl'] as String,
      viewUrl: json['viewUrl'] as String,
    );

Map<String, dynamic> _$MediaPageModelToJson(_MediaPageModel instance) =>
    <String, dynamic>{
      'pageNo': instance.pageNo,
      'width': instance.width,
      'height': instance.height,
      'blurHash': ?instance.blurHash,
      'thumbUrl': instance.thumbUrl,
      'viewUrl': instance.viewUrl,
    };

_MediaAssetModel _$MediaAssetModelFromJson(Map<String, dynamic> json) =>
    _MediaAssetModel(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'image',
      purpose: json['purpose'] as String? ?? 'image',
      status: json['status'] as String? ?? 'processing',
      failureReason: json['failureReason'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      blurHash: json['blurHash'] as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map(
                (e) => MediaVariantModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <MediaVariantModel>[],
      title: json['title'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
      pagesReady: (json['pagesReady'] as num?)?.toInt() ?? 0,
      pages:
          (json['pages'] as List<dynamic>?)
              ?.map((e) => MediaPageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MediaPageModel>[],
      allowDownload: json['allowDownload'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MediaAssetModelToJson(_MediaAssetModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'purpose': instance.purpose,
      'status': instance.status,
      'failureReason': ?instance.failureReason,
      'width': ?instance.width,
      'height': ?instance.height,
      'blurHash': ?instance.blurHash,
      'sizeBytes': instance.sizeBytes,
      'variants': instance.variants.map((e) => e.toJson()).toList(),
      'title': ?instance.title,
      'pageCount': ?instance.pageCount,
      'pagesReady': instance.pagesReady,
      'pages': instance.pages.map((e) => e.toJson()).toList(),
      'allowDownload': instance.allowDownload,
      'createdAt': ?instance.createdAt?.toIso8601String(),
    };

_ImageAttachmentModel _$ImageAttachmentModelFromJson(
  Map<String, dynamic> json,
) => _ImageAttachmentModel(
  assetId: json['assetId'] as String,
  order: (json['order'] as num?)?.toInt() ?? 0,
  caption: json['caption'] as String?,
  altText: json['altText'] as String? ?? '',
  width: (json['width'] as num?)?.toInt() ?? 0,
  height: (json['height'] as num?)?.toInt() ?? 0,
  blurHash: json['blurHash'] as String?,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => MediaVariantModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MediaVariantModel>[],
);

Map<String, dynamic> _$ImageAttachmentModelToJson(
  _ImageAttachmentModel instance,
) => <String, dynamic>{
  'assetId': instance.assetId,
  'order': instance.order,
  'caption': ?instance.caption,
  'altText': instance.altText,
  'width': instance.width,
  'height': instance.height,
  'blurHash': ?instance.blurHash,
  'variants': instance.variants.map((e) => e.toJson()).toList(),
};

_DocumentAttachmentModel _$DocumentAttachmentModelFromJson(
  Map<String, dynamic> json,
) => _DocumentAttachmentModel(
  assetId: json['assetId'] as String,
  title: json['title'] as String,
  pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
  allowDownload: json['allowDownload'] as bool? ?? false,
  canDownload: json['canDownload'] as bool? ?? false,
  downloadUrl: json['downloadUrl'] as String? ?? '',
  pages:
      (json['pages'] as List<dynamic>?)
          ?.map((e) => MediaPageModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MediaPageModel>[],
);

Map<String, dynamic> _$DocumentAttachmentModelToJson(
  _DocumentAttachmentModel instance,
) => <String, dynamic>{
  'assetId': instance.assetId,
  'title': instance.title,
  'pageCount': instance.pageCount,
  'allowDownload': instance.allowDownload,
  'canDownload': instance.canDownload,
  'downloadUrl': instance.downloadUrl,
  'pages': instance.pages.map((e) => e.toJson()).toList(),
};

_ArticleAttachmentsModel _$ArticleAttachmentsModelFromJson(
  Map<String, dynamic> json,
) => _ArticleAttachmentsModel(
  kind: json['kind'] as String? ?? 'images',
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => ImageAttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ImageAttachmentModel>[],
  document: json['document'] == null
      ? null
      : DocumentAttachmentModel.fromJson(
          json['document'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ArticleAttachmentsModelToJson(
  _ArticleAttachmentsModel instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'images': instance.images.map((e) => e.toJson()).toList(),
  'document': ?instance.document?.toJson(),
};

_SetAttachmentsRequestModel _$SetAttachmentsRequestModelFromJson(
  Map<String, dynamic> json,
) => _SetAttachmentsRequestModel(
  items: (json['items'] as List<dynamic>)
      .map((e) => AttachmentItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SetAttachmentsRequestModelToJson(
  _SetAttachmentsRequestModel instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

_AttachmentItemModel _$AttachmentItemModelFromJson(Map<String, dynamic> json) =>
    _AttachmentItemModel(
      mediaAssetId: json['mediaAssetId'] as String,
      order: (json['order'] as num).toInt(),
      caption: json['caption'] as String?,
      altText: json['altText'] as String?,
      title: json['title'] as String?,
      allowDownload: json['allowDownload'] as bool?,
    );

Map<String, dynamic> _$AttachmentItemModelToJson(
  _AttachmentItemModel instance,
) => <String, dynamic>{
  'mediaAssetId': instance.mediaAssetId,
  'order': instance.order,
  'caption': ?instance.caption,
  'altText': ?instance.altText,
  'title': ?instance.title,
  'allowDownload': ?instance.allowDownload,
};
