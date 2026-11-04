import '../rdoc_document.dart';

/// The result of an inline edit: the new nodes and where the caret goes (an offset in their plain text).
typedef InlineEditResult = ({List<RInline> nodes, int caret});

/// Pure operations on RDoc inline content (SPEC §13.3), for any editing surface.
///
/// The content is addressed by offsets in its plain text ([plainTextOf]): a text node contributes its text, a term
/// or mention its display text and a hard break one `\n`. Terms, mentions and hard breaks are **atomic**: an edit
/// that touches part of one removes it whole, and text typed inside one goes after it. That keeps glossary terms
/// (F21, no insertion UI yet) and mentions intact through any edit that doesn't delete them.
abstract final class InlineEditing {
  static bool _isAtomic(RInline node) => node is! RText;

  static int _length(RInline node) => node.plainText.length;

  /// Merges neighbouring text nodes with the same marks and drops empty ones.
  static List<RInline> normalize(List<RInline> nodes) {
    final out = <RInline>[];
    for (final node in nodes) {
      if (node is RText) {
        if (node.text.isEmpty) continue;
        final last = out.isEmpty ? null : out.last;
        if (last is RText && _sameMarks(last.marks, node.marks)) {
          out[out.length - 1] = RText(last.text + node.text, marks: last.marks);
          continue;
        }
      }
      out.add(node);
    }
    return out;
  }

  static bool _sameMarks(List<RMark> a, List<RMark> b) {
    if (a.length != b.length) return false;
    final rest = [...b];
    for (final m in a) {
      if (!rest.remove(m)) return false;
    }
    return true;
  }

  /// Splits [nodes] at the plain-text [offset] (text nodes are cut; an atomic node stays on the side it starts on).
  static (List<RInline>, List<RInline>) splitAt(List<RInline> nodes, int offset) {
    final before = <RInline>[];
    final after = <RInline>[];
    var pos = 0;
    for (final node in nodes) {
      final len = _length(node);
      if (pos + len <= offset) {
        before.add(node);
      } else if (pos >= offset) {
        after.add(node);
      } else if (node is RText) {
        before.add(RText(node.text.substring(0, offset - pos), marks: node.marks));
        after.add(RText(node.text.substring(offset - pos), marks: node.marks));
      } else {
        before.add(node);
      }
      pos += len;
    }
    return (normalize(before), normalize(after));
  }

  /// The marks a character typed at [offset] gets: those of the text just before it (or just after it at the start).
  /// A link is not continued past its end.
  static List<RMark> marksAt(List<RInline> nodes, int offset) {
    var pos = 0;
    RInline? before;
    RInline? after;
    for (final node in nodes) {
      final len = _length(node);
      if (pos < offset && offset <= pos + len) before = node;
      if (after == null && pos >= offset) after = node;
      if (pos < offset && offset < pos + len) after = node;
      pos += len;
    }
    if (before is RText) {
      final inside = after == before;
      return [for (final m in before.marks) if (m.type != RMarkType.link || inside) m];
    }
    if (before == null && after is RText) return [for (final m in after.marks) if (m.type != RMarkType.link) m];
    return const [];
  }

  /// Replaces the plain-text range [start, end) with [insert]. Atomic nodes the range touches are removed whole; an
  /// insertion inside one goes after it. [marks] defaults to [marksAt] the insertion point.
  static InlineEditResult replaceRange(List<RInline> nodes, int start, int end, String insert, {List<RMark>? marks}) {
    final total = plainTextOf(nodes).length;
    var from = start.clamp(0, total);
    var to = end.clamp(from, total);

    // Widen the deleted range to whole atomic nodes; move a pure insertion out of one.
    var pos = 0;
    for (final node in nodes) {
      final len = _length(node);
      final nodeStart = pos;
      final nodeEnd = pos + len;
      pos = nodeEnd;
      if (!_isAtomic(node)) continue;
      if (from == to) {
        if (from > nodeStart && from < nodeEnd) from = to = nodeEnd;
      } else if (from < nodeEnd && to > nodeStart) {
        if (nodeStart < from) from = nodeStart;
        if (nodeEnd > to) to = nodeEnd;
      }
    }

    final insertMarks = marks ?? marksAt(nodes, from);
    final out = <RInline>[];
    var inserted = insert.isEmpty;
    void addInsert() {
      if (!inserted) out.add(RText(insert, marks: insertMarks));
      inserted = true;
    }

    pos = 0;
    for (final node in nodes) {
      final len = _length(node);
      final nodeStart = pos;
      final nodeEnd = pos + len;
      pos = nodeEnd;
      if (nodeEnd <= from) {
        out.add(node);
        continue;
      }
      if (nodeStart >= to) {
        if (nodeStart >= from) addInsert();
        out.add(node);
        continue;
      }
      // The node overlaps [from, to).
      if (node is RText) {
        final keepBefore = from > nodeStart ? node.text.substring(0, from - nodeStart) : '';
        final keepAfter = to < nodeEnd ? node.text.substring(to - nodeStart) : '';
        if (keepBefore.isNotEmpty) out.add(RText(keepBefore, marks: node.marks));
        addInsert();
        if (keepAfter.isNotEmpty) out.add(RText(keepAfter, marks: node.marks));
      } else {
        addInsert(); // atomic nodes in the range are dropped
      }
    }
    addInsert();
    return (nodes: normalize(out), caret: from + insert.length);
  }

