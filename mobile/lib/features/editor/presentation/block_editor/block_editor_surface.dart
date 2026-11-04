import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/table_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../media/domain/entities/media.dart';
import 'block_editor_controller.dart';
import 'block_kinds_ui.dart';
import 'inline_formatter.dart';
import 'inline_text_controller.dart';

/// What a surface needs from the page besides the document.
class BlockEditorContext {
  const BlockEditorContext({
    required this.fallbackDirection,
    required this.focus,
    required this.pickImage,
    required this.uploadImage,
    this.problemBlockIds = const {},
    this.enabled = true,
    this.header,
  });

  /// The article's direction, for blocks without strong characters (`dir: auto`).
  final TextDirection fallbackDirection;

  /// The inline field of a structured block in focus (a table cell, a step's text).
  final EditorFocus focus;

  /// Picks one image on the device; null when cancelled.
  final Future<PickedMediaFile?> Function() pickImage;

  /// Uploads an image-block image (`purpose=image`); null when it failed.
  final Future<MediaAsset?> Function(PickedMediaFile file) uploadImage;

  /// Blocks a publish check points at (an image without alt text).
  final Set<String> problemBlockIds;
  final bool enabled;

  /// Scrolls with the content, above the first block (the title and subtitle).
  final Widget? header;
}

/// A block-editing surface: makes the [BlockEditorController] for a document and the widget that edits it. The
/// app uses the AppFlowy one; any other library implements the same two methods.
abstract interface class BlockEditorSurface {
  BlockEditorController createController(RDocDocument document);

  Widget build(BuildContext context, BlockEditorController controller, BlockEditorContext editorContext);
}

/// Which inline field of a structured block (a table cell, a step's text) is in focus: the toolbar formats it, and
/// shows the table tools for a table cell ([cell]).
class EditorFocus extends ChangeNotifier {
  InlineTextController? _active;
  String? _blockId;
  TablePosition? _cell;

  InlineTextController? get active => _active;
  String? get blockId => _blockId;

  /// The table cell in focus, if the field is one.
  TablePosition? get cell => _cell;

  void activate(String blockId, InlineTextController controller, {TablePosition? cell}) {
    if (_active == controller && _blockId == blockId && _cell == cell) return;
    _active?.removeListener(_notify);
    _active = controller..addListener(_notify);
    _blockId = blockId;
    _cell = cell;
    _notify();
  }

  void deactivate(InlineTextController controller) {
    if (_active != controller) return;
    controller.removeListener(_notify);
    _active = null;
    _blockId = null;
    _cell = null;
    _notify();
  }

  /// [deactivate] for a field being disposed: the tree is locked then, so listeners hear about it after the frame.
  void release(InlineTextController controller) {
    if (_active != controller) return;
    controller.removeListener(_notify);
    _active = null;
    _blockId = null;
    _cell = null;
    _notifyAfterFrame();
  }

  /// Announces a change (the field's text or caret too: the toolbar's marks follow it). A field updated while the
  /// tree builds (an undo, a table tool) is announced after the frame.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) return _notifyAfterFrame();
    notifyListeners();
  }

  bool _pending = false;

  void _notifyAfterFrame() {
    if (_pending) return;
    _pending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (!_disposed) notifyListeners();
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _active?.removeListener(_notify);
    super.dispose();
  }
}

/// Shared with the inline block editors: where they write ([host]), the uploads and the focus.
class BlockEditorScope extends InheritedWidget {
  const BlockEditorScope({super.key, required super.child, required this.host, required this.editorContext, required this.registry});

  final StructuredBlockHost host;
  final BlockEditorContext editorContext;
  final BlockFocusRegistry registry;

  static BlockEditorScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BlockEditorScope>()!;

  @override
  bool updateShouldNotify(BlockEditorScope old) =>
      old.host != host || old.editorContext != editorContext || old.registry != registry;
}

/// Each block's first focusable field, so a block can be focused.
class BlockFocusRegistry {
  final _nodes = <String, FocusNode>{};

  void register(String blockId, FocusNode node) => _nodes[blockId] = node;

  void unregister(String blockId, FocusNode node) {
    if (_nodes[blockId] == node) _nodes.remove(blockId);
  }

  FocusNode? operator [](String blockId) => _nodes[blockId];
}

