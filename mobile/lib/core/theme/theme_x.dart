import 'package:flutter/material.dart';

import 'tokens.g.dart';

extension ThemeX on BuildContext {
  /// Semantic design-token colors for the active theme.
  ReadInColors get colors => Theme.of(this).extension<ReadInColors>()!;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

/// The platforms' color emoji fonts (Android, iOS, Windows). The system finds them anyway; naming them lets golden
/// tests, which only see the fonts they load, draw the reactions 💡 ❤️ 🔥 🤯 instead of empty boxes.
const emojiFontFallback = ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji'];

extension EmojiTextStyle on TextStyle {
  /// This style with the color emoji fonts after its own fallbacks.
  TextStyle withEmoji() => copyWith(fontFamilyFallback: [...?fontFamilyFallback, ...emojiFontFallback]);
}

/// Code is always set in JetBrains Mono (SPEC §15.3).
TextStyle codeTextStyle({double size = ReadInType.codeSize, Color? color}) => TextStyle(
      fontFamily: ReadInFonts.mono,
      fontFamilyFallback: const [ReadInFonts.latin, ReadInFonts.arabic],
      fontSize: size,
      height: ReadInType.codeHeight,
      color: color,
    );
