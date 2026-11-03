import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.g.dart';
import '../code_highlighter.dart';
import '../rdoc_document.dart';
import '../rdoc_scope.dart';

class RCodeView extends StatelessWidget {
  const RCodeView(this.block, {super.key});

  final RCode block;

  @override
  Widget build(BuildContext context) => CodePanel(
        lang: block.lang,
        code: block.code,
        filename: block.filename,
        highlightLines: block.highlightLines,
      );
}

class RCodeTabsView extends StatefulWidget {
  const RCodeTabsView(this.block, {super.key});

  final RCodeTabs block;

  @override
  State<RCodeTabsView> createState() => _RCodeTabsViewState();
}

class _RCodeTabsViewState extends State<RCodeTabsView> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = widget.block.tabs;
    if (tabs.isEmpty) return const SizedBox.shrink();
    final tab = tabs[_selected.clamp(0, tabs.length - 1)];
    final colors = context.colors;
    return CodePanel(
      lang: tab.lang,
      code: tab.code,
      filename: tab.filename,
      header: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s1),
              child: Semantics(
                selected: i == _selected,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(ReadInRadius.sm),
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: 6),
                    decoration: BoxDecoration(
                      color: i == _selected ? colors.codeText.withValues(alpha: 0.12) : null,
                      borderRadius: BorderRadius.circular(ReadInRadius.sm),
                    ),
                    child: Text(
                      tabs[i].label,
                      style: codeTextStyle(
                        size: 13,
                        color: i == _selected ? colors.codeText : colors.codeText.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Code is always LTR, left-aligned, JetBrains Mono, on `code-bg` in both
/// themes (SPEC §14.2 rule 3, §15.2), with filename/language header and copy.
class CodePanel extends StatelessWidget {
  const CodePanel({
    super.key,
    required this.lang,
    required this.code,
    this.filename,
    this.highlightLines = const [],
    this.header,
  });

  final String lang;
  final String code;
  final String? filename;
  final List<int> highlightLines;

  /// Replaces the filename label (used by code tabs).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = RDocScope.of(context).scale;
    final base = codeTextStyle(size: ReadInType.codeSize * scale, color: colors.codeText);
    final lines = CodeHighlighter.instance.highlightLines(code, lang, dark: context.isDark, base: base);
    final emphasized = highlightLines.toSet();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        key: const ValueKey('rdoc-code-panel'),
        decoration: BoxDecoration(
          color: colors.codeBg,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: Border.all(color: colors.codeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s3, ReadInSpace.s1, ReadInSpace.s1, 0),
              child: Row(
                children: [
                  Expanded(
                    child: header ??
                        Text(
                          filename ?? lang,
                          style: codeTextStyle(size: 12, color: colors.codeText.withValues(alpha: 0.65)),
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                  _CopyButton(code: code),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(0, ReadInSpace.s1, 0, ReadInSpace.s3),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      Container(
                        color: emphasized.contains(i + 1) ? colors.codeText.withValues(alpha: 0.10) : null,
                        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
                        child: Text.rich(
                          TextSpan(
                            style: base,
                            children: [
                              if (lines[i].isEmpty) const TextSpan(text: ' '),
                              for (final (text, style) in lines[i]) TextSpan(text: text, style: style),
                            ],
                          ),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          softWrap: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      tooltip: context.l10n.copyCode,
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.copy_rounded, size: 18, color: colors.codeText.withValues(alpha: 0.75)),
      onPressed: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final copied = context.l10n.copied;
        await Clipboard.setData(ClipboardData(text: code));
        messenger?.showSnackBar(SnackBar(content: Text(copied), duration: const Duration(seconds: 2)));
      },
    );
  }
}
