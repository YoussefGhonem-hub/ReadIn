@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/theme/tokens.g.dart';
import 'package:readin/features/reading/presentation/widgets/milestone_sheet.dart';
import 'package:readin/features/reading/presentation/widgets/reading_heatmap.dart';
import 'package:readin/features/reading/presentation/widgets/reading_stats_card.dart';
import 'package:readin/shared/widgets/badges.dart';

import '../helpers/reading_fixtures.dart';
import '../helpers/test_app.dart';

/// Streaks & reading stats (F08) in the 4 mandatory variants: ar/en × light/dark (SPEC §8.2).
void main() {
  Future<void> pump(WidgetTester tester, Variant variant, Widget child, {double height = 600}) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(ReadInSpace.s4),
          child: Align(alignment: AlignmentDirectional.topStart, child: child),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.all) {
    testWidgets('reading stats card ${variant.name}', (tester) async {
      await pump(tester, variant, ReadingStatsView(stats: sampleStats()));
      await expectLater(find.byType(ReadingStatsView), matchesGoldenFile('goldens/reading_stats_card_${variant.name}.png'));
    });
  }

  // Yesterday was missed: reading today uses a freeze. No top fields yet.
  for (final variant in Variant.all) {
    testWidgets('reading stats card freeze pending ${variant.name}', (tester) async {
      final stats = sampleStats(
        streak: sampleStreak(current: 4, longest: 4, readToday: false, freezeAvailable: false, freezePending: true),
        topFields: const [],
      );
      await pump(tester, variant, ReadingStatsView(stats: stats));
      await expectLater(
        find.byType(ReadingStatsView),
        matchesGoldenFile('goldens/reading_stats_card_pending_${variant.name}.png'),
      );
    });
  }

  for (final variant in Variant.all) {
    testWidgets('reading heatmap ${variant.name}', (tester) async {
      await pump(tester, variant, ReadingHeatmapView(heatmap: sampleHeatmap()), height: 260);
      await expectLater(find.byType(ReadingHeatmapView), matchesGoldenFile('goldens/reading_heatmap_${variant.name}.png'));
    });
  }

  for (final variant in Variant.all) {
    testWidgets('milestone card ${variant.name}', (tester) async {
      await pump(tester, variant, const MilestoneShareCard(days: 30), height: 420);
      await expectLater(find.byType(MilestoneShareCard), matchesGoldenFile('goldens/reading_milestone_card_${variant.name}.png'));
    });
  }

  // Home badge: read today, not read yet today, freeze pending, and a guest / new streak.
  for (final variant in Variant.all) {
    testWidgets('streak badge states ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        const Wrap(
          key: ValueKey('badges'),
          spacing: ReadInSpace.s2,
          runSpacing: ReadInSpace.s2,
          children: [
            StreakBadge(days: 12),
            StreakBadge(days: 12, notReadToday: true),
            StreakBadge(days: 12, notReadToday: true, freezePending: true),
            StreakBadge(days: 0),
          ],
        ),
        height: 120,
      );
      await expectLater(find.byKey(const ValueKey('badges')), matchesGoldenFile('goldens/reading_streak_badges_${variant.name}.png'));
    });
  }
}
