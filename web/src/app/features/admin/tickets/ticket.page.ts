import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { isApiError } from '../../../core/api/api.config';
import { AdminTicketDto, SUPPORT_CATEGORIES, SupportCategory } from '../../../core/api/models';
import { SupportApi } from '../../../core/api/support.api';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ModerationLogEntry } from '../../moderation/moderation-ui';
import { MESSAGE_MAX, SupportAttachments, TicketStatus } from '../../support/support-ui';
import { provideAdminIcons } from '../admin-icons';
import { ADMIN_CARD, AdminConfirm } from '../admin-ui';
import { AdminReportRow, SignInMethods, UserStatus } from '../users/user-bits';

type State = { status: 'loading' } | { status: 'loaded'; data: AdminTicketDto } | { status: 'error'; notFound: boolean };

/**
 * A ticket in the console (F35, `support.manage`), `/admin/tickets/{id}` (where `readin://admin/support/{id}` lands): the
 * conversation with who wrote each message and the internal notes (shown apart: only admins see them), the screenshots,
 * the member's card (linking to their console page), the device details, their reports and moderation history. Reply
 * (the ticket becomes Answered and the member is told) or add an internal note (nobody is told); change the category;
 * close (asks first) or reopen.
 */
@Component({
  selector: 'rd-admin-ticket-page',
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
    AdminConfirm,
    AdminReportRow,
    ModerationLogEntry,
    SignInMethods,
    SupportAttachments,
    TicketStatus,
    UserStatus,
  ],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-ticket': '' },
  styles: `
    .ticket-grid {
      display: grid;
      gap: 0.5rem;
    }
    @media (width >= 80rem) {
      .ticket-grid {
        grid-template-columns: minmax(0, 1fr) 20rem;
        align-items: start;
      }
    }
    .note {
      background: var(--rd-color-callout-warning);
      border-inline-start: 3px solid var(--rd-color-callout-warning-accent);
    }
    .facts {
      display: grid;
      grid-template-columns: minmax(0, auto) minmax(0, 1fr);
      gap: 0.25rem 0.75rem;
    }
  `,
  template: `
    <a routerLink="/admin/tickets" class="mb-2 inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-ticket-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'admin.tickets.back' | transloco }}
    </a>

    @switch (state().status) {
      @case ('loaded') {
        @let t = data()!;
        <div class="ticket-grid">
          <div class="flex min-w-0 flex-col gap-2">
            <header [class]="card + ' p-4 lg:p-5'">
              <p class="m-0 flex flex-wrap items-center gap-2 text-sm text-text-secondary">
                <bdi dir="ltr">#{{ t.number }}</bdi>
                <rd-ticket-status [status]="t.status" />
                @if (t.closedBy; as by) {
                  <span>{{ 'admin.tickets.closedBy.' + by | transloco }}</span>
                }
              </p>
              <h1 class="m-0 mt-1 text-xl font-bold lg:text-2xl" dir="auto" data-ticket-subject>{{ t.subject }}</h1>
              <div class="mt-3 flex flex-wrap items-center gap-2">
                <label for="ticket-category" class="text-sm text-text-secondary">{{ 'support.form.category' | transloco }}</label>
                <select id="ticket-category" class="rd-input min-h-10 w-auto py-1" [value]="t.category" [disabled]="busy()" (change)="setCategory($any($event.target).value)" data-ticket-category>
                  @for (c of categories; track c) {
                    <option [value]="c">{{ 'support.categories.' + c | transloco }}</option>
                  }
                </select>
                @if (t.status === 'closed') {
                  <button type="button" class="rd-btn rd-btn-outline min-h-10 px-4" [disabled]="busy()" (click)="setStatus('open')" data-ticket-reopen>{{ 'support.reopen' | transloco }}</button>
                } @else {
                  <button type="button" class="rd-btn rd-btn-outline min-h-10 px-4" [disabled]="busy()" (click)="closing.set(true)" data-ticket-close>{{ 'support.close' | transloco }}</button>
                }
              </div>
            </header>

            <section [class]="card" [attr.aria-label]="'support.conversation' | transloco">
              <ol class="m-0 list-none divide-y divide-border p-0" data-messages>
                @for (m of t.messages; track m.id) {
                  <li
                    class="px-4 py-3 lg:px-5"
                    [class.note]="m.isInternalNote"
                    [class.bg-primary-container]="m.fromSupport && !m.isInternalNote"
                    [attr.data-message]="m.id"
                    [attr.data-kind]="m.isInternalNote ? 'note' : m.fromSupport ? 'reply' : 'member'"
                  >
                    <p class="m-0 flex flex-wrap items-center gap-2 text-sm">
                      @if (m.isInternalNote) {
                        <span class="rd-tag rd-tag-neutral gap-1" data-note-tag>
                          <svg lucideIcon="StickyNote" [size]="12" aria-hidden="true"></svg>{{ 'admin.tickets.note' | transloco }}
                        </span>
                      }
                      <span class="font-semibold">
                        @if (m.author; as author) {
                          <rd-bdi-text [text]="author.displayName" />
                        } @else {
                          {{ 'common.deletedUser' | transloco }}
                        }
                      </span>
                      @if (m.fromSupport && !m.isInternalNote) {
                        <span class="text-xs text-text-secondary">· {{ 'support.supportTeam' | transloco }}</span>
                      }
                      <time class="text-xs text-text-secondary" [attr.datetime]="m.createdAt" [title]="m.createdAt | rdDate: lang() : 'long'">{{ m.createdAt | rdRelativeTime: lang() }}</time>
                    </p>
                    <p class="m-0 mt-1 whitespace-pre-line text-[15px] leading-relaxed [overflow-wrap:anywhere]" dir="auto" data-message-body>{{ m.body }}</p>
                    @if (m.attachments.length) {
                      <rd-support-attachments class="mt-2" [attachments]="m.attachments" />
                    }
                  </li>
                }
              </ol>
            </section>

            <form [class]="card + ' flex flex-col gap-3 p-4 lg:p-5'" (submit)="$event.preventDefault()" data-admin-reply>
              <div class="flex gap-2" role="radiogroup" [attr.aria-label]="'admin.tickets.writeAs' | transloco">
                <button type="button" role="radio" class="rd-chip" [attr.aria-checked]="!internal()" [attr.aria-pressed]="!internal()" (click)="internal.set(false)" data-mode="reply">
                  {{ 'admin.tickets.replyMode' | transloco }}
                </button>
                <button type="button" role="radio" class="rd-chip" [attr.aria-checked]="internal()" [attr.aria-pressed]="internal()" (click)="internal.set(true)" data-mode="note">
                  {{ 'admin.tickets.noteMode' | transloco }}
                </button>
              </div>
              <label for="admin-reply" class="sr-only">{{ (internal() ? 'admin.tickets.noteMode' : 'admin.tickets.replyMode') | transloco }}</label>
              <textarea
                id="admin-reply"
                class="rd-input rd-autogrow"
                [class.note]="internal()"
                rows="4"
                dir="auto"
                [attr.maxlength]="messageMax"
                [value]="draft()"
                [disabled]="busy()"
                [placeholder]="(internal() ? 'admin.tickets.notePlaceholder' : 'admin.tickets.replyPlaceholder') | transloco"
                (input)="draft.set($any($event.target).value)"
                data-admin-reply-text
              ></textarea>
              @if (!internal() && t.status === 'closed') {
                <p class="m-0 text-xs text-text-secondary" data-reopen-first>{{ 'errors.support.ticket_closed' | transloco }}</p>
              }
              @if (error()) {
                <p class="rd-alert rd-alert-error m-0" role="alert" data-admin-reply-error>{{ error() }}</p>
              }
              <button type="button" class="rd-btn rd-btn-primary min-h-11 self-start px-5" [disabled]="!canSend()" (click)="send()" data-admin-reply-send>
                <svg [lucideIcon]="internal() ? 'StickyNote' : 'Send'" [size]="16" aria-hidden="true"></svg>
                {{ (internal() ? 'admin.tickets.addNote' : 'admin.tickets.sendReply') | transloco }}
              </button>
              <p class="m-0 text-xs text-text-secondary">{{ (internal() ? 'admin.tickets.noteHint' : 'admin.tickets.replyHint') | transloco }}</p>
            </form>
          </div>

          <!-- The member, their device and their history -->
          <aside class="flex min-w-0 flex-col gap-2">
            <section [class]="card + ' p-4'" aria-labelledby="ticket-member" data-ticket-member>
              <h2 id="ticket-member" class="m-0 mb-3 text-sm font-semibold text-text-secondary">{{ 'admin.tickets.member' | transloco }}</h2>
              <a [routerLink]="session.hasPermission('users.read') ? ['/admin/users', t.user.id] : '/@' + t.user.username" class="flex items-center gap-3 text-text-primary no-underline hover:underline" data-member-link>
                <rd-avatar [name]="t.user.displayName" [src]="t.user.avatarUrl" [size]="40" />
                <span class="min-w-0">
                  <span class="block truncate font-semibold"><rd-bdi-text [text]="t.user.displayName" /></span>
                  <bdi dir="ltr" class="block truncate text-xs text-text-secondary">&#64;{{ t.user.username }}</bdi>
                </span>
              </a>
              <dl class="facts m-0 mt-3 text-sm">
                <dt class="text-text-secondary">{{ 'admin.users.columns.status' | transloco }}</dt>
                <dd class="m-0"><rd-user-status [status]="t.member.status" [until]="t.member.suspendedUntil" /></dd>
                <dt class="text-text-secondary">{{ 'admin.users.columns.joined' | transloco }}</dt>
                <dd class="m-0">{{ t.member.joinedAt | rdDate: lang() }}</dd>
                <dt class="text-text-secondary">{{ 'admin.users.columns.signIn' | transloco }}</dt>
                <dd class="m-0"><rd-sign-in-methods [methods]="t.member.signInMethods" /></dd>
                <dt class="text-text-secondary">{{ 'admin.users.tickets' | transloco }}</dt>
                <dd class="m-0 tabular-nums">{{ t.member.ticketCount }}</dd>
                @if (t.reportsAgainst !== null) {
                  <dt class="text-text-secondary">{{ 'admin.users.columns.reports' | transloco }}</dt>
                  <dd class="m-0 tabular-nums">{{ t.reportsAgainst }}</dd>
                }
              </dl>
            </section>

            <section [class]="card + ' p-4'" aria-labelledby="ticket-device" data-ticket-device>
              <h2 id="ticket-device" class="m-0 mb-2 text-sm font-semibold text-text-secondary">{{ 'admin.tickets.device' | transloco }}</h2>
              <dl class="facts m-0 text-sm">
                <dt class="text-text-secondary">{{ 'admin.tickets.platform' | transloco }}</dt>
                <dd class="m-0" dir="ltr">{{ t.device.platform ?? '—' }}</dd>
                <dt class="text-text-secondary">{{ 'admin.tickets.os' | transloco }}</dt>
                <dd class="m-0" dir="ltr">{{ t.device.osVersion ?? '—' }}</dd>
                <dt class="text-text-secondary">{{ 'admin.tickets.appVersion' | transloco }}</dt>
                <dd class="m-0" dir="ltr">{{ t.device.appVersion ?? '—' }}</dd>
                <dt class="text-text-secondary">{{ 'admin.users.uiLanguage' | transloco }}</dt>
                <dd class="m-0">{{ t.device.language === 'ar' ? 'العربية' : t.device.language === 'en' ? 'English' : '—' }}</dd>
                <dt class="text-text-secondary">{{ 'admin.tickets.screen' | transloco }}</dt>
                <dd class="m-0 [overflow-wrap:anywhere]" dir="ltr">{{ t.device.screen ?? '—' }}</dd>
              </dl>
            </section>

            @if (t.reportsFiled; as filed) {
              <section [class]="card + ' p-4'" aria-labelledby="ticket-reports" data-ticket-reports>
                <h2 id="ticket-reports" class="m-0 text-sm font-semibold text-text-secondary">{{ 'admin.users.reportsFiled' | transloco }} ({{ filed.total }})</h2>
                @if (filed.items.length) {
                  <ul class="m-0 list-none divide-y divide-border p-0">
                    @for (r of filed.items; track r.id) {
                      <li><rd-admin-report-row [report]="r" /></li>
                    }
                  </ul>
                } @else {
                  <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'admin.users.none' | transloco }}</p>
                }
              </section>
            }

            @if (t.moderation; as history) {
              <section [class]="card" aria-labelledby="ticket-moderation" data-ticket-moderation>
                <h2 id="ticket-moderation" class="m-0 px-4 pt-4 text-sm font-semibold text-text-secondary">{{ 'admin.users.moderation' | transloco }}</h2>
                @if (history.length) {
                  <ol class="m-0 list-none divide-y divide-border p-0">
                    @for (entry of history; track entry.id) {
                      <li class="px-4"><rd-moderation-log-entry [entry]="entry" /></li>
                    }
                  </ol>
                } @else {
                  <p class="m-0 px-4 pb-4 pt-1 text-sm text-text-secondary">{{ 'admin.users.noHistory' | transloco }}</p>
                }
              </section>
            }
          </aside>
        </div>
      }
      @case ('error') {
        <div [class]="card">
          @if (notFound()) {
            <rd-empty-state [title]="'errors.support.ticket_not_found' | transloco" data-ticket-not-found>
              <a routerLink="/admin/tickets" class="rd-btn rd-btn-primary mt-3">{{ 'admin.tickets.back' | transloco }}</a>
            </rd-empty-state>
          } @else {
            <rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" />
          }
        </div>
      }
      @default {
        <div [class]="card + ' flex flex-col gap-3 p-5'" aria-busy="true" data-ticket-loading>
          <div class="rd-skeleton h-6 w-2/3" aria-hidden="true"></div>
          <div class="rd-skeleton h-32 w-full" aria-hidden="true"></div>
        </div>
      }
    }

    <rd-admin-confirm
      [open]="closing()"
      [title]="'admin.tickets.closeTitle' | transloco"
      [body]="'admin.tickets.closeBody' | transloco"
      [busy]="busy()"
      [error]="error()"
      (confirmed)="setStatus('closed')"
      (closed)="closing.set(false)"
    />
  `,
})
export class AdminTicketPage {
  private readonly api = inject(SupportApi);
  private readonly summary = inject(AdminSummaryStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly title = inject(Title);
  protected readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  readonly id = input.required<string>();

  protected readonly card = ADMIN_CARD;
  protected readonly categories = SUPPORT_CATEGORIES;
  protected readonly messageMax = MESSAGE_MAX;
  protected readonly state = signal<State>({ status: 'loading' });
  protected readonly data = computed(() => {
    const s = this.state();
    return s.status === 'loaded' ? s.data : null;
  });
  protected readonly notFound = computed(() => {
    const s = this.state();
    return s.status === 'error' && s.notFound;
  });
  protected readonly internal = signal(false);
  protected readonly draft = signal('');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly closing = signal(false);
  /** A reply needs an open ticket; a note works in any status. */
  protected readonly canSend = computed(() => {
    const n = this.draft().trim().length;
    return !this.busy() && n >= 1 && n <= MESSAGE_MAX && (this.internal() || this.data()?.status !== 'closed');
  });

  constructor() {
    effect(() => {
      this.id();
      untracked(() => {
        this.state.set({ status: 'loading' });
        void this.load();
      });
    });
    effect(() => {
      const t = this.data();
      this.title.setTitle(`${t ? `#${t.number} ${t.subject}` : this.transloco.translate('admin.nav.tickets')} — ReadIn`);
    });
  }

  async load(): Promise<void> {
    const id = this.id();
    if (this.state().status === 'error') this.state.set({ status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.adminTicket(id));
      if (id === this.id()) this.state.set({ status: 'loaded', data });
    } catch (error) {
      if (id === this.id()) this.state.set({ status: 'error', notFound: isApiError(error) && error.status === 404 });
    }
  }

  protected async send(): Promise<void> {
    const t = this.data();
    if (!t || !this.canSend()) return;
    const internal = this.internal();
    await this.run(async () => {
      const message = await firstValueFrom(this.api.adminMessage(t.id, this.draft().trim(), internal));
      // A reply makes the ticket Answered; a note changes nothing.
      this.state.set({ status: 'loaded', data: { ...t, status: internal ? t.status : 'answered', waitingSince: internal ? t.waitingSince : null, messages: [...t.messages, message] } });
      this.draft.set('');
      this.toasts.success(this.transloco.translate(internal ? 'admin.tickets.noteAdded' : 'admin.tickets.replied'));
      void this.summary.refresh();
    });
  }

  protected async setCategory(category: SupportCategory): Promise<void> {
    const t = this.data();
    if (!t || t.category === category) return;
    await this.update({ category });
  }

  protected async setStatus(status: 'open' | 'closed'): Promise<void> {
    await this.update({ status });
    if (!this.error()) this.closing.set(false);
  }

  private async update(change: { status?: 'open' | 'closed'; category?: SupportCategory }): Promise<void> {
    const t = this.data();
    if (!t) return;
    await this.run(async () => {
      const data = await firstValueFrom(this.api.adminUpdate(t.id, change));
      this.state.set({ status: 'loaded', data });
      this.toasts.success(this.transloco.translate(change.status ? `admin.tickets.done.${change.status}` : 'admin.tickets.done.category'));
      void this.summary.refresh();
    });
  }

  private async run(action: () => Promise<void>): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await action();
    } catch (error) {
      if (isApiError(error) && error.code === 'validation.failed') {
        const first = Object.values(error.validationErrors).flat()[0];
        this.error.set(first ? this.errors.forCode(first) : this.errors.forError(error));
      } else this.error.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }
}
