import { DOCUMENT, Injectable, computed, inject, signal } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { CookieService } from '../platform/cookie.service';

export type UiLanguage = 'ar' | 'en';
export const UI_LANGUAGES: readonly UiLanguage[] = ['ar', 'en'];
export const DEFAULT_UI_LANGUAGE: UiLanguage = 'ar';
const COOKIE = 'lang';

export function isUiLanguage(value: unknown): value is UiLanguage {
  return value === 'ar' || value === 'en';
}

/**
 * UI language (SPEC §14.1 axis 1): app strings + layout direction.
 * Independent from the article language. Persisted in the `lang` cookie so SSR renders the right `<html lang dir>`.
 */
@Injectable({ providedIn: 'root' })
export class LanguageService {
  private readonly transloco = inject(TranslocoService);
  private readonly cookies = inject(CookieService);
  private readonly document = inject(DOCUMENT);

  private readonly _lang = signal<UiLanguage>(DEFAULT_UI_LANGUAGE);
  readonly lang = this._lang.asReadonly();
  readonly dir = computed(() => (this._lang() === 'ar' ? 'rtl' : 'ltr'));
  /** BCP-47 locale for Intl formatting, always with Western digits (SPEC §14.2 rule 4). */
  readonly locale = computed(() => (this._lang() === 'ar' ? 'ar-EG-u-nu-latn' : 'en-US'));

  /** Resolves the initial language and loads its translations. Runs as an app initializer on server and browser. */
  async init(): Promise<void> {
    const fromCookie = this.cookies.get(COOKIE);
    await this.apply(isUiLanguage(fromCookie) ? fromCookie : DEFAULT_UI_LANGUAGE);
  }

  async setLanguage(lang: UiLanguage): Promise<void> {
    if (lang === this._lang() && this.transloco.getActiveLang() === lang) return;
    this.cookies.set(COOKIE, lang);
    await this.apply(lang);
  }

  private async apply(lang: UiLanguage): Promise<void> {
    await firstValueFrom(this.transloco.load(lang));
    this.transloco.setActiveLang(lang);
    this._lang.set(lang);
    const html = this.document.documentElement;
    html.setAttribute('lang', lang);
    html.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  }
}
