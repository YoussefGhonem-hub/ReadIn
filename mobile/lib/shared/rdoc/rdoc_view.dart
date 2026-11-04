import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/tokens.g.dart';
import 'blocks/code_blocks.dart';
import 'blocks/media_blocks.dart';
import 'blocks/text_blocks.dart';
import 'rdoc_document.dart';
import 'rdoc_scope.dart';

export 'rdoc_document.dart';
export 'rdoc_scope.dart';

/// Renders a single RDoc block. Keyed by block id so reader state (code tab
/// selection, scroll restoration) survives rebuilds.
class RBlockView extends StatelessWidget {
  const RBlockView(this.block, {super.key});

  final RBlock block;

  @override
  Widget build(BuildContext context) {
    final child = switch (block) {
      final RParagraph b => RParagraphView(b),
      final RHeading b => RHeadingView(b),
      final RList b => RListView(b),
      final RSteps b => RStepsView(b),
      final RQuote b => RQuoteView(b),
      final RCallout b => RCalloutView(b),
      final RCode b => RCodeView(b),
      final RCodeTabs b => RCodeTabsView(b),
      final RTable b => RTableView(b),
      final RImage b => RImageView(b),
      RDivider() => const RDividerView(),
      final REmbed b => REmbedView(b),
      final RSummary b => RSummaryView(b),
    };
    return Padding(
      key: ValueKey('rdoc-${block.type}-${block.id}'),
      padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
      child: child,
    );
  }
}

/// Lazily renders long articles (SPEC §25: lazy RDoc rendering).
///
/// A lazy list only knows the heights of the blocks it has laid out. By default it guesses the rest from the blocks
/// on screen, so the scroll range jumps whenever a tall code block or a short heading comes into view. This one
/// remembers every block it has measured and guesses only the blocks it never laid out, from their average: the range
/// changes only when a block is measured for the first time, and the reading position measured against it (progress
/// bar, F04 read tracking and resume) stays where it was.
class RDocSliver extends StatefulWidget {
  const RDocSliver(this.document, {super.key, this.skipSummary = false, this.locator});

  final RDocDocument document;
  final bool skipSummary;

  /// Lets a table of contents scroll to one of the blocks (F04).
  final RDocBlockLocator? locator;

  @override
  State<RDocSliver> createState() => _RDocSliverState();
}

/// Scrolls the scroll view of an [RDocSliver] to one of its blocks: the reader's table of contents (F04).
class RDocBlockLocator {
  _RDocSliverState? _sliver;

  /// Brings block [blockId] to the top of the view, whether it is built yet or not. Completes with false when no
  /// attached sliver has that block.
  Future<bool> reveal(String blockId, {Duration duration = ReadInMotion.slow, Curve curve = Curves.easeOutCubic}) async =>
      await _sliver?._reveal(blockId, duration, curve) ?? false;
}

class _RDocSliverState extends State<RDocSliver> {
  final _extents = _BlockExtents();

  /// The keys of the blocks built so far, by block id: only with a [RDocSliver.locator].
  final _keys = <String, GlobalKey>{};
  List<RBlock> _blocks = const [];

  /// Rounds of [_reveal]: each lays out the blocks around the guess, so a few are enough even for long articles.
  static const _maxRevealPasses = 12;

  @override
  void initState() {
    super.initState();
    widget.locator?._sliver = this;
  }

  @override
  void didUpdateWidget(RDocSliver old) {
    super.didUpdateWidget(old);
    if (!identical(old.document, widget.document) || old.skipSummary != widget.skipSummary) {
      _extents.clear();
      _keys.clear();
    }
    if (old.locator != widget.locator) {
      if (old.locator?._sliver == this) old.locator!._sliver = null;
      widget.locator?._sliver = this;
    }
  }

  @override
  void dispose() {
    if (widget.locator?._sliver == this) widget.locator!._sliver = null;
    super.dispose();
  }

