import { ChangeDetectionStrategy, Component, computed, effect, inject, input, untracked } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AdminApi, AdminUsersQuery } from '../../../core/api/admin.api';
import { AdminUserRowDto, SIGN_IN_METHODS } from '../../../core/api/models';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { VerifiedBadge } from '../../../shared/ui/verified-badge';
import { ADMIN_CARD, ADMIN_PAGE_SIZE, ADMIN_TABLE_STYLES, AdminPageHeader, AdminPager, PagedState, boolParam, dateParam, oneOf, pageParam } from '../admin-ui';
import { SignInMethods, UserStatus } from './user-bits';
import { provideAdminIcons } from '../admin-icons';

const STATUSES = ['active', 'suspended'] as const;
const SORTS = ['joined', 'lastSeen', 'followers', 'openReports'] as const;
const DIRS = ['desc', 'asc'] as const;

/**
 * Users (F23), `/admin/users?q=&status=&verified=&method=&joinedFrom=&joinedTo=&hasReports=&sort=&dir=&page=`: every
 * account, 50 a page, with its sign-in methods, the masked phone number, when it joined and was last seen, its
 * published articles, followers, Verified, status and open reports. Search by name, @username or (with
 * `users.read.pii`) an exact phone number; filter and sort; the URL keeps it all, so every view can be linked to. A row
 * opens the user's page.
 */
