import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi } from '../../../core/api/admin.api';
import { ADMIN_PERIODS, AdminDashboardDto, AdminPeriod, DashboardDayDto } from '../../../core/api/models';
import { LanguageService, UiLanguage } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { intlLocale, translatePlural } from '../../../shared/pipes/intl';
import { urlLangFor } from '../../../shared/ui/article-link';
import { Avatar } from '../../../shared/ui/avatar';
import { SegmentOption, Segmented } from '../../../shared/ui/segmented';
import { ErrorState } from '../../../shared/ui/states';
import { ADMIN_CARD, AdminPageHeader, oneOf } from '../admin-ui';
import { ChartPoint, DashboardChart } from './dashboard-chart';
import { provideAdminIcons } from '../admin-icons';

export interface Change {
  delta: number;
  /** Null when the previous period had nothing (no percentage of zero). */
  percent: number | null;
  direction: 'up' | 'down' | 'flat';
}

/** The change from the previous period of the same length. */
export function changeOf(value: number, previous: number): Change {
  const delta = value - previous;
  return {
    delta,
    // Rounded half away from zero, so a rise and a fall of the same size read the same.
    percent: previous > 0 ? Math.sign(delta) * Math.round(Math.abs(delta / previous) * 100) : null,
    direction: delta > 0 ? 'up' : delta < 0 ? 'down' : 'flat',
  };
}

/** "+12 (+20%)" / "−3 (−50%)" / "0", Western digits in both languages. */
export function formatChange(change: Change, lang: UiLanguage): string {
  const signed = new Intl.NumberFormat(intlLocale(lang), { signDisplay: 'exceptZero' });
  const delta = signed.format(change.delta);
  return change.percent === null || change.delta === 0 ? delta : `${delta} (${signed.format(change.percent)}%)`;
}

type ValueCard = 'articlesPublished' | 'newUsers' | 'activeReaders' | 'reads' | 'comments' | 'reactions' | 'reposts';
const VALUE_CARDS: readonly ValueCard[] = ['articlesPublished', 'newUsers', 'activeReaders', 'reads', 'comments', 'reactions', 'reposts'];
const CHARTS: readonly (keyof Omit<DashboardDayDto, 'date'>)[] = ['newUsers', 'activeReaders', 'articlesPublished'];

type State = { status: 'loading' } | { status: 'loaded'; data: AdminDashboardDto } | { status: 'error' };

/**
 * The console's dashboard (F23), `/admin?period=today|yesterday|7d|30d`: the period switch, a card per number with its
 * change from the previous period ("Articles published" opens Content for the period), the queues right now (each
 * opening its section), the last 30 days as three small bar charts, the top articles and writers, the searches that
 * found nothing, streak retention and the content pipeline. No personal data. The server caches it for 60 seconds.
 */
