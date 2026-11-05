/**
 * Writer category names (F31, docs/api/contract-v1.md → "Writer categories", Names): the server's cleaning and checks,
 * which the clients run before sending so the writer sees the problem inline. Pure functions, no Angular.
 */

/** A name has 1–40 characters (UTF-16 code units, like the server) after cleaning. */
export const CATEGORY_NAME_MAX = 40;
/** Categories one writer may have (`category.limit`). */
export const MAX_CATEGORIES = 50;
/** The reserved slug of the uncategorized list, "مقالات تانية". A category's slug never starts with `_`. */
export const OTHER_CATEGORY_SLUG = '_other';

/** Invisible format characters (Unicode `Cf`): LRM/RLM, bidi isolates, zero-width joiners. */
const FORMAT_CHARS = /\p{Cf}/gu;
/** Control characters that are not whitespace (whitespace becomes one space first). */
const CONTROL_CHARS = /\p{Cc}/gu;
const ARABIC_INDIC_DIGITS = /[٠-٩۰-۹]/g;
/** A letter or digit; tatweel (U+0640) only stretches letters, so it doesn't count. */
const LETTER_OR_DIGIT = /(?!ـ)[\p{L}\p{Nd}]/u;
/** §22: Arabic diacritics, the superscript alef, Quranic marks and tatweel. */
const ARABIC_MARKS = /[ً-ٰٟۖ-ۭـ]/g;

/** Why a name can't be saved (`category.name_invalid`). */
export type CategoryNameProblem = 'empty' | 'tooLong' | 'noLetter';

/**
 * Like tag rule 1, but a leading `#` stays: format characters out, every run of whitespace → one space, other control
 * characters out, trimmed, and Arabic-Indic digits written as 0–9.
 */
export function cleanCategoryName(raw: string): string {
  return raw
    .replace(FORMAT_CHARS, '')
    .replace(/\s+/g, ' ')
    .replace(CONTROL_CHARS, '')
    .trim()
    .replace(ARABIC_INDIC_DIGITS, (digit) => String(digit.charCodeAt(0) - (digit >= '۰' ? 0x06f0 : 0x0660)));
}

/** The problem with a cleaned name, or null: 1–40 characters with at least one letter (tatweel aside) or digit. */
export function categoryNameProblem(name: string): CategoryNameProblem | null {
  if (!name) return 'empty';
  if (name.length > CATEGORY_NAME_MAX) return 'tooLong';
  if (!LETTER_OR_DIGIT.test(name)) return 'noLetter';
  return null;
}

/** The form two names are compared in (tag rule 3): lower case and the §22 Arabic normalization. */
export function normalizeCategoryName(name: string): string {
  return cleanCategoryName(name).toLowerCase().replace(ARABIC_MARKS, '').replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه');
}

/** Another of `categories` (not `exceptId`) already has this name, ignoring case and Arabic spelling variants. */
export function categoryNameTaken(categories: readonly { id: string; name: string }[], name: string, exceptId: string | null = null): boolean {
  const key = normalizeCategoryName(name);
  return categories.some((c) => c.id !== exceptId && normalizeCategoryName(c.name) === key);
}

/**
 * A category page's route, `/@{username}/c/{slug}` (`_other`: the uncategorized list). The router percent-encodes the
 * slug, which may hold Arabic letters; it comes from the server, a client never builds one from a name.
 */
export function categoryLink(username: string, slug: string): string[] {
  return [`/@${username}`, 'c', slug];
}

/** The same page as a path (canonical URLs, Open Graph). */
export function categoryPath(username: string, slug: string): string {
  return `/@${encodeURIComponent(username)}/c/${encodeURIComponent(slug)}`;
}
