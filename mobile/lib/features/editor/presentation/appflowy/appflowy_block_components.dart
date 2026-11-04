import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../domain/entities/editor_entities.dart';
import '../block_editor/block_editors.dart';
import 'appflowy_block_editor_controller.dart';
import 'rdoc_appflowy_codec.dart';

/// What the custom blocks need from the surface: the controller and the publish checks' problem blocks. The inline
/// block editors also find a `BlockEditorScope` above the editor.
class RDocEditorScope extends InheritedWidget {
  const RDocEditorScope({
    super.key,
    required super.child,
    required this.controller,
    required this.enabled,
    required this.problemBlockIds,
  });

  final AppFlowyBlockEditorController controller;
  final bool enabled;

  /// Blocks a publish check points at.
  final Set<String> problemBlockIds;

  static RDocEditorScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<RDocEditorScope>()!;

  @override
  bool updateShouldNotify(RDocEditorScope old) =>
      old.controller != controller || old.enabled != enabled || old.problemBlockIds != problemBlockIds;
}

/// Fields inside a block (a table cell, the code, a callout's title) take the keyboard from AppFlowy: when one gets
/// focus, AppFlowy's selection is cleared, so only one caret shows and the toolbar formats that field.
class EditorFieldFocus extends StatelessWidget {
  const EditorFieldFocus({super.key, required this.editorState, required this.child});

  final EditorState editorState;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) {
          if (focused && editorState.selection != null) editorState.selection = null;
        },
        child: child,
      );
}

// ── Text blocks with chrome: quote (+ cite), callout (variant + title), TL;DR ──────────────

enum RDocTextBlockKind { quote, callout, summary }

class RDocTextBlockComponentBuilder extends BlockComponentBuilder {
  RDocTextBlockComponentBuilder({required this.kind, super.configuration});

  final RDocTextBlockKind kind;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return RDocTextBlockComponent(
      key: node.key,
      node: node,
      kind: kind,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(blockComponentContext, state),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(blockComponentContext, state),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.delta != null;
}

class RDocTextBlockComponent extends BlockComponentStatefulWidget {
  const RDocTextBlockComponent({
    super.key,
    required super.node,
    required this.kind,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  final RDocTextBlockKind kind;

  @override
  State<RDocTextBlockComponent> createState() => _RDocTextBlockComponentState();
}

class _RDocTextBlockComponentState extends State<RDocTextBlockComponent>
    with SelectableMixin, DefaultSelectableMixin, BlockComponentConfigurable, BlockComponentTextDirectionMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(debugLabel: 'rdoc_text_block');

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late final editorState = RDocEditorScope.of(context).controller.editorState;

  Widget _richText(TextDirection direction) => AppFlowyRichText(
        key: forwardKey,
        delegate: this,
        node: widget.node,
        editorState: editorState,
        textAlign: textAlign,
        placeholderText: placeholderText,
        textSpanDecorator: (span) => span.updateTextStyle(textStyleWithTextSpan(textSpan: span)),
        placeholderTextSpanDecorator: (span) => span.updateTextStyle(placeholderTextStyleWithTextSpan(textSpan: span)),
        textDirection: direction,
        cursorColor: editorState.editorStyle.cursorColor,
        selectionColor: editorState.editorStyle.selectionColor,
        cursorWidth: editorState.editorStyle.cursorWidth,
      );

  @override
  Widget build(BuildContext context) {
    final direction = calculateTextDirection(layoutDirection: Directionality.maybeOf(context));
    final block = RDocAppFlowyCodec.blockFor(node);
    Widget child = switch (block) {
      final RQuote q => _Quote(block: q, direction: direction, text: _richText(direction)),
      final RCallout c => _Callout(block: c, direction: direction, text: _richText(direction)),
      _ => SummaryBox(direction: direction, child: _richText(direction)),
    };
    child = Container(key: blockComponentKey, padding: padding, child: child);
    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );
    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }
    return Padding(padding: margin, child: child);
  }
}

/// A quote: its text, then "— who said it" edited in place (as the web editor's quote).
class _Quote extends StatelessWidget {
  const _Quote({required this.block, required this.direction, required this.text});

  final RQuote block;
  final TextDirection direction;
  final Widget text;

