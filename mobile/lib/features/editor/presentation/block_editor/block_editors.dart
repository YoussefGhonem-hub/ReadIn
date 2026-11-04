import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/inline_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/editor_entities.dart';
import 'block_editor_surface.dart';
import 'block_kinds_ui.dart';
import 'inline_text_controller.dart';

/// The editor of a structured block in its sheet: steps, code, code tabs, table, image or embed.
class StructuredBlockEditor extends StatelessWidget {
  const StructuredBlockEditor({super.key, required this.block});

  final RBlock block;

  @override
  Widget build(BuildContext context) => switch (block) {
        final RSteps b => StepsBlockEditor(block: b),
        final RCode b => CodeBlockEditor(block: b),
        final RCodeTabs b => CodeTabsBlockEditor(block: b),
        final RTable b => TableBlockEditor(block: b),
        final RImage b => ImageBlockEditor(block: b),
        final REmbed b => EmbedBlockEditor(block: b),
        _ => const SizedBox.shrink(),
      };
}

TextDirection _dirOf(BuildContext context, RBlock block) =>
    BlockDirection.resolve(block, fallback: BlockEditorScope.of(context).editorContext.fallbackDirection);

// ── Fields ─────────────────────────────────────────────────

/// Inline text with no box: the theme's outlined borders and fill are switched off (InputDecoration.collapsed
/// keeps the theme's enabled/focused borders).
InputDecoration bareDecoration({String? hintText, TextStyle? hintStyle}) => InputDecoration(
      isCollapsed: true,
      filled: false,
      contentPadding: EdgeInsets.zero,
      hintText: hintText,
      hintStyle: hintStyle,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );

/// A borderless multi-line field over RDoc inline content ([InlineTextController]). The toolbar formats the one
/// in focus.
class InlineField extends StatefulWidget {
  const InlineField({
    super.key,
    required this.blockId,
    required this.nodes,
    required this.onChanged,
    required this.style,
    required this.direction,
    this.onSplit,
    this.hint,
    this.primary = false,
    this.focusNode,
    this.fieldKey,
  });

  final String blockId;
  final List<RInline> nodes;
  final ValueChanged<List<RInline>> onChanged;
  final InlineSplitCallback? onSplit;
  final TextStyle style;
  final TextDirection direction;
  final String? hint;

  /// The block's first field: focused when the block is revealed.
  final bool primary;
  final FocusNode? focusNode;
  final Key? fieldKey;

  @override
  State<InlineField> createState() => _InlineFieldState();
}

class _InlineFieldState extends State<InlineField> {
  late final InlineTextController _controller = InlineTextController(
    nodes: widget.nodes,
    onSplit: widget.onSplit,
    onNodesChanged: (nodes) => widget.onChanged(nodes),
  );
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  BlockEditorScope? _scope;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = BlockEditorScope.of(context);
    if (widget.primary) _scope!.registry.register(widget.blockId, _focus);
  }

  @override
  void didUpdateWidget(InlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.onSplit = widget.onSplit;
    _controller.onNodesChanged = widget.onChanged;
    _controller.nodes = widget.nodes;
  }

  void _onFocus() {
    final scope = _scope;
    if (scope == null) return;
    if (_focus.hasFocus) {
      scope.controller.focusedBlockId = widget.blockId;
      scope.editorContext.focus.activate(widget.blockId, _controller);
    } else {
      scope.editorContext.focus.deactivate(_controller);
    }
  }

  @override
  void dispose() {
    if (widget.primary) _scope?.registry.unregister(widget.blockId, _focus);
    _focus.removeListener(_onFocus);
    _scope?.editorContext.focus.release(_controller);
    if (widget.focusNode == null) _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        key: widget.fieldKey,
        controller: _controller,
        focusNode: _focus,
        enabled: BlockEditorScope.of(context).editorContext.enabled,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        textDirection: widget.direction,
        style: widget.style,
        decoration: bareDecoration(
          hintText: widget.hint,
          hintStyle: widget.style.copyWith(color: context.colors.textSecondary),
        ),
      );
}

