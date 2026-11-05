import { ArticleLanguage, SearchTopicDto, SearchType } from '../../core/api/models';
import { SearchFilters } from '../../core/api/search.api';
import { cleanTagName, normalizeTagName } from '../editor/tag-rules';

/**
 * The search query and the search page's URL (F16, docs/api/contract-v1.md → Search). Pure functions, shared by the
 * page and the header box.
 */

/** Wait this long after the last keystroke before searching (the contract's rate limit assumes it). */
export const SEARCH_DEBOUNCE_MS = 300;
/** As you type, searching starts at 2 characters; Enter searches from 1. */
export const MIN_TYPED_LENGTH = 2;
/** The cleaned query's limit (UTF-16 code units, like the API). */
export const MAX_QUERY_LENGTH = 100;
/** Room in the box for stray spaces and invisible characters; the 100 count after cleaning. */
export const INPUT_MAX_LENGTH = 200;
/** Results per page. */
export const SEARCH_PAGE_SIZE = 20;

export const SEARCH_TYPES: readonly SearchType[] = ['articles', 'users', 'topics', 'tags'];

/** A letter or digit; tatweel (U+0640) only stretches letters, so it doesn't count (like the server). */
const LETTER_OR_DIGIT = /(?!ـ)[\p{L}\p{Nd}]/u;

/**
 * The query as the API cleans it before matching: invisible format characters out, Arabic-Indic digits → 0–9,
 * whitespace runs → one space, trimmed, leading `#`s dropped (Tags rule 1), then one leading `@` (`@mona` finds Mona).
 */
export function cleanSearchQuery(raw: string | null | undefined): string {
  const cleaned = cleanTagName(raw ?? '');
  return cleaned.startsWith('@') ? cleaned.slice(1).trim() : cleaned;
}

/** The API accepts it: 1–100 characters after cleaning, with a letter or digit (else `search.query_invalid`). */
export function isSearchable(cleaned: string): boolean {
  return cleaned.length >= 1 && cleaned.length <= MAX_QUERY_LENGTH && LETTER_OR_DIGIT.test(cleaned);
}

/** Two queries that search the same thing (case, Arabic diacritics and letter forms aside): one recent search. */
export function searchKey(query: string): string {
  return normalizeTagName(cleanSearchQuery(query));
}

/** The reading-time chips: `≤ 5`, `5–10` and `> 10` minutes. */
export type ReadingTime = 'short' | 'medium' | 'long';
export const READING_TIMES: readonly ReadingTime[] = ['short', 'medium', 'long'];
const READING_TIME_RANGES: Record<ReadingTime, Pick<SearchFilters, 'minMinutes' | 'maxMinutes'>> = {
  short: { maxMinutes: 5 },
  medium: { minMinutes: 6, maxMinutes: 10 },
  long: { minMinutes: 11 },
};

export const ARTICLE_LANGUAGES: readonly ArticleLanguage[] = ['ar-EG', 'en'];

/** One search: what `/search` shows, read from its URL (`?q=&type=&field=&lang=&time=`). */
export interface SearchRequest {
  /** Cleaned. */
  q: string;
  type: SearchType;
  /** A field slug (articles only). */
  field: string | null;
  lang: ArticleLanguage | null;
  time: ReadingTime | null;
}

/** What the page's URL holds; null leaves a parameter out. */
export interface SearchUrl {
  q?: string | null;
  type?: SearchType;
  field?: string | null;
  lang?: ArticleLanguage | null;
  time?: ReadingTime | null;
}

export interface SearchParams {
  q?: string | null;
  type?: string | null;
  field?: string | null;
  lang?: string | null;
  time?: string | null;
}

/** The URL's search, or null without a query. Unknown values fall back to the defaults (Articles, no filter). */
export function searchRequestOf(params: SearchParams): SearchRequest | null {
  const q = cleanSearchQuery(params.q);
  if (!q) return null;
  return {
    q,
    type: parseType(params.type),
    field: params.field?.trim() || null,
    lang: ARTICLE_LANGUAGES.includes(params.lang as ArticleLanguage) ? (params.lang as ArticleLanguage) : null,
    time: READING_TIMES.includes(params.time as ReadingTime) ? (params.time as ReadingTime) : null,
  };
}

export function parseType(value: string | null | undefined): SearchType {
  return SEARCH_TYPES.includes(value as SearchType) ? (value as SearchType) : 'articles';
}

/** The filters sent with a request: only Articles has any. */
export function filtersOf(request: SearchRequest): SearchFilters {
  if (request.type !== 'articles') return {};
  return { field: request.field, lang: request.lang, ...(request.time ? READING_TIME_RANGES[request.time] : {}) };
}

/** The article filters in use. */
export function hasFilters(request: SearchRequest | null): boolean {
  return !!request && request.type === 'articles' && !!(request.field || request.lang || request.time);
}

/** Same results: the same query and tab, and for Articles the same filters (other tabs ignore them). */
export function sameSearch(a: SearchRequest | null, b: SearchRequest | null): boolean {
  if (!a || !b) return a === b;
  if (a.q !== b.q || a.type !== b.type) return false;
  return a.type !== 'articles' || (a.field === b.field && a.lang === b.lang && a.time === b.time);
}

/**
 * The page's query parameters for a search (the defaults left out, so `/search?q=docker` is Articles with no filter).
 * The filters stay in the URL on the other tabs, so coming back to Articles keeps them.
 */
export function searchQueryParams(request: SearchUrl): Record<string, string | null> {
  return {
    q: request.q || null,
    type: request.type && request.type !== 'articles' ? request.type : null,
    field: request.field ?? null,
    lang: request.lang ?? null,
    time: request.time ?? null,
  };
}

/** Where a field or topic result goes: the field page (F15), with the topic for a topic. */
export function topicRoute(topic: Pick<SearchTopicDto, 'fieldSlug' | 'topicSlug'>): { commands: string[]; queryParams: Record<string, string> } {
  return { commands: ['/f', topic.fieldSlug], queryParams: topic.topicSlug ? { topic: topic.topicSlug } : {} };
}

/** A field's color token as a CSS color (unknown tokens fall back to primary). */
export function fieldColorOf(token: string): string {
  return `var(--rd-color-${/^[a-z][a-z-]*$/.test(token) ? token : 'primary'})`;
}
