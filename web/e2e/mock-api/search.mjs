/**
 * Search (F16) for the mock API, following docs/api/contract-v1.md → Search: the query is cleaned and normalized like
 * a tag name (case, Arabic diacritics and letter forms never matter), every word must start a word of the text (an
 * Arabic one also after a leading `ال`), and `GET /search?type=` pages through articles (title, text, then the
 * attached PDF's text, with `matchedIn`), writers, fields and topics, and tags; `GET /search/suggest` has the first
 * 3 of each. Articles are ranked place × phrase rank × freshness (the mock has no quality score), the others as the
 * contract orders them. Personalized like every feed (your reactions, saves and follows).
 */
import { cleanTagName, normalizeTagName, slugOf } from './tags.mjs';

const API = '/api/v1';
const TYPES = ['articles', 'users', 'topics', 'tags'];
const LETTER_OR_DIGIT = /(?!ـ)[\p{L}\p{Nd}]/u;
const WORD_CHAR = /[\p{L}\p{N}]/u;
const ARABIC = /\p{Script=Arabic}/u;
const MAX_QUERY = 100;
const MAX_RESULTS = 200;
const SUGGESTIONS = 3;
/** Freshness is counted from here, so the order doesn't change with the day the suite runs. */
const NOW = Date.parse('2026-11-04T09:00:00Z');

/** The query as the API cleans it: Tags rule 1, then one leading `@`. */
export function cleanQuery(raw) {
  const cleaned = cleanTagName(raw);
  return cleaned.startsWith('@') ? cleaned.slice(1).trim() : cleaned;
}

const normalize = (text) => normalizeTagName(String(text ?? ''));
const wordsOf = (q) => normalize(q).split(' ').filter(Boolean).slice(0, 8);

/** `word` starts a word of `text` (both normalized), also after a leading `ال` for an Arabic word. */
function startsAWord(text, word) {
  for (let i = text.indexOf(word); i >= 0; i = text.indexOf(word, i + 1)) {
    if (i === 0 || !WORD_CHAR.test(text[i - 1])) return true;
    if (ARABIC.test(word[0]) && i >= 2 && text.slice(i - 2, i) === 'ال' && (i === 2 || !WORD_CHAR.test(text[i - 3]))) return true;
  }
  return false;
}
const hasAll = (text, words) => words.every((w) => startsAWord(text, w));

/** An article's text for searching: every block's text, list items, steps and code. */
export function textOfBlocks(blocks = []) {
  const inline = (nodes = []) => nodes.map((n) => n.text ?? '').join('');
  return blocks
    .map((b) =>
      [
        b.title ?? '',
        inline(b.content),
        ...(b.items ?? []).map((item) => (Array.isArray(item) ? inline(item) : `${item.title ?? ''} ${inline(item.content)}`)),
        b.code ?? '',
      ].join(' '),
    )
    .join(' ');
}

function page(items, q) {
  const all = items.slice(0, MAX_RESULTS);
  const offset = Number(q.get('cursor') ?? 0) || 0;
  const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
  return { items: all.slice(offset, offset + limit), nextCursor: offset + limit < all.length ? String(offset + limit) : null };
}

/**
 * @param {{ articles: () => any[], textOf: (card: any) => string, attachmentTextOf: (card: any) => string | null,
 *   people: () => any[], fields: any[], topics: Record<string, any[]>, topicCount: (topic: any) => number,
 *   tags: () => { slug: string, name: string, articleCount: number }[], personalize: Function, viewerOf: Function,
 *   isFollowing: (viewer: string | null, id: string) => boolean, problem: Function }} deps
 *   `articles`: every published card (guest values); `people`: everyone who can be found (with `followerCount`,
 *   `bio`, `followsEveryone`); `tags`: the visible tags as `TagDto`s.
 */
