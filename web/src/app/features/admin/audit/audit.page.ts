import { ChangeDetectionStrategy, Component, computed, effect, inject, input, untracked } from '@angular/core';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AdminApi, AdminAuditQuery } from '../../../core/api/admin.api';
import { AuditEntryDto } from '../../../core/api/models';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ADMIN_CARD, ADMIN_PAGE_SIZE, AdminPageHeader, AdminPager, PagedState, dateParam, oneOf, pageParam } from '../admin-ui';
import { AuditEntry } from './audit-entry';

const SOURCES = ['audit', 'moderation'] as const;
/** Quick filters: a prefix that ends in "." matches every code under it (contract). */
export const AUDIT_PREFIXES = ['admin.', 'moderation.', 'auth.', 'user.'] as const;

/**
 * The audit log (F23, `audit.read`, web only), `/admin/audit?actor=&target=&action=&source=&from=&to=&page=`: the audit
 * entries and the moderation log in one list, newest first, 50 a page, filtered by who did it, whom it concerns, the
 * action (an exact code or a prefix ending in "."), the source and dates. IP addresses show only with `users.read.pii`.
 */
@Component({
  selector: 'rd-admin-audit-page',
  imports: [TranslocoPipe, LucideDynamicIcon, EmptyState, ErrorState, AdminPageHeader, AdminPager, AuditEntry],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-audit': '' },
  template: `
    <rd-admin-page-header [title]="'admin.nav.audit' | transloco" [subtitle]="'admin.audit.subtitle' | transloco" />
    <div [class]="card">
      <form class="flex flex-col gap-3 border-b border-border p-4 text-sm" role="search" (submit)="search($event, action.value)" data-audit-filters>
        <div class="flex flex-wrap items-end gap-2">
          <label class="flex min-w-48 flex-1 flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.audit.action' | transloco }}</span>
            <span class="flex gap-2">
              <input #action type="search" class="rd-input flex-1" dir="ltr" maxlength="64" [value]="query().action ?? ''" placeholder="admin.pii_viewed" data-audit-action />
              <button type="submit" class="rd-btn rd-btn-primary min-h-11 px-3" [attr.aria-label]="'admin.search' | transloco">
                <svg lucideIcon="Search" [size]="16" aria-hidden="true"></svg>
              </button>
            </span>
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.audit.source' | transloco }}</span>
            <select class="rd-input min-h-10 py-1" [value]="query().source ?? ''" (change)="set({ source: $any($event.target).value })" data-filter="source">
              <option value="">{{ 'admin.all' | transloco }}</option>
              @for (s of sources; track s) {
                <option [value]="s">{{ 'admin.audit.sources.' + s | transloco }}</option>
              }
            </select>
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.content.from' | transloco }}</span>
            <input type="date" class="rd-input min-h-10 py-1" dir="ltr" [value]="query().from ?? ''" (change)="set({ from: $any($event.target).value })" data-filter="from" />
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.content.to' | transloco }}</span>
            <input type="date" class="rd-input min-h-10 py-1" dir="ltr" [value]="query().to ?? ''" (change)="set({ to: $any($event.target).value })" data-filter="to" />
          </label>
        </div>
        <div class="flex flex-wrap gap-2" role="toolbar" [attr.aria-label]="'admin.audit.prefixes' | transloco">
          @for (p of prefixes; track p) {
            <button type="button" class="rd-chip" [attr.aria-pressed]="query().action === p" (click)="set({ action: query().action === p ? null : p })" [attr.data-prefix]="p">
              <bdi dir="ltr">{{ p }}*</bdi>
            </button>
          }
        </div>
        @if (query().actor || query().target) {
          <p class="m-0 flex flex-wrap items-center gap-2" data-audit-people>
            @if (query().actor; as actor) {
              <span class="rd-tag rd-tag-neutral gap-1.5">{{ 'admin.audit.byActor' | transloco }} <bdi dir="ltr">{{ actor }}</bdi></span>
              <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2" (click)="set({ actor: null })">{{ 'admin.clear' | transloco }}</button>
            }
            @if (query().target; as target) {
              <span class="rd-tag rd-tag-neutral gap-1.5">{{ 'admin.audit.aboutTarget' | transloco }} <bdi dir="ltr">{{ target }}</bdi></span>
              <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2" (click)="set({ target: null })">{{ 'admin.clear' | transloco }}</button>
            }
          </p>
        }
      </form>

      @switch (list.status()) {
        @case ('error') {
          <rd-error-state [message]="'admin.loadError' | transloco" (retry)="list.load()" />
        }
        @case ('loaded') {
          @if (list.items().length) {
            <ol class="m-0 list-none divide-y divide-border p-0" [attr.aria-busy]="list.refreshing()" data-audit-list>
              @for (entry of list.items(); track entry.source + entry.id) {
                <li class="px-4"><rd-audit-entry [entry]="entry" /></li>
              }
            </ol>
            <rd-admin-pager [page]="list.page()" [totalPages]="list.totalPages()" [totalCount]="list.totalCount()" (pageChange)="goTo($event)" />
          } @else {
            <rd-empty-state [title]="'admin.audit.empty' | transloco" [message]="'admin.emptyFilters' | transloco" data-audit-empty />
          }
        }
        @default {
          <div class="flex flex-col gap-3 p-4" aria-busy="true" data-audit-loading>
            @for (i of [1, 2, 3, 4]; track i) {
              <div class="rd-skeleton h-12 w-full" aria-hidden="true"></div>
            }
          </div>
        }
      }
    </div>
  `,
})
export class AdminAuditPage {
  private readonly api = inject(AdminApi);
  private readonly router = inject(Router);

  readonly actor = input<string | undefined>();
  readonly target = input<string | undefined>();
  readonly action = input<string | undefined>();
  readonly source = input<string | undefined>();
  readonly from = input<string | undefined>();
  readonly to = input<string | undefined>();
  readonly page = input<string | undefined>();

  protected readonly card = ADMIN_CARD;
  protected readonly sources = SOURCES;
  protected readonly prefixes = AUDIT_PREFIXES;

  protected readonly query = computed<AdminAuditQuery>(() => ({
    actor: this.actor() || null,
    target: this.target() || null,
    action: this.action()?.trim() || null,
    source: oneOf(this.source(), SOURCES),
    from: dateParam(this.from()),
    to: dateParam(this.to()),
    page: pageParam(this.page()),
    pageSize: ADMIN_PAGE_SIZE,
  }));
  protected readonly list = new PagedState<AuditEntryDto>(() => this.api.audit(this.query()));

  constructor() {
    effect(() => {
      this.query();
      untracked(() => void this.list.load());
    });
  }

  protected search(event: Event, action: string): void {
    event.preventDefault();
    this.set({ action: action.trim() });
  }

  protected set(change: Record<string, string | null>): void {
    const queryParams: Record<string, string | null> = { page: null };
    for (const [key, value] of Object.entries(change)) queryParams[key] = value || null;
    void this.router.navigate(['/admin/audit'], { queryParams, queryParamsHandling: 'merge' });
  }

  protected goTo(page: number): void {
    void this.router.navigate(['/admin/audit'], { queryParams: { page: page > 1 ? page : null }, queryParamsHandling: 'merge' });
  }
}
