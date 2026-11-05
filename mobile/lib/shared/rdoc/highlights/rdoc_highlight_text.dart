import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart' show TextDirection;

import '../../../core/bidi/bidi.dart';
import '../rdoc_document.dart';

/// Highlights (F30): a block's plain text, its text units, and the selection → range rules of
/// docs/api/contract-v1.md ("Highlights (F30)"). Offsets are UTF-16 code units (Dart [String] indexes) in the block's
/// plain text, end exclusive; `shared/rdoc/highlight-fixtures.json` holds the cases the backend and both clients agree
/// on.
abstract final class HighlightLimits {
  /// Fewer code units after trimming: no Highlight button.
  static const minLength = 3;

  /// More: the `highlight.too_long` message, without calling the API.
  static const maxLength = 1000;
}

/// The isolate and embedding characters a renderer inserts (U+2066–U+2069, U+202A–U+202E). They never count: stored
/// content never holds them, and the renderer's own are dropped when a selection is mapped.
bool isBidiControl(int codeUnit) => (codeUnit >= 0x2066 && codeUnit <= 0x2069) || (codeUnit >= 0x202A && codeUnit <= 0x202E);

/// The whitespace trimmed at both ends of a highlight (the contract's list; never inside one).
bool isHighlightWhitespace(int codeUnit) =>
    (codeUnit >= 0x09 && codeUnit <= 0x0D) ||
    codeUnit == 0x20 ||
    codeUnit == 0x85 ||
    codeUnit == 0xA0 ||
    codeUnit == 0x1680 ||
    (codeUnit >= 0x2000 && codeUnit <= 0x200A) ||
    codeUnit == 0x2028 ||
    codeUnit == 0x2029 ||
    codeUnit == 0x202F ||
    codeUnit == 0x205F ||
    codeUnit == 0x3000;

/// The string the reader draws for one inline node in a block of [direction]: runs in the other script wrapped in
/// isolates, inline code as an LTR isolate, a hard break as `\n` (SPEC §14.2). Its characters other than
/// [isBidiControl] ones are exactly the node's plain text.
String renderedInlineText(RInline node, TextDirection direction) => switch (node) {
      RText(:final text) when node.has(RMarkType.code) => Bidi.ltrIsolate(text),
      RText(:final text) => Bidi.isolateOppositeRuns(text, direction),
      RTerm(:final text) => Bidi.isolateOppositeRuns(text, direction),
      RMention(:final text) => Bidi.isolateOppositeRuns(text, direction),
      RHardBreak() => '\n',
    };

/// The plain offset of [renderedOffset] in [rendered]: the characters before it, without the [isBidiControl] ones. A
/// point next to an isolate maps to the same plain offset on either side of it.
int plainOffsetOf(String rendered, int renderedOffset) {
  final end = renderedOffset.clamp(0, rendered.length);
  var plain = 0;
  for (var i = 0; i < end; i++) {
    if (!isBidiControl(rendered.codeUnitAt(i))) plain++;
  }
  return plain;
}

/// Where each plain offset of [rendered] sits in it: entry `p` is the rendered index of the `p`-th plain character
/// (after the isolates that open before it), and the last entry is the rendered string's end.
List<int> renderedOffsetsOf(String rendered) => [
      for (var i = 0; i < rendered.length; i++)
        if (!isBidiControl(rendered.codeUnitAt(i))) i,
      rendered.length,
    ];

/// One run of highlightable text: a whole block, or one list item (a highlight stays inside one item).
class RTextUnit {
  const RTextUnit({required this.index, required this.start, required this.nodes});

  /// 0, or the list item's index.
  final int index;

  /// Where it starts in the block's plain text.
  final int start;
  final List<RInline> nodes;

  String get text => plainTextOf(nodes);

  int get end => start + text.length;
}

/// A highlightable block's plain text (contract "Offsets"): its inline nodes in order (a mention gives its `@username`
/// text, a hard break `\n`, marks nothing); a list's items joined by one `\n`. A callout's title, a quote's cite, the
/// summary's label and list bullets are never part of it.
class RBlockText {
  const RBlockText._(this.blockId, this.text, this.units);

