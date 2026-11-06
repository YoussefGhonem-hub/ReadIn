import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { isApiError } from '../../core/api/api.config';
import { AuthFrame } from './auth-frame';

/** The auth screens' form, in the shared frame (auth-frame.ts): a card on phones, open on the page beside the showcase on wide screens. */
@Component({
  selector: 'rd-auth-card',
  imports: [AuthFrame],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <rd-auth-frame>
      <main class="rd-card rd-auth-pop w-full max-w-[440px] p-6 sm:p-8 lg:max-w-[420px] lg:border-transparent lg:bg-transparent lg:p-0 lg:shadow-none">
        <ng-content select="[rdAuthCardTop]" />
        <h1 class="rd-auth-rise m-0 text-2xl font-semibold lg:text-[28px] lg:font-bold lg:tracking-tight" style="--d: 60ms">{{ title() }}</h1>
        @if (subtitle()) {
          <p class="rd-auth-rise m-0 mt-1 text-sm text-text-secondary" style="--d: 120ms">{{ subtitle() }}</p>
        }
        <div class="rd-auth-body mt-6"><ng-content /></div>
      </main>
    </rd-auth-frame>
  `,
})
export class AuthCard {
  readonly title = input.required<string>();
  readonly subtitle = input<string | null>(null);
}

/** "Step 1 of 3" with a three-part progress bar (Create account, SPEC §9.2). */
@Component({
  selector: 'rd-auth-steps',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mb-4 block' },
  template: `
    <p class="m-0 mb-2 text-xs font-semibold text-primary" data-step>{{ 'auth.signUp.step' | transloco: { current: current(), total: total() } }}</p>
    <div class="flex gap-1.5" dir="ltr" aria-hidden="true">
      @for (step of steps(); track step) {
        <span class="h-1.5 flex-1 rounded-chip bg-border"><span class="block h-full rounded-chip bg-primary" [class.rd-auth-step-on]="step <= current()" [class.invisible]="step > current()"></span></span>
      }
    </div>
  `,
})
export class AuthSteps {
  readonly current = input.required<number>();
  readonly total = input(3);
  protected steps(): number[] {
    return Array.from({ length: this.total() }, (_, i) => i + 1);
  }
}

/** A submit button that shows a spinner and blocks double submits while `busy`. */
@Component({
  selector: 'rd-submit-button',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <button type="submit" class="rd-btn rd-btn-primary w-full" [disabled]="busy() || disabled()" [attr.aria-busy]="busy()" data-submit>
      @if (busy()) {
        <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
      }
      <ng-content />
    </button>
  `,
})
export class SubmitButton {
  readonly busy = input(false);
  readonly disabled = input(false);
}

/** Validation codes the API returned for one request field (`errors.{field}`), e.g. `['password.too_common']`. */
export function fieldErrors(error: unknown, field: string): string[] {
  return isApiError(error) ? (error.validationErrors[field] ?? []) : [];
}

/** Translation key of an error code (`errors.*`). */
export function errorKey(code: string): string {
  return `errors.${code}`;
}
