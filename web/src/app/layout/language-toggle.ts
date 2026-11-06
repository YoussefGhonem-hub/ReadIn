import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { PreferencesService } from '../core/auth/preferences.service';
import { ErrorMessages } from '../core/i18n/error-messages';
import { LanguageService, UiLanguage } from '../core/i18n/language.service';
import { ToastService } from '../shared/ui/toast/toast.service';

/** Each language's name in itself: the switch offers the other one, so a reader who can't read this one still finds it. */
const ENDONYMS: Record<UiLanguage, { name: string; short: string }> = {
  ar: { name: 'العربية', short: 'ع' },
  en: { name: 'English', short: 'EN' },
};

/**
 * The top bar's Arabic/English switch (SPEC §14.1 axis 1): one click changes the interface language and direction,
 * saved like Settings saves it (the `lang` cookie, and the profile when signed in). It shows the other language in its
 * own script. `icon` is the narrow bar's square button with the short name; `stacked` is the wide bar's icon above
 * the full name.
 */
@Component({
  selector: 'rd-language-toggle',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    <button
      type="button"
      [class]="variant() === 'icon' ? 'rd-icon-btn font-semibold text-sm' : stackedClass"
      [attr.aria-label]="action()"
      [attr.title]="action()"
      data-language-toggle
      [attr.data-variant]="variant()"
      (click)="toggle()"
    >
      @if (variant() === 'icon') {
        <span [attr.lang]="target()" aria-hidden="true">{{ endonym().short }}</span>
      } @else {
        <svg lucideIcon="Languages" [size]="22" class="shrink-0" aria-hidden="true"></svg>
        <span class="sr-only max-w-full truncate text-xs leading-4 lg:not-sr-only" [attr.lang]="target()" aria-hidden="true">{{
          endonym().name
        }}</span>
      }
    </button>
  `,
})
export class LanguageToggle {
  private readonly language = inject(LanguageService);
  private readonly preferences = inject(PreferencesService);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);

  readonly variant = input<'icon' | 'stacked'>('icon');

  protected readonly stackedClass =
    'relative flex h-full min-w-12 cursor-pointer flex-col items-center justify-center gap-0.5 px-2 text-text-secondary transition-colors hover:text-text-primary lg:min-w-20';
  /** The language the switch changes to. */
  protected readonly target = computed<UiLanguage>(() => (this.language.lang() === 'ar' ? 'en' : 'ar'));
  protected readonly endonym = computed(() => ENDONYMS[this.target()]);
  protected readonly action = computed(() =>
    this.transloco.translate('auth.switchLanguage', { language: this.endonym().name }, this.language.lang()),
  );

  protected async toggle(): Promise<void> {
    try {
      await this.preferences.setUiLanguage(this.target());
    } catch (error) {
      // The language already changed here; only saving it to the profile failed.
      this.toasts.error(this.errors.forError(error));
    }
  }
}