@Component({
  selector: 'rd-admin-dashboard-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, Avatar, RelativeTimePipe, LocalizedDatePipe, Segmented, ErrorState, AdminPageHeader, DashboardChart],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-dashboard': '' },
  styles: `
    .cards {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 0.5rem;
    }
    @media (width >= 64rem) {
      .cards {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }
    }
    .charts,
    .lists {
      display: grid;
      gap: 0.5rem;
    }
    @media (width >= 48rem) {
      .charts {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }
    }
    @media (width >= 64rem) {
      .lists {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }
  `,
  template: `
    <rd-admin-page-header [title]="'admin.nav.dashboard' | transloco" [subtitle]="subtitle()">
      <rd-segmented class="w-full sm:w-auto" [options]="periodOptions()" [value]="currentPeriod()" (valueChange)="setPeriod($event)" [label]="'admin.dashboard.period' | transloco" />
    </rd-admin-page-header>

    @switch (state().status) {
      @case ('error') {
        <div [class]="card"><rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" /></div>
      }
      @case ('loaded') {
        @let d = data()!;
        <section class="cards" [attr.aria-label]="'admin.dashboard.numbers' | transloco">
          @for (key of valueCards; track key) {
            @let v = d.cards[key];
            @let change = changeOf(v.value, v.previous);
            <div [class]="card + ' flex flex-col gap-1 p-4'" [attr.data-card]="key">
              @if (key === 'articlesPublished') {
                <a routerLink="/admin/content" [queryParams]="{ from: d.fromDate, to: d.toDate }" class="text-sm text-link no-underline hover:underline">{{
                  'admin.dashboard.cards.' + key | transloco
                }}</a>
              } @else {
                <span class="text-sm text-text-secondary">{{ 'admin.dashboard.cards.' + key | transloco }}</span>
              }
              <span class="text-2xl font-bold tabular-nums" data-card-value>{{ number(v.value) }}</span>
              <span class="flex items-center gap-1 text-xs text-text-secondary" [attr.data-change]="change.direction">
                @if (change.direction !== 'flat') {
                  <svg [lucideIcon]="change.direction === 'up' ? 'TrendingUp' : 'TrendingDown'" [size]="14" [class]="change.direction === 'up' ? 'text-success' : 'text-error'" aria-hidden="true"></svg>
                }
                <bdi dir="ltr" class="tabular-nums">{{ formatChange(change) }}</bdi>
                <span>{{ 'admin.dashboard.vsPrevious' | transloco }}</span>
              </span>
              @if (key === 'newUsers') {
                <span class="text-xs text-text-secondary" data-signup-split>
                  {{ 'admin.signIn.phone' | transloco }} {{ number(d.cards.newUsers.phone) }} · Google {{ number(d.cards.newUsers.google) }} · Apple {{ number(d.cards.newUsers.apple) }}
                </span>
              }
            </div>
          }
          <a [class]="card + ' flex flex-col gap-1 p-4 text-inherit no-underline hover:bg-surface-variant'" routerLink="/admin/users" [queryParams]="{ status: 'suspended' }" data-card="suspendedNow">
            <span class="text-sm text-text-secondary">{{ 'admin.dashboard.cards.suspendedNow' | transloco }}</span>
            <span class="text-2xl font-bold tabular-nums">{{ number(d.cards.suspendedNow) }}</span>
            <span class="text-xs text-text-secondary">{{ 'admin.dashboard.now' | transloco }}</span>
          </a>
        </section>

        <!-- The queues right now: each opens its section -->
        @if (queues().length) {
          <section class="cards mt-2" [attr.aria-label]="'admin.dashboard.queues' | transloco">
            @for (q of queues(); track q.key) {
              <a [class]="card + ' flex items-center gap-3 p-4 text-inherit no-underline hover:bg-surface-variant'" [routerLink]="q.path" [attr.data-queue]="q.key">
                <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
                  <svg [lucideIcon]="q.icon" [size]="18"></svg>
                </span>
                <span class="min-w-0 flex-1">
                  <span class="block text-sm text-text-secondary">{{ 'admin.dashboard.cards.' + q.key | transloco }}</span>
                  <span class="block text-xl font-bold tabular-nums">{{ number(q.value) }}</span>
                </span>
              </a>
            }
          </section>
        }

        <!-- The last 30 days -->
        <section class="charts mt-2" [attr.aria-label]="'admin.dashboard.last30' | transloco">
          @for (key of charts; track key) {
            <div [class]="card + ' p-4'" [attr.data-chart]="key">
              <h2 class="m-0 mb-1 text-sm font-semibold">{{ 'admin.dashboard.charts.' + key | transloco }}</h2>
              <p class="m-0 mb-2 text-xs text-text-secondary">{{ 'admin.dashboard.last30' | transloco }} · {{ number(chartTotal(key)) }}</p>
              <rd-dashboard-chart [points]="chartPoints(key)" [label]="'admin.dashboard.charts.' + key | transloco" [lang]="lang()" />
            </div>
          }
        </section>

        <div class="lists mt-2">
          <!-- Top articles -->
          <section [class]="card" aria-labelledby="top-articles">
            <h2 id="top-articles" class="m-0 px-4 pb-2 pt-4 text-base font-semibold">{{ 'admin.dashboard.topArticles' | transloco }}</h2>
            @if (d.topArticles.length) {
              <ol class="m-0 list-none divide-y divide-border p-0" data-top-articles>
                @for (a of d.topArticles; track a.id; let i = $index) {
                  <li class="flex items-center gap-3 px-4 py-2.5 text-sm">
                    <span class="w-5 shrink-0 text-center tabular-nums text-text-secondary">{{ i + 1 }}</span>
                    <span class="min-w-0 flex-1">
                      <a [routerLink]="['/' + urlLang(a.language), 'a', a.slug]" class="line-clamp-2 font-semibold text-text-primary no-underline hover:underline" [attr.lang]="a.language" [attr.dir]="a.language === 'ar-EG' ? 'rtl' : 'ltr'">
                        <rd-bdi-text [text]="a.title" />
                      </a>
                      <span class="block truncate text-xs text-text-secondary">
                        @if (a.author; as author) {
                          <rd-bdi-text [text]="author.displayName" />
                        } @else {
                          {{ 'common.deletedUser' | transloco }}
                        }
                        · {{ lang() === 'ar' ? a.field.nameAr : a.field.nameEn }}
                      </span>
                    </span>
                    <span class="shrink-0 tabular-nums text-text-secondary">{{ readsLabel(a.reads) }}</span>
                  </li>
                }
              </ol>
            } @else {
              <p class="m-0 px-4 pb-4 text-sm text-text-secondary">{{ 'admin.dashboard.noReads' | transloco }}</p>
            }
          </section>

          <!-- Top writers -->
          <section [class]="card" aria-labelledby="top-writers">
            <h2 id="top-writers" class="m-0 px-4 pb-2 pt-4 text-base font-semibold">{{ 'admin.dashboard.topWriters' | transloco }}</h2>
            @if (d.topWriters.length) {
              <ol class="m-0 list-none divide-y divide-border p-0" data-top-writers>
                @for (w of d.topWriters; track w.writer.id) {
                  <li class="flex items-center gap-3 px-4 py-2.5 text-sm">
                    <rd-avatar [name]="w.writer.displayName" [src]="w.writer.avatarUrl" [size]="32" />
                    <a [routerLink]="'/@' + w.writer.username" class="min-w-0 flex-1 text-text-primary no-underline hover:underline">
                      <span class="block truncate font-semibold"><rd-bdi-text [text]="w.writer.displayName" /></span>
                      <bdi dir="ltr" class="block truncate text-xs text-text-secondary">&#64;{{ w.writer.username }}</bdi>
                    </a>
                    <span class="shrink-0 text-end text-xs text-text-secondary">
                      <span class="block text-sm tabular-nums text-text-primary">{{ readsLabel(w.reads) }}</span>
                      {{ articlesReadLabel(w.articles) }}
                    </span>
                  </li>
                }
              </ol>
            } @else {
              <p class="m-0 px-4 pb-4 text-sm text-text-secondary">{{ 'admin.dashboard.noReads' | transloco }}</p>
            }
          </section>

          <!-- Searches with no results -->
          <section [class]="card" aria-labelledby="missed-searches">
            <h2 id="missed-searches" class="m-0 px-4 pt-4 text-base font-semibold">{{ 'admin.dashboard.missedSearches' | transloco }}</h2>
            <p class="m-0 px-4 pb-2 text-xs text-text-secondary">{{ 'admin.dashboard.missedSearchesHint' | transloco }}</p>
            @if (d.missedSearches.length) {
              <ol class="m-0 flex list-none flex-wrap gap-1.5 px-4 pb-4" data-missed-searches>
                @for (m of d.missedSearches; track m.language + m.query) {
                  <li class="rd-tag rd-tag-neutral gap-1.5">
                    <bdi dir="auto">{{ m.query }}</bdi>
                    <span class="tabular-nums text-text-secondary">{{ m.count }}</span>
                  </li>
                }
              </ol>
            } @else {
              <p class="m-0 px-4 pb-4 text-sm text-text-secondary">{{ 'admin.dashboard.noMissedSearches' | transloco }}</p>
            }
          </section>

          <!-- Streak retention and the content pipeline -->
          <section [class]="card + ' p-4'" aria-labelledby="retention">
            <h2 id="retention" class="m-0 text-base font-semibold">{{ 'admin.dashboard.retention' | transloco }}</h2>
            <p class="m-0 mt-1 text-xs text-text-secondary">{{ 'admin.dashboard.retentionHint' | transloco }}</p>
            @if (d.streakRetention.rate !== null) {
              <p class="m-0 mt-2 text-2xl font-bold tabular-nums" data-retention-rate>{{ percent(d.streakRetention.rate) }}</p>
              <p class="m-0 text-sm text-text-secondary">{{ 'admin.dashboard.retentionOf' | transloco: { kept: d.streakRetention.kept, cohort: d.streakRetention.cohort } }}</p>
            } @else {
              <p class="m-0 mt-2 text-sm text-text-secondary" data-retention-empty>{{ 'admin.dashboard.retentionEmpty' | transloco }}</p>
            }

            <h2 class="m-0 mt-5 text-base font-semibold">{{ 'admin.dashboard.pipeline' | transloco }}</h2>
            <dl class="m-0 mt-2 grid grid-cols-2 gap-x-4 gap-y-1 text-sm" data-pipeline>
              <dt class="text-text-secondary">{{ 'admin.dashboard.pipelineFolders' | transloco }}</dt>
              <dd class="m-0 tabular-nums">{{ number(d.contentPipeline.folders) }}</dd>
              <dt class="text-text-secondary">{{ 'admin.dashboard.pipelineSeeded' | transloco }}</dt>
              <dd class="m-0 tabular-nums">{{ number(d.contentPipeline.seeded) }}</dd>
              <dt class="text-text-secondary">{{ 'admin.dashboard.pipelinePublished' | transloco }}</dt>
              <dd class="m-0 tabular-nums">{{ number(d.contentPipeline.published) }}</dd>
              <dt class="text-text-secondary">{{ 'admin.dashboard.pipelineLastRun' | transloco }}</dt>
              <dd class="m-0">
                @if (d.contentPipeline.lastSeedRunAt; as at) {
                  <time [attr.datetime]="at" [title]="at | rdDate: lang() : 'long'">{{ at | rdRelativeTime: lang() }}</time>
                } @else {
                  —
                }
              </dd>
            </dl>
          </section>
        </div>
      }
      @default {
        <div class="cards" aria-busy="true" data-dashboard-loading>
          @for (i of skeletons; track i) {
            <div [class]="card + ' flex flex-col gap-2 p-4'" aria-hidden="true">
              <div class="rd-skeleton h-4 w-2/3"></div>
              <div class="rd-skeleton h-7 w-1/3"></div>
              <div class="rd-skeleton h-3 w-1/2"></div>
            </div>
          }
        </div>
      }
    }
  `,
})
export class AdminDashboardPage {
  private readonly api = inject(AdminApi);
  private readonly router = inject(Router);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  /** `?period=` (component input binding). */
  readonly period = input<string | undefined>();

