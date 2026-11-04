import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/rdoc_scope.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../comments/presentation/cubit/mention_suggestions_cubit.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../../media/presentation/cubit/attachments_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/editor_entities.dart';
import '../appflowy/appflowy_surface.dart';
import '../block_editor/block_editor_controller.dart';
import '../block_editor/block_editor_surface.dart';
import '../block_editor/block_editors.dart';
import '../block_editor/inline_formatter.dart';
import '../cubit/article_editor_cubit.dart';
import '../cubit/revisions_cubit.dart';
import '../cubit/tag_suggestions_cubit.dart';
import '../widgets/article_settings_sheet.dart';
import '../widgets/editor_widgets.dart';
import 'article_preview_page.dart';
import 'revisions_page.dart';

/// The article editor (F05), opened from "My articles": a new article ([articleId] null, created by the first
/// autosave) or an existing one.
class ArticleEditorPage extends StatelessWidget {
  const ArticleEditorPage({super.key, this.articleId});

  final String? articleId;

  @override
  Widget build(BuildContext context) {
    final language = context.read<SettingsCubit>().state.articleLanguage;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ArticleEditorCubit>()..open(articleId: articleId, language: language),
        ),
        BlocProvider(create: (_) => getIt<AttachmentsCubit>()),
        BlocProvider(create: (_) => getIt<MentionSuggestionsCubit>()),
        BlocProvider(create: (_) => getIt<TagSuggestionsCubit>()),
      ],
      child: const ArticleEditorView(),
    );
  }
}

/// The editor once its cubits are provided ([ArticleEditorCubit], [AttachmentsCubit], [MentionSuggestionsCubit],
/// [TagSuggestionsCubit]).
class ArticleEditorView extends StatefulWidget {
  const ArticleEditorView({super.key, this.surface = const AppFlowyBlockEditorSurface(), this.pickImage, this.author});

  /// The block-editing surface (AppFlowy).
  final BlockEditorSurface surface;

  /// Test seams.
  final Future<PickedMediaFile?> Function()? pickImage;
  final Author? author;

  @override
  State<ArticleEditorView> createState() => _ArticleEditorViewState();
}

class _ArticleEditorViewState extends State<ArticleEditorView> {
  final _focus = EditorFocus();
  final _contents = <String, BlockEditorController>{};
  final _titles = <String, TextEditingController>{};
  final _subtitles = <String, TextEditingController>{};
  final _titleFocus = <String, FocusNode>{};
  late final AppLifecycleListener _lifecycle;
  int _revision = -1;

