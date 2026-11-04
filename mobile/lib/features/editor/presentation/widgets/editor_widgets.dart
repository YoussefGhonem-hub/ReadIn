import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/inline_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../comments/presentation/cubit/mention_suggestions_cubit.dart';
import '../../domain/entities/editor_entities.dart';
import '../block_editor/block_editor_controller.dart';
import '../block_editor/block_editor_surface.dart';
import '../block_editor/block_kinds_ui.dart';
import '../block_editor/inline_formatter.dart';
import '../cubit/article_editor_cubit.dart';

/// The article language's name in the UI language.
String articleLanguageName(AppLocalizations l10n, String language) =>
    language == ArticleLanguages.en ? l10n.articleVersionEnglish : l10n.articleVersionArabic;

/// جاري الحفظ… / اتحفظ / offline, saved on the device (F05 autosave).
class SaveStatusLabel extends StatelessWidget {
  const SaveStatusLabel({super.key, required this.state});

  final ArticleEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (IconData? icon, String? text, Color color) = switch (state.saveStatus) {
      SaveStatus.saving => (Icons.sync_rounded, l10n.saveStatusSaving, colors.textSecondary),
      SaveStatus.offline => (Icons.cloud_off_rounded, l10n.saveStatusOffline, colors.textSecondary),
      SaveStatus.failed => (Icons.error_outline_rounded, l10n.saveStatusFailed, colors.error),
      SaveStatus.saved when !state.dirty => (Icons.cloud_done_outlined, l10n.saveStatusSaved, colors.textSecondary),
      _ when state.dirty => (null, l10n.saveStatusUnsaved, colors.textSecondary),
      _ when !state.isNew => (Icons.cloud_done_outlined, l10n.saveStatusSaved, colors.textSecondary),
      _ => (null, null, colors.textSecondary),
    };
    if (text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Row(
        key: const ValueKey('save-status'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: ReadInSpace.s1)],
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

/// The language versions as tabs: the source first, then the translation or "Add the … version".
class LanguageBar extends StatelessWidget {
  const LanguageBar({super.key, required this.state});

  final ArticleEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ArticleEditorCubit>();
    final document = state.document;
    final enabled = state.busy == EditorBusy.none;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s2),
      child: Row(
        children: [
          for (final t in document.translations) ...[
            ChoiceChip(
              key: ValueKey('language-${t.language}'),
              selected: t.language == state.activeLanguage,
              label: Text(
                t.language == document.sourceLanguage
                    ? '${articleLanguageName(l10n, t.language)} · ${l10n.sourceLanguageTag}'
                    : articleLanguageName(l10n, t.language),
              ),
              onSelected: (_) => cubit.setActiveLanguage(t.language),
            ),
            const SizedBox(width: ReadInSpace.s2),
          ],
          if (!document.hasTranslation)
            ActionChip(
              key: const ValueKey('language-add'),
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.addTranslation(articleLanguageName(l10n, ArticleLanguages.other(document.sourceLanguage)))),
              onPressed: enabled ? cubit.addTranslation : null,
            ),
        ],
      ),
    );
  }
}

/// The publish checks in one line: "Ready to publish · 6 min read" or "3 things to fix"; opens the list.
class ChecksStrip extends StatelessWidget {
  const ChecksStrip({super.key, required this.state, required this.onOpen});

