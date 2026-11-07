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

/// A suspension: its length (null = permanent), the reason, and whether all of the user's articles and comments are
/// hidden too (F23, for spam accounts; it can be undone).
typedef SuspensionChoice = ({int? days, String note, bool hideContent});

/// "Suspend {name}", the console's form (F23): 1, 3, 7 or 30 days, a custom 1–365 days, or permanently; a reason of
/// 5–500 characters; and "Also hide all of their articles and comments". Null when cancelled.
Future<SuspensionChoice?> showSuspendDialog(BuildContext context, {required String name}) =>
    showDialog<SuspensionChoice>(context: context, builder: (_) => SuspendDialog(name: name));

class SuspendDialog extends StatefulWidget {
  const SuspendDialog({super.key, required this.name});

  final String name;

  @override
  State<SuspendDialog> createState() => _SuspendDialogState();
}

/// The custom length's chip ("Custom…").
const _customDays = -1;

class _SuspendDialogState extends State<SuspendDialog> {
  final _note = TextEditingController();
  final _custom = TextEditingController();
  int? _days = TakeModerationAction.suspensionDays.first;
  bool _hideContent = false;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
    _custom.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    _custom.dispose();
    super.dispose();
  }

  /// The custom length, when it is a whole number of 1–365 days.
  int? get _customValue {
    final value = int.tryParse(_custom.text.trim());
    return value != null && value >= TakeModerationAction.minSuspensionDays && value <= TakeModerationAction.maxSuspensionDays
        ? value
        : null;
  }

  bool get _valid =>
      _note.text.trim().length >= TakeModerationAction.minSuspensionReason && (_days != _customDays || _customValue != null);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final customInvalid = _days == _customDays && _custom.text.trim().isNotEmpty && _customValue == null;
    Widget chip(int? days, String label) => ChoiceChip(
          key: ValueKey('suspend-days-${days ?? 'forever'}'),
          label: Text(label),
          selected: _days == days,
          showCheckmark: false,
          onSelected: (_) => setState(() => _days = days),
        );
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
                if (days != null) chip(days, l10n.suspensionLength(days)),
              chip(_customDays, l10n.adminSuspendCustom),
              chip(null, l10n.moderationPermanent),
            ],
          ),
          if (_days == _customDays) ...[
            const SizedBox(height: ReadInSpace.s3),
            TextField(
              key: const ValueKey('suspend-custom-days'),
              controller: _custom,
              autofocus: true,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.adminSuspendCustomLabel,
                errorText: customInvalid ? l10n.adminSuspendCustomInvalid : null,
              ),
            ),
          ],
          const SizedBox(height: ReadInSpace.s4),
          BidiTextField(
            key: const ValueKey('suspend-reason'),
            controller: _note,
            minLines: 2,
            maxLines: 5,
            maxLength: TakeModerationAction.maxNoteLength,
            counterWithin: 100,
            decoration: InputDecoration(labelText: l10n.adminSuspendReason, helperText: l10n.adminSuspendReasonHint),
          ),
          const SizedBox(height: ReadInSpace.s2),
          CheckboxListTile(
            key: const ValueKey('suspend-hide-content'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _hideContent,
            onChanged: (value) => setState(() => _hideContent = value ?? false),
            title: Text(l10n.adminSuspendHideContent),
            subtitle: Text(l10n.adminSuspendHideContentHint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: _valid
              ? () => Navigator.of(context).pop((
                    days: _days == _customDays ? _customValue : _days,
                    note: _note.text.trim(),
                    hideContent: _hideContent,
                  ))
              : null,
          child: Text(l10n.moderationSuspendConfirm),
        ),
      ],
    );
  }
}