  protected readonly card = ADMIN_CARD;
  protected readonly valueCards = VALUE_CARDS;
  protected readonly charts = CHARTS;
  protected readonly skeletons = [1, 2, 3, 4, 5, 6, 7, 8];
  protected readonly changeOf = changeOf;
  protected readonly urlLang = urlLangFor;

  protected readonly state = signal<State>({ status: 'loading' });
  protected readonly data = computed(() => {
    const s = this.state();
    return s.status === 'loaded' ? s.data : null;
  });
  protected readonly currentPeriod = computed<AdminPeriod>(() => oneOf(this.period(), ADMIN_PERIODS) ?? 'today');
  protected readonly periodOptions = computed<SegmentOption<AdminPeriod>[]>(() => {
    this.lang();
    return ADMIN_PERIODS.map((p) => ({ value: p, label: this.transloco.translate(`admin.dashboard.periods.${p}`) }));
  });
  protected readonly subtitle = computed(() => {
    const d = this.data();
    if (!d) return null;
    return this.transloco.translate('admin.dashboard.subtitle', { zone: d.timeZone, from: d.fromDate, to: d.toDate });
  });
  /** Open reports, open tickets and pending requests, for the permissions that see them. */
  protected readonly queues = computed(() => {
    const c = this.data()?.cards;
    if (!c) return [];
    const all = [
      { key: 'openReports', value: c.openReports, path: '/admin/reports', icon: 'Flag' },
      { key: 'openTickets', value: c.openTickets, path: '/admin/tickets', icon: 'LifeBuoy' },
      { key: 'pendingVerifications', value: c.pendingVerifications, path: '/admin/verification', icon: 'BadgeCheck' },
    ];
    return all.filter((q): q is typeof q & { value: number } => q.value !== null);
  });

