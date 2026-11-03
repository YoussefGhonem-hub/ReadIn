import 'package:flutter/material.dart';

import '../../core/theme/tokens.g.dart';
import 'blocks/code_blocks.dart';
import 'blocks/media_blocks.dart';
import 'blocks/text_blocks.dart';
import 'rdoc_document.dart';

export 'rdoc_document.dart';
export 'rdoc_scope.dart';

/// Renders a single RDoc block. Keyed by block id so reader state (code tab
/// selection, scroll restoration) survives rebuilds.
class RBlockView extends StatelessWidget {
  const RBlockView(this.block, {super.key});

  final RBlock block;

  @override
  Widget build(BuildContext context) {
    final child = switch (block) {
      final RParagraph b => RParagraphView(b),
      final RHeading b => RHeadingView(b),
      final RList b => RListView(b),
      final RSteps b => RStepsView(b),
      final RQuote b => RQuoteView(b),
      final RCallout b => RCalloutView(b),
      final RCode b => RCodeView(b),
      final RCodeTabs b => RCodeTabsView(b),
      final RTable b => RTableView(b),
      final RImage b => RImageView(b),
      RDivider() => const RDividerView(),
      final REmbed b => REmbedView(b),
      final RSummary b => RSummaryView(b),
    };
    return Padding(
      key: ValueKey('rdoc-${block.type}-${block.id}'),
      padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
      child: child,
    );
  }
}

/// Lazily renders long articles (SPEC §25: lazy RDoc rendering).
class RDocSliver extends StatelessWidget {
  const RDocSliver(this.document, {super.key, this.skipSummary = false});

  final RDocDocument document;
  final bool skipSummary;

  @override
  Widget build(BuildContext context) {
    final blocks = skipSummary ? document.blocks.where((b) => b is! RSummary).toList() : document.blocks;
    return SliverList.builder(
      itemCount: blocks.length,
      itemBuilder: (context, i) => RBlockView(blocks[i]),
    );
  }
}

/// Eager column variant for short content, previews and tests.
class RDocColumn extends StatelessWidget {
  const RDocColumn(this.document, {super.key});

  final RDocDocument document;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in document.blocks) RBlockView(b)],
      );
}
