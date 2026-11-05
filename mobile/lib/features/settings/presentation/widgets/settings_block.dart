import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/page_block.dart';

/// A section of Settings and its pages, LinkedIn style: a white [PageBlock] a gap under the last, its [title] inside
/// it, an optional [note] under the title, then its [rows] split by 1 px dividers. The rows line up with the gutter.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({super.key, this.title, required this.rows, this.note});

  final String? title;
  final Widget? note;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => PageBlock(
        margin: const EdgeInsets.only(top: PageBlock.gap),
        padding: EdgeInsets.fromLTRB(PageBlock.gutter, title == null ? ReadInSpace.s1 : ReadInSpace.s4, PageBlock.gutter, ReadInSpace.s1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title case final title?) ...[
              Semantics(header: true, child: Text(title, style: context.textTheme.titleMedium)),
              const SizedBox(height: ReadInSpace.s2),
            ],
            ?note,
            for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(), rows[i]],
          ],
        ),
      );
}