  final ArticleEditorState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final problems = state.problems;
    final ready = problems.isEmpty && !state.uploading;
    final minutes = state.readingTime?.minutes;
    final text = problems.isNotEmpty
        ? l10n.checksCount(problems.length)
        : state.uploading
            ? l10n.checksUploading
            : l10n.checksReady;
    return Material(
      color: colors.surface,
      child: InkWell(
        key: const ValueKey('checks-strip'),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s3),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
          child: Row(
            children: [
              Icon(
                ready ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                size: 20,
                color: ready ? colors.success : colors.accent,
              ),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(child: Text(text, style: context.textTheme.bodyMedium)),
              if (minutes != null && minutes > 0) Text(l10n.readingTime(minutes), style: context.textTheme.bodySmall),
              const SizedBox(width: ReadInSpace.s1),
              Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The message of a publish problem.
String problemMessage(AppLocalizations l10n, DraftProblem problem) => switch (problem.code) {
      DraftProblemCodes.fieldRequired => l10n.problemFieldRequired,
      DraftProblemCodes.titleLength => l10n.problemTitleLength,
      DraftProblemCodes.contentEmpty => l10n.problemContentEmpty,
      DraftProblemCodes.contentInvalid => l10n.problemContentInvalid,
      DraftProblemCodes.imageAltRequired => l10n.problemImageAlt,
      DraftProblemCodes.sourcesRequired => l10n.problemSourcesRequired,
      DraftProblemCodes.attachmentAltRequired => l10n.problemAttachmentAlt,
      DraftProblemCodes.attachmentTitleRequired => l10n.problemAttachmentTitle,
      DraftProblemCodes.attachmentNotReady => l10n.problemAttachmentNotReady,
      _ => l10n.errServer,
    };

/// Where tapping a problem goes.
enum ProblemTarget { settings, title, content, block }

ProblemTarget problemTarget(DraftProblem problem) => switch (problem.code) {
      DraftProblemCodes.titleLength => ProblemTarget.title,
      DraftProblemCodes.imageAltRequired when problem.blockId != null => ProblemTarget.block,
      DraftProblemCodes.contentEmpty || DraftProblemCodes.contentInvalid || DraftProblemCodes.imageAltRequired =>
        ProblemTarget.content,
      _ => ProblemTarget.settings,
    };

/// The publish checks: reading time per language, then each problem; tapping one jumps to its block or field.
class ChecksList extends StatelessWidget {
  const ChecksList({super.key, required this.state, required this.onProblem});

  final ArticleEditorState state;
  final ValueChanged<DraftProblem> onProblem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final problems = state.problems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s2,
          children: [
            for (final t in state.document.translations)
              InfoTag(
                label: '${articleLanguageName(l10n, t.language)} · ${l10n.readingTime(state.checks.readingTimeOf(t.language)?.minutes ?? 0)}',
                tone: InfoTagTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        if (problems.isEmpty && !state.uploading)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle_outline_rounded, color: colors.success),
            title: Text(l10n.checksReady),
          ),
        if (state.uploading)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_upload_outlined, color: colors.accent),
            title: Text(l10n.checksUploading),
          ),
        for (final (i, p) in problems.indexed)
          ListTile(
            key: ValueKey('problem-$i'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.error_outline_rounded, color: colors.accent),
            title: Text(problemMessage(l10n, p)),
            subtitle: p.language == null || !state.document.hasTranslation
                ? null
                : Text(articleLanguageName(l10n, p.language!), style: context.textTheme.bodySmall),
            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
            onTap: () => onProblem(p),
          ),
      ],
    );
  }
}


