import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/inline_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../comments/domain/entities/comment_text.dart';
import 'inline_formatter.dart';

/// Called when the writer presses Enter in a block that splits: [before] stays, [after] are the new paragraphs
/// below (one per typed or pasted line break).
typedef InlineSplitCallback = void Function(List<RInline> before, List<List<RInline>> after);

/// A [TextEditingController] over RDoc inline content: the field shows the plain text, and every edit is applied to
/// the nodes with [InlineEditing], so marks, links, mentions and glossary terms stay where they are. It draws the
/// marks while editing, and applies the inline markdown shortcuts (`**bold**`, `` `code` ``, `~~strike~~`).
class InlineTextController extends TextEditingController implements InlineFormatter {
  InlineTextController({List<RInline> nodes = const [], this.onSplit, this.onNodesChanged})
      : _nodes = InlineEditing.normalize(nodes),
        super(text: plainTextOf(nodes));

  /// Enter splits the block; without it, a line break becomes a hard break inside the block.
  InlineSplitCallback? onSplit;

  /// The nodes after every edit.
  ValueChanged<List<RInline>>? onNodesChanged;

  List<RInline> _nodes;
  List<RMark>? _pendingMarks;

  List<RInline> get nodes => _nodes;

  /// Replaces the content from outside (a reload); keeps the caret where it fits.
  set nodes(List<RInline> nodes) {
    final next = InlineEditing.normalize(nodes);
    if (_listEquals(next, _nodes)) return;
    _nodes = next;
    final text = plainTextOf(next);
    final offset = selection.isValid ? selection.extentOffset.clamp(0, text.length) : text.length;
    super.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }

