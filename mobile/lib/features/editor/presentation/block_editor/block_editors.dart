import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/media_blocks.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/editing/block_editing.dart';
import '../../../../shared/rdoc/editing/table_editing.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/editor_entities.dart';
import 'block_editor_surface.dart';
import 'block_kinds_ui.dart';
import 'inline_text_controller.dart';

/// A structured block edited in place, inside the editor (as the web editor's node views): steps, code, code tabs,
/// table, image or embed. Every change goes to [BlockEditorScope.host].
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

/// A borderless multi-line field over RDoc inline content ([InlineTextController]): a table cell, a step's text. The
/// toolbar formats the one in focus; a table cell also tells it which [cell] it is, for the table tools.
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
    this.cell,
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
  final TablePosition? cell;

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
    if (_focus.hasFocus && oldWidget.cell != widget.cell) _onFocus();
  }

  void _onFocus() {
    final scope = _scope;
    if (scope == null) return;
    if (_focus.hasFocus) {
      scope.editorContext.focus.activate(widget.blockId, _controller, cell: widget.cell);
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
/// unless [direction] is given. A value changed from outside (undo, a reload) replaces the text even while typing.
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
    this.fieldKey,
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
  final Key? fieldKey;

  @override
  State<PlainField> createState() => _PlainFieldState();
}

class _PlainFieldState extends State<PlainField> {
  late final _controller = TextEditingController(text: widget.value);
  late String _sent = widget.value;
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
    if (widget.value != _controller.text && (widget.value != _sent || !_focus.hasFocus)) {
      _sent = widget.value;
      _controller.value = TextEditingValue(text: widget.value, selection: TextSelection.collapsed(offset: widget.value.length));
    }
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
      key: widget.fieldKey,
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
        _sent = v;
        setState(() {}); // direction follows the text
        widget.onChanged(v);
      },
    );
  }
}

// ── Steps ──────────────────────────────────────────────────

/// Numbered steps: each step's title and text in place, add and remove steps.
class StepsBlockEditor extends StatelessWidget {
  const StepsBlockEditor({super.key, required this.block});

  final RSteps block;

  static const _maxSteps = 50;

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final dir = _dirOf(context, block);
    final style = rdocBodyStyle(context, dir);
    void set(List<RStep> items) => scope.host.replace(RSteps(block.id, dir: block.dir, items: items));
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
                          fieldKey: ValueKey('${block.id}-step-title-$i'),
                          value: block.items[i].title,
                          hint: l10n.stepTitleHint,
                          maxLength: DraftLimits.maxPlainText,
                          direction: dir,
                          primaryFor: i == 0 ? block.id : null,
                          style: style.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                          onChanged: (v) => set([...block.items]..[i] = RStep(title: v, content: block.items[i].content)),
                        ),
                        InlineField(
                          fieldKey: ValueKey('${block.id}-step-body-$i'),
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
                      key: ValueKey('${block.id}-step-remove-$i'),
                      tooltip: l10n.removeStep,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: scope.editorContext.enabled ? () => set([...block.items]..removeAt(i)) : null,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
          if (block.items.length < _maxSteps)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: ValueKey('${block.id}-step-add'),
                onPressed: scope.editorContext.enabled ? () => set([...block.items, const RStep(title: '', content: [])]) : null,
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
  const _LangPicker({required this.value, required this.onChanged, this.pickerKey});

  final String value;
  final ValueChanged<String> onChanged;
  final Key? pickerKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = codeTextStyle(size: 13, color: colors.codeText);
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        key: pickerKey,
        value: value,
        isDense: true,
        dropdownColor: colors.codeBg,
        iconEnabledColor: colors.codeText,
        style: style,
        items: [
          for (final lang in {...codeLanguages, value}) DropdownMenuItem(value: lang, child: Text(codeLanguageName(lang), style: style)),
        ],
        onChanged: BlockEditorScope.of(context).editorContext.enabled ? (v) => onChanged(v ?? value) : null,
      ),
    );
  }
}

