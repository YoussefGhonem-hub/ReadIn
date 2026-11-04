import 'package:equatable/equatable.dart';

/// RDoc — ReadIn Document v1 (SPEC §13, shared/rdoc/rdoc.schema.json).
///
/// The API validates and sanitizes RDoc before storing it, so parsing here is
/// lenient: unknown block types are skipped (forward compatibility) and
/// missing optional attributes fall back to defaults. [toJson] writes the
/// schema form back (the editor's autosave): every attribute round-trips,
/// except that `dir: "auto"` (the default) and empty `marks` are left out.
class RDocDocument extends Equatable {
  const RDocDocument({required this.version, required this.language, required this.blocks});

  final int version;

  /// `ar-EG` or `en`.
  final String language;
  final List<RBlock> blocks;

  static const empty = RDocDocument(version: 1, language: 'en', blocks: []);

  factory RDocDocument.fromJson(Map<String, dynamic> json) => RDocDocument(
        version: (json['version'] as num?)?.toInt() ?? 1,
        language: json['language'] as String? ?? 'en',
        blocks: [
          for (final raw in (json['blocks'] as List? ?? const []))
            if (raw is Map<String, dynamic>) ?RBlock.tryParse(raw),
        ],
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'language': language,
        'blocks': [for (final b in blocks) b.toJson()],
      };

  bool get hasSummaryBlock => blocks.any((b) => b is RSummary);

  RDocDocument copyWith({String? language, List<RBlock>? blocks}) =>
      RDocDocument(version: version, language: language ?? this.language, blocks: blocks ?? this.blocks);

  @override
  List<Object?> get props => [version, language, blocks];
}

// ── Inline ──────────────────────────────────────────────────

enum RMarkType { bold, italic, code, link, highlight, strike }

class RMark extends Equatable {
  const RMark(this.type, {this.href});

  final RMarkType type;

  /// Only for [RMarkType.link]; http/https only (validated server-side).
  final String? href;

  static RMark? tryParse(Map<String, dynamic> json) {
    final type = RMarkType.values.where((t) => t.name == json['type']).firstOrNull;
    if (type == null) return null;
    return RMark(type, href: json['href'] as String?);
  }

  Map<String, dynamic> toJson() => {'type': type.name, if (type == RMarkType.link) 'href': href ?? ''};

  @override
  List<Object?> get props => [type, href];
}

sealed class RInline extends Equatable {
  const RInline();

  String get plainText;

  Map<String, dynamic> toJson();

  static RInline? tryParse(Map<String, dynamic> json) => switch (json['type']) {
        'text' => RText(
            json['text'] as String? ?? '',
            marks: [
              for (final m in (json['marks'] as List? ?? const []))
                if (m is Map<String, dynamic>) ?RMark.tryParse(m),
            ],
          ),
        'term' => RTerm(termId: json['termId'] as String? ?? '', text: json['text'] as String? ?? ''),
        'mention' => RMention(userId: json['userId'] as String? ?? '', text: json['text'] as String? ?? ''),
        'hardBreak' => const RHardBreak(),
        _ => null,
      };

  static List<RInline> parseList(Object? raw) => [
        for (final n in (raw as List? ?? const []))
          if (n is Map<String, dynamic>) ?RInline.tryParse(n),
      ];

  static List<Map<String, dynamic>> listToJson(List<RInline> nodes) => [for (final n in nodes) n.toJson()];
}

class RText extends RInline {
  const RText(this.text, {this.marks = const []});

  final String text;
  final List<RMark> marks;

  bool has(RMarkType type) => marks.any((m) => m.type == type);
  String? get href => marks.where((m) => m.type == RMarkType.link).firstOrNull?.href;

  @override
  String get plainText => text;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
        if (marks.isNotEmpty) 'marks': [for (final m in marks) m.toJson()],
      };

  @override
  List<Object?> get props => [text, marks];
}

/// A glossary term (F21): tap shows the definition sheet.
class RTerm extends RInline {
  const RTerm({required this.termId, required this.text});

  final String termId;
  final String text;

  @override
  String get plainText => text;

  @override
  Map<String, dynamic> toJson() => {'type': 'term', 'termId': termId, 'text': text};

  @override
  List<Object?> get props => [termId, text];
}

class RMention extends RInline {
  const RMention({required this.userId, required this.text});

  final String userId;
  final String text;

  @override
  String get plainText => text;

  @override
  Map<String, dynamic> toJson() => {'type': 'mention', 'userId': userId, 'text': text};

  @override
  List<Object?> get props => [userId, text];
}

class RHardBreak extends RInline {
  const RHardBreak();

  @override
  String get plainText => '\n';

  @override
  Map<String, dynamic> toJson() => const {'type': 'hardBreak'};

  @override
  List<Object?> get props => const [];
}

