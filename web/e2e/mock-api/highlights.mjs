/**
 * Highlights (F30) for the mock API, per docs/api/contract-v1.md "Highlights (F30)": `GET /articles/{id}/highlights`
 * (🌐; `mine` empty for guests), `POST /articles/{id}/highlights` (the contract's checks in order, trimming, joining
 * your touching or overlapping highlights, the limit of 100), `DELETE /highlights/{id}` (`404 highlight.not_found`
 * when it isn't yours), `GET /me/highlights` (one group per article version, newest first, cursor paging) and
 * `showHighlights` (`PUT /me/preferences`, `GET /me`).
 *
 * The "Highlights lab" article (`/ar/a/highlights-lab`, `/en/a/highlights-lab`) is the shared offsets fixtures'
 * two documents (shared/rdoc/highlight-fixtures.json, owned by the backend), with popular ranges on its mixed
 * Arabic/English sentences. It is in no list or feed, so no other screen changes. Every other article answers with no
 * highlights, so the other reader specs draw nothing.
 *
 * State is per signed-in viewer. Only viewers whose id starts with `u-hl` get `highlights.create` and
 * `showHighlights` in `GET /me`, so every other spec's `/me` stays as it was.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const API = '/api/v1';
const FIXTURES = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), '../../../shared/rdoc/highlight-fixtures.json'), 'utf8'));

export const HIGHLIGHT_VIEWER_PREFIX = 'u-hl';
export const LAB_SLUG = 'highlights-lab';
const LAB_ID = 'a-highlights-lab';
const LAB_TITLES = { 'ar-EG': 'تجربة الـ Highlights: نص عربي و English', en: 'Highlights lab: English with عربي' };

const HIGHLIGHTABLE = new Set(['paragraph', 'heading', 'bulletList', 'orderedList', 'quote', 'callout', 'summary']);
const LIMIT = 100;

/** Popular ranges on the lab article (≥ 3 readers), most marked first. */
const POPULAR = {
  'ar-EG': [
    { blockId: 'p1', startOffset: 15, endOffset: 62, count: 12 },
    { blockId: 'p3', startOffset: 16, endOffset: 27, count: 5 },
    { blockId: 'l1', startOffset: 39, endOffset: 63, count: 3 },
  ],
  en: [
    { blockId: 'e1', startOffset: 15, endOffset: 43, count: 4 },
    { blockId: 'e2', startOffset: 13, endOffset: 26, count: 3 },
  ],
};

/** U+0009–U+000D, U+0020, U+0085, U+00A0, U+1680, U+2000–U+200A, U+2028, U+2029, U+202F, U+205F, U+3000. */
export const isSpace = (c) =>
  (c >= 0x09 && c <= 0x0d) || c === 0x20 || c === 0x85 || c === 0xa0 || c === 0x1680 || (c >= 0x2000 && c <= 0x200a) || c === 0x2028 || c === 0x2029 || c === 0x202f || c === 0x205f || c === 0x3000;

const inlineText = (content) => (content ?? []).map((n) => (n.type === 'hardBreak' ? '\n' : n.text)).join('');

/** A block's plain text and its units (list items), or null when it can't be highlighted (also quoted, F24). */
export function plainOf(block) {
  if (!HIGHLIGHTABLE.has(block.type)) return null;
  if (block.type === 'bulletList' || block.type === 'orderedList') {
    const items = [];
    let start = 0;
    for (const item of block.items) {
      const text = inlineText(item);
      items.push({ start, end: start + text.length });
      start += text.length + 1;
    }
    return { text: block.items.map(inlineText).join('\n'), units: items };
  }
  const text = inlineText(block.content);
  return { text, units: [{ start: 0, end: text.length }] };
}

/**
 * @param {{
 *   problem: (status: number, code: string, title: string) => any,
 *   viewerOf: (req: any) => string | null,
 *   details: (id: string) => any,
 *   labBase: () => any,
 * }} deps the reader's `ArticleDetailsDto` of a published article by id (null when unknown), and the copy the lab
 *   article is built from.
 */
