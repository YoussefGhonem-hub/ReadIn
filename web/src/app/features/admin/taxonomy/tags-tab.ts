import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi, AdminTagsQuery } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { AdminTagDto } from '../../../core/api/models';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { isolate } from '../../../shared/directives/bidi';
import { LocalizedDatePipe } from '../../../shared/pipes/format.pipes';
import { translatePlural } from '../../../shared/pipes/intl';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ADMIN_PAGE_SIZE, ADMIN_TABLE_STYLES, AdminConfirm, AdminPager, PagedState, oneOf, pageParam } from '../admin-ui';
import { provideAdminIcons } from '../admin-icons';

const STATUSES = ['all', 'visible', 'hidden'] as const;
const ORIGINS = ['all', 'system', 'user'] as const;
const SORTS = ['articles', 'name', 'newest'] as const;
/** A tag's name (F32): 1–64 characters. */
export const TAG_NAME_MAX = 64;

type Dialog =
  | { kind: 'rename'; tag: AdminTagDto }
  | { kind: 'merge'; tag: AdminTagDto; into: AdminTagDto | { id: string; slug: string; name: string } | null }
  | { kind: 'hide'; tag: AdminTagDto };

/**
 * Tags (F23, F32): search by name, slug or alias, filter by visible / hidden and system / user, sort by articles, name or
 * newest, 50 a page. Rename keeps the slug (the old spelling becomes an alias); a name another tag has offers
 * "Merge into #{name}". Merge moves every article to the other tag and can't be undone (confirmed with how many
 * articles move). Hide asks first; Unhide doesn't.
 */