  static bool _listEquals(List<RInline> a, List<RInline> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  set value(TextEditingValue newValue) {
    final old = super.value;
    if (newValue.text == old.text) {
      if (newValue.selection != old.selection) _pendingMarks = null;
      super.value = newValue;
      return;
    }
    final caret = newValue.selection.isValid ? newValue.selection.extentOffset : null;
    final change = InlineEditing.diff(old.text, newValue.text, caret: caret);
    final marks = _pendingMarks;
    _pendingMarks = null;

    if (change.insert.contains('\n')) {
      final lines = change.insert.split('\n');
      final split = onSplit;
      if (split != null) {
        final head = InlineEditing.replaceRange(_nodes, change.start, change.end, lines.first, marks: marks);
        final (before, after) = InlineEditing.splitAt(head.nodes, head.caret);
        final rest = [for (final line in lines.skip(1).take(lines.length - 2)) InlineEditing.normalize([RText(line)])];
        final last = InlineEditing.replaceRange(after, 0, 0, lines.last).nodes;
        _commit(before, TextSelection.collapsed(offset: plainTextOf(before).length), notify: false);
        split(before, [...rest, last]);
        return;
      }
      // A line break inside the block.
      var result = InlineEditing.replaceRange(_nodes, change.start, change.end, lines.first, marks: marks);
      for (final line in lines.skip(1)) {
        result = InlineEditing.insertHardBreak(result.nodes, result.caret);
        result = InlineEditing.replaceRange(result.nodes, result.caret, result.caret, line, marks: marks);
      }
      _commit(result.nodes, TextSelection.collapsed(offset: result.caret));
      return;
    }

    var result = InlineEditing.replaceRange(_nodes, change.start, change.end, change.insert, marks: marks);
    if (change.insert.length == 1) result = MarkdownShortcuts.inlineShortcut(result.nodes, result.caret) ?? result;
    final text = plainTextOf(result.nodes);
    if (text == newValue.text) {
      _nodes = result.nodes;
      super.value = newValue;
      onNodesChanged?.call(_nodes);
    } else {
      _commit(result.nodes, TextSelection.collapsed(offset: result.caret));
    }
  }

  void _commit(List<RInline> nodes, TextSelection selection, {bool notify = true}) {
    _nodes = nodes;
    final text = plainTextOf(nodes);
    super.value = TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: selection.baseOffset.clamp(0, text.length),
        extentOffset: selection.extentOffset.clamp(0, text.length),
      ),
    );
    if (notify) onNodesChanged?.call(_nodes);
  }

  (int, int) get _range {
    final s = selection;
    if (!s.isValid) return (text.length, text.length);
    return (s.start, s.end);
  }

  @override
  bool hasMark(RMarkType type) {
    final (start, end) = _range;
    if (start == end) {
      return (_pendingMarks ?? InlineEditing.marksAt(_nodes, start)).any((m) => m.type == type);
    }
    return InlineEditing.hasMark(_nodes, start, end, type);
  }

  /// Bold, italic, code, highlight or strike on the selection; with a caret, for the next characters typed.
  @override
  void toggleMark(RMarkType type) {
    final (start, end) = _range;
    if (start == end) {
      final marks = _pendingMarks ?? InlineEditing.marksAt(_nodes, start);
      final on = marks.any((m) => m.type == type);
      _pendingMarks = [for (final m in marks) if (m.type != type) m, if (!on) RMark(type)];
      notifyListeners();
      return;
    }
    _commit(InlineEditing.toggleMark(_nodes, start, end, type), selection);
  }

  @override
  String? get link {
    final (start, end) = _range;
    return InlineEditing.linkAt(_nodes, start, end);
  }

  /// Links the selection to [href] (http/https), or unlinks it when null.
  @override
  void setLink(String? href) {
    final (start, end) = _range;
    if (start == end) return;
    _commit(InlineEditing.setLink(_nodes, start, end, href), selection);
  }

  @override
  void insertHardBreak() {
    final (start, end) = _range;
    final result = InlineEditing.insertHardBreak(_nodes, start, end);
    _commit(result.nodes, TextSelection.collapsed(offset: result.caret));
  }

  /// The `@word` being typed (not inside an existing mention), for the suggestions.
  @override
  MentionQuery? get activeMention {
    final s = selection;
    if (!s.isValid || !s.isCollapsed) return null;
    final query = CommentText.activeMention(text, s.baseOffset);
    if (query == null) return null;
    var pos = 0;
    for (final node in _nodes) {
      final len = node.plainText.length;
      if (node is! RText && query.start >= pos && query.start < pos + len) return null;
      pos += len;
    }
    return query;
  }

  /// Replaces the typed `@word` with a mention of [userId] shown as [text] (`@username`).
  @override
  void insertMention(MentionQuery query, {required String userId, required String text}) {
    final result = InlineEditing.insertMention(_nodes, query.start, query.end, userId: userId, text: text);
    _commit(result.nodes, TextSelection.collapsed(offset: result.caret));
  }

  // ── InlineFormatter: the toolbar formats a table cell or a step's text like the editor's own text ──

  @override
  bool get canFormat => true;

  @override
  bool get hasRange => selection.isValid && !selection.isCollapsed;

  @override
  void startMention() {
    final (start, end) = _range;
    final needsSpace = start > 0 && text[start - 1].trim().isNotEmpty;
    value = value.replaced(TextRange(start: start, end: end), needsSpace ? ' @' : '@');
  }

  /// No slash menu inside a structured block.
  @override
  String? get slashQuery => null;

  @override
  void applySlash(RBlockKind kind) {}

  @override
  TermSelection? get termSelection {
    if (!selection.isValid) return null;
    final (start, end) = _range;
    final found = InlineEditing.termAt(_nodes, start, end, maxText: TermSelection.maxText);
    return found == null ? null : TermSelection(start: found.start, end: found.end, text: found.text, termId: found.termId);
  }

  @override
  void markTerm(TermSelection selection, String termId) {
    final result = InlineEditing.markTerm(_nodes, selection.start, selection.end, termId: termId, text: selection.text);
    _commit(result.nodes, TextSelection.collapsed(offset: result.caret));
  }

  @override
  void unmarkTerm(TermSelection selection) {
    final result = InlineEditing.unmarkTerm(_nodes, selection.start, selection.end);
    _commit(result.nodes, TextSelection.collapsed(offset: result.caret));
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (plainTextOf(_nodes) != text) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    final colors = context.colors;
    final size = style?.fontSize ?? 16;
    final spans = <InlineSpan>[];
    for (final node in _nodes) {
      switch (node) {
        case RText():
          var s = const TextStyle();
          if (node.has(RMarkType.bold)) s = s.copyWith(fontWeight: FontWeight.w700);
          if (node.has(RMarkType.italic)) s = s.copyWith(fontStyle: FontStyle.italic);
          final decorations = [
            if (node.has(RMarkType.strike)) TextDecoration.lineThrough,
            if (node.href != null) TextDecoration.underline,
          ];
          if (decorations.isNotEmpty) {
            s = s.copyWith(decoration: TextDecoration.combine(decorations), decorationColor: node.href != null ? colors.link : colors.textSecondary);
          }
          if (node.has(RMarkType.highlight)) s = s.copyWith(backgroundColor: colors.highlight);
          if (node.has(RMarkType.code)) {
            s = s.merge(codeTextStyle(size: size * 0.9, color: colors.textPrimary)).copyWith(backgroundColor: colors.surfaceVariant);
          }
          if (node.href != null) s = s.copyWith(color: colors.link);
          spans.add(TextSpan(text: node.text, style: s));
        case RMention():
          spans.add(TextSpan(text: node.text, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)));
        case RTerm():
          spans.add(TextSpan(
            text: node.text,
            style: TextStyle(
              color: colors.primary,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: colors.primary,
            ),
          ));
        case RHardBreak():
          spans.add(const TextSpan(text: '\n'));
      }
    }
    return TextSpan(style: style, children: spans);
  }
}
