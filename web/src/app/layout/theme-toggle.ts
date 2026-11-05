import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { PreferencesService } from '../core/auth/preferences.service';
import { ErrorMessages } from '../core/i18n/error-messages';
import { LanguageService } from '../core/i18n/language.service';
import { ThemeService } from '../core/theme/theme.service';
import { ToastService } from '../shared/ui/toast/toast.service';

/**
 * The top bar's light/dark switch: one click flips the theme you see (System resolves first), saved like Settings
 * saves it (the cookie, and the profile when signed in). The Moon shows in light and the Sun in dark through the
 * `rd-only-*` classes, so a server-rendered page with System already shows the right one. `icon` is the narrow bar's
 * square button; `stacked` is the wide bar's icon above "Theme".
 */
@Component({
  selector: 'rd-theme-toggle',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    <button
      type="button"
      [class]="variant() === 'icon' ? 'rd-icon-btn' : stackedClass"
      [attr.aria-pressed]="dark()"
      [attr.aria-label]="label()"
      [attr.title]="action()"
      data-theme-toggle
      [attr.data-variant]="variant()"
      (click)="toggle()"
    >
      <svg lucideIcon="Moon" [size]="variant() === 'icon' ? 18 : 22" class="rd-only-light shrink-0" aria-hidden="true"></svg>
      <svg lucideIcon="Sun" [size]="variant() === 'icon' ? 18 : 22" class="rd-only-dark shrink-0" aria-hidden="true"></svg>
      @if (variant() === 'stacked') {
        <span class="sr-only max-w-full truncate text-xs leading-4 lg:not-sr-only" aria-hidden="true">{{ 'topbar.theme.label' | transloco }}</span>
      }
    </button>
  `,
})
export class ThemeToggle {
  private readonly theme = inject(ThemeService);
  private readonly preferences = inject(PreferencesService);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;

  readonly variant = input<'icon' | 'stacked'>('icon');

  protected readonly stackedClass =
    'relative flex h-full min-w-12 cursor-pointer flex-col items-center justify-center gap-0.5 px-2 text-text-secondary transition-colors hover:text-text-primary lg:min-w-20';
  /** The theme on screen is dark (also when System resolves to dark). */
  protected readonly dark = computed(() => this.theme.resolved() === 'dark');
  protected readonly action = computed(() => this.transloco.translate(this.dark() ? 'topbar.theme.toLight' : 'topbar.theme.toDark', {}, this.lang()));
  /** The stacked variant shows "Theme": its name starts with it (label in name). */
  protected readonly label = computed(() =>
    this.variant() === 'icon' ? this.action() : this.transloco.translate('topbar.theme.named', { action: this.action() }, this.lang()),
  );

  protected async toggle(): Promise<void> {
    try {
      await this.preferences.setTheme(this.dark() ? 'light' : 'dark');
    } catch (error) {
      // The theme already changed here; only saving it to the profile failed.
      this.toasts.error(this.errors.forError(error));
    }
  }
}
