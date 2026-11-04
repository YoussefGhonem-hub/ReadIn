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
