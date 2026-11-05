import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_x.dart';
import '../../../core/theme/tokens.g.dart' show ReadInColors;
import '../rdoc_document.dart';
import 'rdoc_highlight_text.dart';

export 'rdoc_highlight_text.dart';

typedef RHighlightHandler = void Function(BuildContext context, HighlightSelection selection);
typedef RHighlightRemoveHandler = void Function(BuildContext context, String highlightId);
typedef RHighlightCountHandler = void Function(BuildContext context, Offset globalPosition, int count);

/// One of your highlights was tapped: [highlightId] to remove, and [count] readers when it is popular too (else 0).
typedef RHighlightMineTapHandler = void Function(BuildContext context, Offset globalPosition, String highlightId, int count);

/// Highlights for the RDoc tree below (F30): the marks to draw, by block id, and what the selection toolbar does.
/// Without it (the editor preview, post cards), or while not [enabled] ("Hide highlights"), blocks render as before:
/// no marks, no selection.
class RDocHighlights extends InheritedWidget {
  const RDocHighlights({
    super.key,
    required super.child,
    this.enabled = true,
    this.marks = const {},
    this.canHighlight = true,
    required this.onHighlight,
    required this.onRemove,
    this.onCountTap,
    this.onMineTap,
  });

  /// Off while highlights are hidden: the same tree, so the reader keeps its place when they are toggled.
  final bool enabled;

  /// Your highlights and the popular ranges, by block id (block plain-text offsets).
  final Map<String, List<RHighlightMark>> marks;

  /// The toolbar offers Highlight and Remove: members with `highlights.create`, and guests (Highlight asks them to sign
  /// in; they have none to remove).
  final bool canHighlight;

  /// Highlight was tapped: an [HighlightSelectionStatus.ok] or [HighlightSelectionStatus.tooLong] selection.
  final RHighlightHandler onHighlight;

  /// Remove was tapped inside one of your highlights.
  final RHighlightRemoveHandler onRemove;

  /// A popular range was tapped: "N readers highlighted this".
  final RHighlightCountHandler? onCountTap;

  /// One of your highlights was tapped (with [canHighlight]): offer Remove, as selecting inside it does. Without it, a
  /// tap on yours shows only the count, when it is popular too.
  final RHighlightMineTapHandler? onMineTap;

  /// The enclosing highlights, or null when there are none or they are hidden.
  static RDocHighlights? maybeOf(BuildContext context) {
    final highlights = context.dependOnInheritedWidgetOfExactType<RDocHighlights>();
    return highlights != null && highlights.enabled ? highlights : null;
  }

  List<RHighlightMark> marksFor(String blockId) => marks[blockId] ?? const [];

  @override
  bool updateShouldNotify(RDocHighlights old) =>
      old.enabled != enabled || old.canHighlight != canHighlight || !_sameMarks(old.marks, marks);

  static bool _sameMarks(Map<String, List<RHighlightMark>> a, Map<String, List<RHighlightMark>> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!listEquals(entry.value, b[entry.key])) return false;
    }
    return true;
  }
}

/// How a marked piece of text looks (SPEC F30, colors from the tokens in light and dark): yours an amber underline with
/// a soft background, popular ones a lighter underline. The text itself, and so its direction, never changes.
TextStyle highlightPieceStyle(TextStyle style, RHighlightPiece piece, ReadInColors colors) {
  if (piece.isPlain) return style;
  final existing = style.decoration;
  final underline = existing == null || existing == TextDecoration.none
      ? TextDecoration.underline
      : TextDecoration.combine([existing, TextDecoration.underline]);
  return style.copyWith(
    backgroundColor: piece.mine ? colors.accentContainer : null,
    decoration: underline,
    decorationColor: piece.mine ? colors.accent : colors.accent.withValues(alpha: 0.55),
    decorationStyle: TextDecorationStyle.solid,
    decorationThickness: 2,
  );
}

