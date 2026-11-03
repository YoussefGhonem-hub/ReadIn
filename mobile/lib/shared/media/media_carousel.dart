import 'package:flutter/material.dart';

import '../../core/bidi/bidi.dart';
import '../../core/l10n/l10n_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';
import 'media_image.dart';
import 'media_item.dart';

/// LinkedIn-style carousel for post images and PDF pages (SPEC F26):
/// horizontal paging with snap, 12 px slide cards, the next slide peeking
/// ~15 % from the trailing edge, a "3 / 12" counter on the current slide and
/// an optional one-line caption bar under image slides.
///
/// Follows the UI direction: in Arabic the first slide sits on the right and
/// swiping right moves forward. Slides are built lazily and only the ones
/// within [loadRadius] of the current page load real images; the others keep
/// their BlurHash placeholder.
class MediaCarousel extends StatefulWidget {
  const MediaCarousel({
    super.key,
    required this.items,
    required this.aspectRatio,
    required this.semanticLabel,
    this.counterTotal,
    this.onTap,
    this.trailing,
    this.showCaptions = true,
    this.viewportFraction = defaultViewportFraction,
    this.loadRadius = 1,
  });

  static const defaultViewportFraction = 0.85;
  static const gap = ReadInSpace.s2;
  static const captionBarHeight = 36.0;

  final List<MediaItem> items;

  /// Width / height of every slide's media area.
  final double aspectRatio;

  /// Screen-reader label for slide `index` (0-based) of `total`, e.g. "Page 3 of 12".
  final String Function(int index, int total) semanticLabel;

  /// Total shown in the counter (a PDF's page count may exceed [items]).
  final int? counterTotal;
  final ValueChanged<int>? onTap;

  /// Extra last slide, e.g. "+2 pages, open document".
  final Widget? trailing;
  final bool showCaptions;
  final double viewportFraction;
  final int loadRadius;

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  late final PageController _controller = PageController(viewportFraction: widget.viewportFraction);
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _slideCount => widget.items.length + (widget.trailing == null ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final hasCaptions = widget.showCaptions && widget.items.any((i) => i.hasCaption);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * widget.viewportFraction - MediaCarousel.gap;
        final mediaHeight = cardWidth / widget.aspectRatio;
        final height = mediaHeight + (hasCaptions ? MediaCarousel.captionBarHeight : 0);
        return SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: _slideCount,
            onPageChanged: (page) => setState(() => _current = page),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsetsDirectional.only(end: MediaCarousel.gap),
              child: index < widget.items.length
                  ? _Slide(
                      key: ValueKey('carousel-slide-$index'),
                      item: widget.items[index],
                      index: index,
                      total: widget.counterTotal ?? widget.items.length,
                      current: index == _current,
                      load: (index - _current).abs() <= widget.loadRadius,
                      mediaHeight: mediaHeight,
                      captionBar: hasCaptions,
                      semanticLabel: widget.semanticLabel(index, widget.counterTotal ?? widget.items.length),
                      onTap: widget.onTap == null ? null : () => widget.onTap!(index),
                    )
                  : KeyedSubtree(key: const ValueKey('carousel-slide-trailing'), child: widget.trailing!),
            ),
          ),
        );
      },
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    super.key,
    required this.item,
    required this.index,
    required this.total,
    required this.current,
    required this.load,
    required this.mediaHeight,
    required this.captionBar,
    required this.semanticLabel,
    this.onTap,
  });

  final MediaItem item;
  final int index;
  final int total;
  final bool current;
  final bool load;
  final double mediaHeight;
  final bool captionBar;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final alt = item.altText?.trim() ?? '';
    return Semantics(
      label: alt.isEmpty ? semanticLabel : '$semanticLabel. $alt',
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: MediaCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: mediaHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaImage(sources: item.sources, blurHash: item.blurHash, load: load),
                  if (current)
                    PositionedDirectional(
                      top: ReadInSpace.s2,
                      end: ReadInSpace.s2,
                      child: MediaCounterBadge(index: index, total: total),
                    ),
                ],
              ),
            ),
            if (captionBar) MediaCaptionBar(caption: item.caption),
          ],
        ),
      ),
    );
  }
}

/// Rounded (12 px) slide card with a subtle border in dark mode.
class MediaCard extends StatelessWidget {
  const MediaCard({super.key, required this.child, this.onTap, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(ReadInRadius.md);
    return Material(
      color: color ?? colors.surfaceVariant,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: context.isDark ? BorderSide(color: colors.border) : BorderSide.none,
      ),
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

/// "3 / 12" badge. Always Western digits and LTR so it never flips in RTL.
class MediaCounterBadge extends StatelessWidget {
  const MediaCounterBadge({super.key, required this.index, required this.total, this.inverse = false});

  final int index;
  final int total;

  /// Light-on-dark in the full-screen viewer.
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: (inverse ? colors.surfaceRaised : colors.textPrimary).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
      ),
      child: Text(
        '${index + 1} / $total',
        textDirection: TextDirection.ltr,
        style: context.textTheme.labelSmall?.copyWith(
          color: inverse ? colors.textPrimary : colors.bg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One-line, semi-bold caption under an image slide (`dir="auto"`: aligned by
/// the caption's own direction, not the UI's).
class MediaCaptionBar extends StatelessWidget {
  const MediaCaptionBar({super.key, required this.caption});

  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = caption?.trim() ?? '';
    final dir = Bidi.detect(text) ?? Directionality.of(context);
    return Container(
      height: MediaCarousel.captionBarHeight,
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
      alignment: AlignmentDirectional.centerStart.resolve(dir),
      child: text.isEmpty
          ? null
          : Text(
              Bidi.isolateOppositeRuns(text, dir),
              textDirection: dir,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w600),
            ),
    );
  }
}

/// Default carousel semantics: "Image 2 of 3" / "صورة 2 من 3".
String imageSlideLabel(BuildContext context, int index, int total) => context.l10n.viewerImageOf(index + 1, total);

/// "Page 5 of 12" / "صفحة 5 من 12".
String pageSlideLabel(BuildContext context, int index, int total) => context.l10n.viewerPageOf(index + 1, total);
