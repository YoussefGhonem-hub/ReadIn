import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../../shared/rdoc/rdoc_scope.dart';
import '../block_editor/block_editor_controller.dart';
import '../block_editor/block_editor_surface.dart';
import '../block_editor/structured_block_sheet.dart';
import 'appflowy_block_components.dart';
import 'appflowy_block_editor_controller.dart';
import 'rdoc_appflowy_codec.dart';

/// The article editor's surface (F05, SPEC §3.3): AppFlowy Editor, with RDoc's blocks (custom components where
/// AppFlowy has none), marks, mentions and terms, per-block direction, markdown shortcuts and a mobile slash menu
/// (in the page's toolbar).
class AppFlowyBlockEditorSurface implements BlockEditorSurface {
  const AppFlowyBlockEditorSurface();

  @override
  BlockEditorController createController(RDocDocument document) => AppFlowyBlockEditorController(document: document);

  @override
  Widget build(BuildContext context, BlockEditorController controller, BlockEditorContext editorContext) =>
      AppFlowyRDocEditor(controller: controller as AppFlowyBlockEditorController, editorContext: editorContext);
}

/// RDoc markdown shortcuts on AppFlowy: `#`/`##` → H2, `###` → H3, `-`/`*` → bullets, `1.` → numbers, `>` → quote,
/// a triple backtick (with a language) → code, `---` → divider, and `**bold**`, `` `code` ``, `_italic_`, `~~strike~~`,
/// `[text](url)`.
final rdocCharacterShortcutEvents = <CharacterShortcutEvent>[
  insertNewLineAfterBulletedList,
  insertNewLineAfterNumberedList,
  insertNewLineAfterHeading,
  insertNewLine,
  formatAsteriskToBulletedList,
  formatMinusToBulletedList,
  formatNumberToNumberedList,
  rdocHeadingShortcut,
  rdocQuoteShortcut,
  rdocCodeShortcut,
  convertMinusesToDivider,
  formatBackquoteToCode,
  formatUnderscoreToItalic,
  formatAsteriskToItalic,
  formatTildeToStrikethrough,
  formatDoubleTilesToStrikethrough,
  formatDoubleAsterisksToBold,
  formatDoubleUnderscoresToBold,
  formatMarkdownLinkToLink,
];

/// `# ` and `## ` make an H2, `### ` an H3 (H1 is the article title).
final rdocHeadingShortcut = CharacterShortcutEvent(
  key: 'rdoc heading',
  character: ' ',
  handler: (editorState) => formatMarkdownSymbol(
    editorState,
    (node) => node.type == ParagraphBlockKeys.type,
    (_, text, _) => text == '#' || text == '##' || text == '###',
    (text, node, delta) => [
      Node(
        type: HeadingBlockKeys.type,
        attributes: {
          HeadingBlockKeys.level: text.length == 3 ? 3 : 2,
          blockComponentDelta: delta.compose(Delta()..delete(text.length)).toJson(),
          blockComponentTextDirection: ?node.attributes[blockComponentTextDirection],
        },
      ),
    ],
  ),
);

/// `> ` makes a quote.
final rdocQuoteShortcut = CharacterShortcutEvent(
  key: 'rdoc quote',
  character: ' ',
  handler: (editorState) => formatMarkdownSymbol(
    editorState,
    (node) => node.type == ParagraphBlockKeys.type,
    (_, text, _) => text == '>',
    (text, node, delta) => [
      Node(
        type: QuoteBlockKeys.type,
        attributes: {
          blockComponentDelta: delta.compose(Delta()..delete(1)).toJson(),
          blockComponentTextDirection: ?node.attributes[blockComponentTextDirection],
        },
      ),
    ],
  ),
);

final _fence = RegExp(r'^```([a-z0-9+#.-]{0,32})$');

/// ```` ```lang ```` and a space make a code block.
final rdocCodeShortcut = CharacterShortcutEvent(
  key: 'rdoc code',
  character: ' ',
  handler: (editorState) => formatMarkdownSymbol(
    editorState,
    (node) => node.type == ParagraphBlockKeys.type && (node.delta?.toPlainText().startsWith('```') ?? false),
    (_, text, _) => _fence.hasMatch(text),
    (text, node, delta) {
      final lang = _fence.firstMatch(text)!.group(1)!;
      return [
        RDocAppFlowyCodec.blockNode(RCode(BlockIds.generate(const {}), lang: lang.isEmpty ? 'plaintext' : lang, code: '')),
        Node(type: ParagraphBlockKeys.type, attributes: {blockComponentDelta: Delta().toJson()}),
      ];
    },
  ),
);

