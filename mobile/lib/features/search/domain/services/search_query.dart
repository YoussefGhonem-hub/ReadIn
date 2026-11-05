import '../../../tags/domain/services/tag_names.dart';

/// What the search box may send as `q` (docs/api/contract-v1.md, "Search (F16)" → "The query"), so the app never asks
/// for something the API refuses with `search.query_invalid`.
abstract final class SearchQuery {
  /// The longest query, in UTF-16 code units; the box stops there.
  static const maxLength = 100;

  /// As you type, a search starts from this many characters; Enter searches from 1.
  static const asYouTypeMinLength = 2;

  /// The wait after the last keystroke before searching.
  static const debounce = Duration(milliseconds: 300);

  /// A letter or a digit; tatweel only stretches letters, so it doesn't count (like the API).
  static final _letterOrDigit = RegExp(r'(?!ـ)[\p{L}\p{Nd}]', unicode: true);

  /// The text sent as `q`: cleaned like a tag name (invisible format characters dropped, trimmed, leading `#`s
  /// dropped, whitespace runs one space, Arabic-Indic digits as `0–9`). The API cleans it again.
  static String clean(String text) => TagNames.clean(text);

  /// [clean], then one leading `@` dropped: what the API matches.
  static String _words(String text) {
    final q = clean(text);
    return q.startsWith('@') ? q.substring(1).trim() : q;
  }

  /// [text] can be searched: as you type from [asYouTypeMinLength] characters, on Enter ([submitted]) from 1, and
  /// always with a letter or a digit (`##` or `@` alone can't).
  static bool canSearch(String text, {bool submitted = false}) {
    final q = _words(text);
    return q.length >= (submitted ? 1 : asYouTypeMinLength) && q.length <= maxLength && _letterOrDigit.hasMatch(q);
  }

  /// Two texts with the same key are the same search for the API: case, Arabic diacritics, tatweel, letter forms
  /// (`أ إ آ → ا`, `ى → ي`, `ة → ه`), a leading `#` or `@` and extra spaces don't matter.
  static String key(String text) => TagNames.normalize(_words(text));
}
