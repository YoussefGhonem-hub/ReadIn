import 'package:flutter/material.dart';

import '../../core/bidi/bidi.dart';

/// [Text] for content-derived strings (field/topic names, author names,
/// handles): runs in the opposite script are isolated against the ambient
/// direction, so `.NET`, `C#` or `Node.js` don't render as `NET.` in RTL.
class BidiText extends StatelessWidget {
  const BidiText(this.text, {super.key, this.style, this.maxLines, this.overflow, this.textAlign});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
        Bidi.isolateOppositeRuns(text, Directionality.of(context)),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
}
