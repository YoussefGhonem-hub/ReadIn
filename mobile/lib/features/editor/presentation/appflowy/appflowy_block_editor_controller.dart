import 'dart:async';
import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/inline_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../comments/domain/entities/comment_text.dart';
import '../block_editor/block_editor_controller.dart';
import '../block_editor/block_editor_surface.dart';
import '../block_editor/inline_formatter.dart';
import 'rdoc_appflowy_codec.dart';

/// The AppFlowy surface's controller (F05): an AppFlowy [EditorState] seen as RDoc. Every transaction is converted
/// back with [RDocAppFlowyCodec] and announced to listeners; the toolbar formats through [InlineFormatter], undoes
/// through [UndoRedo] and the block options sheet uses [BlockStructureCommands]. The structured blocks edited in
/// place write through [StructuredBlockHost], one undoable transaction per edit.
class AppFlowyBlockEditorController extends BlockEditorController
    implements InlineFormatter, BlockStructureCommands, StructuredBlockHost, UndoRedo {
  AppFlowyBlockEditorController({required RDocDocument document}) : _language = document.language {
    appflowyEditorSliceAttributes = rdocSliceAttributes;
    _attach(_stateFor(document));
  }

  /// The attributes typed text takes from the text before it: AppFlowy's, except mentions and glossary terms, which
  /// are atomic and never grow.
  static Attributes? rdocSliceAttributes(Delta delta, int index) {
    final attributes = defaultAppFlowyEditorSliceAttributes?.call(delta, index);
    if (attributes == null) return null;
    return {
      for (final e in attributes.entries)
        if (e.key != RDocNodeKeys.mention && e.key != RDocNodeKeys.term) e.key: e.value,
    };
  }

  late EditorState _state;
  StreamSubscription<EditorTransactionValue>? _transactions;
  late RDocDocument _document;
  String _language;
  bool _disposed = false;

  /// Bumped by [load]: the surface builds a new editor for the new state.
  int generation = 0;

  /// The first field of each structured block, so inserting or revealing one puts the caret in it.
  final focusRegistry = BlockFocusRegistry();

  EditorState get editorState => _state;

  static EditorState _stateFor(RDocDocument document) {
    final blocks = document.blocks.isEmpty
        ? [RParagraph(BlockIds.generate(const {}), dir: BlockDirection.auto, content: const [])]
        : document.blocks;
    return EditorState(document: RDocAppFlowyCodec.toDocument(document.copyWith(blocks: blocks)));
  }

  void _attach(EditorState state) {
    _transactions?.cancel();
    _state = state;
    _document = RDocAppFlowyCodec.fromDocument(state.document, language: _language);
    _transactions = state.transactionStream.listen((value) {
      if (value.$1 == TransactionTime.after) _onTransaction();
    });
    state.selectionNotifier.addListener(_onSelection);
  }

  void _detach() {
    _transactions?.cancel();
    _state.selectionNotifier.removeListener(_onSelection);
  }

  void _onTransaction() {
    if (_disposed) return;
    _document = RDocAppFlowyCodec.fromDocument(_state.document, language: _language);
    notifyListeners();
  }

  void _onSelection() {
    if (_disposed) return;
    if (_state.selection case final selection?) _lastSelection = selection;
    notifyListeners();
  }

  /// The last selection the editor had. A dialog opened from the toolbar (the link's) takes the focus, and AppFlowy
  /// drops its selection with it: what the dialog applies goes to this one.
  Selection? _lastSelection;

  // ── BlockEditorController ─────────────────────────────────

  @override
  RDocDocument get document => _document;

  @override
  void load(RDocDocument document) {
    _detach();
    final old = _state;
    _language = document.language;
    _lastSelection = null;
    _attach(_stateFor(document));
    generation++;
    // The old editor widget still reads it until the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// The top-level node the selection is in.
  Node? get _selectedNode {
    final selection = _state.selection;
    if (selection == null) return null;
    final path = selection.start.path;
    if (path.isEmpty) return null;
    return _state.getNodeAtPath([path.first]);
  }

  /// The RDoc id of a node: a list item belongs to its list.
  static String _blockIdOf(Node node) => node.attributes[RDocNodeKeys.listId] as String? ?? node.id;

  @override
  String? get focusedBlockId {
    final node = _selectedNode;
    return node == null ? null : _blockIdOf(node);
  }

  List<Node> get _topNodes => _state.document.root.children.toList();

  /// The nodes of block [id] (several for a list).
  List<Node> _nodesOf(String id) {
    final nodes = _topNodes;
    final index = nodes.indexWhere((n) => n.id == id || n.attributes[RDocNodeKeys.listId] == id);
    if (index < 0) return const [];
    final first = nodes[index];
    if (first.type != BulletedListBlockKeys.type && first.type != NumberedListBlockKeys.type) return [first];
    final group = [first];
    for (var i = index + 1; i < nodes.length && nodes[i].type == first.type; i++) {
      final list = nodes[i].attributes[RDocNodeKeys.listId] as String?;
      if (list != null && list != _blockIdOf(first)) break;
      group.add(nodes[i]);
    }
    return group;
  }

  @override
  String insertBlock(RBlockKind kind, {String? afterId, List<RInline> content = const []}) {
    final taken = {for (final b in _document.blocks) b.id};
    final id = BlockIds.generate(taken);
    final block = BlockEditing.create(kind, id, content: content);
    final nodes = RDocAppFlowyCodec.nodesFor(block);
    if (kind == RBlockKind.divider) {
      nodes.add(RDocAppFlowyCodec.nodesFor(RParagraph(BlockIds.generate({...taken, id}), dir: BlockDirection.auto, content: const [])).single);
    }
    final anchor = _nodesOf(afterId ?? focusedBlockId ?? '');
    final path = anchor.isEmpty ? [_topNodes.length] : anchor.last.path.next;
    final transaction = _state.transaction..insertNodes(path, nodes, deepCopy: false);
    final focus = nodes.lastWhere((n) => n.delta != null, orElse: () => nodes.first);
    final focusPath = [path.first + nodes.indexOf(focus)];
    transaction.afterSelection = focus.delta != null
        ? Selection.collapsed(Position(path: focusPath))
        : Selection.single(path: focusPath, startOffset: 0, endOffset: 1);
    unawaited(_state.apply(transaction));
    if (focus.type == RDocNodeKeys.block) _focusField(id);
    return id;
  }

  @override
  void setDirection(String blockId, String dir) {
    final nodes = _nodesOf(blockId);
    if (nodes.isEmpty) return;
    final value = BlockDirection.values.contains(dir) ? dir : BlockDirection.auto;
    final transaction = _state.transaction;
    for (final node in nodes) {
      if (node.type == RDocNodeKeys.block) {
        final block = RDocAppFlowyCodec.blockFor(node);
        if (block == null || !BlockDirection.supportsDir(block)) return;
        transaction.updateNode(node, {RDocNodeKeys.blockJson: BlockDirection.withDir(block, value).toJson()});
      } else if (node.delta != null) {
        transaction.updateNode(node, {blockComponentTextDirection: value});
      }
    }
    unawaited(_state.apply(transaction));
  }

  @override
  void reveal(String blockId) {
    final nodes = _nodesOf(blockId);
    if (nodes.isEmpty) return;
    final node = nodes.first;
    unawaited(_state.updateSelectionWithReason(
      node.delta != null ? Selection.collapsed(Position(path: node.path)) : Selection.single(path: node.path, startOffset: 0, endOffset: 1),
      reason: SelectionUpdateReason.uiEvent,
    ));
    if (node.type == RDocNodeKeys.block) _focusField(blockId);
  }

  /// Puts the caret in a structured block's first field once it is built (a code block's code, the first cell).
  void _focusField(String blockId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) focusRegistry[blockId]?.requestFocus();
    });
  }

  // ── StructuredBlockHost ───────────────────────────────────

  /// Replaces a structured block (steps, code, tabs, table, image, embed) after an edit inside it.
  @override
  void replace(RBlock block) {
    final nodes = _nodesOf(block.id);
    if (nodes.length != 1 || nodes.single.type != RDocNodeKeys.block) return;
    final json = block.toJson();
    if (jsonEncode(nodes.single.attributes[RDocNodeKeys.blockJson]) == jsonEncode(json)) return;
    unawaited(_state.apply(_state.transaction..updateNode(nodes.single, {RDocNodeKeys.blockJson: json})));
  }

  /// Updates attributes of a text block's node (callout variant and title, quote cite).
  void updateAttributes(String blockId, Map<String, Object?> attributes) {
    final nodes = _nodesOf(blockId);
    if (nodes.isEmpty) return;
    final node = nodes.first;
    if (attributes.entries.every((e) => node.attributes[e.key] == e.value)) return;
    final transaction = _state.transaction..updateNode(node, attributes);
    transaction.afterSelection = _state.selection;
    unawaited(_state.apply(transaction));
  }

  // ── UndoRedo ──────────────────────────────────────────────

  @override
  bool get canUndo => _state.undoManager.undoStack.isNonEmpty;

  @override
  bool get canRedo => _state.undoManager.redoStack.isNonEmpty;

  @override
  void undo() {
    _state.undoManager.undo();
    // The stacks change after the transaction is announced.
    notifyListeners();
  }

  @override
  void redo() {
    _state.undoManager.redo();
    notifyListeners();
  }

  // ── BlockStructureCommands ────────────────────────────────

  @override
  RBlock? blockOf(String id) => _document.blocks.where((b) => b.id == id).firstOrNull;

  @override
  int indexOf(String id) => _document.blocks.indexWhere((b) => b.id == id);

  @override
  int get blockCount => _document.blocks.length;

  @override
  void convert(String id, RBlockKind kind) {
    final block = blockOf(id);
    final nodes = _nodesOf(id);
    if (block == null || nodes.isEmpty || BlockEditing.kindOf(block) == kind) return;
    final content = BlockEditing.textOf(block) ?? [for (final n in nodes) ...RDocAppFlowyCodec.inlinesFrom(n.delta)];
    final next = BlockEditing.withId(BlockEditing.create(kind, id, content: content, dir: BlockDirection.dirOf(block)), id);
    _replace(nodes, RDocAppFlowyCodec.nodesFor(next));
  }

  @override
  void move(String id, int delta) {
    final nodes = _nodesOf(id);
    final blocks = _document.blocks;
    final index = indexOf(id);
    final target = index + delta;
    if (nodes.isEmpty || index < 0 || target < 0 || target >= blocks.length) return;
    final other = _nodesOf(blocks[target].id);
    final copies = [for (final n in nodes) n.copyWith(id: n.id)];
    final transaction = _state.transaction;
    // Remove the block, then insert it before (up) or after (down) its neighbour.
    final insertAt = delta < 0 ? other.first.path : other.last.path.next;
    transaction.insertNodes(insertAt, copies, deepCopy: false);
    transaction.deleteNodes(nodes);
    unawaited(_state.apply(transaction));
  }

  @override
  void remove(String id) {
    final nodes = _nodesOf(id);
    if (nodes.isEmpty) return;
    final transaction = _state.transaction..deleteNodes(nodes);
    if (_topNodes.length == nodes.length) {
      transaction.insertNode([0], RDocAppFlowyCodec.nodesFor(RParagraph(BlockIds.generate(const {}), dir: 'auto', content: const [])).single);
    }
    unawaited(_state.apply(transaction));
  }

  void _replace(List<Node> old, List<Node> next) {
    final path = old.first.path;
    final transaction = _state.transaction
      ..insertNodes(path, next, deepCopy: false)
      ..deleteNodes(old);
    final focus = next.firstWhere((n) => n.delta != null, orElse: () => next.first);
    transaction.afterSelection = focus.delta != null
        ? Selection.collapsed(Position(path: [path.first + next.indexOf(focus)], offset: focus.delta!.length))
        : Selection.single(path: [path.first + next.indexOf(focus)], startOffset: 0, endOffset: 1);
    unawaited(_state.apply(transaction));
  }

  // ── InlineFormatter ───────────────────────────────────────

  static String _key(RMarkType type) => switch (type) {
        RMarkType.bold => AppFlowyRichTextKeys.bold,
        RMarkType.italic => AppFlowyRichTextKeys.italic,
        RMarkType.code => AppFlowyRichTextKeys.code,
        RMarkType.strike => AppFlowyRichTextKeys.strikethrough,
        RMarkType.highlight => RDocNodeKeys.highlight,
        RMarkType.link => AppFlowyRichTextKeys.href,
      };

  Node? get _textNode {
    final selection = _state.selection;
    if (selection == null) return null;
    final node = _state.getNodeAtPath(selection.start.path);
    return node?.delta == null ? null : node;
  }

  @override
  bool get canFormat => _textNode != null;

  @override
  bool get hasRange => !(_state.selection?.isCollapsed ?? true);

  @override
  bool hasMark(RMarkType type) {
    final selection = _state.selection;
    final key = _key(type);
    if (selection == null) return false;
    if (selection.isCollapsed) {
      final toggled = _state.toggledStyle[key];
      if (toggled is bool) return toggled;
      final node = _textNode;
      final offset = selection.start.offset;
      if (node == null || offset == 0) return false;
      return node.delta!.slice(offset - 1, offset).everyAttributes((a) => a[key] == true || (key == AppFlowyRichTextKeys.href && a[key] != null));
    }
    final nodes = _state.getNodesInSelection(selection);
    return nodes.allSatisfyInSelection(selection, (delta) => delta.everyAttributes((a) => a[key] == true));
  }

  @override
  void toggleMark(RMarkType type) {
    if (type == RMarkType.link) return;
    unawaited(_state.toggleAttribute(_key(type)));
  }

  @override
  String? get link {
    final selection = _state.selection;
    final node = _textNode;
    if (selection == null || node == null) return null;
    final start = selection.normalized.start.offset;
    final end = selection.isCollapsed ? start + 1 : selection.normalized.end.offset;
    if (end > node.delta!.length) return null;
    for (final op in node.delta!.slice(start, end).whereType<TextInsert>()) {
      final href = op.attributes?[AppFlowyRichTextKeys.href];
      if (href is String) return href;
    }
    return null;
  }

  @override
  void setLink(String? href) {
    final selection = _state.selection ?? _lastSelection;
    if (selection == null || selection.isCollapsed) return;
    if (href != null && !InlineEditing.isHttpUrl(href)) return;
    unawaited(_state.formatDelta(selection, {AppFlowyRichTextKeys.href: href?.trim()}));
  }

  @override
  void insertHardBreak() => unawaited(_state.insertTextAtCurrentSelection('\n'));

  @override
  void startMention() {
    final selection = _state.selection;
    final node = _textNode;
    if (selection == null || node == null) return;
    final offset = selection.normalized.start.offset;
    final text = node.delta!.toPlainText();
    final needsSpace = offset > 0 && text[offset - 1].trim().isNotEmpty;
    unawaited(_state.insertTextAtCurrentSelection(needsSpace ? ' @' : '@'));
  }

  @override
  MentionQuery? get activeMention {
    final selection = _state.selection;
    final node = _textNode;
    if (selection == null || node == null || !selection.isCollapsed) return null;
    // A mention or term is one placeholder character, never part of an `@word`.
    return CommentText.activeMention(node.delta!.toPlainText(), selection.start.offset);
  }

  /// Replaces the typed `@word` with the mention: one atomic placeholder character, then a space.
  @override
  void insertMention(MentionQuery query, {required String userId, required String text}) {
    final node = _textNode;
    if (node == null) return;
    final transaction = _state.transaction
      ..deleteText(node, query.start, query.end - query.start)
      // One delta: indexes of later inserts in the same transaction would be checked against the old text.
      ..insertTextDelta(
        node,
        query.start,
        Delta()
          ..insert(RDocNodeKeys.placeholder, attributes: RDocAppFlowyCodec.mentionAttributes(userId: userId, text: text))
          ..insert(' '),
      );
    transaction.afterSelection = Selection.collapsed(Position(path: node.path, offset: query.start + 2));
    unawaited(_state.apply(transaction));
  }

  @override
  String? get slashQuery {
    final node = _textNode;
    if (node == null || node.type != ParagraphBlockKeys.type || !(_state.selection?.isCollapsed ?? false)) return null;
    return MarkdownShortcuts.slashQuery(node.delta!.toPlainText());
  }

  @override
  void applySlash(RBlockKind kind) {
    final node = _textNode;
    if (node == null || node.type != ParagraphBlockKeys.type) return;
    final dir = node.attributes[blockComponentTextDirection] as String? ?? BlockDirection.auto;
    final block = BlockEditing.create(kind, node.id, dir: dir);
    final nodes = RDocAppFlowyCodec.nodesFor(block);
    if (kind == RBlockKind.divider) {
      nodes.add(RDocAppFlowyCodec.nodesFor(RParagraph(BlockIds.generate({for (final b in _document.blocks) b.id}), dir: 'auto', content: const [])).single);
    }
    final path = node.path;
    final transaction = _state.transaction
      ..deleteNode(node)
      ..insertNodes(path, nodes, deepCopy: false);
    final focus = nodes.lastWhere((n) => n.delta != null, orElse: () => nodes.first);
    final focusPath = [path.first + nodes.indexOf(focus)];
    transaction.afterSelection = focus.delta != null
        ? Selection.collapsed(Position(path: focusPath))
        : Selection.single(path: focusPath, startOffset: 0, endOffset: 1);
    unawaited(_state.apply(transaction));
  }

  // ── Glossary terms (F21): a term is one placeholder character carrying its id and words ──

  @override
  TermSelection? get termSelection {
    final selection = _state.selection;
    final node = _textNode;
    if (selection == null || node == null || !selection.isSingle) return null;
    final start = selection.normalized.start.offset;
    final end = selection.normalized.end.offset;
    // One run per character of a mention or term (two equal neighbours share one insert), one per plain insert.
    final runs = <({int start, int end, RDocAtom? atom})>[];
    var pos = 0;
    for (final op in node.delta!.whereType<TextInsert>()) {
      final atom = RDocAppFlowyCodec.atomOf(op.attributes);
      if (atom == null) {
        runs.add((start: pos, end: pos + op.text.length, atom: null));
      } else {
        for (var i = 0; i < op.text.length; i++) {
          runs.add((start: pos + i, end: pos + i + 1, atom: atom));
        }
      }
      pos += op.text.length;
    }
    bool isTerm(({int start, int end, RDocAtom? atom}) r) => r.atom != null && !r.atom!.mention;
    TermSelection term(({int start, int end, RDocAtom? atom}) r) =>
        TermSelection(start: r.start, end: r.end, text: r.atom!.text, termId: r.atom!.id, path: node.path);

    if (start == end) {
      // The caret just after a term, else just before one.
      for (final r in runs) {
        if (isTerm(r) && r.end == start) return term(r);
      }
      for (final r in runs) {
        if (isTerm(r) && r.start == start) return term(r);
      }
      return null;
    }
    for (final r in runs) {
      if (isTerm(r) && r.start <= start && end <= r.end) return term(r);
    }
    for (final r in runs) {
      if (r.atom != null && r.start < end && r.end > start) return null;
    }
    final raw = node.delta!.toPlainText().substring(start.clamp(0, pos), end.clamp(0, pos));
    final text = raw.trim();
    if (text.isEmpty || text.contains('\n') || text.length > TermSelection.maxText) return null;
    final from = start + (raw.length - raw.trimLeft().length);
    return TermSelection(start: from, end: from + text.length, text: text, path: node.path);
  }

  @override
  void markTerm(TermSelection selection, String termId) {
    _replaceRange(
      selection,
      Delta()..insert(RDocNodeKeys.placeholder, attributes: RDocAppFlowyCodec.termAttributes(termId: termId, text: selection.text)),
    );
  }

  @override
  void unmarkTerm(TermSelection selection) {
    if (selection.termId == null) return;
    _replaceRange(selection, Delta()..insert(selection.text));
  }

  /// Replaces [selection]'s range of its text with [delta] (exactly: no attributes taken from neighbours), then puts
  /// the caret after it.
  void _replaceRange(TermSelection selection, Delta delta) {
    final path = selection.path;
    final node = path == null ? _textNode : _state.getNodeAtPath(path);
    if (node == null || node.delta == null || selection.end > node.delta!.length) return;
    final transaction = _state.transaction
      ..deleteText(node, selection.start, selection.end - selection.start)
      ..insertTextDelta(node, selection.start, delta);
    transaction.afterSelection = Selection.collapsed(Position(path: node.path, offset: selection.start + delta.length));
    unawaited(_state.apply(transaction));
  }

  @override
  void dispose() {
    _disposed = true;
    _detach();
    _state.dispose();
    super.dispose();
  }
}
