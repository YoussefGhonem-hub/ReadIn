import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { isApiError } from '../../core/api/api.config';
import { LanguageService } from '../../core/i18n/language.service';
import { LanguageSwitch } from '../../shared/ui/language-switch';
import { Wordmark } from '../../shared/ui/wordmark';

/** Centered card frame shared by the auth screens, with the UI language switcher. */
@Component({
  selector: 'rd-auth-card',
  imports: [RouterLink, TranslocoPipe, Wordmark, LanguageSwitch],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative flex min-h-dvh flex-col items-center justify-center px-4 pb-10 pt-16' },
  template: `
    <div class="absolute end-3 top-3"><rd-language-switch /></div>
    <a routerLink="/" class="mb-6 no-underline" [attr.aria-label]="'nav.home' | transloco"><rd-wordmark [size]="30" [withIcon]="true" /></a>
    <main class="rd-card w-full max-w-[440px] p-6 sm:p-8">
      <ng-content select="[rdAuthCardTop]" />
      <h1 class="m-0 text-2xl font-semibold">{{ title() }}</h1>
      @if (subtitle()) {
        <p class="m-0 mt-1 text-sm text-text-secondary">{{ subtitle() }}</p>
      }
      <div class="mt-6"><ng-content /></div>
    </main>
    <p class="mt-6 text-center text-xs text-text-secondary">
      {{ 'app.tagline' | transloco }}
      @if (lang() === 'ar') {
        · <span dir="ltr">Read daily. Grow daily.</span>
      }
    </p>
  `,
})
export class AuthCard {
  readonly title = input.required<string>();
  readonly subtitle = input<string | null>(null);
  protected readonly lang = inject(LanguageService).lang;
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
        <span class="h-1.5 flex-1 rounded-chip" [class]="step <= current() ? 'bg-primary' : 'bg-border'"></span>
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