@Component({
  selector: 'rd-admin-users-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, Avatar, VerifiedBadge, LocalizedDatePipe, RelativeTimePipe, EmptyState, ErrorState, AdminPageHeader, AdminPager, SignInMethods, UserStatus],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-users': '' },
  styles: ADMIN_TABLE_STYLES,
  template: `
    <rd-admin-page-header [title]="'admin.nav.users' | transloco" [subtitle]="'admin.users.subtitle' | transloco" />

    <div [class]="card">
      <!-- Search and filters -->
      <form class="flex flex-col gap-3 border-b border-border p-4" role="search" (submit)="search($event, q.value)" data-users-filters>
        <div class="flex gap-2">
          <label for="users-q" class="sr-only">{{ 'admin.users.search' | transloco }}</label>
          <input
            #q
            id="users-q"
            type="search"
            class="rd-input flex-1"
            dir="auto"
            maxlength="100"
            [value]="query().q ?? ''"
            [placeholder]="'admin.users.searchPlaceholder' | transloco"
            data-users-q
          />
          <button type="submit" class="rd-btn rd-btn-primary min-h-11 px-4">
            <svg lucideIcon="Search" [size]="16" aria-hidden="true"></svg>
            {{ 'admin.search' | transloco }}
          </button>
        </div>
        <div class="flex flex-wrap items-end gap-2 text-sm">
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.users.status' | transloco }}</span>
            <select class="rd-input min-h-10 py-1" [value]="query().status ?? ''" (change)="set({ status: $any($event.target).value })" data-filter="status">
              <option value="">{{ 'admin.all' | transloco }}</option>
              @for (s of statuses; track s) {
                <option [value]="s">{{ 'admin.users.statuses.' + s | transloco }}</option>
              }
            </select>
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.users.verified' | transloco }}</span>
            <select class="rd-input min-h-10 py-1" [value]="boolValue(query().verified)" (change)="set({ verified: $any($event.target).value })" data-filter="verified">
              <option value="">{{ 'admin.all' | transloco }}</option>
              <option value="true">{{ 'admin.yes' | transloco }}</option>
              <option value="false">{{ 'admin.no' | transloco }}</option>
            </select>
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.users.method' | transloco }}</span>
            <select class="rd-input min-h-10 py-1" [value]="query().method ?? ''" (change)="set({ method: $any($event.target).value })" data-filter="method">
              <option value="">{{ 'admin.all' | transloco }}</option>
              @for (m of methods; track m) {
                <option [value]="m">{{ 'admin.signIn.' + m | transloco }}</option>
              }
            </select>
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.users.joinedFrom' | transloco }}</span>
            <input type="date" class="rd-input min-h-10 py-1" dir="ltr" [value]="query().joinedFrom ?? ''" (change)="set({ joinedFrom: $any($event.target).value })" data-filter="joinedFrom" />
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.users.joinedTo' | transloco }}</span>
            <input type="date" class="rd-input min-h-10 py-1" dir="ltr" [value]="query().joinedTo ?? ''" (change)="set({ joinedTo: $any($event.target).value })" data-filter="joinedTo" />
          </label>
          <label class="flex min-h-10 items-center gap-2">
            <input type="checkbox" class="h-4 w-4" [checked]="query().hasReports === true" (change)="set({ hasReports: $any($event.target).checked ? 'true' : '' })" data-filter="hasReports" />
            {{ 'admin.users.hasReports' | transloco }}
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-xs text-text-secondary">{{ 'admin.sortBy' | transloco }}</span>
            <select class="rd-input min-h-10 py-1" [value]="query().sort ?? 'joined'" (change)="set({ sort: $any($event.target).value })" data-filter="sort">
              @for (s of sorts; track s) {
                <option [value]="s">{{ 'admin.users.sorts.' + s | transloco }}</option>
              }
            </select>
          </label>
          <button
            type="button"
            class="rd-btn rd-btn-outline min-h-10 px-3"
            [attr.aria-label]="(query().dir === 'asc' ? 'admin.ascending' : 'admin.descending') | transloco"
            [title]="(query().dir === 'asc' ? 'admin.ascending' : 'admin.descending') | transloco"
            (click)="set({ dir: query().dir === 'asc' ? 'desc' : 'asc' })"
            data-filter="dir"
          >
            <svg [lucideIcon]="query().dir === 'asc' ? 'ArrowUp' : 'ArrowDown'" [size]="16" aria-hidden="true"></svg>
          </button>
        </div>
      </form>

      @switch (list.status()) {
        @case ('error') {
          <rd-error-state [message]="'admin.loadError' | transloco" (retry)="list.load()" />
        }
        @case ('loaded') {
          @if (list.items().length) {
            <table class="admin-table" [attr.aria-busy]="list.refreshing()" data-users-table>
              <thead>
                <tr>
                  <th scope="col">{{ 'admin.users.columns.user' | transloco }}</th>
                  <th scope="col">{{ 'admin.users.columns.signIn' | transloco }}</th>
                  <th scope="col">{{ 'admin.users.columns.joined' | transloco }}</th>
                  <th scope="col">{{ 'admin.users.columns.lastSeen' | transloco }}</th>
                  <th scope="col" class="num">{{ 'admin.users.columns.articles' | transloco }}</th>
                  <th scope="col" class="num">{{ 'admin.users.columns.followers' | transloco }}</th>
                  <th scope="col">{{ 'admin.users.columns.status' | transloco }}</th>
                  <th scope="col" class="num">{{ 'admin.users.columns.reports' | transloco }}</th>
                </tr>
              </thead>
              <tbody>
                @for (u of list.items(); track u.id) {
                  <tr [attr.data-user-row]="u.id">
                    <td class="cell-main">
                      <a [routerLink]="['/admin/users', u.id]" class="flex min-w-0 items-center gap-2.5 text-text-primary no-underline hover:underline">
                        <rd-avatar [name]="u.displayName" [src]="u.avatarUrl" [size]="32" />
                        <span class="min-w-0">
                          <span class="flex items-center gap-1 font-semibold">
                            <rd-bdi-text class="truncate" [text]="u.displayName" />
                            @if (u.isVerified) {
                              <rd-verified-badge [size]="14" />
                            }
                          </span>
                          <bdi dir="ltr" class="block truncate text-xs text-text-secondary">&#64;{{ u.username }}</bdi>
                        </span>
                      </a>
                      @if (u.isSystemAccount) {
                        <span class="rd-tag rd-tag-neutral mt-1">{{ 'admin.users.system' | transloco }}</span>
                      }
                    </td>
                    <td [attr.data-label]="'admin.users.columns.signIn' | transloco">
                      <rd-sign-in-methods [methods]="u.signInMethods" [phone]="u.phoneMasked" />
                    </td>
                    <td [attr.data-label]="'admin.users.columns.joined' | transloco">
                      <time [attr.datetime]="u.joinedAt">{{ u.joinedAt | rdDate: lang() }}</time>
                    </td>
                    <td [attr.data-label]="'admin.users.columns.lastSeen' | transloco">
                      @if (u.lastSeenAt; as seen) {
                        <time [attr.datetime]="seen" [title]="seen | rdDate: lang() : 'long'">{{ seen | rdRelativeTime: lang() }}</time>
                      } @else {
                        <span class="text-text-secondary">{{ 'admin.users.neverSeen' | transloco }}</span>
                      }
                    </td>
                    <td class="num" [attr.data-label]="'admin.users.columns.articles' | transloco">{{ u.publishedArticles }}</td>
                    <td class="num" [attr.data-label]="'admin.users.columns.followers' | transloco">{{ u.followers }}</td>
                    <td [attr.data-label]="'admin.users.columns.status' | transloco"><rd-user-status [status]="u.status" [until]="u.suspendedUntil" /></td>
                    <td class="num" [attr.data-label]="'admin.users.columns.reports' | transloco">
                      @if (u.openReports > 0) {
                        <span class="font-semibold text-error">{{ u.openReports }}</span>
                      } @else {
                        0
                      }
                    </td>
                  </tr>
                }
              </tbody>
            </table>
            <rd-admin-pager [page]="list.page()" [totalPages]="list.totalPages()" [totalCount]="list.totalCount()" (pageChange)="goTo($event)" />
          } @else {
            <rd-empty-state [title]="'admin.users.empty' | transloco" [message]="'admin.emptyFilters' | transloco" data-users-empty />
          }
        }
        @default {
          <div class="flex flex-col gap-3 p-4" aria-busy="true" data-users-loading>
            @for (i of skeletons; track i) {
              <div class="flex items-center gap-3" aria-hidden="true">
                <div class="rd-skeleton h-8 w-8 rounded-full"></div>
                <div class="rd-skeleton h-4 flex-1"></div>
              </div>
            }
          </div>
        }
      }
    </div>
  `,
})
export class AdminUsersPage {
  private readonly api = inject(AdminApi);
  private readonly router = inject(Router);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly transloco = inject(TranslocoService);