String plainTextOf(List<RInline> nodes) => nodes.map((n) => n.plainText).join();

// ── Blocks ──────────────────────────────────────────────────

/// `dir` is left out when it is the default.
Map<String, dynamic> _dir(String dir) => dir == 'auto' ? const {} : {'dir': dir};

List<List<Map<String, dynamic>>> _itemsToJson(List<List<RInline>> items) => [for (final i in items) RInline.listToJson(i)];

sealed class RBlock extends Equatable {
  const RBlock(this.id);

  final String id;

  /// RDoc `type` value, e.g. `paragraph`, `codeTabs`.
  String get type;

  /// The schema form of this block.
  Map<String, dynamic> toJson();

  static RBlock? tryParse(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final dir = j['dir'] as String? ?? 'auto';
    return switch (j['type']) {
      'paragraph' => RParagraph(id, dir: dir, content: RInline.parseList(j['content'])),
      'heading' => RHeading(id, level: (j['level'] as num?)?.toInt() == 3 ? 3 : 2, dir: dir, content: RInline.parseList(j['content'])),
      'bulletList' => RList(id, ordered: false, dir: dir, items: _items(j['items'])),
      'orderedList' => RList(id, ordered: true, dir: dir, items: _items(j['items'])),
      'steps' => RSteps(id, dir: dir, items: [
          for (final s in (j['items'] as List? ?? const []))
            if (s is Map<String, dynamic>) RStep(title: s['title'] as String? ?? '', content: RInline.parseList(s['content'])),
        ]),
      'quote' => RQuote(id, dir: dir, content: RInline.parseList(j['content']), cite: j['cite'] as String?),
      'callout' => RCallout(
          id,
          variant: RCalloutVariant.values.where((v) => v.name == j['variant']).firstOrNull ?? RCalloutVariant.info,
          title: j['title'] as String?,
          dir: dir,
          content: RInline.parseList(j['content']),
        ),
      'code' => RCode(
          id,
          lang: j['lang'] as String? ?? 'plaintext',
          code: j['code'] as String? ?? '',
          filename: j['filename'] as String?,
          highlightLines: [for (final n in (j['highlightLines'] as List? ?? const [])) (n as num).toInt()],
          compile: j['compile'] as bool?,
        ),
      'codeTabs' => RCodeTabs(id, tabs: [
          for (final t in (j['tabs'] as List? ?? const []))
            if (t is Map<String, dynamic>)
              RCodeTab(
                label: t['label'] as String? ?? '',
                lang: t['lang'] as String? ?? 'plaintext',
                code: t['code'] as String? ?? '',
                filename: t['filename'] as String?,
                compile: t['compile'] as bool?,
              ),
        ]),
      'table' => RTable(
          id,
          dir: dir,
          header: _items(j['header']),
          rows: [for (final r in (j['rows'] as List? ?? const [])) _items(r)],
        ),
      'image' => RImage(
          id,
          src: j['src'] as String? ?? '',
          darkSrc: j['darkSrc'] as String?,
          alt: j['alt'] as String? ?? '',
          caption: j['caption'] as String?,
          width: (j['width'] as num?)?.toInt(),
          height: (j['height'] as num?)?.toInt(),
        ),
      'divider' => RDivider(id),
      'embed' => REmbed(id, provider: j['provider'] as String? ?? '', url: j['url'] as String? ?? ''),
      'summary' => RSummary(id, dir: dir, content: RInline.parseList(j['content'])),
      _ => null,
    };
  }

  static List<List<RInline>> _items(Object? raw) => [for (final item in (raw as List? ?? const [])) RInline.parseList(item)];
}

class RParagraph extends RBlock {
  const RParagraph(super.id, {required this.dir, required this.content});

  final String dir;
  final List<RInline> content;

  @override
  String get type => 'paragraph';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type, ..._dir(dir), 'content': RInline.listToJson(content)};

  @override
  List<Object?> get props => [id, dir, content];
}

class RHeading extends RBlock {
  const RHeading(super.id, {required this.level, required this.dir, required this.content});

  /// 2 or 3 (H1 is the article title, not a block).
  final int level;
  final String dir;
  final List<RInline> content;

  @override
  String get type => 'heading';

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'type': type, 'level': level, ..._dir(dir), 'content': RInline.listToJson(content)};

  @override
  List<Object?> get props => [id, level, dir, content];
}

class RList extends RBlock {
  const RList(super.id, {required this.ordered, required this.dir, required this.items});

  final bool ordered;
  final String dir;
  final List<List<RInline>> items;

  @override
  String get type => ordered ? 'orderedList' : 'bulletList';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type, ..._dir(dir), 'items': _itemsToJson(items)};

  @override
  List<Object?> get props => [id, ordered, dir, items];
}

class RStep extends Equatable {
  const RStep({required this.title, required this.content});

