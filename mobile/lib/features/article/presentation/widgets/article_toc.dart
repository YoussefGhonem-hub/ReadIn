import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/rdoc_document.dart';
import '../../../../shared/widgets/bidi_text.dart';

/// A heading listed in the table of contents.
typedef TocEntry = ({String blockId, int level, String text});

/// The h2/h3 headings of [document], in order.
List<TocEntry> tableOfContents(RDocDocument document) => [
      for (final block in document.blocks)
        if (block is RHeading) (blockId: block.id, level: block.level, text: plainTextOf(block.content).trim()),
    ];

/// The table of contents of a long article (F04, as on the web): collapsed under "In this article" until opened;
/// a heading scrolls the reader to it.
class ArticleToc extends StatefulWidget {
  const ArticleToc({super.key, required this.entries, required this.onSelected});

  /// Shown once an article has this many headings ("long articles").
  static const minHeadings = 3;

  final List<TocEntry> entries;
  final ValueChanged<TocEntry> onSelected;

  @override
  State<ArticleToc> createState() => _ArticleTocState();
}

class _ArticleTocState extends State<ArticleToc> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = context.l10n.articleToc;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : ReadInMotion.base;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4, vertical: ReadInSpace.s3),
                  child: Row(
                    children: [
                      Icon(Icons.toc_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: ReadInSpace.s2),
                      Expanded(child: Text(title, style: context.textTheme.titleSmall)),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: duration,
                        child: Icon(Icons.expand_more_rounded, size: 20, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional.topStart,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Semantics(
                      label: title,
                      container: true,
                      explicitChildNodes: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [for (final entry in widget.entries) _TocLink(entry: entry, onTap: () => widget.onSelected(entry))],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TocLink extends StatelessWidget {
  const _TocLink({required this.entry, required this.onTap});

  final TocEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              // An h3 sits under its h2.
              padding: EdgeInsetsDirectional.fromSTEB(
                entry.level >= 3 ? ReadInSpace.s4 + ReadInSpace.s4 : ReadInSpace.s4,
                ReadInSpace.s2,
                ReadInSpace.s4,
                ReadInSpace.s2,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: BidiText(entry.text, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              ),
            ),
          ),
        ),
      );
}
