import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/bidi/bidi.dart';
import '../../core/l10n/l10n_x.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';
import 'media_carousel.dart';
import 'media_image.dart';
import 'media_item.dart';

enum MediaViewerKind { images, document }

/// Full-screen viewer for post images and PDF pages (SPEC F26): dark overlay
/// in both themes, paging, pinch and double-tap zoom, a "5 / 12" counter, a
/// thumbnail strip for documents, and close with ✕, system back or a swipe
/// down. Feature code supplies [actions] (Download / Share).
class MediaViewerPage extends StatefulWidget {
  const MediaViewerPage({
    super.key,
    required this.items,
    required this.kind,
    this.initialIndex = 0,
    this.totalCount,
    this.title,
    this.actions = const [],
  });

  final List<MediaItem> items;
  final MediaViewerKind kind;
  final int initialIndex;

  /// Documents: the page count, which may exceed [items] while the remaining
  /// pages load; those slots show a loading placeholder.
  final int? totalCount;
  final String? title;
  final List<Widget> actions;

  static const maxScale = 4.0;
  static const doubleTapScale = 2.5;
  static const dismissDistance = 120.0;

  /// Pushes the viewer on the root navigator as a translucent route, so the
  /// page underneath shows through while swiping down to close.
  static Future<void> open(BuildContext context, WidgetBuilder builder) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: reduceMotion ? Duration.zero : ReadInMotion.base,
      reverseTransitionDuration: reduceMotion ? Duration.zero : ReadInMotion.base,
      pageBuilder: (context, _, _) => builder(context),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> with SingleTickerProviderStateMixin {
  late final PageController _pages;
  final _thumbs = ScrollController();

  /// Springs the page back when a swipe down doesn't close the viewer.
  late final AnimationController _settle;
  late int _index;
  bool _zoomed = false;
  double _dragOffset = 0;
  double _settleFrom = 0;

  static const _thumbWidth = 44.0;
  static const _thumbGap = ReadInSpace.s2;

  int get _total => math.max(widget.totalCount ?? widget.items.length, widget.items.length);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pages = PageController(initialPage: widget.initialIndex);
    _settle = AnimationController(vsync: this, duration: ReadInMotion.base)
      ..addListener(() => setState(() => _dragOffset = _settleFrom * (1 - _settle.value)));
    // Opened on a later page: bring its thumbnail into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealThumb(_index, animate: false);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _thumbs.dispose();
    _settle.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _revealThumb(index, animate: !_reduceMotion);
  }

  /// Centers the current page's thumbnail in the strip.
  void _revealThumb(int index, {required bool animate}) {
    if (!_thumbs.hasClients) return;
    final viewport = _thumbs.position.viewportDimension;
    final target = (ReadInSpace.s4 + index * (_thumbWidth + _thumbGap) - (viewport - _thumbWidth) / 2)
        .clamp(0.0, _thumbs.position.maxScrollExtent);
    if (animate) {
      _thumbs.animateTo(target, duration: ReadInMotion.base, curve: Curves.easeOut);
    } else {
      _thumbs.jumpTo(target);
    }
  }

