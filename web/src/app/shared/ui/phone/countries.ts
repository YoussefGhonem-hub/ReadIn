import data from '../../../../../../shared/countries/countries.json';
import { digitsOnly, toAsciiDigits } from '../../utils/digits';

/**
 * Countries for the phone field (SPEC §9.4). The single source of truth is `shared/countries/countries.json`,
 * generated from libphonenumber-js by `tools/countries`; web and mobile read it as is.
 */
export interface Country {
  iso2: string;
  dialCode: string;
  nameAr: string;
  nameEn: string;
  /** Example mobile number in national format, e.g. "010 01234567". */
  exampleNational: string;
}

export type CountryLanguage = 'ar' | 'en';

export const COUNTRIES: readonly Country[] = data.countries;
/** Shown first, in this order: Egypt, then the other Arab countries. */
export const PINNED_COUNTRIES: readonly string[] = data.pinned;
export const DEFAULT_COUNTRY: string = data.defaultCountry;

const BY_ISO = new Map(COUNTRIES.map((country) => [country.iso2, country]));

export function countryByIso(iso2: string | null | undefined): Country | undefined {
  return iso2 ? BY_ISO.get(iso2.toUpperCase()) : undefined;
}

export function countryName(country: Country, lang: CountryLanguage): string {
  return lang === 'ar' ? country.nameAr : country.nameEn;
}

/** Pinned countries first (in their order), then every other country sorted by its name in the UI language. */
export function sortedCountries(lang: CountryLanguage): Country[] {
  const pinned = PINNED_COUNTRIES.map((iso2) => BY_ISO.get(iso2)).filter((c): c is Country => !!c);
  const collator = new Intl.Collator(lang === 'ar' ? 'ar' : 'en', { sensitivity: 'base' });
  const rest = COUNTRIES.filter((c) => !PINNED_COUNTRIES.includes(c.iso2)).sort((a, b) =>
    collator.compare(countryName(a, lang), countryName(b, lang)),
  );
  return [...pinned, ...rest];
}

/**
 * Folds text for matching: case, Latin accents, Arabic diacritics and tatweel, and the hamza/alef, taa marbuta and
 * alef maqsura variants, so "مصر", "Egypt", "egy" and "الامارات" all find what people expect.
 */
export function foldSearchText(text: string): string {
  return toAsciiDigits(text)
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/[’'`.,()&-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

const FOLDED = new Map(
  COUNTRIES.map((country) => [country.iso2, { ar: foldSearchText(country.nameAr), en: foldSearchText(country.nameEn) }]),
);

/**
 * Filters `countries` (keeping their order) by Arabic name, English name, ISO code or dial code. A query made of
 * digits (optionally starting with "+" or "00") matches dial codes by prefix.
 */
export function searchCountries(countries: readonly Country[], query: string): Country[] {
  const folded = foldSearchText(query);
  if (!folded) return [...countries];

  const dialQuery = /^(\+|00)?\s*[\d\s]+$/.test(toAsciiDigits(query.trim()))
    ? digitsOnly(query).replace(/^00/, '')
    : null;
  if (dialQuery !== null) return countries.filter((c) => c.dialCode.startsWith(dialQuery));

  const iso = folded.length === 2 ? folded.toUpperCase() : null;
  const words = folded.split(' ');
  const matches = (name: string) => words.every((word) => name.includes(word));
  const exact: Country[] = [];
  const others: Country[] = [];
  for (const country of countries) {
    const names = FOLDED.get(country.iso2)!;
    if (iso === country.iso2) exact.push(country);
    else if (matches(names.ar) || matches(names.en)) others.push(country);
  }
  return [...exact, ...others];
}

const LAST_USED_KEY = 'readin.phoneCountry';

function storage(): Storage | null {
  try {
    return typeof localStorage === 'undefined' ? null : localStorage;
  } catch {
    return null; // blocked third-party storage, Safari private mode…
  }
}

/** Remembers the country the user picked (or signed in with) for the next visit. */
export function rememberCountry(iso2: string): void {
  if (countryByIso(iso2)) storage()?.setItem(LAST_USED_KEY, iso2.toUpperCase());
}

/** Region of the first browser language that has one, e.g. "ar-SA" → "SA". */
export function browserRegion(languages: readonly string[]): string | null {
  for (const language of languages) {
    try {
      const region = new Intl.Locale(language).region;
      if (region && countryByIso(region)) return region;
    } catch {
      /* malformed language tag */
    }
  }
  return null;
}

/** Default country (SPEC §9.4): last used → browser region → Egypt. */
export function defaultCountry(languages: readonly string[] = typeof navigator === 'undefined' ? [] : navigator.languages ?? []): string {
  const lastUsed = storage()?.getItem(LAST_USED_KEY);
  if (lastUsed && countryByIso(lastUsed)) return lastUsed;
  return browserRegion(languages) ?? DEFAULT_COUNTRY;
}

/** SVG flag from `flag-icons` (copied to `/flags` by angular.json); emoji flags don't render on Windows. */
export function flagUrl(iso2: string): string {
  const code = iso2.toLowerCase();
  // Ascension Island and Tristan da Cunha are drawn as part of Saint Helena in flag-icons.
  const file = code === 'ac' ? 'sh-ac' : code === 'ta' ? 'sh-ta' : code;
  return `/flags/${file}.svg`;
}
