import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../media/presentation/cubit/attachments_cubit.dart';
import '../../../media/presentation/widgets/attachment_bar.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/article_draft.dart';
import '../cubit/composer_cubit.dart';

/// Post composer (F05 minimal + F26 attachments). The full block editor
/// (AppFlowy + RDoc converters) replaces the plain body field later.
class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.read<SettingsCubit>().state.articleLanguage;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ComposerCubit>()..start(language: language)),
        BlocProvider(create: (_) => getIt<AttachmentsCubit>()),
      ],
      child: const EditorView(),
    );
  }
}

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  late final _title = TextEditingController(text: context.read<ComposerCubit>().state.title);
  late final _body = TextEditingController(text: context.read<ComposerCubit>().state.body);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _publish() {
    final attachments = context.read<AttachmentsCubit>().state;
    if (!attachments.canPublish) return;
    context.read<ComposerCubit>().publish(attachments: attachments.requestItems);
  }

  void _onPublished(BuildContext context, String slug) {
    context.read<AttachmentsCubit>().clear();
    context.read<ComposerCubit>().reset();
    _title.clear();
    _body.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.composerPublished)));
    context.push('/a/$slug');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ComposerCubit, ComposerState>(
      listenWhen: (a, b) => a.publishStatus != b.publishStatus && b.publishStatus == PublishStatus.success,
      listener: (context, state) => _onPublished(context, state.publishedSlug!),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.composerTitle), automaticallyImplyLeading: false),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ComposerCubit, ComposerState>(
                builder: (context, state) {
                  final cubit = context.read<ComposerCubit>();
                  final enabled = !state.publishing;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s6),
                    children: [
                      _FieldPicker(state: state),
                      const SizedBox(height: ReadInSpace.s4),
                      Text(l10n.articleLanguage, style: context.textTheme.labelMedium),
                      const SizedBox(height: ReadInSpace.s2),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: 'ar-EG', label: Text(l10n.langToggleArEg), tooltip: l10n.articleLangArEg),
                          ButtonSegment(value: 'en', label: Text(l10n.langToggleEn), tooltip: l10n.articleLangEn),
                        ],
                        selected: {state.language},
                        onSelectionChanged: enabled ? (v) => cubit.setLanguage(v.first) : null,
                      ),
                      const SizedBox(height: ReadInSpace.s5),
                      BidiTextField(
                        controller: _title,
                        enabled: enabled,
                        maxLength: ArticleDraft.maxTitle,
                        // Wraps instead of scrolling, but stays a single paragraph.
                        minLines: 1,
                        maxLines: 3,
                        keyboardType: TextInputType.text,
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))],
                        textInputAction: TextInputAction.next,
                        style: context.textTheme.titleMedium,
                        decoration: InputDecoration(labelText: l10n.composerTitleLabel, hintText: l10n.composerTitleHint),
                        onChanged: cubit.setTitle,
                      ),
                      const SizedBox(height: ReadInSpace.s2),
                      BidiTextField(
                        controller: _body,
                        enabled: enabled,
                        minLines: 6,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: l10n.composerBodyLabel,
                          helperText: l10n.composerBodyHint,
                          alignLabelWithHint: true,
                        ),
                        onChanged: cubit.setBody,
                      ),
                      const SizedBox(height: ReadInSpace.s5),
                      _SourcesSection(state: state),
                      const SizedBox(height: ReadInSpace.s5),
                      Text(l10n.composerAttachments, style: context.textTheme.titleMedium),
                      const SizedBox(height: ReadInSpace.s2),
                      AttachmentBar(enabled: enabled),
                    ],
                  );
                },
              ),
            ),
            _PublishBar(onPublish: _publish),
          ],
        ),
      ),
    );
  }
}

class _FieldPicker extends StatelessWidget {
  const _FieldPicker({required this.state});

  final ComposerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ComposerCubit>();
    if (state.fieldsFailure != null && state.fields.isEmpty) {
      return ErrorView(failure: state.fieldsFailure!, compact: true, onRetry: cubit.loadFields);
    }
    final lang = Localizations.localeOf(context).languageCode;
    return InputDecorator(
      decoration: InputDecoration(labelText: l10n.composerField, contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s2)),
      isEmpty: state.fieldId == null,
      child: state.fieldsLoading && state.fields.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const ValueKey('composer-field'),
                value: state.fieldId,
                isExpanded: true,
                hint: Text(l10n.composerFieldHint),
                items: [
                  for (final f in state.fields) DropdownMenuItem(value: f.id, child: BidiText(f.nameFor(lang), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: state.publishing ? null : cubit.selectField,
              ),
            ),
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.state});

  final ComposerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ComposerCubit>();
    final required = state.requiresSources;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('📚 ${l10n.sources}', style: context.textTheme.titleMedium),
        const SizedBox(height: ReadInSpace.s1),
        Text(
          required ? l10n.composerSourcesRequired : l10n.composerSourcesOptional,
          style: context.textTheme.bodySmall?.copyWith(color: required ? context.colors.textPrimary : null),
        ),
        for (final source in state.sources)
          Padding(
            key: ValueKey('source-${source.key}'),
            padding: const EdgeInsets.only(top: ReadInSpace.s3),
            child: _SourceRow(source: source, enabled: !state.publishing),
          ),
        const SizedBox(height: ReadInSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: state.publishing ? null : cubit.addSource,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.composerAddSource),
          ),
        ),
      ],
    );
  }
}

