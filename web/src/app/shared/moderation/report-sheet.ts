import { ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ModerationApi } from '../../core/api/moderation.api';
import { ModerationTargetType, REPORT_REASONS, ReportReason } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { BottomSheet } from '../ui/bottom-sheet';
import { ToastService } from '../ui/toast/toast.service';
import { ModerationErrors } from './moderation-errors';

/** Optional report details (contract: ≤ 500). */
export const REPORT_DETAILS_MAX_LENGTH = 500;

/** What is being reported: an article, a comment or a user, by id. */
export interface ReportTarget {
  type: ModerationTargetType;
  id: string;
}

/**
 * The one report sheet (F22) for articles, comments and users: a reason, optional details (≤ 500, with a counter) and
 * Send. Reporting the same target again succeeds too (the API treats it as a no-op), so a success always closes the
 * sheet with the thanks toast; a failure stays in the sheet with its message. Guests get the sign-in prompt instead.
 */
@Component({
  selector: 'rd-report-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="report-sheet-title" [dismissible]="!busy()" (closed)="close()">
      @if (target(); as t) {
        <form class="flex flex-col gap-3 pt-1" (submit)="submit($event)" data-report-sheet [attr.data-report-target]="t.type">
          <h2 id="report-sheet-title" class="m-0 pe-10 text-xl font-semibold">{{ 'report.title.' + t.type | transloco }}</h2>
          <fieldset class="m-0 flex flex-col gap-1 border-0 p-0">
            <legend class="mb-2 p-0 text-sm text-text-secondary">{{ 'report.body.' + t.type | transloco }}</legend>
            @for (option of reasons; track option) {
              <label class="flex min-h-11 cursor-pointer items-center gap-3 rounded-md px-2 hover:bg-surface-variant">
                <input
                  type="radio"
                  name="report-reason"
                  class="h-5 w-5 shrink-0 accent-primary"
                  [value]="option"
                  [checked]="reason() === option"
                  [disabled]="busy()"
                  [attr.data-reason]="option"
                  (change)="pickReason(option)"
                />
                <span class="text-sm">{{ 'report.reasons.' + option | transloco }}</span>
              </label>
            }
          </fieldset>
          <div>
            <label for="report-details" class="rd-label">{{ 'report.details' | transloco }}</label>
            <textarea
              id="report-details"
              dir="auto"
              rows="3"
              class="rd-input rd-autogrow"
              [value]="details()"
              [attr.maxlength]="detailsMax"
              [placeholder]="'report.detailsPlaceholder' | transloco"
              [disabled]="busy()"
              aria-describedby="report-details-count"
              (input)="details.set($any($event.target).value)"
              data-report-details
            ></textarea>
            <p id="report-details-count" class="m-0 mt-1 text-end text-xs text-text-secondary tabular-nums" dir="ltr" data-report-count>
              {{ details().length }}/{{ detailsMax }}
            </p>
          </div>
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-report-error>{{ error() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
            <button type="submit" class="rd-btn rd-btn-primary flex-1" [disabled]="!canSend()" [attr.aria-busy]="busy()" data-report-submit>
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'report.submit' | transloco }}
            </button>
          </div>
        </form>
      }
    </rd-bottom-sheet>
  `,
})
export class ReportSheet {
  private readonly api = inject(ModerationApi);
  private readonly prompt = inject(AuthPromptService);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ModerationErrors);

  /** Opens the sheet for this target; null closes it. */
  readonly target = input<ReportTarget | null>(null);
  /** Cancelled, dismissed, or sent. */
  readonly closed = output<void>();
  /** Sent (or already reported): the API answered 204. */
  readonly reported = output<ReportTarget>();

  protected readonly reasons = REPORT_REASONS;
  protected readonly detailsMax = REPORT_DETAILS_MAX_LENGTH;
  protected readonly reason = signal<ReportReason | null>(null);
  protected readonly details = signal('');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  /** Guests never see the form: they get the sign-in prompt. */
  protected readonly open = computed(() => this.target() !== null && !this.guest());
  protected readonly canSend = computed(() => !!this.reason() && !this.busy() && this.details().length <= this.detailsMax);
  private readonly guest = signal(false);

  constructor() {
    // A new target starts empty.
    effect(() => {
      const target = this.target();
      untracked(() => {
        this.reason.set(null);
        this.details.set('');
        this.error.set(null);
        this.busy.set(false);
        this.guest.set(false);
        if (target && !this.prompt.requireAuth()) {
          this.guest.set(true);
          this.closed.emit();
        }
      });
    });
  }

  protected pickReason(reason: ReportReason): void {
    this.reason.set(reason);
    this.error.set(null);
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    const target = this.target();
    const reason = this.reason();
    if (!target || !reason || !this.canSend()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(this.api.report(target.type, target.id, reason, this.details()));
      this.busy.set(false);
      this.toasts.success(this.transloco.translate('report.thanks'));
      this.reported.emit(target);
      this.closed.emit();
    } catch (error) {
      this.error.set(this.errors.message(error));
    } finally {
      this.busy.set(false);
    }
  }
}
