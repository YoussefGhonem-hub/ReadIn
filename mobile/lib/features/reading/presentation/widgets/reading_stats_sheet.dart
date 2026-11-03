import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import 'reading_heatmap.dart';
import 'reading_stats_card.dart';

/// "Reading stats" from the Home streak badge (F03, F08): the stats card and the heatmap.
Future<void> showReadingStatsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ReadingStatsSheet(),
    );

class ReadingStatsSheet extends StatelessWidget {
  const ReadingStatsSheet({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.readingStatsTitle, style: context.textTheme.titleLarge),
            const SizedBox(height: ReadInSpace.s4),
            const ReadingStatsCard(),
            const SizedBox(height: ReadInSpace.s4),
            const ReadingHeatmap(),
          ],
        ),
      );
}
