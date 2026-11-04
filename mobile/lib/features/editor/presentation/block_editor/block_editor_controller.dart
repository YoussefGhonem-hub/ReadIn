import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/rdoc_codec.dart';
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

/// RDoc blocks edited in place by the block editors (`block_editors.dart`): the structured-block sheets (steps,
/// code, code tabs, table, image, embed) edit one block with it. All edits are pure operations on RDoc.
class SimpleBlockEditorController extends BlockEditorController {
  SimpleBlockEditorController({RDocDocument? document, Random? random})
      : _random = random,
        _document = BlockIds.ensureUnique(document ?? const RDocDocument(version: 1, language: 'ar-EG', blocks: []), random: random);

  final Random? _random;
  RDocDocument _document;
  String? _focused;

  @override
  RDocDocument get document => _document;

  List<RBlock> get blocks => _document.blocks;

  @override
  String? get focusedBlockId => _focused;

  set focusedBlockId(String? id) => _focused = id;

  @override
  void load(RDocDocument document) {
    _document = RDocCodec.decode(document.toJson(), language: document.language);
    _focused = null;
  }

  int indexOf(String id) => _document.blocks.indexWhere((b) => b.id == id);

  RBlock? blockOf(String id) => _document.blocks.where((b) => b.id == id).firstOrNull;

  void _set(List<RBlock> blocks) {
    _document = _document.copyWith(blocks: blocks);
    notifyListeners();
  }

  @override
  String insertBlock(RBlockKind kind, {String? afterId}) {
    final id = BlockIds.generate({for (final b in _document.blocks) b.id}, random: _random);
    final anchor = afterId ?? _focused;
    final at = anchor == null ? -1 : indexOf(anchor);
    final blocks = [..._document.blocks]..insert(at < 0 ? _document.blocks.length : at + 1, BlockEditing.create(kind, id));
    _set(blocks);
    return id;
  }

  @override
  void setDirection(String blockId, String dir) {
    final block = blockOf(blockId);
    if (block == null || !BlockDirection.supportsDir(block)) return;
    replace(BlockDirection.withDir(block, dir));
  }

  @override
  void reveal(String blockId) => _focused = indexOf(blockId) < 0 ? _focused : blockId;

  /// Replaces a block (same id) after an edit inside it.
  void replace(RBlock block) {
    final i = indexOf(block.id);
    if (i < 0 || _document.blocks[i] == block) return;
    final blocks = [..._document.blocks];
    blocks[i] = block;
    _set(blocks);
  }
}
