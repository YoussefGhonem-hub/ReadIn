import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../../media/presentation/cubit/attachments_cubit.dart';
import '../../../media/presentation/widgets/attachment_bar.dart';
import '../../domain/entities/editor_entities.dart';
import '../cubit/article_editor_cubit.dart';
import '../cubit/tag_suggestions_cubit.dart';
import 'editor_widgets.dart';

/// Opens the article settings (F05 metadata): language versions, field and topic, tags, cover, sources, version
/// badge, AI-assisted and the attachments.
Future<void> showArticleSettingsSheet(BuildContext context) {
  final editor = context.read<ArticleEditorCubit>();
  final attachments = context.read<AttachmentsCubit>();
  final tags = context.read<TagSuggestionsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheet) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: editor),
        BlocProvider.value(value: attachments),
        BlocProvider.value(value: tags),
      ],
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scroll) => ArticleSettingsPanel(scrollController: scroll),
      ),
    ),
  );
}

/// The settings sheet's content (also used directly in tests).
class ArticleSettingsPanel extends StatelessWidget {
  const ArticleSettingsPanel({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ArticleEditorCubit, ArticleEditorState>(
      builder: (context, state) {
        final enabled = state.busy == EditorBusy.none;
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s8),
          children: [
            Text(l10n.editorSettings, style: context.textTheme.titleLarge),
            const SizedBox(height: ReadInSpace.s4),
            _LanguagesSection(state: state, enabled: enabled),
            const _SectionGap(),
            _FieldSection(state: state, enabled: enabled),
            const _SectionGap(),
            _TagsSection(state: state, enabled: enabled),
            const _SectionGap(),
            _CoverSection(state: state, enabled: enabled),
            const _SectionGap(),
            _SourcesSection(state: state, enabled: enabled),
            const _SectionGap(),
            _BadgeSection(state: state, enabled: enabled),
            const _SectionGap(),
            Text(l10n.composerAttachments, style: context.textTheme.titleMedium),
            const SizedBox(height: ReadInSpace.s2),
            AttachmentBar(enabled: enabled),
          ],
        );
      },
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s4),
        child: Divider(height: 1, color: context.colors.border),
      );
}

class _LanguagesSection extends StatelessWidget {
  const _LanguagesSection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ArticleEditorCubit>();
    final document = state.document;
    final other = ArticleLanguages.other(document.sourceLanguage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.languageVersions, style: context.textTheme.titleMedium),
        const SizedBox(height: ReadInSpace.s2),
        SegmentedButton<String>(
          key: const ValueKey('settings-source-language'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ArticleLanguages.ar, label: Text(l10n.articleVersionArabic)),
            ButtonSegment(value: ArticleLanguages.en, label: Text(l10n.articleVersionEnglish)),
          ],
          selected: {document.sourceLanguage},
          onSelectionChanged: enabled && !document.hasTranslation ? (v) => cubit.setSourceLanguage(v.first) : null,
        ),
        const SizedBox(height: ReadInSpace.s1),
        Text(l10n.sourceLanguageHint, style: context.textTheme.bodySmall),
        const SizedBox(height: ReadInSpace.s2),
        if (document.hasTranslation)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('settings-remove-translation'),
              style: TextButton.styleFrom(foregroundColor: context.colors.error),
              onPressed: enabled
                  ? () async {
                      final name = articleLanguageName(l10n, other);
                      final ok = await confirmDialog(
                        context,
                        title: l10n.removeTranslation(name),
                        body: l10n.removeTranslationBody,
                        confirm: l10n.removeAction,
                        destructive: true,
                      );
                      if (ok) cubit.removeTranslation(other);
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: Text(l10n.removeTranslation(articleLanguageName(l10n, other))),
            ),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('settings-add-translation'),
              onPressed: enabled ? cubit.addTranslation : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addTranslation(articleLanguageName(l10n, other))),
            ),
          ),
      ],
    );
  }
}

class _FieldSection extends StatelessWidget {
  const _FieldSection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ArticleEditorCubit>();
    final lang = Localizations.localeOf(context).languageCode;
    final fieldId = state.fields.any((f) => f.id == state.document.fieldId) ? state.document.fieldId : null;
    final topicId = state.topics.any((t) => t.id == state.document.topicId) ? state.document.topicId : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('settings-field-${state.fields.length}-$fieldId'),
          initialValue: fieldId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.composerField, hintText: l10n.composerFieldHint),
          items: [
            for (final f in state.fields)
              DropdownMenuItem(value: f.id, child: BidiText(f.nameFor(lang), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: enabled ? cubit.selectField : null,
        ),
        const SizedBox(height: ReadInSpace.s3),
        DropdownButtonFormField<String?>(
          key: ValueKey('settings-topic-$fieldId'),
          initialValue: topicId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.topicLabel),
          items: [
            DropdownMenuItem<String?>(child: Text(l10n.topicNone)),
            for (final t in state.topics)
              DropdownMenuItem(value: t.id, child: BidiText(t.nameFor(lang), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: enabled && state.topics.isNotEmpty ? cubit.selectTopic : null,
        ),
      ],
    );
  }
}