/// A highlightable block (paragraph, heading, list, quote, callout, summary) under [RDocHighlights]: long-press
/// selection with the toolbar's **Highlight**, or **Remove** inside one of your highlights, next to Copy and Select all.
/// Its text units ([RHighlightUnit]) report what is selected; the first one holding part of the selection decides
/// ([mapBlockSelection]). Each block selects on its own, so a selection never leaves the block it started in.
class RHighlightableBlock extends StatefulWidget {
  const RHighlightableBlock({super.key, required this.block, required this.text, required this.child});

  final RBlock block;
  final RBlockText text;
  final Widget child;

  @override
  State<RHighlightableBlock> createState() => _RHighlightableBlockState();
}

class _RHighlightableBlockState extends State<RHighlightableBlock> {
  final _units = <int, _RHighlightUnitState>{};

  void _attach(int unit, _RHighlightUnitState state) => _units[unit] = state;

  void _detach(int unit, _RHighlightUnitState state) {
    if (_units[unit] == state) _units.remove(unit);
  }

  /// What the current selection maps to.
  HighlightSelection _selection() {
    final rendered = <String>[];
    final selected = <RenderedRange?>[];
    for (final unit in widget.text.units) {
      final state = _units[unit.index];
      rendered.add(state?.widget.rendered ?? '');
      selected.add(state?.selected);
    }
    return mapBlockSelection(widget.block, rendered, selected);
  }

  /// The toolbar, built in the overlay ([menuContext]); the highlights are this block's, read without depending on
  /// them (the toolbar is rebuilt for every selection anyway).
  Widget _toolbar(BuildContext menuContext, SelectableRegionState region) {
    final found = context.getInheritedWidgetOfExactType<RDocHighlights>();
    final highlights = found != null && found.enabled ? found : null;
    final l10n = menuContext.l10n;
    final selection = _selection();
    final range = selection.range;
    // Remove needs the same permission as Highlight (`DELETE /highlights/{id}`, `highlights.create`).
    final own = range == null || highlights == null || !highlights.canHighlight
        ? null
        : highlights
            .marksFor(widget.block.id)
            .where((m) => m.isRemovable && m.start <= range.startOffset && range.endOffset <= m.end)
            .firstOrNull;
    final canHighlight = highlights != null &&
        highlights.canHighlight &&
        (selection.status == HighlightSelectionStatus.ok || selection.status == HighlightSelectionStatus.tooLong);

    void done() {
      region
        ..hideToolbar()
        ..clearSelection();
    }

    final items = <ContextMenuButtonItem>[
      if (own != null)
        ContextMenuButtonItem(
          label: l10n.highlightRemove,
          onPressed: () {
            done();
            highlights!.onRemove(context, own.id!);
          },
        )
      else if (canHighlight)
        ContextMenuButtonItem(
          label: l10n.highlightAction,
          onPressed: () {
            done();
            highlights.onHighlight(context, selection);
          },
        ),
      ...region.contextMenuButtonItems,
    ];
    return AdaptiveTextSelectionToolbar(anchors: region.contextMenuAnchors, children: _buttons(menuContext, items));
  }

  /// The platform's toolbar buttons. On Android the labels take the app's font (IBM Plex, SPEC §15.3), like every other
  /// menu, rather than the system one the stock buttons fall back to.
  static List<Widget> _buttons(BuildContext context, List<ContextMenuButtonItem> items) {
    final platform = Theme.of(context).platform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.fuchsia) {
      return AdaptiveTextSelectionToolbar.getAdaptiveButtons(context, items).toList();
    }
    final font = Theme.of(context).textTheme.labelLarge;
    final style = TextStyle(fontFamily: font?.fontFamily, fontFamilyFallback: font?.fontFamilyFallback);
    return [
      for (var i = 0; i < items.length; i++)
        TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(i, items.length),
          onPressed: items[i].onPressed,
          alignment: AlignmentDirectional.centerStart,
          child: Text(AdaptiveTextSelectionToolbar.getButtonLabel(context, items[i]), style: style),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final highlights = RDocHighlights.maybeOf(context);
    return SelectionArea(
      contextMenuBuilder: _toolbar,
      child: RHighlightUnits._(
        this,
        text: widget.text,
        marks: highlights?.marksFor(widget.block.id) ?? const [],
        onCountTap: highlights?.onCountTap,
        // Remove needs the same permission as Highlight.
        onMineTap: highlights != null && highlights.canHighlight ? highlights.onMineTap : null,
        child: widget.child,
      ),
    );
  }
}

