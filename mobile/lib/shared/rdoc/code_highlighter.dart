import 'package:flutter/painting.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/plaintext.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github-dark-dimmed.dart';
import 'package:re_highlight/styles/github-dark.dart';

/// One styled run of highlighted code.
typedef CodeSegment = (String text, TextStyle? style);

/// Syntax highlighting for RDoc code blocks (re_highlight, SPEC §3.3).
///
/// Code blocks sit on `code-bg`, which is dark in both themes, so both
/// palettes are dark variants: github-dark-dimmed (light UI) and github-dark
/// (dark UI). Theme backgrounds are dropped so the token background shows.
class CodeHighlighter {
  CodeHighlighter._() {
    _highlight.registerLanguages({
      'csharp': langCsharp,
      'typescript': langTypescript,
      'javascript': langJavascript,
      'dart': langDart,
      'json': langJson,
      'yaml': langYaml,
      'bash': langBash,
      'shell': langShell,
      'sql': langSql,
      'xml': langXml,
      'kotlin': langKotlin,
      'swift': langSwift,
      'python': langPython,
      'css': langCss,
      'plaintext': langPlaintext,
    });
  }

  static final instance = CodeHighlighter._();

  final _highlight = Highlight();

  static const _aliases = {
    'cs': 'csharp',
    'c#': 'csharp',
    'ts': 'typescript',
    'js': 'javascript',
    'yml': 'yaml',
    'sh': 'bash',
    'html': 'xml',
    'kt': 'kotlin',
    'py': 'python',
    'text': 'plaintext',
  };

  static Map<String, TextStyle> _withoutBackground(Map<String, TextStyle> theme) => {
        for (final e in theme.entries)
          e.key: TextStyle(
            color: e.value.color,
            fontWeight: e.value.fontWeight,
            fontStyle: e.value.fontStyle,
            decoration: e.value.decoration,
          ),
      };

  static final _lightTheme = _withoutBackground(githubDarkDimmedTheme);
  static final _darkTheme = _withoutBackground(githubDarkTheme);

  String resolveLanguage(String lang) {
    final key = _aliases[lang.toLowerCase()] ?? lang.toLowerCase();
    return _highlight.getLanguage(key) != null ? key : 'plaintext';
  }

  /// Highlights [code] and splits the result into lines of styled segments,
  /// so callers can emphasize individual lines (`highlightLines`).
  List<List<CodeSegment>> highlightLines(String code, String lang, {required bool dark, required TextStyle base}) {
    final theme = dark ? _darkTheme : _lightTheme;
    TextSpan? span;
    try {
      final result = _highlight.highlight(code: code, language: resolveLanguage(lang));
      final renderer = TextSpanRenderer(base, theme);
      result.render(renderer);
      span = renderer.span;
    } catch (_) {
      span = null;
    }
    final segments = <CodeSegment>[];
    if (span == null) {
      segments.add((code, base));
    } else {
      _flatten(span, null, segments);
    }

    final lines = <List<CodeSegment>>[[]];
    for (final (text, style) in segments) {
      final parts = text.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) lines.add([]);
        if (parts[i].isNotEmpty) lines.last.add((parts[i], style));
      }
    }
    return lines;
  }

  static void _flatten(InlineSpan span, TextStyle? inherited, List<CodeSegment> out) {
    if (span is! TextSpan) return;
    final style = inherited == null ? span.style : inherited.merge(span.style);
    final text = span.text;
    if (text != null && text.isNotEmpty) out.add((text, style));
    for (final child in span.children ?? const <InlineSpan>[]) {
      _flatten(child, style, out);
    }
  }
}
