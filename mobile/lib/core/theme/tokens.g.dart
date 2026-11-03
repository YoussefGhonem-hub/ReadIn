// GENERATED FILE — do not edit. Source: design/tokens.json, generator: tools/tokens/build.mjs
// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';

/// Semantic colors for ReadIn. Access with `Theme.of(context).extension<ReadInColors>()!`
/// (or the `context.colors` helper). Never use hex colors in widgets (SPEC §15.5).
@immutable
class ReadInColors extends ThemeExtension<ReadInColors> {
  const ReadInColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.bg,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.link,
    required this.focusRing,
    required this.highlight,
    required this.scrim,
    required this.calloutTip,
    required this.calloutTipAccent,
    required this.calloutInfo,
    required this.calloutInfoAccent,
    required this.calloutWarning,
    required this.calloutWarningAccent,
    required this.calloutDanger,
    required this.calloutDangerAccent,
    required this.codeBg,
    required this.codeText,
    required this.codeBorder,
    required this.success,
    required this.error,
    required this.onError,
  });

  /// Buttons, links, logo, active states
  final Color primary;
  /// Text/icons on primary
  final Color onPrimary;
  /// Selected chips, soft backgrounds
  final Color primaryContainer;
  /// Text on primary container
  final Color onPrimaryContainer;
  /// Streaks, highlights, badges
  final Color accent;
  /// Text on accent
  final Color onAccent;
  /// Streak badge background
  final Color accentContainer;
  /// App background (never pure black)
  final Color bg;
  /// Cards, sheets
  final Color surface;
  /// Inputs, subtle fills, skeletons
  final Color surfaceVariant;
  /// Dialogs, menus
  final Color surfaceRaised;
  /// Dividers, outlines
  final Color border;
  /// Main text
  final Color textPrimary;
  /// Meta text
  final Color textSecondary;
  /// Inline links in articles
  final Color link;
  /// Keyboard focus outline
  final Color focusRing;
  /// Highlight mark in RDoc
  final Color highlight;
  /// Modal/bottom sheet backdrop
  final Color scrim;
  /// Tip callout background
  final Color calloutTip;
  /// Tip callout stripe/icon
  final Color calloutTipAccent;
  /// Info callout background
  final Color calloutInfo;
  /// Info callout stripe/icon
  final Color calloutInfoAccent;
  /// Warning callout background
  final Color calloutWarning;
  /// Warning callout stripe/icon
  final Color calloutWarningAccent;
  /// Danger callout background
  final Color calloutDanger;
  /// Danger callout stripe/icon
  final Color calloutDangerAccent;
  /// Code blocks (dark in both modes)
  final Color codeBg;
  /// Code block default text
  final Color codeText;
  /// Code block border
  final Color codeBorder;
  /// Success states
  final Color success;
  /// Error states
  final Color error;
  /// Text on error
  final Color onError;

  static const light = ReadInColors(
    primary: Color(0xFF0F5E52),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3F1EE),
    onPrimaryContainer: Color(0xFF0A493F),
    accent: Color(0xFFF2A93B),
    onAccent: Color(0xFF1A1A1A),
    accentContainer: Color(0xFFFFF3D9),
    bg: Color(0xFFFAF8F4),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3F0EA),
    surfaceRaised: Color(0xFFFFFFFF),
    border: Color(0xFFE8E4DC),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    link: Color(0xFF0F5E52),
    focusRing: Color(0xFF0F5E52),
    highlight: Color(0xFFFFF0C2),
    scrim: Color(0x661A1A1A),
    calloutTip: Color(0xFFE8F3EF),
    calloutTipAccent: Color(0xFF0F5E52),
    calloutInfo: Color(0xFFEEF1F5),
    calloutInfoAccent: Color(0xFF3B6EA5),
    calloutWarning: Color(0xFFFDF3E1),
    calloutWarningAccent: Color(0xFFA86400),
    calloutDanger: Color(0xFFFBEAEA),
    calloutDangerAccent: Color(0xFFC0392B),
    codeBg: Color(0xFF1E2321),
    codeText: Color(0xFFE6E6E1),
    codeBorder: Color(0xFF1E2321),
    success: Color(0xFF2E7D5B),
    error: Color(0xFFC0392B),
    onError: Color(0xFFFFFFFF),
  );

  static const dark = ReadInColors(
    primary: Color(0xFF3FB8A3),
    onPrimary: Color(0xFF0B1F1B),
    primaryContainer: Color(0xFF16302A),
    onPrimaryContainer: Color(0xFFBFE7DF),
    accent: Color(0xFFF5B95A),
    onAccent: Color(0xFF1A1A1A),
    accentContainer: Color(0xFF3A2E17),
    bg: Color(0xFF121413),
    surface: Color(0xFF1B1E1C),
    surfaceVariant: Color(0xFF202321),
    surfaceRaised: Color(0xFF232624),
    border: Color(0xFF2E322F),
    textPrimary: Color(0xFFECEAE6),
    textSecondary: Color(0xFFA3A39E),
    link: Color(0xFF3FB8A3),
    focusRing: Color(0xFF3FB8A3),
    highlight: Color(0xFF4A3B12),
    scrim: Color(0x99000000),
    calloutTip: Color(0xFF16302A),
    calloutTipAccent: Color(0xFF3FB8A3),
    calloutInfo: Color(0xFF1E2530),
    calloutInfoAccent: Color(0xFF8DB3E2),
    calloutWarning: Color(0xFF3A2E17),
    calloutWarningAccent: Color(0xFFF5B95A),
    calloutDanger: Color(0xFF3A1E1E),
    calloutDangerAccent: Color(0xFFE5675A),
    codeBg: Color(0xFF0E100F),
    codeText: Color(0xFFE6E6E1),
    codeBorder: Color(0xFF2E322F),
    success: Color(0xFF5CC594),
    error: Color(0xFFE5675A),
    onError: Color(0xFF1A1A1A),
  );

  @override
  ReadInColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? bg,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? link,
    Color? focusRing,
    Color? highlight,
    Color? scrim,
    Color? calloutTip,
    Color? calloutTipAccent,
    Color? calloutInfo,
    Color? calloutInfoAccent,
    Color? calloutWarning,
    Color? calloutWarningAccent,
    Color? calloutDanger,
    Color? calloutDangerAccent,
    Color? codeBg,
    Color? codeText,
    Color? codeBorder,
    Color? success,
    Color? error,
    Color? onError,
  }) {
    return ReadInColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      link: link ?? this.link,
      focusRing: focusRing ?? this.focusRing,
      highlight: highlight ?? this.highlight,
      scrim: scrim ?? this.scrim,
      calloutTip: calloutTip ?? this.calloutTip,
      calloutTipAccent: calloutTipAccent ?? this.calloutTipAccent,
      calloutInfo: calloutInfo ?? this.calloutInfo,
      calloutInfoAccent: calloutInfoAccent ?? this.calloutInfoAccent,
      calloutWarning: calloutWarning ?? this.calloutWarning,
      calloutWarningAccent: calloutWarningAccent ?? this.calloutWarningAccent,
      calloutDanger: calloutDanger ?? this.calloutDanger,
      calloutDangerAccent: calloutDangerAccent ?? this.calloutDangerAccent,
      codeBg: codeBg ?? this.codeBg,
      codeText: codeText ?? this.codeText,
      codeBorder: codeBorder ?? this.codeBorder,
      success: success ?? this.success,
      error: error ?? this.error,
      onError: onError ?? this.onError,
    );
  }

  @override
  ReadInColors lerp(ThemeExtension<ReadInColors>? other, double t) {
    if (other is! ReadInColors) return this;
    return ReadInColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      link: Color.lerp(link, other.link, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      calloutTip: Color.lerp(calloutTip, other.calloutTip, t)!,
      calloutTipAccent: Color.lerp(calloutTipAccent, other.calloutTipAccent, t)!,
      calloutInfo: Color.lerp(calloutInfo, other.calloutInfo, t)!,
      calloutInfoAccent: Color.lerp(calloutInfoAccent, other.calloutInfoAccent, t)!,
      calloutWarning: Color.lerp(calloutWarning, other.calloutWarning, t)!,
      calloutWarningAccent: Color.lerp(calloutWarningAccent, other.calloutWarningAccent, t)!,
      calloutDanger: Color.lerp(calloutDanger, other.calloutDanger, t)!,
      calloutDangerAccent: Color.lerp(calloutDangerAccent, other.calloutDangerAccent, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
      codeText: Color.lerp(codeText, other.codeText, t)!,
      codeBorder: Color.lerp(codeBorder, other.codeBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
    );
  }
}

abstract final class ReadInFonts {
  static const String arabic = 'IBM Plex Sans Arabic';
  static const String latin = 'IBM Plex Sans';
  static const String mono = 'JetBrains Mono';
}

abstract final class ReadInType {
  static const double captionSize = 12;
  static const double captionHeight = 1.4;
  static const FontWeight captionWeight = FontWeight.w500;
  static const double metaSize = 13;
  static const double metaHeight = 1.45;
  static const FontWeight metaWeight = FontWeight.w400;
  static const double uiSize = 15;
  static const double uiHeight = 1.5;
  static const FontWeight uiWeight = FontWeight.w400;
  static const double uiLgSize = 16;
  static const double uiLgHeight = 1.5;
  static const FontWeight uiLgWeight = FontWeight.w500;
  static const double bodySize = 18;
  static const double bodyHeight = 1.8;
  static const FontWeight bodyWeight = FontWeight.w400;
  static const double h3Size = 22;
  static const double h3Height = 1.4;
  static const FontWeight h3Weight = FontWeight.w600;
  static const double h2Size = 28;
  static const double h2Height = 1.3;
  static const FontWeight h2Weight = FontWeight.w600;
  static const double h1Size = 32;
  static const double h1Height = 1.25;
  static const FontWeight h1Weight = FontWeight.w600;
  static const double codeSize = 14;
  static const double codeHeight = 1.6;
  static const FontWeight codeWeight = FontWeight.w400;
}

abstract final class ReadInArticleFontScale {
  static const double s = 16;
  static const double m = 18;
  static const double l = 20;
  static const double xl = 22;
}

abstract final class ReadInSpace {
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 40;
  static const double s8 = 48;
  static const double s9 = 64;
}

abstract final class ReadInRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double chip = 999;
}

abstract final class ReadInMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}

abstract final class ReadInLayout {
  static const double readingWidth = 720;
  static const double contentMaxWidth = 1200;
  static const double sideNavWidth = 248;
  static const double bottomNavHeight = 64;
}