  final String title;
  final List<RInline> content;

  Map<String, dynamic> toJson() => {'title': title, 'content': RInline.listToJson(content)};

  @override
  List<Object?> get props => [title, content];
}

class RSteps extends RBlock {
  const RSteps(super.id, {required this.dir, required this.items});

  final String dir;
  final List<RStep> items;

  @override
  String get type => 'steps';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type, ..._dir(dir), 'items': [for (final s in items) s.toJson()]};

  @override
  List<Object?> get props => [id, dir, items];
}

class RQuote extends RBlock {
  const RQuote(super.id, {required this.dir, required this.content, this.cite});

  final String dir;
  final List<RInline> content;
  final String? cite;

  @override
  String get type => 'quote';

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'type': type, ..._dir(dir), 'content': RInline.listToJson(content), 'cite': ?cite};

  @override
  List<Object?> get props => [id, dir, content, cite];
}

enum RCalloutVariant { tip, info, warning, danger }

class RCallout extends RBlock {
  const RCallout(super.id, {required this.variant, required this.dir, required this.content, this.title});

  final RCalloutVariant variant;
  final String? title;
  final String dir;
  final List<RInline> content;

  @override
  String get type => 'callout';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'variant': variant.name,
        'title': ?title,
        ..._dir(dir),
        'content': RInline.listToJson(content),
      };

  @override
  List<Object?> get props => [id, variant, title, dir, content];
}

/// Always rendered LTR, even inside RTL articles (SPEC §14.2 rule 3).
class RCode extends RBlock {
  const RCode(super.id, {required this.lang, required this.code, this.filename, this.highlightLines = const [], this.compile});

  final String lang;
  final String code;
  final String? filename;

  /// 1-based line numbers to emphasize.
  final List<int> highlightLines;

  /// `false` skips the content pipeline's compile check (SPEC §19.3); kept as written.
  final bool? compile;

  @override
  String get type => 'code';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'lang': lang,
        'filename': ?filename,
        if (highlightLines.isNotEmpty) 'highlightLines': highlightLines,
        'code': code,
        'compile': ?compile,
      };

  @override
  List<Object?> get props => [id, lang, code, filename, highlightLines, compile];
}

class RCodeTab extends Equatable {
  const RCodeTab({required this.label, required this.lang, required this.code, this.filename, this.compile});

  final String label;
  final String lang;
  final String code;
  final String? filename;
  final bool? compile;

  Map<String, dynamic> toJson() =>
      {'label': label, 'lang': lang, 'filename': ?filename, 'code': code, 'compile': ?compile};

  @override
  List<Object?> get props => [label, lang, code, filename, compile];
}

class RCodeTabs extends RBlock {
  const RCodeTabs(super.id, {required this.tabs});

  final List<RCodeTab> tabs;

  @override
  String get type => 'codeTabs';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'tabs': [for (final t in tabs) t.toJson()]};

  @override
  List<Object?> get props => [id, tabs];
}

class RTable extends RBlock {
  const RTable(super.id, {required this.dir, required this.header, required this.rows});

  final String dir;
  final List<List<RInline>> header;
  final List<List<List<RInline>>> rows;

  @override
  String get type => 'table';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        ..._dir(dir),
        'header': _itemsToJson(header),
        'rows': [for (final r in rows) _itemsToJson(r)],
      };

  @override
  List<Object?> get props => [id, dir, header, rows];
}

class RImage extends RBlock {
  const RImage(super.id, {required this.src, required this.alt, this.darkSrc, this.caption, this.width, this.height});

  final String src;

  /// Optional variant for dark mode (diagrams), SPEC §15.5 rule 5.
  final String? darkSrc;
  final String alt;
  final String? caption;
  final int? width;
  final int? height;

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'src': src,
        'darkSrc': ?darkSrc,
        'alt': alt,
        'caption': ?caption,
        'width': ?width,
        'height': ?height,
      };

  @override
  List<Object?> get props => [id, src, darkSrc, alt, caption, width, height];
}

class RDivider extends RBlock {
  const RDivider(super.id);

  @override
  String get type => 'divider';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type};

  @override
  List<Object?> get props => [id];
}

class REmbed extends RBlock {
  const REmbed(super.id, {required this.provider, required this.url});

  /// `youtube` | `github-gist` (allow-listed server-side).
  final String provider;
  final String url;

  @override
  String get type => 'embed';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'provider': provider, 'url': url};

  @override
  List<Object?> get props => [id, provider, url];
}

/// TL;DR box at the top of an article.
class RSummary extends RBlock {
  const RSummary(super.id, {required this.dir, required this.content});

  final String dir;
  final List<RInline> content;

  @override
  String get type => 'summary';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type, ..._dir(dir), 'content': RInline.listToJson(content)};

  @override
  List<Object?> get props => [id, dir, content];
}
