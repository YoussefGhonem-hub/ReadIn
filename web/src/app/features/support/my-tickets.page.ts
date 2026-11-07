import { ChangeDetectionStrategy, Component, computed, effect, inject, input, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SupportTicketSummaryDto } from '../../core/api/models';
import { SupportApi } from '../../core/api/support.api';
import { LanguageService } from '../../core/i18n/language.service';
import { RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { CursorList } from '../moderation/cursor-list';
import { TicketStatus } from './support-ui';

const TABS = ['all', 'active', 'closed'] as const;
type Tab = (typeof TABS)[number];
export const MY_TICKETS_PAGE_SIZE = 20;

/**
 * My tickets (F35), `/support/tickets?status=active|closed`: your tickets, latest activity first, 20 at a time: the
 * number and subject, the category, the status, and the last message (from Support or you). A row opens the ticket.
 * Signed in only (route guard), rendered in the browser.
 */
@Component({
  selector: 'rd-my-tickets-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, RelativeTimePipe, EmptyState, ErrorState, TicketStatus],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pb-10 pt-5 lg:pt-8', 'data-my-tickets-page': '' },
  template: `
    <div class="rd-card overflow-clip shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
      <header class="flex flex-wrap items-center justify-between gap-2 px-4 pt-4 lg:px-5 lg:pt-5">
        <div>
          <a routerLink="/support" class="inline-flex min-h-9 items-center gap-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-support>
            <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
            {{ 'support.title' | transloco }}
          </a>
          <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'support.myTickets' | transloco }}</h1>
        </div>
        <a routerLink="/support" class="rd-btn rd-btn-primary min-h-11 px-4" data-new-ticket-link>
          <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
          {{ 'support.newTicket' | transloco }}
        </a>
      </header>
      <nav class="mt-3 flex gap-5 border-b border-border px-4 lg:px-5" [attr.aria-label]="'support.tabsLabel' | transloco" data-ticket-tabs>
        @for (t of tabs; track t) {
          <a
            routerLink="/support/tickets"
            [queryParams]="t === 'all' ? {} : { status: t }"
            class="-mb-px inline-flex min-h-11 items-center border-b-2 px-1 text-sm no-underline"
            [class]="tab() === t ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
            [attr.aria-current]="tab() === t ? 'page' : null"
            [attr.data-ticket-tab]="t"
            >{{ 'support.tabs.' + t | transloco }}</a
          >
        }
      </nav>

      @switch (list.status()) {
        @case ('error') {
          <rd-error-state [message]="'support.loadError' | transloco" (retry)="list.load()" />
        }
        @case ('loaded') {
          @if (list.items().length) {
            <ol class="m-0 list-none divide-y divide-border p-0" data-tickets>
              @for (t of list.items(); track t.id) {
                <li>
                  <a [routerLink]="['/support/tickets', t.id]" class="block px-4 py-3 text-inherit no-underline hover:bg-surface-variant lg:px-5" [attr.data-ticket]="t.id">
                    <p class="m-0 flex flex-wrap items-center gap-2">
                      <bdi dir="ltr" class="text-sm text-text-secondary">#{{ t.number }}</bdi>
                      <span class="min-w-0 flex-1 font-semibold" dir="auto">{{ t.subject }}</span>
                      <rd-ticket-status [status]="t.status" />
                    </p>
                    <p class="m-0 mt-1 line-clamp-1 text-sm text-text-secondary">
                      <span class="font-semibold">{{ (t.lastMessage.fromSupport ? 'support.fromSupport' : 'support.fromYou') | transloco }}:</span>
                      <bdi dir="auto">{{ t.lastMessage.excerpt }}</bdi>
                    </p>
                    <p class="m-0 mt-1 text-xs text-text-secondary">
                      {{ 'support.categories.' + t.category | transloco }} ·
                      <time [attr.datetime]="t.updatedAt">{{ t.updatedAt | rdRelativeTime: lang() }}</time>
                    </p>
                  </a>
                </li>
              }
            </ol>
            @if (list.hasMore()) {
              <div class="border-t border-border p-3">
                <button type="button" class="rd-btn rd-btn-outline w-full" [disabled]="list.loadingMore()" (click)="list.loadMore()" data-tickets-more>
                  {{ (list.moreFailed() ? 'common.retry' : 'support.more') | transloco }}
                </button>
              </div>
            }
          } @else {
            <rd-empty-state [title]="'support.empty.' + tab() | transloco" [message]="'support.emptyBody' | transloco" data-tickets-empty />
          }
        }
        @default {
          <div class="flex flex-col gap-3 p-4" aria-busy="true" data-tickets-loading>
            @for (i of [1, 2, 3]; track i) {
              <div class="rd-skeleton h-14 w-full" aria-hidden="true"></div>
            }
          </div>
        }
      }
    </div>
  `,
})
export class MyTicketsPage {
  private readonly api = inject(SupportApi);
  protected readonly lang = inject(LanguageService).lang;

  /** `?status=` (component input binding). */
  readonly status = input<string | undefined>();

  protected readonly tabs = TABS;
  protected readonly tab = computed<Tab>(() => (this.status() === 'active' || this.status() === 'closed' ? (this.status() as Tab) : 'all'));
  protected readonly list = new CursorList<SupportTicketSummaryDto>(
    (cursor) => this.api.mine(this.tab() === 'all' ? null : (this.tab() as 'active' | 'closed'), cursor, MY_TICKETS_PAGE_SIZE),
    (t) => t.id,
  );

  constructor() {
    effect(() => {
      this.tab();
      untracked(() => void this.list.load());
    });
  }
}