/// A code block: the language and file name in its header, the code below (Enter adds a line; no marks).
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
    return _CodeSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LangPicker(
                pickerKey: ValueKey('${block.id}-lang'),
                value: block.lang,
                onChanged: (v) => scope.host.replace(_with(lang: v)),
              ),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(
                child: PlainField(
                  fieldKey: ValueKey('${block.id}-filename'),
                  value: block.filename ?? '',
                  hint: l10n.codeFilenameHint,
                  maxLength: 200,
                  direction: TextDirection.ltr,
                  style: codeTextStyle(size: 13, color: colors.codeText),
                  onChanged: (v) => scope.host.replace(_with(filename: () => v.isEmpty ? null : v)),
                ),
              ),
            ],
          ),
          Divider(color: colors.codeBorder, height: ReadInSpace.s4),
          PlainField(
            fieldKey: ValueKey('${block.id}-code'),
            value: block.code,
            hint: l10n.codeHint,
            primaryFor: block.id,
            direction: TextDirection.ltr,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            style: codeTextStyle(color: colors.codeText),
            onChanged: (v) => scope.host.replace(_with(code: v)),
          ),
        ],
      ),
    );
  }
}

/// Code tabs: a tab strip (switch, add up to 8), and the active tab's name, language, file name and code in place.
/// Removing the last tab removes the block.
class CodeTabsBlockEditor extends StatefulWidget {
  const CodeTabsBlockEditor({super.key, required this.block});

  final RCodeTabs block;

  static const maxTabs = 8;

  @override
  State<CodeTabsBlockEditor> createState() => _CodeTabsBlockEditorState();
}

class _CodeTabsBlockEditorState extends State<CodeTabsBlockEditor> {
  int _selected = 0;

  void _set(List<RCodeTab> tabs) => BlockEditorScope.of(context).host.replace(RCodeTabs(widget.block.id, tabs: tabs));

  RCodeTab _tab(RCodeTab t, {String? label, String? lang, String? code, String? Function()? filename}) => RCodeTab(
        label: label ?? t.label,
        lang: lang ?? t.lang,
        code: code ?? t.code,
        filename: filename != null ? filename() : t.filename,
        compile: t.compile,
      );

