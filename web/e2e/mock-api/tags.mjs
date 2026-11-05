/**
 * Tags (F32) for the mock API, following the contract's rules (docs/api/contract-v1.md → Tags): names are cleaned and
 * compared normalized (case, Arabic spelling variants), the first spelling is kept, a slug is made once (`C#` →
 * `csharp`, `.NET` → `dotnet`, a clash gets `-2`), and hidden tags are never shown, suggested or served.
 *
 * - `createTagRegistry()`: every card and article takes its `TagRefDto`s from it (server.mjs registers the fixtures'
 *   tags as it builds them, in order, so the first spelling wins).
 * - `createTags()`: the editor's suggestions (`GET /tags?q=`) and the tag page (`GET /tags/{slug}`,
 *   `GET /tags/{slug}/articles`, cursor pages of cards, newest first, personalized like every feed).
 *
 * Stateless across tests: the editor's new names (a publish) are never registered, so parallel tests can't see each
 * other's tags.
 */

const API = '/api/v1';
const FORMAT_CHARS = /\p{Cf}/gu;
const ARABIC_INDIC_DIGITS = /[٠-٩۰-۹]/g;
const ALLOWED = /^[\p{L}\p{M}\p{Nd} _.+#-]+$/u;
const LETTER_OR_DIGIT = /[\p{L}\p{Nd}]/u;
const ARABIC_MARKS = /[ً-ٰٟۖ-ۭـ]/g;
const MAX_NAME = 30;

/** Rule 1: format characters out, trimmed, leading `#`s dropped, whitespace runs → one space, ٠–٩ → 0–9. */
export function cleanTagName(raw) {
  return String(raw ?? '')
    .replace(FORMAT_CHARS, '')
    .trim()
    .replace(/^#+/, '')
    .trim()
    .replace(/\s+/g, ' ')
    .replace(ARABIC_INDIC_DIGITS, (d) => String(d.charCodeAt(0) - (d >= '۰' ? 0x06f0 : 0x0660)));
}

/** Rule 3: the compared form. */
export function normalizeTagName(name) {
  return cleanTagName(name).toLowerCase().replace(ARABIC_MARKS, '').replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه');
}

/** Rule 2, for a cleaned name that would create a tag. */
export function isValidNewTagName(name) {
  return name.length >= 2 && name.length <= MAX_NAME && ALLOWED.test(name) && LETTER_OR_DIGIT.test(name);
}

/** Rule 4: `C#` → `csharp`, `C++` → `cplusplus`, `.NET` → `dotnet`, `ASP.NET Core` → `asp-net-core`, Arabic kept. */
export function slugOf(name) {
  return cleanTagName(name)
    .toLowerCase()
    .replace(ARABIC_MARKS, '')
    .replace(/#/g, 'sharp')
    .replace(/\+/g, 'plus')
    .replace(/^\./, 'dot')
    .replace(/[^\p{L}\p{Nd}]+/gu, '-')
    .replace(/^-+|-+$/g, '');
}

/** A word of the normalized name starts with `q` (at the start, or after a space, `-`, `_` or `.`). */
function wordStartsWith(normalized, q) {
  if (normalized.startsWith(q)) return true;
  for (let i = 1; i < normalized.length; i++) if (' -_.'.includes(normalized[i - 1]) && normalized.startsWith(q, i)) return true;
  return false;
}

export function createTagRegistry() {
  const byKey = new Map();
  const slugs = new Set();

  /** The tag for `name`, created with this spelling if it is new. */
  function register(name, { hidden = false } = {}) {
    const clean = cleanTagName(name);
    const key = normalizeTagName(clean);
    let tag = byKey.get(key);
    if (!tag) {
      const base = slugOf(clean) || 'tag';
      let slug = base;
      for (let n = 2; slugs.has(slug); n++) slug = `${base}-${n}`;
      slugs.add(slug);
      tag = { slug, name: clean, hidden };
      byKey.set(key, tag);
    }
    return tag;
  }

  const find = (name) => byKey.get(normalizeTagName(name)) ?? null;
  const ref = ({ slug, name }) => ({ slug, name });

  return {
    register,
    find,
    bySlug: (slug) => [...byKey.values()].find((t) => t.slug === slug) ?? null,
    all: () => [...byKey.values()],
    /** Registers the names (fixtures) and returns their visible `TagRefDto`s, in order. */
    refs: (names) => names.map((n) => register(n)).filter((t) => !t.hidden).map(ref),
    /** The visible refs of names without registering new ones (a published editor article). */
    refsOf: (names) =>
      names.flatMap((n) => {
        const tag = find(n);
        if (tag) return tag.hidden ? [] : [ref(tag)];
        return [{ slug: slugOf(n) || 'tag', name: cleanTagName(n) }];
      }),
  };
}

/**
 * @param {{ registry: ReturnType<typeof createTagRegistry>, articles: () => any[], tagsOf: (card: any) => any[],
 *   personalize: (card: any, viewer: string | null) => any, viewerOf: (req: any) => string | null, problem: Function }} deps
 *   `articles`: every published card (guest values); `tagsOf`: all of a card's tag refs (cards carry 3).
 */
export function createTags({ registry, articles, tagsOf, personalize, viewerOf, problem }) {
  const notFound = () => [404, problem(404, 'tag.not_found', 'This tag does not exist.')];
  const withTag = (tag) =>
    articles()
      .filter((a) => tagsOf(a).some((t) => t.slug === tag.slug))
      .sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
  const dto = (tag) => ({ slug: tag.slug, name: tag.name, articleCount: withTag(tag).length });
  const visible = (slug) => {
    const tag = registry.bySlug(decodeURIComponent(slug));
    return tag && !tag.hidden ? tag : null;
  };

  const routes = [
    [
      'GET',
      new RegExp(`^${API}/tags$`),
      (q) => {
        const raw = q.get('q') ?? '';
        const query = normalizeTagName(raw);
        const querySlug = slugOf(raw);
        const limit = Math.min(20, Math.max(1, Number(q.get('limit') ?? 10) || 10));
        if (query.length > MAX_NAME) return [200, []];
        const found = registry
          .all()
          .filter((t) => !t.hidden)
          .filter((t) => !query || wordStartsWith(normalizeTagName(t.name), query) || (querySlug && t.slug.startsWith(querySlug)))
          .map(dto)
          .sort(
            (a, b) =>
              Number(normalizeTagName(b.name) === query) - Number(normalizeTagName(a.name) === query) ||
              b.articleCount - a.articleCount ||
              a.name.localeCompare(b.name),
          );
        return [200, found.slice(0, limit)];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/tags/([^/]+)$`),
      (_q, [, slug]) => {
        const tag = visible(slug);
        return tag ? [200, dto(tag)] : notFound();
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/tags/([^/]+)/articles$`),
      (q, [, slug], _body, req) => {
        const tag = visible(slug);
        if (!tag) return notFound();
        const items = withTag(tag);
        const offset = Number(q.get('cursor') ?? 0) || 0;
        const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
        const viewer = viewerOf(req);
        return [
          200,
          {
            items: items.slice(offset, offset + limit).map((a) => personalize(a, viewer)),
            nextCursor: offset + limit < items.length ? String(offset + limit) : null,
          },
        ];
      },
    ],
  ];

  // `visible`: every tag readers can see, as `TagDto`s (search, F16).
  return { routes, visible: () => registry.all().filter((t) => !t.hidden).map(dto) };
}
