import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../domain/usecases/moderation_usecases.dart';
import 'moderation_labels.dart';

/// Asks before a moderator's action. [destructive] paints the confirm button in the error color. True to go ahead.
Future<bool> confirmModeration(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: dialogContext.colors.error, foregroundColor: dialogContext.colors.onError)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Hide (note optional) or warn (note required, the user sees it). The note, '' when left empty; null when cancelled.
Future<String?> showModerationNoteDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required bool noteRequired,
  bool destructive = false,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        noteRequired: noteRequired,
        destructive: destructive,
      ),
    );

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.noteRequired,
    required this.destructive,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool noteRequired;
  final bool destructive;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _valid => !widget.noteRequired || _note.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s4),
          ModerationNoteField(controller: _note, required: widget.noteRequired),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError)
              : null,
          onPressed: _valid ? () => Navigator.of(context).pop(_note.text.trim()) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// The moderator's note (≤ 500, mixed text in its own direction). When [required], the affected user sees it.
class ModerationNoteField extends StatelessWidget {
  const ModerationNoteField({super.key, required this.controller, required this.required});

  final TextEditingController controller;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BidiTextField(
      controller: controller,
      minLines: 2,
      maxLines: 5,
      maxLength: TakeModerationAction.maxNoteLength,
      counterWithin: 100,
      decoration: InputDecoration(
        labelText: required ? l10n.moderationNoteLabel : l10n.moderationNoteOptional,
        helperText: required ? l10n.moderationNoteForUser : null,
      ),
    );
  }
}

/// A suspension: its length (null = permanent) and the moderator's note.
typedef SuspensionChoice = ({int? days, String note});

/// "Suspend {name}": 1, 7 or 30 days or permanently, and a note (required). Null when cancelled.
Future<SuspensionChoice?> showSuspendDialog(BuildContext context, {required String name}) =>
    showDialog<SuspensionChoice>(context: context, builder: (_) => _SuspendDialog(name: name));

class _SuspendDialog extends StatefulWidget {
  const _SuspendDialog({required this.name});

  final String name;

  @override
  State<_SuspendDialog> createState() => _SuspendDialogState();
}

class _SuspendDialogState extends State<_SuspendDialog> {
  final _note = TextEditingController();
  int? _days = TakeModerationAction.suspensionDays.first;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final valid = _note.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(l10n.moderationSuspendTitle(widget.name)),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.moderationSuspendBody, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s4),
          Text(l10n.moderationSuspendDuration, style: context.textTheme.labelLarge),
          const SizedBox(height: ReadInSpace.s2),
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s2,
            children: [
              for (final days in TakeModerationAction.suspensionDays)
                ChoiceChip(
                  label: Text(l10n.suspensionLength(days)),
                  selected: _days == days,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _days = days),
                ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s4),
          ModerationNoteField(controller: _note, required: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: valid ? () => Navigator.of(context).pop((days: _days, note: _note.text.trim())) : null,
          child: Text(l10n.moderationSuspendConfirm),
        ),
      ],
    );
  }
}
