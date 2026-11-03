import { ChangeDetectionStrategy, Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ModerationApi } from '../../core/api/moderation.api';
import { REPORT_REASONS, ReportReason } from '../../core/api/models';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CommentErrors } from './comment-errors';
import { REPORT_DETAILS_MAX_LENGTH } from './comment-text';
import { CommentsStore } from './comments.store';

/**
 * Report a comment (F11, stored for the F22 queue): a reason and optional details (≤ 500). Reporting the same comment
 * again succeeds too (the API treats it as a no-op), so the thanks toast always follows a success.
 */
@Component({
  selector: 'rd-report-comment-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="report-comment-title" [dismissible]="!busy()" (closed)="close()">
      <form class="flex flex-col gap-3 pt-1" (submit)="submit($event)" data-report-sheet>
        <h2 id="report-comment-title" class="m-0 pe-10 text-xl font-semibold">{{ 'comments.report.title' | transloco }}</h2>
        <fieldset class="m-0 flex flex-col gap-1 border-0 p-0">
          <legend class="mb-2 p-0 text-sm text-text-secondary">{{ 'comments.report.body' | transloco }}</legend>
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
              <span class="text-sm">{{ 'comments.report.reasons.' + option | transloco }}</span>
            </label>
          }
        </fieldset>
        <div>
          <label for="report-details" class="rd-label">{{ 'comments.report.details' | transloco }}</label>
          <textarea
            id="report-details"
            dir="auto"
            rows="3"
            class="rd-input rd-autogrow"
            [value]="details()"
            [attr.maxlength]="detailsMax"
            [placeholder]="'comments.report.detailsPlaceholder' | transloco"
            [disabled]="busy()"
            aria-describedby="report-details-count"
            (input)="details.set($any($event.target).value)"
            data-report-details
          ></textarea>
          <p id="report-details-count" class="m-0 mt-1 text-end text-xs text-text-secondary tabular-nums" dir="ltr">{{ details().length }}/{{ detailsMax }}</p>
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error m-0" role="alert" data-report-error>{{ error() }}</p>
        }
        <div class="flex gap-2">
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
          <button type="submit" class="rd-btn rd-btn-primary flex-1" [disabled]="!reason() || busy()" [attr.aria-busy]="busy()" data-report-submit>
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ 'comments.report.submit' | transloco }}
          </button>
        </div>
      </form>
    </rd-bottom-sheet>
  `,
})
export class ReportCommentSheet {
  private readonly store = inject(CommentsStore);
  private readonly api = inject(ModerationApi);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(CommentErrors);

  protected readonly reasons = REPORT_REASONS;
  protected readonly detailsMax = REPORT_DETAILS_MAX_LENGTH;
  protected readonly target = computed(() => {
    const dialog = this.store.dialog();
    return dialog?.kind === 'report' ? dialog.comment : null;
  });
  protected readonly open = computed(() => this.target() !== null);
  protected readonly reason = signal<ReportReason | null>(null);
  protected readonly details = signal('');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      this.target();
      untracked(() => {
        this.reason.set(null);
        this.details.set('');
        this.error.set(null);
      });
    });
  }

  protected pickReason(reason: ReportReason): void {
    this.reason.set(reason);
    this.error.set(null);
  }

  protected close(): void {
    if (!this.busy()) this.store.closeDialog();
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    const comment = this.target();
    const reason = this.reason();
    if (!comment || !reason || this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(this.api.reportComment(comment.id, reason, this.details()));
      this.busy.set(false);
      this.store.closeDialog();
      this.toasts.success(this.transloco.translate('comments.report.thanks'));
    } catch (error) {
      this.error.set(this.errors.message(error));
    } finally {
      this.busy.set(false);
    }
  }
}

/** "Delete this comment?" for your own comment, or as a moderator (audited). */
@Component({
  selector: 'rd-delete-comment-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet
      [open]="open()"
      role="alertdialog"
      labelledBy="delete-comment-title"
      describedBy="delete-comment-body"
      [dismissible]="!busy()"
      (closed)="close()"
    >
      <div class="flex flex-col gap-3 pt-1" data-delete-comment-sheet>
        <h2 id="delete-comment-title" class="m-0 pe-10 text-xl font-semibold">
          {{ (asModerator() ? 'comments.deleteSheet.moderatorTitle' : 'comments.deleteSheet.title') | transloco }}
        </h2>
        <p id="delete-comment-body" class="m-0 text-sm text-text-secondary">
          {{ (asModerator() ? 'comments.deleteSheet.moderatorBody' : 'comments.deleteSheet.body') | transloco }}
        </p>
        @if (error()) {
          <p class="rd-alert rd-alert-error m-0" role="alert">{{ error() }}</p>
        }
        <div class="mt-2 flex gap-2">
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
          <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="busy()" [attr.aria-busy]="busy()" data-confirm-delete (click)="confirm()">
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ 'comments.delete' | transloco }}
          </button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class DeleteCommentSheet {
  private readonly store = inject(CommentsStore);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(CommentErrors);

  protected readonly target = computed(() => {
    const dialog = this.store.dialog();
    return dialog?.kind === 'delete' || dialog?.kind === 'moderatorDelete' ? dialog : null;
  });
  protected readonly open = computed(() => this.target() !== null);
  protected readonly asModerator = computed(() => this.target()?.kind === 'moderatorDelete');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      this.target();
      untracked(() => this.error.set(null));
    });
  }

  protected close(): void {
    if (!this.busy()) this.store.closeDialog();
  }

  protected async confirm(): Promise<void> {
    const target = this.target();
    if (!target || this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      if (target.kind === 'moderatorDelete') {
        await this.store.moderate(target.comment.id, 'delete');
        this.toasts.success(this.transloco.translate('comments.moderation.deleted'));
      } else {
        await this.store.remove(target.comment.id);
      }
      this.busy.set(false);
      this.store.closeDialog();
    } catch (error) {
      this.error.set(this.errors.message(error));
    } finally {
      this.busy.set(false);
    }
  }
}
