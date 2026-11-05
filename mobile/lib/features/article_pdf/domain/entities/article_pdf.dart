import 'dart:convert';

import 'package:equatable/equatable.dart';

/// An article's PDF (SPEC F33), built by the API and saved to a temporary file for the share sheet.
class ArticlePdf extends Equatable {
  const ArticlePdf({required this.path, required this.fileName});

  /// The temporary file.
  final String path;

  /// The server's name for it, `{slug}-{lang}.pdf` (e.g. `clean-code-en.pdf`, `الذكاء-الاصطناعي-ar-EG.pdf`).
  final String fileName;

  @override
  List<Object?> get props => [path, fileName];
}

/// The PDF's file name from the response's `Content-Disposition` (F33 contract, "The 200 response").
abstract final class ArticlePdfFileName {
  /// The ASCII `filename` the server always sends, used when `filename*` is missing or doesn't decode.
  static const fallback = 'readin-article.pdf';

  /// Most file systems allow 255 bytes per name.
  static const _maxBytes = 240;

  static final _extended = RegExp(r'''(?:^|;)\s*filename\*\s*=\s*([^;]*)''', caseSensitive: false);
  static final _plain = RegExp(r'''(?:^|;)\s*filename\s*=\s*("(?:[^"\\]|\\.)*"|[^;]*)''', caseSensitive: false);
  static final _unsafe = RegExp(r'[\\/:*?"<>|\x00-\x1F\x7F]');

  /// `filename*=UTF-8''{percent-encoded}` (RFC 5987) when it decodes, else `filename`, else [fallback]; made safe for
  /// the file system and always ending in `.pdf`.
  static String fromContentDisposition(String? header) {
    if (header == null || header.trim().isEmpty) return fallback;
    final extended = _decodeExtended(_extended.firstMatch(header)?.group(1));
    if (extended != null) return extended;
    final plain = _safe(_unquote(_plain.firstMatch(header)?.group(1)));
    return plain ?? fallback;
  }

  /// `charset'language'value`: only UTF-8 (the server's charset; RFC 8187 also allows ISO-8859-1, never sent).
  static String? _decodeExtended(String? raw) {
    if (raw == null) return null;
    final value = _unquote(raw);
    if (value == null) return null;
    final first = value.indexOf("'");
    final second = first < 0 ? -1 : value.indexOf("'", first + 1);
    if (second < 0 || value.substring(0, first).toLowerCase() != 'utf-8') return null;
    try {
      return _safe(Uri.decodeComponent(value.substring(second + 1)));
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

  /// No path separators or characters Android/iOS refuse, no leading dots, `.pdf` at the end, at most [_maxBytes]
  /// (a long slug is shortened, keeping the `-{lang}` that says which version it is).
  static String? _safe(String? name) {
    if (name == null) return null;
    var base = name.trim().replaceAll(_unsafe, '_').replaceFirst(RegExp(r'^\.+'), '');
    if (base.toLowerCase().endsWith('.pdf')) base = base.substring(0, base.length - 4);
    base = base.trim();
    if (base.isEmpty) return null;
    final language = RegExp(r'-(ar-EG|en)$').firstMatch(base)?.group(0) ?? '';
    var stem = base.substring(0, base.length - language.length);
    while (stem.isNotEmpty && utf8.encode('$stem$language.pdf').length > _maxBytes) {
      stem = String.fromCharCodes(stem.runes.take(stem.runes.length - 1));
    }
    return stem.isEmpty && language.isEmpty ? null : '$stem$language.pdf';
  }
}
