import { DOCUMENT, DestroyRef, effect, inject } from '@angular/core';
import { environment } from '../../../environments/environment';
import { LanguageService, UiLanguage, isUiLanguage } from './language.service';

const MARK = 'data-rd-lang-alternates';

/**
 * Canonical and hreflang links for a public page the apps open with `?lang=` (F37, LANG_PARAM_PATHS): the language
 * shown is canonical (`{path}?lang=…`), both languages are alternates, and the bare path (the visitor's own language)
 * is `x-default`. Rendered on the server for crawlers.
 */
export function setLanguageAlternates(document: Document, path: string, shown: UiLanguage): void {
  clearLanguageAlternates(document);
  const url = (lang: UiLanguage | null) => `${environment.siteUrl}${path}${lang ? `?lang=${lang}` : ''}`;
  const links: Record<string, string>[] = [
    { rel: 'canonical', href: url(shown) },
    { rel: 'alternate', hreflang: 'ar', href: url('ar') },
    { rel: 'alternate', hreflang: 'en', href: url('en') },
    { rel: 'alternate', hreflang: 'x-default', href: url(null) },
  ];
  for (const attributes of links) {
    const link = document.createElement('link');
    for (const [name, value] of Object.entries(attributes)) link.setAttribute(name, value);
    link.setAttribute(MARK, '');
    document.head.appendChild(link);
  }
}

export function clearLanguageAlternates(document: Document): void {
  document.head.querySelectorAll(`[${MARK}]`).forEach((el) => el.remove());
}

/**
 * For a `?lang=` page (call it in the constructor): while the page is open it shows the language its `?lang=` asks for
 * (`ar` / `en`; anything else: the saved language), never saving it, with the canonical and hreflang links; closing it
 * shows the saved language again. The first paint already has it (LanguageService reads the URL at start).
 */
export function bindPageLanguage(path: () => string, requested: () => string | null | undefined): void {
  const language = inject(LanguageService);
  const document = inject(DOCUMENT);
  effect(() => {
    const lang = requested();
    void language.showOnly(isUiLanguage(lang) ? lang : null);
  });
  effect(() => setLanguageAlternates(document, path(), language.lang()));
  inject(DestroyRef).onDestroy(() => {
    clearLanguageAlternates(document);
    void language.showOnly(null);
  });
}
