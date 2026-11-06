import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/bidi_text_field.dart';
import '../../../categories/domain/entities/writer_category.dart';
import '../../../categories/domain/services/category_names.dart';
import '../../../categories/presentation/widgets/category_dialogs.dart';
import '../../../media/domain/usecases/media_usecases.dart';
import '../../../media/presentation/cubit/attachments_cubit.dart';
import '../../../media/presentation/widgets/attachment_bar.dart';
import '../../../tags/domain/services/tag_names.dart';
import '../../domain/entities/editor_entities.dart';
import '../cubit/article_editor_cubit.dart';
import '../cubit/tag_suggestions_cubit.dart';
import 'editor_widgets.dart';

/// Opens the article settings (F05 metadata): language versions, field and topic, the writer's category (F31), tags,
/// cover, sources, version badge, AI-assisted and the attachments.
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
            const SizedBox(height: ReadInSpace.s3),
            _CategorySection(state: state, enabled: enabled),
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
                        title: l10n.removeTranslationTitle(name),
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

/// The optional "القسم" picker (F31): no category, one of the writer's categories (in their order), or "＋ قسم جديد",
/// which asks for a name, creates it and puts the article in it. A choice applies at once (a new article is saved
/// first), so it isn't part of the draft: no publish, no revision.
class _CategorySection extends StatefulWidget {
  const _CategorySection({required this.state, required this.enabled});

  final ArticleEditorState state;
  final bool enabled;

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  static const _newCategory = '\u0000new';

  /// Rebuilds the dropdown after "＋ قسم جديد" was picked and the dialog closed, so it shows the article's category again.
  int _reset = 0;

