import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BottomSheet } from '../bottom-sheet';
import { formatPhoneForDisplay } from './phone-number';

let nextId = 0;

/**
 * "Confirm your number" (SPEC §9.2, step 3 of Create account; also before changing the number in Settings). Without
 * SMS the app can't prove the number is the user's, so they see it large, LTR, with the warning, before it's sent.
 */
@Component({
  selector: 'rd-confirm-phone-dialog',
  imports: [BottomSheet, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" role="alertdialog" [labelledBy]="titleId" [describedBy]="warningId" [dismissible]="!busy()" (closed)="edit.emit()">
      <div class="flex flex-col gap-4 pt-1" data-confirm-phone>
        @if (stepLabel()) {
          <p class="m-0 text-xs font-semibold text-primary">{{ stepLabel() }}</p>
        }
        <h2 [id]="titleId" class="m-0 pe-10 text-xl font-semibold">{{ 'auth.confirmPhone.title' | transloco }}</h2>
        <p class="m-0 rounded-md bg-surface-variant px-4 py-5 text-center font-latin text-3xl font-bold tracking-wide" dir="ltr" data-phone>
          {{ formatted() }}
        </p>
        <p [id]="warningId" class="m-0 flex items-start gap-2 text-sm text-text-secondary">
          <svg lucideIcon="TriangleAlert" [size]="18" class="mt-0.5 shrink-0 text-error" aria-hidden="true"></svg>
          <span>{{ 'auth.confirmPhone.warning' | transloco }}</span>
        </p>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
        <div class="flex flex-col gap-2 sm:flex-row-reverse">
          <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="confirm.emit()" data-confirm>
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ confirmLabel() }}
          </button>
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="edit.emit()" data-edit>
            {{ 'auth.confirmPhone.edit' | transloco }}
          </button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class ConfirmPhoneDialog {
  readonly open = input(false);
  /** E.164. */
  readonly phone = input<string | null>(null);
  readonly confirmLabel = input.required<string>();
  /** e.g. "Step 3 of 3" in the Create account stepper. */
  readonly stepLabel = input<string | null>(null);
  readonly busy = input(false);
  readonly error = input<string | null>(null);
  readonly confirm = output<void>();
  /** "Edit", the close button, Escape or the scrim: back to the form. */
  readonly edit = output<void>();

  private readonly id = nextId++;
  protected readonly titleId = `rd-confirm-phone-title-${this.id}`;
  protected readonly warningId = `rd-confirm-phone-warning-${this.id}`;
  protected readonly formatted = computed(() => formatPhoneForDisplay(this.phone()));
}
