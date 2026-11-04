import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../../shared/rdoc/rdoc_scope.dart';
import '../../domain/entities/editor_entities.dart';
import 'block_editor_controller.dart';
import 'block_editor_surface.dart';
import 'block_editors.dart';
import 'block_kinds_ui.dart';

/// Edits a structured block (steps, code, code tabs, table, image, embed) in a sheet; the edited block, or null when
/// dismissed.
Future<RBlock?> showStructuredBlockSheet(BuildContext context, RBlock block, BlockEditorContext editorContext) {
  final direction = RDocScope.of(context).baseDirection;
  return showModalBottomSheet<RBlock>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheet) => RDocScope(
      baseDirection: direction,
      child: _StructuredBlockSheet(block: block, editorContext: editorContext),
    ),
  );
}

class _StructuredBlockSheet extends StatefulWidget {
  const _StructuredBlockSheet({required this.block, required this.editorContext});

  final RBlock block;
  final BlockEditorContext editorContext;

  @override
  State<_StructuredBlockSheet> createState() => _StructuredBlockSheetState();
}

class _StructuredBlockSheetState extends State<_StructuredBlockSheet> {
  late final _controller = SimpleBlockEditorController(
    document: RDocDocument(version: 1, language: 'en', blocks: [widget.block]),
  );
  final _registry = BlockFocusRegistry();
  final _focus = EditorFocus();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final block = _controller.blocks.single;
    final editorContext = BlockEditorContext(
      fallbackDirection: widget.editorContext.fallbackDirection,
      focus: _focus,
      pickImage: widget.editorContext.pickImage,
      uploadImage: widget.editorContext.uploadImage,
      enabled: widget.editorContext.enabled,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s3, ReadInSpace.s2),
            child: Row(
              children: [
                Icon(BlockEditing.kindOf(block).icon, color: context.colors.textSecondary),
                const SizedBox(width: ReadInSpace.s2),
                Expanded(child: Text(BlockEditing.kindOf(block).label(l10n), style: context.textTheme.titleMedium)),
                FilledButton(
                  key: const ValueKey('structured-done'),
                  onPressed: () => Navigator.of(context).pop(_controller.blocks.single),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s6),
              child: BlockEditorScope(
                controller: _controller,
                editorContext: editorContext,
                registry: _registry,
                child: StructuredBlockEditor(block: block),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The callout's variant and title.
Future<({RCalloutVariant variant, String? title})?> showCalloutSheet(BuildContext context, RCallout callout) =>
    showModalBottomSheet<({RCalloutVariant variant, String? title})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => _CalloutSheet(callout: callout),
    );

class _CalloutSheet extends StatefulWidget {
  const _CalloutSheet({required this.callout});

  final RCallout callout;

  @override
  State<_CalloutSheet> createState() => _CalloutSheetState();
}

class _CalloutSheetState extends State<_CalloutSheet> {
  late RCalloutVariant _variant = widget.callout.variant;
  late final _title = TextEditingController(text: widget.callout.title ?? '');

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.blockCallout, style: context.textTheme.titleMedium),
          const SizedBox(height: ReadInSpace.s3),
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s2,
            children: [
              for (final (variant, label) in [
                (RCalloutVariant.tip, l10n.calloutTip),
                (RCalloutVariant.info, l10n.calloutInfo),
                (RCalloutVariant.warning, l10n.calloutWarning),
                (RCalloutVariant.danger, l10n.calloutDanger),
              ])
                ChoiceChip(
                  key: ValueKey('callout-${variant.name}'),
                  label: Text(label),
                  selected: _variant == variant,
                  onSelected: (_) => setState(() => _variant = variant),
                ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s3),
          TextField(
            key: const ValueKey('callout-title'),
            controller: _title,
            maxLength: DraftLimits.maxPlainText,
            decoration: InputDecoration(labelText: l10n.calloutTitleHint),
          ),
          const SizedBox(height: ReadInSpace.s2),
          FilledButton(
            key: const ValueKey('callout-save'),
            onPressed: () => Navigator.of(context).pop((variant: _variant, title: _title.text.trim().isEmpty ? null : _title.text.trim())),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// One line of plain text (a quote's cite); '' clears it, null when cancelled.
Future<String?> showTextDialog(BuildContext context, {required String label, String? initial, int maxLength = DraftLimits.maxPlainText}) =>
    showDialog<String>(
      context: context,
      builder: (dialog) => _TextDialog(label: label, initial: initial, maxLength: maxLength),
    );

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.label, this.initial, required this.maxLength});

  final String label;
  final String? initial;
  final int maxLength;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _text = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      content: TextField(
        key: const ValueKey('text-dialog-field'),
        controller: _text,
        autofocus: true,
        maxLength: widget.maxLength,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(key: const ValueKey('text-dialog-save'), onPressed: () => Navigator.of(context).pop(_text.text.trim()), child: Text(l10n.save)),
      ],
    );
  }
}
