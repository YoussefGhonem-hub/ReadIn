import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  PLATFORM_ID,
  afterRenderEffect,
  computed,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ReadingHeatmapDto } from '../../core/api/models';
import { HEATMAP_DAYS, ReadingApi } from '../../core/api/reading.api';
import { LanguageService } from '../../core/i18n/language.service';
import { intlLocale, translatePlural } from '../../shared/pipes/format.pipes';
import { HeatmapLevel, buildHeatmapGrid } from './heatmap-grid';

/** Cell colors by level, from the design tokens (they follow light/dark). */
const LEVEL_CLASSES: Record<HeatmapLevel, string> = {
  0: 'bg-border',
  1: 'bg-primary/35',
  2: 'bg-primary/65',
  3: 'bg-primary',
};
const FROZEN_CLASS = 'bg-callout-info-accent';
const LEVELS: { level: HeatmapLevel; label: string }[] = [
  { level: 0, label: '0' },
  { level: 1, label: '1' },
  { level: 2, label: '2' },
  { level: 3, label: '3+' },
];

let nextId = 0;

/**
 * Reading heatmap (F08, F14): the last 12 months, GitHub-style, one column per week. Loads its own data
 * (`GET /me/stats/heatmap`, owner only), so it can sit on any page. The grid mirrors in RTL (time flows toward the
 * inline end) and opens scrolled to today.
 */
@Component({
  selector: 'rd-reading-heatmap',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section [attr.aria-labelledby]="titleId">
      <h3 [id]="titleId" class="m-0 mb-3 text-base font-semibold">{{ 'reading.heatmap.title' | transloco }}</h3>
      @switch (status()) {
        @case ('loaded') {
          @if (view(); as v) {
            <div
              #scroller
              class="overflow-x-auto pb-2"
              tabindex="0"
              role="group"
              [attr.aria-label]="'reading.heatmap.label' | transloco"
            >
              <div
                class="grid w-max gap-[3px]"
                [style.grid-template-columns]="'repeat(' + v.columns + ', 0.75rem)'"
                style="grid-template-rows: 1rem repeat(7, 0.75rem)"
              >
                @for (month of v.months; track month.date) {
                  <span
                    class="whitespace-nowrap text-[11px] leading-4 text-text-secondary"
                    [style.grid-column]="month.column + 1"
                    style="grid-row: 1"
                    aria-hidden="true"
                    >{{ month.label }}</span
                  >
                }
                @for (cell of v.cells; track cell.date) {
                  <span
                    class="rounded-[3px]"
                    [class]="cell.classes"
                    [style.grid-column]="cell.column + 1"
                    [style.grid-row]="cell.row + 2"
                    role="img"
                    [attr.aria-label]="cell.label"
                    [attr.title]="cell.label"
                  ></span>
                }
              </div>
            </div>
            <div class="mt-2 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-text-secondary">
              <span class="inline-flex items-center gap-1.5">
                {{ 'reading.heatmap.legend' | transloco }}
                @for (item of levels; track item.level) {
                  <span class="inline-flex items-center gap-1">
                    <span class="h-3 w-3 rounded-[3px]" [class]="levelClasses[item.level]" aria-hidden="true"></span>
                    <span dir="ltr">{{ item.label }}</span>
                  </span>
                }
              </span>
              <span class="inline-flex items-center gap-1">
                <span class="h-3 w-3 rounded-[3px]" [class]="frozenClass" aria-hidden="true"></span>
                ❄ {{ 'reading.heatmap.frozen' | transloco }}
              </span>
            </div>
          }
        }
        @case ('error') {
          <div class="flex flex-wrap items-center gap-3 rounded-md bg-callout-danger p-3 text-sm" role="alert">
            <span class="flex-1">{{ 'reading.heatmap.loadError' | transloco }}</span>
            <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="load()">
              <svg lucideIcon="RefreshCw" [size]="14" aria-hidden="true"></svg>
              {{ 'common.retry' | transloco }}
            </button>
          </div>
        }
        @default {
          <div class="rd-skeleton h-[124px] w-full" aria-busy="true"></div>
        }
      }
    </section>
  `,
})
export class ReadingHeatmap {
  private readonly api = inject(ReadingApi);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);

  protected readonly titleId = `rd-heatmap-title-${nextId++}`;
  protected readonly levels = LEVELS;
  protected readonly levelClasses = LEVEL_CLASSES;
  protected readonly frozenClass = FROZEN_CLASS;
  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  private readonly data = signal<ReadingHeatmapDto | null>(null);
  private readonly scroller = viewChild<ElementRef<HTMLElement>>('scroller');

  protected readonly view = computed(() => {
    const data = this.data();
    if (!data) return null;
    const lang = this.language.lang();
    // Weeks start on Saturday in Arabic and Sunday in English, like the mobile app (its MaterialLocalizations).
    const grid = buildHeatmapGrid(data, lang === 'ar' ? 6 : 0);
    const locale = intlLocale(lang);
    const dayFormat = new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'short', timeZone: 'UTC' });
    const monthFormat = new Intl.DateTimeFormat(locale, { month: 'short', timeZone: 'UTC' });
    return {
      columns: grid.columns,
      months: grid.months.map((month) => ({ ...month, label: monthFormat.format(new Date(`${month.date}T00:00:00Z`)) })),
      cells: grid.cells.map((cell) => {
        const date = dayFormat.format(new Date(`${cell.date}T00:00:00Z`));
        let label: string;
        if (cell.articles > 0) {
          label = this.transloco.translate(
            'reading.heatmap.cellRead',
            {
              date,
              articles: translatePlural(this.transloco, 'reading.articles', cell.articles, lang),
              minutes: translatePlural(this.transloco, 'reading.minutes', cell.minutes, lang),
            },
            lang,
          );
        } else {
          label = this.transloco.translate(cell.frozen ? 'reading.heatmap.cellFrozen' : 'reading.heatmap.cellEmpty', { date }, lang);
        }
        const today = cell.date === data.to ? ' ring-1 ring-text-secondary' : '';
        return { ...cell, label, classes: (cell.frozen ? FROZEN_CLASS : LEVEL_CLASSES[cell.level]) + today };
      }),
    };
  });

  constructor() {
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.load();

    // Open on the newest weeks. In RTL they are on the left, where scrollLeft is negative.
    let scrolledFor: HTMLElement | null = null;
    afterRenderEffect(() => {
      const el = this.scroller()?.nativeElement;
      if (!el || el === scrolledFor) return;
      scrolledFor = el;
      el.scrollLeft = this.language.dir() === 'rtl' ? -el.scrollWidth : el.scrollWidth;
    });
  }

  protected async load(): Promise<void> {
    this.status.set('loading');
    try {
      this.data.set(await firstValueFrom(this.api.heatmap(HEATMAP_DAYS)));
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
  }
}
