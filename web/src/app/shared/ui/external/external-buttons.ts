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
 * "Continue with Google / Apple" (SPEC §9.2, ADR 0012). Google's button is the official one rendered by Google
 * Identity Services (its branding rules don't allow a custom button), in the UI language and theme; Apple's follows
 * Apple's rules (black on light, white on dark, the Apple logo). Emits the provider's credential; a closed popup emits
 * nothing.
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
          <div class="relative flex min-h-11 justify-center" [class.pointer-events-none]="busy()" [class.opacity-60]="busy()">
            <div #google class="flex w-full max-w-[400px] justify-center" [attr.aria-busy]="busy()" data-google-button></div>
            @if (googleFailed()) {
              <p class="rd-field-hint m-0 text-center" role="status">{{ 'auth.external.unavailable' | transloco: { provider: 'Google' } }}</p>
            }
          </div>
        }
        @if (shows('apple')) {
          <button type="button" class="rd-apple-btn mx-auto w-full max-w-[400px]" [disabled]="busy()" (click)="apple()" data-apple-button>
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
  /** GIS button wording: "Continue with Google" or "Sign in with Google". */
  readonly text = input<'continue_with' | 'signin_with'>('continue_with');
  /** Apple button wording when it confirms an action (e.g. "Confirm with Apple"); default "Continue with Apple". */
  readonly appleLabel = input<string | null>(null);
  readonly credential = output<ExternalResult>();

  private readonly external = inject(ExternalIdentityService);
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
    // (Re)render Google's button when it appears and whenever the theme or the UI language changes.
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

  protected async apple(): Promise<void> {
    if (this.busy()) return;
    const result = await this.external.signInWithApple().catch(() => null);
    if (result) this.emit(result);
  }

  private emit(result: ExternalResult): void {
    if (!this.busy()) this.credential.emit(result);
  }
}
