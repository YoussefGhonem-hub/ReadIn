import 'dart:math';

import 'package:flutter/widgets.dart' show TextDirection;

import '../../../core/bidi/bidi.dart';
import '../rdoc_document.dart';
import 'inline_editing.dart';

/// The blocks a writer can insert (SPEC §13.2), in slash-menu order.
enum RBlockKind {
  paragraph,
  heading2,
  heading3,
  bulletList,
  orderedList,
  steps,
  quote,
  callout,
  code,
  codeTabs,
  table,
  image,
  divider,
  embed,
  summary,
}

/// Block ids: unique in a document, `^[A-Za-z0-9_-]{1,64}$` (rdoc.schema.json), and stable — an id never changes
/// once given, so comments, anchors and the checks' `blockId` keep pointing at the same block.
abstract final class BlockIds {
  static final _valid = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  static bool isValid(String id) => _valid.hasMatch(id);

  /// A new id that isn't in [taken], e.g. `b4k2x9q1`.
  static String generate(Set<String> taken, {Random? random}) {
    final rnd = random ?? Random();
    while (true) {
      final id = 'b${List.generate(8, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join()}';
      if (!taken.contains(id)) return id;
    }
  }

  /// [document] with every block id valid and unique: the first block keeps an id, later duplicates and invalid ids
  /// get new ones. Returns the same instance when nothing had to change.
  static RDocDocument ensureUnique(RDocDocument document, {Random? random}) {
    final taken = {for (final b in document.blocks) if (isValid(b.id)) b.id};
    final seen = <String>{};
    var changed = false;
    final blocks = <RBlock>[];
    for (final block in document.blocks) {
      if (isValid(block.id) && seen.add(block.id)) {
        blocks.add(block);
        continue;
      }
      final id = generate(taken, random: random);
      taken.add(id);
      seen.add(id);
      blocks.add(BlockEditing.withId(block, id));
      changed = true;
    }
    return changed ? document.copyWith(blocks: blocks) : document;
  }
}

/// Per-block direction (SPEC §14.2): `auto` follows the first strong character, `rtl`/`ltr` override it; code is
/// always LTR. The same rules as the reader's block widgets.
abstract final class BlockDirection {
  static const auto = 'auto';
  static const rtl = 'rtl';
  static const ltr = 'ltr';
  static const values = [auto, rtl, ltr];

  /// Blocks with a `dir` attribute in the schema.
  static bool supportsDir(RBlock block) =>
      block is RParagraph ||
      block is RHeading ||
      block is RList ||
      block is RSteps ||
      block is RQuote ||
      block is RCallout ||
      block is RTable ||
      block is RSummary;

  static bool isAlwaysLtr(RBlock block) => block is RCode || block is RCodeTabs;

  static String dirOf(RBlock block) => switch (block) {
        RParagraph(:final dir) || RHeading(:final dir) || RList(:final dir) || RSteps(:final dir) => dir,
        RQuote(:final dir) || RCallout(:final dir) || RTable(:final dir) || RSummary(:final dir) => dir,
        _ => auto,
      };

  /// The text whose first strong character decides `auto`, as the reader computes it.
  static String directionText(RBlock block) => switch (block) {
        RParagraph(:final content) || RHeading(:final content) || RQuote(:final content) || RSummary(:final content) =>
          plainTextOf(content),
        RList(:final items) => items.isEmpty ? '' : plainTextOf(items.first),
        RSteps(:final items) => items.isEmpty ? '' : items.first.title,
        RCallout(:final title, :final content) => '${title ?? ''}${plainTextOf(content)}',
        RTable(:final header) => plainTextOf(header.expand((c) => c).toList()),
        RImage(:final caption, :final alt) => caption ?? alt,
        _ => '',
      };

  /// The direction the block is laid out in; [fallback] is the article's direction for text without strong
  /// characters.
  static TextDirection resolve(RBlock block, {required TextDirection fallback}) => isAlwaysLtr(block)
      ? TextDirection.ltr
      : Bidi.resolve(dirOf(block), directionText(block), fallback: fallback);