  void _remove(int index) {
    final tabs = widget.block.tabs;
    if (tabs.length <= 1) return BlockEditorScope.of(context).host.remove(widget.block.id);
    _set([...tabs]..removeAt(index));
    setState(() => _selected = (index - 1).clamp(0, tabs.length - 2));
  }

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final enabled = scope.editorContext.enabled;
    final colors = context.colors;
    final l10n = context.l10n;
    final id = widget.block.id;
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
                      key: ValueKey('$id-tab-$i'),
                      label: Text(tabs[i].label.isEmpty ? codeLanguageName(tabs[i].lang) : tabs[i].label),
                      selected: i == index,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _selected = i),
                    ),
                  ),
                if (tabs.length < CodeTabsBlockEditor.maxTabs)
                  IconButton(
                    key: ValueKey('$id-tab-add'),
                    tooltip: l10n.addCodeTab,
                    color: colors.codeText,
                    iconSize: 18,
                    onPressed: enabled
                        ? () {
                            _set([...tabs, RCodeTab(label: codeLanguageName('plaintext'), lang: 'plaintext', code: '')]);
                            setState(() => _selected = tabs.length);
                          }
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ReadInSpace.s2),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: PlainField(
                  key: ValueKey('$id-label-$index'),
                  fieldKey: ValueKey('$id-tab-label'),
                  value: tab.label,
                  hint: l10n.codeTabLabelHint,
                  maxLength: 40,
                  direction: TextDirection.ltr,
                  style: small,
                  onChanged: (v) => _set([...tabs]..[index] = _tab(tab, label: v)),
                ),
              ),
              const SizedBox(width: ReadInSpace.s2),
              _LangPicker(
                pickerKey: ValueKey('$id-tab-lang'),
                value: tab.lang,
                // A name that still names the old language follows the new one.
                onChanged: (v) => _set([...tabs]
                  ..[index] = tab.label.isEmpty || tab.label == codeLanguageName(tab.lang)
                      ? _tab(tab, lang: v, label: codeLanguageName(v))
                      : _tab(tab, lang: v)),
              ),
              const Spacer(),
              IconButton(
                key: ValueKey('$id-tab-remove'),
                tooltip: l10n.removeCodeTab,
                color: colors.codeText,
                iconSize: 18,
                onPressed: enabled ? () => _remove(index) : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          PlainField(
            key: ValueKey('$id-filename-$index'),
            fieldKey: ValueKey('$id-tab-filename'),
            value: tab.filename ?? '',
            hint: l10n.codeFilenameHint,
            maxLength: 200,
            direction: TextDirection.ltr,
            style: small,
            onChanged: (v) => _set([...tabs]..[index] = _tab(tab, filename: () => v.isEmpty ? null : v)),
          ),
          Divider(color: colors.codeBorder, height: ReadInSpace.s4),
          PlainField(
            key: ValueKey('$id-code-$index'),
            fieldKey: ValueKey('$id-tab-code'),
            value: tab.code,
            hint: l10n.codeHint,
            primaryFor: id,
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

/// A table edited in place, a field per cell; the header row is bold. The toolbar's table tools add and delete rows
/// and columns around the cell in focus ([InlineField.cell]); when the cell in focus is deleted, the caret moves to
/// the nearest cell left, as in the web editor.
class TableBlockEditor extends StatefulWidget {
  const TableBlockEditor({super.key, required this.block});

  final RTable block;

  @override
  State<TableBlockEditor> createState() => _TableBlockEditorState();
}

class _TableBlockEditorState extends State<TableBlockEditor> {
  final _focusNodes = <(int, int), FocusNode>{};

  FocusNode _nodeAt(int row, int col) => _focusNodes.putIfAbsent((row, col), FocusNode.new);

  @override
  void didUpdateWidget(TableBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rows = widget.block.rows.length;
    final columns = widget.block.header.length;
    bool gone((int, int) at) => at.$1 > rows || at.$2 >= columns;
    final removed = [for (final at in _focusNodes.keys) if (gone(at)) at];
    if (removed.isEmpty) return;
    final focused = removed.where((at) => _focusNodes[at]!.hasFocus).firstOrNull;
    final nodes = [for (final at in removed) _focusNodes.remove(at)!];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The fields that used them are gone by now.
      for (final node in nodes) {
        node.dispose();
      }
      if (focused != null && mounted && columns > 0) {
        _nodeAt(focused.$1 > rows ? rows : focused.$1, focused.$2 >= columns ? columns - 1 : focused.$2).requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final dir = _dirOf(context, block);
    final style = rdocBodyStyle(context, dir, factor: 0.85).copyWith(height: 1.5);
    final columns = block.header.length;
    void set({List<List<RInline>>? header, List<List<List<RInline>>>? rows}) =>
        scope.host.replace(RTable(block.id, dir: block.dir, header: header ?? block.header, rows: rows ?? block.rows));

    Widget cell(List<RInline> nodes, ValueChanged<List<RInline>> onChanged, TablePosition at) => Padding(
          padding: const EdgeInsets.all(ReadInSpace.s2),
          child: InlineField(
            key: ValueKey('${block.id}-cell-${at.row}-${at.col}'),
            fieldKey: ValueKey('${block.id}-field-${at.row}-${at.col}'),
            blockId: block.id,
            primary: at.row == 0 && at.col == 0,
            cell: at,
            focusNode: _nodeAt(at.row, at.col),
            nodes: nodes,
            style: at.row == 0 ? style.copyWith(fontWeight: FontWeight.w700) : style,
            direction: dir,
            onChanged: onChanged,
          ),
        );

    return Directionality(
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
                for (var c = 0; c < columns; c++) cell(block.header[c], (n) => set(header: [...block.header]..[c] = n), (row: 0, col: c)),
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
                    (row: r + 1, col: c),
                  ),
              ]),
          ],
        ),
      ),
    );
  }
}

