import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export type ArticleFontSize = 's' | 'm' | 'l' | 'xl';
export const ARTICLE_FONT_SIZES: readonly ArticleFontSize[] = ['s', 'm', 'l', 'xl'];
const STORAGE_KEY = 'rd.reader.fontSize';

/**
 * Article font size S/M/L/XL (F04, F18) — a per-device convenience kept in localStorage.
 * Maps to the `--rd-article-size-*` tokens. Server renders `m`; the browser applies the saved size after hydration.
 */
@Injectable({ providedIn: 'root' })
export class ReaderPrefsService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  readonly fontSize = signal<ArticleFontSize>(this.read());

  setFontSize(size: ArticleFontSize): void {
    this.fontSize.set(size);
    if (!this.isBrowser) return;
    try {
      localStorage.setItem(STORAGE_KEY, size);
    } catch {
      /* storage unavailable (private mode): keep the in-memory value */
    }
  }

  /** CSS value for `--rd-article-size`. */
  cssSize(size: ArticleFontSize = this.fontSize()): string {
    return `var(--rd-article-size-${size})`;
  }

  private read(): ArticleFontSize {
    if (!this.isBrowser) return 'm';
    try {
      const value = localStorage.getItem(STORAGE_KEY);
      return (ARTICLE_FONT_SIZES as readonly string[]).includes(value ?? '') ? (value as ArticleFontSize) : 'm';
    } catch {
      return 'm';
    }
  }
}
