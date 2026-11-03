import 'package:readin/features/reading/domain/entities/reading.dart';

final readingToday = DateTime.utc(2026, 11, 3);

Streak sampleStreak({
  int current = 12,
  int longest = 30,
  bool readToday = true,
  bool freezeAvailable = true,
  bool freezePending = false,
}) =>
    Streak(
      current: current,
      longest: longest,
      readToday: readToday,
      freezeAvailable: freezeAvailable,
      freezePending: freezePending,
      today: readingToday,
    );

const sampleTopFields = [
  TopField(id: 'f-dotnet', slug: 'dotnet', name: '.NET', icon: 'code-xml', color: 'callout-info-accent', articles: 54),
  TopField(id: 'f-ai', slug: 'ai-fundamentals', name: 'AI Fundamentals', icon: 'sparkles', color: 'primary', articles: 31),
  TopField(id: 'f-db', slug: 'databases', name: 'Databases', icon: 'database', color: 'accent', articles: 12),
];

ReadingStats sampleStats({Streak? streak, List<TopField> topFields = sampleTopFields}) => ReadingStats(
      streak: streak ?? sampleStreak(),
      totalArticles: 128,
      minutesRead: 1240,
      articlesThisWeek: 9,
      minutesThisWeek: 74,
      articlesThisMonth: 31,
      topFields: topFields,
    );

/// A year of reading ending on [readingToday]: a 12-day streak with one freeze, and a sparse history before it.
ReadingHeatmapData sampleHeatmap() {
  final days = <HeatmapDay>[];
  for (var back = 364; back >= 0; back--) {
    final date = DateTime.utc(2026, 11, 3 - back);
    if (back == 8) {
      days.add(HeatmapDay(date: date, articles: 0, minutes: 0, frozen: true));
    } else if (back < 13 || (back * 7) % 5 < 2 || back % 11 == 0) {
      final articles = 1 + (back * 3) % 4;
      days.add(HeatmapDay(date: date, articles: articles, minutes: articles * 6));
    }
  }
  return ReadingHeatmapData(from: DateTime.utc(2025, 11, 4), to: readingToday, days: days);
}
