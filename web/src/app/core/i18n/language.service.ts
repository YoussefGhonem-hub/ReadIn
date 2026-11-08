import { DOCUMENT, Injectable, REQUEST, computed, inject, signal } from '@angular/core';
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
 * Public pages the apps open in a given language (F37): `/terms?lang=en`, `/community-guidelines?lang=ar`,
 * `/support?lang=…`. The language shows (server-rendered) without being saved.
 */
export const LANG_PARAM_PATHS: readonly string[] = ['/terms', '/community-guidelines', '/support'];

/**
 * The language `?lang=` asks for on one of {@link LANG_PARAM_PATHS}; null on another page, or when the value is missing
 * or isn't `ar` / `en` (then the usual rules apply). Takes a path or an absolute URL.
 */
export function requestedLanguage(url: string | null | undefined): UiLanguage | null {
  const [path, query] = (url ?? '').replace(/^\w+:\/\/[^/]*/, '').split('#')[0].split('?');
  const lang = new URLSearchParams(query).get('lang');
  return LANG_PARAM_PATHS.includes(path.replace(/\/+$/, '')) && isUiLanguage(lang) ? lang : null;
}

/**
 * UI language (SPEC §14.1 axis 1): app strings + layout direction.
 * Independent from the article language. Persisted in the `lang` cookie so SSR renders the right `<html lang dir>`.
 * A `?lang=` page (F37, {@link requestedLanguage}) shows its language without saving it: from the first paint (here,
 * from the request's URL), then while it is open ({@link showOnly}, called by the page).
 */
@Injectable({ providedIn: 'root' })
export class LanguageService {
  private readonly transloco = inject(TranslocoService);
  private readonly cookies = inject(CookieService);
  private readonly document = inject(DOCUMENT);
  /** Only on the server (the browser has none). */
  private readonly request = inject(REQUEST, { optional: true });

  private readonly _lang = signal<UiLanguage>(DEFAULT_UI_LANGUAGE);
  readonly lang = this._lang.asReadonly();
  readonly dir = computed(() => (this._lang() === 'ar' ? 'rtl' : 'ltr'));
  /** BCP-47 locale for Intl formatting, always with Western digits (SPEC §14.2 rule 4). */
  readonly locale = computed(() => (this._lang() === 'ar' ? 'ar-EG-u-nu-latn' : 'en-US'));
  /** The member's own language (the cookie, or their last pick); a `?lang=` page never changes it. */
  private saved: UiLanguage = DEFAULT_UI_LANGUAGE;
  /** The language shown, or on its way: a newer choice wins over a load still running (leaving one `?lang=` page for another). */
  private target: UiLanguage = DEFAULT_UI_LANGUAGE;

  /**
   * Resolves the initial language and loads its translations. Runs as an app initializer on server and browser: both
   * read the same URL (the request's, `location`), so the first paint and hydration agree.
   */
  async init(): Promise<void> {
    const fromCookie = this.cookies.get(COOKIE);
    this.saved = isUiLanguage(fromCookie) ? fromCookie : DEFAULT_UI_LANGUAGE;
    const url = this.request?.url || this.document.location?.href;
    await this.apply(requestedLanguage(url) ?? this.saved);
  }

  /** A `?lang=` page shows `lang` without saving it; null (the page closed, or no valid `?lang=`) shows the saved one. */
  async showOnly(lang: UiLanguage | null): Promise<void> {
    const shown = lang ?? this.saved;
    if (!this.showing(shown)) await this.apply(shown);
  }

  async setLanguage(lang: UiLanguage): Promise<void> {
    const shown = this.showing(lang);
    if (shown && lang === this.saved) return;
    this.saved = lang;
    this.cookies.set(COOKIE, lang);
    if (!shown) await this.apply(lang);
  }

  private showing(lang: UiLanguage): boolean {
    return lang === this.target && this.transloco.getActiveLang() === lang;
  }

  private async apply(lang: UiLanguage): Promise<void> {
    this.target = lang;
    await firstValueFrom(this.transloco.load(lang));
    if (this.target !== lang) return;
    this.transloco.setActiveLang(lang);
    this._lang.set(lang);
    const html = this.document.documentElement;
    html.setAttribute('lang', lang);
    html.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  }
}
