import 'package:appflowy_editor/appflowy_editor.dart';

import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/inline_editing.dart';
import '../../../../shared/rdoc/editing/rdoc_codec.dart';
import '../../../../shared/rdoc/rdoc_document.dart';

/// Node types and attribute keys of RDoc content inside an AppFlowy document.
abstract final class RDocNodeKeys {
  /// A callout: its text is the node's delta; [variant] and [title] are attributes.
  static const callout = 'rdoc_callout';

  /// The TL;DR box: its text is the node's delta.
  static const summary = 'rdoc_summary';

  /// Steps, code, code tabs, table, image and embed: the RDoc block JSON in [block], edited in a sheet.
  static const block = 'rdoc_block';

  static const blockJson = 'rdoc';
  static const variant = 'variant';
  static const title = 'title';
  static const cite = 'cite';

  /// List items of one RDoc list share its id.
  static const listId = 'rdoc_list';

  // Inline attributes.
  static const mention = 'rdoc_mention';
  static const term = 'rdoc_term';
  static const highlight = 'highlight';
}

/// RDoc ⇄ AppFlowy, on top of the library-independent [RDocCodec]: block ids become node ids (AppFlowy's own ids
/// are valid RDoc ids), `dir` becomes the node's `textDirection`, marks become delta attributes, and mentions and
/// glossary terms are text runs that carry their user / term id. A hard break is a `\n` inside a block's text.
abstract final class RDocAppFlowyCodec {
  // ── RDoc → AppFlowy ──────────────────────────────────────

  static Document toDocument(RDocDocument document) => Document(
        root: Node(type: 'page', children: [for (final b in document.blocks) ...nodesFor(b)]),
      );

  /// The nodes of one block: one per list item, one for every other block.
  static List<Node> nodesFor(RBlock block) => switch (block) {
        RParagraph() => [_text(block.id, ParagraphBlockKeys.type, block.content, block.dir)],
        RHeading() => [_text(block.id, HeadingBlockKeys.type, block.content, block.dir, {HeadingBlockKeys.level: block.level})],
        RList() => [
            for (final (i, item) in block.items.indexed)
              _text(
                i == 0 ? block.id : _itemId(block.id, i),
                block.ordered ? NumberedListBlockKeys.type : BulletedListBlockKeys.type,
                item,
                block.dir,
                {RDocNodeKeys.listId: block.id},
              ),
          ],
        RQuote() => [_text(block.id, QuoteBlockKeys.type, block.content, block.dir, {RDocNodeKeys.cite: ?block.cite})],
        RCallout() => [
            _text(block.id, RDocNodeKeys.callout, block.content, block.dir, {
              RDocNodeKeys.variant: block.variant.name,
              RDocNodeKeys.title: ?block.title,
            }),
          ],
        RSummary() => [_text(block.id, RDocNodeKeys.summary, block.content, block.dir)],
        RDivider() => [Node(id: block.id, type: DividerBlockKeys.type)],
        RSteps() || RCode() || RCodeTabs() || RTable() || RImage() || REmbed() => [blockNode(block)],
      };

  /// A structured block (steps, code, tabs, table, image, embed) as one node holding its RDoc.
  static Node blockNode(RBlock block) => Node(id: block.id, type: RDocNodeKeys.block, attributes: {RDocNodeKeys.blockJson: block.toJson()});

  static String _itemId(String listId, int i) {
    final suffix = '-$i';
    final base = listId.length + suffix.length > 64 ? listId.substring(0, 64 - suffix.length) : listId;
    return '$base$suffix';
  }

  static Node _text(String id, String type, List<RInline> content, String dir, [Map<String, Object?> extra = const {}]) => Node(
        id: id,
        type: type,
        attributes: {
          blockComponentDelta: deltaFor(content).toJson(),
          blockComponentTextDirection: dir,
          for (final e in extra.entries)
            if (e.value != null) e.key: e.value,
        },
      );

  /// Inline nodes as a delta: marks are attributes, a mention or term is a run with its id, a hard break is `\n`.
  static Delta deltaFor(List<RInline> nodes) {
    final delta = Delta();
    for (final node in nodes) {
      switch (node) {
        case RText():
          final attributes = <String, Object>{
            for (final m in node.marks) ...switch (m.type) {
              RMarkType.bold => {AppFlowyRichTextKeys.bold: true},
              RMarkType.italic => {AppFlowyRichTextKeys.italic: true},
              RMarkType.code => {AppFlowyRichTextKeys.code: true},
              RMarkType.strike => {AppFlowyRichTextKeys.strikethrough: true},
              RMarkType.link => {AppFlowyRichTextKeys.href: m.href ?? ''},
              RMarkType.highlight => {RDocNodeKeys.highlight: true},
            },
          };
          delta.insert(node.text, attributes: attributes.isEmpty ? null : attributes);
        case RMention():
          delta.insert(node.text, attributes: {RDocNodeKeys.mention: node.userId});
        case RTerm():
          delta.insert(node.text, attributes: {RDocNodeKeys.term: node.termId});
        case RHardBreak():
          delta.insert('\n');
      }
    }
    return delta;
  }

  // ── AppFlowy → RDoc ──────────────────────────────────────

