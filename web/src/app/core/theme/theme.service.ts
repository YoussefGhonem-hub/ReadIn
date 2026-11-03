import { DOCUMENT, DestroyRef, Injectable, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { CookieService } from '../platform/cookie.service';

export type ThemePreference = 'system' | 'light' | 'dark';
export type ResolvedTheme = 'light' | 'dark';
export const THEME_PREFERENCES: readonly ThemePreference[] = ['system', 'light', 'dark'];
const COOKIE = 'theme';

export function isThemePreference(value: unknown): value is ThemePreference {
  return value === 'system' || value === 'light' || value === 'dark';
}

/**
 * Light / Dark / System theme (SPEC §15.5).
 * - Preference lives in the `theme` cookie so SSR renders `<html data-theme>` and there is no flash.
 * - `data-theme="system"` lets tokens.css follow `prefers-color-scheme` without JS.
 * - Syncing to the user profile is done by PreferencesService; this service stays auth-agnostic.
 */
@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly document = inject(DOCUMENT);
  private readonly cookies = inject(CookieService);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly _preference = signal<ThemePreference>('system');
  private readonly systemPrefersDark = signal(false);

  readonly preference = this._preference.asReadonly();
  /** Effective theme. On the server with `system`, this is `light` (CSS still resolves the real one). */
  readonly resolved = computed<ResolvedTheme>(() => {
    const pref = this._preference();
    if (pref !== 'system') return pref;
    return this.systemPrefersDark() ? 'dark' : 'light';
  });

  constructor() {
    const fromCookie = this.cookies.get(COOKIE);
    this._preference.set(isThemePreference(fromCookie) ? fromCookie : 'system');
    this.applyAttribute();

    if (this.isBrowser && typeof matchMedia === 'function') {
      const query = matchMedia('(prefers-color-scheme: dark)');
      this.systemPrefersDark.set(query.matches);
      const onChange = (e: MediaQueryListEvent) => this.systemPrefersDark.set(e.matches);
      query.addEventListener('change', onChange);
      inject(DestroyRef).onDestroy(() => query.removeEventListener('change', onChange));
    }
  }

  setPreference(preference: ThemePreference): void {
    this._preference.set(preference);
    this.cookies.set(COOKIE, preference);
    this.applyAttribute();
  }

  private applyAttribute(): void {
    this.document.documentElement.setAttribute('data-theme', this._preference());
  }
}
