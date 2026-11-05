import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import 'highlights/rdoc_highlights.dart';
import 'rdoc_document.dart';
import 'rdoc_scope.dart';

/// Renders RDoc inline nodes (text + marks, glossary terms, mentions, hard
/// breaks) as one rich paragraph in [direction].
///
/// BiDi (SPEC §14.2): runs written in the opposite script are wrapped in
/// Unicode isolates so punctuation and word order never break; inline code is
/// always an LTR isolate.
///
/// Highlights (F30): with a [unit] inside a highlightable block ([RHighlightUnits]), the nodes' drawn strings are cut
/// where marks start and end and the pieces styled. The cuts only split the same string into more spans, so the text,
/// its isolates and its direction stay exactly as without marks.
class RDocText extends StatefulWidget {
  const RDocText(this.nodes, {super.key, required this.style, required this.direction, this.textAlign, this.unit});

  final List<RInline> nodes;
  final TextStyle style;
  final TextDirection direction;
  final TextAlign? textAlign;

  /// The highlight text unit these nodes are (0, or the list item's index); null for text that can't be highlighted.
  final int? unit;

  @override
  State<RDocText> createState() => _RDocTextState();
}

class _RDocTextState extends State<RDocText> {
  final _recognizers = <GestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _tap(VoidCallback onTap) {
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final scope = RDocScope.of(context);
    final colors = context.colors;
    final dir = widget.direction;
    final units = widget.unit == null ? null : RHighlightUnits.maybeOf(context);
    final pieces = units?.piecesFor(widget.unit!);

    InlineSpan spanFor(RInline node, String text, RHighlightPiece? piece) {
      TextStyle? style;
      GestureRecognizer? recognizer;
      switch (node) {
        case RText():
          var s = const TextStyle();
          if (node.has(RMarkType.bold)) s = s.copyWith(fontWeight: FontWeight.w700);
          if (node.has(RMarkType.italic)) s = s.copyWith(fontStyle: FontStyle.italic);
          if (node.has(RMarkType.strike)) {
            s = s.copyWith(decoration: TextDecoration.lineThrough, decorationColor: colors.textSecondary);
          }
          if (node.has(RMarkType.highlight)) s = s.copyWith(backgroundColor: colors.highlight);
          if (node.has(RMarkType.code)) {
            s = s.merge(codeTextStyle(size: widget.style.fontSize! * 0.88, color: colors.textPrimary))
                .copyWith(backgroundColor: colors.surfaceVariant);
          }
          final href = node.href;
          if (href != null) {
            s = s.copyWith(color: colors.link, decoration: TextDecoration.underline, decorationColor: colors.link);
            if (scope.onLinkTap != null) recognizer = _tap(() => scope.onLinkTap!(href));
          }
          style = s;
        case RTerm():
          style = TextStyle(
            color: colors.primary,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.primary,
          );
          if (scope.onTermTap != null) recognizer = _tap(() => scope.onTermTap!(node));
        case RMention():
          style = TextStyle(color: colors.primary, fontWeight: FontWeight.w600);
          if (scope.onMentionTap != null) recognizer = _tap(() => scope.onMentionTap!(node));
        case RHardBreak():
          break;
      }
      if (piece != null && !piece.isPlain) {
        style = highlightPieceStyle(style ?? const TextStyle(), piece, colors);
        // One of yours offers Remove (with the count when it is popular too); a popular range says how many readers
        // marked it. A link, term or mention keeps its own tap.
        final onCount = units?.onCountTap;
        final onMine = units?.onMineTap;
        final own = piece.mine && onMine != null ? units!.removableAt(widget.unit!, piece.start) : null;
        final count = piece.count;
        if (recognizer == null && own != null) {
          final id = own.id!;
          final tap = TapGestureRecognizer()..onTapUp = (details) => onMine!(context, details.globalPosition, id, count);
          _recognizers.add(tap);
          recognizer = tap;
        } else if (recognizer == null && count > 0 && onCount != null) {
          final tap = TapGestureRecognizer()..onTapUp = (details) => onCount(context, details.globalPosition, count);
          _recognizers.add(tap);
          recognizer = tap;
        }
      }
      return TextSpan(text: text, style: style, recognizer: recognizer);
    }

    final rendered = [for (final n in widget.nodes) renderedInlineText(n, dir)];
    final spans = <InlineSpan>[];
    if (pieces == null || (pieces.length == 1 && pieces.single.isPlain)) {
      for (var i = 0; i < widget.nodes.length; i++) {
        spans.add(spanFor(widget.nodes[i], rendered[i], null));
      }
    } else {
      var nodeStart = 0;
      for (var i = 0; i < widget.nodes.length; i++) {
        final node = widget.nodes[i];
        final length = node.plainText.length;
        final nodeEnd = nodeStart + length;
        if (length == 0) {
          spans.add(spanFor(node, rendered[i], null));
          continue;
        }
        // The cuts fall before a plain character (after the isolates that open there), so the pieces join back into
        // exactly the node's drawn string.
        final at = renderedOffsetsOf(rendered[i]);
        for (final piece in pieces) {
          if (piece.end <= nodeStart || piece.start >= nodeEnd) continue;
          final from = piece.start <= nodeStart ? 0 : at[piece.start - nodeStart];
          final to = piece.end >= nodeEnd ? rendered[i].length : at[piece.end - nodeStart];
          spans.add(spanFor(node, rendered[i].substring(from, to), piece));
        }
        nodeStart = nodeEnd;
      }
    }

    final text = Text.rich(
      TextSpan(style: widget.style, children: spans),
      textDirection: dir,
      textAlign: widget.textAlign ?? TextAlign.start,
    );
    return units == null ? text : RHighlightUnit(unit: widget.unit!, rendered: rendered.join(), child: text);
  }
}
