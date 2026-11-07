import { ChangeDetectionStrategy, Component, computed, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Observable, firstValueFrom } from 'rxjs';
import { PagedList } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../../shared/pipes/intl';
import { BottomSheet } from '../../shared/ui/bottom-sheet';

/** Rows of an admin table page (contract: default 50, at most 100). */
export const ADMIN_PAGE_SIZE = 50;

/** A card of the console: flush with the screen's edges on phones, like the app's other pages. */
export const ADMIN_CARD = 'rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0';

/**
 * The console's tables: real `<table>`s from `md` up; below it each row becomes a stacked card whose cells show their
 * column name (`data-label`), so a phone never scrolls sideways. A cell marked `.cell-main` (the row's name) spans the
 * card without a label.
 */
export const ADMIN_TABLE_STYLES = `
  .admin-table { width: 100%; border-collapse: collapse; font-size: 0.875rem; }
  .admin-table th { text-align: start; font-weight: 600; font-size: 0.75rem; color: var(--rd-color-text-secondary); padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--rd-color-border); white-space: nowrap; }
  .admin-table td { padding: 0.625rem 0.75rem; border-bottom: 1px solid var(--rd-color-border); vertical-align: middle; }
  .admin-table tbody tr:hover { background: var(--rd-color-surface-variant); }
  .admin-table .num { text-align: end; font-variant-numeric: tabular-nums; white-space: nowrap; }
  @media (width < 48rem) {
    .admin-table thead { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }
    .admin-table, .admin-table tbody, .admin-table tr, .admin-table td { display: block; width: 100%; }
    .admin-table tr { padding: 0.5rem 0; border-bottom: 1px solid var(--rd-color-border); }
    .admin-table td { border: 0; padding: 0.2rem 1rem; display: flex; justify-content: space-between; align-items: center; gap: 1rem; text-align: end; }
    .admin-table td[data-label]::before { content: attr(data-label); color: var(--rd-color-text-secondary); font-size: 0.75rem; text-align: start; }
    .admin-table td.cell-main { display: block; text-align: start; }
  }
`;

export type PagedStatus = 'loading' | 'loaded' | 'error';

/**
 * One page of an admin table (offset pages, §17.1). `load` fetches the page the caller's query describes; a newer load
 * wins over a slower older one. While a page reloads, the rows on screen stay (`refreshing`).
 */
export class PagedState<T> {
  private readonly _items = signal<T[]>([]);
  private readonly _status = signal<PagedStatus>('loading');
  private readonly _refreshing = signal(false);
  private readonly _page = signal(1);
  private readonly _totalPages = signal(0);
  private readonly _totalCount = signal(0);
  private generation = 0;

  readonly items = this._items.asReadonly();
  readonly status = this._status.asReadonly();
  readonly refreshing = this._refreshing.asReadonly();
  readonly page = this._page.asReadonly();
  readonly totalPages = this._totalPages.asReadonly();
  readonly totalCount = this._totalCount.asReadonly();

  constructor(private readonly fetch: () => Observable<PagedList<T>>) {}

  async load(): Promise<void> {
    const generation = ++this.generation;
    if (this._status() === 'loaded') this._refreshing.set(true);
    else this._status.set('loading');
    try {
      const page = await firstValueFrom(this.fetch());
      if (generation !== this.generation) return;
      this._items.set(page.items);
      this._page.set(page.page);
      this._totalPages.set(page.totalPages);
      this._totalCount.set(page.totalCount);
      this._status.set('loaded');
    } catch {
      if (generation === this.generation) this._status.set('error');
    } finally {
      if (generation === this.generation) this._refreshing.set(false);
    }
  }

  /** Replaces a row in place (after an action), matched by `match`. */
  update(match: (item: T) => boolean, change: (item: T) => T): void {
    this._items.update((items) => items.map((item) => (match(item) ? change(item) : item)));
  }
}

/** A positive page number from the URL (`?page=`), else 1. */
export function pageParam(value: string | undefined | null): number {
  const page = Number(value);
  return Number.isInteger(page) && page > 1 ? page : 1;
}

/** A `YYYY-MM-DD` date from the URL, else null. */
export function dateParam(value: string | undefined | null): string | null {
  return value && /^\d{4}-\d{2}-\d{2}$/.test(value) ? value : null;
}

/** `true` / `false` from the URL, else null. */
export function boolParam(value: string | undefined | null): boolean | null {
  return value === 'true' ? true : value === 'false' ? false : null;
}

