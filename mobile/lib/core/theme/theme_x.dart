import 'package:flutter/material.dart';

import 'tokens.g.dart';

extension ThemeX on BuildContext {
  /// Semantic design-token colors for the active theme.
  ReadInColors get colors => Theme.of(this).extension<ReadInColors>()!;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

/// Code is always set in JetBrains Mono (SPEC §15.3).
TextStyle codeTextStyle({double size = ReadInType.codeSize, Color? color}) => TextStyle(
      fontFamily: ReadInFonts.mono,
      fontFamilyFallback: const [ReadInFonts.latin, ReadInFonts.arabic],
      fontSize: size,
      height: ReadInType.codeHeight,
      color: color,
    );
