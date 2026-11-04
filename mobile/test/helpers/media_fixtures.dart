import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/media/domain/entities/media.dart';

import 'fixtures.dart';

const _cdn = 'https://api.readin.test/uploads';

/// A valid 4×3 BlurHash (https://blurha.sh sample).
const sampleBlurHash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';

List<MediaVariant> variantsFor(String id, {int width = 1600, int height = 1200}) => [
      for (final w in const [320, 640, 1080, 1600])
        if (w <= width) MediaVariant(width: w, height: (w * height / width).round(), url: '$_cdn/$id/$w.webp', bytes: w * 90),
    ];

ImageAttachment sampleImage(int i, {String? caption, int width = 1600, int height = 1200}) => ImageAttachment(
      assetId: 'img-$i',
      order: i,
      caption: caption,
      altText: 'لقطة شاشة رقم ${i + 1} من Visual Studio',
      width: width,
      height: height,
      blurHash: sampleBlurHash,
      variants: variantsFor('img-$i', width: width, height: height),
    );

MediaPage samplePage(int n) => MediaPage(
      pageNo: n,
      width: 1080,
      height: 1528,
      blurHash: sampleBlurHash,
      thumbUrl: '$_cdn/doc-1/page-$n-400.webp',
      viewUrl: '$_cdn/doc-1/page-$n-1080.webp',
    );

DocumentAttachment sampleDocument({int pageCount = 12, int pages = 10, bool canDownload = true}) => DocumentAttachment(
      assetId: 'doc-1',
      title: 'Clean Architecture في .NET — ملخص',
      pageCount: pageCount,
      allowDownload: canDownload,
      canDownload: canDownload,
      downloadUrl: 'https://api.readin.test/api/v1/documents/doc-1/download',
      pages: [for (var n = 1; n <= pages; n++) samplePage(n)],
    );

ArticleCard cardWithImages(int count, {String language = 'ar-EG'}) {
  final base = sampleCard(1, language: language);
  return ArticleCard(
    id: base.id,
    slug: base.slug,
    language: base.language,
    title: base.title,
    field: base.field,
    author: base.author,
    readingTimeMinutes: base.readingTimeMinutes,
    publishedAt: base.publishedAt,
    reactionCount: base.reactionCount,
    commentCount: base.commentCount,
    attachments: ArticleAttachments(
      kind: AttachmentsKind.images,
      images: [
        for (var i = 0; i < count; i++) sampleImage(i, caption: i == 0 ? 'الـ DI container في Program.cs' : null),
      ],
    ),
  );
}

ArticleCard cardWithDocument({String language = 'ar-EG'}) {
  final base = sampleCard(2, language: language);
  return ArticleCard(
    id: base.id,
    slug: base.slug,
    language: base.language,
    title: base.title,
    field: base.field,
    author: base.author,
    readingTimeMinutes: base.readingTimeMinutes,
    publishedAt: base.publishedAt,
    reactionCount: base.reactionCount,
    commentCount: base.commentCount,
    attachments: ArticleAttachments(kind: AttachmentsKind.document, document: sampleDocument()),
  );
}

MediaAsset imageAsset(String id) => MediaAsset(
      id: id,
      kind: MediaKind.image,
      status: MediaStatus.ready,
      width: 1600,
      height: 1200,
      blurHash: sampleBlurHash,
      sizeBytes: 480000,
      variants: variantsFor(id),
    );

MediaAsset documentAsset({required MediaStatus status, int pagesReady = 0, int pageCount = 12, String? failureReason}) =>
    MediaAsset(
      id: 'doc-asset',
      kind: MediaKind.document,
      purpose: 'document',
      status: status,
      failureReason: failureReason,
      width: 1080,
      height: 1528,
      sizeBytes: 2400000,
      title: 'slides',
      pageCount: pageCount,
      pagesReady: pagesReady,
      pages: [for (var n = 1; n <= pagesReady; n++) samplePage(n)],
    );

const sampleImageFile = PickedMediaFile(path: '/tmp/photo-1.jpg', name: 'photo-1.jpg', sizeBytes: 3200000);
const sampleImageFile2 = PickedMediaFile(path: '/tmp/photo-2.heic', name: 'photo-2.heic', sizeBytes: 2100000);
const samplePdfFile = PickedMediaFile(path: '/tmp/clean_architecture_notes.pdf', name: 'clean_architecture_notes.pdf', sizeBytes: 2400000);