  ArticleEditorCubit get _cubit => context.read<ArticleEditorCubit>();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onPause: _flush, onHide: _flush);
    _sync(_cubit.state);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    for (final c in _contents.values) {
      c.dispose();
    }
    for (final c in [..._titles.values, ..._subtitles.values]) {
      c.dispose();
    }
    for (final f in _titleFocus.values) {
      f.dispose();
    }
    _focus.dispose();
    super.dispose();
  }

  void _flush() => unawaited(_cubit.flush());

  /// Keeps one set of fields per language version, and reloads them when the document was replaced from outside
  /// the fields (open, reload, restore, discard).
  void _sync(ArticleEditorState state) {
    if (!state.isReady) return;
    final reload = state.documentRevision != _revision;
    _revision = state.documentRevision;
    final document = state.document;
    for (final language in [..._contents.keys]) {
      if (document.translation(language) != null) continue;
      // The removed version's fields still hold these until the next frame unmounts them.
      final removed = <ChangeNotifier?>[
        _contents.remove(language),
        _titles.remove(language),
        _subtitles.remove(language),
        _titleFocus.remove(language),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final notifier in removed) {
          notifier?.dispose();
        }
      });
    }
    for (final t in document.translations) {
      final existing = _contents[t.language];
      final controller = existing ?? widget.surface.createController(t.content);
      if (existing == null) {
        controller.addListener(() => _cubit.setContent(t.language, controller.document));
        _contents[t.language] = controller;
      } else if (reload) {
        controller.load(t.content);
      }
      final title = _titles.putIfAbsent(t.language, () => TextEditingController(text: t.title));
      final subtitle = _subtitles.putIfAbsent(t.language, () => TextEditingController(text: t.subtitle ?? ''));
      if (reload) {
        _set(title, t.title);
        _set(subtitle, t.subtitle ?? '');
      }
      _titleFocus.putIfAbsent(t.language, FocusNode.new);
    }
    if (!reload) return;
    final attachments = context.read<AttachmentsCubit>();
    if (!_sameItems(attachments.state.draftItems, document.attachments)) {
      attachments.seed(document.attachments, state.media);
    }
  }

  static void _set(TextEditingController c, String text) {
    if (c.text != text) c.text = text;
  }

  static bool _sameItems(List<AttachmentItem> a, List<AttachmentItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<PickedMediaFile?> _pickImage() async {
    final pick = widget.pickImage;
    if (pick != null) return pick();
    final files = await getIt<PickImages>()(limit: 1);
    return files.firstOrNull;
  }

  Author _author() {
    final given = widget.author;
    if (given != null) return given;
    final me = context.read<SessionCubit>().state.me;
    return me == null
        ? const Author(id: '', displayName: 'ReadIn', username: 'readin')
        : Author(
            id: me.id,
            displayName: me.displayName,
            username: me.username,
            avatarUrl: me.avatarUrl,
            isVerified: me.isVerified,
          );
  }

  Future<void> _onBack() async {
    await _cubit.flush();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Listeners ──────────────────────────────────────────────

  Future<void> _onEvent(BuildContext context, ArticleEditorState state) async {
    final l10n = context.l10n;
    switch (state.event) {
      case EditorEvent.published || EditorEvent.updated:
        showActionMessage(
          context,
          state.event == EditorEvent.published ? l10n.editorPublishedMessage : l10n.editorUpdatedMessage,
        );
        final slug = state.publishedSlug;
        if (slug != null) context.pushReplacement('/a/$slug');
      case EditorEvent.deleted:
        showActionMessage(context, l10n.articleDeleted);
        Navigator.of(context).pop(true);
      case EditorEvent.discarded:
        showActionMessage(context, l10n.changesDiscarded);
      case EditorEvent.restored:
        showActionMessage(context, l10n.revisionRestored);
      case null:
        break;
    }
  }

  Future<void> _offerBackup(BuildContext context, ArticleEditorState state) async {
    final backup = state.backupOffer;
    if (backup == null) return;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final time =
        '${formatDate(backup.editedAt.toLocal(), lang)} ${TimeOfDay.fromDateTime(backup.editedAt.toLocal()).format(context)}';
    final restore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.restoreBackupTitle),
        content: Text(l10n.restoreBackupBody(time)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.discardBackupAction)),
          FilledButton(
            key: const ValueKey('backup-restore'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.restoreAction),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (restore == true) {
      _cubit.restoreBackup();
    } else {
      await _cubit.dismissBackup();
    }
  }

  Future<void> _onConflict(BuildContext context) async {
    final l10n = context.l10n;
    final keepMine = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.conflictTitle),
        content: Text(l10n.conflictBody),
        actions: [
          TextButton(
            key: const ValueKey('conflict-reload'),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.conflictReload),
          ),
          FilledButton(
            key: const ValueKey('conflict-keep'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.conflictKeepMine),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (keepMine == true) {
      await _cubit.keepMine();
    } else {
      await _cubit.reloadServerCopy();
    }
  }

  // ── Actions ────────────────────────────────────────────────

  void _openPreview(ArticleEditorState state) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticlePreviewPage(
          data: PreviewData(
            document: state.document,
            author: _author(),
            media: [...state.media, ...state.attachmentAssets.values],
            field: state.field,
            topic: state.topics.where((t) => t.id == state.document.topicId).firstOrNull,
            readingTime: state.checks.readingTime,
            publishedAt: state.publishedAt,
          ),
        ),
      ),
    );
  }

  void _openChecks() {
    final cubit = _cubit;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
            child: BlocBuilder<ArticleEditorCubit, ArticleEditorState>(
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.checksTitle, style: context.textTheme.titleMedium),
                  const SizedBox(height: ReadInSpace.s3),
                  ChecksList(
                    state: state,
                    onProblem: (problem) {
                      Navigator.of(sheet).pop();
                      _goTo(problem);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Jumps to what a check is about: its block, the title, or the settings.
  void _goTo(DraftProblem problem) {
    final cubit = _cubit;
    final language = problem.language ?? cubit.state.activeLanguage;
    cubit.setActiveLanguage(language);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (problemTarget(problem)) {
        case ProblemTarget.settings:
          showArticleSettingsSheet(context);
        case ProblemTarget.title:
          _titleFocus[language]?.requestFocus();
        case ProblemTarget.content:
          final content = _contents[language];
          final first = content?.document.blocks.firstOrNull;
          if (first != null) content!.reveal(first.id);
        case ProblemTarget.block:
          _contents[language]?.reveal(problem.blockId!);
      }
    });
  }

  Future<void> _openRevisions(ArticleEditorState state) async {
    final id = state.articleId;
    if (id == null) return;
    final cubit = _cubit;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<RevisionsCubit>(param1: id)..load(),
          child: RevisionsPage(
            author: _author(),
            fields: state.fields,
            topics: state.topics,
            onRestore: cubit.restoreRevision,
          ),
        ),
      ),
    );
  }

  Future<void> _discard() async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.discardChangesTitle,
      body: l10n.discardChangesBody,
      confirm: l10n.discardAction,
      destructive: true,
    );
    if (ok && mounted) await _cubit.discardChanges();
  }

  Future<void> _delete(ArticleEditorState state) async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.deleteArticleTitle,
      body: state.isPublished ? l10n.deletePublishedBody : l10n.deleteDraftBody,
      confirm: l10n.deleteAction,
      destructive: true,
    );
    if (ok && mounted) await _cubit.delete();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        BlocListener<ArticleEditorCubit, ArticleEditorState>(
          listenWhen: (a, b) =>
              a.documentRevision != b.documentRevision ||
              a.loadStatus != b.loadStatus ||
              a.document.translations.length != b.document.translations.length,
          listener: (context, state) => setState(() => _sync(state)),
        ),
        BlocListener<ArticleEditorCubit, ArticleEditorState>(
          listenWhen: (a, b) => a.eventSeq != b.eventSeq,
          listener: _onEvent,
        ),
        BlocListener<ArticleEditorCubit, ArticleEditorState>(
          listenWhen: (a, b) => a.noticeSeq != b.noticeSeq && b.notice != null,
          listener: (context, state) => showActionFailure(context, state.notice),
        ),
        BlocListener<ArticleEditorCubit, ArticleEditorState>(
          listenWhen: (a, b) => a.backupOffer == null && b.backupOffer != null,
          listener: _offerBackup,
        ),
        BlocListener<ArticleEditorCubit, ArticleEditorState>(
          listenWhen: (a, b) => !a.conflicted && b.conflicted,
          listener: (context, _) => _onConflict(context),
        ),
        BlocListener<AttachmentsCubit, AttachmentsState>(
          listener: (context, attachments) =>
              _cubit.setAttachments(attachments.draftItems, busy: attachments.isBusy, assets: attachments.assetsById),
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_onBack());
        },
        child: BlocBuilder<ArticleEditorCubit, ArticleEditorState>(
          builder: (context, state) {
            final enabled = state.isReady && state.busy == EditorBusy.none && !state.conflicted;
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(onPressed: _onBack),
                titleSpacing: 0,
                title: state.isReady
                    ? SaveStatusLabel(state: state)
                    : Text(state.isNew ? l10n.editorNewTitle : l10n.editorEditTitle),
                actions: state.isReady
                    ? [
                        IconButton(
                          key: const ValueKey('editor-preview'),
                          tooltip: l10n.editorPreview,
                          onPressed: () => _openPreview(state),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          key: const ValueKey('editor-settings'),
                          tooltip: l10n.editorSettings,
                          onPressed: enabled ? () => showArticleSettingsSheet(context) : null,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        _MoreMenu(
                          state: state,
                          enabled: enabled,
                          onRevisions: () => _openRevisions(state),
                          onDiscard: _discard,
                          onDelete: () => _delete(state),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s3),
                          child: _PublishButton(state: state),
                        ),
                      ]
                    : null,
              ),
              body: switch (state.loadStatus) {
                EditorLoadStatus.loading => const Center(child: CircularProgressIndicator()),
                EditorLoadStatus.failure => ErrorView(
                  failure: state.loadFailure!,
                  onRetry: () => _cubit.open(articleId: state.articleId, language: state.activeLanguage),
                ),
                EditorLoadStatus.ready => _body(context, state, enabled),
              },
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ArticleEditorState state, bool enabled) {
    final l10n = context.l10n;
    final language = state.activeLanguage;
    final content = _contents[language];
    final title = _titles[language];
    final subtitle = _subtitles[language];
    if (content == null || title == null || subtitle == null) return const Center(child: CircularProgressIndicator());
    final direction = RDocScope.directionForLanguage(language);
    final titleStyle = context.textTheme.headlineSmall?.copyWith(fontSize: ReadInType.h3Size + 2, height: 1.45);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BidiTextField(
            key: ValueKey('editor-title-$language'),
            controller: title,
            focusNode: _titleFocus[language],
            enabled: enabled,
            maxLength: DraftLimits.maxTitle,
            counterWithin: 20,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))],
            style: titleStyle,
            decoration: bareDecoration(
              hintText: l10n.editorTitleHint,
              hintStyle: titleStyle?.copyWith(color: context.colors.textSecondary),
            ),
            onChanged: (v) => _cubit.setTitle(language, v),
          ),
          const SizedBox(height: ReadInSpace.s2),
          BidiTextField(
            key: ValueKey('editor-subtitle-$language'),
            controller: subtitle,
            enabled: enabled,
            maxLength: DraftLimits.maxSubtitle,
            counterWithin: 30,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.text,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))],
            style: context.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
            decoration: bareDecoration(hintText: l10n.editorSubtitleHint),
            onChanged: (v) => _cubit.setSubtitle(language, v),
          ),
          Padding(
            padding: const EdgeInsets.only(top: ReadInSpace.s3, bottom: ReadInSpace.s3),
            child: Divider(height: 1, color: context.colors.border),
          ),
        ],
      ),
    );
    final formatter = content is InlineFormatter ? content as InlineFormatter : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LanguageBar(state: state),
        Expanded(
          child: RDocScope(
            baseDirection: direction,
            child: KeyedSubtree(
              key: ValueKey('editor-body-$language'),
              child: widget.surface.build(
                context,
                content,
                BlockEditorContext(
                  fallbackDirection: direction,
                  focus: _focus,
                  pickImage: _pickImage,
                  uploadImage: _cubit.uploadImage,
                  enabled: enabled,
                  header: header,
                  problemBlockIds: {
                    for (final p in state.problems)
                      if (p.blockId != null && p.language == language) p.blockId!,
                  },
                ),
              ),
            ),
          ),
        ),
        ChecksStrip(state: state, onOpen: _openChecks),
        EditorToolbar(
          formatter: formatter,
          enabled: enabled,
          onAddBlock: () => showInsertBlockSheet(context, content),
          onBlockOptions: () {
            final id = content.focusedBlockId;
            if (content is BlockStructureCommands && id != null) {
              showBlockOptionsSheet(context, content as BlockStructureCommands, id);
            }
          },
        ),
      ],
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.state});

  final ArticleEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final publishing = state.busy == EditorBusy.publishing;
    return FilledButton(
      key: const ValueKey('editor-publish'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
      ),
      onPressed: state.canPublish ? context.read<ArticleEditorCubit>().publish : null,
      child: publishing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textSecondary),
                ),
                const SizedBox(width: ReadInSpace.s2),
                Text(l10n.editorPublishing),
              ],
            )
          : Text(state.isPublished ? l10n.editorUpdate : l10n.editorPublish),
    );
  }
}

enum _MoreAction { revisions, discard, delete }

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.state,
    required this.enabled,
    required this.onRevisions,
    required this.onDiscard,
    required this.onDelete,
  });

  final ArticleEditorState state;
  final bool enabled;
  final VoidCallback onRevisions;
  final VoidCallback onDiscard;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_MoreAction>(
      key: const ValueKey('editor-more'),
      tooltip: l10n.editorMore,
      enabled: enabled,
      onSelected: (action) => switch (action) {
        _MoreAction.revisions => onRevisions(),
        _MoreAction.discard => onDiscard(),
        _MoreAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        if (state.isPublished)
          PopupMenuItem(
            value: _MoreAction.revisions,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text(l10n.editorRevisions),
            ),
          ),
        if (state.isPublished && (state.hasUnpublishedChanges || state.dirty))
          PopupMenuItem(
            value: _MoreAction.discard,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.undo_rounded),
              title: Text(l10n.editorDiscardChanges),
            ),
          ),
        PopupMenuItem(
          value: _MoreAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded, color: context.colors.error),
            title: Text(l10n.editorDelete, style: TextStyle(color: context.colors.error)),
          ),
        ),
      ],
    );
  }
}
