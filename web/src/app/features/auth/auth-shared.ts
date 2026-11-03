import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { MeDto } from '../../core/api/models';
import { Wordmark } from '../../shared/ui/wordmark';

/** Centered card frame shared by the auth pages. */
@Component({
  selector: 'rd-auth-card',
  imports: [RouterLink, TranslocoPipe, Wordmark],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex min-h-dvh flex-col items-center justify-center px-4 py-10' },
  template: `
    <a routerLink="/" class="mb-6 no-underline" [attr.aria-label]="'nav.home' | transloco"><rd-wordmark [size]="30" [withIcon]="true" /></a>
    <main class="rd-card w-full max-w-[420px] p-6 sm:p-8">
      <h1 class="m-0 text-2xl font-semibold">{{ title() }}</h1>
      @if (subtitle()) {
        <p class="m-0 mt-1 text-sm text-text-secondary">{{ subtitle() }}</p>
      }
      <div class="mt-6"><ng-content /></div>
    </main>
    <p class="mt-6 text-center text-xs text-text-secondary">{{ 'app.tagline' | transloco }} · <span dir="ltr">Read daily. Grow daily.</span></p>
  `,
})
export class AuthCard {
  readonly title = input.required<string>();
  readonly subtitle = input<string | null>(null);
}

/** Only same-origin paths are accepted as a post-login redirect (no open redirects). */
export function safeReturnUrl(value: string | null | undefined): string {
  return value && value.startsWith('/') && !value.startsWith('//') && !value.startsWith('/auth') ? value : '/';
}

/** Where to go after a successful sign-in/up: onboarding first when needed (F02). */
export function postSignInUrl(me: MeDto | null, returnUrl: string | null | undefined): string {
  if (me && !me.onboardingCompleted) return '/onboarding';
  return safeReturnUrl(returnUrl);
}