  /// [block] with `dir` set to [dir] (`auto` | `rtl` | `ltr`); blocks without `dir` are returned unchanged.
  static RBlock withDir(RBlock block, String dir) {
    final d = values.contains(dir) ? dir : auto;
    return switch (block) {
      RParagraph() => RParagraph(block.id, dir: d, content: block.content),
      RHeading() => RHeading(block.id, level: block.level, dir: d, content: block.content),
      RList() => RList(block.id, ordered: block.ordered, dir: d, items: block.items),
      RSteps() => RSteps(block.id, dir: d, items: block.items),
      RQuote() => RQuote(block.id, dir: d, content: block.content, cite: block.cite),
      RCallout() => RCallout(block.id, variant: block.variant, title: block.title, dir: d, content: block.content),
      RTable() => RTable(block.id, dir: d, header: block.header, rows: block.rows),
      RSummary() => RSummary(block.id, dir: d, content: block.content),
      _ => block,
    };
  }
}

/// Pure block operations shared by editing surfaces.
abstract final class BlockEditing {
  static RBlock withId(RBlock block, String id) => switch (block) {
        RParagraph() => RParagraph(id, dir: block.dir, content: block.content),
        RHeading() => RHeading(id, level: block.level, dir: block.dir, content: block.content),
        RList() => RList(id, ordered: block.ordered, dir: block.dir, items: block.items),
        RSteps() => RSteps(id, dir: block.dir, items: block.items),
        RQuote() => RQuote(id, dir: block.dir, content: block.content, cite: block.cite),
        RCallout() => RCallout(id, variant: block.variant, title: block.title, dir: block.dir, content: block.content),
        RCode() => RCode(id, lang: block.lang, code: block.code, filename: block.filename, highlightLines: block.highlightLines, compile: block.compile),
        RCodeTabs() => RCodeTabs(id, tabs: block.tabs),
        RTable() => RTable(id, dir: block.dir, header: block.header, rows: block.rows),
        RImage() => RImage(id, src: block.src, alt: block.alt, darkSrc: block.darkSrc, caption: block.caption, width: block.width, height: block.height),
        RDivider() => RDivider(id),
        REmbed() => REmbed(id, provider: block.provider, url: block.url),
        RSummary() => RSummary(id, dir: block.dir, content: block.content),
      };

  /// A new, empty block of [kind]. [content] fills the first text slot (a converted paragraph keeps its text).
  static RBlock create(RBlockKind kind, String id, {List<RInline> content = const [], String dir = 'auto'}) =>
      switch (kind) {
        RBlockKind.paragraph => RParagraph(id, dir: dir, content: content),
        RBlockKind.heading2 => RHeading(id, level: 2, dir: dir, content: content),
        RBlockKind.heading3 => RHeading(id, level: 3, dir: dir, content: content),
        RBlockKind.bulletList => RList(id, ordered: false, dir: dir, items: [content]),
        RBlockKind.orderedList => RList(id, ordered: true, dir: dir, items: [content]),
        RBlockKind.steps => RSteps(id, dir: dir, items: [RStep(title: '', content: content)]),
        RBlockKind.quote => RQuote(id, dir: dir, content: content),
        RBlockKind.callout => RCallout(id, variant: RCalloutVariant.tip, dir: dir, content: content),
        RBlockKind.code => RCode(id, lang: 'plaintext', code: plainTextOf(content)),
        RBlockKind.codeTabs => RCodeTabs(id, tabs: const [
            RCodeTab(label: 'C#', lang: 'csharp', code: ''),
            RCodeTab(label: 'TypeScript', lang: 'typescript', code: ''),
          ]),
        RBlockKind.table => RTable(id, dir: dir, header: [content, const []], rows: const [
            [[], []],
          ]),
        RBlockKind.image => RImage(id, src: '', alt: ''),
        RBlockKind.divider => RDivider(id),
        RBlockKind.embed => REmbed(id, provider: 'youtube', url: ''),
        RBlockKind.summary => RSummary(id, dir: dir, content: content),
      };

  /// The kind of an existing block (for "turn into" and the menu's current item).
  static RBlockKind kindOf(RBlock block) => switch (block) {
        RParagraph() => RBlockKind.paragraph,
        RHeading(:final level) => level == 3 ? RBlockKind.heading3 : RBlockKind.heading2,
        RList(:final ordered) => ordered ? RBlockKind.orderedList : RBlockKind.bulletList,
        RSteps() => RBlockKind.steps,
        RQuote() => RBlockKind.quote,
        RCallout() => RBlockKind.callout,
        RCode() => RBlockKind.code,
        RCodeTabs() => RBlockKind.codeTabs,
        RTable() => RBlockKind.table,
        RImage() => RBlockKind.image,
        RDivider() => RBlockKind.divider,
        REmbed() => RBlockKind.embed,
        RSummary() => RBlockKind.summary,
      };

