import 'package:flutter/foundation.dart';

import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';

/// The block-editing surface behind the editor page (F05). The page knows only this interface: the document goes
/// in as RDoc ([load]), changes come out as RDoc ([document], notified to listeners), and the page sends the two
/// commands its toolbar has, [insertBlock] and [setDirection]. The AppFlowy surface implements it
/// (`AppFlowyBlockEditorController`); the conversions that don't depend on the library (block ids, direction,
/// mentions and terms) are in `shared/rdoc/editing`.
abstract class BlockEditorController extends ChangeNotifier {
  /// The current content, in RDoc.
  RDocDocument get document;

  /// Replaces the content (opening, reloading the saved copy, restoring a revision). Doesn't notify.
  void load(RDocDocument document);

  /// Inserts a new block of [kind] after [afterId] (or after the focused block, or at the end) and focuses it.
  /// Returns its id.
  String insertBlock(RBlockKind kind, {String? afterId});

  /// Sets a block's direction override: `auto` | `rtl` | `ltr` (code is always LTR and ignores it).
  void setDirection(String blockId, String dir);

  /// The block the writer is in, if any.
  String? get focusedBlockId;

  /// Scrolls to [blockId] and puts the caret in it (a check's "jump to the block").
  void reveal(String blockId);
}

/// Where the inline block editors (steps, code, code tabs, table, image, embed; block_editors.dart) write: the
/// surface's controller.
abstract interface class StructuredBlockHost {
  /// Replaces a block (same id) after an edit inside it.
  void replace(RBlock block);

  /// Removes block [id] (the last code tab removed, the table deleted).
  void remove(String id);
}

/// Undo and redo of the editing surface (the toolbar's buttons).
abstract interface class UndoRedo implements Listenable {
  bool get canUndo;
  bool get canRedo;
  void undo();
  void redo();
}