/// A plain text attribute (step title, cite, callout title, code, alt text…). Follows its content's direction
/// unless [direction] is given.
class PlainField extends StatefulWidget {
  const PlainField({
    super.key,
    required this.value,
    required this.onChanged,
    this.style,
    this.direction,
    this.hint,
    this.label,
    this.helper,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.decorated = false,
    this.keyboardType,
    this.primaryFor,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final TextStyle? style;
  final TextDirection? direction;
  final String? hint;
  final String? label;
  final String? helper;
  final String? errorText;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;

  /// An outlined field with a label, instead of inline text.
  final bool decorated;
  final TextInputType? keyboardType;

  /// Registers as this block's first field.
  final String? primaryFor;

  @override
  State<PlainField> createState() => _PlainFieldState();
}

class _PlainFieldState extends State<PlainField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  BlockEditorScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = BlockEditorScope.of(context);
    if (widget.primaryFor != null) _scope!.registry.register(widget.primaryFor!, _focus);
  }

  @override
  void didUpdateWidget(PlainField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !_focus.hasFocus) _controller.text = widget.value;
  }

  @override
  void dispose() {
    if (widget.primaryFor != null) _scope?.registry.unregister(widget.primaryFor!, _focus);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? context.textTheme.bodyMedium!;
    final direction = widget.direction ?? Bidi.detect(_controller.text) ?? Directionality.of(context);
    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: BlockEditorScope.of(context).editorContext.enabled,
      maxLength: widget.maxLength,
      buildCounter: widget.maxLength == null
          ? null
          : (context, {required currentLength, required isFocused, required maxLength}) =>
              maxLength != null && currentLength > maxLength - 50 ? Text('$currentLength/$maxLength', style: context.textTheme.bodySmall) : null,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType ?? (widget.maxLines == 1 ? TextInputType.text : TextInputType.multiline),
      textDirection: direction,
      style: style,
      decoration: widget.decorated
          ? InputDecoration(labelText: widget.label, hintText: widget.hint, helperText: widget.helper, errorText: widget.errorText, isDense: true)
          : bareDecoration(hintText: widget.hint, hintStyle: style.copyWith(color: context.colors.textSecondary)),
      onChanged: (v) {
        setState(() {}); // direction follows the text
        widget.onChanged(v);
      },
    );
  }
}

// ── Steps ──────────────────────────────────────────────────

class StepsBlockEditor extends StatelessWidget {
  const StepsBlockEditor({super.key, required this.block});

  final RSteps block;

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final dir = _dirOf(context, block);
    final style = rdocBodyStyle(context, dir);
    void set(List<RStep> items) => scope.controller.replace(RSteps(block.id, dir: block.dir, items: items));
    return Directionality(
      textDirection: dir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < block.items.length; i++)
            Padding(
              key: ValueKey('${block.id}-step-$i'),
              padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: context.textTheme.labelLarge?.copyWith(color: colors.onPrimaryContainer)),
                  ),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlainField(
                          value: block.items[i].title,
                          hint: l10n.stepTitleHint,
                          maxLength: DraftLimits.maxPlainText,
                          direction: dir,
                          primaryFor: i == 0 ? block.id : null,
                          style: style.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                          onChanged: (v) => set([...block.items]..[i] = RStep(title: v, content: block.items[i].content)),
                        ),
                        InlineField(
                          blockId: block.id,
                          nodes: block.items[i].content,
                          style: style,
                          direction: dir,
                          hint: l10n.stepContentHint,
                          onChanged: (nodes) => set([...block.items]..[i] = RStep(title: block.items[i].title, content: nodes)),
                        ),
                      ],
                    ),
                  ),
                  if (block.items.length > 1)
                    IconButton(
                      tooltip: l10n.removeStep,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: () => set([...block.items]..removeAt(i)),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
          if (block.items.length < 50)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => set([...block.items, const RStep(title: '', content: [])]),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addStep),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Code ───────────────────────────────────────────────────

/// Code is always LTR, set in JetBrains Mono on the code background (SPEC §14.2 rule 3, §15.2).
class _CodeSurface extends StatelessWidget {
  const _CodeSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(ReadInSpace.s3),
        decoration: BoxDecoration(
          color: colors.codeBg,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: Border.all(color: colors.codeBorder),
        ),
        child: child,
      ),
    );
  }
}

