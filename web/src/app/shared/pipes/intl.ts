import type { TranslocoService } from '@jsverse/transloco';
import type { UiLanguage } from '../../core/i18n/language.service';

// Kept apart from format.pipes.ts so the initial bundle (the 🔥 badge) can use them without pulling in every pipe.

/** Locales always use Western digits for consistency with code (SPEC §14.2 rule 4). */
export function intlLocale(lang: UiLanguage): string {
  return lang === 'ar' ? 'ar-EG-u-nu-latn' : 'en-US';
}

/**
 * Plural-aware translation with the CLDR categories of the UI language (Arabic has zero/one/two/few/many/other).
 * Looks up `{key}.{category}` and falls back to `{key}.other`; `{{count}}` is always available to the string.
 */
export function translatePlural(
  transloco: TranslocoService,
  key: string,
  count: number,
  lang: UiLanguage,
  params: Record<string, unknown> = {},
): string {
  const category = new Intl.PluralRules(intlLocale(lang)).select(count);
  const values = { count, ...params };
  const exact = `${key}.${category}`;
  const text = transloco.translate(exact, values, lang);
  return text && text !== exact ? text : transloco.translate(`${key}.other`, values, lang);
}