/// The AppFlowy editor with ReadIn's styles (SPEC §15): the reader's body font and sizes, token colors, highlight,
/// mentions and glossary terms.
class AppFlowyRDocEditor extends StatelessWidget {
  const AppFlowyRDocEditor({super.key, required this.controller, required this.editorContext});

  final AppFlowyBlockEditorController controller;
  final BlockEditorContext editorContext;

  TextDirection _direction(BuildContext context, Node node) {
    final dir = node.attributes[blockComponentTextDirection] as String?;
    return Bidi.resolve(dir, node.delta?.toPlainText() ?? '', fallback: RDocScope.of(context).baseDirection);
  }

  /// The body font follows the block's script, as in the reader.
  TextStyle _font(BuildContext context, Node node) {
    final rtl = _direction(context, node) == TextDirection.rtl;
    return TextStyle(
      fontFamily: rtl ? ReadInFonts.arabic : ReadInFonts.latin,
      fontFamilyFallback: [rtl ? ReadInFonts.latin : ReadInFonts.arabic],
    );
  }

  InlineSpan _decorate(BuildContext context, Node node, int index, TextInsert text, TextSpan before, TextSpan after) {
    final colors = context.colors;
    final attributes = text.attributes ?? const {};
    var style = before.style ?? const TextStyle();
    if (attributes[RDocNodeKeys.highlight] == true) style = style.copyWith(backgroundColor: colors.highlight);
    if (attributes[RDocNodeKeys.mention] != null) style = style.copyWith(color: colors.primary, fontWeight: FontWeight.w600);
    if (attributes[RDocNodeKeys.term] != null) {
      style = style.copyWith(
        color: colors.primary,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: colors.primary,
      );
    }
    return TextSpan(text: text.text, style: style);
  }