class _LangPicker extends StatelessWidget {
  const _LangPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = codeTextStyle(size: 13, color: colors.codeText);
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        dropdownColor: colors.codeBg,
        iconEnabledColor: colors.codeText,
        style: style,
        items: [
          for (final lang in {...codeLanguages, value}) DropdownMenuItem(value: lang, child: Text(lang, style: style)),
        ],
        onChanged: BlockEditorScope.of(context).editorContext.enabled ? (v) => onChanged(v ?? value) : null,
      ),
    );
  }
}

class CodeBlockEditor extends StatelessWidget {
  const CodeBlockEditor({super.key, required this.block});

  final RCode block;

  RCode _with({String? lang, String? code, String? Function()? filename}) => RCode(
        block.id,
        lang: lang ?? block.lang,
        code: code ?? block.code,
        filename: filename != null ? filename() : block.filename,
        highlightLines: block.highlightLines,
        compile: block.compile,
      );

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final code = codeTextStyle(color: colors.codeText);
    return _CodeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LangPicker(value: block.lang, onChanged: (v) => scope.controller.replace(_with(lang: v))),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(
                child: PlainField(
                  value: block.filename ?? '',
                  hint: l10n.codeFilenameHint,
                  maxLength: 200,
                  direction: TextDirection.ltr,
                  style: codeTextStyle(size: 13, color: colors.codeText),
                  onChanged: (v) => scope.controller.replace(_with(filename: () => v.isEmpty ? null : v)),
                ),
              ),
            ],
          ),
          Divider(color: colors.codeBorder, height: ReadInSpace.s4),
          PlainField(
            value: block.code,
            hint: l10n.codeHint,
            primaryFor: block.id,
            direction: TextDirection.ltr,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            style: code,
            onChanged: (v) => scope.controller.replace(_with(code: v)),
          ),
        ],
      ),
    );
  }
}

class CodeTabsBlockEditor extends StatefulWidget {
  const CodeTabsBlockEditor({super.key, required this.block});

  final RCodeTabs block;

  @override
  State<CodeTabsBlockEditor> createState() => _CodeTabsBlockEditorState();
}

class _CodeTabsBlockEditorState extends State<CodeTabsBlockEditor> {
  int _selected = 0;

  void _set(List<RCodeTab> tabs) => BlockEditorScope.of(context).controller.replace(RCodeTabs(widget.block.id, tabs: tabs));

  RCodeTab _tab(RCodeTab t, {String? label, String? lang, String? code, String? Function()? filename}) => RCodeTab(
        label: label ?? t.label,
        lang: lang ?? t.lang,
        code: code ?? t.code,
        filename: filename != null ? filename() : t.filename,
        compile: t.compile,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final tabs = widget.block.tabs;
    if (tabs.isEmpty) return const SizedBox.shrink();
    final index = _selected.clamp(0, tabs.length - 1);
    final tab = tabs[index];
    final small = codeTextStyle(size: 13, color: colors.codeText);
    return _CodeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s1),
                    child: ChoiceChip(
                      key: ValueKey('${widget.block.id}-tab-$i'),
                      label: Text(tabs[i].label.isEmpty ? tabs[i].lang : tabs[i].label),
                      selected: i == index,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _selected = i),
                    ),
                  ),
                if (tabs.length < 8)
                  IconButton(
                    tooltip: l10n.addCodeTab,
                    color: colors.codeText,
                    iconSize: 18,
                    onPressed: () {
                      _set([...tabs, const RCodeTab(label: 'Dart', lang: 'dart', code: '')]);
                      setState(() => _selected = tabs.length);
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ReadInSpace.s2),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: PlainField(
                  key: ValueKey('${widget.block.id}-label-$index'),
                  value: tab.label,
                  hint: l10n.codeTabLabelHint,
                  maxLength: 40,
                  direction: TextDirection.ltr,
                  style: small,
                  onChanged: (v) => _set([...tabs]..[index] = _tab(tab, label: v)),
                ),
              ),
              const SizedBox(width: ReadInSpace.s2),
              _LangPicker(value: tab.lang, onChanged: (v) => _set([...tabs]..[index] = _tab(tab, lang: v))),
              const Spacer(),
              if (tabs.length > 1)
                IconButton(
                  tooltip: l10n.removeCodeTab,
                  color: colors.codeText,
                  iconSize: 18,
                  onPressed: () {
                    _set([...tabs]..removeAt(index));
                    setState(() => _selected = (index - 1).clamp(0, tabs.length - 2));
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          Divider(color: colors.codeBorder, height: ReadInSpace.s4),
          PlainField(
            key: ValueKey('${widget.block.id}-code-$index'),
            value: tab.code,
            hint: l10n.codeHint,
            primaryFor: widget.block.id,
            direction: TextDirection.ltr,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            style: codeTextStyle(color: colors.codeText),
            onChanged: (v) => _set([...tabs]..[index] = _tab(tab, code: v)),
          ),
        ],
      ),
    );
  }
}

