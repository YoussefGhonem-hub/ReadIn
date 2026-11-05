import '../../../../core/bidi/bidi.dart';
import '../entities/writer_category.dart';

/// Why a typed name can't be a category name (`category.name_invalid`).
enum CategoryNameError {
  /// Nothing left after cleaning.
  empty,

  /// More than [CategoryNames.maxLength] characters after cleaning.
  tooLong,

  /// No letter or digit (tatweel doesn't count), e.g. only punctuation or emoji.
  noLetter,
}

/// The category name rules the API applies (docs/api/contract-v1.md, "Writer categories (F31)" → "Names"), so the
/// app checks a name before sending it, with inline messages.
abstract final class CategoryNames {
  static const minLength = 1;
  static const maxLength = 40;

  /// At most this many categories per writer (`category.limit`).
  static const maxPerWriter = 50;

  static final _format = RegExp(r'\p{Cf}', unicode: true);
  static final _control = RegExp(r'\p{Cc}', unicode: true);
  static final _spaces = RegExp(r'\s+', unicode: true);

  /// A letter or digit; tatweel (U+0640, `\p{Lm}`) only stretches letters, so it doesn't count (like the API).
  static final _letterOrDigit = RegExp(r'(?!\u0640)[\p{L}\p{Nd}]', unicode: true);

  /// Like a tag name (rule 1) but a leading `#` stays: invisible format and control characters removed (a tab or a line
  /// break is a space first), trimmed, every run of whitespace one space, and Arabic-Indic digits written as `0–9`.
  static String clean(String name) {
    final text = name.replaceAll(_format, '').replaceAll(_spaces, ' ').replaceAll(_control, '').trim().replaceAll(_spaces, ' ');
    return String.fromCharCodes(text.runes.map(_westernDigit));
  }

  /// For a [clean]ed name: null when it can be a category name.
  static CategoryNameError? validate(String name) {
    if (name.length < minLength) return CategoryNameError.empty;
    if (name.length > maxLength) return CategoryNameError.tooLong;
    if (!_letterOrDigit.hasMatch(name)) return CategoryNameError.noLetter;
    return null;
  }

  /// The form two names of the same category share (tag rule 3): cleaned, lower case, with the §22 Arabic
  /// normalization (diacritics, Quranic marks and tatweel removed; `أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`).
  static String normalize(String name) =>
      Bidi.normalizeArabic(String.fromCharCodes(clean(name).toLowerCase().runes.where((c) => !_isQuranicMark(c))));

  /// [a] and [b] are the same name for the API (`409 category.name_taken`).
  static bool same(String a, String b) => normalize(a) == normalize(b);

  /// Another of [categories] (not [exceptId], the one being renamed) already has [name].
  static bool isTaken(Iterable<WriterCategory> categories, String name, {String? exceptId}) {
    final key = normalize(name);
    return categories.any((c) => c.id != exceptId && normalize(c.name) == key);
  }

  static bool _isQuranicMark(int c) => c >= 0x06D6 && c <= 0x06ED;

  static int _westernDigit(int c) => switch (c) {
        >= 0x0660 && <= 0x0669 => 0x30 + c - 0x0660,
        >= 0x06F0 && <= 0x06F9 => 0x30 + c - 0x06F0,
        _ => c,
      };
}
