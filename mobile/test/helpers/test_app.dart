import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';

/// Reads a file from the monorepo's `shared/` folder (tests run from `mobile/`).
Map<String, dynamic> readSharedJson(String relativePath) =>
    jsonDecode(File('../shared/$relativePath').readAsStringSync()) as Map<String, dynamic>;

/// One of the 4 mandatory visual variants (SPEC §8.2): ar/light, ar/dark, en/light, en/dark.
class Variant {
  const Variant(this.locale, this.brightness);

  final Locale locale;
  final Brightness brightness;

  String get name => '${locale.languageCode}_${brightness.name}';

  static const all = [
    Variant(AppLocales.ar, Brightness.light),
    Variant(AppLocales.ar, Brightness.dark),
    Variant(AppLocales.en, Brightness.light),
    Variant(AppLocales.en, Brightness.dark),
  ];

  /// Golden baselines exist only for ar/light and en/dark (SPEC §27): both directions and both themes.
  bool get hasGolden =>
      (locale == AppLocales.ar && brightness == Brightness.light) ||
      (locale == AppLocales.en && brightness == Brightness.dark);
}

/// [matchesGoldenFile] for the variants with a baseline. ar/dark and en/light still build and lay out the same screen in
/// the same test, so an exception or an overflow there fails it, but they have no image to compare.
Matcher matchesVariantGolden(Variant variant, String path) => variant.hasGolden ? matchesGoldenFile(path) : anything;

/// Wraps [child] in a themed, localized MaterialApp.
Widget testApp(Widget child, {Variant variant = const Variant(AppLocales.ar, Brightness.light)}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(variant.locale),
      darkTheme: AppTheme.dark(variant.locale),
      themeMode: variant.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: variant.locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    );

/// Sets a phone-sized surface for the duration of a test.
void usePhoneSurface(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