// ── Table ──────────────────────────────────────────────────

class TableBlockEditor extends StatelessWidget {
  const TableBlockEditor({super.key, required this.block});

  final RTable block;

  static const _maxColumns = 12;
  static const _maxRows = 200;

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final dir = _dirOf(context, block);
    final style = rdocBodyStyle(context, dir, factor: 0.85).copyWith(height: 1.5);
    final columns = block.header.length;
    void set({List<List<RInline>>? header, List<List<List<RInline>>>? rows}) =>
        scope.controller.replace(RTable(block.id, dir: block.dir, header: header ?? block.header, rows: rows ?? block.rows));

    Widget cell(List<RInline> nodes, ValueChanged<List<RInline>> onChanged, {required bool head, bool primary = false}) => Padding(
          padding: const EdgeInsets.all(ReadInSpace.s2),
          child: InlineField(
            blockId: block.id,
            primary: primary,
            nodes: nodes,
            style: head ? style.copyWith(fontWeight: FontWeight.w700) : style,
            direction: dir,
            onChanged: onChanged,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: dir,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(150),
              border: TableBorder.all(color: colors.border, borderRadius: BorderRadius.circular(ReadInRadius.sm)),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.surfaceVariant),
                  children: [
                    for (var c = 0; c < columns; c++)
                      cell(block.header[c], (n) => set(header: [...block.header]..[c] = n), head: true, primary: c == 0),
                  ],
                ),
                for (var r = 0; r < block.rows.length; r++)
                  TableRow(children: [
                    for (var c = 0; c < columns; c++)
                      cell(
                        c < block.rows[r].length ? block.rows[r][c] : const [],
                        (n) {
                          final row = [...block.rows[r], for (var k = block.rows[r].length; k < columns; k++) <RInline>[]];
                          row[c] = n;
                          set(rows: [...block.rows]..[r] = row);
                        },
                        head: false,
                      ),
                  ]),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: ReadInSpace.s1,
          children: [
            if (block.rows.length < _maxRows)
              TextButton.icon(
                onPressed: () => set(rows: [...block.rows, [for (var c = 0; c < columns; c++) <RInline>[]]]),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.tableAddRow),
              ),
            if (columns < _maxColumns)
              TextButton.icon(
                onPressed: () => set(
                  header: [...block.header, const []],
                  rows: [for (final r in block.rows) [...r, const []]],
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.tableAddColumn),
              ),
            if (block.rows.isNotEmpty)
              TextButton(onPressed: () => set(rows: [...block.rows]..removeLast()), child: Text(l10n.tableRemoveRow)),
            if (columns > 1)
              TextButton(
                onPressed: () => set(
                  header: [...block.header]..removeLast(),
                  rows: [for (final r in block.rows) r.length >= columns ? ([...r]..removeLast()) : r],
                ),
                child: Text(l10n.tableRemoveColumn),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Media and embeds ───────────────────────────────────────

class ImageBlockEditor extends StatefulWidget {
  const ImageBlockEditor({super.key, required this.block});

  final RImage block;

  @override
  State<ImageBlockEditor> createState() => _ImageBlockEditorState();
}

class _ImageBlockEditorState extends State<ImageBlockEditor> {
  bool _uploading = false;

  RImage _with({String? src, String? alt, String? Function()? caption, int? Function()? width, int? Function()? height}) => RImage(
        widget.block.id,
        src: src ?? widget.block.src,
        alt: alt ?? widget.block.alt,
        darkSrc: widget.block.darkSrc,
        caption: caption != null ? caption() : widget.block.caption,
        width: width != null ? width() : widget.block.width,
        height: height != null ? height() : widget.block.height,
      );

  Future<void> _pick() async {
    final scope = BlockEditorScope.of(context);
    final file = await scope.editorContext.pickImage();
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    final asset = await scope.editorContext.uploadImage(file);
    if (!mounted) return;
    setState(() => _uploading = false);
    final url = asset == null || asset.variants.isEmpty ? null : asset.variants.last.url;
    if (url == null) return;
    scope.controller.replace(_with(src: url, width: () => asset!.width, height: () => asset!.height));
  }

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final block = widget.block;
    final hasImage = block.src.isNotEmpty;
    final missingAlt = hasImage && block.alt.trim().isEmpty;
    final ratio = block.width != null && block.height != null && block.height! > 0 ? block.width! / block.height! : 16 / 9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          AppNetworkImage(
            url: block.src,
            semanticLabel: block.alt.isEmpty ? null : block.alt,
            aspectRatio: ratio,
            borderRadius: BorderRadius.circular(ReadInRadius.md),
            errorLabel: l10n.imageUnavailable,
          )
        else
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(ReadInRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: _uploading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(height: ReadInSpace.s2),
                          Text(l10n.uploadingLabel, style: context.textTheme.bodySmall),
                        ],
                      )
                    : FilledButton.tonalIcon(
                        key: ValueKey('image-choose-${block.id}'),
                        onPressed: scope.editorContext.enabled ? _pick : null,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(l10n.imageChoose),
                      ),
              ),
            ),
          ),
        if (hasImage) ...[
          const SizedBox(height: ReadInSpace.s3),
          PlainField(
            value: block.alt,
            decorated: true,
            primaryFor: block.id,
            label: l10n.imageAltLabel,
            helper: missingAlt ? null : l10n.imageAltHelp,
            errorText: missingAlt ? l10n.imageAltHelp : null,
            maxLength: DraftLimits.maxImageAlt,
            onChanged: (v) => scope.controller.replace(_with(alt: v)),
          ),
          const SizedBox(height: ReadInSpace.s3),
          PlainField(
            value: block.caption ?? '',
            decorated: true,
            label: l10n.imageCaptionLabel,
            maxLength: DraftLimits.maxPlainText,
            onChanged: (v) => scope.controller.replace(_with(caption: () => v.isEmpty ? null : v)),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: scope.editorContext.enabled && !_uploading ? _pick : null,
              icon: _uploading
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(l10n.imageReplace),
            ),
          ),
        ],
      ],
    );
  }
}

