import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { safeReturnUrl } from '../../core/auth/account-setup';
import { AuthFrame, AuthShowcase } from './auth-frame';
import { ExternalSignIn } from './external-sign-in';

/**
 * Welcome (SPEC §9.2): logo + tagline, Create account, Sign in, Continue with Google / Apple, Browse as guest, UI
 * language switcher. The logo, the tagline and the language switcher come from the shared frame, with the brand showcase
 * beside it on wide screens; on phones a small version of its cards sits above the title.
 */
@Component({
  selector: 'rd-welcome-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, AuthFrame, AuthShowcase, ExternalSignIn],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <rd-auth-frame>
      <main class="flex w-full max-w-[420px] flex-col items-center text-center lg:items-start lg:text-start" data-welcome>
        <rd-auth-showcase class="rd-auth-rise mb-8 w-full lg:hidden" style="--d: 0ms" [compact]="true" />
        <h1 class="rd-auth-rise rd-auth-ink m-0 text-[2rem] font-bold leading-tight tracking-tight sm:text-[2.5rem]" style="--d: 60ms">
          {{ 'auth.welcome.title' | transloco }}
        </h1>
        <p class="rd-auth-rise m-0 mt-4 text-text-secondary sm:text-lg" style="--d: 140ms">{{ 'auth.welcome.body' | transloco }}</p>
        <ul class="m-0 mt-8 flex w-full list-none flex-col gap-3 p-0 text-start text-sm">
          <li class="rd-auth-rise flex items-center gap-3" style="--d: 220ms">
            <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container" aria-hidden="true">
              <svg lucideIcon="Sparkles" [size]="18" class="rd-auth-twinkle"></svg>
            </span>
            {{ 'auth.welcome.point1' | transloco }}
          </li>
          <li class="rd-auth-rise flex items-center gap-3" style="--d: 290ms">
            <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-accent-container text-text-primary" aria-hidden="true">
              <svg lucideIcon="Flame" [size]="18" class="rd-auth-twinkle"></svg>
            </span>
            {{ 'auth.welcome.point2' | transloco }}
          </li>
        </ul>
        <div class="rd-auth-rise mt-10 flex w-full flex-col gap-3" style="--d: 380ms">
          <a routerLink="/auth/sign-up" [queryParams]="returnParams()" class="rd-btn rd-btn-primary w-full no-underline" data-create-account>
            <svg lucideIcon="UserPlus" [size]="18" aria-hidden="true"></svg>{{ 'auth.welcome.createAccount' | transloco }}
          </a>
          <a routerLink="/auth/sign-in" [queryParams]="returnParams()" class="rd-btn rd-btn-outline w-full no-underline" data-sign-in>
            <svg lucideIcon="LogIn" [size]="18" class="rd-flip-rtl" aria-hidden="true"></svg>{{ 'auth.welcome.signIn' | transloco }}
          </a>
          <rd-external-sign-in [returnUrl]="returnUrl()" />
          <a [routerLink]="guestUrl()" class="rd-btn rd-btn-ghost w-full no-underline" data-guest>{{ 'auth.continueAsGuest' | transloco }}</a>
        </div>
      </main>
    </rd-auth-frame>
  `,
})
export class WelcomePage {
  readonly returnUrl = input<string | null>(null);

  protected readonly guestUrl = computed(() => safeReturnUrl(this.returnUrl()));
  protected readonly returnParams = computed(() => (this.returnUrl() ? { returnUrl: this.returnUrl() } : {}));
}
