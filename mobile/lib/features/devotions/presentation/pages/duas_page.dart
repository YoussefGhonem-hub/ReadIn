import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/devotions.dart';
import '../cubit/devotions_cubits.dart';
import '../widgets/devotions_widgets.dart';

/// «أدعيتي» (F38): the account's own du'as, oldest first. ＋ adds one; a du'a's menu edits or deletes it (after a
/// confirmation). They live on the account, so they come back after a reinstall.
class DuasPage extends StatelessWidget {
  const DuasPage({super.key, this.cubit});

  /// Test seam; the app takes the cubit from DI.
  final DuasCubit? cubit;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => (cubit ?? getIt<DuasCubit>())..load(), child: const DuasView());
}

class DuasView extends StatelessWidget {
  const DuasView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DuasCubit>();
    final state = context.watch<DuasCubit>().state;
    final canAdd = state.status == DevotionsStatus.ready && !state.busy && state.items.length < DuasCubit.limit;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devotionsDuas),
        actions: [
          if (state.items.isNotEmpty)
            IconButton(
              key: const ValueKey('duas-reset'),
              tooltip: l10n.devotionsReset,
              onPressed: cubit.reset,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
        ],
      ),
      floatingActionButton: state.status == DevotionsStatus.ready
          ? FloatingActionButton.extended(
              key: const ValueKey('duas-add'),
              onPressed: canAdd ? () => unawaited(_edit(context)) : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.duasAdd),
            )
          : null,
      body: switch (state.status) {
        DevotionsStatus.loading => const Center(child: CircularProgressIndicator()),
        DevotionsStatus.failure => ErrorView(failure: state.failure!, onRetry: cubit.load),
        DevotionsStatus.ready when state.items.isEmpty => EmptyView(
          icon: Icons.volunteer_activism_outlined,
          title: l10n.duasEmptyTitle,
          body: l10n.duasEmptyBody,
        ),
        DevotionsStatus.ready => RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView.separated(
            key: const ValueKey('duas-list'),
            padding: const EdgeInsets.fromLTRB(0, ReadInSpace.s4, 0, ReadInSpace.s9 + ReadInSpace.s5),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: ReadInSpace.s3),
            itemBuilder: (context, i) => DevotionsColumn(
              child: _DuaCard(
                key: ValueKey('dua-${state.items[i].id}'),
                dua: state.items[i],
                left: state.left(state.items[i]),
              ),
            ),
          ),
        ),
      },
    );
  }
}

/// Opens the editor for a new du'a, or for [dua]; saves it and says so.
Future<void> _edit(BuildContext context, [PersonalDua? dua]) async {
  final cubit = context.read<DuasCubit>();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: DuaEditorSheet(dua: dua),
    ),
  );
  if (saved == true && context.mounted) showActionMessage(context, context.l10n.duasSaved);
}