@Component({
  selector: 'rd-admin-tags-tab',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, LocalizedDatePipe, BottomSheet, EmptyState, ErrorState, AdminConfirm, AdminPager],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-tags-tab': '' },
  styles: ADMIN_TABLE_STYLES,
  template: `
    <form class="flex flex-wrap items-end gap-2 border-b border-border p-4 text-sm" role="search" (submit)="search($event, q.value)" data-tags-filters>
      <label class="flex min-w-48 flex-1 flex-col gap-1">
        <span class="text-xs text-text-secondary">{{ 'admin.tags.search' | transloco }}</span>
        <span class="flex gap-2">
          <input #q type="search" class="rd-input flex-1" dir="auto" maxlength="64" [value]="query().q ?? ''" data-tags-q />
          <button type="submit" class="rd-btn rd-btn-primary min-h-11 px-3" [attr.aria-label]="'admin.search' | transloco">
            <svg lucideIcon="Search" [size]="16" aria-hidden="true"></svg>
          </button>
        </span>
      </label>
      <label class="flex flex-col gap-1">
        <span class="text-xs text-text-secondary">{{ 'admin.tags.status' | transloco }}</span>
        <select class="rd-input min-h-10 py-1" [value]="query().status ?? 'all'" (change)="set({ status: $any($event.target).value })" data-filter="status">
          @for (s of statuses; track s) {
            <option [value]="s">{{ 'admin.tags.statuses.' + s | transloco }}</option>
          }
        </select>
      </label>
      <label class="flex flex-col gap-1">
        <span class="text-xs text-text-secondary">{{ 'admin.tags.origin' | transloco }}</span>
        <select class="rd-input min-h-10 py-1" [value]="query().origin ?? 'all'" (change)="set({ origin: $any($event.target).value })" data-filter="origin">
          @for (o of origins; track o) {
            <option [value]="o">{{ 'admin.tags.origins.' + o | transloco }}</option>
          }
        </select>
      </label>
      <label class="flex flex-col gap-1">
        <span class="text-xs text-text-secondary">{{ 'admin.sortBy' | transloco }}</span>
        <select class="rd-input min-h-10 py-1" [value]="query().sort ?? 'articles'" (change)="set({ sort: $any($event.target).value })" data-filter="sort">
          @for (s of sorts; track s) {
            <option [value]="s">{{ 'admin.tags.sorts.' + s | transloco }}</option>
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
          <table class="admin-table" [attr.aria-busy]="list.refreshing()" data-tags-table>
            <thead>
              <tr>
                <th scope="col">{{ 'admin.tags.columns.tag' | transloco }}</th>
                <th scope="col" class="num">{{ 'admin.tags.columns.articles' | transloco }}</th>
                <th scope="col">{{ 'admin.tags.columns.created' | transloco }}</th>
                <th scope="col">{{ 'admin.tags.columns.state' | transloco }}</th>
                <th scope="col"><span class="sr-only">{{ 'admin.users.actions' | transloco }}</span></th>
              </tr>
            </thead>
            <tbody>
              @for (t of list.items(); track t.id) {
                <tr [attr.data-tag-row]="t.slug">
                  <td class="cell-main">
                    <a [routerLink]="['/tags', t.slug]" class="font-semibold text-text-primary no-underline hover:underline"><bdi dir="auto">#{{ t.name }}</bdi></a>
                    <span class="block text-xs text-text-secondary"><bdi dir="ltr">{{ t.slug }}</bdi></span>
                    @if (t.aliases.length) {
                      <span class="block text-xs text-text-secondary" data-tag-aliases>{{ 'admin.tags.aliases' | transloco }}: <bdi dir="auto">{{ t.aliases.join('، ') }}</bdi></span>
                    }
                  </td>
                  <td class="num" [attr.data-label]="'admin.tags.columns.articles' | transloco">
                    {{ t.articleCount }}
                    @if (t.taggedCount !== t.articleCount) {
                      <span class="text-xs text-text-secondary">/ {{ t.taggedCount }}</span>
                    }
                  </td>
                  <td [attr.data-label]="'admin.tags.columns.created' | transloco">
                    <time [attr.datetime]="t.createdAt">{{ t.createdAt | rdDate: lang() }}</time>
                    @if (t.createdBy; as by) {
                      <bdi dir="ltr" class="block text-xs text-text-secondary">&#64;{{ by.username }}</bdi>
                    }
                  </td>
                  <td [attr.data-label]="'admin.tags.columns.state' | transloco">
                    <span class="inline-flex flex-wrap justify-end gap-1">
                      @if (t.isHidden) {
                        <span class="rd-tag bg-callout-warning text-text-primary" data-tag-hidden>{{ 'admin.tags.hidden' | transloco }}</span>
                      }
                      @if (t.isSystem) {
                        <span class="rd-tag rd-tag-neutral">{{ 'admin.tags.system' | transloco }}</span>
                      }
                      @if (t.emptySince; as since) {
                        <span class="rd-tag rd-tag-neutral" [title]="'admin.tags.emptyHint' | transloco">{{ 'admin.tags.emptySince' | transloco: { date: (since | rdDate: lang()) } }}</span>
                      }
                    </span>
                  </td>
                  <td>
                    <span class="flex flex-wrap justify-end gap-1">
                      <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" (click)="openRename(t)" data-tag-action="rename">{{ 'admin.tags.rename' | transloco }}</button>
                      <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" (click)="openMerge(t, null)" data-tag-action="merge">{{ 'admin.tags.merge' | transloco }}</button>
                      @if (t.isHidden) {
                        <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" (click)="setHidden(t, false)" data-tag-action="unhide">{{ 'admin.tags.unhide' | transloco }}</button>
                      } @else {
                        <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs text-error" (click)="openDialog({ kind: 'hide', tag: t })" data-tag-action="hide">
                          {{ 'admin.tags.hide' | transloco }}
                        </button>
                      }
                    </span>
                  </td>
                </tr>
              }
            </tbody>
          </table>
          <rd-admin-pager [page]="list.page()" [totalPages]="list.totalPages()" [totalCount]="list.totalCount()" (pageChange)="goTo($event)" />
        } @else {
          <rd-empty-state [title]="'admin.tags.empty' | transloco" [message]="'admin.emptyFilters' | transloco" data-tags-empty />
        }
      }
      @default {
        <div class="flex flex-col gap-3 p-4" aria-busy="true" data-tags-loading>
          @for (i of [1, 2, 3, 4]; track i) {
            <div class="rd-skeleton h-10 w-full" aria-hidden="true"></div>
          }
        </div>
      }
    }

    <!-- Rename -->
    <rd-bottom-sheet [open]="dialog()?.kind === 'rename'" labelledBy="tag-rename-title" [dismissible]="!busy()" (closed)="closeDialog()">
      @if (renaming(); as t) {
        <form class="flex flex-col gap-3 pt-1" (submit)="rename($event)" data-tag-rename>
          <h2 id="tag-rename-title" class="m-0 pe-10 text-xl font-semibold">{{ 'admin.tags.renameTitle' | transloco: { name: isolate('#' + t.name) } }}</h2>
          <p class="m-0 text-sm text-text-secondary">{{ 'admin.tags.renameBody' | transloco }}</p>
          <label for="tag-name" class="sr-only">{{ 'admin.tags.newName' | transloco }}</label>
          <input id="tag-name" class="rd-input" dir="auto" [attr.maxlength]="nameMax" [value]="name()" [disabled]="busy()" (input)="name.set($any($event.target).value)" data-tag-name />
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-tag-error>{{ error() }}</p>
          }
          @if (taken(); as other) {
            <button type="button" class="rd-btn rd-btn-outline" (click)="openMerge(t, other)" data-merge-into-taken>
              <svg lucideIcon="Merge" [size]="16" aria-hidden="true"></svg>
              {{ 'admin.tags.mergeInto' | transloco: { name: isolate('#' + other.name) } }}
            </button>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="closeDialog()">{{ 'common.cancel' | transloco }}</button>
            <button type="submit" class="rd-btn rd-btn-primary flex-1" [disabled]="busy() || !name().trim() || name().trim().length > nameMax" data-tag-rename-save>{{ 'common.save' | transloco }}</button>
          </div>
        </form>
      }
    </rd-bottom-sheet>

    <!-- Merge: pick the tag to merge into, then confirm (it can't be undone) -->
    <rd-bottom-sheet [open]="dialog()?.kind === 'merge'" labelledBy="tag-merge-title" describedBy="tag-merge-body" role="alertdialog" [dismissible]="!busy()" (closed)="closeDialog()">
      @if (merging(); as m) {
        <div class="flex flex-col gap-3 pt-1" data-tag-merge>
          <h2 id="tag-merge-title" class="m-0 pe-10 text-xl font-semibold">{{ 'admin.tags.mergeTitle' | transloco: { name: isolate('#' + m.tag.name) } }}</h2>
          <p id="tag-merge-body" class="m-0 text-sm text-text-secondary">{{ mergeBody() }}</p>
          @if (m.into; as into) {
            <p class="m-0 flex items-center gap-2 rounded-md bg-surface-variant p-3 text-sm font-semibold" data-merge-target>
              <svg lucideIcon="Merge" [size]="16" aria-hidden="true"></svg>
              <bdi dir="auto">#{{ m.tag.name }}</bdi> → <bdi dir="auto">#{{ into.name }}</bdi>
              <button type="button" class="rd-btn rd-btn-ghost ms-auto min-h-9 px-2 text-xs" [disabled]="busy()" (click)="pickTarget(null)">{{ 'admin.change' | transloco }}</button>
            </p>
          } @else {
            <label for="merge-q" class="rd-label m-0">{{ 'admin.tags.mergeSearch' | transloco }}</label>
            <input id="merge-q" type="search" class="rd-input" dir="auto" maxlength="64" (input)="findTargets($any($event.target).value)" data-merge-q />
            <ul class="m-0 flex max-h-56 list-none flex-col overflow-y-auto p-0" data-merge-options>
              @for (option of targets(); track option.id) {
                <li>
                  <button type="button" class="flex min-h-11 w-full items-center justify-between gap-2 rounded-sm px-2 text-start text-sm hover:bg-surface-variant" (click)="pickTarget(option)" [attr.data-merge-option]="option.slug">
                    <bdi dir="auto">#{{ option.name }}</bdi>
                    <span class="text-xs text-text-secondary">{{ option.articleCount }}</span>
                  </button>
                </li>
              }
            </ul>
          }
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-tag-error>{{ error() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="closeDialog()">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="busy() || !m.into" (click)="merge()" data-tag-merge-confirm>{{ 'admin.confirm.ok' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>

    <rd-admin-confirm
      [open]="dialog()?.kind === 'hide'"
      [title]="'admin.tags.hideTitle' | transloco: { name: isolate('#' + (dialog()?.tag?.name ?? '')) }"
      [body]="'admin.tags.hideBody' | transloco"
      [danger]="true"
      [busy]="busy()"
      [error]="error()"
      (confirmed)="setHidden(dialog()!.tag, true)"
      (closed)="closeDialog()"
    />
  `,
})
export class TagsTab {
  private readonly api = inject(AdminApi);
  private readonly router = inject(Router);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly q = input<string | undefined>();
  readonly status = input<string | undefined>();
  readonly origin = input<string | undefined>();
  readonly sort = input<string | undefined>();
  readonly page = input<string | undefined>();

