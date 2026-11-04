import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';

/// Labels, icons and search words of the insertable blocks (slash menu, "Add a block", "Turn into").
extension RBlockKindUi on RBlockKind {
  String label(AppLocalizations l10n) => switch (this) {
        RBlockKind.paragraph => l10n.blockParagraph,
        RBlockKind.heading2 => l10n.blockHeading2,
        RBlockKind.heading3 => l10n.blockHeading3,
        RBlockKind.bulletList => l10n.blockBulletList,
        RBlockKind.orderedList => l10n.blockOrderedList,
        RBlockKind.steps => l10n.blockSteps,
        RBlockKind.quote => l10n.blockQuote,
        RBlockKind.callout => l10n.blockCallout,
        RBlockKind.code => l10n.blockCode,
        RBlockKind.codeTabs => l10n.blockCodeTabs,
        RBlockKind.table => l10n.blockTable,
        RBlockKind.image => l10n.blockImage,
        RBlockKind.divider => l10n.blockDivider,
        RBlockKind.embed => l10n.blockEmbed,
        RBlockKind.summary => l10n.blockSummary,
      };

  IconData get icon => switch (this) {
        RBlockKind.paragraph => Icons.notes_rounded,
        RBlockKind.heading2 => Icons.title_rounded,
        RBlockKind.heading3 => Icons.text_fields_rounded,
        RBlockKind.bulletList => Icons.format_list_bulleted_rounded,
        RBlockKind.orderedList => Icons.format_list_numbered_rounded,
        RBlockKind.steps => Icons.linear_scale_rounded,
        RBlockKind.quote => Icons.format_quote_rounded,
        RBlockKind.callout => Icons.lightbulb_outline_rounded,
        RBlockKind.code => Icons.code_rounded,
        RBlockKind.codeTabs => Icons.tab_outlined,
        RBlockKind.table => Icons.table_chart_outlined,
        RBlockKind.image => Icons.image_outlined,
        RBlockKind.divider => Icons.horizontal_rule_rounded,
        RBlockKind.embed => Icons.smart_display_outlined,
        RBlockKind.summary => Icons.summarize_outlined,
      };

  /// English words the slash menu also matches, whatever the UI language (`/code`, `/h2`, `/tldr`).
  List<String> get keywords => switch (this) {
        RBlockKind.paragraph => const ['text', 'paragraph', 'p'],
        RBlockKind.heading2 => const ['heading', 'h2', 'title'],
        RBlockKind.heading3 => const ['subheading', 'h3'],
        RBlockKind.bulletList => const ['bullet', 'list', 'ul'],
        RBlockKind.orderedList => const ['numbered', 'ordered', 'ol', 'list'],
        RBlockKind.steps => const ['steps'],
        RBlockKind.quote => const ['quote', 'blockquote'],
        RBlockKind.callout => const ['callout', 'tip', 'note', 'warning'],
        RBlockKind.code => const ['code'],
        RBlockKind.codeTabs => const ['tabs', 'codetabs', 'code'],
        RBlockKind.table => const ['table'],
        RBlockKind.image => const ['image', 'img', 'picture'],
        RBlockKind.divider => const ['divider', 'hr', 'line'],
        RBlockKind.embed => const ['embed', 'youtube', 'gist', 'video'],
        RBlockKind.summary => const ['summary', 'tldr'],
      };

  bool matches(String query, AppLocalizations l10n) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label(l10n).toLowerCase().contains(q) || keywords.any((k) => k.startsWith(q));
  }
}

/// The kinds a text block can be turned into (keeping its text).
const textBlockKinds = [
  RBlockKind.paragraph,
  RBlockKind.heading2,
  RBlockKind.heading3,
  RBlockKind.bulletList,
  RBlockKind.orderedList,
  RBlockKind.quote,
  RBlockKind.callout,
  RBlockKind.summary,
];

/// Code languages offered in code blocks (any `^[a-z0-9+#.-]{1,32}$` value round-trips).
const codeLanguages = [
  'plaintext',
  'csharp',
  'typescript',
  'javascript',
  'dart',
  'python',
  'java',
  'kotlin',
  'swift',
  'go',
  'rust',
  'sql',
  'json',
  'yaml',
  'xml',
  'html',
  'css',
  'bash',
  'powershell',
  'dockerfile',
];

const _codeLanguageNames = {
  'plaintext': 'Text',
  'text': 'Text',
  'csharp': 'C#',
  'cs': 'C#',
  'typescript': 'TypeScript',
  'ts': 'TypeScript',
  'tsx': 'TSX',
  'javascript': 'JavaScript',
  'js': 'JavaScript',
  'dart': 'Dart',
  'python': 'Python',
  'py': 'Python',
  'java': 'Java',
  'kotlin': 'Kotlin',
  'swift': 'Swift',
  'go': 'Go',
  'rust': 'Rust',
  'sql': 'SQL',
  'json': 'JSON',
  'yaml': 'YAML',
  'yml': 'YAML',
  'xml': 'XML',
  'html': 'HTML',
  'css': 'CSS',
  'scss': 'SCSS',
  'bash': 'Bash',
  'sh': 'Shell',
  'shell': 'Shell',
  'powershell': 'PowerShell',
  'dockerfile': 'Dockerfile',
  'markdown': 'Markdown',
  'razor': 'Razor',
};

/// A code language's display name (the web editor's labels): a code tab's default name.
String codeLanguageName(String lang) => _codeLanguageNames[lang.toLowerCase()] ?? lang;
