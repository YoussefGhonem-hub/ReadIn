import { ReadingHeatmapDto } from '../../core/api/models';

/** 0, 1, 2 and 3+ articles a day. */
export type HeatmapLevel = 0 | 1 | 2 | 3;

export interface HeatmapCell {
  /** "yyyy-MM-dd". */
  date: string;
  articles: number;
  minutes: number;
  /** A missed day covered by a streak freeze. */
  frozen: boolean;
  level: HeatmapLevel;
  /** Week column, oldest first. */
  column: number;
  /** Day row, 0 = the first day of the week. */
  row: number;
}

export interface HeatmapMonth {
  /** The week column holding the month's first day. */
  column: number;
  /** "yyyy-MM-01". */
  date: string;
}

export interface HeatmapGrid {
  /** Number of week columns. */
  columns: number;
  /** Every day from `from` to `to`, oldest first. */
  cells: HeatmapCell[];
  /** Months whose first day is in the range, for the labels above the grid. */
  months: HeatmapMonth[];
}

const DAY_MS = 86_400_000;
/** The API returns at most 371 days (53 weeks). */
const MAX_DAYS = 371;
const EMPTY_GRID: HeatmapGrid = { columns: 0, cells: [], months: [] };

export function heatmapLevel(articles: number): HeatmapLevel {
  return articles >= 3 ? 3 : articles <= 0 ? 0 : (articles as 1 | 2);
}

/**
 * Lays out the reading heatmap (F08) GitHub-style: one column per week and one row per weekday, from `from` to `to`
 * (the user's local today). The API lists only days with a read or a freeze; every other day is empty. Dates are
 * calendar dates, so they're computed in UTC and never shift with the device's time zone.
 *
 * @param weekStart the first row's weekday, 0 = Sunday … 6 = Saturday.
 */
export function buildHeatmapGrid(heatmap: Pick<ReadingHeatmapDto, 'from' | 'to' | 'days'>, weekStart = 0): HeatmapGrid {
  const to = parseDate(heatmap.to);
  let from = parseDate(heatmap.from);
  if (to === null || from === null || from > to) return EMPTY_GRID;
  from = Math.max(from, to - (MAX_DAYS - 1) * DAY_MS);

  const byDate = new Map(heatmap.days.map((day) => [day.date, day]));
  const lead = (new Date(from).getUTCDay() - weekStart + 7) % 7;
  const cells: HeatmapCell[] = [];
  const months: HeatmapMonth[] = [];

  for (let time = from, index = lead; time <= to; time += DAY_MS, index++) {
    const date = formatDate(time);
    const day = byDate.get(date);
    const articles = Math.max(0, day?.articles ?? 0);
    const column = Math.floor(index / 7);
    cells.push({
      date,
      articles,
      minutes: Math.max(0, day?.minutes ?? 0),
      frozen: articles === 0 && (day?.frozen ?? false),
      level: heatmapLevel(articles),
      column,
      row: index % 7,
    });
    if (new Date(time).getUTCDate() === 1) months.push({ column, date });
  }

  return { columns: cells.length ? cells[cells.length - 1].column + 1 : 0, cells, months };
}

/** "yyyy-MM-dd" → UTC midnight in ms, or null. */
function parseDate(value: string): number | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return null;
  const time = Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  return Number.isNaN(time) ? null : time;
}

function formatDate(time: number): string {
  return new Date(time).toISOString().slice(0, 10);
}