  EditorStyle _style(BuildContext context) {
    final colors = context.colors;
    final direction = RDocScope.of(context).baseDirection;
    final body = rdocBodyStyle(context, direction);
    return EditorStyle.mobile(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
      cursorColor: colors.primary,
      dragHandleColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.22),
      defaultTextDirection: BlockDirection.auto,
      textStyleConfiguration: TextStyleConfiguration(
        text: body,
        bold: const TextStyle(fontWeight: FontWeight.w700),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        strikethrough: TextStyle(decoration: TextDecoration.lineThrough, decorationColor: colors.textSecondary),
        href: TextStyle(color: colors.link, decoration: TextDecoration.underline, decorationColor: colors.link),
        code: codeTextStyle(size: (body.fontSize ?? ReadInType.bodySize) * 0.88, color: colors.textPrimary)
            .copyWith(backgroundColor: colors.surfaceVariant),
      ),
      textSpanDecorator: _decorate,
    );
  }

  Map<String, BlockComponentBuilder> _builders(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final scale = RDocScope.of(context).scale;
    final onlyBlock = controller.editorState.document.root.children.length <= 1;
    final config = BlockComponentConfiguration(
      padding: (_) => const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
      textStyle: (node, {textSpan}) => _font(context, node),
      placeholderTextStyle: (node, {textSpan}) => _font(context, node).copyWith(color: colors.textSecondary),
    );
    return {
      PageBlockKeys.type: PageBlockComponentBuilder(),
      ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
        configuration: config.copyWith(placeholderText: (_) => onlyBlock ? l10n.editorStartWriting : ' '),
      ),
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: config.copyWith(
          padding: (_) => const EdgeInsets.only(top: ReadInSpace.s3, bottom: ReadInSpace.s1),
          placeholderText: (node) => node.attributes[HeadingBlockKeys.level] == 3 ? l10n.blockHeading3 : l10n.blockHeading2,
        ),
        textStyleBuilder: (level) => TextStyle(
          fontSize: (level >= 3 ? ReadInType.uiLgSize + 3 : ReadInType.h3Size) * scale,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: config.copyWith(placeholderText: (_) => l10n.listItemHint),
        iconBuilder: (context, node) => _ListMarker(node: node, ordered: false),
      ),
      NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
        configuration: config.copyWith(placeholderText: (_) => l10n.listItemHint),
        iconBuilder: (context, node, _) => _ListMarker(node: node, ordered: true),
      ),
      QuoteBlockKeys.type: RDocTextBlockComponentBuilder(
        kind: RDocTextBlockKind.quote,
        configuration: config.copyWith(
          placeholderText: (_) => l10n.blockQuote,
          textStyle: (node, {textSpan}) => _font(context, node).copyWith(fontStyle: FontStyle.italic),
        ),
      ),
      RDocNodeKeys.callout: RDocTextBlockComponentBuilder(
        kind: RDocTextBlockKind.callout,
        configuration: config.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
          placeholderText: (_) => l10n.blockCallout,
        ),
      ),
      RDocNodeKeys.summary: RDocTextBlockComponentBuilder(
        kind: RDocTextBlockKind.summary,
        configuration: config.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
          placeholderText: (_) => l10n.blockSummary,
        ),
      ),
      DividerBlockKeys.type: DividerBlockComponentBuilder(
        lineColor: colors.border,
        configuration: config.copyWith(padding: (_) => const EdgeInsets.symmetric(vertical: ReadInSpace.s3)),
      ),
      RDocNodeKeys.block: RDocStructuredBlockComponentBuilder(
        configuration: config.copyWith(padding: (_) => const EdgeInsets.symmetric(vertical: ReadInSpace.s2)),
      ),
    };
  }

  Future<void> _pickImage(RImage image) async {
    final file = await editorContext.pickImage();
    if (file == null) return;
    final asset = await editorContext.uploadImage(file);
    if (asset == null || asset.variants.isEmpty) return;
    controller.updateBlock(RImage(
      image.id,
      src: asset.variants.last.url,
      alt: image.alt,
      darkSrc: image.darkSrc,
      caption: image.caption,
      width: asset.width,
      height: asset.height,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RDocEditorScope(
      controller: controller,
      enabled: editorContext.enabled,
      problemBlockIds: editorContext.problemBlockIds,
      onEditBlock: (block) async {
        final edited = await showStructuredBlockSheet(context, block, editorContext);
        if (edited != null) controller.updateBlock(edited);
      },
      onPickImage: _pickImage,
      onEditCallout: (callout) async {
        final result = await showCalloutSheet(context, callout);
        if (result != null) {
          controller.updateAttributes(callout.id, {RDocNodeKeys.variant: result.variant.name, RDocNodeKeys.title: result.title});
        }
      },
      onEditCite: (quote) async {
        final cite = await showTextDialog(context, label: l10n.quoteCiteHint, initial: quote.cite);
        if (cite != null) controller.updateAttributes(quote.id, {RDocNodeKeys.cite: cite.isEmpty ? null : cite});
      },
      child: AppFlowyEditor(
        key: ValueKey('appflowy-${controller.generation}'),
        editorState: controller.editorState,
        editable: editorContext.enabled,
        editorStyle: _style(context),
        blockComponentBuilders: _builders(context),
        characterShortcutEvents: rdocCharacterShortcutEvents,
        commandShortcutEvents: standardCommandShortcutEvents,
        header: editorContext.header,
        footer: const SizedBox(height: ReadInSpace.s9),
      ),
    );
  }
}

/// The reader's list markers (SPEC §15): `•` or the item's number, in the primary color.
class _ListMarker extends StatelessWidget {
  const _ListMarker({required this.node, required this.ordered});

  final Node node;
  final bool ordered;

  /// 1-based position among the consecutive numbered items before it.
  int get _number {
    var n = 1;
    for (var previous = node.previous; previous != null && previous.type == node.type; previous = previous.previous) {
      n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Bidi.detect(node.delta?.toPlainText() ?? '') == TextDirection.rtl;
    final style = rdocBodyStyle(context, rtl ? TextDirection.rtl : TextDirection.ltr)
        .copyWith(color: context.colors.primary, fontWeight: FontWeight.w600);
    return SizedBox(width: 28, child: Text(ordered ? '$_number.' : '•', style: style));
  }
}
