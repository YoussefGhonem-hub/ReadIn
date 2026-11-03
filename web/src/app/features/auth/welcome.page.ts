import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { safeReturnUrl } from '../../core/auth/account-setup';
import { LanguageSwitch } from '../../shared/ui/language-switch';
import { Wordmark } from '../../shared/ui/wordmark';

/** Welcome (SPEC §9.2): logo + tagline, Create account, Sign in, Browse as guest, UI language switcher. */
@Component({
  selector: 'rd-welcome-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Wordmark, LanguageSwitch],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative flex min-h-dvh flex-col items-center justify-center px-4 pb-10 pt-16' },
  template: `
    <div class="absolute end-3 top-3"><rd-language-switch /></div>
    <main class="flex w-full max-w-[400px] flex-col items-center text-center" data-welcome>
      <rd-wordmark [size]="44" [withIcon]="true" />
      <h1 class="m-0 mt-6 text-3xl font-bold tracking-tight">{{ 'auth.welcome.title' | transloco }}</h1>
      <p class="m-0 mt-3 text-text-secondary">{{ 'auth.welcome.body' | transloco }}</p>
      <ul class="m-0 mt-8 flex w-full list-none flex-col gap-3 p-0 text-start text-sm">
        <li class="flex items-center gap-3">
          <span class="grid h-9 w-9 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container" aria-hidden="true"><svg lucideIcon="Sparkles" [size]="18"></svg></span>
          {{ 'auth.welcome.point1' | transloco }}
        </li>
        <li class="flex items-center gap-3">
          <span class="grid h-9 w-9 shrink-0 place-items-center rounded-md bg-accent-container text-text-primary" aria-hidden="true"><svg lucideIcon="Flame" [size]="18"></svg></span>
          {{ 'auth.welcome.point2' | transloco }}
        </li>
      </ul>
      <div class="mt-10 flex w-full flex-col gap-3">
        <a routerLink="/auth/sign-up" [queryParams]="returnParams()" class="rd-btn rd-btn-primary w-full no-underline" data-create-account>
          <svg lucideIcon="UserPlus" [size]="18" aria-hidden="true"></svg>{{ 'auth.welcome.createAccount' | transloco }}
        </a>
        <a routerLink="/auth/sign-in" [queryParams]="returnParams()" class="rd-btn rd-btn-outline w-full no-underline" data-sign-in>
          <svg lucideIcon="LogIn" [size]="18" class="rd-flip-rtl" aria-hidden="true"></svg>{{ 'auth.welcome.signIn' | transloco }}
        </a>
        <a [routerLink]="guestUrl()" class="rd-btn rd-btn-ghost w-full no-underline" data-guest>{{ 'auth.continueAsGuest' | transloco }}</a>
      </div>
    </main>
  `,
})
export class WelcomePage {
  readonly returnUrl = input<string | null>(null);

  protected readonly guestUrl = computed(() => safeReturnUrl(this.returnUrl()));
  protected readonly returnParams = computed(() => (this.returnUrl() ? { returnUrl: this.returnUrl() } : {}));
}
