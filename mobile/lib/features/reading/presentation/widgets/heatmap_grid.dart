import 'package:equatable/equatable.dart';

import '../../domain/entities/reading.dart';

/// One day of the reading heatmap.
class HeatmapCell extends Equatable {
  const HeatmapCell({required this.date, this.articles = 0, this.minutes = 0, this.frozen = false});

  /// Date only (UTC midnight).
  final DateTime date;
  final int articles;
  final int minutes;

  /// A missed day covered by a streak freeze.
  final bool frozen;

  /// Color step: 0, 1, 2 or 3+ completed articles.
  int get level => levelFor(articles);

  static int levelFor(int articles) => articles <= 0 ? 0 : (articles >= 3 ? 3 : articles);

  @override
  List<Object?> get props => [date, articles, minutes, frozen];
}

/// A month label over the week column that holds the month's first day.
class HeatmapMonthLabel extends Equatable {
  const HeatmapMonthLabel({required this.column, required this.month});

  final int column;

  /// The 1st of the month, date only (UTC midnight).
  final DateTime month;

  @override
  List<Object?> get props => [column, month];
}

/// GitHub-style layout: one column per week, oldest first, 7 rows from the first day of the week. Days outside
/// `from`–`to` are null (not drawn).
class HeatmapGrid extends Equatable {
  const HeatmapGrid({required this.weeks, required this.months});

  final List<List<HeatmapCell?>> weeks;
  final List<HeatmapMonthLabel> months;

  /// Days with at least one completed article.
  int get readingDays => weeks.expand((w) => w).where((c) => c != null && c.articles > 0).length;

  @override
  List<Object?> get props => [weeks, months];
}

/// Lays out [heatmap] in week columns that start on [firstDayOfWeek] (`DateTime.monday` … `DateTime.sunday`).
///
/// A month gets a label on the column that holds its 1st. The first, partial month gets one too when the next label
/// is at least [minLabelGap] columns away, so labels never overlap.
HeatmapGrid buildHeatmapGrid(ReadingHeatmapData heatmap, {int firstDayOfWeek = DateTime.sunday, int minLabelGap = 3}) {
  final from = _dateOnly(heatmap.from);
  final to = _dateOnly(heatmap.to);
  if (to.isBefore(from)) return const HeatmapGrid(weeks: [], months: []);

  final byDate = {for (final d in heatmap.days) _dateOnly(d.date): d};
  final start = _addDays(from, -((from.weekday - firstDayOfWeek) % 7));

  final weeks = <List<HeatmapCell?>>[];
  final months = <HeatmapMonthLabel>[];
  for (var weekStart = start; !weekStart.isAfter(to); weekStart = _addDays(weekStart, 7)) {
    final column = weeks.length;
    final week = <HeatmapCell?>[];
    for (var row = 0; row < 7; row++) {
      final date = _addDays(weekStart, row);
      if (date.isBefore(from) || date.isAfter(to)) {
        week.add(null);
        continue;
      }
      final day = byDate[date];
      week.add(HeatmapCell(date: date, articles: day?.articles ?? 0, minutes: day?.minutes ?? 0, frozen: day?.frozen ?? false));
      if (date.day == 1) months.add(HeatmapMonthLabel(column: column, month: date));
    }
    weeks.add(week);
  }

  // The range rarely starts on the 1st: label its first month too when there is room before the next label.
  if (from.day != 1 && (months.isEmpty || months.first.column >= minLabelGap)) {
    months.insert(0, HeatmapMonthLabel(column: 0, month: DateTime.utc(from.year, from.month)));
  }
  return HeatmapGrid(weeks: weeks, months: months);
}

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _addDays(DateTime d, int days) => DateTime.utc(d.year, d.month, d.day + days);