export function createHighlights({ problem, viewerOf, details, labBase }) {
  /** viewer → their highlights: `HighlightDto` plus `articleId` and `language`. */
  const state = new Map();
  /** viewer → `showHighlights`. */
  const shown = new Map();
  let seq = 0;
  let lastAt = 0;

  const listOf = (viewer) => {
    if (!state.has(viewer)) state.set(viewer, []);
    return state.get(viewer);
  };

  function lab(language) {
    const base = labBase();
    return {
      ...base,
      id: LAB_ID,
      slug: LAB_SLUG,
      language,
      title: LAB_TITLES[language],
      subtitle: null,
      availableLanguages: ['ar-EG', 'en'],
      content: FIXTURES.documents[language === 'en' ? 'en' : 'ar'],
      summary: null,
      topic: null,
      tags: [],
      tagCount: 0,
      readingTimeMinutes: 3,
      commentCount: 0,
      reactionCount: 0,
      reactions: { insightful: 0, love: 0, fire: 0, mindBlown: 0 },
      saveCount: 0,
      repostCount: 0,
      isReposted: false,
      myReaction: null,
      isSaved: false,
      collectionIds: [],
      myProgress: null,
      category: null,
      moderation: null,
      attachments: null,
      coverUrl: null,
    };
  }

  /** The version asked for, else the source (as `GET /articles/{slug}`; the other mock articles have one version). */
  function articleFor(id, lang) {
    if (id === LAB_ID) return lab(lang === 'en' ? 'en' : 'ar-EG');
    return details(id) ?? null;
  }

  const blocksOf = (article) => article.content?.blocks ?? [];
  const order = (article) => {
    const index = new Map(blocksOf(article).map((b, i) => [b.id, i]));
    return (a, b) => (index.get(a.blockId) ?? 1e9) - (index.get(b.blockId) ?? 1e9) || a.startOffset - b.startOffset;
  };
  const dto = ({ id, blockId, startOffset, endOffset, text, createdAt }) => ({ id, blockId, startOffset, endOffset, text, createdAt });
  const now = () => {
    lastAt = Math.max(Date.now(), lastAt + 1);
    return new Date(lastAt).toISOString();
  };

  function popularOf(article) {
    if (article.id !== LAB_ID) return [];
    return POPULAR[article.language].map((p) => {
      const block = blocksOf(article).find((b) => b.id === p.blockId);
      return { ...p, text: plainOf(block).text.slice(p.startOffset, p.endOffset) };
    });
  }

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const bad = (code, title) => [400, problem(400, code, title)];

  function create(viewer, articleId, body) {
    const language = body?.language;
    if (!['ar-EG', 'en'].includes(language) || !/^[A-Za-z0-9_-]{1,64}$/.test(body?.blockId ?? '') || typeof body?.text !== 'string')
      return bad('validation.failed', 'One or more fields are invalid.');
    const { startOffset: s0, endOffset: e0 } = body;
    if (!Number.isInteger(s0) || !Number.isInteger(e0) || s0 < 0 || e0 <= s0) return bad('validation.failed', 'One or more fields are invalid.');
    const base = articleFor(articleId, language);
    if (!base) return [404, problem(404, 'article.not_found', 'Article not found')];
    const available = articleId === LAB_ID ? ['ar-EG', 'en'] : (base.availableLanguages ?? [base.language]);
    if (!available.includes(language)) return bad('highlight.text_mismatch', 'This text has changed in the article.');
    const article = articleFor(articleId, language);
    const block = blocksOf(article).find((b) => b.id === body.blockId);
    if (!block) return bad('highlight.text_mismatch', 'This text has changed in the article.');
    const plain = plainOf(block);
    if (!plain) return bad('highlight.block_not_allowed', "This part can't be highlighted.");
    const unit = plain.units.find((u) => s0 >= u.start && e0 <= u.end);
    if (!unit || plain.text.slice(s0, e0) !== body.text) return bad('highlight.text_mismatch', 'This text has changed in the article.');
    let [s, e] = [s0, e0];
    while (s < e && isSpace(plain.text.charCodeAt(s))) s++;
    while (e > s && isSpace(plain.text.charCodeAt(e - 1))) e--;
    if (e - s < 3) return bad('highlight.too_short', 'Select at least 3 characters.');
    if (e - s > 1000) return bad('highlight.too_long', 'A highlight can be at most 1,000 characters.');

    const list = listOf(viewer);
    const same = list.filter((h) => h.articleId === articleId && h.language === language && h.blockId === block.id);
    const holder = same.find((h) => h.startOffset <= s && e <= h.endOffset);
    if (holder) return [200, { highlight: dto(holder), replacedIds: [] }];
    const joined = same.filter((h) => h.startOffset <= e && h.endOffset >= s);
    const start = Math.min(s, ...joined.map((h) => h.startOffset));
    const end = Math.max(e, ...joined.map((h) => h.endOffset));
    if (end - start > 1000) return bad('highlight.too_long', 'A highlight can be at most 1,000 characters.');
    const onArticle = list.filter((h) => h.articleId === articleId).length - joined.length + 1;
    if (onArticle > LIMIT) return bad('highlight.limit', 'You can have at most 100 highlights in one article.');
    const replaced = new Set(joined.map((h) => h.id));
    const highlight = { id: `hl-${++seq}`, articleId, language, blockId: block.id, startOffset: start, endOffset: end, text: plain.text.slice(start, end), createdAt: now() };
    state.set(viewer, [...list.filter((h) => !replaced.has(h.id)), highlight]);
    return [201, { highlight: dto(highlight), replacedIds: [...replaced] }];
  }

  function groups(viewer, q) {
    const byVersion = new Map();
    for (const h of listOf(viewer)) {
      const key = `${h.articleId}|${h.language}`;
      if (!byVersion.has(key)) byVersion.set(key, []);
      byVersion.get(key).push(h);
    }
    const all = [];
    for (const [key, list] of byVersion) {
      const [articleId, language] = key.split('|');
      const article = articleFor(articleId, language);
      if (!article) continue;
      const highlights = [...list].sort((a, b) => b.createdAt.localeCompare(a.createdAt) || b.id.localeCompare(a.id));
      all.push({
        article: { id: article.id, slug: article.slug, language, title: article.title, author: article.author ?? null },
        highlights: highlights.map(dto),
        latestAt: highlights[0].createdAt,
      });
    }
    all.sort((a, b) => b.latestAt.localeCompare(a.latestAt) || a.article.id.localeCompare(b.article.id) || a.article.language.localeCompare(b.article.language));
    const offset = Number(q.get('cursor') ?? 0) || 0;
    const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
    return { items: all.slice(offset, offset + limit), nextCursor: offset + limit < all.length ? String(offset + limit) : null };
  }

  const routes = [
    // The lab article, before the generic `GET /articles/{slug}`; nobody has commented on it.
    ['GET', new RegExp(`^${API}/articles/${LAB_SLUG}$`), (q) => [200, lab(q.get('lang') === 'en' ? 'en' : 'ar-EG')]],
    ['GET', new RegExp(`^${API}/articles/${LAB_ID}/comments$`), () => [200, { items: [], nextCursor: null, total: 0 }]],
    [
      'GET',
      new RegExp(`^${API}/articles/([^/]+)/highlights$`),
      (q, [, id], _body, req) => {
        const article = articleFor(decodeURIComponent(id), q.get('lang'));
        if (!article) return [404, problem(404, 'article.not_found', 'Article not found')];
        const viewer = viewerOf(req);
        const mine = viewer
          ? listOf(viewer)
              .filter((h) => h.articleId === article.id && h.language === article.language)
              .sort(order(article))
              .map(dto)
          : [];
        return [200, { articleId: article.id, language: article.language, mine, popular: popularOf(article) }];
      },
    ],
    [
      'POST',
      new RegExp(`^${API}/articles/([^/]+)/highlights$`),
      (_q, [, id], body, req) => {
        const viewer = viewerOf(req);
        return viewer ? create(viewer, decodeURIComponent(id), body) : unauthorized();
      },
    ],
    [
      'DELETE',
      new RegExp(`^${API}/highlights/([^/]+)$`),
      (_q, [, id], _body, req) => {
        const viewer = viewerOf(req);
        if (!viewer) return unauthorized();
        const list = listOf(viewer);
        if (!list.some((h) => h.id === id)) return [404, problem(404, 'highlight.not_found', 'Highlight not found.')];
        state.set(
          viewer,
          list.filter((h) => h.id !== id),
        );
        return [204, undefined];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/me/highlights$`),
      (q, _m, _body, req) => {
        const viewer = viewerOf(req);
        return viewer ? [200, groups(viewer, q)] : unauthorized();
      },
    ],
    [
      // Before the stateless `PUT /me/preferences` of server.mjs: keeps `showHighlights`.
      'PUT',
      new RegExp(`^${API}/me/preferences$`),
      (_q, _m, body, req) => {
        const viewer = viewerOf(req);
        if (viewer && typeof body?.showHighlights === 'boolean') shown.set(viewer, body.showHighlights);
        return [204, undefined];
      },
    ],
  ];

  /** `GET /me` of a highlights viewer: the permission and the setting. */
  function decorateMe(me, viewer) {
    if (!viewer?.startsWith(HIGHLIGHT_VIEWER_PREFIX)) return me;
    return { ...me, showHighlights: shown.get(viewer) ?? true, permissions: [...new Set([...(me.permissions ?? []), 'highlights.create'])] };
  }

  // `articleFor`: the reader's article version by id, the lab article too (the quote cards' checks, F24).
  return { routes, decorateMe, articleFor };
}
