/**
 * Quote cards (F24) for the mock API, per docs/api/contract-v1.md "Quote card (F24)": `POST /articles/{id}/quote-card`
 * (🌐, guests too) checks the request in the API's order (a malformed body → `400 validation.failed`; an unknown
 * article → `404 article.not_found`; hidden by moderators, for a moderator → `409 quote.hidden`; a missing version or
 * block, an offset past the text, a range across list items or other text → `400 quote.text_mismatch`; code, tables and
 * the like → `400 quote.block_not_allowed`; fewer than 3 or more than 400 code units once trimmed → `400 quote.too_short`
 * / `quote.too_long`) against the reader's articles and the "Highlights lab" (the shared offsets fixtures,
 * highlights.mjs), and answers a solid card-like PNG of the format's size (1080 × 1080 or 1200 × 630, light or dark)
 * with the API's headers (`readin-quote-{slug}.png` in RFC 5987 `filename*`, `Cache-Control: private, max-age=600`,
 * `nosniff`). Stateless: the limit, busy, failed and offline answers are tested with `page.route`
 * (e2e/quote-card.e2e.ts), so parallel tests never share a count.
 */
import { isSpace, plainOf } from './highlights.mjs';

const API = '/api/v1';
const LANGUAGES = ['ar-EG', 'en'];
const THEMES = ['light', 'dark'];
const SIZES = { square: [1080, 1080], landscape: [1200, 630] };
const BLOCK_ID = /^[A-Za-z0-9_-]{1,64}$/;
const MIN = 3;
const MAX = 400;

/** §15.2 colours of each theme: background, surface, primary, text, secondary text. */
const COLORS = {
  light: { bg: [244, 242, 238], card: [255, 255, 255], primary: [15, 94, 82], text: [26, 26, 26], meta: [107, 107, 107] },
  dark: { bg: [18, 20, 19], card: [27, 30, 28], primary: [63, 184, 163], text: [236, 234, 230], meta: [163, 163, 158] },
};

/** A card-like picture: a quote mark, a few lines of "quote", the title and writer lines, and the logo band. */
function cardPixel(theme, format) {
  const c = COLORS[theme];
  const wide = format === 'landscape';
  return (u, v) => {
    if (u < 0.05 || u > 0.95 || v < 0.05 || v > 0.95) return c.bg;
    if (u > 0.1 && u < 0.18 && v > 0.12 && v < (wide ? 0.26 : 0.2)) return c.primary; // the quotation mark
    const lines = wide ? [0.34, 0.44, 0.54] : [0.3, 0.38, 0.46, 0.54];
    const height = wide ? 0.06 : 0.04;
    for (const [i, top] of lines.entries()) if (v > top && v < top + height && u > 0.1 && u < (i === lines.length - 1 ? 0.62 : 0.9)) return c.text;
    if (v > 0.7 && v < 0.73 && u > 0.1 && u < 0.7) return c.meta; // the article title
    if (v > 0.76 && v < 0.79 && u > 0.1 && u < 0.4) return c.meta; // the writer
    if (v > 0.84 && v < 0.9 && u > 0.1 && u < 0.3) return c.primary; // the ReadIn logo
    return c.card;
  };
}

/**
 * @param {{
 *   problem: (status: number, code: string, title: string) => any,
 *   viewerOf: (req: any) => string | null,
 *   articleFor: (id: string, language: string) => any,
 *   hiddenFor: (article: any, viewer: string | null) => boolean,
 *   png: (width: number, height: number, pixel: (u: number, v: number) => number[]) => Buffer,
 * }} deps `articleFor`: the reader's `ArticleDetailsDto` of a version by id (null when unknown); `hiddenFor`: hidden by
 *   moderators, as the viewer sees it.
 */
export function createQuoteCards({ problem, viewerOf, articleFor, hiddenFor, png }) {
  const images = new Map();
  const imageOf = (theme, format) => {
    const key = `${theme}|${format}`;
    if (!images.has(key)) images.set(key, png(...SIZES[format], cardPixel(theme, format)));
    return images.get(key);
  };

  const bad = (code, title) => [400, problem(400, code, title)];
  const mismatch = () => bad('quote.text_mismatch', 'This text has changed in the article. Reload and try again.');

  function invalid(body) {
    const errors = {};
    const need = (field, ok) => {
      if (body?.[field] === undefined || body?.[field] === null) errors[field] = ['validation.required'];
      else if (!ok(body[field])) errors[field] = [field === 'language' ? 'article.language_invalid' : 'validation.invalid'];
    };
    need('language', (v) => LANGUAGES.includes(v));
    need('blockId', (v) => typeof v === 'string' && BLOCK_ID.test(v));
    need('startOffset', (v) => Number.isInteger(v) && v >= 0);
    need('endOffset', (v) => Number.isInteger(v) && v >= 0 && (!Number.isInteger(body.startOffset) || v > body.startOffset));
    need('text', (v) => typeof v === 'string');
    need('theme', (v) => THEMES.includes(v));
    need('format', (v) => v in SIZES);
    return Object.keys(errors).length ? errors : null;
  }

  function card(id, body, req) {
    const errors = invalid(body);
    if (errors) return [400, { ...problem(400, 'validation.failed', 'One or more fields are invalid.'), errors }];
    const { language, blockId, startOffset: s0, endOffset: e0, text, theme, format } = body;
    const base = articleFor(id, language);
    if (!base) return [404, problem(404, 'article.not_found', 'Article not found')];
    if (hiddenFor(base, viewerOf(req))) return [409, problem(409, 'quote.hidden', "Moderators hid this article, so its quotes can't be shared.")];
    const available = base.availableLanguages ?? [base.language];
    if (!available.includes(language)) return mismatch();
    const article = articleFor(id, language);
    const block = (article.content?.blocks ?? []).find((b) => b.id === blockId);
    if (!block) return mismatch();
    const plain = plainOf(block);
    if (!plain) return bad('quote.block_not_allowed', "This part can't be shared as a quote.");
    const unit = plain.units.find((u) => s0 >= u.start && e0 <= u.end);
    if (!unit || plain.text.slice(s0, e0) !== text || isSplitPair(plain.text, s0) || isSplitPair(plain.text, e0)) return mismatch();
    let [s, e] = [s0, e0];
    while (s < e && isSpace(plain.text.charCodeAt(s))) s++;
    while (e > s && isSpace(plain.text.charCodeAt(e - 1))) e--;
    if (e - s < MIN) return bad('quote.too_short', 'Select at least 3 characters.');
    if (e - s > MAX) return bad('quote.too_long', 'A quote can be at most 400 characters. Select less text.');
    const image = imageOf(theme, format);
    const name = `readin-quote-${article.slug}.png`;
    return [
      200,
      image,
      {
        'content-type': 'image/png',
        'content-length': String(image.length),
        'content-disposition': `inline; filename="readin-quote.png"; filename*=UTF-8''${encodeURIComponent(name)}`,
        'cache-control': 'private, max-age=600',
        'x-content-type-options': 'nosniff',
      },
    ];
  }

  const routes = [['POST', new RegExp(`^${API}/articles/([^/]+)/quote-card$`), (_q, [, id], body, req) => card(decodeURIComponent(id), body, req)]];
  return { routes };
}

/** An offset between the two halves of a surrogate pair. */
function isSplitPair(text, offset) {
  const before = text.charCodeAt(offset - 1);
  const at = text.charCodeAt(offset);
  return before >= 0xd800 && before <= 0xdbff && at >= 0xdc00 && at <= 0xdfff;
}