  /// The blocks are built lazily: a block far from the screen has no position yet. Until it is built, this jumps to
  /// where the measured heights (and their average for the others) put it and lets a frame lay out the blocks there;
  /// then it scrolls the block to the top.
  Future<bool> _reveal(String blockId, Duration duration, Curve curve) async {
    for (var pass = 0; pass < _maxRevealPasses; pass++) {
      if (!mounted) return false;
      final target = _keys[blockId]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, duration: duration, curve: curve);
        return true;
      }
      final index = _blocks.indexWhere((b) => b.id == blockId);
      final sliver = context.findRenderObject();
      final position = Scrollable.maybeOf(context)?.position;
      if (index < 0 || sliver is! RenderSliver || position == null) return false;
      final offset = sliver.constraints.precedingScrollExtent + _extents.before(index, fallback: position.viewportDimension / 4);
      position.jumpTo(offset.clamp(position.minScrollExtent, position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final blocks = _blocks = widget.skipSummary ? document.blocks.where((b) => b is! RSummary).toList() : document.blocks;
    final locating = widget.locator != null;
    // Heights measured at another font size or text scale don't hold anymore.
    _extents.layout = (RDocScope.of(context).bodyFontSize, MediaQuery.textScalerOf(context));
    return SliverList(
      delegate: _MeasuredBlocksDelegate(
        (context, i) => _MeasuredBlock(
          key: locating ? _keys.putIfAbsent(blocks[i].id, GlobalKey.new) : null,
          index: i,
          extents: _extents,
          child: RBlockView(blocks[i]),
        ),
        childCount: blocks.length,
        extents: _extents,
      ),
    );
  }
}

/// The heights of the blocks laid out so far, for one document, width, font size and text scale.
class _BlockExtents {
  final _heights = <int, double>{};
  double _sum = 0;
  double? _width;
  Object? _layout;

  set layout(Object value) {
    if (value == _layout) return;
    _layout = value;
    clear();
  }

  void clear() {
    _heights.clear();
    _sum = 0;
  }

  void record(int index, double height, double width) {
    if (width != _width) {
      _width = width;
      clear();
    }
    _sum += height - (_heights[index] ?? 0);
    _heights[index] = height;
  }

  /// The height of the blocks after [lastIndex] of [count]: as measured, or the average of the measured ones
  /// ([fallback] before any).
  double after(int lastIndex, int count, {required double fallback}) {
    final average = _heights.isEmpty ? fallback : _sum / _heights.length;
    var total = 0.0;
    for (var i = lastIndex + 1; i < count; i++) {
      total += _heights[i] ?? average;
    }
    return total;
  }

  /// The height of the blocks before [index], counted the same way as [after].
  double before(int index, {required double fallback}) {
    final average = _heights.isEmpty ? fallback : _sum / _heights.length;
    var total = 0.0;
    for (var i = 0; i < index; i++) {
      total += _heights[i] ?? average;
    }
    return total;
  }
}

class _MeasuredBlocksDelegate extends SliverChildBuilderDelegate {
  _MeasuredBlocksDelegate(super.builder, {required int super.childCount, required this.extents});

  final _BlockExtents extents;

  @override
  double? estimateMaxScrollOffset(int firstIndex, int lastIndex, double leadingScrollOffset, double trailingScrollOffset) {
    final count = childCount!;
    if (lastIndex >= count - 1) return trailingScrollOffset;
    final onScreen = (trailingScrollOffset - leadingScrollOffset) / (lastIndex - firstIndex + 1);
    return trailingScrollOffset + extents.after(lastIndex, count, fallback: onScreen);
  }
}

/// Records the laid-out height of block [index] in [extents].
class _MeasuredBlock extends SingleChildRenderObjectWidget {
  const _MeasuredBlock({super.key, required this.index, required this.extents, required super.child});

  final int index;
  final _BlockExtents extents;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasuredBlock(index, extents);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasuredBlock renderObject) => renderObject
    ..index = index
    ..extents = extents;
}

class _RenderMeasuredBlock extends RenderProxyBox {
  _RenderMeasuredBlock(this.index, this.extents);

  int index;
  _BlockExtents extents;

  @override
  void performLayout() {
    super.performLayout();
    extents.record(index, size.height, constraints.maxWidth);
  }
}

/// Eager column variant for short content, previews and tests.
class RDocColumn extends StatelessWidget {
  const RDocColumn(this.document, {super.key});

  final RDocDocument document;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in document.blocks) RBlockView(b)],
      );
}
