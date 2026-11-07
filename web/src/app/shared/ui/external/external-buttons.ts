import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  ViewEncapsulation,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { ExternalProvider } from '../../../core/api/models';
import { ExternalIdentityService, ExternalResult } from '../../../core/auth/external-identity.service';
import { LanguageService } from '../../../core/i18n/language.service';
import { ThemeService } from '../../../core/theme/theme.service';

/**
 * "Continue with Google / Apple" (SPEC §9.2, ADR 0012). Google's button is our own (the size, corners and border of the
 * form's fields, Google's "G") when the API can trade Google's one-time code; otherwise it is the official one rendered by
 * Google Identity Services, in the UI language and theme. Apple's follows Apple's rules (black on light, white on dark,
 * the Apple logo). Emits the provider's credential; a closed popup emits nothing.
 */
@Component({
  selector: 'rd-external-buttons',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  // Its classes' rules (not in the global stylesheet, so they stay out of the initial bundle).
  encapsulation: ViewEncapsulation.None,
  styleUrl: './external-buttons.css',
  host: { class: 'block' },
  template: `
    @if (shown().length) {
      <div class="flex flex-col gap-2" data-external-buttons>
        @if (shows('google')) {
          @if (external.googleCodeSignIn()) {
            <button
              type="button"
              class="rd-btn rd-google-btn w-full"
              [disabled]="busy()"
              [attr.aria-busy]="busy()"
              (click)="google()"
              data-google-button
              data-google-code
            >
              <svg viewBox="0 0 48 48" width="20" height="20" class="shrink-0" aria-hidden="true">
                <path
                  fill="#EA4335"
                  d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
                />
                <path
                  fill="#4285F4"
                  d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
                />
                <path
                  fill="#FBBC05"
                  d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
                />
                <path
                  fill="#34A853"
                  d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
                />
              </svg>
              <span>{{ (text() === 'signin_with' ? 'auth.external.googleSignIn' : 'auth.external.google') | transloco }}</span>
            </button>
          } @else {
            <div class="relative flex min-h-11 justify-center" [class.pointer-events-none]="busy()" [class.opacity-60]="busy()">
              <!-- Light color-scheme: in dark mode Chrome would paint Google's iframe on an opaque white box. -->
              <div #google class="flex w-full max-w-[400px] justify-center [color-scheme:light]" [attr.aria-busy]="busy()" data-google-button></div>
            </div>
          }
          @if (googleFailed()) {
            <p class="rd-field-hint m-0 text-center" role="status">{{ 'auth.external.unavailable' | transloco: { provider: 'Google' } }}</p>
          }
        }
        @if (shows('apple')) {
          <button type="button" class="rd-apple-btn w-full" [disabled]="busy()" (click)="apple()" data-apple-button>
            <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" fill="currentColor">
              <path
                d="M16.37 1.43c0 1.14-.49 2.27-1.18 3.08-.74.9-1.99 1.57-2.99 1.57-.12 0-.23-.02-.3-.03-.01-.06-.04-.22-.04-.39 0-1.15.57-2.27 1.2-2.98.81-.94 2.15-1.64 3.25-1.68.03.13.06.28.06.43zm4.56 15.71c-.03.07-.46 1.58-1.52 3.12-.94 1.34-1.94 2.71-3.43 2.71-1.52 0-1.9-.88-3.63-.88-1.7 0-2.3.91-3.67.91-1.38 0-2.33-1.26-3.43-2.8C3.96 18.38 2.93 15.57 2.93 12.92c0-4.28 2.8-6.55 5.55-6.55 1.45 0 2.68.95 3.6.95.87 0 2.22-1.01 3.9-1.01.62 0 2.89.06 4.38 2.19-.13.09-2.38 1.37-2.38 4.19 0 3.26 2.85 4.42 2.95 4.45z"
              />
            </svg>
            <span>{{ appleLabel() ?? ('auth.external.apple' | transloco) }}</span>
          </button>
        }
      </div>
    }
  `,
})
export class ExternalButtons {
  /** Restrict to these providers (e.g. the linked ones, to confirm a sensitive action). Default: every available one. */
  readonly only = input<ExternalProvider[] | null>(null);
  readonly busy = input(false);
  /** Google button wording: "Continue with Google" or "Sign in with Google". */
  readonly text = input<'continue_with' | 'signin_with'>('continue_with');
  /** Apple button wording when it confirms an action (e.g. "Confirm with Apple"); default "Continue with Apple". */
  readonly appleLabel = input<string | null>(null);
  readonly credential = output<ExternalResult>();

  protected readonly external = inject(ExternalIdentityService);
  private readonly theme = inject(ThemeService);
  private readonly language = inject(LanguageService);
  private readonly googleHost = viewChild<ElementRef<HTMLElement>>('google');
  protected readonly googleFailed = signal(false);

  protected readonly shown = computed(() => {
    const only = this.only();
    return this.external.providers().filter((p) => !only || only.includes(p));
  });

  constructor() {
    void this.external.load();
    // Our own button: load Google's script before the click, so the popup opens within it.
    effect(() => {
      if (!this.shows('google') || !this.external.googleCodeSignIn()) return;
      untracked(() => {
        this.googleFailed.set(false);
        this.external.prepareGoogleCode().catch(() => this.googleFailed.set(true));
      });
    });
    // Google's button: (re)render it when it appears and whenever the theme or the UI language changes.
    effect(() => {
      const host = this.googleHost()?.nativeElement;
      const theme = this.theme.resolved();
      const locale = this.language.lang();
      const text = this.text();
      if (!host) return;
      untracked(() => {
        this.googleFailed.set(false);
        const width = host.getBoundingClientRect().width || 320;
        this.external
          .renderGoogleButton(host, { theme, locale, width, text }, (result) => this.emit(result))
          .catch(() => this.googleFailed.set(true));
      });
    });
  }

  protected shows(provider: ExternalProvider): boolean {
    return this.shown().includes(provider);
  }

  /** A second click opens the popup again; the first request then ends with nothing. */
  protected async google(): Promise<void> {
    if (this.busy()) return;
    const result = await this.external.signInWithGoogle().catch(() => {
      this.googleFailed.set(true); // the script was blocked or the network is down
      return null;
    });
    if (result) {
      this.googleFailed.set(false);
      this.emit(result);
    }
  }

  protected async apple(): Promise<void> {
    if (this.busy()) return;
    const result = await this.external.signInWithApple().catch(() => null);
    if (result) this.emit(result);
  }

  private emit(result: ExternalResult): void {
    if (!this.busy()) this.credential.emit(result);
  }
}
