import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/rdoc_view.dart';
import 'appflowy_block_editor_controller.dart';
import 'rdoc_appflowy_codec.dart';

/// What the custom blocks need from the surface: the controller, the uploads, and the edit sheets.
class RDocEditorScope extends InheritedWidget {
  const RDocEditorScope({
    super.key,
    required super.child,
    required this.controller,
    required this.enabled,
    required this.problemBlockIds,
    required this.onEditBlock,
    required this.onPickImage,
    required this.onEditCallout,
    required this.onEditCite,
  });

  final AppFlowyBlockEditorController controller;
  final bool enabled;

  /// Blocks a publish check points at.
  final Set<String> problemBlockIds;

  /// Opens a structured block (steps, code, tabs, table, image, embed) in its sheet.
  final ValueChanged<RBlock> onEditBlock;

  /// Chooses and uploads the image of an empty image block.
  final Future<void> Function(RImage block) onPickImage;
  final ValueChanged<RCallout> onEditCallout;
  final ValueChanged<RQuote> onEditCite;

  static RDocEditorScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<RDocEditorScope>()!;

  @override
  bool updateShouldNotify(RDocEditorScope old) =>
      old.controller != controller || old.enabled != enabled || old.problemBlockIds != problemBlockIds;
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

class _Quote extends StatelessWidget {
  const _Quote({required this.block, required this.direction, required this.text});

  final RQuote block;
  final TextDirection direction;
  final Widget text;

  @override
  Widget build(BuildContext context) {
    final scope = RDocEditorScope.of(context);
    final cite = block.cite;
    final empty = cite == null || cite.isEmpty;
    return Directionality(
      textDirection: direction,
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s4),
        decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: context.colors.primary, width: 3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            InkWell(
              key: ValueKey('quote-cite-${block.id}'),
              onTap: scope.enabled ? () => scope.onEditCite(block) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
                child: Text(
                  empty ? '— ${context.l10n.quoteCiteHint}' : '— ${Bidi.isolateOppositeRuns(cite, direction)}',
                  style: context.textTheme.bodySmall?.copyWith(color: empty ? context.colors.textSecondary.withValues(alpha: 0.7) : null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final (bg, accent, icon, label) = switch (block.variant) {
      RCalloutVariant.tip => (colors.calloutTip, colors.calloutTipAccent, Icons.lightbulb_outline, l10n.calloutTip),
      RCalloutVariant.info => (colors.calloutInfo, colors.calloutInfoAccent, Icons.info_outline, l10n.calloutInfo),
      RCalloutVariant.warning => (colors.calloutWarning, colors.calloutWarningAccent, Icons.warning_amber_rounded, l10n.calloutWarning),
      RCalloutVariant.danger => (colors.calloutDanger, colors.calloutDangerAccent, Icons.dangerous_outlined, l10n.calloutDanger),
    };
    final title = block.title;
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon, color: accent, size: 22)),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    key: ValueKey('callout-settings-${block.id}'),
                    onTap: scope.enabled ? () => scope.onEditCallout(block) : null,
                    child: Text(
                      title == null || title.isEmpty ? label : Bidi.isolateOppositeRuns(title, direction),
                      style: style.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: title == null || title.isEmpty ? accent : null,
                      ),
                    ),
                  ),
                  text,
                ],
              ),
            ),
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

/// A structured block shown as readers will see it (the reader's own block widgets); a tap opens it in its sheet.
/// It takes the caret like AppFlowy's divider.
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
  bool _uploading = false;

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  Future<void> _pick(RDocEditorScope scope, RImage image) async {
    setState(() => _uploading = true);
    try {
      await scope.onPickImage(image);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = RDocEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final editorState = scope.controller.editorState;
    final block = RDocAppFlowyCodec.blockFor(node);
    if (block == null) return const SizedBox.shrink();
    final problem = scope.problemBlockIds.contains(block.id);
    final emptyImage = block is RImage && block.src.isEmpty;
    final missingAlt = block is RImage && block.src.isNotEmpty && block.alt.trim().isEmpty;

    final Widget preview = emptyImage
        ? AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(ReadInRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: _uploading
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(height: ReadInSpace.s2),
                        Text(l10n.uploadingLabel, style: context.textTheme.bodySmall),
                      ])
                    : FilledButton.tonalIcon(
                        key: ValueKey('image-choose-${block.id}'),
                        onPressed: scope.enabled ? () => _pick(scope, block) : null,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(l10n.imageChoose),
                      ),
              ),
            ),
          )
        : (block is REmbed && block.url.isEmpty)
            ? ListTile(
                leading: const Icon(Icons.smart_display_outlined),
                title: Text(l10n.blockEmbed),
                subtitle: Text(l10n.embedInvalid),
              )
            : IgnorePointer(child: RBlockView(block));

    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        preview,
        if (missingAlt)
          Padding(
            padding: const EdgeInsets.only(top: ReadInSpace.s1),
            child: Row(children: [
              Icon(Icons.error_outline_rounded, size: 16, color: colors.error),
              const SizedBox(width: ReadInSpace.s1),
              Expanded(child: Text(l10n.problemImageAlt, style: context.textTheme.bodySmall?.copyWith(color: colors.error))),
            ]),
          ),
      ],
    );
    child = Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: ValueKey('structured-${block.id}'),
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        onTap: scope.enabled && !emptyImage ? () => scope.onEditBlock(block) : null,
        child: Container(
          key: _bodyKey,
          padding: const EdgeInsets.all(ReadInSpace.s1),
          decoration: problem || missingAlt
              ? BoxDecoration(border: Border.all(color: colors.error), borderRadius: BorderRadius.circular(ReadInRadius.md))
              : null,
          child: child,
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