  final String blockId;
  final String text;
  final List<RTextUnit> units;

  /// Null for the blocks that can't be highlighted: code, code tabs, table, steps, image, divider, embed.
  static RBlockText? of(RBlock block) {
    List<RInline>? single;
    switch (block) {
      case RParagraph(:final content) || RHeading(:final content) || RQuote(:final content):
        single = content;
      case RCallout(:final content) || RSummary(:final content):
        single = content;
      case RList(:final items):
        final units = <RTextUnit>[];
        var start = 0;
        for (var i = 0; i < items.length; i++) {
          final unit = RTextUnit(index: i, start: start, nodes: items[i]);
          units.add(unit);
          start = unit.end + 1;
        }
        return RBlockText._(block.id, items.map(plainTextOf).join('\n'), units);
      default:
        return null;
    }
    return RBlockText._(block.id, plainTextOf(single), [RTextUnit(index: 0, start: 0, nodes: single)]);
  }

  /// The unit holding [offset] (a range starting there belongs to it), or null.
  RTextUnit? unitAt(int offset) => units.where((u) => offset >= u.start && offset <= u.end).firstOrNull;
}

/// A range of a block's plain text: what `POST /articles/{id}/highlights` takes (with the version's language).
class HighlightRange extends Equatable {
  const HighlightRange({required this.blockId, required this.startOffset, required this.endOffset, required this.text});

  final String blockId;
  final int startOffset;
  final int endOffset;

  /// Exactly the block's plain text between the offsets.
  final String text;

  int get length => endOffset - startOffset;

  /// [other] lies inside this range (same block).
  bool contains(HighlightRange other) =>
      other.blockId == blockId && other.startOffset >= startOffset && other.endOffset <= endOffset;

  Map<String, dynamic> toJson() => {'blockId': blockId, 'startOffset': startOffset, 'endOffset': endOffset, 'text': text};

  @override
  List<Object?> get props => [blockId, startOffset, endOffset, text];

  @override
  String toString() => 'HighlightRange($blockId, $startOffset–$endOffset, "$text")';
}

enum HighlightSelectionStatus {
  /// 3–1,000 code units: the toolbar offers Highlight.
  ok,

  /// Nothing (or fewer than 3 code units) left once trimmed: no Highlight button.
  tooShort,

  /// More than 1,000: Highlight shows `highlight.too_long` without calling the API.
  tooLong,

  /// The selection starts in a block that can't be highlighted: no toolbar.
  notAllowed,
}

/// What a selection in the reader maps to.
class HighlightSelection extends Equatable {
  const HighlightSelection(this.status, [this.range]);

  static const notAllowed = HighlightSelection(HighlightSelectionStatus.notAllowed);
  static const nothing = HighlightSelection(HighlightSelectionStatus.tooShort);

  final HighlightSelectionStatus status;

  /// The trimmed range: always for [HighlightSelectionStatus.ok] and [HighlightSelectionStatus.tooLong], and for a short
  /// one when something is left (a word inside one of your highlights still offers Remove).
  final HighlightRange? range;

  @override
  List<Object?> get props => [status, range];
}

/// The range a selection of unit [unit] of [block] covers, from [start] to [end] (unit-local plain offsets, either
/// order): clipped to the unit, then trimmed, then checked against [HighlightLimits].
HighlightSelection resolveHighlightSelection(RBlockText block, RTextUnit unit, int start, int end) {
  final length = unit.text.length;
  var from = unit.start + math.min(start, end).clamp(0, length);
  var to = unit.start + math.max(start, end).clamp(0, length);
  final text = block.text;
  while (from < to && isHighlightWhitespace(text.codeUnitAt(from))) {
    from++;
  }
  while (to > from && isHighlightWhitespace(text.codeUnitAt(to - 1))) {
    to--;
  }
  if (to <= from) return HighlightSelection.nothing;
  final range = HighlightRange(blockId: block.blockId, startOffset: from, endOffset: to, text: text.substring(from, to));
  final status = switch (range.length) {
    < HighlightLimits.minLength => HighlightSelectionStatus.tooShort,
    > HighlightLimits.maxLength => HighlightSelectionStatus.tooLong,
    _ => HighlightSelectionStatus.ok,
  };
  return HighlightSelection(status, range);
}

