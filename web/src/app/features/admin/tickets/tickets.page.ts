import { ChangeDetectionStrategy, Component, computed, effect, inject, input, untracked } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AdminTicketRowDto, SUPPORT_CATEGORIES, SupportStatus } from '../../../core/api/models';
import { AdminTicketsQuery, SupportApi } from '../../../core/api/support.api';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ADMIN_CARD, ADMIN_PAGE_SIZE, AdminPageHeader, AdminPager, PagedState, oneOf, pageParam } from '../admin-ui';

const STATUSES: readonly SupportStatus[] = ['open', 'answered', 'closed'];

/**
 * Tickets (F35 in the console, `support.manage`), `/admin/tickets?status=open|answered|closed&category=&q=&page=`: Open
 * (waiting longest first), Answered and Closed, filtered by category and searched by subject, member or `#12`. Each row:
 * the member, the number and subject, the category, how long it has waited (or when it closed) and the last message;
 * internal notes are marked. A row opens the ticket.
 */
@Component({
  selector: 'rd-admin-tickets-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, RelativeTimePipe, Avatar, EmptyState, ErrorState, AdminPageHeader, AdminPager],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-tickets': '' },
  template: `
    <rd-admin-page-header [title]="'admin.nav.tickets' | transloco" [subtitle]="'admin.tickets.subtitle' | transloco" />
    <div [class]="card">
      <nav class="flex gap-5 border-b border-border px-4" [attr.aria-label]="'admin.tickets.tabs' | transloco" data-ticket-tabs>
        @for (s of statuses; track s) {
          <a
            routerLink="/admin/tickets"
            [queryParams]="{ status: s === 'open' ? null : s, category: query().category, q: query().q }"
            class="-mb-px inline-flex min-h-11 items-center border-b-2 px-1 text-sm no-underline"
            [class]="query().status === s ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
            [attr.aria-current]="query().status === s ? 'page' : null"
            [attr.data-ticket-tab]="s"
            >{{ 'support.statuses.' + s | transloco }}</a
          >
        }
      </nav>
      <form class="flex flex-wrap items-end gap-2 border-b border-border p-4 text-sm" role="search" (submit)="search($event, q.value)" data-ticket-filters>
        <label class="flex min-w-48 flex-1 flex-col gap-1">
          <span class="text-xs text-text-secondary">{{ 'admin.tickets.search' | transloco }}</span>
          <span class="flex gap-2">
            <input #q type="search" class="rd-input flex-1" dir="auto" maxlength="100" [value]="query().q ?? ''" [placeholder]="'admin.tickets.searchPlaceholder' | transloco" data-ticket-q />
            <button type="submit" class="rd-btn rd-btn-primary min-h-11 px-3" [attr.aria-label]="'admin.search' | transloco">
              <svg lucideIcon="Search" [size]="16" aria-hidden="true"></svg>
            </button>
          </span>
        </label>
        <label class="flex flex-col gap-1">
          <span class="text-xs text-text-secondary">{{ 'support.form.category' | transloco }}</span>
          <select class="rd-input min-h-10 py-1" [value]="query().category ?? ''" (change)="set({ category: $any($event.target).value })" data-filter="category">
            <option value="">{{ 'admin.all' | transloco }}</option>
            @for (c of categories; track c) {
              <option [value]="c">{{ 'support.categories.' + c | transloco }}</option>
            }
          </select>
        </label>
      </form>

      @switch (list.status()) {
        @case ('error') {
          <rd-error-state [message]="'admin.loadError' | transloco" (retry)="list.load()" />
        }
        @case ('loaded') {
          @if (list.items().length) {
            <ol class="m-0 list-none divide-y divide-border p-0" [attr.aria-busy]="list.refreshing()" data-admin-ticket-list>
              @for (t of list.items(); track t.id) {
                <li>
                  <a [routerLink]="['/admin/tickets', t.id]" class="flex gap-3 px-4 py-3 text-inherit no-underline hover:bg-surface-variant" [attr.data-admin-ticket]="t.id">
                    <rd-avatar [name]="t.user.displayName" [src]="t.user.avatarUrl" [size]="36" />
                    <span class="min-w-0 flex-1 text-sm">
                      <span class="flex flex-wrap items-center gap-x-2">
                        <span class="font-semibold"><rd-bdi-text [text]="t.user.displayName" /></span>
                        <bdi dir="ltr" class="text-xs text-text-secondary">&#64;{{ t.user.username }}</bdi>
                        <span class="rd-tag rd-tag-neutral">{{ 'support.categories.' + t.category | transloco }}</span>
                      </span>
                      <span class="mt-0.5 block font-semibold"><bdi dir="ltr" class="text-text-secondary">#{{ t.number }}</bdi> · <bdi dir="auto">{{ t.subject }}</bdi></span>
                      <span class="mt-0.5 line-clamp-1 block text-text-secondary">
                        @if (t.lastMessage.isInternalNote) {
                          <span class="font-semibold">{{ 'admin.tickets.note' | transloco }}:</span>
                        } @else if (t.lastMessage.fromSupport) {
                          <span class="font-semibold">{{ 'support.supportTeam' | transloco }}:</span>
                        }
                        <bdi dir="auto">{{ t.lastMessage.excerpt }}</bdi>
                      </span>
                    </span>
                    <span class="shrink-0 text-end text-xs text-text-secondary" data-ticket-when>
                      @if (t.waitingSince; as since) {
                        <span class="font-semibold text-text-primary">{{ 'admin.tickets.waiting' | transloco: { time: (since | rdRelativeTime: lang()) } }}</span>
                      } @else if (t.closedAt; as closed) {
                        {{ 'admin.tickets.closedAt' | transloco: { time: (closed | rdRelativeTime: lang()) } }}
                      } @else {
                        <time [attr.datetime]="t.lastMessage.createdAt">{{ t.lastMessage.createdAt | rdRelativeTime: lang() }}</time>
                      }
                    </span>
                  </a>
                </li>
              }
            </ol>
            <rd-admin-pager [page]="list.page()" [totalPages]="list.totalPages()" [totalCount]="list.totalCount()" (pageChange)="goTo($event)" />
          } @else {
            <rd-empty-state [title]="'admin.tickets.empty.' + query().status | transloco" data-admin-tickets-empty />
          }
        }
        @default {
          <div class="flex flex-col gap-3 p-4" aria-busy="true" data-admin-tickets-loading>
            @for (i of [1, 2, 3]; track i) {
              <div class="rd-skeleton h-14 w-full" aria-hidden="true"></div>
            }
          </div>
        }
      }
    </div>
  `,
})
export class AdminTicketsPage {
  private readonly api = inject(SupportApi);
  private readonly router = inject(Router);
  protected readonly lang = inject(LanguageService).lang;