/** The value when it is one of `allowed`, else null. */
export function oneOf<T extends string>(value: string | undefined | null, allowed: readonly T[]): T | null {
  return allowed.includes(value as T) ? (value as T) : null;
}

/** The console page's heading: its title, a line about it, and its actions at the end. */
@Component({
  selector: 'rd-admin-page-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mb-3 flex flex-wrap items-end justify-between gap-3' },
  template: `
    <div class="min-w-0">
      <h1 class="m-0 text-xl font-bold lg:text-2xl" data-admin-title>{{ title() }}</h1>
      @if (subtitle()) {
        <p class="m-0 mt-1 text-sm text-text-secondary">{{ subtitle() }}</p>
      }
    </div>
    <div class="flex flex-wrap gap-2"><ng-content /></div>
  `,
})
export class AdminPageHeader {
  readonly title = input.required<string>();
  readonly subtitle = input<string | null>(null);
}

/** "Page 2 of 7 · 312 results" with Previous / Next. Hidden while everything fits on one page. */
@Component({
  selector: 'rd-admin-pager',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-wrap items-center justify-between gap-2 px-4 py-3 text-sm text-text-secondary', 'data-admin-pager': '' },
  template: `
    <span aria-live="polite" data-pager-count>{{ countLabel() }}</span>
    @if (totalPages() > 1) {
      <nav class="flex items-center gap-2" [attr.aria-label]="'admin.pager.label' | transloco">
        <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3" [disabled]="page() <= 1" (click)="pageChange.emit(page() - 1)" data-pager-prev>
          <svg lucideIcon="ChevronRight" [size]="16" class="ltr:rotate-180" aria-hidden="true"></svg>
          {{ 'admin.pager.previous' | transloco }}
        </button>
        <span class="tabular-nums" data-pager-page>{{ 'admin.pager.page' | transloco: { page: page(), pages: totalPages() } }}</span>
        <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3" [disabled]="page() >= totalPages()" (click)="pageChange.emit(page() + 1)" data-pager-next>
          {{ 'admin.pager.next' | transloco }}
          <svg lucideIcon="ChevronLeft" [size]="16" class="ltr:rotate-180" aria-hidden="true"></svg>
        </button>
      </nav>
    }
  `,
})
export class AdminPager {
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;

  readonly page = input.required<number>();
  readonly totalPages = input.required<number>();
  readonly totalCount = input.required<number>();
  readonly pageChange = output<number>();

  protected readonly countLabel = computed(() => translatePlural(this.transloco, 'admin.pager.results', this.totalCount(), this.lang()));
}

/**
 * A confirmation (SPEC §14.4: the title is a question, «إلغاء» / «موافق»). The page runs the action on `confirm` and
 * keeps the dialog open with `busy` until it is done; `error` shows a failure inside it.
 */
@Component({
  selector: 'rd-admin-confirm',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" role="alertdialog" labelledBy="admin-confirm-title" describedBy="admin-confirm-body" [dismissible]="!busy()" (closed)="cancel()">
      @if (open()) {
        <div class="flex flex-col gap-3 pt-1" data-admin-confirm>
          <h2 id="admin-confirm-title" class="m-0 pe-10 text-xl font-semibold">{{ title() }}</h2>
          <p id="admin-confirm-body" class="m-0 whitespace-pre-line text-sm text-text-secondary">{{ body() }}</p>
          <ng-content />
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-confirm-error>{{ error() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="cancel()" data-confirm-cancel>{{ 'common.cancel' | transloco }}</button>
            <button
              type="button"
              class="rd-btn flex-1"
              [class]="danger() ? 'bg-error text-on-error' : 'rd-btn-primary'"
              [disabled]="busy() || disabled()"
              [attr.aria-busy]="busy()"
              (click)="confirmed.emit()"
              data-confirm-ok
            >
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'admin.confirm.ok' | transloco }}
            </button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class AdminConfirm {
  readonly open = input(false);
  readonly title = input.required<string>();
  readonly body = input('');
  readonly danger = input(false);
  readonly busy = input(false);
  /** The confirm button stays off (e.g. until a required choice is made). */
  readonly disabled = input(false);
  readonly error = input<string | null>(null);
  readonly confirmed = output<void>();
  readonly closed = output<void>();

  protected cancel(): void {
    if (!this.busy()) this.closed.emit();
  }
}
