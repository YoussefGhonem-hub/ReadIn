import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { PreferencesService } from '../../core/auth/preferences.service';
import { LanguageService, UiLanguage } from '../../core/i18n/language.service';

/** UI language switcher for the auth screens: one button showing the other language, in that language. */
@Component({
  selector: 'rd-language-switch',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <button
      type="button"
      class="rd-btn rd-btn-ghost min-h-10 px-3 text-sm"
      [attr.lang]="other()"
      [attr.aria-label]="'auth.switchLanguage' | transloco: { language: otherName() }"
      (click)="switch()"
      data-language-switch
    >
      <svg lucideIcon="Languages" [size]="16" aria-hidden="true"></svg>
      <span [attr.dir]="other() === 'ar' ? 'rtl' : 'ltr'">{{ otherName() }}</span>
    </button>
  `,
})
export class LanguageSwitch {
  private readonly language = inject(LanguageService);
  private readonly preferences = inject(PreferencesService);

  protected readonly other = computed<UiLanguage>(() => (this.language.lang() === 'ar' ? 'en' : 'ar'));
  protected readonly otherName = computed(() => (this.other() === 'ar' ? 'العربية' : 'English'));

  protected switch(): void {
    void this.preferences.setUiLanguage(this.other()).catch(() => undefined);
  }
}