  Future<void> _changed(String? value) async {
    final cubit = context.read<ArticleEditorCubit>();
    if (value != _newCategory) {
      await cubit.setCategory(value);
      return;
    }
    final l10n = context.l10n;
    final created = await showCategoryNameDialog<WriterCategory>(
      context,
      title: l10n.categoryNew,
      action: l10n.createAction,
      existing: cubit.state.categories,
      submit: cubit.createCategory,
    );
    if (!mounted) return;
    setState(() => _reset++);
    if (created != null) await cubit.setCategory(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final state = widget.state;
    final dir = Directionality.of(context);
    final loading = state.categoriesStatus == EditorLoadStatus.loading;
    final failed = state.categoriesStatus == EditorLoadStatus.failure;
    final full = state.categories.length >= CategoryNames.maxPerWriter;
    // Until the list arrives, a category the article has can't be named: the field waits.
    final value = state.categoryId == null || state.category != null ? state.categoryId : null;
    final enabled = widget.enabled && !loading && !failed && !state.categoryBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          key: ValueKey('settings-category-${state.categories.length}-$value-$_reset'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.editorCategoryLabel,
            prefixIcon: const Icon(Icons.folder_outlined),
            suffixIcon: state.categoryBusy || loading
                ? const Padding(
                    padding: EdgeInsets.all(ReadInSpace.s3),
                    child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            helperText: l10n.editorCategoryHint,
            helperMaxLines: 3,
          ),
          items: [
            DropdownMenuItem<String?>(child: Text(l10n.editorCategoryNone)),
            for (final c in state.categories)
              DropdownMenuItem<String?>(
                value: c.id,
                child: Text(Bidi.isolateOppositeRuns(c.name, dir), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            if (!full)
              DropdownMenuItem<String?>(
                key: const ValueKey('settings-category-new'),
                value: _newCategory,
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 20, color: colors.primary),
                    const SizedBox(width: ReadInSpace.s2),
                    Flexible(
                      child: Text(
                        l10n.categoryNew,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          // The menu shows "＋ قسم جديد" as a choice; the field itself never keeps it.
          selectedItemBuilder: (context) => [
            Text(l10n.editorCategoryNone, maxLines: 1, overflow: TextOverflow.ellipsis),
            for (final c in state.categories)
              Text(Bidi.isolateOppositeRuns(c.name, dir), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (!full) Text(l10n.categoryNew, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          onChanged: enabled ? (v) => _changed(v) : null,
        ),
        if (failed)
          Row(
            children: [
              Expanded(
                child: Text(l10n.editorCategoryLoadFailed, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
              ),
              TextButton(
                key: const ValueKey('settings-category-retry'),
                onPressed: context.read<ArticleEditorCubit>().loadCategories,
                child: Text(l10n.retry),
              ),
            ],
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

/// The tag field (F32, "عرض التاجات في المحرر"): the chosen tags as removable chips, then a field that suggests
/// existing tags as you type (most used first) and offers "Create new tag: {name}" when none is the typed one. Enter, a
/// comma or "Add" adds what was typed; a picked suggestion is added as it is. New names follow the tag rules, with
/// inline messages; a repeat is ignored. At 5 tags the field is disabled with a hint.
class _TagsSectionState extends State<_TagsSection> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  /// The last attempt to add what was typed, while it still describes the field (cleared as soon as the text changes).
  TagAddResult? _result;

  static const _shownSuggestions = 6;
  static final _commas = RegExp('[,،]');

  @override
  void initState() {
    super.initState();
    // The suggestions show while the field has the focus.
    _focus.addListener(() {
      if (!mounted) return;
      if (_focus.hasFocus) context.read<TagSuggestionsCubit>().search(_input.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<ArticleTag> get _suggestions => context.read<TagSuggestionsCubit>().state;

  /// Adds [text] as typed: an existing tag spelled another way (`ai` for `AI`) becomes that tag. True when added.
  bool _submit(String text) {
    final name = TagNames.clean(text);
    if (name.isEmpty) return false;
    final existing = _suggestions.where((s) => TagNames.same(s.name, name)).firstOrNull;
    return _add(existing?.name ?? name, existing: existing != null);
  }

  bool _add(String name, {required bool existing}) {
    final result = context.read<ArticleEditorCubit>().addTag(name, existing: existing);
    final added = result == TagAddResult.added;
    setState(() => _result = added ? null : result);
    if (added) {
      _input.clear();
      context.read<TagSuggestionsCubit>().search('');
    }
    return added;
  }

  void _changed(String text) {
    if (_commas.hasMatch(text)) {
      // A comma (or the Arabic "،") ends a tag; pasted "a, b, c" adds them all. A repeat is skipped like an empty part;
      // the first name that can't be added stays in the field with its message.
      final parts = text.split(_commas);
      final rest = parts.removeLast();
      for (final part in parts) {
        final name = TagNames.clean(part);
        if (name.isEmpty || TagNames.containsTag(context.read<ArticleEditorCubit>().state.document.tags, name)) continue;
        if (!_submit(part)) {
          _setText(part.trim());
          return;
        }
      }
      if (_result != null) setState(() => _result = null);
      _setText(rest);
      context.read<TagSuggestionsCubit>().search(rest);
      return;
    }
    if (_result != null) setState(() => _result = null);
    context.read<TagSuggestionsCubit>().search(text);
  }

  void _setText(String text) => _input.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

  String? _message(AppLocalizations l10n, TagAddResult? result) => switch (result) {
        TagAddResult.duplicate => l10n.tagAlreadyAdded,
        TagAddResult.full => l10n.tagsFull,
        TagAddResult.tooShort => l10n.tagTooShort,
        TagAddResult.tooLong => l10n.tagTooLong,
        TagAddResult.invalidCharacters => l10n.tagInvalidCharacters,
        TagAddResult.noLetter => l10n.tagNoLetter,
        TagAddResult.added || TagAddResult.empty || null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<ArticleEditorCubit>();
    final state = widget.state;
    final tags = state.document.tags;
    final full = tags.length >= DraftLimits.maxTags;
    final enabled = widget.enabled && !full;

    final typed = TagNames.clean(_input.text);
    final all = context.watch<TagSuggestionsCubit>().state;
    final exact = typed.isNotEmpty && all.any((s) => TagNames.same(s.name, typed));
    final suggestions = all.where((s) => !TagNames.containsTag(tags, s.name)).take(_shownSuggestions).toList();
    // While typing, the rules a new name breaks show at once (too short waits for Enter: it may still grow).
    final liveError = typed.isEmpty || exact
        ? null
        : switch (TagNames.validate(typed)) {
            TagNameError.tooLong => TagAddResult.tooLong,
            TagNameError.invalidCharacters => TagAddResult.invalidCharacters,
            _ => null,
          };
    final canCreate = typed.isNotEmpty && !exact && TagNames.validate(typed) == null && !TagNames.containsTag(tags, typed);
    final showPanel = enabled && _focus.hasFocus && (suggestions.isNotEmpty || canCreate);

    // Why publishing or saving refused tags: hidden ones, the daily limit (per tag), and the API's validation.
    final tagProblems = [for (final tag in tags) ?state.tagProblemOf(tag)];
    final saveErrors = state.saveFailure?.fieldErrors ?? const <String, List<String>>{};
    final saveMessages = {
      for (final MapEntry(:key, :value) in saveErrors.entries)
        if (key == 'document.tags' || key.startsWith('document.tags['))
          for (final code in value) localizeErrorCode(l10n, code),
    };

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
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s2,
            children: [
              for (final tag in tags)
                _TagInputChip(
                  key: ValueKey('tag-$tag'),
                  name: tag,
                  problem: state.tagProblemOf(tag) != null,
                  onDeleted: widget.enabled ? () => cubit.removeTag(tag) : null,
                ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s2),
        ],
        for (final message in [for (final p in tagProblems) problemMessage(l10n, p), ...saveMessages])
          Padding(
            padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
            child: Text(message, style: context.textTheme.bodySmall?.copyWith(color: colors.error)),
          ),
        BidiTextField(
          key: const ValueKey('settings-tag-input'),
          controller: _input,
          focusNode: _focus,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: l10n.tagsHint,
            prefixIcon: const Icon(Icons.tag_rounded),
            helperText: full ? l10n.tagsFull : null,
            helperMaxLines: 3,
            errorText: full ? null : _message(l10n, _result ?? liveError),
            errorMaxLines: 3,
          ),
          onEditingComplete: () => _submit(_input.text),
          onChanged: _changed,
        ),
        if (showPanel)
          _TagSuggestionsPanel(
            suggestions: suggestions,
            create: canCreate ? typed : null,
            onPick: (tag) => _add(tag.name, existing: true),
            onCreate: (name) => _add(name, existing: false),
          ),
        if (!full)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const ValueKey('settings-tag-add'),
              onPressed: enabled ? () => _submit(_input.text) : null,
              child: Text(l10n.tagsAdd),
            ),
          ),
      ],
    );
  }
}

/// A chosen tag: `#name` with a remove button; in the error colors while the API refuses it (`tag.hidden`,
/// `tag.limit`).
class _TagInputChip extends StatelessWidget {
  const _TagInputChip({super.key, required this.name, required this.problem, this.onDeleted});

  final String name;
  final bool problem;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InputChip(
      label: Text(Bidi.isolateOppositeRuns('#$name', Directionality.of(context))),
      avatar: problem ? Icon(Icons.error_outline_rounded, size: 18, color: colors.error) : null,
      side: problem ? BorderSide(color: colors.error) : null,
      labelStyle: problem ? TextStyle(color: colors.error) : null,
      deleteButtonTooltipMessage: context.l10n.removeTag(name),
      onDeleted: onDeleted,
    );
  }
}

/// The suggestions under the tag field: existing tags with their article counts (the API sends the most used first),
/// then "Create new tag: {name}" when none is the typed name.
class _TagSuggestionsPanel extends StatelessWidget {
  const _TagSuggestionsPanel({required this.suggestions, required this.create, required this.onPick, required this.onCreate});

  final List<ArticleTag> suggestions;

  /// The cleaned typed name, when it can become a new tag.
  final String? create;
  final ValueChanged<ArticleTag> onPick;
  final ValueChanged<String> onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final dir = Directionality.of(context);
    final create = this.create;
    return Container(
      key: const ValueKey('tag-suggestions'),
      margin: const EdgeInsets.only(top: ReadInSpace.s2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          label: l10n.tagSuggestionsLabel,
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in suggestions)
                ListTile(
                  key: ValueKey('tag-suggestion-${s.slug}'),
                  dense: true,
                  minTileHeight: 44,
                  leading: Icon(Icons.tag_rounded, size: 20, color: colors.textSecondary),
                  title: Text(Bidi.isolateOppositeRuns(s.name, dir), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(l10n.tagPageArticleCount(s.articleCount), style: context.textTheme.bodySmall),
                  onTap: () => onPick(s),
                ),
              if (create != null)
                ListTile(
                  key: const ValueKey('tag-create'),
                  dense: true,
                  minTileHeight: 44,
                  leading: Icon(Icons.add_rounded, size: 20, color: colors.primary),
                  title: Text(
                    l10n.tagCreate('${Bidi.fsi}$create${Bidi.pdi}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => onCreate(create),
                ),
            ],
          ),
        ),
      ),
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
