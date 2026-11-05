import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/media/media_carousel.dart';
import '../../../../shared/media/media_image.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/presentation/media_items.dart';
import '../../domain/entities/article.dart';
import 'attachment_viewers.dart';

/// Post attachments under a feed card or after the article content (F26):
/// one image full width, 2+ images in the carousel, a PDF as a header strip
/// plus page carousel with a "+N pages" card. Taps open the full-screen viewer.
class ArticleAttachmentsView extends StatelessWidget {
  const ArticleAttachmentsView({super.key, required this.article});

  final ArticleCard article;

  /// Single images keep their own ratio, clamped like LinkedIn's feed.
  static const minAspect = 4 / 5;
  static const maxAspect = 1.91;

  static double clampAspect(double ratio) => ratio.clamp(minAspect, maxAspect);

  @override
  Widget build(BuildContext context) {
    final attachments = article.attachments;
    if (attachments == null) return const SizedBox.shrink();
    return switch (attachments.kind) {
      AttachmentsKind.images when attachments.images.length == 1 => _SingleImage(article: article, image: attachments.images.first),
      AttachmentsKind.images => _ImageCarousel(article: article, images: attachments.images),
      AttachmentsKind.document when attachments.document != null => _DocumentBlock(article: article, document: attachments.document!),
      AttachmentsKind.document => const SizedBox.shrink(),
    };
  }
}

class _SingleImage extends StatelessWidget {
  const _SingleImage({required this.article, required this.image});

  final ArticleCard article;
  final ImageAttachment image;

  @override
  Widget build(BuildContext context) {
    final item = MediaItems.image(image);
    final label = context.l10n.viewerImageOf(1, 1);
    void open() => openImageViewer(context, article: article, images: [image], index: 0);
    return Semantics(
      label: image.altText.trim().isEmpty ? label : '$label. ${image.altText.trim()}',
      button: true,
      onTap: open,
      excludeSemantics: true,
      child: MediaCard(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: ArticleAttachmentsView.clampAspect(image.aspectRatio),
              child: MediaImage(sources: item.sources, blurHash: item.blurHash),
            ),
            if (item.hasCaption) MediaCaptionBar(caption: item.caption),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.article, required this.images});

  final ArticleCard article;
  final List<ImageAttachment> images;

  @override
  Widget build(BuildContext context) => MediaCarousel(
        items: [for (final i in images) MediaItems.image(i)],
        aspectRatio: 1,
        semanticLabel: (index, total) => imageSlideLabel(context, index, total),
        onTap: (index) => openImageViewer(context, article: article, images: images, index: index),
      );
}

class _DocumentBlock extends StatelessWidget {
  const _DocumentBlock({required this.article, required this.document});

  final ArticleCard article;
  final DocumentAttachment document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = document.pages;
    final remaining = document.pageCount - pages.length;
    void open(int index) => openDocumentViewer(context, article: article, document: document, index: index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentHeader(article: article, document: document, onTap: () => open(0)),
        if (pages.isNotEmpty) ...[
          const SizedBox(height: ReadInSpace.s2),
          MediaCarousel(
            items: [for (final p in pages) MediaItems.pageThumb(p)],
            aspectRatio: pages.first.aspectRatio,
            counterTotal: document.pageCount,
            showCaptions: false,
            semanticLabel: (index, total) => pageSlideLabel(context, index, total),
            onTap: open,
            trailing: remaining > 0
                ? Semantics(
                    button: true,
                    label: l10n.pdfMorePages(remaining),
                    onTap: () => open(pages.length),
                    excludeSemantics: true,
                    child: MediaCard(
                      onTap: () => open(pages.length),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(ReadInSpace.s4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📄', style: TextStyle(fontSize: 32)),
                              const SizedBox(height: ReadInSpace.s2),
                              Text(
                                l10n.pdfMorePages(remaining),
                                textAlign: TextAlign.center,
                                style: context.textTheme.titleSmall?.copyWith(color: context.colors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ],
    );
  }
}

/// "📄 {title} · 12 pages", opening the viewer, then the download icon when the caller may download the file
/// ([DocumentDownloadButton]): a separate button, so screen readers reach both.
class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.article, required this.document, required this.onTap});

  final ArticleCard article;
  final DocumentAttachment document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final title = Bidi.isolateOppositeRuns(document.title, Directionality.of(context));
    final pages = l10n.pdfPageCount(document.pageCount);
    final radius = BorderRadius.circular(ReadInRadius.md);
    return Material(
      color: colors.primaryContainer,
      borderRadius: radius,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '${l10n.openDocument}: ${document.title}, $pages',
              onTap: onTap,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: ConstrainedBox(
                  // A 48 px target, the download icon's height too: the strip keeps its height with or without it.
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
                    child: Row(
                      children: [
                        const Text('📄'),
                        const SizedBox(width: ReadInSpace.s2),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              TextSpan(text: ' · $pages'),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
                          ),
                        ),
                        Icon(Icons.open_in_full_rounded, size: 16, color: colors.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (document.canDownload) ...[
            Container(width: 1, height: 24, color: colors.onPrimaryContainer.withValues(alpha: 0.2)),
            DocumentDownloadButton(article: article, document: document, color: colors.onPrimaryContainer),
          ],
        ],
      ),
    );
  }
}
