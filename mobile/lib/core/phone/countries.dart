import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../bidi/bidi.dart';
import '../security/credential_rules.dart';
import '../storage/key_value_store.dart';

part 'country_list.g.dart';

/// One entry of `shared/countries/countries.json` (SPEC §9.4).
@immutable
class Country {
  const Country({
    required this.iso2,
    required this.dialCode,
    required this.nameAr,
    required this.nameEn,
    required this.exampleNational,
  });

  final String iso2;

  /// Without "+", e.g. "20".
  final String dialCode;
  final String nameAr;
  final String nameEn;

  /// An example mobile number in national format ("010 01234567"), used as the hint.
  final String exampleNational;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  bool operator ==(Object other) => other is Country && other.iso2 == iso2;

  @override
  int get hashCode => iso2.hashCode;

  @override
  String toString() => 'Country($iso2, +$dialCode)';
}

/// The country list compiled in from `shared/countries/countries.json` (`tools/countries/build.mjs`).
abstract final class Countries {
  static const String defaultIso2 = _defaultCountry;

  /// Egypt, Saudi Arabia, UAE, … in the SPEC's order.
  static const List<String> pinned = _pinned;

  static const List<Country> all = _countries;

  static final Map<String, Country> _byIso2 = {for (final c in all) c.iso2: c};
  static final Map<String, List<Country>> _ordered = {};

  static Country? byIso2(String? iso2) => iso2 == null ? null : _byIso2[iso2.toUpperCase()];

  static Country get fallback => _byIso2[defaultIso2]!;

  /// Pinned countries first in their order, then the rest by name in the UI language.
  static List<Country> ordered(String languageCode) => _ordered.putIfAbsent(languageCode, () {
        final pinnedCountries = [for (final iso2 in pinned) ?_byIso2[iso2]];
        final rest = all.where((c) => !pinned.contains(c.iso2)).toList()
          ..sort((a, b) => _sortKey(a, languageCode).compareTo(_sortKey(b, languageCode)));
        return List.unmodifiable([...pinnedCountries, ...rest]);
      });

  static String _sortKey(Country c, String languageCode) =>
      languageCode == 'ar' ? Bidi.normalizeArabic(c.nameAr) : c.nameEn.toLowerCase();

  /// Matches the Arabic name, the English name, the ISO code and the dial code ("+20", "20"), in [ordered] order.
  static List<Country> search(String query, String languageCode) {
    final list = ordered(languageCode);
    final q = query.trim();
    if (q.isEmpty) return list;
    final latin = q.toLowerCase();
    final arabic = Bidi.normalizeArabic(q);
    final dial = digitsOnly(q);
    final looksLikeDialCode = RegExp(r'^\+?[0-9٠-٩۰-۹\s]+$').hasMatch(q);
    return list.where((c) {
      if (looksLikeDialCode) return dial.isNotEmpty && c.dialCode.startsWith(dial);
      return c.iso2.toLowerCase() == latin ||
          c.nameEn.toLowerCase().contains(latin) ||
          Bidi.normalizeArabic(c.nameAr).contains(arabic);
    }).toList();
  }
}

/// The phone field's starting country: the last one used → the device region → Egypt (SPEC §9.4).
@lazySingleton
class PhoneCountryMemory {
  PhoneCountryMemory(this._store);

  static const _key = 'phone.lastCountry';

  final KeyValueStore _store;

  String initial({String? deviceRegion}) {
    final region = deviceRegion ?? WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    return Countries.byIso2(_store.read<String>(_key))?.iso2 ?? Countries.byIso2(region)?.iso2 ?? Countries.defaultIso2;
  }

  Future<void> remember(String iso2) => _store.write(_key, iso2);
}
