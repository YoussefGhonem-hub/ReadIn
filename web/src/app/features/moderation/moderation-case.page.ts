import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ModerationApi } from '../../core/api/moderation.api';
import { ModerationCaseDto, ModerationTargetType } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { AdminSummaryStore } from '../../core/admin/admin-summary.store';
import { ModerationSummaryStore } from '../../core/moderation/moderation-summary.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { isolate } from '../../shared/directives/bidi';
import { ModerationActionDraft, ModerationActionSheet } from '../../shared/moderation/moderation-action-sheet';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { LocalizedDatePipe, PluralPipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { categoryLink } from '../categories/category-rules';
import { LinkIcon } from '../profile/link-icon';
import { profileLinks } from '../profile/profile-links';
import { ModerationLogEntry, ReasonChips, TargetPreview, isTargetType, targetLink, textDir } from './moderation-ui';

type CaseState = { status: 'loading' } | { status: 'loaded'; data: ModerationCaseDto } | { status: 'error'; notFound: boolean };

/** A button of the case's actions. */
export interface CaseAction {
  id: string;
  labelKey: string;
  icon: string;
  danger?: boolean;
  draft: ModerationActionDraft;
}

/**
 * One case (F22), `/admin/reports/{type}/{id}`: the reported article, comment or user with a link to it, the reasons, the
 * actions a moderator can take (Dismiss, Hide / Unhide, Delete a comment, Warn or Suspend the author or the user,
 * Unsuspend; suspending needs `users.suspend`), a user's title and social links with "Clear title" / "Clear links"
 * (F14), a user's writer categories with "Clear name" for an offensive one (F31), every report (reporter, reason, details, time, outcome) and the history. Each action is confirmed in a sheet with an optional note (required to warn and suspend); afterwards the
 * case and the nav badge load again.
 */
@Component({
  selector: 'rd-moderation-case-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    Avatar,
    LocalizedDatePipe,
    PluralPipe,
    RelativeTimePipe,
    EmptyState,
    ErrorState,
    ModerationActionSheet,
    ModerationLogEntry,
    ReasonChips,
    TargetPreview,
    LinkIcon,
  ],
  providers: [provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pb-10 pt-5 lg:pt-8' },
  template: `
    <a routerLink="/admin/reports" class="mb-2 inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-case-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'moderation.case.back' | transloco }}
    </a>

    @switch (state().status) {
      @case ('loaded') {
        @let c = data()!;
        <!-- A stack of cards: the case (title, target, reasons), actions, a user's profile and categories, reports, history. -->
        <div class="flex flex-col gap-2">
          <div class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5">
            <header class="mb-4 flex flex-wrap items-center gap-2">
              <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'moderation.case.title.' + c.item.targetType | transloco }}</h1>
              <span class="rd-tag" [class]="c.item.status === 'open' ? 'bg-callout-warning text-text-primary' : 'rd-tag-neutral'" data-case-status>
                {{ 'moderation.case.status.' + c.item.status | transloco }}
              </span>
            </header>

            <section data-case-target>
              <rd-target-preview [item]="c.item" />
              <rd-reason-chips class="mt-3" [reasons]="c.item.reasons" />
              @if (link(); as href) {
                <a [routerLink]="href" class="mt-3 inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-link no-underline hover:underline" data-case-link>
                  {{ 'moderation.case.open.' + c.item.targetType | transloco }}
                  <svg lucideIcon="ArrowLeft" [size]="16" class="ltr:rotate-180" aria-hidden="true"></svg>
                </a>
              }
            </section>
          </div>

          <!-- Actions -->
          <section class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-labelledby="case-actions-title">
            <h2 id="case-actions-title" class="m-0 mb-3 text-base font-semibold">{{ 'moderation.case.actions' | transloco }}</h2>
            @if (actions().length) {
              <div class="flex flex-wrap gap-2" data-case-actions>
                @for (action of actions(); track action.id) {
                  <button
                    type="button"
                    class="rd-btn min-h-11 gap-1.5 px-4 text-sm"
                    [class]="action.danger ? 'rd-btn-outline border-error text-error' : 'rd-btn-outline'"
                    [attr.data-case-action]="action.id"
                    (click)="draft.set(action.draft)"
                  >
                    <svg [lucideIcon]="action.icon" [size]="16" aria-hidden="true"></svg>
                    {{ action.labelKey | transloco }}
                  </button>
                }
              </div>
            } @else {
              <p class="m-0 text-sm text-text-secondary">{{ 'moderation.case.noActions' | transloco }}</p>
            }
          </section>

          <!-- A user's title and social links (F14): an abusive one is cleared, audited, with no notice to the user -->
          @if (c.item.targetType === 'user') {
            @let headline = c.item.target.author?.headline;
            @let links = targetLinks();
            <section class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-labelledby="case-profile-title" data-case-profile>
              <h2 id="case-profile-title" class="m-0 mb-3 text-base font-semibold">{{ 'moderation.case.profile' | transloco }}</h2>
              <div class="flex flex-wrap items-start gap-3 border-b border-border pb-3">
                <div class="min-w-0 flex-1">
                  <h3 class="m-0 text-sm font-semibold text-text-secondary">{{ 'moderation.case.headline' | transloco }}</h3>
                  @if (headline) {
                    <p class="m-0 mt-1 [overflow-wrap:anywhere]" [attr.dir]="textDir(headline)" data-case-headline><rd-bdi-text [text]="headline" /></p>
                  } @else {
                    <p class="m-0 mt-1 text-sm text-text-secondary" data-case-no-headline>{{ 'moderation.case.noHeadline' | transloco }}</p>
                  }
                </div>
                @if (headline) {
                  <button
                    type="button"
                    class="rd-btn rd-btn-outline min-h-11 shrink-0 gap-1.5 border-error px-3 text-sm text-error"
                    data-case-clear-headline
                    (click)="draft.set({ action: 'clear_headline', targetType: 'user', targetId: c.item.targetId, name: c.item.target.author?.displayName ?? null })"
                  >
                    <svg lucideIcon="Eraser" [size]="16" aria-hidden="true"></svg>
                    {{ 'moderation.actions.clearHeadline' | transloco }}
                  </button>
                }
              </div>
              <div class="flex flex-wrap items-start gap-3 pt-3">
                <div class="min-w-0 flex-1">
                  <h3 class="m-0 text-sm font-semibold text-text-secondary">
                    {{ 'moderation.case.links' | transloco }} <span class="font-normal">({{ links.length }})</span>
                  </h3>
                  @if (links.length) {
                    <ul class="m-0 mt-1 flex list-none flex-col p-0" data-case-links>
                      @for (link of links; track $index) {
                        <li class="flex min-h-11 items-center gap-2 text-sm" [attr.data-case-link]="link.platform">
                          <rd-link-icon class="text-text-secondary" [platform]="link.platform" [size]="18" />
                          <span class="shrink-0 font-semibold">
                            @if (link.label; as label) {
                              <bdi dir="auto">{{ label }}</bdi>
                            } @else {
                              {{ 'profile.links.platforms.' + link.platform | transloco }}
                            }
                          </span>
                          <!-- The whole address, so a moderator sees exactly where it goes. -->
                          <a
                            [href]="link.url"
                            target="_blank"
                            rel="nofollow ugc noopener noreferrer"
                            class="min-w-0 text-link [overflow-wrap:anywhere]"
                            dir="ltr"
                            data-case-link-url
                            >{{ link.url }}</a
                          >
                        </li>
                      }
                    </ul>
                  } @else {
                    <p class="m-0 mt-1 text-sm text-text-secondary" data-case-no-links>{{ 'moderation.case.noLinks' | transloco }}</p>
                  }
                </div>
                @if (links.length) {
                  <button
                    type="button"
                    class="rd-btn rd-btn-outline min-h-11 shrink-0 gap-1.5 border-error px-3 text-sm text-error"
                    data-case-clear-links
                    (click)="draft.set({ action: 'clear_links', targetType: 'user', targetId: c.item.targetId, name: c.item.target.author?.displayName ?? null })"
                  >
                    <svg lucideIcon="Eraser" [size]="16" aria-hidden="true"></svg>
                    {{ 'moderation.actions.clearLinks' | transloco }}
                  </button>
                }
              </div>
            </section>
          }

          <!-- A user's writer categories (F31): an offensive name is cleared to a neutral placeholder -->
          @if (c.item.targetType === 'user') {
            <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="case-categories-title" data-case-categories>
              <div class="px-4 pb-1 pt-4 lg:px-5 lg:pt-5">
                <h2 id="case-categories-title" class="m-0 mb-1 text-base font-semibold">
                  {{ 'moderation.case.categories' | transloco }} <span class="font-normal text-text-secondary">({{ c.categories?.length ?? 0 }})</span>
                </h2>
                @if (!c.categories?.length) {
                  <p class="m-0 pb-3 text-sm text-text-secondary" data-case-no-categories>{{ 'moderation.case.noCategories' | transloco }}</p>
                } @else {
                  <p class="m-0 text-sm text-text-secondary">{{ 'moderation.case.categoriesHint' | transloco }}</p>
                }
              </div>
              <ul class="m-0 list-none divide-y divide-border p-0">
                @for (category of c.categories; track category.id) {
                  <li class="flex items-center gap-3 px-4 py-2 lg:px-5" [attr.data-case-category]="category.id">
                    <div class="min-w-0 flex-1">
                      @if (c.item.target.author; as user) {
                        <a [routerLink]="categoryLink(user.username, category.slug)" class="text-text-primary no-underline hover:underline">
                          <span class="block truncate font-semibold"><bdi dir="auto" data-case-category-name>{{ category.name }}</bdi></span>
                        </a>
                      } @else {
                        <span class="block truncate font-semibold"><bdi dir="auto" data-case-category-name>{{ category.name }}</bdi></span>
                      }
                      <span class="block text-xs text-text-secondary">{{
                        category.articleCount ? (category.articleCount | rdPlural: 'reading.articles' : lang()) : ('categories.noArticles' | transloco)
                      }}</span>
                    </div>
                    <button
                      type="button"
                      class="rd-btn rd-btn-outline min-h-11 shrink-0 gap-1.5 border-error px-3 text-sm text-error"
                      data-case-clear-category
                      [attr.aria-label]="'moderation.actions.clearCategoryOf' | transloco: { name: isolate(category.name) }"
                      (click)="draft.set({ action: 'clear_category', targetType: 'user', targetId: c.item.targetId, categoryId: category.id, name: category.name })"
                    >
                      <svg lucideIcon="Eraser" [size]="16" aria-hidden="true"></svg>
                      {{ 'moderation.actions.clearCategory' | transloco }}
                    </button>
                  </li>
                }
              </ul>
            </section>
          }

          <!-- Reports -->
          <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="case-reports-title">
            <h2 id="case-reports-title" class="m-0 px-4 pb-1 pt-4 text-base font-semibold lg:px-5 lg:pt-5">
              {{ 'moderation.case.reports' | transloco }} <span class="font-normal text-text-secondary">({{ c.reports.length }})</span>
            </h2>
            <ol class="m-0 list-none divide-y divide-border p-0" data-case-reports>
              @for (report of c.reports; track report.id) {
                <li class="flex gap-3 px-4 py-3 lg:px-5" [attr.data-report]="report.id">
                  @if (report.reporter; as r) {
                    <rd-avatar [name]="r.displayName" [src]="r.avatarUrl" [size]="32" />
                  } @else {
                    <span class="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-surface-variant text-text-secondary" aria-hidden="true">
                      <svg lucideIcon="UserRound" [size]="16"></svg>
                    </span>
                  }
                  <div class="min-w-0 flex-1 text-sm">
                    <p class="m-0 flex flex-wrap items-center gap-x-1.5 gap-y-1">
                      @if (report.reporter; as r) {
                        <span class="font-semibold"><rd-bdi-text [text]="r.displayName" /></span>
                        <bdi dir="ltr" class="text-xs text-text-secondary">&#64;{{ r.username }}</bdi>
                      } @else {
                        <span class="font-semibold text-text-secondary">{{ 'moderation.deletedUser' | transloco }}</span>
                      }
                      <span class="rd-tag rd-tag-neutral" [attr.data-report-reason]="report.reason">{{ 'report.reasons.' + report.reason | transloco }}</span>
                      @if (report.status !== 'open') {
                        <span class="rd-tag rd-tag-neutral">{{ 'moderation.case.status.' + report.status | transloco }}</span>
                      }
                    </p>
                    @if (report.details) {
                      <p class="m-0 mt-1 whitespace-pre-line [overflow-wrap:anywhere]" [attr.dir]="textDir(report.details)" data-report-details><rd-bdi-text [text]="report.details" /></p>
                    }
                    <p class="m-0 mt-1 text-xs text-text-secondary">
                      <time [attr.datetime]="report.createdAt" [title]="report.createdAt | rdDate: lang() : 'long'">{{ report.createdAt | rdRelativeTime: lang() }}</time>
                      @if (report.closedBy; as by) {
                        · {{ 'moderation.case.closedBy' | transloco: { name: isolate(by.displayName) } }}
                      }
                    </p>
                  </div>
                </li>
              }
            </ol>
          </section>

          <!-- History -->
          <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="case-history-title">
            <h2 id="case-history-title" class="m-0 px-4 pb-1 pt-4 text-base font-semibold lg:px-5 lg:pt-5">{{ 'moderation.case.history' | transloco }}</h2>
            @if (c.history.length) {
              <ol class="m-0 list-none divide-y divide-border p-0" data-case-history>
                @for (entry of c.history; track entry.id) {
                  <li class="px-4 lg:px-5"><rd-moderation-log-entry [entry]="entry" [linkTarget]="false" /></li>
                }
              </ol>
            } @else {
              <p class="m-0 px-4 pb-4 pt-1 text-sm text-text-secondary lg:px-5" data-case-no-history>{{ 'moderation.case.noHistory' | transloco }}</p>
            }
          </section>
        </div>
      }
      @case ('error') {
        <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
          @if (notFound()) {
            <rd-empty-state [title]="'moderation.case.notFound.title' | transloco" [message]="'moderation.case.notFound.body' | transloco" data-case-not-found>
              <a routerLink="/admin/reports" class="rd-btn rd-btn-primary mt-3">{{ 'moderation.case.back' | transloco }}</a>
            </rd-empty-state>
          } @else {
            <rd-error-state [message]="'moderation.case.loadError' | transloco" (retry)="load()" />
          }
        </div>
      }
      @default {
        <div class="rd-card flex flex-col gap-4 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-busy="true" data-case-loading>
          <div class="rd-skeleton h-7 w-1/2"></div>
          <div class="flex flex-col gap-2" aria-hidden="true">
            <div class="rd-skeleton h-4 w-16"></div>
            <div class="rd-skeleton h-5 w-4/5"></div>
            <div class="rd-skeleton h-3 w-1/3"></div>
          </div>
          <div class="rd-skeleton h-11 w-2/3"></div>
        </div>
      }
    }

    <rd-moderation-action-sheet [draft]="draft()" (done)="onDone()" (closed)="draft.set(null)" />
  `,
})
export class ModerationCasePage {
  private readonly api = inject(ModerationApi);
  private readonly session = inject(SessionStore);
  private readonly summary = inject(ModerationSummaryStore);
  private readonly adminSummary = inject(AdminSummaryStore);
  private readonly transloco = inject(TranslocoService);
  private readonly title = inject(Title);
  protected readonly lang = inject(LanguageService).lang;

  /** Route params (component input binding). */
  readonly type = input.required<string>();
  readonly id = input.required<string>();

  protected readonly state = signal<CaseState>({ status: 'loading' });
  protected readonly data = computed(() => {
    const state = this.state();
    return state.status === 'loaded' ? state.data : null;
  });
  protected readonly notFound = computed(() => {
    const state = this.state();
    return state.status === 'error' && state.notFound;
  });
  protected readonly draft = signal<ModerationActionDraft | null>(null);
  protected readonly textDir = textDir;
  protected readonly isolate = isolate;
  protected readonly categoryLink = categoryLink;
  protected readonly link = computed(() => {
    const data = this.data();
    return data ? targetLink(data.item, this.lang()) : null;
  });
  /** A user target's social links now (F14), in their order; only http(s) addresses are shown as links. */
  protected readonly targetLinks = computed(() => profileLinks(this.data()?.item.target.links ?? []));

  /** What a moderator can do here, by the target's type and state; suspending needs `users.suspend`. */
  protected readonly actions = computed<CaseAction[]>(() => {
    const data = this.data();
    if (!data) return [];
    const { item } = data;
    const { targetType: type, targetId: id, target } = item;
    const canSuspend = this.session.permissions().has('users.suspend');
    const actions: CaseAction[] = [];
    const on = { targetType: type, targetId: id };

    if (type === 'user') {
      const name = target.author?.displayName ?? null;
      if (target.state !== 'deleted') {
        actions.push({ id: 'warn', labelKey: 'moderation.actions.warn', icon: 'TriangleAlert', draft: { action: 'warn', ...on, name } });
        if (canSuspend && target.state === 'suspended') {
          actions.push({ id: 'unsuspend', labelKey: 'moderation.actions.unsuspend', icon: 'UserRoundCheck', draft: { action: 'unsuspend', ...on, name } });
        } else if (canSuspend) {
          actions.push({ id: 'suspend', labelKey: 'moderation.actions.suspend', icon: 'Ban', danger: true, draft: { action: 'suspend', ...on, name } });
        }
      }
    } else {
      if (target.state === 'hidden') {
        actions.push({ id: 'unhide', labelKey: `moderation.actions.unhide.${type}`, icon: 'Eye', draft: { action: 'unhide', ...on } });
      } else if (target.state === 'visible') {
        actions.push({ id: 'hide', labelKey: `moderation.actions.hide.${type}`, icon: 'EyeOff', danger: true, draft: { action: 'hide', ...on } });
      }
      if (type === 'comment' && target.state !== 'deleted') {
        actions.push({ id: 'delete', labelKey: 'moderation.actions.delete', icon: 'Trash2', danger: true, draft: { action: 'delete', ...on } });
      }
      // Warn or suspend the author; the content's open reports close with it.
      const author = target.author;
      if (author) {
        const user = { targetType: 'user' as ModerationTargetType, targetId: author.id, name: author.displayName, resolveReportsOf: on };
        actions.push({ id: 'warnAuthor', labelKey: 'moderation.actions.warnAuthor', icon: 'TriangleAlert', draft: { action: 'warn', ...user } });
        if (canSuspend) {
          actions.push({ id: 'suspendAuthor', labelKey: 'moderation.actions.suspendAuthor', icon: 'Ban', danger: true, draft: { action: 'suspend', ...user } });
        }
      }
    }
    if (item.status === 'open') {
      actions.push({ id: 'dismiss', labelKey: 'moderation.actions.dismiss', icon: 'CircleX', draft: { action: 'dismiss', ...on } });
    }
    return actions;
  });

  constructor() {
    effect(() => {
      this.type();
      this.id();
      untracked(() => void this.load());
    });
    effect(() => {
      const data = this.data();
      const name = this.transloco.translate(data ? `moderation.case.title.${data.item.targetType}` : 'moderation.title');
      this.title.setTitle(`${name} — ReadIn`);
    });
  }

  async load(): Promise<void> {
    const type = this.type();
    const id = this.id();
    if (!isTargetType(type)) {
      this.state.set({ status: 'error', notFound: true });
      return;
    }
    // A reload after an action keeps the page on screen.
    if (this.state().status !== 'loaded') this.state.set({ status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.case(type, id));
      if (type === this.type() && id === this.id()) this.state.set({ status: 'loaded', data });
    } catch (error) {
      if (type === this.type() && id === this.id()) this.state.set({ status: 'error', notFound: isApiError(error) && error.status === 404 });
    }
  }

  protected onDone(): void {
    void this.load();
    void this.summary.refresh();
    void this.adminSummary.refresh();
  }
}