  /// The editor's document as RDoc in [language]: nested nodes (indented list items) are flattened in reading order,
  /// consecutive list items of one list form one list block, and ids are made unique.
  static RDocDocument fromDocument(Document document, {required String language}) {
    final nodes = <Node>[];
    void walk(Node node) {
      for (final child in node.children) {
        nodes.add(child);
        walk(child);
      }
    }

    walk(document.root);
    final blocks = <RBlock>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final type = node.type;
      if (type == BulletedListBlockKeys.type || type == NumberedListBlockKeys.type) {
        final listId = node.attributes[RDocNodeKeys.listId] as String? ?? node.id;
        final items = [inlinesFrom(node.delta)];
        while (i + 1 < nodes.length && nodes[i + 1].type == type) {
          final nextList = nodes[i + 1].attributes[RDocNodeKeys.listId] as String?;
          if (nextList != null && nextList != listId) break;
          items.add(inlinesFrom(nodes[++i].delta));
        }
        blocks.add(RList(listId, ordered: type == NumberedListBlockKeys.type, dir: _dir(node), items: items));
        continue;
      }
      final block = blockFor(node);
      if (block != null) blocks.add(block);
    }
    return RDocCodec.decode(
      RDocDocument(version: 1, language: language, blocks: blocks).toJson(),
      language: language,
    );
  }

  /// One node as a block (list items are grouped by [fromDocument]); null for nodes RDoc has no block for.
  static RBlock? blockFor(Node node) {
    final id = node.id;
    final dir = _dir(node);
    return switch (node.type) {
      ParagraphBlockKeys.type => RParagraph(id, dir: dir, content: inlinesFrom(node.delta)),
      HeadingBlockKeys.type => RHeading(
          id,
          level: ((node.attributes[HeadingBlockKeys.level] as num?)?.toInt() ?? 2) >= 3 ? 3 : 2,
          dir: dir,
          content: inlinesFrom(node.delta),
        ),
      QuoteBlockKeys.type => RQuote(id, dir: dir, content: inlinesFrom(node.delta), cite: node.attributes[RDocNodeKeys.cite] as String?),
      RDocNodeKeys.callout => RCallout(
          id,
          variant: RCalloutVariant.values.where((v) => v.name == node.attributes[RDocNodeKeys.variant]).firstOrNull ?? RCalloutVariant.tip,
          title: node.attributes[RDocNodeKeys.title] as String?,
          dir: dir,
          content: inlinesFrom(node.delta),
        ),
      RDocNodeKeys.summary => RSummary(id, dir: dir, content: inlinesFrom(node.delta)),
      DividerBlockKeys.type => RDivider(id),
      RDocNodeKeys.block => _structured(node),
      // Anything else with text (e.g. a to-do item pasted in) keeps its text as a paragraph.
      _ => node.delta == null ? null : RParagraph(id, dir: dir, content: inlinesFrom(node.delta)),
    };
  }

  static RBlock? _structured(Node node) {
    final json = node.attributes[RDocNodeKeys.blockJson];
    if (json is! Map) return null;
    final block = RBlock.tryParse({...Map<String, dynamic>.from(json), 'id': node.id});
    return block;
  }

  static String _dir(Node node) {
    final value = node.attributes[blockComponentTextDirection] as String?;
    return BlockDirection.values.contains(value) ? value! : BlockDirection.auto;
  }

  /// A delta back to inline nodes: `\n` becomes a hard break, a run with a mention or term id becomes that node,
  /// `false` attributes (AppFlowy's "toggled off") are no marks, and links keep http(s) only.
  static List<RInline> inlinesFrom(Delta? delta) {
    if (delta == null) return const [];
    final out = <RInline>[];
    for (final op in delta.whereType<TextInsert>()) {
      final attributes = op.attributes ?? const {};
      final mention = attributes[RDocNodeKeys.mention];
      final term = attributes[RDocNodeKeys.term];
      final parts = op.text.split('\n');
      for (final (i, part) in parts.indexed) {
        if (i > 0) out.add(const RHardBreak());
        if (part.isEmpty) continue;
        if (mention is String && mention.isNotEmpty) {
          out.add(RMention(userId: mention, text: part));
        } else if (term is String && term.isNotEmpty) {
          out.add(RTerm(termId: term, text: part));
        } else {
          out.add(RText(part, marks: _marks(attributes)));
        }
      }
    }
    return InlineEditing.normalize(out);
  }

  static List<RMark> _marks(Map<String, dynamic> attributes) => [
        for (final e in attributes.entries)
          ?switch (e.key) {
            _ when e.value == false || e.value == null => null,
            final k when k == AppFlowyRichTextKeys.bold => const RMark(RMarkType.bold),
            final k when k == AppFlowyRichTextKeys.italic => const RMark(RMarkType.italic),
            final k when k == AppFlowyRichTextKeys.code => const RMark(RMarkType.code),
            final k when k == AppFlowyRichTextKeys.strikethrough => const RMark(RMarkType.strike),
            final k when k == AppFlowyRichTextKeys.href =>
              e.value is String && InlineEditing.isHttpUrl(e.value as String) ? RMark(RMarkType.link, href: (e.value as String).trim()) : null,
            RDocNodeKeys.highlight => const RMark(RMarkType.highlight),
            _ => null,
          },
      ];
}
