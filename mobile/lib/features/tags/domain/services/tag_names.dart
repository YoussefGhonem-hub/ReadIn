import '../../../../core/bidi/bidi.dart';

/// Why a typed name can't become a new tag (rule 2 of the contract's "Tag names").
enum TagNameError {
  /// Fewer than [TagNames.minLength] characters after cleaning.
  tooShort,

  /// More than [TagNames.maxLength] characters after cleaning.
  tooLong,

  /// Something other than letters, digits, spaces and `- _ . + #`.
  invalidCharacters,

  /// Only allowed characters, but no letter or digit (e.g. `++`, or only tatweel).
  noLetter,
}

/// The tag name rules the API applies (docs/api/contract-v1.md, "Tags (F32)" → "Tag names"), so the editor can
/// check a name before it becomes a chip.
abstract final class TagNames {
  static const minLength = 2;
  static const maxLength = 30;

  /// At most this many tags per article (`article.too_many_tags`).
  static const maxPerArticle = 5;

  static final _format = RegExp(r'\p{Cf}', unicode: true);
  static final _spaces = RegExp(r'\s+', unicode: true);
  static final _allowed = RegExp(r'^[\p{L}\p{M}\p{Nd} \-_.+#]+$', unicode: true);

  /// A letter or digit; tatweel (U+0640, `\p{Lm}`) only stretches letters, so it doesn't count (like the API).
  static final _letterOrDigit = RegExp(r'(?!\u0640)[\p{L}\p{Nd}]', unicode: true);

  /// Rule 1: invisible format characters removed (LRM/RLM, isolates, zero-width joiners), trimmed, leading `#`s
  /// dropped, every run of whitespace one space, and Arabic-Indic digits written as `0–9`.
  static String clean(String name) {
    var text = name.replaceAll(_format, '').trim();
    var start = 0;
    while (start < text.length && text.codeUnitAt(start) == 0x23 /* # */) {
      start++;
    }
    text = text.substring(start).trim().replaceAll(_spaces, ' ');
    return String.fromCharCodes(text.runes.map(_westernDigit));
  }

  /// Rule 2, for a new tag ([name] already [clean]ed): null when it can become one.
  static TagNameError? validate(String name) {
    if (name.length < minLength) return TagNameError.tooShort;
    if (name.length > maxLength) return TagNameError.tooLong;
    if (!_allowed.hasMatch(name)) return TagNameError.invalidCharacters;
    if (!_letterOrDigit.hasMatch(name)) return TagNameError.noLetter;
    return null;
  }

  /// Rule 3: the form two names of the same tag share: cleaned, lower case, with the §22 Arabic normalization
  /// (diacritics, Quranic marks and tatweel removed; `أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`). `AI`, `ai` and `#AI` are one tag.
  static String normalize(String name) =>
      Bidi.normalizeArabic(String.fromCharCodes(clean(name).toLowerCase().runes.where((c) => !_isQuranicMark(c))));

  /// [a] and [b] name the same tag.
  static bool same(String a, String b) => normalize(a) == normalize(b);

  /// Whether [names] already hold the tag [name].
  static bool containsTag(Iterable<String> names, String name) {
    final key = normalize(name);
    return names.any((n) => normalize(n) == key);
  }

  static bool _isQuranicMark(int c) => c >= 0x06D6 && c <= 0x06ED;

  static int _westernDigit(int c) => switch (c) {
        >= 0x0660 && <= 0x0669 => 0x30 + c - 0x0660,
        >= 0x06F0 && <= 0x06F9 => 0x30 + c - 0x06F0,
        _ => c,
      };
}
