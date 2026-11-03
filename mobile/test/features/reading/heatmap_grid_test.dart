import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/widgets/heatmap_grid.dart';

DateTime d(int year, int month, int day) => DateTime.utc(year, month, day);

/// 2025-11-04 (a Tuesday) … 2026-11-03 (a Tuesday): the default 365 days.
ReadingHeatmapData year({List<HeatmapDay> days = const []}) =>
    ReadingHeatmapData(from: d(2025, 11, 4), to: d(2026, 11, 3), days: days);

void main() {
  test('Sunday first: 53 week columns of 7 rows, days outside the range left out', () {
    final grid = buildHeatmapGrid(year(), firstDayOfWeek: DateTime.sunday);

    expect(grid.weeks, hasLength(53));
    expect(grid.weeks.every((w) => w.length == 7), isTrue);
    expect(grid.weeks.expand((w) => w).whereType<HeatmapCell>(), hasLength(365));

    // The first column starts on Sunday 2025-11-02; the range starts on its Tuesday.
    expect(grid.weeks.first.take(2), [null, null]);
    expect(grid.weeks.first[2]?.date, d(2025, 11, 4));
    // The last column starts on Sunday 2026-11-01 and ends with today, a Tuesday.
    expect(grid.weeks.last.map((c) => c?.date), [d(2026, 11, 1), d(2026, 11, 2), d(2026, 11, 3), null, null, null, null]);
  });

  test('Saturday first (Arabic) shifts the rows', () {
    final grid = buildHeatmapGrid(year(), firstDayOfWeek: DateTime.saturday);

    expect(grid.weeks, hasLength(53));
    expect(grid.weeks.first.take(3), [null, null, null]); // Sat 1, Sun 2, Mon 3 Nov
    expect(grid.weeks.first[3]?.date, d(2025, 11, 4));
    expect(grid.weeks.last.map((c) => c?.date), [d(2026, 10, 31), d(2026, 11, 1), d(2026, 11, 2), d(2026, 11, 3), null, null, null]);
  });

  test('levels are 0, 1, 2 and 3+ articles; freezes are flagged', () {
    final grid = buildHeatmapGrid(year(days: [
      HeatmapDay(date: d(2026, 10, 1), articles: 1, minutes: 6),
      HeatmapDay(date: d(2026, 10, 2), articles: 2, minutes: 11),
      HeatmapDay(date: d(2026, 10, 3), articles: 3, minutes: 19),
      HeatmapDay(date: d(2026, 10, 5), articles: 7, minutes: 52),
      HeatmapDay(date: d(2026, 10, 4), articles: 0, minutes: 0, frozen: true),
    ]));
    final cells = {for (final c in grid.weeks.expand((w) => w).whereType<HeatmapCell>()) c.date: c};

    expect([for (var day = 1; day <= 6; day++) cells[d(2026, 10, day)]!.level], [1, 2, 3, 0, 3, 0]);
    expect(cells[d(2026, 10, 4)]!.frozen, isTrue);
    expect(cells[d(2026, 10, 5)], HeatmapCell(date: d(2026, 10, 5), articles: 7, minutes: 52));
    expect(grid.readingDays, 4);
    expect([0, 1, 2, 3, 4, 99].map(HeatmapCell.levelFor), [0, 1, 2, 3, 3, 3]);
  });

  test('month labels sit over the column with the 1st, plus the first partial month when there is room', () {
    final grid = buildHeatmapGrid(year(), firstDayOfWeek: DateTime.sunday);

    expect(grid.months, hasLength(13));
    expect(grid.months.first, HeatmapMonthLabel(column: 0, month: d(2025, 11, 1)));
    expect(grid.months[1], HeatmapMonthLabel(column: 4, month: d(2025, 12, 1))); // Monday 1 Dec, week of Sun 30 Nov
    expect(grid.months.last, HeatmapMonthLabel(column: 52, month: d(2026, 11, 1)));
  });

  test('no label for the partial first month when the next one starts within 3 columns', () {
    final grid = buildHeatmapGrid(
      ReadingHeatmapData(from: d(2025, 11, 20), to: d(2026, 1, 31)),
      firstDayOfWeek: DateTime.sunday,
    );

    expect(grid.months.first, HeatmapMonthLabel(column: 2, month: d(2025, 12, 1)));
    expect(grid.months, hasLength(2));
  });

  test('an inverted range is empty', () {
    final grid = buildHeatmapGrid(ReadingHeatmapData(from: d(2026, 11, 3), to: d(2026, 11, 2)));

    expect(grid.weeks, isEmpty);
    expect(grid.months, isEmpty);
    expect(grid.readingDays, 0);
  });
}