  @override
  Widget build(BuildContext context) {
    final scope = RDocEditorScope.of(context);
    final style = context.textTheme.bodySmall!;
    return Directionality(
      textDirection: direction,
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s4),
        decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: context.colors.primary, width: 3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
              child: Row(
                children: [
                  ExcludeSemantics(child: Text('— ', style: style)),
                  Expanded(
                    child: EditorFieldFocus(
                      editorState: scope.controller.editorState,
                      child: PlainField(
                        fieldKey: ValueKey('quote-cite-${block.id}'),
                        value: block.cite ?? '',
                        hint: context.l10n.quoteCiteHint,
                        maxLength: DraftLimits.maxPlainText,
                        style: style,
                        onChanged: (v) => scope.controller.updateAttributes(block.id, {RDocNodeKeys.cite: v.isEmpty ? null : v}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A callout: the variant and the title in its head, edited in place (as the web editor's callout), then its text.
class _Callout extends StatelessWidget {
  const _Callout({required this.block, required this.direction, required this.text});

  final RCallout block;
  final TextDirection direction;
  final Widget text;

  @override
  Widget build(BuildContext context) {
    final scope = RDocEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    (Color, Color, IconData, String) look(RCalloutVariant v) => switch (v) {
          RCalloutVariant.tip => (colors.calloutTip, colors.calloutTipAccent, Icons.lightbulb_outline, l10n.calloutTip),
          RCalloutVariant.info => (colors.calloutInfo, colors.calloutInfoAccent, Icons.info_outline, l10n.calloutInfo),
          RCalloutVariant.warning => (colors.calloutWarning, colors.calloutWarningAccent, Icons.warning_amber_rounded, l10n.calloutWarning),
          RCalloutVariant.danger => (colors.calloutDanger, colors.calloutDangerAccent, Icons.dangerous_outlined, l10n.calloutDanger),
        };
    final (bg, accent, _, _) = look(block.variant);
    final style = rdocBodyStyle(context, direction, factor: 0.94);
    return Directionality(
      textDirection: direction,
      child: Container(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: BorderDirectional(start: BorderSide(color: accent, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorFieldFocus(
              editorState: scope.controller.editorState,
              child: Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<RCalloutVariant>(
                      key: ValueKey('callout-variant-${block.id}'),
                      value: block.variant,
                      isDense: true,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: accent),
                      menuWidth: 200,
                      selectedItemBuilder: (context) => [
                        for (final v in RCalloutVariant.values) Icon(look(v).$3, color: look(v).$2, size: 22, semanticLabel: look(v).$4),
                      ],
                      items: [
                        for (final v in RCalloutVariant.values)
                          DropdownMenuItem(
                            value: v,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(look(v).$3, color: look(v).$2, size: 20),
                                const SizedBox(width: ReadInSpace.s2),
                                Text(look(v).$4),
                              ],
                            ),
                          ),
                      ],
                      onChanged: scope.enabled
                          ? (v) => scope.controller.updateAttributes(block.id, {RDocNodeKeys.variant: (v ?? block.variant).name})
                          : null,
                    ),
                  ),
                  const SizedBox(width: ReadInSpace.s2),
                  Expanded(
                    child: PlainField(
                      fieldKey: ValueKey('callout-title-${block.id}'),
                      value: block.title ?? '',
                      hint: l10n.calloutTitleHint,
                      maxLength: DraftLimits.maxPlainText,
                      style: style.copyWith(fontWeight: FontWeight.w700, height: 1.5),
                      onChanged: (v) => scope.controller.updateAttributes(block.id, {RDocNodeKeys.title: v.isEmpty ? null : v}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ReadInSpace.s1),
            text,
          ],
        ),
      ),
    );
  }
}

// ── Structured blocks: steps, code, code tabs, table, image, embed ─────────────────────────

class RDocStructuredBlockComponentBuilder extends BlockComponentBuilder {
  RDocStructuredBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return RDocStructuredBlockComponent(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(blockComponentContext, state),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.attributes[RDocNodeKeys.blockJson] is Map;
}

/// A structured block edited in place with its inline editor ([StructuredBlockEditor]), as the web editor's node
/// views: every change is one undoable transaction. Outside its fields it takes the caret like AppFlowy's divider.
class RDocStructuredBlockComponent extends BlockComponentStatefulWidget {
  const RDocStructuredBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<RDocStructuredBlockComponent> createState() => _RDocStructuredBlockComponentState();
}

class _RDocStructuredBlockComponentState extends State<RDocStructuredBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final _bodyKey = GlobalKey();

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  @override
  Widget build(BuildContext context) {
    final scope = RDocEditorScope.of(context);
    final colors = context.colors;
    final editorState = scope.controller.editorState;
    final block = RDocAppFlowyCodec.blockFor(node);
    if (block == null) return const SizedBox.shrink();
    final problem = scope.problemBlockIds.contains(block.id);
    final missingAlt = block is RImage && block.src.isNotEmpty && block.alt.trim().isEmpty;

    Widget child = Material(
      type: MaterialType.transparency,
      child: Container(
        key: _bodyKey,
        padding: const EdgeInsets.all(ReadInSpace.s1),
        decoration: problem || missingAlt
            ? BoxDecoration(border: Border.all(color: colors.error), borderRadius: BorderRadius.circular(ReadInRadius.md))
            : null,
        child: EditorFieldFocus(
          editorState: editorState,
          child: KeyedSubtree(key: ValueKey('structured-${block.id}'), child: StructuredBlockEditor(block: block)),
        ),
      ),
    );
    child = Padding(padding: padding, child: child);
    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      cursorColor: editorState.editorStyle.cursorColor,
      selectionColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block, BlockSelectionType.cursor, BlockSelectionType.selection],
      child: child,
    );
    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(node: node, actionBuilder: widget.actionBuilder!, child: child);
    }
    return Padding(padding: margin, child: child);
  }

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) => getRectsInSelection(Selection.invalid()).first;

  @override
  Rect? getCursorRectInPosition(Position position, {bool shiftWithBaseOffset = false}) {
    if (_renderBox == null) return null;
    return getRectsInSelection(Selection.collapsed(position), shiftWithBaseOffset: shiftWithBaseOffset).firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(Selection selection, {bool shiftWithBaseOffset = false}) {
    if (_renderBox == null) return [];
    final parentBox = context.findRenderObject();
    final body = _bodyKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && body is RenderBox) {
      return [(shiftWithBaseOffset ? body.localToGlobal(Offset.zero, ancestor: parentBox) : Offset.zero) & body.size];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) => _renderBox!.localToGlobal(offset);

  @override
  TextDirection textDirection() => TextDirection.ltr;
}