  /// The single inline content of a text block, when it has exactly one.
  static List<RInline>? textOf(RBlock block) => switch (block) {
        RParagraph(:final content) || RHeading(:final content) || RQuote(:final content) => content,
        RCallout(:final content) || RSummary(:final content) => content,
        RList(:final items) when items.length == 1 => items.first,
        _ => null,
      };

  /// True when the block holds any text (the `article.content_empty` rule: an article needs one such block).
  static bool hasText(RBlock block) {
    bool filled(List<RInline> nodes) => plainTextOf(nodes).trim().isNotEmpty;
    return switch (block) {
      RParagraph(:final content) || RHeading(:final content) || RQuote(:final content) => filled(content),
      RCallout(:final content, :final title) => filled(content) || (title?.trim().isNotEmpty ?? false),
      RSummary(:final content) => filled(content),
      RList(:final items) => items.any(filled),
      RSteps(:final items) => items.any((s) => s.title.trim().isNotEmpty || filled(s.content)),
      RCode(:final code) => code.trim().isNotEmpty,
      RCodeTabs(:final tabs) => tabs.any((t) => t.code.trim().isNotEmpty),
      RTable(:final header, :final rows) => header.any(filled) || rows.any((r) => r.any(filled)),
      RImage() || RDivider() || REmbed() => false,
    };
  }
}

/// Markdown shortcuts typed at the start of a paragraph or around a word (SPEC F05).
abstract final class MarkdownShortcuts {
  static final _code = RegExp(r'^```([a-z0-9+#.-]{0,32})[ \n]$');

  /// A paragraph whose text starts with a block marker followed by a space: `#`/`##` → H2, `###` → H3, `-`/`*` →
  /// bullets, `1.` → numbers, `>` → quote, a triple backtick (with an optional language) → code, and `---` → a
  /// divider. Returns the new kind, how many characters the marker takes, and the code language.
  static ({RBlockKind kind, int marker, String? lang})? blockShortcut(String text) {
    if (text == '---') return (kind: RBlockKind.divider, marker: 3, lang: null);
    final code = _code.firstMatch(text);
    if (code != null) {
      final lang = code.group(1)!;
      return (kind: RBlockKind.code, marker: text.length, lang: lang.isEmpty ? null : lang);
    }
    for (final (prefix, kind) in const [
      ('### ', RBlockKind.heading3),
      ('## ', RBlockKind.heading2),
      ('# ', RBlockKind.heading2),
      ('- ', RBlockKind.bulletList),
      ('* ', RBlockKind.bulletList),
      ('1. ', RBlockKind.orderedList),
      ('> ', RBlockKind.quote),
    ]) {
      if (text.startsWith(prefix)) return (kind: kind, marker: prefix.length, lang: null);
    }
    return null;
  }

  /// `/query` typed alone in a paragraph opens the slash menu; returns the query without the `/`.
  static String? slashQuery(String text) {
    final match = RegExp(r'^/(\S{0,24})$').firstMatch(text);
    return match?.group(1);
  }

  static final _inline = [
    (RegExp(r'\*\*([^*\n]+)\*\*$'), 2, RMarkType.bold),
    (RegExp(r'~~([^~\n]+)~~$'), 2, RMarkType.strike),
    (RegExp(r'`([^`\n]+)`$'), 1, RMarkType.code),
  ];

