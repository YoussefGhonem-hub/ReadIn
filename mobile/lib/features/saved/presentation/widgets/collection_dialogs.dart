import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../domain/usecases/saved_usecases.dart';

/// Asks for a collection name (create or rename). [submit] runs while the dialog shows progress; a failure (e.g.
/// `collection.name_taken`) stays in the dialog under the field, success closes it with the value.
Future<T?> showCollectionNameDialog<T>(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
  required Future<(T?, Failure?)> Function(String name) submit,
}) =>
    showDialog<T>(
      context: context,
      builder: (_) => CollectionNameDialog<T>(title: title, action: action, initial: initial, submit: submit),
    );

class CollectionNameDialog<T> extends StatefulWidget {
  const CollectionNameDialog({super.key, required this.title, required this.action, required this.submit, this.initial = ''});

  final String title;
  final String action;
  final String initial;
  final Future<(T?, Failure?)> Function(String name) submit;

  @override
  State<CollectionNameDialog<T>> createState() => _CollectionNameDialogState<T>();
}

class _CollectionNameDialogState<T> extends State<CollectionNameDialog<T>> {
  late final _name = TextEditingController(text: widget.initial);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = l10n.fieldRequired);
    if (name.length > ManageCollections.maxNameLength) return setState(() => _error = l10n.errTooLong);
    setState(() {
      _busy = true;
      _error = null;
    });
    final (value, failure) = await widget.submit(name);
    if (!mounted) return;
    if (failure == null) return Navigator.of(context).pop(value);
    setState(() {
      _busy = false;
      _error = localizeActionFailure(l10n, failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: BidiTextField(
        controller: _name,
        enabled: !_busy,
        maxLength: ManageCollections.maxNameLength,
        counterWithin: 10,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(labelText: l10n.collectionName, hintText: l10n.collectionNameHint, errorText: _error),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.action),
        ),
      ],
    );
  }
}

/// "Delete “name”? Its articles stay saved." True when confirmed.
Future<bool> confirmDeleteCollection(BuildContext context, String name) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteCollectionTitle(name)),
      content: Text(l10n.deleteCollectionBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: dialogContext.colors.error, foregroundColor: dialogContext.colors.onError),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.deleteConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