// ── Media and embeds ───────────────────────────────────────

/// An image: upload or replace it in place, with its alt text (required, flagged red while missing), caption and an
/// optional dark mode version (diagrams, SPEC §15.5 rule 5) under it.
class ImageBlockEditor extends StatefulWidget {
  const ImageBlockEditor({super.key, required this.block});

  final RImage block;

  @override
  State<ImageBlockEditor> createState() => _ImageBlockEditorState();
}

class _ImageBlockEditorState extends State<ImageBlockEditor> {
  bool _uploading = false;
  bool _uploadingDark = false;

  RImage _with({
    String? src,
    String? alt,
    String? Function()? darkSrc,
    String? Function()? caption,
    int? Function()? width,
    int? Function()? height,
  }) =>
      RImage(
        widget.block.id,
        src: src ?? widget.block.src,
        alt: alt ?? widget.block.alt,
        darkSrc: darkSrc != null ? darkSrc() : widget.block.darkSrc,
        caption: caption != null ? caption() : widget.block.caption,
        width: width != null ? width() : widget.block.width,
        height: height != null ? height() : widget.block.height,
      );

  /// Uploads the picture, or with [dark] its dark mode version (the size stays the picture's).
  Future<void> _pick({bool dark = false}) async {
    final scope = BlockEditorScope.of(context);
    final file = await scope.editorContext.pickImage();
    if (file == null || !mounted) return;
    void uploading(bool value) => setState(() {
          if (dark) {
            _uploadingDark = value;
          } else {
            _uploading = value;
          }
        });
    uploading(true);
    final asset = await scope.editorContext.uploadImage(file);
    if (!mounted) return;
    uploading(false);
    final url = asset == null || asset.variants.isEmpty ? null : asset.variants.last.url;
    if (url == null) return;
    scope.host.replace(dark ? _with(darkSrc: () => url) : _with(src: url, width: () => asset!.width, height: () => asset!.height));
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
            fieldKey: ValueKey('${block.id}-alt'),
            value: block.alt,
            decorated: true,
            primaryFor: block.id,
            label: l10n.imageAltLabel,
            helper: missingAlt ? null : l10n.imageAltHelp,
            errorText: missingAlt ? l10n.problemImageAlt : null,
            maxLength: DraftLimits.maxImageAlt,
            onChanged: (v) => scope.host.replace(_with(alt: v)),
          ),
          const SizedBox(height: ReadInSpace.s3),
          PlainField(
            fieldKey: ValueKey('${block.id}-caption'),
            value: block.caption ?? '',
            decorated: true,
            label: l10n.imageCaptionLabel,
            maxLength: DraftLimits.maxPlainText,
            onChanged: (v) => scope.host.replace(_with(caption: () => v.isEmpty ? null : v)),
          ),
          _DarkVersionRow(
            block: block,
            uploading: _uploadingDark,
            onAdd: scope.editorContext.enabled && !_uploadingDark ? () => _pick(dark: true) : null,
            onRemove: scope.editorContext.enabled ? () => scope.host.replace(_with(darkSrc: () => null)) : null,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: ValueKey('image-replace-${block.id}'),
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

/// The image's dark mode version (`darkSrc`, shown in dark mode instead: diagrams), as in the web editor: a thumbnail
/// with a remove button once there is one, else a button to add it.
class _DarkVersionRow extends StatelessWidget {
  const _DarkVersionRow({required this.block, required this.uploading, required this.onAdd, required this.onRemove});

  final RImage block;
  final bool uploading;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final darkSrc = block.darkSrc;
    if (darkSrc == null || darkSrc.isEmpty) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: ValueKey('image-dark-add-${block.id}'),
          onPressed: onAdd,
          icon: uploading
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.dark_mode_outlined, size: 18),
          label: Text(l10n.imageDarkAdd),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: AppNetworkImage(url: darkSrc, borderRadius: BorderRadius.circular(ReadInRadius.sm), errorLabel: l10n.imageUnavailable),
          ),
          const SizedBox(width: ReadInSpace.s3),
          Expanded(child: Text(l10n.imageDarkVersion, style: context.textTheme.bodyMedium)),
          IconButton(
            key: ValueKey('image-dark-remove-${block.id}'),
            tooltip: l10n.imageDarkRemove,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Allow-listed embeds (SPEC §13.2), the same check as the web editor's `isAllowedEmbed`: a YouTube video id
/// (youtu.be, youtube.com watch / embed / shorts / live, youtube-nocookie.com) or a GitHub Gist.
abstract final class EmbedLinks {
  static final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _gist = RegExp(r'^https://gist\.github\.com/[\w.-]+/[0-9a-f]+', caseSensitive: false);
  static final _http = RegExp(r'''^https?://[^\s<>"']+$''', caseSensitive: false);
  static final _youtubePath = RegExp(r'^/(?:embed|shorts|live)/([^/]+)');

  static String? youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.|^m\.'), '');
    String? id;
    if (host == 'youtu.be') {
      id = uri.path.length > 1 ? uri.path.substring(1) : null;
    } else if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
      id = uri.queryParameters['v'] ?? _youtubePath.firstMatch(uri.path)?.group(1);
    }
    return id != null && _youtubeId.hasMatch(id) ? id : null;
  }

