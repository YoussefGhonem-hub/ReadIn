import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../widgets/reading_heatmap.dart';
import '../widgets/reading_stats_card.dart';

/// "Reading stats" as a screen (F08): where `readin://me/stats` leads, e.g. the streak reminder (F17). The same card
/// and heatmap as the Home streak badge's sheet.
class ReadingStatsPage extends StatelessWidget {
  const ReadingStatsPage({super.key});

  static const path = '/me/stats';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.readingStatsTitle)),
        body: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ReadingStatsCard(), SizedBox(height: ReadInSpace.s4), ReadingHeatmap()],
          ),
        ),
      );
}