/// Allow-listed embeds (SPEC §13.2): YouTube and GitHub Gist links only.
abstract final class EmbedLinks {
  static const _youtube = {'youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be', 'www.youtube-nocookie.com'};
  static const _gist = {'gist.github.com'};

  static bool isValid(String provider, String url) {
    if (!InlineEditing.isHttpUrl(url)) return false;
    final host = Uri.parse(url.trim()).host.toLowerCase();
    return provider == 'github-gist' ? _gist.contains(host) : _youtube.contains(host);
  }
}

class EmbedBlockEditor extends StatelessWidget {
  const EmbedBlockEditor({super.key, required this.block});

  final REmbed block;

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final invalid = block.url.trim().isNotEmpty && !EmbedLinks.isValid(block.provider, block.url);
    return Container(
      padding: const EdgeInsets.all(ReadInSpace.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'youtube', label: Text('YouTube'), icon: Icon(Icons.smart_display_outlined)),
              ButtonSegment(value: 'github-gist', label: Text('GitHub Gist'), icon: Icon(Icons.code_rounded)),
            ],
            selected: {block.provider == 'github-gist' ? 'github-gist' : 'youtube'},
            onSelectionChanged: (v) => scope.controller.replace(REmbed(block.id, provider: v.first, url: block.url)),
          ),
          const SizedBox(height: ReadInSpace.s3),
          PlainField(
            value: block.url,
            decorated: true,
            primaryFor: block.id,
            label: l10n.embedUrlLabel,
            hint: block.provider == 'github-gist' ? 'https://gist.github.com/…' : 'https://www.youtube.com/watch?v=…',
            errorText: invalid ? l10n.embedInvalid : null,
            direction: TextDirection.ltr,
            keyboardType: TextInputType.url,
            maxLength: DraftLimits.maxUrl,
            onChanged: (v) => scope.controller.replace(REmbed(block.id, provider: block.provider, url: v.trim())),
          ),
        ],
      ),
    );
  }
}

