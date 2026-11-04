/**
 * Bidirectional text helpers (SPEC §14.2). Pure functions so web tests and the RDoc renderer share them.
 */

export type TextDir = 'rtl' | 'ltr';

/** Hebrew, Arabic (+ supplements, presentation forms), Syriac, Thaana, N'Ko. */
const RTL_CHAR = /[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]/;
/** Latin (+ extended), Greek, Cyrillic — "strong LTR" for our content. */
const LTR_CHAR = /[A-Za-zÀ-ʸͰ-ϿЀ-ӿ]/;

/** Direction from the first strong character (what `dir="auto"` does), or null when there is none. */
export function detectDir(text: string | null | undefined): TextDir | null {
  if (!text) return null;
  for (const ch of text) {
    if (RTL_CHAR.test(ch)) return 'rtl';
    if (LTR_CHAR.test(ch)) return 'ltr';
  }
  return null;
}

/**
 * Wraps a name or title in Unicode isolates (FSI … PDI) for interpolation into a translated sentence, so an English
 * title inside "مقالك «…» اتخفى" keeps its own direction and doesn't pull the quotes and words around it.
 */
export function isolate(text: string | null | undefined): string {
  return text ? `\u2068${text}\u2069` : '';
}

export function hasRtl(text: string): boolean {
  return RTL_CHAR.test(text);
}

export interface BidiSegment {
  text: string;
  /** True when this run is in the opposite direction of the base and must be isolated (`<bdi>`). */
  isolate: boolean;
}

/**
 * A Latin run inside RTL text: starts at a Latin letter (optionally prefixed by `.`, `@`, `#` as in `.NET`,
 * `@handle`, `#tag`) and continues through Latin words, digits and code punctuation separated by spaces.
 */
const LATIN_RUN =
  /[.@#]?[A-Za-zÀ-ɏ][\wÀ-ɏ.+#\-/:@<>(),'&=*[\]{}?%~]*(?:[ \t]+[\wÀ-ɏ.+#\-/:@<>(),'&=*[\]{}?%~]+)*/g;
/** An Arabic run inside LTR text. */
const RTL_RUN = /[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF][\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF\d\s\u060C\u061B\u061F]*/g;

const TRAILING_PUNCTUATION = /[\s.,:;!?،؛؟'"-]+$/;

/**
 * Removes trailing punctuation and unbalanced closing brackets so they stay with the surrounding text, and ends the
 * run before a bracket it opens but never closes (`الـ render (` before inline code, `render (Math.random()،`).
 */
function trimRun(run: string): string {
  let result = run;
  for (;;) {
    const before = result;
    const unclosed = firstUnclosedBracket(result);
    if (unclosed > 0) result = result.slice(0, unclosed);
    result = result.replace(TRAILING_PUNCTUATION, '');
    for (const [open, close] of [['(', ')'], ['[', ']'], ['{', '}'], ['<', '>']] as const) {
      while (result.endsWith(close) && count(result, close) > count(result, open)) result = result.slice(0, -1);
    }
    if (result === before) return result;
  }
}

/** Index of the first `(`, `[` or `{` without a matching closer later in the run, or -1. */
function firstUnclosedBracket(text: string): number {
  const open: number[] = [];
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '(' || c === '[' || c === '{') open.push(i);
    else if ((c === ')' || c === ']' || c === '}') && open.length > 0) open.pop();
  }
  return open.length > 0 ? open[0] : -1;
}

function count(text: string, ch: string): number {
  let n = 0;
  for (const c of text) if (c === ch) n++;
  return n;
}

/**
 * Splits text into runs; runs in the opposite direction of `baseDir` are marked for isolation so punctuation
 * and word order never break (e.g. `يعني إيه Dependency Injection؟`).
 */
export function segmentBidi(text: string, baseDir: TextDir): BidiSegment[] {
  const pattern = baseDir === 'rtl' ? LATIN_RUN : RTL_RUN;
  if (baseDir === 'rtl' ? !LTR_CHAR.test(text) : !hasRtl(text)) return [{ text, isolate: false }];

  const segments: BidiSegment[] = [];
  let cursor = 0;
  pattern.lastIndex = 0;
  for (let match = pattern.exec(text); match; match = pattern.exec(text)) {
    const run = trimRun(match[0]);
    if (!run) continue;
    const start = match.index;
    if (start > cursor) segments.push({ text: text.slice(cursor, start), isolate: false });
    segments.push({ text: run, isolate: true });
    cursor = start + run.length;
    pattern.lastIndex = cursor;
  }
  if (cursor < text.length) segments.push({ text: text.slice(cursor), isolate: false });
  return segments;
}