  // `?…` (component input binding)
  readonly q = input<string | undefined>();
  readonly status = input<string | undefined>();
  readonly verified = input<string | undefined>();
  readonly method = input<string | undefined>();
  readonly joinedFrom = input<string | undefined>();
  readonly joinedTo = input<string | undefined>();
  readonly hasReports = input<string | undefined>();
  readonly sort = input<string | undefined>();
  readonly dir = input<string | undefined>();
  readonly page = input<string | undefined>();

  protected readonly card = ADMIN_CARD;
  protected readonly statuses = STATUSES;
  protected readonly methods = SIGN_IN_METHODS;
  protected readonly sorts = SORTS;
  protected readonly skeletons = [1, 2, 3, 4, 5];

  /** The query the URL describes (unknown values dropped). */
  protected readonly query = computed<AdminUsersQuery>(() => ({
    q: this.q()?.trim() || null,
    status: oneOf(this.status(), STATUSES),
    verified: boolParam(this.verified()),
    method: oneOf(this.method(), SIGN_IN_METHODS),
    joinedFrom: dateParam(this.joinedFrom()),
    joinedTo: dateParam(this.joinedTo()),
    hasReports: this.hasReports() === 'true' ? true : null,
    sort: oneOf(this.sort(), SORTS),
    dir: oneOf(this.dir(), DIRS),
    page: pageParam(this.page()),
    pageSize: ADMIN_PAGE_SIZE,
  }));

  protected readonly list = new PagedState<AdminUserRowDto>(() => this.api.users(this.query()));

  constructor() {
    effect(() => {
      this.query();
      untracked(() => void this.list.load());
    });
  }

  protected boolValue(value: boolean | null | undefined): string {
    return value === true ? 'true' : value === false ? 'false' : '';
  }

  protected search(event: Event, q: string): void {
    event.preventDefault();
    this.set({ q: q.trim() });
  }

  /** Changes filters (an empty value removes one) and goes back to the first page. */
  protected set(change: Record<string, string | null>): void {
    const queryParams: Record<string, string | null> = { page: null };
    for (const [key, value] of Object.entries(change)) queryParams[key] = value || null;
    void this.router.navigate(['/admin/users'], { queryParams, queryParamsHandling: 'merge' });
  }

  protected goTo(page: number): void {
    void this.router.navigate(['/admin/users'], { queryParams: { page: page > 1 ? page : null }, queryParamsHandling: 'merge' });
  }
}
