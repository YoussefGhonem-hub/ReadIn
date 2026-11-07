import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';

/// "ReadIn" wordmark: always Latin, always LTR (SPEC §15.1), "In" in primary. On the brand green (the Sign in
/// header) [color] and [accentColor] set the two parts.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28, this.color, this.accentColor});

  final double size;

  /// "Read" (defaults to `textPrimary`).
  final Color? color;

  /// "In" (defaults to `primary`).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(
      fontFamily: ReadInFonts.latin,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -size * 0.05,
      height: 1.1,
    );
    return Semantics(
      label: 'ReadIn',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Read', style: style.copyWith(color: color ?? colors.textPrimary)),
          TextSpan(text: 'In', style: style.copyWith(color: accentColor ?? colors.primary)),
        ]),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