/// "Add a block": every block kind, inserted after the focused block (or at the end).
Future<void> showInsertBlockSheet(BuildContext context, BlockEditorController controller, {String? afterId}) {
  final l10n = context.l10n;
  final anchor = afterId ?? controller.focusedBlockId;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
              child: Text(l10n.addBlock, style: sheet.textTheme.titleMedium),
            ),
            for (final kind in RBlockKind.values)
              ListTile(
                key: ValueKey('insert-${kind.name}'),
                leading: Icon(kind.icon),
                title: Text(kind.label(l10n)),
                onTap: () {
                  Navigator.of(sheet).pop();
                  controller.insertBlock(kind, afterId: anchor);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// A block's options: direction (auto / RTL / LTR), turn into, move, delete.
Future<void> showBlockOptionsSheet(BuildContext context, BlockStructureCommands commands, String blockId) {
  final l10n = context.l10n;
  final block = commands.blockOf(blockId);
  if (block == null) return Future.value();
  final index = commands.indexOf(blockId);
  final count = commands.blockCount;
  final kind = BlockEditing.kindOf(block);
  final canTurn = textBlockKinds.contains(kind);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      void close() => Navigator.of(sheet).pop();
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
                child: Text(l10n.blockOptions, style: sheet.textTheme.titleMedium),
              ),
              if (BlockDirection.supportsDir(block)) ...[
                _SheetLabel(l10n.blockDirection),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
                  child: SegmentedButton<String>(
                    key: const ValueKey('block-direction'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: BlockDirection.auto, label: Text(l10n.dirAuto)),
                      ButtonSegment(value: BlockDirection.rtl, label: const Text('RTL'), tooltip: l10n.dirRtl),
                      ButtonSegment(value: BlockDirection.ltr, label: const Text('LTR'), tooltip: l10n.dirLtr),
                    ],
                    selected: {BlockDirection.dirOf(block)},
                    onSelectionChanged: (v) {
                      commands.setDirection(block.id, v.first);
                      close();
                    },
                  ),
                ),
              ],
              if (canTurn) ...[
                _SheetLabel(l10n.turnInto),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
                  child: Wrap(
                    spacing: ReadInSpace.s2,
                    runSpacing: ReadInSpace.s2,
                    children: [
                      for (final k in textBlockKinds)
                        ChoiceChip(
                          key: ValueKey('turn-${k.name}'),
                          avatar: Icon(k.icon, size: 18),
                          label: Text(k.label(l10n)),
                          selected: k == kind,
                          onSelected: (_) {
                            commands.convert(block.id, k);
                            close();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: ReadInSpace.s2),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: Text(l10n.moveUp),
                enabled: index > 0,
                onTap: () {
                  commands.move(block.id, -1);
                  close();
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: Text(l10n.moveDown),
                enabled: index < count - 1,
                onTap: () {
                  commands.move(block.id, 1);
                  close();
                },
              ),
              ListTile(
                key: const ValueKey('block-delete'),
                leading: Icon(Icons.delete_outline_rounded, color: sheet.colors.error),
                title: Text(l10n.deleteBlock, style: TextStyle(color: sheet.colors.error)),
                onTap: () {
                  commands.remove(block.id);
                  close();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s5, ReadInSpace.s2),
        child: Text(text, style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
      );
}

/// The table tools (as the web editor's), on the cell in focus.
enum TableTool { addRow, addColumn, deleteRow, deleteColumn, deleteTable }

/// Applies a table tool to the table cell in [focus], within the schema's limits ([TableEditing]): one edit through
/// [host], so it is undoable.
void applyTableTool(BlockStructureCommands commands, StructuredBlockHost host, EditorFocus focus, TableTool tool) {
  final blockId = focus.blockId;
  final cell = focus.cell;
  if (blockId == null || cell == null) return;
  final table = commands.blockOf(blockId);
  if (table is! RTable) return;
  final op = switch (tool) {
    TableTool.addRow => TableOp.addRow,
    TableTool.addColumn => TableOp.addColumn,
    TableTool.deleteRow => TableOp.deleteRow,
    TableTool.deleteColumn => TableOp.deleteColumn,
    TableTool.deleteTable => null,
  };
  if (op == null) return host.remove(blockId);
  final next = TableEditing.apply(table, op, cell);
  if (!identical(next, table)) host.replace(next);
}
