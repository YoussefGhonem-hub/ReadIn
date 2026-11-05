/**
 * Tag names (F32, docs/api/contract-v1.md → Tags): the server's rules 1–3, which the editor applies before adding a
 * chip so the writer sees the problem inline instead of a failed save.
 */

export const MAX_TAGS = 5;
export const TAG_MIN_LENGTH = 2;
export const TAG_MAX_LENGTH = 30;

/** Invisible format characters (Unicode `Cf`): LRM/RLM, bidi isolates, zero-width joiners. */
const FORMAT_CHARS = /\p{Cf}/gu;
const ARABIC_INDIC_DIGITS = /[٠-٩۰-۹]/g;
/** Letters, combining marks, digits, spaces and `- _ . + #`. */
const ALLOWED = /^[\p{L}\p{M}\p{Nd} _.+#-]+$/u;
/** A letter or digit; tatweel (U+0640, `\p{Lm}`) only stretches letters, so it doesn't count (like the server). */
const LETTER_OR_DIGIT = /(?!\u0640)[\p{L}\p{Nd}]/u;
/** §22: Arabic diacritics, Quranic marks and tatweel. */
const ARABIC_MARKS = /[ً-ٰٟۖ-ۭـ]/g;

/** Why a name can't become a new tag (rule 2). */
export type TagNameProblem = 'tooShort' | 'tooLong' | 'charset' | 'noLetter';

/**
 * Rule 1: removes invisible format characters, trims, drops leading `#`s and trims again, turns every run of
 * whitespace into one space, and writes Arabic-Indic digits as 0–9.
 */
export function cleanTagName(raw: string): string {
  return raw
    .replace(FORMAT_CHARS, '')
    .trim()
    .replace(/^#+/, '')
    .trim()
    .replace(/\s+/g, ' ')
    .replace(ARABIC_INDIC_DIGITS, (digit) => String(digit.charCodeAt(0) - (digit >= '۰' ? 0x06f0 : 0x0660)));
}

/**
 * Rule 3: the form two names are compared in (the same tag when equal): cleaned, lower case, without Arabic
 * diacritics or tatweel, with `أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`. So `AI`, `ai` and `#AI` are one tag.
 */
export function normalizeTagName(name: string): string {
  return cleanTagName(name).toLowerCase().replace(ARABIC_MARKS, '').replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه');
}

/**
 * Rule 2, for a cleaned name that would create a new tag: 2–30 characters (UTF-16 units, like the server), only
 * letters, marks, digits, spaces and `- _ . + #`, and at least one letter (tatweel aside) or digit. Null when it
 * is fine. An existing tag's name is always accepted, so a picked suggestion skips this check.
 */
export function tagNameProblem(name: string): TagNameProblem | null {
  if (!ALLOWED.test(name)) return 'charset';
  if (name.length < TAG_MIN_LENGTH) return 'tooShort';
  if (name.length > TAG_MAX_LENGTH) return 'tooLong';
  if (!LETTER_OR_DIGIT.test(name)) return 'noLetter';
  return null;
}

/** `tags` already has the same tag as `name` (rule 3). */
export function hasTag(tags: readonly string[], name: string): boolean {
  const key = normalizeTagName(name);
  return tags.some((tag) => normalizeTagName(tag) === key);
}

/**
 * Adds `raw` to `tags` once cleaned. Unchanged when it is empty, the same tag is already there, the article has 5,
 * or it breaks rule 2 (unless `existing`: the name of a tag that exists, as picked from the suggestions).
 */
export function addTag(tags: readonly string[], raw: string, existing = false): string[] {
  const name = existing ? raw.trim() : cleanTagName(raw);
  if (!name || tags.length >= MAX_TAGS || hasTag(tags, name)) return [...tags];
  if (!existing && tagNameProblem(name)) return [...tags];
  return [...tags, name];
}