  static bool isValid(String provider, String url) {
    final value = url.trim();
    if (!_http.hasMatch(value)) return false;
    if (provider == 'github-gist') return _gist.hasMatch(value);
    return youtubeId(value) != null;
  }
}

/// An embed: the provider, the link in place (checked as you type), and the reader's preview once it is valid.
class EmbedBlockEditor extends StatelessWidget {
  const EmbedBlockEditor({super.key, required this.block});

  final REmbed block;

  @override
  Widget build(BuildContext context) {
    final scope = BlockEditorScope.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    final provider = block.provider == 'github-gist' ? 'github-gist' : 'youtube';
    final empty = block.url.trim().isEmpty;
    final valid = !empty && EmbedLinks.isValid(provider, block.url);
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
            key: ValueKey('${block.id}-provider'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'youtube', label: Text('YouTube'), icon: Icon(Icons.smart_display_outlined)),
              ButtonSegment(value: 'github-gist', label: Text('GitHub Gist'), icon: Icon(Icons.code_rounded)),
            ],
            selected: {provider},
            onSelectionChanged: scope.editorContext.enabled
                ? (v) => scope.host.replace(REmbed(block.id, provider: v.first, url: block.url))
                : null,
          ),
          const SizedBox(height: ReadInSpace.s3),
          PlainField(
            fieldKey: ValueKey('${block.id}-url'),
            value: block.url,
            decorated: true,
            primaryFor: block.id,
            label: l10n.embedUrlLabel,
            hint: provider == 'github-gist' ? 'https://gist.github.com/…' : 'https://www.youtube.com/watch?v=…',
            errorText: !empty && !valid ? l10n.embedInvalid : null,
            direction: TextDirection.ltr,
            keyboardType: TextInputType.url,
            maxLength: DraftLimits.maxUrl,
            onChanged: (v) => scope.host.replace(REmbed(block.id, provider: provider, url: v)),
          ),
          if (valid) ...[
            const SizedBox(height: ReadInSpace.s3),
            IgnorePointer(child: REmbedView(REmbed(block.id, provider: provider, url: block.url.trim()))),
          ],
        ],
      ),
    );
  }
}
