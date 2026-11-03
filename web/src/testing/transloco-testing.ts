import { TranslocoTestingModule, TranslocoTestingOptions } from '@jsverse/transloco';
import ar from '../../public/i18n/ar.json';
import en from '../../public/i18n/en.json';

/** Real ar/en translations for component tests (default UI language: ar). */
export function translocoTesting(options: TranslocoTestingOptions = {}) {
  return TranslocoTestingModule.forRoot({
    langs: { ar, en },
    translocoConfig: { availableLangs: ['ar', 'en'], defaultLang: 'ar' },
    preloadLangs: true,
    ...options,
  });
}