export function createSearch(deps) {
  const { problem } = deps;
  const invalid = (code, title) => [400, problem(400, code, title)];

  function parseQuery(q) {
    const query = cleanQuery(q.get('q') ?? '');
    if (!query || query.length > MAX_QUERY || !LETTER_OR_DIGIT.test(query)) return { error: invalid('search.query_invalid', 'Type a word with letters or digits.') };
    return { query, words: wordsOf(query), normalized: normalize(query) };
  }

  function parseFilters(q) {
    const minutes = (name) => {
      const raw = q.get(name);
      if (raw === null || raw === '') return { value: null };
      if (!/^\d+$/.test(raw)) return { error: invalid('request.invalid', `${name} must be a whole number.`) };
      const value = Number(raw);
      return value > 600 ? { error: invalid('search.filter_invalid', 'Reading time is 0–600 minutes.') } : { value };
    };
    const lang = q.get('lang') || null;
    if (lang && lang !== 'ar-EG' && lang !== 'en') return { error: invalid('search.filter_invalid', 'Unknown article language.') };
    const min = minutes('minMinutes');
    if (min.error) return min;
    const max = minutes('maxMinutes');
    if (max.error) return max;
    if (min.value !== null && max.value !== null && min.value > max.value) return { error: invalid('search.filter_invalid', 'minMinutes is over maxMinutes.') };
    return { field: q.get('field') || null, lang, min: min.value, max: max.value };
  }

  function articles({ words, normalized }, filters, viewer) {
    const found = [];
    for (const a of deps.articles()) {
      if (filters.field && a.field.slug !== filters.field) continue;
      if (filters.lang && a.language !== filters.lang) continue;
      if (filters.min !== null && filters.min !== undefined && a.readingTimeMinutes < filters.min) continue;
      if (filters.max !== null && filters.max !== undefined && a.readingTimeMinutes > filters.max) continue;
      const title = normalize(a.title);
      const body = normalize(`${a.title} ${deps.textOf(a)}`);
      const pdfText = deps.attachmentTextOf(a);
      const pdf = pdfText ? normalize(pdfText) : null;
      let hit = null;
      if (hasAll(title, words)) hit = { matchedIn: 'title', place: 1, text: title };
      else if (hasAll(body, words)) hit = { matchedIn: 'text', place: 0.6, text: body };
      else if (pdf && hasAll(pdf, words)) hit = { matchedIn: 'attachment', place: 0.4, text: pdf };
      if (!hit) continue;
      const rank = hit.text.includes(normalized) ? 1 : 0.5;
      const days = Math.max(0, (NOW - Date.parse(a.publishedAt)) / 86_400_000);
      found.push({ a, matchedIn: hit.matchedIn, score: hit.place * (0.5 + 0.5 * rank) * (1 / (1 + days / 365)) });
    }
    found.sort((x, y) => y.score - x.score || y.a.publishedAt.localeCompare(x.a.publishedAt) || x.a.id.localeCompare(y.a.id));
    return found.map(({ a, matchedIn }) => ({ article: deps.personalize(a, viewer), matchedIn }));
  }

  function users({ words, normalized }, viewer) {
    const oneWord = words.length === 1;
    const tier = (u) => {
      const name = normalize(u.displayName);
      const handle = normalize(u.username);
      if (handle === normalized || name === normalized) return 0;
      if (handle.startsWith(normalized) || name.startsWith(normalized)) return 1;
      return 2;
    };
    return deps
      .people()
      .filter((u) => hasAll(normalize(u.displayName), words) || (oneWord && normalize(u.username).startsWith(words[0])))
      .sort(
        (a, b) =>
          tier(a) - tier(b) ||
          Number(b.isVerified) - Number(a.isVerified) ||
          (b.followerCount ?? 0) - (a.followerCount ?? 0) ||
          a.username.localeCompare(b.username),
      )
      .map((u) => ({
        id: u.id,
        displayName: u.displayName,
        username: u.username,
        avatarUrl: u.avatarUrl ?? null,
        isVerified: !!u.isVerified,
        bio: u.bio ?? null,
        isFollowing: !!viewer && viewer !== u.id && deps.isFollowing(viewer, u.id),
        followsYou: !!viewer && viewer !== u.id && !!u.followsEveryone,
      }));
  }

  function topics({ words, query, normalized }, req) {
    const en = (req.headers['accept-language'] ?? '').startsWith('en');
    const querySlug = slugOf(query);
    const all = deps.fields.flatMap((field) => [
      {
        kind: 'field',
        id: field.id,
        name: en ? field.nameEn : field.nameAr,
        nameAr: field.nameAr,
        nameEn: field.nameEn,
        fieldSlug: field.slug,
        topicSlug: null,
        fieldName: en ? field.nameEn : field.nameAr,
        icon: field.icon,
        color: field.color,
        articleCount: deps.articles().filter((a) => a.field.id === field.id).length,
        slug: field.slug,
      },
      ...(deps.topics[field.slug] ?? []).map((topic) => ({
        kind: 'topic',
        id: topic.id,
        name: en ? topic.nameEn : topic.nameAr,
        nameAr: topic.nameAr,
        nameEn: topic.nameEn,
        fieldSlug: field.slug,
        topicSlug: topic.slug,
        fieldName: en ? field.nameEn : field.nameAr,
        icon: field.icon,
        color: field.color,
        articleCount: deps.topicCount(topic),
        slug: topic.slug,
      })),
    ]);
    const exact = (t) => normalize(t.nameAr) === normalized || normalize(t.nameEn) === normalized;
    return all
      .filter((t) => hasAll(normalize(t.nameAr), words) || hasAll(normalize(t.nameEn), words) || (querySlug && t.slug.startsWith(querySlug)))
      .sort(
        (a, b) =>
          Number(exact(b)) - Number(exact(a)) ||
          Number(b.kind === 'field') - Number(a.kind === 'field') ||
          b.articleCount - a.articleCount ||
          a.name.localeCompare(b.name),
      )
      .map(({ slug: _slug, ...dto }) => dto);
  }

  function tags({ words, query, normalized }) {
    const querySlug = slugOf(query);
    return deps
      .tags()
      .filter((t) => t.articleCount > 0)
      .filter((t) => hasAll(normalize(t.name), words) || (querySlug && t.slug.startsWith(querySlug)))
      .sort(
        (a, b) =>
          Number(normalize(b.name) === normalized) - Number(normalize(a.name) === normalized) ||
          b.articleCount - a.articleCount ||
          a.name.localeCompare(b.name),
      );
  }

  const routes = [
    [
      'GET',
      new RegExp(`^${API}/search$`),
      (q, _m, _body, req) => {
        const type = q.get('type') || 'articles';
        if (!TYPES.includes(type)) return invalid('search.type_invalid', 'Unknown result type.');
        const parsed = parseQuery(q);
        if (parsed.error) return parsed.error;
        const viewer = deps.viewerOf(req);
        switch (type) {
          case 'users':
            return [200, page(users(parsed, viewer), q)];
          case 'topics':
            return [200, page(topics(parsed, req), q)];
          case 'tags':
            return [200, page(tags(parsed), q)];
          default: {
            const filters = parseFilters(q);
            if (filters.error) return filters.error;
            return [200, page(articles(parsed, filters, viewer), q)];
          }
        }
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/search/suggest$`),
      (q, _m, _body, req) => {
        const parsed = parseQuery(q);
        if (parsed.error) return parsed.error;
        const viewer = deps.viewerOf(req);
        return [
          200,
          {
            articles: articles(parsed, {}, viewer).slice(0, SUGGESTIONS),
            users: users(parsed, viewer).slice(0, SUGGESTIONS),
            topics: topics(parsed, req).slice(0, SUGGESTIONS),
            tags: tags(parsed).slice(0, SUGGESTIONS),
          },
        ];
      },
    ],
  ];

  return { routes };
}
