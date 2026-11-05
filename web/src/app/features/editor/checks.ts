import { ArticleLanguage, DraftChecksDto, DraftProblemCode, DraftProblemDto } from '../../core/api/models';

/** SPEC F05 / contract: a title has 5..150 characters to publish. */
export const TITLE_MIN = 5;
export const TITLE_MAX = 150;
export const SUBTITLE_MAX = 250;

/** Where a problem is fixed: the editor scrolls there and focuses it. */
export type CheckTarget =
  | { kind: 'field' }
  | { kind: 'title'; language: ArticleLanguage }
  | { kind: 'content'; language: ArticleLanguage }
  | { kind: 'block'; language: ArticleLanguage; blockId: string }
  | { kind: 'sources' }
  | { kind: 'attachment'; mediaAssetId: string | null }
  | { kind: 'tag'; tag: string | null };

export interface CheckItem {
  code: DraftProblemCode;
  /** Translation key under `editor.problems`. */
  messageKey: string;
  /** The language version it belongs to (shown as a label when the article has two). */
  language: ArticleLanguage | null;
  /** The tag it is about (F32), shown beside the message. */
  tag: string | null;
  target: CheckTarget;
}

const ORDER: readonly DraftProblemCode[] = [
  'article.field_required',
  'tag.hidden',
  'tag.limit',
  'article.title_length',
  'article.content_empty',
  'article.content_invalid',
  'article.image_alt_required',
  'article.sources_required',
  'attachments.asset_not_ready',
  'attachments.alt_text_required',
  'attachments.title_required',
  'attachments.mixed_kinds',
  'attachments.single_document',
  'media.in_use',
];

function target(problem: DraftProblemDto, source: ArticleLanguage): CheckTarget {
  const language = problem.language ?? source;
  switch (problem.code) {
    case 'article.field_required':
      return { kind: 'field' };
    case 'article.title_length':
      return { kind: 'title', language };
    case 'article.content_empty':
      return { kind: 'content', language };
    case 'article.content_invalid':
    case 'article.image_alt_required':
      return problem.blockId ? { kind: 'block', language, blockId: problem.blockId } : { kind: 'content', language };
    case 'article.sources_required':
      return { kind: 'sources' };
    case 'tag.hidden':
    case 'tag.limit':
      return { kind: 'tag', tag: problem.tag ?? null };
    default:
      return { kind: 'attachment', mediaAssetId: problem.mediaAssetId };
  }
}

/**
 * The live checks (`checks.problems` of the last save) as a list to show: in a stable order (article settings and
 * tags, then each language, then attachments), duplicates removed, each with the message key and the place to fix it.
 */
export function checkItems(checks: DraftChecksDto | null, sourceLanguage: ArticleLanguage): CheckItem[] {
  const problems = checks?.problems ?? [];
  const seen = new Set<string>();
  const items: CheckItem[] = [];
  for (const problem of problems) {
    const key = `${problem.code}|${problem.language}|${problem.blockId}|${problem.mediaAssetId}|${problem.tag ?? null}`;
    if (seen.has(key)) continue;
    seen.add(key);
    items.push({
      code: problem.code,
      messageKey: ORDER.includes(problem.code) ? `editor.problems.${problem.code.replace('.', '_')}` : 'editor.problems.unknown',
      language: problem.language,
      tag: problem.tag ?? null,
      target: target(problem, sourceLanguage),
    });
  }
  const rank = (item: CheckItem) => {
    const order = ORDER.indexOf(item.code);
    const languageRank = item.language === null ? 0 : item.language === sourceLanguage ? 1 : 2;
    return (order < 0 ? ORDER.length : order) + languageRank * 0.1;
  };
  return items.map((item, i) => ({ item, i })).sort((a, b) => rank(a.item) - rank(b.item) || a.i - b.i).map(({ item }) => item);
}

export type TitleState = 'empty' | 'short' | 'ok' | 'long';

/** Title length while typing (counted like the server: trimmed). */
export function titleState(title: string): { length: number; state: TitleState } {
  const length = title.trim().length;
  const state: TitleState = length === 0 ? 'empty' : length < TITLE_MIN ? 'short' : length > TITLE_MAX ? 'long' : 'ok';
  return { length, state };
}

/** Reading time of one language version from the last checks, or null before the first save. */
export function readingTimeOf(checks: DraftChecksDto | null, language: ArticleLanguage): { minutes: number; words: number } | null {
  const entry = checks?.readingTime?.find((r) => r.language === language);
  return entry ? { minutes: entry.minutes, words: entry.words } : null;
}