Future<void> _delete(BuildContext context, PersonalDua dua) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.duasDeleteTitle),
      content: Text(l10n.duasDeleteBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('dua-delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: dialogContext.colors.error,
            foregroundColor: dialogContext.colors.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.deleteConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final failure = await context.read<DuasCubit>().delete(dua.id);
  if (!context.mounted) return;
  if (failure != null) return showActionFailure(context, failure);
  showActionMessage(context, l10n.duasDeleted);
}

enum _DuaAction { edit, delete }

class _DuaCard extends StatelessWidget {
  const _DuaCard({super.key, required this.dua, required this.left});

  final PersonalDua dua;

  /// Repetitions left: a tap counts one, like the adhkar.
  final int left;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final busy = context.select((DuasCubit c) => c.state.busy);
    final done = left == 0;
    return Material(
      color: done ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        side: BorderSide(color: done ? colors.primary.withValues(alpha: 0.4) : colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('dua-count-${dua.id}'),
        onTap: done
            ? null
            : () {
                HapticFeedback.selectionClick();
                context.read<DuasCubit>().count(dua);
              },
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s4, ReadInSpace.s2, ReadInSpace.s1, ReadInSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: ReadInSpace.s2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (dua.title case final title?) ...[
                        Text(title, textDirection: _direction(title), style: context.textTheme.titleMedium),
                        const SizedBox(height: ReadInSpace.s2),
                      ],
                      Text(
                        dua.text,
                        textDirection: _direction(dua.text),
                        style: context.textTheme.bodyLarge?.copyWith(height: 1.9, color: colors.textPrimary),
                      ),
                      const SizedBox(height: ReadInSpace.s3),
                      Semantics(
                        liveRegion: true,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: DevotionsCounter(left: left, total: dua.repeat),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<_DuaAction>(
                key: ValueKey('dua-menu-${dua.id}'),
                enabled: !busy,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) => unawaited(switch (action) {
                  _DuaAction.edit => _edit(context, dua),
                  _DuaAction.delete => _delete(context, dua),
                }),
                itemBuilder: (_) => [
                  PopupMenuItem(key: const ValueKey('dua-edit'), value: _DuaAction.edit, child: Text(l10n.edit)),
                  PopupMenuItem(
                    key: const ValueKey('dua-delete'),
                    value: _DuaAction.delete,
                    child: Text(l10n.deleteConfirm, style: TextStyle(color: colors.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A du'a is usually Arabic; one written in English reads left to right.
  static TextDirection _direction(String text) =>
      RegExp(r'[؀-ۿ]').hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
}

/// Add or edit a du'a: an optional one-line title (≤ 100), the text (1–2,000, line breaks kept) and how many times it is
/// said (1–1,000, Western or Arabic-Indic digits). The same checks
/// as the API run before sending; its answer's field errors show under the fields.
class DuaEditorSheet extends StatefulWidget {
  const DuaEditorSheet({super.key, this.dua});

  /// Null for a new du'a.
  final PersonalDua? dua;

  static const titleMax = 100;
  static const textMax = 2000;

  @override
  State<DuaEditorSheet> createState() => _DuaEditorSheetState();
}

class _DuaEditorSheetState extends State<DuaEditorSheet> {
  late final _title = TextEditingController(text: widget.dua?.title ?? '');
  late final _text = TextEditingController(text: widget.dua?.text ?? '');
  late final _repeat = TextEditingController(text: '${widget.dua?.repeat ?? 1}');
  String? _titleError;
  String? _textError;
  String? _repeatError;
  Failure? _failure;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _repeat.dispose();
    super.dispose();
  }

  /// The repeat count typed in Western or Arabic-Indic digits; null when it isn't a whole number.
  static int? _parseRepeat(String value) {
    final western = value.trim().replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
    return int.tryParse(western);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final title = _title.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final text = _text.text.trim();
    final repeat = _parseRepeat(_repeat.text);
    setState(() {
      _titleError = title.length > DuaEditorSheet.titleMax ? l10n.errTooLong : null;
      _textError = text.isEmpty ? l10n.fieldRequired : (text.length > DuaEditorSheet.textMax ? l10n.errTooLong : null);
      _repeatError = repeat == null || repeat < 1 || repeat > DuaDraft.maxRepeat ? l10n.errInvalidValue : null;
      _failure = null;
    });
    if (_titleError != null || _textError != null || _repeatError != null) return;
    final draft = DuaDraft(title: title.isEmpty ? null : title, text: text, repeat: repeat!);
    final failure = await context.read<DuasCubit>().save(draft, id: widget.dua?.id);
    if (!mounted) return;
    if (failure == null) return Navigator.of(context).pop(true);
    String? fieldError(String name) => switch (failure.fieldErrors[name]?.firstOrNull) {
      final code? => localizeErrorCode(l10n, code),
      null => null,
    };
    setState(() {
      _titleError = fieldError('title');
      _textError = fieldError('text');
      _repeatError = fieldError('repeat');
      _failure = _titleError == null && _textError == null && _repeatError == null ? failure : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = context.select((DuasCubit c) => c.state.busy);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, 0, ReadInSpace.s4, ReadInSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.dua == null ? l10n.duasAdd : l10n.duasEdit, style: context.textTheme.titleLarge),
            const SizedBox(height: ReadInSpace.s4),
            TextField(
              key: const ValueKey('dua-title'),
              controller: _title,
              textInputAction: TextInputAction.next,
              maxLines: 1,
              decoration: InputDecoration(labelText: l10n.duasTitleLabel, errorText: _titleError),
            ),
            const SizedBox(height: ReadInSpace.s3),
            TextField(
              key: const ValueKey('dua-text'),
              controller: _text,
              autofocus: widget.dua == null,
              minLines: 5,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: l10n.duasTextLabel,
                errorText: _textError,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: ReadInSpace.s3),
            TextField(
              key: const ValueKey('dua-repeat'),
              controller: _repeat,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(labelText: l10n.duasRepeatLabel, errorText: _repeatError, counterText: ''),
            ),
            if (_failure case final failure?) ...[
              const SizedBox(height: ReadInSpace.s3),
              Text(localizeFailure(l10n, failure), style: TextStyle(color: context.colors.error)),
            ],
            const SizedBox(height: ReadInSpace.s4),
            FilledButton(
              key: const ValueKey('dua-save'),
              onPressed: busy ? null : () => unawaited(_save()),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