  constructor() {
    effect(() => {
      this.currentPeriod();
      untracked(() => void this.load());
    });
  }

  async load(): Promise<void> {
    const period = this.currentPeriod();
    if (this.state().status !== 'loaded') this.state.set({ status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.dashboard(period));
      if (period === this.currentPeriod()) this.state.set({ status: 'loaded', data });
    } catch {
      if (period === this.currentPeriod()) this.state.set({ status: 'error' });
    }
  }

  protected setPeriod(period: AdminPeriod): void {
    void this.router.navigate(['/admin'], { queryParams: { period: period === 'today' ? null : period }, replaceUrl: true });
  }

  protected chartPoints(key: (typeof CHARTS)[number]): ChartPoint[] {
    return (this.data()?.charts ?? []).map((day) => ({ date: day.date, value: day[key] }));
  }

  protected chartTotal(key: (typeof CHARTS)[number]): number {
    return (this.data()?.charts ?? []).reduce((sum, day) => sum + day[key], 0);
  }

  protected number(value: number): string {
    return new Intl.NumberFormat(intlLocale(this.lang())).format(value);
  }

  protected percent(rate: number): string {
    return new Intl.NumberFormat(intlLocale(this.lang()), { style: 'percent', maximumFractionDigits: 1 }).format(rate);
  }

  protected formatChange(change: Change): string {
    return formatChange(change, this.lang());
  }

  protected readsLabel(reads: number): string {
    return translatePlural(this.transloco, 'admin.dashboard.reads', reads, this.lang());
  }

  protected articlesReadLabel(count: number): string {
    return translatePlural(this.transloco, 'admin.dashboard.articlesRead', count, this.lang());
  }
}
