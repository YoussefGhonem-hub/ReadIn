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
import { ModerationSummaryStore } from '../../core/moderation/moderation-summary.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { isolate } from '../../shared/directives/bidi';
import { ModerationActionDraft, ModerationActionSheet } from '../../shared/moderation/moderation-action-sheet';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { LocalizedDatePipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../shared/ui/states';
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
 * One case (F22), `/moderation/{type}/{id}`: the reported article, comment or user with a link to it, the reasons, the
 * actions a moderator can take (Dismiss, Hide / Unhide, Delete a comment, Warn or Suspend the author or the user,
 * Unsuspend; suspending needs `users.suspend`), every report (reporter, reason, details, time, outcome) and the
 * history. Each action is confirmed in a sheet with an optional note (required to warn and suspend); afterwards the
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
    RelativeTimePipe,
    EmptyState,
    ErrorState,
    ModerationActionSheet,
    ModerationLogEntry,
    ReasonChips,
    TargetPreview,
  ],
  providers: [provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    <a routerLink="/moderation" class="mb-4 inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-case-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'moderation.case.back' | transloco }}
    </a>

    @switch (state().status) {
      @case ('loaded') {
        @let c = data()!;
        <header class="mb-4 flex flex-wrap items-center gap-2">
          <h1 class="m-0 text-2xl font-bold">{{ 'moderation.case.title.' + c.item.targetType | transloco }}</h1>
          <span class="rd-tag" [class]="c.item.status === 'open' ? 'bg-callout-warning text-text-primary' : 'rd-tag-neutral'" data-case-status>
            {{ 'moderation.case.status.' + c.item.status | transloco }}
          </span>
        </header>

        <section class="rd-card p-4 shadow-none" data-case-target>
          <rd-target-preview [item]="c.item" />
          <rd-reason-chips class="mt-3" [reasons]="c.item.reasons" />
          @if (link(); as href) {
            <a [routerLink]="href" class="mt-3 inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-link no-underline hover:underline" data-case-link>
              {{ 'moderation.case.open.' + c.item.targetType | transloco }}
              <svg lucideIcon="ArrowLeft" [size]="16" class="ltr:rotate-180" aria-hidden="true"></svg>
            </a>
          }
        </section>

        <!-- Actions -->
        <section class="mt-6" aria-labelledby="case-actions-title">
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

        <!-- Reports -->
        <section class="mt-6" aria-labelledby="case-reports-title">
          <h2 id="case-reports-title" class="m-0 mb-1 text-base font-semibold">
            {{ 'moderation.case.reports' | transloco }} <span class="font-normal text-text-secondary">({{ c.reports.length }})</span>
          </h2>
          <ol class="m-0 list-none divide-y divide-border p-0" data-case-reports>
            @for (report of c.reports; track report.id) {
              <li class="flex gap-3 py-3" [attr.data-report]="report.id">
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
        <section class="mt-6" aria-labelledby="case-history-title">
          <h2 id="case-history-title" class="m-0 mb-1 text-base font-semibold">{{ 'moderation.case.history' | transloco }}</h2>
          @if (c.history.length) {
            <ol class="m-0 list-none divide-y divide-border p-0" data-case-history>
              @for (entry of c.history; track entry.id) {
                <li><rd-moderation-log-entry [entry]="entry" [linkTarget]="false" /></li>
              }
            </ol>
          } @else {
            <p class="m-0 py-2 text-sm text-text-secondary" data-case-no-history>{{ 'moderation.case.noHistory' | transloco }}</p>
          }
        </section>
      }
      @case ('error') {
        @if (notFound()) {
          <rd-empty-state [title]="'moderation.case.notFound.title' | transloco" [message]="'moderation.case.notFound.body' | transloco" data-case-not-found>
            <a routerLink="/moderation" class="rd-btn rd-btn-primary mt-3">{{ 'moderation.case.back' | transloco }}</a>
          </rd-empty-state>
        } @else {
          <rd-error-state [message]="'moderation.case.loadError' | transloco" (retry)="load()" />
        }
      }
      @default {
        <div class="flex flex-col gap-4" aria-busy="true" data-case-loading>
          <div class="rd-skeleton h-7 w-1/2"></div>
          <div class="rd-card flex flex-col gap-2 p-4 shadow-none" aria-hidden="true">
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
  protected readonly link = computed(() => {
    const data = this.data();
    return data ? targetLink(data.item, this.lang()) : null;
  });

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
  }
}