  protected readonly statuses = STATUSES;
  protected readonly origins = ORIGINS;
  protected readonly sorts = SORTS;
  protected readonly nameMax = TAG_NAME_MAX;
  protected readonly isolate = isolate;

  protected readonly query = computed<AdminTagsQuery>(() => ({
    q: this.q()?.trim() || null,
    status: oneOf(this.status(), STATUSES),
    origin: oneOf(this.origin(), ORIGINS),
    sort: oneOf(this.sort(), SORTS),
    page: pageParam(this.page()),
    pageSize: ADMIN_PAGE_SIZE,
  }));
  protected readonly list = new PagedState<AdminTagDto>(() => this.api.tags(this.query()));

  protected readonly dialog = signal<Dialog | null>(null);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly name = signal('');
  /** The tag that already has the new name (`409 tag.name_taken`). */
  protected readonly taken = signal<{ id: string; slug: string; name: string } | null>(null);
  protected readonly targets = signal<AdminTagDto[]>([]);
  private searchRun = 0;

  protected readonly renaming = computed(() => {
    const d = this.dialog();
    return d?.kind === 'rename' ? d.tag : null;
  });
  protected readonly merging = computed(() => {
    const d = this.dialog();
    return d?.kind === 'merge' ? d : null;
  });
  protected readonly mergeBody = computed(() => {
    const m = this.merging();
    return m ? translatePlural(this.transloco, 'admin.tags.mergeBody', m.tag.taggedCount, this.lang()) : '';
  });

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
    const queryParams: Record<string, string | null> = { tab: 'tags', page: null };
    for (const [key, value] of Object.entries(change)) queryParams[key] = value && value !== 'all' ? value : null;
    void this.router.navigate(['/admin/taxonomy'], { queryParams, queryParamsHandling: 'merge' });
  }

  protected goTo(page: number): void {
    void this.router.navigate(['/admin/taxonomy'], { queryParams: { tab: 'tags', page: page > 1 ? page : null }, queryParamsHandling: 'merge' });
  }

  protected openDialog(dialog: Dialog): void {
    this.error.set(null);
    this.taken.set(null);
    this.dialog.set(dialog);
  }

  protected closeDialog(): void {
    if (!this.busy()) this.dialog.set(null);
  }

  protected openRename(tag: AdminTagDto): void {
    this.name.set(tag.name);
    this.openDialog({ kind: 'rename', tag });
  }

  protected openMerge(tag: AdminTagDto, into: { id: string; slug: string; name: string } | null): void {
    this.targets.set([]);
    this.openDialog({ kind: 'merge', tag, into });
  }

  protected pickTarget(into: AdminTagDto | null): void {
    const d = this.merging();
    if (d) this.dialog.set({ ...d, into });
  }

  protected async findTargets(q: string): Promise<void> {
    const run = ++this.searchRun;
    const text = q.trim();
    if (!text) {
      this.targets.set([]);
      return;
    }
    try {
      const page = await firstValueFrom(this.api.tags({ q: text, pageSize: 10 }));
      const self = this.merging()?.tag.id;
      if (run === this.searchRun) this.targets.set(page.items.filter((t) => t.id !== self));
    } catch {
      if (run === this.searchRun) this.targets.set([]);
    }
  }

  protected async rename(event: Event): Promise<void> {
    event.preventDefault();
    const tag = this.renaming();
    const name = this.name().trim();
    if (!tag || !name || this.busy()) return;
    await this.run(async () => {
      const saved = await firstValueFrom(this.api.renameTag(tag.id, name));
      this.list.update((t) => t.id === tag.id, () => saved);
      this.toasts.success(this.transloco.translate('admin.tags.renamed'));
    });
  }

  protected async merge(): Promise<void> {
    const m = this.merging();
    if (!m?.into || this.busy()) return;
    const into = m.into;
    await this.run(async () => {
      await firstValueFrom(this.api.mergeTag(m.tag.id, into.id));
      this.toasts.success(this.transloco.translate('admin.tags.merged', { from: isolate(`#${m.tag.name}`), to: isolate(`#${into.name}`) }));
      void this.list.load();
    });
  }

  protected async setHidden(tag: AdminTagDto, hidden: boolean): Promise<void> {
    if (this.busy()) return;
    await this.run(async () => {
      const saved = await firstValueFrom(this.api.setTagHidden(tag.id, hidden));
      this.list.update((t) => t.id === tag.id, () => saved);
      this.toasts.success(this.transloco.translate(hidden ? 'admin.tags.hiddenDone' : 'admin.tags.unhiddenDone'));
    });
  }

  /** Runs a write; a failure stays in the open dialog (or a toast without one). */
  private async run(write: () => Promise<void>): Promise<void> {
    this.busy.set(true);
    this.error.set(null);
    this.taken.set(null);
    try {
      await write();
      this.busy.set(false);
      this.dialog.set(null);
    } catch (error) {
      const message = this.message(error);
      if (this.dialog()) this.error.set(message);
      else this.toasts.error(message);
      if (isApiError(error) && error.code === 'tag.name_taken') {
        const problem = error.problem as { tagId?: string; tagSlug?: string } | null;
        if (problem?.tagId) this.taken.set({ id: problem.tagId, slug: problem.tagSlug ?? '', name: this.name().trim() });
      }
    } finally {
      this.busy.set(false);
    }
  }

  private message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}
