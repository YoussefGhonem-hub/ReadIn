import { HeatmapDayDto } from '../../core/api/models';
import { buildHeatmapGrid, heatmapLevel } from './heatmap-grid';

const day = (date: string, articles: number, minutes = articles * 6, frozen = false): HeatmapDayDto => ({ date, articles, minutes, frozen });

describe('buildHeatmapGrid', () => {
  it('lays out one column per week and one row per weekday, Sunday first', () => {
    // 1 Nov 2026 is a Sunday, 14 Nov a Saturday.
    const grid = buildHeatmapGrid({ from: '2026-11-01', to: '2026-11-14', days: [] });

    expect(grid.columns).toBe(2);
    expect(grid.cells).toHaveLength(14);
    expect(grid.cells[0]).toMatchObject({ date: '2026-11-01', column: 0, row: 0 });
    expect(grid.cells[6]).toMatchObject({ date: '2026-11-07', column: 0, row: 6 });
    expect(grid.cells[7]).toMatchObject({ date: '2026-11-08', column: 1, row: 0 });
    expect(grid.cells[13]).toMatchObject({ date: '2026-11-14', column: 1, row: 6 });
  });

  it('starts the first week on the right weekday and ends on `to`', () => {
    // 4 Nov 2026 is a Wednesday and 10 Nov a Tuesday.
    const grid = buildHeatmapGrid({ from: '2026-11-04', to: '2026-11-10', days: [] });
    expect(grid.cells[0]).toMatchObject({ date: '2026-11-04', column: 0, row: 3 });
    expect(grid.cells.at(-1)).toMatchObject({ date: '2026-11-10', column: 1, row: 2 });
    expect(grid.columns).toBe(2);
  });

  it('supports another first day of the week', () => {
    // Saturday first: Wednesday is the fifth row.
    const grid = buildHeatmapGrid({ from: '2026-11-04', to: '2026-11-07', days: [] }, 6);
    expect(grid.cells[0]).toMatchObject({ row: 4, column: 0 });
    expect(grid.cells[3]).toMatchObject({ date: '2026-11-07', row: 0, column: 1 });
  });

  it('covers a full year as 53 consecutive weeks with today last', () => {
    const grid = buildHeatmapGrid({ from: '2025-11-04', to: '2026-11-03', days: [] });

    expect(grid.cells).toHaveLength(365);
    expect(grid.columns).toBe(53);
    expect(grid.cells.at(-1)?.date).toBe('2026-11-03');
    // No day is skipped or repeated, daylight saving or not.
    for (let i = 1; i < grid.cells.length; i++) {
      expect(Date.parse(grid.cells[i].date) - Date.parse(grid.cells[i - 1].date)).toBe(86_400_000);
    }
  });

  it('labels each month that starts inside the range at its week column', () => {
    const grid = buildHeatmapGrid({ from: '2026-09-15', to: '2026-11-03', days: [] });

    expect(grid.months.map((m) => m.date)).toEqual(['2026-10-01', '2026-11-01']);
    const october = grid.cells.find((c) => c.date === '2026-10-01')!;
    const november = grid.cells.find((c) => c.date === '2026-11-01')!;
    expect(grid.months[0].column).toBe(october.column);
    expect(grid.months[1].column).toBe(november.column);
  });

  it('fills the days the API returned and leaves the rest empty', () => {
    const grid = buildHeatmapGrid({
      from: '2026-11-01',
      to: '2026-11-07',
      days: [day('2026-11-02', 1, 9), day('2026-11-03', 2), day('2026-11-05', 4)],
    });
    const byDate = Object.fromEntries(grid.cells.map((c) => [c.date, c]));

    expect(byDate['2026-11-01']).toMatchObject({ articles: 0, minutes: 0, level: 0, frozen: false });
    expect(byDate['2026-11-02']).toMatchObject({ articles: 1, minutes: 9, level: 1 });
    expect(byDate['2026-11-03']).toMatchObject({ articles: 2, level: 2 });
    expect(byDate['2026-11-05']).toMatchObject({ articles: 4, level: 3 });
  });

  it('marks frozen days, but a day with a read is never frozen', () => {
    const grid = buildHeatmapGrid({
      from: '2026-11-01',
      to: '2026-11-03',
      days: [day('2026-11-01', 0, 0, true), day('2026-11-02', 1, 5, true)],
    });

    expect(grid.cells[0]).toMatchObject({ frozen: true, level: 0 });
    expect(grid.cells[1]).toMatchObject({ frozen: false, level: 1 });
    expect(grid.cells[2].frozen).toBe(false);
  });

  it('ignores days outside the range', () => {
    const grid = buildHeatmapGrid({ from: '2026-11-01', to: '2026-11-02', days: [day('2026-10-31', 3), day('2026-11-09', 3)] });
    expect(grid.cells.every((c) => c.articles === 0)).toBe(true);
  });

  it('returns an empty grid for an invalid or reversed range', () => {
    expect(buildHeatmapGrid({ from: 'nope', to: '2026-11-03', days: [] })).toEqual({ columns: 0, cells: [], months: [] });
    expect(buildHeatmapGrid({ from: '2026-11-04', to: '2026-11-03', days: [] }).cells).toHaveLength(0);
  });

  it('never lays out more than the 371 days the API serves', () => {
    const grid = buildHeatmapGrid({ from: '2020-01-01', to: '2026-11-03', days: [] });
    expect(grid.cells).toHaveLength(371);
    expect(grid.cells.at(-1)?.date).toBe('2026-11-03');
  });
});

describe('heatmapLevel', () => {
  it('maps 0 / 1 / 2 / 3+ articles to four levels', () => {
    expect([0, 1, 2, 3, 12].map(heatmapLevel)).toEqual([0, 1, 2, 3, 3]);
  });
});
