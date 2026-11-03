import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import 'l10n_x.dart';

/// The active UI locale, readable outside the widget tree (e.g. by the
/// `Accept-Language` interceptor). Updated by the settings feature.
@lazySingleton
class CurrentLocale extends ValueNotifier<Locale> {
  CurrentLocale() : super(AppLocales.fallback);

  String get languageCode => value.languageCode;
}