/// The editor's toolbar above the keyboard: "Add a block", block options, undo and redo, formatting for the text the
/// writer is in (a structured block's field in [focus] first, else [formatter]), the table tools while a table cell
/// is in focus, and, while one is typed, the `@mention` suggestions or the slash menu's blocks.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.formatter,
    required this.onAddBlock,
    required this.onBlockOptions,
    required this.enabled,
    this.focus,
    this.history,
    this.onTableTool,
  });

  final InlineFormatter? formatter;
  final VoidCallback onAddBlock;

  /// Opens the options of the block the writer is in.
  final VoidCallback onBlockOptions;
  final bool enabled;

  /// The field of a structured block in focus (a table cell, a step's text).
  final EditorFocus? focus;
  final UndoRedo? history;
  final ValueChanged<TableTool>? onTableTool;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([formatter, focus, history]),
      builder: (context, _) {
        final formatter = focus?.active ?? this.formatter;
        final canFormat = enabled && (formatter?.canFormat ?? false);
        final mention = canFormat ? formatter!.activeMention : null;
        final slash = canFormat ? formatter!.slashQuery : null;
        final cell = focus?.cell;
        final history = this.history;
        final suggestions = context.watch<MentionSuggestionsCubit>().state;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.read<MentionSuggestionsCubit>().search(mention?.query);
        });
        final kinds = slash == null ? const <RBlockKind>[] : [for (final k in RBlockKind.values) if (k.matches(slash, l10n)) k];

        Widget mark(RMarkType type, IconData icon, String tooltip) => IconButton(
              key: ValueKey('format-${type.name}'),
              tooltip: tooltip,
              isSelected: canFormat && formatter!.hasMark(type),
              color: colors.textSecondary,
              selectedIcon: Icon(icon, color: colors.primary),
              onPressed: canFormat ? () => formatter!.toggleMark(type) : null,
              icon: Icon(icon),
            );

        Widget tableTool(TableTool tool, Widget icon, String tooltip, {Color? color}) => IconButton(
              key: ValueKey('table-${tool.name}'),
              tooltip: tooltip,
              color: color ?? colors.textSecondary,
              onPressed: enabled && onTableTool != null ? () => onTableTool!(tool) : null,
              icon: icon,
            );

        return Material(
          color: colors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mention != null && suggestions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    key: const ValueKey('mention-suggestions'),
                    shrinkWrap: true,
                    children: [
                      for (final user in suggestions)
                        ListTile(
                          dense: true,
                          leading: UserAvatar(name: user.displayName, url: user.avatarUrl, size: 28),
                          title: BidiText(user.displayName),
                          subtitle: Text('@${user.username}', textDirection: TextDirection.ltr),
                          onTap: () {
                            formatter!.insertMention(mention, userId: user.id, text: '@${user.username}');
                            context.read<MentionSuggestionsCubit>().clear();
                          },
                        ),
                    ],
                  ),
                ),
              if (slash != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: kinds.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(ReadInSpace.s4),
                          child: Text(l10n.slashNoMatches, style: context.textTheme.bodySmall),
                        )
                      : ListView(
                          key: const ValueKey('slash-menu'),
                          shrinkWrap: true,
                          children: [
                            for (final kind in kinds)
                              ListTile(
                                key: ValueKey('slash-${kind.name}'),
                                dense: true,
                                leading: Icon(kind.icon, size: 20),
                                title: Text(kind.label(l10n)),
                                onTap: () => formatter!.applySlash(kind),
                              ),
                          ],
                        ),
                ),
              if (cell != null)
                DecoratedBox(
                  key: const ValueKey('table-tools'),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s2, end: ReadInSpace.s1),
                          child: Text(l10n.tableTools, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
                        ),
                        tableTool(TableTool.addRow, const _TableToolIcon(Icons.table_rows_outlined, add: true), l10n.tableAddRow),
                        tableTool(TableTool.addColumn, const _TableToolIcon(Icons.view_column_outlined, add: true), l10n.tableAddColumn),
                        tableTool(TableTool.deleteRow, const _TableToolIcon(Icons.table_rows_outlined, add: false), l10n.tableDeleteRow),
                        tableTool(TableTool.deleteColumn, const _TableToolIcon(Icons.view_column_outlined, add: false), l10n.tableDeleteColumn),
                        tableTool(TableTool.deleteTable, const Icon(Icons.delete_outline_rounded), l10n.tableDelete, color: colors.error),
                      ],
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('toolbar-add-block'),
                        tooltip: l10n.addBlock,
                        color: colors.primary,
                        onPressed: enabled ? onAddBlock : null,
                        icon: const Icon(Icons.add_box_outlined),
                      ),
                      IconButton(
                        key: const ValueKey('toolbar-block-options'),
                        tooltip: l10n.blockOptions,
                        color: colors.textSecondary,
                        onPressed: enabled ? onBlockOptions : null,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      if (history != null) ...[
                        // Both icons mirror in RTL (matchTextDirection).
                        IconButton(
                          key: const ValueKey('toolbar-undo'),
                          tooltip: l10n.undo,
                          color: colors.textSecondary,
                          onPressed: enabled && history.canUndo ? history.undo : null,
                          icon: const Icon(Icons.undo_rounded),
                        ),
                        IconButton(
                          key: const ValueKey('toolbar-redo'),
                          tooltip: l10n.redo,
                          color: colors.textSecondary,
                          onPressed: enabled && history.canRedo ? history.redo : null,
                          icon: const Icon(Icons.redo_rounded),
                        ),
                      ],
                      mark(RMarkType.bold, Icons.format_bold_rounded, l10n.formatBold),
                      mark(RMarkType.italic, Icons.format_italic_rounded, l10n.formatItalic),
                      mark(RMarkType.strike, Icons.format_strikethrough_rounded, l10n.formatStrike),
                      mark(RMarkType.code, Icons.code_rounded, l10n.formatCode),
                      mark(RMarkType.highlight, Icons.border_color_outlined, l10n.formatHighlight),
                      IconButton(
                        key: const ValueKey('format-link'),
                        tooltip: l10n.formatLink,
                        color: colors.textSecondary,
                        isSelected: canFormat && formatter!.link != null,
                        selectedIcon: Icon(Icons.link_rounded, color: colors.primary),
                        onPressed: canFormat && formatter!.hasRange ? () => _editLink(context, formatter) : null,
                        icon: const Icon(Icons.link_rounded),
                      ),
                      IconButton(
                        key: const ValueKey('format-mention'),
                        tooltip: l10n.formatMention,
                        color: colors.textSecondary,
                        onPressed: canFormat ? formatter!.startMention : null,
                        icon: const Icon(Icons.alternate_email_rounded),
                      ),
                      IconButton(
                        key: const ValueKey('format-line-break'),
                        tooltip: l10n.formatLineBreak,
                        color: colors.textSecondary,
                        onPressed: canFormat ? formatter!.insertHardBreak : null,
                        icon: const Icon(Icons.keyboard_return_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editLink(BuildContext context, InlineFormatter formatter) async {
    final href = await showLinkDialog(context, initial: formatter.link);
    if (href == null) return;
    formatter.setLink(href.isEmpty ? null : href);
  }
}

/// Asks for a link (http/https). Returns '' to remove the link, null when cancelled.
Future<String?> showLinkDialog(BuildContext context, {String? initial}) => showDialog<String>(
      context: context,
      builder: (dialog) => _LinkDialog(initial: initial),
    );

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({this.initial});

  final String? initial;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _url = TextEditingController(text: widget.initial ?? 'https://');
  bool _invalid = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (!InlineEditing.isHttpUrl(_url.text)) return setState(() => _invalid = true);
    Navigator.of(context).pop(_url.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.linkDialogTitle),
      content: TextField(
        key: const ValueKey('link-url'),
        controller: _url,
        autofocus: true,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        autocorrect: false,
        decoration: InputDecoration(labelText: l10n.linkUrlLabel, errorText: _invalid ? l10n.linkInvalid : null),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if (widget.initial != null) TextButton(onPressed: () => Navigator.of(context).pop(''), child: Text(l10n.linkRemove)),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(key: const ValueKey('link-save'), onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

/// A confirmation dialog; true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirm,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(dialog.l10n.cancel)),
        FilledButton(
          key: const ValueKey('confirm-action'),
          style: destructive ? FilledButton.styleFrom(backgroundColor: dialog.colors.error, foregroundColor: dialog.colors.onError) : null,
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}


/// A table tool's icon: rows or columns with a small plus or minus.
class _TableToolIcon extends StatelessWidget {
  const _TableToolIcon(this.icon, {required this.add});

  final IconData icon;
  final bool add;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            PositionedDirectional(
              end: -4,
              bottom: -4,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.colors.surface, shape: BoxShape.circle),
                child: Icon(add ? Icons.add_circle_rounded : Icons.remove_circle_rounded, size: 13),
              ),
            ),
          ],
        ),
      );
}