  /// The edit that turns [oldText] into [newText] (both plain texts of the same content), as a replaced range.
  /// [caret] (the new caret, when known) disambiguates repeated characters: typed text ends at the caret.
  static ({int start, int end, String insert}) diff(String oldText, String newText, {int? caret}) {
    final maxSuffix = caret == null ? newText.length : (newText.length - caret).clamp(0, newText.length);
    var suffix = 0;
    while (suffix < maxSuffix &&
        suffix < oldText.length &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) == newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    final maxPrefix = (oldText.length - suffix) < (newText.length - suffix) ? oldText.length - suffix : newText.length - suffix;
    var prefix = 0;
    while (prefix < maxPrefix && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    return (start: prefix, end: oldText.length - suffix, insert: newText.substring(prefix, newText.length - suffix));
  }

  /// Applies a plain-text change typed in a text field to [nodes].
  static InlineEditResult applyTextChange(List<RInline> nodes, String newText, {int? caret, List<RMark>? marks}) {
    final change = diff(plainTextOf(nodes), newText, caret: caret);
    return replaceRange(nodes, change.start, change.end, change.insert, marks: marks);
  }

  /// True when every text character in [start, end) carries [type].
  static bool hasMark(List<RInline> nodes, int start, int end, RMarkType type) {
    var pos = 0;
    var sawText = false;
    for (final node in nodes) {
      final len = _length(node);
      final nodeStart = pos;
      pos += len;
      if (node is! RText || nodeStart + len <= start || nodeStart >= end) continue;
      sawText = true;
      if (!node.has(type)) return false;
    }
    return sawText;
  }

  static List<RInline> _mapRange(List<RInline> nodes, int start, int end, RText Function(RText) change) {
    if (start >= end) return nodes;
    final (before, rest) = splitAt(nodes, start);
    final (middle, after) = splitAt(rest, end - start);
    return normalize([...before, for (final n in middle) n is RText ? change(n) : n, ...after]);
  }

  /// Adds [type] to the text in [start, end), or removes it when all of it already has it.
  static List<RInline> toggleMark(List<RInline> nodes, int start, int end, RMarkType type) {
    assert(type != RMarkType.link, 'use setLink');
    final remove = hasMark(nodes, start, end, type);
    return _mapRange(nodes, start, end, (t) {
      final marks = [for (final m in t.marks) if (m.type != type) m];
      return RText(t.text, marks: remove ? marks : [...marks, RMark(type)]);
    });
  }

  /// Links the text in [start, end) to [href] (http/https only), or unlinks it when [href] is null.
  static List<RInline> setLink(List<RInline> nodes, int start, int end, String? href) {
    if (href != null && !isHttpUrl(href)) return nodes;
    return _mapRange(nodes, start, end, (t) {
      final marks = [for (final m in t.marks) if (m.type != RMarkType.link) m];
      return RText(t.text, marks: href == null ? marks : [...marks, RMark(RMarkType.link, href: href.trim())]);
    });
  }

  /// The link of the text in [start, end) (or at [start] for a caret), if any.
  static String? linkAt(List<RInline> nodes, int start, int end) {
    var pos = 0;
    for (final node in nodes) {
      final len = _length(node);
      final nodeStart = pos;
      pos += len;
      if (node is! RText) continue;
      final touches = start == end ? (start > nodeStart && start <= nodeStart + len) : (nodeStart < end && nodeStart + len > start);
      if (touches && node.href != null) return node.href;
    }
    return null;
  }

  /// Replaces [start, end) (the typed `@query`) with a mention node and a space after it.
  static InlineEditResult insertMention(List<RInline> nodes, int start, int end, {required String userId, required String text}) {
    final (before, rest) = splitAt(nodes, start);
    final (_, after) = splitAt(rest, end - start);
    final needsSpace = !(after.firstOrNull is RText && (after.first as RText).text.startsWith(' '));
    final mention = RMention(userId: userId, text: text);
    final result = normalize([...before, mention, if (needsSpace) const RText(' '), ...after]);
    return (nodes: result, caret: start + text.length + 1);
  }

  /// Inserts a hard break (a line break inside the block) at [offset], replacing the selection [offset, end).
  static InlineEditResult insertHardBreak(List<RInline> nodes, int offset, [int? end]) {
    final cleared = end != null && end > offset ? replaceRange(nodes, offset, end, '').nodes : nodes;
    final (before, after) = splitAt(cleared, offset);
    return (nodes: normalize([...before, const RHardBreak(), ...after]), caret: offset + 1);
  }

  /// True for `http(s)://host…` within the schema's 2048 characters and without spaces or quotes.
  static bool isHttpUrl(String value) {
    final url = value.trim();
    if (url.length > 2048 || !RegExp(r'''^https?://[^\s<>"']+$''').hasMatch(url)) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.host.isNotEmpty;
  }
}
