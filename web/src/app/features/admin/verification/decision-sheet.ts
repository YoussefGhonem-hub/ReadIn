import { ChangeDetectionStrategy, Component, computed, effect, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { AdminVerificationRequestDto } from '../../../core/api/models';
import { isolate } from '../../../shared/directives/bidi';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { REASON_MAX, REASON_MIN } from '../../verification/verification-rules';
import { VerificationDecision } from './admin-verification.store';

/** A decision to confirm: approve, or reject (which needs a reason). */
export interface DecisionDraft {
  kind: VerificationDecision['kind'];
  item: AdminVerificationRequestDto;
}

/**
 * Confirms an admin's decision on a verification request (F19). Approving says what it does (the role, the badge, the
 * file deleted); rejecting needs a reason of 5–500 characters, which the writer sees on their verification page.
 * Emits the decision; the page applies it (at once, put back when the API refuses).
 */
@Component({
  selector: 'rd-decision-sheet',
  imports: [TranslocoPipe, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!draft()" role="alertdialog" labelledBy="decision-title" describedBy="decision-body" (closed)="closed.emit()">
      @if (draft(); as d) {
        @let name = isolate(d.item.user.displayName);
        <form class="flex flex-col gap-3 pt-1" (submit)="submit($event)" data-decision-sheet [attr.data-decision]="d.kind">
          <h2 id="decision-title" class="m-0 pe-10 text-xl font-semibold">{{ 'verification.admin.' + d.kind + 'Sheet.title' | transloco: { name } }}</h2>
          <p id="decision-body" class="m-0 text-sm text-text-secondary">{{ 'verification.admin.' + d.kind + 'Sheet.body' | transloco: { name } }}</p>

          @if (d.kind === 'reject') {
            <div>
              <label for="decision-reason" class="rd-label">{{ 'verification.admin.rejectSheet.reason' | transloco }}</label>
              <textarea
                id="decision-reason"
                dir="auto"
                rows="3"
                class="rd-input rd-autogrow"
                required
                [value]="reason()"
                [attr.maxlength]="reasonMax"
                [placeholder]="'verification.admin.rejectSheet.placeholder' | transloco"
                aria-describedby="decision-reason-hint"
                (input)="reason.set($any($event.target).value)"
                data-decision-reason
              ></textarea>
              <p id="decision-reason-hint" class="m-0 mt-1 flex justify-between gap-2 text-xs text-text-secondary">
                <span>{{ 'verification.admin.rejectSheet.hint' | transloco }}</span>
                <span class="tabular-nums" dir="ltr" data-decision-count>{{ reason().length }}/{{ reasonMax }}</span>
              </p>
            </div>
          }

          <div class="mt-1 flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" (click)="closed.emit()">{{ 'common.cancel' | transloco }}</button>
            <button type="submit" class="rd-btn flex-1" [class]="d.kind === 'reject' ? 'bg-error text-on-error' : 'rd-btn-primary'" [disabled]="!canSubmit()" data-decision-confirm>
              {{ 'verification.admin.' + d.kind | transloco }}
            </button>
          </div>
        </form>
      }
    </rd-bottom-sheet>
  `,
})
export class DecisionSheet {
  /** Opens the sheet; null closes it. */
  readonly draft = input<DecisionDraft | null>(null);
  readonly closed = output<void>();
  readonly decided = output<{ item: AdminVerificationRequestDto; decision: VerificationDecision }>();

  protected readonly isolate = isolate;
  protected readonly reasonMax = REASON_MAX;
  protected readonly reason = signal('');
  protected readonly canSubmit = computed(() => {
    const draft = this.draft();
    if (!draft) return false;
    if (draft.kind === 'approve') return true;
    const length = this.reason().trim().length;
    return length >= REASON_MIN && length <= REASON_MAX;
  });

  constructor() {
    effect(() => {
      this.draft();
      untracked(() => this.reason.set(''));
    });
  }

  protected submit(event: Event): void {
    event.preventDefault();
    const draft = this.draft();
    if (!draft || !this.canSubmit()) return;
    this.decided.emit({ item: draft.item, decision: draft.kind === 'approve' ? { kind: 'approve' } : { kind: 'reject', reason: this.reason().trim() } });
  }
}
