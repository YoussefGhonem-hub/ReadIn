import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';

/// "ReadIn" wordmark: always Latin, always LTR (SPEC §15.1), "In" in primary.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

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
          TextSpan(text: 'Read', style: style.copyWith(color: colors.textPrimary)),
          TextSpan(text: 'In', style: style.copyWith(color: colors.primary)),
        ]),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
