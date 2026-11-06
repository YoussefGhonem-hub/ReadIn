import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';

/// The quote card (كارت الاقتباس, SPEC F24): a picture of a selection in the reader, drawn by the API
/// (`POST /articles/{id}/quote-card`, docs/api/contract-v1.md "Quote card (F24)").
abstract final class QuoteCardLimits {
  /// Fewer code units after trimming: no Share quote button (the same as a highlight).
  static const minLength = 3;

  /// More: the `quote.too_long` message, without calling the API (a highlight may be up to 1,000).
  static const maxLength = 400;
}

/// The card's colours: the §15.2 light or dark tokens.
enum QuoteCardTheme { light, dark }

/// 1080 × 1080 (Instagram, WhatsApp) or 1200 × 630 (X, Facebook, LinkedIn).
enum QuoteCardFormat {
  square(1080, 1080),
  landscape(1200, 630);

  const QuoteCardFormat(this.width, this.height);

  final int width;
  final int height;

  double get aspectRatio => width / height;
}

/// One card to draw: the version on screen, the F30 selection range (exactly what Highlight sends) and the look.
class QuoteCardRequest extends Equatable {
  const QuoteCardRequest({
    required this.articleId,
    required this.language,
    required this.range,
    required this.theme,
    required this.format,
  });

  /// `ArticleDetailsDto.id`.
  final String articleId;

  /// `ar-EG` | `en`: the version on screen.
  final String language;
  final HighlightRange range;
  final QuoteCardTheme theme;
  final QuoteCardFormat format;

  QuoteCardRequest copyWith({QuoteCardTheme? theme, QuoteCardFormat? format}) => QuoteCardRequest(
        articleId: articleId,
        language: language,
        range: range,
        theme: theme ?? this.theme,
        format: format ?? this.format,
      );

  /// The body: all seven fields.
  Map<String, dynamic> toJson() => {
        'language': language,
        ...range.toJson(),
        'theme': theme.name,
        'format': format.name,
      };

  @override
  List<Object?> get props => [articleId, language, range, theme, format];
}

/// A drawn card: the PNG as the API sent it, and its file name (`readin-quote-{slug}.png`).
class QuoteCardImage extends Equatable {
  const QuoteCardImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  List<Object?> get props => [bytes, fileName];
}

/// The card's file name from the response's `Content-Disposition` (contract "The 200 response"):
/// `filename*=UTF-8''readin-quote-{slug}.png` percent-decoded, else `filename`, else [fallback].
abstract final class QuoteCardFileName {
  /// The ASCII `filename` the server always sends.
  static const fallback = 'readin-quote.png';

  /// Most file systems allow 255 bytes per name.
  static const _maxBytes = 240;

  static final _extended = RegExp(r'''(?:^|;)\s*filename\*\s*=\s*([^;]*)''', caseSensitive: false);
  static final _plain = RegExp(r'''(?:^|;)\s*filename\s*=\s*("(?:[^"\\]|\\.)*"|[^;]*)''', caseSensitive: false);
  static final _unsafe = RegExp(r'[\\/:*?"<>|\x00-\x1F\x7F]');

  static String fromContentDisposition(String? header) {
    if (header == null || header.trim().isEmpty) return fallback;
    return _safe(_decodeExtended(_extended.firstMatch(header)?.group(1))) ??
        _safe(_unquote(_plain.firstMatch(header)?.group(1))) ??
        fallback;
  }

  /// `charset'language'value`, UTF-8 only (the server's charset).
  static String? _decodeExtended(String? raw) {
    final value = _unquote(raw);
    if (value == null) return null;
    final first = value.indexOf("'");
    final second = first < 0 ? -1 : value.indexOf("'", first + 1);
    if (second < 0 || value.substring(0, first).toLowerCase() != 'utf-8') return null;
    try {
      return Uri.decodeComponent(value.substring(second + 1));
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }

  static String? _unquote(String? raw) {
    var value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1).replaceAllMapped(RegExp(r'\\(.)'), (m) => m.group(1)!);
    }
    return value;
  }

  /// No path separators or characters Android/iOS refuse, no leading dots, `.png` at the end, at most [_maxBytes].
  static String? _safe(String? name) {
    if (name == null) return null;
    var stem = name.trim().replaceAll(_unsafe, '_').replaceFirst(RegExp(r'^\.+'), '');
    if (stem.toLowerCase().endsWith('.png')) stem = stem.substring(0, stem.length - 4);
    stem = stem.trim();
    while (stem.isNotEmpty && utf8.encode('$stem.png').length > _maxBytes) {
      stem = String.fromCharCodes(stem.runes.take(stem.runes.length - 1));
    }
    return stem.isEmpty ? null : '$stem.png';
  }
}