  readonly status = input<string | undefined>();
  readonly category = input<string | undefined>();
  readonly q = input<string | undefined>();
  readonly page = input<string | undefined>();

  protected readonly card = ADMIN_CARD;
  protected readonly statuses = STATUSES;
  protected readonly categories = SUPPORT_CATEGORIES;
  protected readonly query = computed<Required<Pick<AdminTicketsQuery, 'status'>> & AdminTicketsQuery>(() => ({
    status: oneOf(this.status(), STATUSES) ?? 'open',
    category: oneOf(this.category(), SUPPORT_CATEGORIES),
    q: this.q()?.trim() || null,
    page: pageParam(this.page()),
    pageSize: ADMIN_PAGE_SIZE,
  }));
  protected readonly list = new PagedState<AdminTicketRowDto>(() => this.api.adminTickets(this.query()));

  constructor() {
    effect(() => {
      this.query();
      untracked(() => void this.list.load());
    });
  }

  protected search(event: Event, q: string): void {
    event.preventDefault();
    this.set({ q: q.trim() });
  }

  protected set(change: Record<string, string | null>): void {
    const queryParams: Record<string, string | null> = { page: null };
    for (const [key, value] of Object.entries(change)) queryParams[key] = value || null;
    void this.router.navigate(['/admin/tickets'], { queryParams, queryParamsHandling: 'merge' });
  }

  protected goTo(page: number): void {
    void this.router.navigate(['/admin/tickets'], { queryParams: { page: page > 1 ? page : null }, queryParamsHandling: 'merge' });
  }
}
