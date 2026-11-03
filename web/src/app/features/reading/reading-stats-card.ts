import { ChangeDetectionStrategy, Component, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ReadingStatsDto, StreakDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { FieldIcon } from '../../shared/ui/field-icon';
import { StreakStore } from './streak.store';

export type FreezeStatus = 'pending' | 'available' | 'later';

/** Which freeze line the streak shows: one is about to be used, one is ready, or the next one comes later. */
export function freezeStatus(streak: Pick<StreakDto, 'freezeAvailable' | 'freezePending'>): FreezeStatus {
  if (streak.freezePending) return 'pending';
  return streak.freezeAvailable ? 'available' : 'later';
}

/** `FieldDto.color` is a design token name ("primary", "callout-info-accent"); anything else falls back to primary. */
export function fieldColor(token: string): string {
  return `var(--rd-color-${/^[a-z][a-z-]*$/.test(token) ? token : 'primary'})`;
}

/**
 * Reading stats card (F08, F14): the streak with its freeze status, the last 7 and 30 days, totals and top fields.
 * Loads its own data (`GET /me/stats`, owner only), so it can sit on any page, and hands the fresh streak to the badge.
 */
@Component({
  selector: 'rd-reading-stats-card',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText, PluralPipe, FieldIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @switch (status()) {
      @case ('loaded') {
        @if (stats(); as s) {
          <!-- Streak -->
          <div class="flex items-start gap-3 rounded-card bg-accent-container p-4">
            <span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-surface text-accent" aria-hidden="true">
              <svg lucideIcon="Flame" [size]="26"></svg>
            </span>
            <div class="min-w-0 flex-1">
              <p class="m-0 text-xs font-semibold text-text-secondary">{{ 'reading.stats.currentStreak' | transloco }}</p>
              <p class="m-0 text-2xl font-bold leading-tight">{{ s.streak.current | rdPlural: 'reading.days' : lang() }}</p>
              <p class="m-0 mt-1 text-xs text-text-secondary">
                {{ 'reading.stats.longest' | transloco: { days: (s.streak.longest | rdPlural: 'reading.days' : lang()) } }}
              </p>
            </div>
          </div>
          <ul class="m-0 mt-3 flex list-none flex-col gap-1.5 p-0 text-sm">
            <li class="flex items-start gap-2">
              @if (s.streak.readToday) {
                <svg lucideIcon="CircleCheck" [size]="16" class="mt-0.5 shrink-0 text-success" aria-hidden="true"></svg>
                {{ 'reading.stats.readToday' | transloco }}
              } @else {
                <svg lucideIcon="BookOpen" [size]="16" class="mt-0.5 shrink-0 text-text-secondary" aria-hidden="true"></svg>
                {{ (s.streak.current > 0 ? 'reading.stats.keepStreak' : 'reading.stats.startStreak') | transloco }}
              }
            </li>
            @if (s.streak.current > 0) {
              <li class="flex items-start gap-2" [class.font-semibold]="freeze() === 'pending'">
                <span class="mt-px w-4 shrink-0 text-center text-callout-info-accent" aria-hidden="true">❄</span>
                {{ 'reading.stats.freeze.' + freeze() | transloco }}
              </li>
            }
          </ul>

          <!-- Last 7 / 30 days and all time -->
          <dl class="m-0 mt-4 grid grid-cols-3 gap-2">
            <div class="rounded-md border border-border p-3">
              <dt class="text-xs text-text-secondary">{{ 'reading.stats.week' | transloco }}</dt>
              <dd class="m-0 mt-1 text-sm font-semibold">{{ s.articlesThisWeek | rdPlural: 'reading.articles' : lang() }}</dd>
              <dd class="m-0 text-xs text-text-secondary">{{ s.minutesThisWeek | rdPlural: 'reading.minutes' : lang() }}</dd>
            </div>
            <div class="rounded-md border border-border p-3">
              <dt class="text-xs text-text-secondary">{{ 'reading.stats.month' | transloco }}</dt>
              <dd class="m-0 mt-1 text-sm font-semibold">{{ s.articlesThisMonth | rdPlural: 'reading.articles' : lang() }}</dd>
            </div>
            <div class="rounded-md border border-border p-3">
              <dt class="text-xs text-text-secondary">{{ 'reading.stats.total' | transloco }}</dt>
              <dd class="m-0 mt-1 text-sm font-semibold">{{ s.totalArticles | rdPlural: 'reading.articles' : lang() }}</dd>
              <dd class="m-0 text-xs text-text-secondary">{{ s.minutesRead | rdPlural: 'reading.minutes' : lang() }}</dd>
            </div>
          </dl>

          <!-- Top fields -->
          <h3 class="m-0 mb-2 mt-5 text-sm font-semibold">{{ 'reading.stats.topFields' | transloco }}</h3>
          @if (s.topFields.length) {
            <ul class="m-0 flex list-none flex-wrap gap-2 p-0">
              @for (field of s.topFields; track field.id) {
                <li
                  class="inline-flex min-h-9 items-center gap-1.5 rounded-chip border border-border px-3 text-sm"
                  [style.background-color]="'color-mix(in srgb, ' + color(field.color) + ' 14%, transparent)'"
                >
                  <span class="inline-flex" [style.color]="color(field.color)"><rd-field-icon [name]="field.icon" [size]="16" /></span>
                  <rd-bdi-text [text]="field.name" />
                  <span class="text-xs text-text-secondary">· {{ field.articles | rdPlural: 'reading.articles' : lang() }}</span>
                </li>
              }
            </ul>
          } @else {
            <p class="m-0 text-sm text-text-secondary">{{ 'reading.stats.noReads' | transloco }}</p>
          }
        }
      }
      @case ('error') {
        <div class="flex flex-wrap items-center gap-3 rounded-md bg-callout-danger p-3 text-sm" role="alert">
          <span class="flex-1">{{ 'reading.stats.loadError' | transloco }}</span>
          <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="load()">
            <svg lucideIcon="RefreshCw" [size]="14" aria-hidden="true"></svg>
            {{ 'common.retry' | transloco }}
          </button>
        </div>
      }
      @default {
        <div class="flex flex-col gap-3" aria-busy="true">
          <div class="rd-skeleton h-20 w-full"></div>
          <div class="rd-skeleton h-4 w-3/4"></div>
          <div class="grid grid-cols-3 gap-2">
            <div class="rd-skeleton h-16"></div>
            <div class="rd-skeleton h-16"></div>
            <div class="rd-skeleton h-16"></div>
          </div>
        </div>
      }
    }
  `,
})
export class ReadingStatsCard {
  private readonly api = inject(ReadingApi);
  private readonly streaks = inject(StreakStore);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly stats = signal<ReadingStatsDto | null>(null);
  protected readonly freeze = computed(() => {
    const stats = this.stats();
    return stats ? freezeStatus(stats.streak) : 'later';
  });
  protected readonly color = fieldColor;

  constructor() {
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.load();
  }

  protected async load(): Promise<void> {
    this.status.set('loading');
    try {
      const stats = await firstValueFrom(this.api.stats());
      this.stats.set(stats);
      this.status.set('loaded');
      this.streaks.setStreak(stats.streak);
    } catch {
      this.status.set('error');
    }
  }
}
