import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart' show embedContent;
import '../../domain/entities/writer_category.dart';
import '../../domain/services/category_names.dart';

/// Asks for a category name (F31): "＋ قسم جديد" in the editor and on the own Categories tab, and "Rename". The rules
/// the API applies are checked first, with inline messages (1–40 characters, a letter or digit, not the name of
/// another of [existing], ignoring case and Arabic spelling). [submit] then runs while the dialog shows progress: a
/// refusal (`category.name_taken`, `category.limit`, …) stays under the field, success closes the dialog with its value.
Future<T?> showCategoryNameDialog<T>(
  BuildContext context, {
  required String title,
  required String action,
  required List<WriterCategory> existing,
  required Future<Result<T>> Function(String name) submit,
  WriterCategory? renaming,
}) =>
    showDialog<T>(
      context: context,
      builder: (_) => CategoryNameDialog<T>(title: title, action: action, existing: existing, submit: submit, renaming: renaming),
    );

class CategoryNameDialog<T> extends StatefulWidget {
  const CategoryNameDialog({
    super.key,
    required this.title,
    required this.action,
    required this.existing,
    required this.submit,
    this.renaming,
  });

  final String title;
  final String action;
  final List<WriterCategory> existing;
  final Future<Result<T>> Function(String name) submit;

  /// The category being renamed: its name fills the field, and another spelling of it (its case) is allowed.
  final WriterCategory? renaming;

  @override
  State<CategoryNameDialog<T>> createState() => _CategoryNameDialogState<T>();
}

class _CategoryNameDialogState<T> extends State<CategoryNameDialog<T>> {
  late final _name = TextEditingController(text: widget.renaming?.name ?? '');
  bool _busy = false;

  /// Shown once "Create" / "Save" was pressed, or while the name is already too long.
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _check(AppLocalizations l10n, String name, {required bool submitting}) {
    final error = CategoryNames.validate(name);
    return switch (error) {
      CategoryNameError.tooLong => l10n.categoryNameTooLong,
      CategoryNameError.empty when submitting => l10n.fieldRequired,
      CategoryNameError.noLetter when submitting => l10n.categoryNameNoLetter,
      CategoryNameError.empty || CategoryNameError.noLetter => null,
      null when CategoryNames.isTaken(widget.existing, name, exceptId: widget.renaming?.id) => l10n.errCategoryNameTaken,
      null => null,
    };
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final name = CategoryNames.clean(_name.text);
    final error = _check(l10n, name, submitting: true);
    if (error != null) return setState(() => _error = error);
    // The same name as now: nothing to send.
    if (widget.renaming case final renaming? when renaming.name == name) return Navigator.of(context).pop();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.submit(name);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = _message(l10n, failure);
        });
    }
  }

  /// `400 validation.failed` carries `category.name_invalid` in `errors.name`.
  static String _message(AppLocalizations l10n, Failure failure) => localizeActionFailure(l10n, failure);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: BidiTextField(
        key: const ValueKey('category-name-input'),
        controller: _name,
        enabled: !_busy,
        maxLength: CategoryNames.maxLength,
        counterWithin: 10,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        onChanged: (text) {
          // Too long or taken shows while typing; "required" and "a letter or digit" wait for the button.
          final live = _check(l10n, CategoryNames.clean(text), submitting: false);
          if (live != _error) setState(() => _error = live);
        },
        decoration: InputDecoration(labelText: l10n.categoryNameLabel, hintText: l10n.categoryNameHint, errorText: _error, errorMaxLines: 3),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('category-name-submit'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.action),
        ),
      ],
    );
  }
}

/// "Delete “name”?" with how many articles are in it; they stay published, without a category. True when confirmed.
Future<bool> confirmDeleteCategory(BuildContext context, WriterCategory category) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.categoryDeleteTitle(embedContent(category.name))),
      content: Text(l10n.categoryDeleteBody(category.articleCount)),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('category-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: dialogContext.colors.error, foregroundColor: dialogContext.colors.onError),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.deleteAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