class _TagsSection extends StatefulWidget {
  const _TagsSection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  State<_TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<_TagsSection> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) context.read<TagSuggestionsCubit>().search(_input.text);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String tag) {
    if (context.read<ArticleEditorCubit>().addTag(tag)) {
      _input.clear();
      context.read<TagSuggestionsCubit>().search('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ArticleEditorCubit>();
    final tags = widget.state.document.tags;
    final full = tags.length >= DraftLimits.maxTags;
    final suggestions = context.watch<TagSuggestionsCubit>().state.where((t) => !tags.any((x) => x.toLowerCase() == t.name.toLowerCase()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.tagsLabel, style: context.textTheme.titleMedium)),
            Text(l10n.tagsLimit(tags.length), style: context.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: ReadInSpace.s2),
        if (tags.isNotEmpty)
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s2,
            children: [
              for (final tag in tags)
                InputChip(
                  key: ValueKey('tag-$tag'),
                  label: BidiText(tag),
                  deleteButtonTooltipMessage: l10n.removeTag(tag),
                  onDeleted: widget.enabled ? () => cubit.removeTag(tag) : null,
                ),
            ],
          ),
        if (!full) ...[
          const SizedBox(height: ReadInSpace.s2),
          BidiTextField(
            key: const ValueKey('settings-tag-input'),
            controller: _input,
            focusNode: _focus,
            enabled: widget.enabled,
            maxLength: DraftLimits.maxTagLength,
            counterWithin: 10,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l10n.tagsHint, prefixIcon: const Icon(Icons.sell_outlined)),
            onSubmitted: _add,
            onChanged: (v) {
              if (v.endsWith(',')) return _add(v.substring(0, v.length - 1));
              context.read<TagSuggestionsCubit>().search(v);
            },
          ),
          if (suggestions.isNotEmpty && _focus.hasFocus)
            Wrap(
              spacing: ReadInSpace.s2,
              runSpacing: ReadInSpace.s1,
              children: [
                for (final s in suggestions.take(8))
                  ActionChip(key: ValueKey('tag-suggestion-${s.slug}'), label: BidiText(s.name), onPressed: () => _add(s.name)),
              ],
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const ValueKey('settings-tag-add'),
              onPressed: widget.enabled ? () => _add(_input.text) : null,
              child: Text(l10n.save),
            ),
          ),
        ],
      ],
    );
  }
}

class _CoverSection extends StatefulWidget {
  const _CoverSection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  State<_CoverSection> createState() => _CoverSectionState();
}

class _CoverSectionState extends State<_CoverSection> {
  bool _uploading = false;

  Future<void> _pick() async {
    final cubit = context.read<ArticleEditorCubit>();
    final files = await getIt<PickImages>()(limit: 1);
    if (files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    await cubit.uploadCover(files.first);
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<ArticleEditorCubit>();
    final cover = widget.state.document.coverUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.coverLabel, style: context.textTheme.titleMedium),
        const SizedBox(height: ReadInSpace.s1),
        Text(l10n.coverHint, style: context.textTheme.bodySmall),
        const SizedBox(height: ReadInSpace.s2),
        if (cover != null && cover.isNotEmpty) ...[
          AppNetworkImage(url: cover, aspectRatio: 16 / 9, borderRadius: BorderRadius.circular(ReadInRadius.md), errorLabel: l10n.imageUnavailable),
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.enabled && !_uploading ? _pick : null,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l10n.coverChange),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: colors.error),
                onPressed: widget.enabled && !_uploading ? () => cubit.setCover(null) : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.coverRemove),
              ),
            ],
          ),
        ] else
          OutlinedButton.icon(
            key: const ValueKey('settings-cover-add'),
            onPressed: widget.enabled && !_uploading ? _pick : null,
            icon: _uploading
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_uploading ? l10n.uploadingLabel : l10n.coverAdd),
          ),
      ],
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ArticleEditorCubit>();
    final required = state.field?.requiresSources ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('📚 ${l10n.sources}', style: context.textTheme.titleMedium?.withEmoji()),
        const SizedBox(height: ReadInSpace.s1),
        Text(
          required ? l10n.composerSourcesRequired : l10n.composerSourcesOptional,
          style: context.textTheme.bodySmall?.copyWith(color: required ? context.colors.textPrimary : null),
        ),
        for (final source in state.sources)
          Padding(
            key: ValueKey('source-${source.key}'),
            padding: const EdgeInsets.only(top: ReadInSpace.s3),
            child: _SourceRow(source: source, enabled: enabled),
          ),
        const SizedBox(height: ReadInSpace.s2),
        if (state.sources.length < DraftLimits.maxSources)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('settings-add-source'),
              onPressed: enabled ? cubit.addSource : null,
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
    final cubit = context.read<ArticleEditorCubit>();
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
                  maxLength: DraftLimits.maxSourceTitle,
                  counterWithin: 20,
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

class _BadgeSection extends StatefulWidget {
  const _BadgeSection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  State<_BadgeSection> createState() => _BadgeSectionState();
}

class _BadgeSectionState extends State<_BadgeSection> {
  late final _badge = TextEditingController(text: widget.state.document.versionBadge ?? '');

  @override
  void dispose() {
    _badge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ArticleEditorCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('settings-version-badge'),
          controller: _badge,
          enabled: widget.enabled,
          maxLength: DraftLimits.maxVersionBadge,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: l10n.versionBadgeLabel, hintText: l10n.versionBadgeHint, counterText: ''),
          onChanged: cubit.setVersionBadge,
        ),
        const SizedBox(height: ReadInSpace.s2),
        SwitchListTile.adaptive(
          key: const ValueKey('settings-ai-assisted'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.aiAssistedSwitch),
          subtitle: Text(l10n.aiAssistedSwitchHint),
          value: widget.state.document.isAiAssisted,
          onChanged: widget.enabled ? cubit.setAiAssisted : null,
        ),
      ],
    );
  }
}