  void _goTo(int index) {
    if (_reduceMotion) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(index, duration: ReadInMotion.slow, curve: Curves.easeOutCubic);
    }
  }

  void _close() => Navigator.of(context).maybePop();

  void _onDragUpdate(DragUpdateDetails details) {
    _settle.stop();
    setState(() => _dragOffset = math.max(0, _dragOffset + details.delta.dy));
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset > MediaViewerPage.dismissDistance || (details.primaryVelocity ?? 0) > 800) {
      _close();
      return;
    }
    if (_reduceMotion) {
      setState(() => _dragOffset = 0);
    } else {
      _settleFrom = _dragOffset;
      _settle.forward(from: 0);
    }
  }

  String _label(int index) => widget.kind == MediaViewerKind.document
      ? context.l10n.viewerPageOf(index + 1, _total)
      : context.l10n.viewerImageOf(index + 1, _total);

  @override
  Widget build(BuildContext context) {
    // The viewer is dark in both themes: it renders with the dark tokens.
    return Theme(
      data: AppTheme.dark(Localizations.localeOf(context)),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Builder(builder: _buildContent),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final progress = (_dragOffset / (MediaViewerPage.dismissDistance * 3)).clamp(0.0, 1.0);
    final isDocument = widget.kind == MediaViewerKind.document;

    return Scaffold(
      backgroundColor: colors.bg.withValues(alpha: 1 - progress * 0.8),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
              onVerticalDragEnd: _zoomed ? null : _onDragEnd,
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: PageView.builder(
                  controller: _pages,
                  physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                  itemCount: _total,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => index < widget.items.length
                      ? _ZoomableItem(
                          key: ValueKey('viewer-item-$index'),
                          item: widget.items[index],
                          label: _label(index),
                          onZoomChanged: (zoomed) {
                            if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                          },
                        )
                      : _LoadingPage(label: _label(index)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Opacity(
              opacity: 1 - progress,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1, vertical: ReadInSpace.s1),
                    child: Row(
                      children: [
                        IconButton(
                          key: const ValueKey('viewer-close'),
                          tooltip: l10n.close,
                          icon: const Icon(Icons.close_rounded),
                          color: colors.textPrimary,
                          onPressed: _close,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null && widget.title!.isNotEmpty) _Title(widget.title!),
                              Semantics(
                                liveRegion: true,
                                label: _label(_index),
                                excludeSemantics: true,
                                child: MediaCounterBadge(index: _index, total: _total, inverse: true),
                              ),
                            ],
                          ),
                        ),
                        ...widget.actions,
                        if (widget.actions.isEmpty) const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isDocument && widget.items.length > 1)
                    _ThumbnailStrip(
                      items: widget.items,
                      current: _index,
                      controller: _thumbs,
                      thumbWidth: _thumbWidth,
                      gap: _thumbGap,
                      label: _label,
                      onSelect: _goTo,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Document title in its own direction (`.NET`, `C#` stay intact in RTL).
class _Title extends StatelessWidget {
  const _Title(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final dir = Bidi.detect(title) ?? Directionality.of(context);
    return Text(
      Bidi.isolateOppositeRuns(title, dir),
      textDirection: dir,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: context.textTheme.labelLarge,
    );
  }
}

class _ZoomableItem extends StatefulWidget {
  const _ZoomableItem({super.key, required this.item, required this.label, required this.onZoomChanged});

  final MediaItem item;
  final String label;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableItem> createState() => _ZoomableItemState();
}

class _ZoomableItemState extends State<_ZoomableItem> with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoom;
  late final Animation<double> _curve;
  Matrix4Tween? _tween;
  Offset? _doubleTapAt;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    _zoom = AnimationController(vsync: this, duration: ReadInMotion.base)
      ..addListener(() {
        final tween = _tween;
        if (tween != null) _transform.value = tween.evaluate(_curve);
      });
    _curve = CurvedAnimation(parent: _zoom, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransform)
      ..dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  void _toggleZoom() {
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      const s = MediaViewerPage.doubleTapScale;
      final at = _doubleTapAt ?? (context.size == null ? Offset.zero : context.size!.center(Offset.zero));
      target = Matrix4.identity()
        ..translateByDouble(-at.dx * (s - 1), -at.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _transform.value = target;
      return;
    }
    _tween = Matrix4Tween(begin: _transform.value.clone(), end: target);
    _zoom.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final alt = item.altText?.trim() ?? '';
    return Semantics(
      label: alt.isEmpty ? widget.label : '${widget.label}. $alt',
      image: true,
      // Screen-reader activation toggles zoom like a double tap does.
      onTap: _toggleZoom,
      onTapHint: context.l10n.viewerZoomHint,
      excludeSemantics: true,
      child: GestureDetector(
        onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: MediaViewerPage.maxScale,
          panEnabled: _zoomed,
          child: SizedBox.expand(
            child: Center(
              child: AspectRatio(
                aspectRatio: item.aspectRatio,
                child: MediaImage(sources: item.sources, blurHash: item.blurHash, fit: BoxFit.contain, largest: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(height: ReadInSpace.s3),
              Text(context.l10n.viewerPageLoading, style: context.textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.items,
    required this.current,
    required this.controller,
    required this.thumbWidth,
    required this.gap,
    required this.label,
    required this.onSelect,
  });

  final List<MediaItem> items;
  final int current;
  final ScrollController controller;
  final double thumbWidth;
  final double gap;
  final String Function(int index) label;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = thumbWidth * 1.42;
    return Semantics(
      label: context.l10n.viewerThumbnails,
      container: true,
      child: SizedBox(
        height: height + ReadInSpace.s4 * 2,
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s4),
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(width: gap),
          itemBuilder: (context, i) {
            final selected = i == current;
            return Semantics(
              label: label(i),
              selected: selected,
              button: true,
              onTap: () => onSelect(i),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  width: thumbWidth,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ReadInRadius.sm / 2),
                    border: Border.all(color: selected ? colors.primary : colors.border, width: selected ? 2 : 1),
                  ),
                  child: MediaImage(sources: [items[i].sources.first], blurHash: items[i].blurHash),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
