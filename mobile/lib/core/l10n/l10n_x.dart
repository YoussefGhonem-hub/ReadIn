import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Supported UI languages (SPEC §14.1). Arabic is the default.
abstract final class AppLocales {
  static const ar = Locale('ar');
  static const en = Locale('en');
  static const supported = [ar, en];
  static const fallback = ar;

  static Locale fromCode(String? code) => code == 'en' ? en : ar;
}
