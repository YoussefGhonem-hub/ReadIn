import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { UiLanguage } from '../../../core/i18n/language.service';
import { intlLocale } from '../../../shared/pipes/intl';

export interface ChartPoint {
  /** "YYYY-MM-DD". */
  date: string;
  value: number;
}

const WIDTH = 300;
const HEIGHT = 72;
const GAP = 2;

/** "7 Nov" / "7 نوفمبر" for a local "YYYY-MM-DD" (read as UTC, so the day never shifts). */
export function shortDate(date: string, lang: UiLanguage): string {
  const d = new Date(`${date}T00:00:00Z`);
  return Number.isNaN(d.getTime()) ? date : new Intl.DateTimeFormat(intlLocale(lang), { day: 'numeric', month: 'short', timeZone: 'UTC' }).format(d);
}

/**
 * One 30-day series of the dashboard (F23) as small bars: one per day, oldest first, the brand color, 2 px apart with
 * rounded tops on a recessive baseline. A single series, so the card's title names it (no legend). Each bar has its day
 * and value as a tooltip (`<title>`), and a visually hidden table carries every point for screen readers. Inline SVG,
 * no chart library.
 */
@Component({
  selector: 'rd-dashboard-chart',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  styles: `
    .bar {
      fill: var(--rd-color-primary);
    }
    .bar:hover {
      fill: var(--rd-color-accent);
    }
    .base {
      stroke: var(--rd-color-border);
    }
  `,
  template: `
    <svg [attr.viewBox]="'0 0 ' + width + ' ' + (height + 1)" class="block h-20 w-full" preserveAspectRatio="none" dir="ltr" aria-hidden="true" data-chart-bars>
      @for (bar of bars(); track bar.date) {
        <path class="bar" [attr.d]="bar.d" [attr.data-chart-bar]="bar.date"><title>{{ bar.label }}</title></path>
      }
      <line class="base" x1="0" [attr.y1]="height + 0.5" [attr.x2]="width" [attr.y2]="height + 0.5" stroke-width="1" />
    </svg>
    <div class="mt-1 flex justify-between text-xs text-text-secondary" dir="ltr" aria-hidden="true">
      <span>{{ first() }}</span><span>{{ last() }}</span>
    </div>
    <table class="sr-only">
      <caption>{{ label() }}</caption>
      <tbody>
        @for (point of points(); track point.date) {
          <tr>
            <th scope="row">{{ point.date }}</th>
            <td>{{ point.value }}</td>
          </tr>
        }
      </tbody>
    </table>
  `,
})
export class DashboardChart {
  readonly points = input.required<ChartPoint[]>();
  /** What the series is ("New users"), for the hidden table. */
  readonly label = input.required<string>();
  readonly lang = input.required<UiLanguage>();

  protected readonly width = WIDTH;
  protected readonly height = HEIGHT;

  protected readonly bars = computed(() => {
    const points = this.points();
    if (!points.length) return [];
    const max = Math.max(1, ...points.map((p) => p.value));
    const slot = WIDTH / points.length;
    const barWidth = Math.max(1, slot - GAP);
    const radius = Math.min(2, barWidth / 2);
    return points.map((p, i) => {
      const x = i * slot + GAP / 2;
      // A zero day still shows a 1 px stub on the baseline, so the axis reads as 30 days.
      const h = p.value > 0 ? Math.max(2, (p.value / max) * HEIGHT) : 1;
      const y = HEIGHT - h;
      const r = p.value > 0 ? Math.min(radius, h) : 0;
      const d = `M${x},${HEIGHT} V${y + r} Q${x},${y} ${x + r},${y} H${x + barWidth - r} Q${x + barWidth},${y} ${x + barWidth},${y + r} V${HEIGHT} Z`;
      return { date: p.date, d, label: `${shortDate(p.date, this.lang())}: ${p.value}` };
    });
  });
  protected readonly first = computed(() => {
    const p = this.points();
    return p.length ? shortDate(p[0].date, this.lang()) : '';
  });
  protected readonly last = computed(() => {
    const p = this.points();
    return p.length ? shortDate(p[p.length - 1].date, this.lang()) : '';
  });
}