/// A selected part of one unit, as the reader's selection reports it: offsets in the unit's rendered string (its
/// isolates included), in either order.
typedef RenderedRange = ({int base, int extent});

/// Maps a selection in [block] to a highlight range (contract "Selection → range"): the first unit (list item) that
/// holds part of the selection decides; its part is taken without the renderer's isolates ([rendered] is each unit's
/// rendered string, [selected] each unit's selected part or null); then [resolveHighlightSelection]. A block that can't
/// be highlighted gives [HighlightSelection.notAllowed].
HighlightSelection mapBlockSelection(RBlock block, List<String> rendered, List<RenderedRange?> selected) {
  final text = RBlockText.of(block);
  if (text == null) return HighlightSelection.notAllowed;
  for (var i = 0; i < text.units.length && i < selected.length && i < rendered.length; i++) {
    final part = selected[i];
    if (part == null || part.base == part.extent) continue;
    final start = plainOffsetOf(rendered[i], math.min(part.base, part.extent));
    final end = plainOffsetOf(rendered[i], math.max(part.base, part.extent));
    return resolveHighlightSelection(text, text.units[i], start, end);
  }
  return HighlightSelection.nothing;
}

/// One highlight to draw in a block: one of yours ([mine]) or a popular range ([count] readers). Offsets in the
/// block's plain text.
class RHighlightMark extends Equatable {
  const RHighlightMark({required this.start, required this.end, this.mine = false, this.id, this.count = 0});

  final int start;
  final int end;

  /// One of your highlights.
  final bool mine;

  /// Yours, once the API has it: Remove deletes this id. Null while it is being created, and for popular ranges.
  final String? id;

  /// Readers who marked this exact range (popular, ≥ 3), or 0.
  final int count;

  /// Selecting inside it offers Remove.
  bool get isRemovable => mine && id != null;

  @override
  List<Object?> get props => [start, end, mine, id, count];
}

/// How a piece of a unit is drawn.
class RHighlightPiece extends Equatable {
  const RHighlightPiece({required this.start, required this.end, required this.mine, required this.count});

  /// Unit-local plain offsets.
  final int start;
  final int end;

  /// Inside one of your highlights: amber underline with a soft background.
  final bool mine;

  /// Inside a popular range: the most readers of the ranges covering it (0 for none). A lighter underline, unless it is
  /// also [mine]; tapping it shows the count.
  final int count;

  bool get isPlain => !mine && count == 0;

  @override
  List<Object?> get props => [start, end, mine, count];
}

/// Cuts unit [unit] into pieces by the [marks] of its block (block offsets): consecutive pieces covering the unit, each
/// either plain or marked. Text with no marks is one plain piece.
List<RHighlightPiece> highlightPieces(RTextUnit unit, List<RHighlightMark> marks) {
  final length = unit.end - unit.start;
  final local = [
    for (final m in marks)
      if (m.end > unit.start && m.start < unit.end)
        (start: math.max(m.start, unit.start) - unit.start, end: math.min(m.end, unit.end) - unit.start, mark: m),
  ];
  if (local.isEmpty || length == 0) return [RHighlightPiece(start: 0, end: length, mine: false, count: 0)];
  final cuts = <int>{0, length, for (final l in local) ...[l.start, l.end]}.toList()..sort();
  final pieces = <RHighlightPiece>[];
  for (var i = 0; i + 1 < cuts.length; i++) {
    final from = cuts[i];
    final to = cuts[i + 1];
    var mine = false;
    var count = 0;
    for (final l in local) {
      if (l.start <= from && l.end >= to) {
        mine = mine || l.mark.mine;
        count = math.max(count, l.mark.count);
      }
    }
    final piece = RHighlightPiece(start: from, end: to, mine: mine, count: count);
    // Neighbours drawn the same way stay one piece.
    final last = pieces.isEmpty ? null : pieces.last;
    if (last != null && last.mine == mine && last.count == count) {
      pieces[pieces.length - 1] = RHighlightPiece(start: last.start, end: to, mine: mine, count: count);
    } else {
      pieces.add(piece);
    }
  }
  return pieces;
}
