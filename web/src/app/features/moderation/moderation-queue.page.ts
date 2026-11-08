import { ChangeDetectionStrategy, Component, computed, effect, inject, input, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ModerationApi } from '../../core/api/moderation.api';
import { MODERATION_TARGET_TYPES, ModerationQueueItemDto, ModerationTargetType, REPORT_STATUSES, ReportStatus } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { ModerationSummaryStore } from '../../core/moderation/moderation-summary.store';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { RelativeTimePipe, translatePlural } from '../../shared/pipes/format.pipes';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { CursorList } from './cursor-list';
import { ModerationHeader, ReasonChips, TargetPreview, isTargetType } from './moderation-ui';

export const QUEUE_PAGE_SIZE = 20;

/**
 * The reports queue (F22), `/admin/reports?status=&type=` (the admin console, F23): Open / Resolved / Dismissed, filtered by type (All, Articles,
 * Comments, Users). One row per reported target: its preview, the reasons with their counts, how many reports and
 * when the last came (or when the case was closed); a row opens its case. Moderators only (route guard), rendered in
 * the browser; the URL keeps the tab and filter, so every view can be linked to.
 */
@Component({
  selector: 'rd-moderation-queue-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, RelativeTimePipe, EmptyState, ErrorState, ModerationHeader, ReasonChips, TargetPreview],
  providers: [provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pb-10 pt-5 lg:pt-8' },
  template: `
    <!-- One card: the title and tabs, the type filter, then the cases. -->
    <div class="rd-card overflow-clip shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
      <rd-moderation-header [active]="currentStatus()" [type]="currentType()" />

      <!-- Type filter -->
      <div class="flex gap-2 overflow-x-auto border-b border-border px-4 py-3 lg:px-5" role="toolbar" [attr.aria-label]="'moderation.types.label' | transloco" data-type-filter>
        <button type="button" class="rd-chip" [attr.aria-pressed]="!currentType()" data-type-chip="all" (click)="setType(null)">
          {{ 'moderation.types.all' | transloco }}
          @if (counts(); as c) {
            <span class="opacity-80 tabular-nums" aria-hidden="true">{{ c.total }}</span>
          }
        </button>
        @for (type of types; track type) {
          <button type="button" class="rd-chip" [attr.aria-pressed]="currentType() === type" [attr.data-type-chip]="type" (click)="setType(type)">
            {{ 'moderation.types.' + type | transloco }}
            @if (counts(); as c) {
              @if (countOf(c, type); as n) {
                <span class="opacity-80 tabular-nums" aria-hidden="true">{{ n }}</span>
              }
            }
          </button>
        }
      </div>

      <section [attr.aria-label]="'moderation.tabs.' + currentStatus() | transloco" aria-live="polite" data-moderation-queue>
        @switch (list.status()) {
          @case ('error') {
            <rd-error-state [message]="'moderation.loadError' | transloco" (retry)="list.load()" />
          }
          @case ('loaded') {
            @if (list.items().length) {
              <ol class="m-0 list-none divide-y divide-border p-0">
                @for (item of list.items(); track item.targetType + item.targetId) {
                  <li>
                    <a
                      [routerLink]="['/admin/reports', item.targetType, item.targetId]"
                      class="block px-4 py-4 text-inherit no-underline transition-colors hover:bg-surface-variant focus-visible:-outline-offset-2 lg:px-5"
                      [attr.data-case]="item.targetType + ':' + item.targetId"
                    >
                      <rd-target-preview [item]="item" [compact]="true" />
                      <rd-reason-chips class="mt-3" [reasons]="item.reasons" />
                      <p class="m-0 mt-3 flex flex-wrap items-center gap-x-2 text-xs text-text-secondary">
                        <span class="inline-flex items-center gap-1 font-semibold text-text-primary" data-report-count>
                          <svg lucideIcon="Flag" [size]="14" aria-hidden="true"></svg>{{ reportCount(item) }}
                        </span>
                        ·
                        @if (item.status === 'open' && item.ageHours !== null && item.ageHours !== undefined) {
                          <!-- F22 (store): every report is handled within 24 hours; 12 hours makes a case urgent -->
                          <span [class.font-semibold]="item.urgent" [class.text-error]="item.urgent" data-case-age>{{ ageLabel(item.ageHours) }}</span>
                          @if (item.urgent) {
                            <span class="rd-tag bg-callout-danger text-error" data-case-urgent>{{ 'moderation.urgent' | transloco }}</span>
                          }
                          ·
                        }
                        @if (item.closedAt && item.status !== 'open') {
                          <span>{{ 'moderation.closedAt' | transloco: { time: (item.closedAt | rdRelativeTime: lang()) } }}</span>
                        } @else {
                          <span>{{ 'moderation.lastReport' | transloco: { time: (item.lastReportedAt | rdRelativeTime: lang()) } }}</span>
                        }
                      </p>
                    </a>
                  </li>
                }
              </ol>
              @if (list.hasMore()) {
                <div class="border-t border-border p-3">
                  <button
                    type="button"
                    class="rd-btn rd-btn-outline w-full"
                    [disabled]="list.loadingMore()"
                    [attr.aria-busy]="list.loadingMore()"
                    data-queue-more
                    (click)="list.loadMore()"
                  >
                    {{ (list.moreFailed() ? 'common.retry' : 'moderation.more') | transloco }}
                  </button>
                </div>
              }
            } @else {
              <rd-empty-state
                [title]="'moderation.empty.' + currentStatus() + '.title' | transloco"
                [message]="'moderation.empty.' + currentStatus() + '.body' | transloco"
                data-queue-empty
              />
            }
          }
          @default {
            <div class="flex flex-col divide-y divide-border" aria-busy="true" data-queue-loading>
              @for (i of skeletons; track i) {
                <div class="flex flex-col gap-2 px-4 py-4 lg:px-5" aria-hidden="true">
                  <div class="rd-skeleton h-4 w-16"></div>
                  <div class="rd-skeleton h-5 w-4/5"></div>
                  <div class="rd-skeleton h-3 w-1/3"></div>
                </div>
              }
            </div>
          }
        }
      </section>
    </div>
  `,
})
export class ModerationQueuePage {
  private readonly api = inject(ModerationApi);
  private readonly router = inject(Router);
  private readonly transloco = inject(TranslocoService);
  private readonly summary = inject(ModerationSummaryStore);
  protected readonly lang = inject(LanguageService).lang;

  /** `?status=` and `?type=` (component input binding); anything else means Open / All. */
  readonly status = input<string | undefined>();
  readonly type = input<string | undefined>();

  protected readonly types = MODERATION_TARGET_TYPES;
  protected readonly skeletons = [1, 2, 3];
  protected readonly currentStatus = computed<ReportStatus>(() => (REPORT_STATUSES.includes(this.status() as ReportStatus) ? (this.status() as ReportStatus) : 'open'));
  protected readonly currentType = computed<ModerationTargetType | null>(() => (isTargetType(this.type()) ? (this.type() as ModerationTargetType) : null));
  /** Open targets per type, on the Open tab. */
  protected readonly counts = computed(() => (this.currentStatus() === 'open' ? this.summary.open() : null));

  protected readonly list = new CursorList<ModerationQueueItemDto>(
    (cursor) => this.api.queue({ status: this.currentStatus(), type: this.currentType(), cursor, limit: QUEUE_PAGE_SIZE }),
    (item) => `${item.targetType}:${item.targetId}`,
  );

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('moderation.title')} — ReadIn`);
    effect(() => {
      this.currentStatus();
      this.currentType();
      untracked(() => void this.list.load());
    });
    void this.summary.refresh();
  }

  protected setType(type: ModerationTargetType | null): void {
    void this.router.navigate(['/admin/reports'], { queryParams: { status: this.currentStatus() === 'open' ? null : this.currentStatus(), type }, replaceUrl: true });
  }

  /** A type's open count from the summary (reposts have none there yet). */
  protected countOf(counts: Record<string, number>, type: string): number | null {
    return counts[type] ?? null;
  }

  /** "Open for 5 hours": whole hours since the oldest open report. */
  protected ageLabel(hours: number): string {
    return translatePlural(this.transloco, 'moderation.age', hours, this.lang());
  }

  protected reportCount(item: ModerationQueueItemDto): string {
    return translatePlural(this.transloco, 'moderation.reportCount', item.reportCount, this.lang());
  }
}
