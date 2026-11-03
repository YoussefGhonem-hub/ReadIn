import { EnvironmentProviders, Injectable, isDevMode, provideAppInitializer, inject } from '@angular/core';
import { Translation, TranslocoLoader, provideTransloco } from '@jsverse/transloco';
import { DEFAULT_UI_LANGUAGE, LanguageService, UI_LANGUAGES } from './language.service';

/**
 * Loads `public/i18n/{lang}.json` through the bundler instead of HTTP, so translations are available
 * identically during SSR and in the browser (no self-request from the server, no hydration mismatch).
 */
@Injectable({ providedIn: 'root' })
export class BundledTranslocoLoader implements TranslocoLoader {
  getTranslation(lang: string): Promise<Translation> {
    const load = lang === 'en' ? import('../../../../public/i18n/en.json') : import('../../../../public/i18n/ar.json');
    return load.then((m) => m.default as Translation);
  }
}

export function provideI18n(): EnvironmentProviders[] {
  return [
    ...provideTransloco({
      config: {
        availableLangs: [...UI_LANGUAGES],
        defaultLang: DEFAULT_UI_LANGUAGE,
        fallbackLang: DEFAULT_UI_LANGUAGE,
        reRenderOnLangChange: true,
        prodMode: !isDevMode(),
        missingHandler: { useFallbackTranslation: true, logMissingKey: isDevMode() },
      },
      loader: BundledTranslocoLoader,
    }),
    provideAppInitializer(() => inject(LanguageService).init()),
  ];
}
