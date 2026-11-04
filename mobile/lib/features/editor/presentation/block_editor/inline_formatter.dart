import 'package:flutter/foundation.dart';

import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../comments/domain/entities/comment_text.dart';

/// What the editor toolbar formats: the text the writer is in. Implemented by the editing surface's controller.
abstract interface class InlineFormatter implements Listenable {
  /// The caret or a selection is in text that takes marks.
  bool get canFormat;

  /// A range (not just a caret) is selected.
  bool get hasRange;

  bool hasMark(RMarkType type);

  /// Bold, italic, inline code, highlight or strike on the selection (with a caret: for what's typed next).
  void toggleMark(RMarkType type);

  /// The link of the selection, if any.
  String? get link;

  /// Links the selection to [href] (http/https), or unlinks it when null.
  void setLink(String? href);

  /// A line break inside the block (RDoc `hardBreak`).
  void insertHardBreak();

  /// Types `@` to start a mention.
  void startMention();

  /// The `@word` being typed, for the suggestions.
  MentionQuery? get activeMention;

  void insertMention(MentionQuery query, {required String userId, required String text});

  /// `/query` typed alone in a paragraph: the slash menu's query.
  String? get slashQuery;

  /// Turns that paragraph into a [kind] block.
  void applySlash(RBlockKind kind);

  /// What the glossary button works on (F21): words selected in this text, or a term the selection covers or the
  /// caret touches. Null otherwise.
  TermSelection? get termSelection;

  /// Turns [selection] into the glossary term [termId] (an existing term gets the new id), keeping its words.
  void markTerm(TermSelection selection, String termId);

  /// Turns the term [selection] back into plain words.
  void unmarkTerm(TermSelection selection);
}

/// The words the glossary button marks (F21), or the term it opens again ([termId] set). [start] and [end] are
/// offsets in the formatter's own text, without the spaces around the words. [path] is where that text is for a
/// formatter over several texts (AppFlowy's node path): the picker takes the focus, and the editor's selection with
/// it, so marking can't rely on the selection. It is not part of equality.
class TermSelection {
  const TermSelection({required this.start, required this.end, required this.text, this.termId, this.path});

  final int start;
  final int end;
  final String text;
  final String? termId;
  final List<int>? path;

  /// The longest text a term node keeps (RDoc schema).
  static const maxText = 200;

  @override
  bool operator ==(Object other) =>
      other is TermSelection && other.start == start && other.end == end && other.text == text && other.termId == termId;

  @override
  int get hashCode => Object.hash(start, end, text, termId);

  @override
  String toString() => 'TermSelection($start, $end, $text, $termId)';
}

/// Block-level commands of the "Block options" sheet.
abstract interface class BlockStructureCommands {
  /// The block (by RDoc id) as it is now.
  RBlock? blockOf(String id);

  int indexOf(String id);

  int get blockCount;

  /// Turns a text block into another text kind, keeping its text.
  void convert(String id, RBlockKind kind);

  void move(String id, int delta);

  void remove(String id);

  void setDirection(String blockId, String dir);
}
