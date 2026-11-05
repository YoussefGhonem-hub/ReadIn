import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.g.dart';

/// Builds Material [ThemeData] from the generated design tokens (SPEC §15).
///
/// Rules: no hex colors outside `tokens.g.dart`; light mode uses soft shadows,
/// dark mode uses lighter surfaces + subtle borders instead of shadows.
abstract final class AppTheme {
  static ThemeData light(Locale locale) => _build(ReadInColors.light, Brightness.light, locale);
  static ThemeData dark(Locale locale) => _build(ReadInColors.dark, Brightness.dark, locale);

  /// Primary UI font follows the UI language; the other script is the fallback
  /// so mixed Arabic/English text always renders with IBM Plex.
  static (String, List<String>) fontsFor(Locale locale) => locale.languageCode == 'ar'
      ? (ReadInFonts.arabic, const [ReadInFonts.latin])
      : (ReadInFonts.latin, const [ReadInFonts.arabic]);

  static ThemeData _build(ReadInColors c, Brightness brightness, Locale locale) {
    final isDark = brightness == Brightness.dark;
    final (family, fallback) = fontsFor(locale);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.accent,
      onSecondary: c.onAccent,
      secondaryContainer: c.accentContainer,
      onSecondaryContainer: c.textPrimary,
      tertiary: c.calloutInfoAccent,
      onTertiary: c.onPrimary,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceVariant,
      error: c.error,
      onError: c.onError,
      outline: c.border,
      outlineVariant: c.border,
      scrim: c.scrim,
      shadow: c.textPrimary,
      surfaceTint: Colors.transparent,
    );

    TextStyle style(double size, double height, FontWeight weight, Color color) => TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontSize: size,
          height: height,
          fontWeight: weight,
          color: color,
        );

    final textTheme = TextTheme(
      displaySmall: style(ReadInType.h1Size, ReadInType.h1Height, ReadInType.h1Weight, c.textPrimary),
      headlineMedium: style(ReadInType.h2Size, ReadInType.h2Height, ReadInType.h2Weight, c.textPrimary),
      headlineSmall: style(ReadInType.h3Size, ReadInType.h3Height, ReadInType.h3Weight, c.textPrimary),
      titleLarge: style(ReadInType.h3Size, ReadInType.h3Height, ReadInType.h3Weight, c.textPrimary),
      titleMedium: style(ReadInType.uiLgSize, ReadInType.uiLgHeight, FontWeight.w600, c.textPrimary),
      titleSmall: style(ReadInType.uiSize, ReadInType.uiHeight, FontWeight.w600, c.textPrimary),
      bodyLarge: style(ReadInType.uiLgSize, ReadInType.uiLgHeight, ReadInType.uiWeight, c.textPrimary),
      bodyMedium: style(ReadInType.uiSize, ReadInType.uiHeight, ReadInType.uiWeight, c.textPrimary),
      bodySmall: style(ReadInType.metaSize, ReadInType.metaHeight, ReadInType.metaWeight, c.textSecondary),
      labelLarge: style(ReadInType.uiSize, ReadInType.uiHeight, FontWeight.w600, c.textPrimary),
      labelMedium: style(ReadInType.metaSize, ReadInType.metaHeight, FontWeight.w500, c.textPrimary),
      labelSmall: style(ReadInType.captionSize, ReadInType.captionHeight, ReadInType.captionWeight, c.textSecondary),
    );

    final cardRadius = BorderRadius.circular(ReadInRadius.card);
    final controlRadius = BorderRadius.circular(ReadInRadius.md);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: family,
      fontFamilyFallback: fallback,
      textTheme: textTheme,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      // White bars over the `bg` canvas, as LinkedIn's: `surface` with a 1 px `border` edge under the bar (a TabBar's
      // own divider lands on that line). Flat whether or not content scrolls under it: no tint, no shadow.
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: c.border)),
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        // The status bar sits on the bar: dark icons on the white one, light icons on the dark one.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: brightness,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        elevation: isDark ? 0 : 1.5,
        shadowColor: c.textPrimary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: isDark ? BorderSide(color: c.border) : BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primaryContainer,
        disabledColor: c.surfaceVariant,
        checkmarkColor: c.onPrimaryContainer,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: c.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfaceVariant,
          disabledForegroundColor: c.textSecondary,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: c.border),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: textTheme.labelLarge),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: c.textPrimary)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.textPrimary,
          selectedBackgroundColor: c.primaryContainer,
          selectedForegroundColor: c.onPrimaryContainer,
          side: BorderSide(color: c.border),
          textStyle: textTheme.labelMedium,
        ),
      ),
      // Inputs on `surface` with their border, as on the web: they read on the `bg` canvas and inside cards alike. A
      // disabled one keeps the old subtle fill, so it still shows without its border.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.disabled) ? c.surfaceVariant : c.surface),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s4),
        border: OutlineInputBorder(borderRadius: controlRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: controlRadius, borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: controlRadius, borderSide: BorderSide(color: c.focusRing, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: controlRadius, borderSide: BorderSide(color: c.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: controlRadius, borderSide: BorderSide(color: c.error, width: 2)),
        errorStyle: textTheme.labelSmall?.copyWith(color: c.error),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaryContainer,
        height: ReadInLayout.bottomNavHeight + 8,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? c.primary : c.textSecondary,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? c.onPrimaryContainer : c.textSecondary),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(ReadInRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.bg),
        actionTextColor: c.accent,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
        circularTrackColor: c.border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : c.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceVariant),
        trackOutlineColor: WidgetStateProperty.all(c.border),
      ),
    );
  }
}
