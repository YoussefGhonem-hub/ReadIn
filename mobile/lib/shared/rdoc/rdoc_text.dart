import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/bidi/bidi.dart';
import '../../core/theme/theme_x.dart';
import 'rdoc_document.dart';
import 'rdoc_scope.dart';

/// Renders RDoc inline nodes (text + marks, glossary terms, mentions, hard
/// breaks) as one rich paragraph in [direction].
///
/// BiDi (SPEC §14.2): runs written in the opposite script are wrapped in
/// Unicode isolates so punctuation and word order never break; inline code is
/// always an LTR isolate.
class RDocText extends StatefulWidget {
  const RDocText(this.nodes, {super.key, required this.style, required this.direction, this.textAlign});

  final List<RInline> nodes;
  final TextStyle style;
  final TextDirection direction;
  final TextAlign? textAlign;

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

    InlineSpan spanFor(RInline node) {
      switch (node) {
        case RText():
          var style = const TextStyle();
          if (node.has(RMarkType.bold)) style = style.copyWith(fontWeight: FontWeight.w700);
          if (node.has(RMarkType.italic)) style = style.copyWith(fontStyle: FontStyle.italic);
          if (node.has(RMarkType.strike)) {
            style = style.copyWith(decoration: TextDecoration.lineThrough, decorationColor: colors.textSecondary);
          }
          if (node.has(RMarkType.highlight)) style = style.copyWith(backgroundColor: colors.highlight);
          final isCode = node.has(RMarkType.code);
          if (isCode) {
            style = style.merge(codeTextStyle(size: widget.style.fontSize! * 0.88, color: colors.textPrimary))
                .copyWith(backgroundColor: colors.surfaceVariant);
          }
          final href = node.href;
          GestureRecognizer? recognizer;
          if (href != null) {
            style = style.copyWith(color: colors.link, decoration: TextDecoration.underline, decorationColor: colors.link);
            if (scope.onLinkTap != null) recognizer = _tap(() => scope.onLinkTap!(href));
          }
          final text = isCode ? Bidi.ltrIsolate(node.text) : Bidi.isolateOppositeRuns(node.text, dir);
          return TextSpan(text: text, style: style, recognizer: recognizer);
        case RTerm():
          return TextSpan(
            text: Bidi.isolateOppositeRuns(node.text, dir),
            style: TextStyle(
              color: colors.primary,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: colors.primary,
            ),
            recognizer: scope.onTermTap == null ? null : _tap(() => scope.onTermTap!(node)),
          );
        case RMention():
          return TextSpan(
            text: Bidi.isolateOppositeRuns(node.text, dir),
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
            recognizer: scope.onMentionTap == null ? null : _tap(() => scope.onMentionTap!(node)),
          );
        case RHardBreak():
          return const TextSpan(text: '\n');
      }
    }

    return Text.rich(
      TextSpan(style: widget.style, children: [for (final n in widget.nodes) spanFor(n)]),
      textDirection: dir,
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }
}
