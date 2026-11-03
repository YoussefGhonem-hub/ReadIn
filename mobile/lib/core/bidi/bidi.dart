import 'package:flutter/widgets.dart';

/// Bidirectional text helpers shared by the RDoc renderer, comments, bios,
/// titles and search inputs (SPEC §14.2).
///
/// Control characters are built with [String.fromCharCode] on purpose: raw
/// bidi control characters in source literals are invisible and flagged by
/// the analyzer (`text_direction_code_point_in_literal`).
abstract final class Bidi {
  /// First Strong Isolate (U+2068).
  static final fsi = String.fromCharCode(0x2068);

  /// Left-to-Right Isolate (U+2066), used for inline code which is always LTR.
  static final lri = String.fromCharCode(0x2066);

  /// Pop Directional Isolate (U+2069).
  static final pdi = String.fromCharCode(0x2069);

  static bool isStrongRtl(int c) {
    if (c < 0x0590) return false;
    if (c <= 0x08FF) {
      // Exclude weak/neutral code points inside the Hebrew/Arabic blocks:
      // Hebrew points, Arabic diacritics (NSM) and Arabic-Indic digits (AN/EN).
      if (c >= 0x0591 && c <= 0x05C7) return false;
      if (c >= 0x064B && c <= 0x065F) return false;
      if (c >= 0x0660 && c <= 0x0669) return false;
      if (c == 0x0670) return false;
      if (c >= 0x06D6 && c <= 0x06ED) return false;
      if (c >= 0x06F0 && c <= 0x06F9) return false;
      return true;
    }
    return (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF);
  }

  static bool isStrongLtr(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7) ||
      (c >= 0x370 && c <= 0x3FF) ||
      (c >= 0x400 && c <= 0x4FF);

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  /// Base direction from the first strong character (`dir="auto"`), or null
  /// when the text has no strong characters (digits/punctuation/emoji only).
  static TextDirection? detect(String text) {
    for (final c in text.runes) {
      if (isStrongRtl(c)) return TextDirection.rtl;
      if (isStrongLtr(c)) return TextDirection.ltr;
    }
    return null;
  }

  /// Resolves an RDoc `dir` attribute (`auto` | `rtl` | `ltr`) for [text].
  static TextDirection resolve(String? dir, String text, {required TextDirection fallback}) => switch (dir) {
        'rtl' => TextDirection.rtl,
        'ltr' => TextDirection.ltr,
        _ => detect(text) ?? fallback,
      };

  static const _prefixChars = {0x2E /* . */, 0x40 /* @ */, 0x23 /* # */, 0x24 /* $ */, 0x5F /* _ */};
  static const _trailingChars = {0x2F /* / */, 0x2B /* + */, 0x23 /* # */, 0x25 /* % */, 0x2A /* * */};
  static const _closers = {0x29: 0x28, 0x5D: 0x5B, 0x7D: 0x7B, 0x3E: 0x3C}; // ) ] } >

  /// Wraps every run written in the opposite direction of [base] in
  /// Unicode isolates (U+2068 … U+2069), so punctuation and word order never
  /// break, e.g. "الـ lifetime (Scoped) مهم." or "اتعمل upgrade لـ .NET 10."
  ///
  /// A run starts at an opposite-direction strong character (pulling in a
  /// directly attached `.`, `@`, `#` prefix: `.NET`, `@handle`), extends until
  /// the next base-direction strong character, and ends at its last strong
  /// character or digit, plus balanced closing brackets, `()` and `/ + # % *`
  /// (`C#`, `C++`, `Foo<T>()`, URLs). Sentence punctuation stays outside.
  static String isolateOppositeRuns(String text, TextDirection base) {
    final cps = text.runes.toList();
    final n = cps.length;
    bool isOpposite(int c) => base == TextDirection.rtl ? isStrongLtr(c) : isStrongRtl(c);
    bool isBase(int c) => base == TextDirection.rtl ? isStrongRtl(c) : isStrongLtr(c);

    final runs = <(int, int)>[];
    var lastEnd = 0;
    var i = 0;
    while (i < n) {
      if (!isOpposite(cps[i])) {
        i++;
        continue;
      }
      var start = i;
      while (start > lastEnd && _prefixChars.contains(cps[start - 1])) {
        start--;
      }
      var lastStrong = i;
      var j = i + 1;
      while (j < n && !isBase(cps[j])) {
        if (isOpposite(cps[j]) || _isDigit(cps[j])) lastStrong = j;
        j++;
      }
      // A bracket the run opens but never closes belongs to the surrounding
      // text ("render (Math.random()، …)"): end the run before it, rescan after.
      final unclosed = _firstUnclosed(cps, start, j);
      if (unclosed > i) {
        j = unclosed;
        while (lastStrong >= unclosed || !(isOpposite(cps[lastStrong]) || _isDigit(cps[lastStrong]))) {
          lastStrong--;
        }
      }
      var end = lastStrong + 1;
      while (end < j) {
        final c = cps[end];
        final opener = _closers[c];
        if (opener != null && _unmatched(cps, start, end, opener, c)) {
          end++;
        } else if (c == 0x28 && end + 1 < n && cps[end + 1] == 0x29) {
          end += 2;
        } else if (_trailingChars.contains(c)) {
          end++;
        } else {
          break;
        }
      }
      runs.add((start, end));
      lastEnd = end;
      i = j;
    }

    if (runs.isEmpty) return text;
    final out = StringBuffer();
    var cursor = 0;
    for (final (s, e) in runs) {
      out
        ..write(String.fromCharCodes(cps.sublist(cursor, s)))
        ..write(fsi)
        ..write(String.fromCharCodes(cps.sublist(s, e)))
        ..write(pdi);
      cursor = e;
    }
    out.write(String.fromCharCodes(cps.sublist(cursor)));
    return out.toString();
  }

  /// Index of the first `(`, `[` or `{` in [start, end) without a matching closer before [end], or -1.
  static int _firstUnclosed(List<int> cps, int start, int end) {
    final open = <int>[];
    for (var k = start; k < end; k++) {
      final c = cps[k];
      if (c == 0x28 || c == 0x5B || c == 0x7B) {
        open.add(k);
      } else if ((c == 0x29 || c == 0x5D || c == 0x7D) && open.isNotEmpty) {
        open.removeLast();
      }
    }
    return open.isEmpty ? -1 : open.first;
  }

  static bool _unmatched(List<int> cps, int start, int end, int opener, int closer) {
    var depth = 0;
    for (var k = start; k < end; k++) {
      if (cps[k] == opener) depth++;
      if (cps[k] == closer) depth--;
    }
    return depth > 0;
  }

  /// Wraps [text] as an LTR isolate (inline code, URLs, handles).
  static String ltrIsolate(String text) => '$lri$text$pdi';

  /// Arabic diacritics (tashkeel), superscript alef and tatweel.
  static bool _isStripped(int c) => (c >= 0x064B && c <= 0x065F) || c == 0x0670 || c == 0x0640;

  static int _unify(int c) => switch (c) {
        0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627, // alef variants → bare alef
        0x0649 => 0x064A, // alef maksura → yeh
        0x0629 => 0x0647, // teh marbuta → heh
        _ => c,
      };

  /// Arabic search normalization (SPEC §22): strips diacritics and tatweel,
  /// unifies alef variants → alef, alef maksura → yeh, teh marbuta → heh.
  static String normalizeArabic(String text) =>
      String.fromCharCodes(text.runes.where((c) => !_isStripped(c)).map(_unify));
}