class _SourceRow extends StatefulWidget {
  const _SourceRow({required this.source, required this.enabled});

  final SourceDraft source;
  final bool enabled;

  @override
  State<_SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends State<_SourceRow> {
  late final _title = TextEditingController(text: widget.source.title);
  late final _url = TextEditingController(text: widget.source.url);

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ComposerCubit>();
    final source = widget.source;
    final urlError = source.url.trim().isNotEmpty && !source.isValidUrl;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s3, ReadInSpace.s3, ReadInSpace.s1, ReadInSpace.s3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                BidiTextField(
                  controller: _title,
                  enabled: widget.enabled,
                  decoration: InputDecoration(labelText: l10n.composerSourceTitle, isDense: true),
                  onChanged: (v) => cubit.updateSource(source.key, title: v),
                ),
                const SizedBox(height: ReadInSpace.s2),
                TextField(
                  controller: _url,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.composerSourceUrl,
                    isDense: true,
                    errorText: urlError ? l10n.composerInvalidUrl : null,
                  ),
                  onChanged: (v) => cubit.updateSource(source.key, url: v),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.composerRemoveSource,
            icon: const Icon(Icons.close_rounded),
            onPressed: widget.enabled ? () => cubit.removeSource(source.key) : null,
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom bar: the first reason publishing is blocked (or the last
/// error) and the Publish button.
class _PublishBar extends StatelessWidget {
  const _PublishBar({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final composer = context.watch<ComposerCubit>().state;
    final attachments = context.watch<AttachmentsCubit>().state;
    final blockers = composer.blockers(hasAttachments: !attachments.isEmpty);
    final attachmentBlockers = attachments.blockers;
    final canPublish = blockers.isEmpty && attachmentBlockers.isEmpty && !composer.publishing;

    final String? hint = switch ((blockers.firstOrNull, attachmentBlockers.firstOrNull)) {
      (ComposerBlocker.field, _) => l10n.composerNeedField,
      (ComposerBlocker.title, _) => l10n.composerNeedTitle,
      (ComposerBlocker.body, _) => l10n.composerNeedBody,
      (ComposerBlocker.sources, _) => l10n.composerNeedSources,
      (ComposerBlocker.incompleteSource, _) => l10n.composerFixSources,
      (null, AttachmentBlocker.busy) => l10n.attachBusy,
      (null, AttachmentBlocker.failed) => l10n.attachFailed,
      (null, AttachmentBlocker.altText) => l10n.attachNeedAlt,
      (null, AttachmentBlocker.documentTitle) => l10n.attachNeedDocTitle,
      (null, null) => null,
    };
    final failure = composer.publishFailure;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s5, ReadInSpace.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null || hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(
                      failure != null ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                      size: 18,
                      color: failure != null ? colors.error : colors.textSecondary,
                    ),
                    const SizedBox(width: ReadInSpace.s2),
                    Expanded(
                      child: Text(
                        failure != null ? publishFailureMessage(l10n, failure) : hint!,
                        style: context.textTheme.bodySmall?.copyWith(color: failure != null ? colors.error : null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FilledButton(
            key: const ValueKey('composer-publish'),
            onPressed: canPublish ? onPublish : null,
            child: composer.publishing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary)),
                      const SizedBox(width: ReadInSpace.s2),
                      Text(l10n.composerPublishing),
                    ],
                  )
                : Text(l10n.composerPublish),
          ),
        ],
      ),
    );
  }
}

/// A validation failure carries per-field codes; show the first one we know.
String publishFailureMessage(AppLocalizations l10n, Failure failure) {
  if (failure.code == FailureCodes.validationFailed) {
    for (final codes in failure.fieldErrors.values) {
      for (final code in codes) {
        final message = localizeErrorCode(l10n, code);
        if (message != l10n.errServer) return message;
      }
    }
  }
  return localizeFailure(l10n, failure);
}
