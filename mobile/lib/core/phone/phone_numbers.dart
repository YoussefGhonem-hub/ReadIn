import 'package:phone_numbers_parser/metadata.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../security/credential_rules.dart';

/// An international number split for the phone field: the country and the national significant digits.
typedef PhoneParts = ({String iso2, String national});

/// libphonenumber rules for the phone field (SPEC §9.4), through `phone_numbers_parser` (a pure-Dart port of the
/// metadata the API and the web validate with). Mobile numbers only; the API receives E.164.
abstract final class PhoneNumbers {
  static final _isoCodes = IsoCode.values.asNameMap();

  static IsoCode? _iso(String iso2) => _isoCodes[iso2.toUpperCase()];

  /// Whether the metadata knows [iso2] (every country in `shared/countries/countries.json` should).
  static bool supports(String iso2) => _iso(iso2) != null;

  /// The longest national number a mobile number of [iso2] can have; extra typed digits are dropped.
  static int maxNationalDigits(String iso2) {
    final iso = _iso(iso2);
    final lengths = iso == null ? null : metadataLengthsByIsoCode[iso];
    final candidates = [...?lengths?.mobile, ...?lengths?.fixedLine, ...?lengths?.general];
    return candidates.isEmpty ? 15 : candidates.reduce((a, b) => a > b ? a : b);
  }

  /// The trunk prefix people type in front of national numbers ("0" in Egypt, "1" in the US), if it can be told
  /// apart from the number: mobile numbers of [iso2] never start with it.
  static String? trunkPrefix(String iso2) {
    final iso = _iso(iso2);
    if (iso == null) return null;
    final prefix = metadataByIsoCode[iso]?.nationalPrefix;
    if (prefix == null || prefix.isEmpty) return null;
    final example = metadataExamplesByIsoCode[iso]?.mobile ?? '';
    return example.isNotEmpty && example.startsWith(prefix) ? null : prefix;
  }

  /// Digits as typed → the national significant number: Arabic-Indic/Persian digits converted, separators dropped,
  /// the trunk prefix stripped and the length capped.
  static String normalizeNational(String input, String iso2) {
    var digits = digitsOnly(input);
    final prefix = trunkPrefix(iso2);
    if (prefix != null && digits.startsWith(prefix)) digits = digits.substring(prefix.length);
    final max = maxNationalDigits(iso2);
    return digits.length > max ? digits.substring(0, max) : digits;
  }

  /// Formats national digits as they are typed, e.g. "100 123 4567" for Egypt. Unknown patterns stay plain digits.
  static String formatNational(String digits, String iso2) {
    final iso = _iso(iso2);
    if (iso == null || digits.isEmpty) return digits;
    try {
      return PhoneNumber(isoCode: iso, nsn: digits).formatNsn();
    } catch (_) {
      return digits;
    }
  }

  /// E.164 (`+201001234567`) when [national] is a valid mobile number of [iso2], otherwise null.
  static String? toE164(String national, String iso2) {
    final iso = _iso(iso2);
    if (iso == null || national.isEmpty) return null;
    try {
      final parsed = PhoneNumber.parse(national, callerCountry: iso, destinationCountry: iso);
      return parsed.isValid(type: PhoneNumberType.mobile) ? parsed.international : null;
    } catch (_) {
      return null;
    }
  }

  /// True when [input] is written as an international number: "+…" or the "00" exit code.
  static bool looksInternational(String input) {
    final text = toAsciiDigits(input).trimLeft();
    return text.startsWith('+') || text.startsWith('00');
  }

  /// Parses a pasted or typed international number ("+20 100 123 4567", "00201001234567") into its country and
  /// national number; null when no country matches.
  static PhoneParts? parseInternational(String input) {
    var digits = digitsOnly(input);
    if (!toAsciiDigits(input).trimLeft().startsWith('+') && digits.startsWith('00')) digits = digits.substring(2);
    if (digits.isEmpty) return null;
    try {
      final parsed = PhoneNumber.parse('+$digits');
      return (iso2: parsed.isoCode.name, national: parsed.nsn);
    } catch (_) {
      return null;
    }
  }

  /// Splits a stored E.164 number for the phone field; null when it can't be parsed.
  static PhoneParts? split(String e164) => parseInternational(e164);

  /// The national significant number of an E.164 number ("1001234567" for "+201001234567").
  static String nationalNumber(String e164) => split(e164)?.national ?? e164.replaceFirst('+', '');

  /// "+20 100 123 4567": how a number is shown to its owner (always LTR).
  static String formatE164(String e164) {
    final parts = split(e164);
    final iso = parts == null ? null : _iso(parts.iso2);
    if (parts == null || iso == null) return e164;
    try {
      final number = PhoneNumber(isoCode: iso, nsn: parts.national);
      return '+${number.countryCode} ${number.formatNsn(format: NsnFormat.international)}';
    } catch (_) {
      return e164;
    }
  }
}