  /// After typing the closing `**`, `~~` or a backtick: the delimited text gets bold, strike or code and loses the
  /// delimiters. Only plain text nodes take part (never a mention, term or line break).
  static InlineEditResult? inlineShortcut(List<RInline> nodes, int caret) {
    final text = plainTextOf(nodes);
    if (caret < 3 || caret > text.length) return null;
    final head = text.substring(0, caret);
    for (final (pattern, width, type) in _inline) {
      final match = pattern.firstMatch(head);
      if (match == null) continue;
      final start = match.start;
      final end = match.end;
      if (!_onlyText(nodes, start, end)) continue;
      // Drop the closing delimiter, then the opening one, then mark the inner text.
      var result = InlineEditing.replaceRange(nodes, end - width, end, '').nodes;
      result = InlineEditing.replaceRange(result, start, start + width, '').nodes;
      final innerEnd = end - 2 * width;
      result = InlineEditing.hasMark(result, start, innerEnd, type)
          ? result
          : InlineEditing.toggleMark(result, start, innerEnd, type);
      return (nodes: result, caret: innerEnd);
    }
    return null;
  }

  static bool _onlyText(List<RInline> nodes, int start, int end) {
    var pos = 0;
    for (final node in nodes) {
      final len = node.plainText.length;
      if (node is! RText && pos < end && pos + len > start) return false;
      pos += len;
    }
    return true;
  }
}

/// What autosave sends: the blocks a writer is still filling in that the schema would reject are left out (an
/// empty heading, an image not uploaded yet, an embed without a valid link, empty lists and steps), and empty text
/// nodes are dropped. The editor keeps its own copy; nothing with content is ever removed.
abstract final class RDocSanitizer {
  static RDocDocument forSave(RDocDocument document) {
    final blocks = <RBlock>[];
    for (final block in document.blocks) {
      final clean = _block(block);
      if (clean != null) blocks.add(clean);
    }
    return document.copyWith(blocks: blocks);
  }

  static List<RInline> _inline(List<RInline> nodes) => InlineEditing.normalize(nodes);

  static RBlock? _block(RBlock b) => switch (b) {
        RParagraph() => RParagraph(b.id, dir: b.dir, content: _inline(b.content)),
        RHeading() => _inline(b.content).isEmpty ? null : RHeading(b.id, level: b.level, dir: b.dir, content: _inline(b.content)),
        RList() => b.items.isEmpty ? null : RList(b.id, ordered: b.ordered, dir: b.dir, items: [for (final i in b.items) _inline(i)]),
        RSteps() => _steps(b),
        RQuote() => RQuote(b.id, dir: b.dir, content: _inline(b.content), cite: _optional(b.cite)),
        RCallout() => RCallout(b.id, variant: b.variant, title: _optional(b.title), dir: b.dir, content: _inline(b.content)),
        RCode() => RCode(
            b.id,
            lang: _lang(b.lang),
            code: b.code,
            filename: _optional(b.filename),
            highlightLines: b.highlightLines,
            compile: b.compile,
          ),
        RCodeTabs() => b.tabs.isEmpty
            ? null
            : RCodeTabs(b.id, tabs: [
                for (final t in b.tabs)
                  RCodeTab(
                    label: t.label.trim().isEmpty ? _lang(t.lang) : t.label,
                    lang: _lang(t.lang),
                    code: t.code,
                    filename: _optional(t.filename),
                    compile: t.compile,
                  ),
              ]),
        RTable() => b.header.isEmpty
            ? null
            : RTable(b.id, dir: b.dir, header: [for (final c in b.header) _inline(c)], rows: [
                for (final r in b.rows)
                  if (r.isNotEmpty) [for (final c in r) _inline(c)],
              ]),
        RImage() => b.src.trim().isEmpty
            ? null
            : RImage(b.id, src: b.src, alt: b.alt, darkSrc: b.darkSrc, caption: _optional(b.caption), width: b.width, height: b.height),
        RDivider() => b,
        REmbed() => InlineEditing.isHttpUrl(b.url) ? b : null,
        RSummary() => RSummary(b.id, dir: b.dir, content: _inline(b.content)),
      };

  static RBlock? _steps(RSteps b) {
    final items = [
      for (final s in b.items)
        if (s.title.trim().isNotEmpty || plainTextOf(s.content).trim().isNotEmpty) RStep(title: s.title, content: _inline(s.content)),
    ];
    return items.isEmpty ? null : RSteps(b.id, dir: b.dir, items: items);
  }

  static String? _optional(String? value) => value == null || value.isEmpty ? null : value;

  static final _codeLang = RegExp(r'^[a-z0-9+#.-]{1,32}$');

  static String _lang(String lang) => _codeLang.hasMatch(lang) ? lang : 'plaintext';
}
