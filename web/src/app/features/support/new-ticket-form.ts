import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { Router } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { SUPPORT_CATEGORIES, SupportCategory, SupportConfigDto } from '../../core/api/models';
import { SupportApi } from '../../core/api/support.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { MAX_SCREENSHOTS, MAX_SCREENSHOT_BYTES, MESSAGE_MAX, MESSAGE_MIN, SUBJECT_MAX, SUBJECT_MIN, ScreenshotPicker, webDevice } from './support-ui';

/**
 * A new support ticket (F35): category, subject (5–120), message (10–2000) and up to 3 screenshots, with the web's device
 * details (contract decision 10). `POST /support/tickets` as multipart; then the ticket opens. The limits answer
 * `429 support.limit`, and the form says which one (5 new tickets a day, or 10 open at once).
 */
@Component({
  selector: 'rd-new-ticket-form',
  imports: [TranslocoPipe, LucideDynamicIcon, ScreenshotPicker],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <form class="flex flex-col gap-4" (submit)="submit($event)" novalidate data-new-ticket>
      <div>
        <label for="ticket-category" class="rd-label">{{ 'support.form.category' | transloco }}</label>
        <select id="ticket-category" class="rd-input" [value]="category() ?? ''" [disabled]="busy()" (change)="category.set($any($event.target).value || null)" data-ticket-category>
          <option value="" disabled>{{ 'support.form.pickCategory' | transloco }}</option>
          @for (c of categories(); track c) {
            <option [value]="c">{{ 'support.categories.' + c | transloco }}</option>
          }
        </select>
      </div>
      <div>
        <label for="ticket-subject" class="rd-label">{{ 'support.form.subject' | transloco }}</label>
        <input
          id="ticket-subject"
          class="rd-input"
          dir="auto"
          [attr.maxlength]="subjectMax"
          [value]="subject()"
          [disabled]="busy()"
          [attr.aria-invalid]="subjectInvalid() || null"
          aria-describedby="ticket-subject-hint"
          (input)="subject.set($any($event.target).value)"
          data-ticket-subject
        />
        <p id="ticket-subject-hint" class="rd-field-hint flex justify-between gap-2">
          <span>{{ 'support.form.subjectHint' | transloco: { min: subjectMin, max: subjectMax } }}</span>
          <span class="tabular-nums" dir="ltr">{{ subject().trim().length }}/{{ subjectMax }}</span>
        </p>
      </div>
      <div>
        <label for="ticket-message" class="rd-label">{{ 'support.form.message' | transloco }}</label>
        <textarea
          id="ticket-message"
          class="rd-input rd-autogrow"
          rows="6"
          dir="auto"
          [attr.maxlength]="messageMax"
          [value]="message()"
          [disabled]="busy()"
          [placeholder]="'support.form.messagePlaceholder' | transloco"
          [attr.aria-invalid]="messageInvalid() || null"
          aria-describedby="ticket-message-hint"
          (input)="message.set($any($event.target).value)"
          data-ticket-message
        ></textarea>
        <p id="ticket-message-hint" class="rd-field-hint flex justify-between gap-2">
          <span>{{ 'support.form.messageHint' | transloco: { min: messageMin, max: messageMax } }}</span>
          <span class="tabular-nums" dir="ltr">{{ message().trim().length }}/{{ messageMax }}</span>
        </p>
      </div>
      <rd-screenshot-picker [files]="files()" (filesChange)="files.set($event)" [disabled]="busy()" [max]="maxFiles()" [maxBytes]="maxBytes()" />
      <p class="m-0 text-xs text-text-secondary">{{ 'support.form.deviceNote' | transloco }}</p>
      @if (error()) {
        <p class="rd-alert rd-alert-error m-0" role="alert" data-ticket-error>{{ error() }}</p>
      }
      <button type="submit" class="rd-btn rd-btn-primary min-h-11 self-start px-5" [disabled]="!valid() || busy()" [attr.aria-busy]="busy()" data-ticket-send>
        @if (busy()) {
          <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
        }
        {{ 'support.form.send' | transloco }}
      </button>
    </form>
  `,
})
export class NewTicketForm {
  private readonly api = inject(SupportApi);
  private readonly router = inject(Router);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;

  /** `GET /support/config` (null until it answers: the contract's defaults apply). */
  readonly config = input<SupportConfigDto | null>(null);
  /** The screen the member came from (the route before /support). */
  readonly screen = input<string | null>(null);

  protected readonly subjectMin = SUBJECT_MIN;
  protected readonly subjectMax = SUBJECT_MAX;
  protected readonly messageMin = MESSAGE_MIN;
  protected readonly messageMax = MESSAGE_MAX;
  protected readonly categories = computed(() => this.config()?.categories ?? SUPPORT_CATEGORIES);
  protected readonly maxFiles = computed(() => this.config()?.maxAttachments ?? MAX_SCREENSHOTS);
  protected readonly maxBytes = computed(() => this.config()?.maxAttachmentBytes ?? MAX_SCREENSHOT_BYTES);

  protected readonly category = signal<SupportCategory | null>(null);
  protected readonly subject = signal('');
  protected readonly message = signal('');
  protected readonly files = signal<File[]>([]);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  protected readonly subjectInvalid = computed(() => {
    const n = this.subject().trim().length;
    return n > 0 && (n < SUBJECT_MIN || n > SUBJECT_MAX);
  });
  protected readonly messageInvalid = computed(() => {
    const n = this.message().trim().length;
    return n > 0 && (n < MESSAGE_MIN || n > MESSAGE_MAX);
  });
  protected readonly valid = computed(() => {
    const s = this.subject().trim().length;
    const m = this.message().trim().length;
    return !!this.category() && s >= SUBJECT_MIN && s <= SUBJECT_MAX && m >= MESSAGE_MIN && m <= MESSAGE_MAX;
  });

  async submit(event: Event): Promise<void> {
    event.preventDefault();
    const category = this.category();
    if (!category || !this.valid() || this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      const ticket = await firstValueFrom(
        this.api.create({ category, subject: this.subject().trim(), message: this.message().trim(), screenshots: this.files(), device: webDevice(this.lang(), this.screen()) }),
      );
      this.toasts.success(this.transloco.translate('support.form.sent', { number: ticket.number }));
      await this.router.navigate(['/support/tickets', ticket.id]);
    } catch (error) {
      this.error.set(this.message$(error));
    } finally {
      this.busy.set(false);
    }
  }

  /** `support.limit` says which limit (`limit: daily | open`); a validation failure names its first field code. */
  private message$(error: unknown): string {
    if (isApiError(error) && error.code === 'support.limit') {
      const limit = (error.problem as { limit?: string } | null)?.limit;
      if (limit === 'daily' || limit === 'open') return this.transloco.translate(`support.limit.${limit}`);
    }
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}
