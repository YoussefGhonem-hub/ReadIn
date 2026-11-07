import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { SupportTicketDto } from '../../core/api/models';
import { SupportApi } from '../../core/api/support.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { LocalizedDatePipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { provideAdminIcons } from '../admin/admin-icons';
import { MESSAGE_MAX, ScreenshotPicker, SupportAttachments, TicketStatus } from './support-ui';

type State = { status: 'loading' } | { status: 'loaded'; data: SupportTicketDto } | { status: 'error'; notFound: boolean };

/**
 * A ticket (F35), `/support/tickets/{id}` (where `readin://support/{id}` lands): its number, subject, category and
 * status, the conversation oldest first (support's replies as «فريق الدعم» / "Support", never an admin's name), the
 * screenshots through the authenticated attachment route, and a reply box with up to 3 screenshots. Close asks first;
 * a closed ticket reopens within 30 days, after that the member sends a new one.
 */
@Component({
  selector: 'rd-ticket-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, LocalizedDatePipe, RelativeTimePipe, BottomSheet, EmptyState, ErrorState, ScreenshotPicker, SupportAttachments, TicketStatus],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[720px] flex-col gap-2 px-4 pb-10 pt-5 lg:pt-8', 'data-ticket-page': '' },
  template: `
    <a routerLink="/support/tickets" class="inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-ticket-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'support.myTickets' | transloco }}
    </a>

    @switch (state().status) {
      @case ('loaded') {
        @let t = data()!;
        <header class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5">
          <p class="m-0 flex flex-wrap items-center gap-2 text-sm text-text-secondary">
            <bdi dir="ltr" data-ticket-number>#{{ t.number }}</bdi>
            <rd-ticket-status [status]="t.status" />
            <span>{{ 'support.categories.' + t.category | transloco }}</span>
          </p>
          <h1 class="m-0 mt-1 text-xl font-bold lg:text-2xl" dir="auto" data-ticket-subject>{{ t.subject }}</h1>
          <p class="m-0 mt-1 text-xs text-text-secondary">
            {{ 'support.opened' | transloco: { date: (t.createdAt | rdDate: lang() : 'long') } }}
            @if (t.closedAt; as closed) {
              · {{ 'support.closedOn' | transloco: { date: (closed | rdDate: lang() : 'long') } }}
            }
          </p>
        </header>

        <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [attr.aria-label]="'support.conversation' | transloco">
          <ol class="m-0 list-none divide-y divide-border p-0" data-messages>
            @for (m of t.messages; track m.id) {
              <li class="px-4 py-3 lg:px-5" [class.bg-primary-container]="m.fromSupport" [attr.data-message]="m.id" [attr.data-from]="m.fromSupport ? 'support' : 'member'">
                <p class="m-0 flex items-center gap-2 text-sm">
                  @if (m.fromSupport) {
                    <svg lucideIcon="LifeBuoy" [size]="16" class="text-primary" aria-hidden="true"></svg>
                  }
                  <span class="font-semibold">{{ (m.fromSupport ? 'support.supportTeam' : 'support.you') | transloco }}</span>
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

        @if (t.status !== 'closed') {
          <form class="rd-card flex flex-col gap-3 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" (submit)="reply($event)" data-reply>
            <label for="ticket-reply" class="rd-label m-0">{{ 'support.reply' | transloco }}</label>
            <textarea
              id="ticket-reply"
              class="rd-input rd-autogrow"
              rows="3"
              dir="auto"
              [attr.maxlength]="messageMax"
              [value]="draft()"
              [disabled]="busy()"
              [placeholder]="'support.replyPlaceholder' | transloco"
              (input)="draft.set($any($event.target).value)"
              data-reply-text
            ></textarea>
            <rd-screenshot-picker [files]="files()" (filesChange)="files.set($event)" [disabled]="busy()" />
            @if (error()) {
              <p class="rd-alert rd-alert-error m-0" role="alert" data-reply-error>{{ error() }}</p>
            }
            <div class="flex flex-wrap gap-2">
              <button type="submit" class="rd-btn rd-btn-primary min-h-11 px-5" [disabled]="!canReply()" [attr.aria-busy]="busy()" data-reply-send>
                <svg lucideIcon="Send" [size]="16" aria-hidden="true"></svg>
                {{ 'support.send' | transloco }}
              </button>
              <button type="button" class="rd-btn rd-btn-outline min-h-11 px-4" [disabled]="busy()" (click)="closing.set(true)" data-ticket-close>{{ 'support.close' | transloco }}</button>
            </div>
          </form>
        } @else {
          <section class="rd-card flex flex-wrap items-center gap-3 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" data-ticket-closed>
            @if (t.canReopen) {
              <p class="m-0 min-w-0 flex-1 text-sm text-text-secondary">{{ 'support.closedCanReopen' | transloco }}</p>
              <button type="button" class="rd-btn rd-btn-primary min-h-11 px-4" [disabled]="busy()" (click)="reopen()" data-ticket-reopen>{{ 'support.reopen' | transloco }}</button>
            } @else {
              <p class="m-0 min-w-0 flex-1 text-sm text-text-secondary">{{ 'support.closedExpired' | transloco }}</p>
              <a routerLink="/support" class="rd-btn rd-btn-primary min-h-11 px-4" data-ticket-new>{{ 'support.newTicket' | transloco }}</a>
            }
            @if (error()) {
              <p class="rd-alert rd-alert-error m-0 w-full" role="alert" data-reply-error>{{ error() }}</p>
            }
          </section>
        }
      }
      @case ('error') {
        <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
          @if (notFound()) {
            <rd-empty-state [title]="'errors.support.ticket_not_found' | transloco" data-ticket-not-found>
              <a routerLink="/support/tickets" class="rd-btn rd-btn-primary mt-3">{{ 'support.myTickets' | transloco }}</a>
            </rd-empty-state>
          } @else {
            <rd-error-state [message]="'support.loadError' | transloco" (retry)="load()" />
          }
        </div>
      }
      @default {
        <div class="rd-card flex flex-col gap-3 p-5 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-busy="true" data-ticket-loading>
          <div class="rd-skeleton h-6 w-2/3" aria-hidden="true"></div>
          <div class="rd-skeleton h-24 w-full" aria-hidden="true"></div>
        </div>
      }
    }

    <rd-bottom-sheet [open]="closing()" role="alertdialog" labelledBy="close-ticket-title" describedBy="close-ticket-body" [dismissible]="!busy()" (closed)="closing.set(false)">
      @if (closing()) {
        <div class="flex flex-col gap-3 pt-1" data-close-sheet>
          <h2 id="close-ticket-title" class="m-0 pe-10 text-xl font-semibold">{{ 'support.closeTitle' | transloco }}</h2>
          <p id="close-ticket-body" class="m-0 text-sm text-text-secondary">{{ 'support.closeBody' | transloco }}</p>
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="closing.set(false)">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="busy()" (click)="close()" data-close-confirm>{{ 'admin.confirm.ok' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class TicketPage {
  private readonly api = inject(SupportApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly title = inject(Title);
  protected readonly lang = inject(LanguageService).lang;

  readonly id = input.required<string>();

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
  protected readonly draft = signal('');
  protected readonly files = signal<File[]>([]);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly closing = signal(false);
  protected readonly canReply = computed(() => {
    const n = this.draft().trim().length;
    return !this.busy() && n >= 1 && n <= MESSAGE_MAX;
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
      this.title.setTitle(`${t ? `#${t.number} ${t.subject}` : this.transloco.translate('support.myTickets')} — ReadIn`);
    });
  }

  async load(): Promise<void> {
    const id = this.id();
    if (this.state().status === 'error') this.state.set({ status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.ticket(id));
      if (id === this.id()) this.state.set({ status: 'loaded', data });
    } catch (error) {
      if (id === this.id()) this.state.set({ status: 'error', notFound: isApiError(error) && error.status === 404 });
    }
  }

  protected async reply(event: Event): Promise<void> {
    event.preventDefault();
    const t = this.data();
    if (!t || !this.canReply()) return;
    await this.run(async () => {
      const message = await firstValueFrom(this.api.reply(t.id, this.draft().trim(), this.files()));
      // A reply moves an answered ticket back to Open.
      this.state.set({ status: 'loaded', data: { ...t, status: 'open', messages: [...t.messages, message], updatedAt: message.createdAt } });
      this.draft.set('');
      this.files.set([]);
    });
  }

  protected async close(): Promise<void> {
    const t = this.data();
    if (!t) return;
    await this.run(async () => {
      await firstValueFrom(this.api.close(t.id));
      this.closing.set(false);
      this.toasts.success(this.transloco.translate('support.closed'));
      await this.load();
    });
  }

  protected async reopen(): Promise<void> {
    const t = this.data();
    if (!t) return;
    await this.run(async () => {
      await firstValueFrom(this.api.reopen(t.id));
      this.toasts.success(this.transloco.translate('support.reopened'));
      await this.load();
    });
  }

  private async run(action: () => Promise<void>): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await action();
    } catch (error) {
      const message = this.message(error);
      if (this.closing()) {
        this.closing.set(false);
        this.toasts.error(message);
      } else this.error.set(message);
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