/// The block's text units and marks, for its [RDocText]s: each draws its unit's pieces and reports its selection.
class RHighlightUnits extends InheritedWidget {
  const RHighlightUnits._(
    this._state, {
    required this.text,
    required this.marks,
    required this.onCountTap,
    required this.onMineTap,
    required super.child,
  });

  final _RHighlightableBlockState _state;
  final RBlockText text;
  final List<RHighlightMark> marks;
  final RHighlightCountHandler? onCountTap;
  final RHighlightMineTapHandler? onMineTap;

  static RHighlightUnits? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<RHighlightUnits>();

  /// The pieces unit [index] is drawn in, or null when the block has no such unit.
  List<RHighlightPiece>? piecesFor(int index) {
    final unit = text.units.where((u) => u.index == index).firstOrNull;
    return unit == null ? null : highlightPieces(unit, marks);
  }

  /// Your highlight (one the API has, so it can be removed) under unit-local plain offset [offset] of unit [index].
  RHighlightMark? removableAt(int index, int offset) {
    final unit = text.units.where((u) => u.index == index).firstOrNull;
    if (unit == null) return null;
    final at = unit.start + offset;
    return marks.where((m) => m.isRemovable && m.start <= at && at < m.end).firstOrNull;
  }

  @override
  bool updateShouldNotify(RHighlightUnits old) =>
      old._state != _state ||
      old.text.text != text.text ||
      !listEquals(old.marks, marks) ||
      (old.onCountTap == null) != (onCountTap == null) ||
      (old.onMineTap == null) != (onMineTap == null);
}

/// One text unit of a highlightable block (its content, or a list item): reports the part of the selection inside it,
/// in its [rendered] string (the renderer's isolates included).
class RHighlightUnit extends StatefulWidget {
  const RHighlightUnit({super.key, required this.unit, required this.rendered, required this.child});

  final int unit;

  /// The unit's text as drawn: its inline nodes' [renderedInlineText] in order.
  final String rendered;
  final Widget child;

  @override
  State<RHighlightUnit> createState() => _RHighlightUnitState();
}

class _RHighlightUnitState extends State<RHighlightUnit> {
  // One per SelectionListener: a notifier can't serve two listeners, even for a frame.
  final _notifier = SelectionListenerNotifier();
  _RHighlightableBlockState? _block;

  /// The selected part, or null when the selection doesn't reach this unit.
  RenderedRange? get selected {
    if (!_notifier.registered) return null;
    final range = _notifier.selection.range;
    return range == null ? null : (base: range.startOffset, extent: range.endOffset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final block = RHighlightUnits.maybeOf(context)?._state;
    if (block == _block) return;
    _block?._detach(widget.unit, this);
    _block = block?.._attach(widget.unit, this);
  }

  @override
  void didUpdateWidget(RHighlightUnit old) {
    super.didUpdateWidget(old);
    if (old.unit != widget.unit) {
      _block
        ?.._detach(old.unit, this)
        .._attach(widget.unit, this);
    }
  }

  @override
  void dispose() {
    _block?._detach(widget.unit, this);
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectionListener(selectionNotifier: _notifier, child: widget.child);
}

/// Keeps text out of a highlightable block's selection: list bullets and numbers, the summary's label.
class RHighlightExcluded extends StatelessWidget {
  const RHighlightExcluded({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RHighlightUnits.maybeOf(context) == null ? child : SelectionContainer.disabled(child: child);
}

/// The block view for [block] under [RDocHighlights]: wrapped in [RHighlightableBlock] when it can be highlighted.
Widget withHighlights(BuildContext context, RBlock block, Widget child) {
  if (RDocHighlights.maybeOf(context) == null) return child;
  final text = RBlockText.of(block);
  return text == null ? child : RHighlightableBlock(block: block, text: text, child: child);
}
