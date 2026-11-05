/**
 * Writer categories (F31) for the mock API, per the contract (docs/api/contract-v1.md → "Writer categories"): the
 * profile's Categories tab, the category pages (`_other` is the uncategorized list), the writer's own list with create,
 * rename, delete and reorder, an article's category (`PUT /articles/{id}/category`), the reader's `category` and the
 * editor's `categoryId`. Names are cleaned and compared like the API (case and Arabic spelling ignored), a slug is made
 * once from the name (Arabic kept, `-2` on a clash) and never changes on rename.
 *
 * State is kept per writer (the owner's id). Seeded: Mona (`u-writer`) has "ASP.NET Core" (2 articles), "نصايح
 * البرمجة" (1, an Arabic slug) and the empty "أفكار جاية", with one article left uncategorized; every editor writer
 * `u-author-*` (e2e/support/editor.ts) starts with "ASP.NET Core" (their published `-p1`), "Clean Code بالعربي" (only
 * their draft `-d1`, so 0) and "أفكار جاية" (empty), their `-p2` uncategorized; the reported reader `u-reader-21` (the
 * user case of moderation.mjs) has an offensive category name. Everyone else starts with none. A writer's changes are
 * theirs alone, so parallel tests that each sign in as their own writer never see each other's.
 */

import { normalizeTagName, slugOf } from './tags.mjs';

const API = '/api/v1';
const OTHER = '_other';
const MAX_NAME = 40;
const MAX_CATEGORIES = 50;
const FORMAT_CHARS = /\p{Cf}/gu;
const CONTROL_CHARS = /\p{Cc}/gu;
const ARABIC_INDIC_DIGITS = /[٠-٩۰-۹]/g;
const LETTER_OR_DIGIT = /(?!ـ)[\p{L}\p{Nd}]/u;

/** Tag rule 1, but a leading `#` stays. */
export function cleanCategoryName(raw) {
  return String(raw ?? '')
    .replace(FORMAT_CHARS, '')
    .replace(/\s+/g, ' ')
    .replace(CONTROL_CHARS, '')
    .trim()
    .replace(ARABIC_INDIC_DIGITS, (d) => String(d.charCodeAt(0) - (d >= '۰' ? 0x06f0 : 0x0660)));
}

const sameName = (a, b) => normalizeTagName(`x${a}`) === normalizeTagName(`x${b}`);

/**
 * @param {{
 *   problem: (status: number, code: string, title: string) => any,
 *   viewerOf: (req: any) => string | null,
 *   lookup: (username: string, viewer: string | null) => any,
 *   articles: () => any[],
 *   editor: { publishedOf: (viewer: string) => any[], owns: (viewer: string, id: string) => boolean },
 *   personalize: (card: any, viewer: string | null) => any,
 * }} deps
 */
export function createCategories({ problem, viewerOf, lookup, articles, editor, personalize }) {
  const owners = new Map();

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const userNotFound = () => [404, problem(404, 'user.not_found', 'User not found')];
  const notFound = () => [404, problem(404, 'category.not_found', 'Category not found')];
  const notOwner = () => [403, problem(403, 'category.not_owner', 'This is not your category.')];
  const nameInvalid = () => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { name: ['category.name_invalid'] } }];
  const taken = () => [409, problem(409, 'category.name_taken', 'You already have a category with this name.')];

  function seed(owner) {
    const state = { categories: [], assigned: new Map(), next: 1 };
    const add = (name, articleIds = [], id = null) => {
      const category = create(state, owner, name, id);
      for (const articleId of articleIds) state.assigned.set(articleId, category.id);
    };
    if (owner === 'u-writer') {
      add('ASP.NET Core', ['a-dependency-injection-ar', 'a-aspnet-core-cheatsheet'], 'c-mona-aspnet');
      add('نصايح البرمجة', ['a-clean-architecture-whiteboard'], 'c-mona-tips');
      add('أفكار جاية', [], 'c-mona-ideas');
    } else if (owner.startsWith('u-author')) {
      add('ASP.NET Core', [`${owner}-p1`], `${owner}-c1`);
      add('Clean Code بالعربي', [`${owner}-d1`], `${owner}-c2`);
      add('أفكار جاية', [], `${owner}-c3`);
    } else if (owner === 'u-reader-21') {
      add('مقالات للأغبيا بس', [], 'c-dina-rude');
      add('Notes', [], 'c-dina-notes');
    }
    return state;
  }

  function stateOf(owner) {
    if (!owners.has(owner)) owners.set(owner, seed(owner));
    return owners.get(owner);
  }

  function create(state, owner, name, id = null) {
    const base = slugOf(name) || 'category';
    let slug = base;
    for (let n = 2; state.categories.some((c) => c.slug === slug); n++) slug = `${base}-${n}`;
    const category = { id: id ?? `cat-${owner}-${state.next}`, slug, name, owner };
    state.next++;
    state.categories.push(category);
    return category;
  }

  /** The owner of a category id, wherever it is (for `category.not_owner`). */
  function findAnywhere(id) {
    for (const state of owners.values()) {
      const category = state.categories.find((c) => c.id === id);
      if (category) return category;
    }
    return null;
  }

  /**
   * The writer's articles readers can see, newest first: the fixtures they wrote and what they published in the editor.
   * The demo writer Mona keeps her fixtures only, like her profile (profiles.mjs): other suites publish as her, and her
   * category pages must not change with them.
   */
  function publishedOf(owner) {
    const fixtures = articles().filter((a) => a.author?.id === owner);
    const written = owner === 'u-writer' ? [] : editor.publishedOf(owner).map((a) => ({ excerpt: null, hasMore: true, ...a }));
    return [...fixtures, ...written].sort((a, b) => b.publishedAt.localeCompare(a.publishedAt) || b.id.localeCompare(a.id));
  }

  function inCategory(owner, categoryId) {
    const state = stateOf(owner);
    return publishedOf(owner).filter((a) => (state.assigned.get(a.id) ?? null) === categoryId);
  }

  const dto = (owner, category, sortOrder) => ({ id: category.id, slug: category.slug, name: category.name, articleCount: inCategory(owner, category.id).length, sortOrder });

  function list(owner, { withEmpty }) {
    const state = stateOf(owner);
    const items = state.categories.map((c, i) => dto(owner, c, i + 1)).filter((c) => withEmpty || c.articleCount > 0);
    return { items, uncategorizedCount: inCategory(owner, null).length };
  }

  const author = (record) => ({ id: record.id, displayName: record.displayName, username: record.username, avatarUrl: record.avatarUrl ?? null, isVerified: !!record.isVerified });

  /** The category page's target: a category of the writer (slug ignoring case), `_other`, or null. */
  function pageOf(owner, rawSlug) {
    const slug = decodeURIComponent(rawSlug).toLowerCase();
    if (slug === OTHER) return { id: null, slug: OTHER, name: null };
    return stateOf(owner).categories.find((c) => c.slug.toLowerCase() === slug) ?? null;
  }

  /** A name that may be saved, or the error to answer with. */
  function checkName(state, raw, exceptId = null) {
    const name = cleanCategoryName(raw);
    if (!name || name.length > MAX_NAME || !LETTER_OR_DIGIT.test(name)) return { error: nameInvalid() };
    if (state.categories.some((c) => c.id !== exceptId && sameName(c.name, name))) return { error: taken() };
    return { name };
  }

  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = viewerOf(req);
      return viewer ? handler(viewer, q, match, body, req) : unauthorized();
    };

  /** One of your categories, or 404 / 403. */
  const own =
    (handler) =>
    (q, match, body, req) => {
      const viewer = viewerOf(req);
      if (!viewer) return unauthorized();
      const id = decodeURIComponent(match[1]);
      const state = stateOf(viewer);
      const category = state.categories.find((c) => c.id === id);
      if (!category) return findAnywhere(id) ? notOwner() : notFound();
      return handler(viewer, state, category, body);
    };

  /** `/users/{username}/categories…`: the writer, or a 404. */
  const ofWriter =
    (handler) =>
    (q, match, body, req) => {
      const viewer = viewerOf(req);
      const record = lookup(match[1], viewer);
      return record ? handler(record, viewer, q, match) : userNotFound();
    };

  const USER = '([^/]+)';
  const routes = [
    ['GET', new RegExp(`^${API}/users/${USER}/categories$`), ofWriter((record) => [200, list(record.id, { withEmpty: false })])],
    [
      'GET',
      new RegExp(`^${API}/users/${USER}/categories/([^/]+)$`),
      ofWriter((record, _viewer, _q, match) => {
        const target = pageOf(record.id, match[2]);
        if (!target) return notFound();
        return [200, { id: target.id, slug: target.slug, name: target.name, articleCount: inCategory(record.id, target.id).length, author: author(record) }];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/users/${USER}/categories/([^/]+)/articles$`),
      ofWriter((record, viewer, q, match) => {
        const target = pageOf(record.id, match[2]);
        if (!target) return notFound();
        const items = inCategory(record.id, target.id);
        const offset = Number(q.get('cursor') ?? 0) || 0;
        const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
        return [200, { items: items.slice(offset, offset + limit).map((a) => personalize(a, viewer)), nextCursor: offset + limit < items.length ? String(offset + limit) : null }];
      }),
    ],
    ['GET', new RegExp(`^${API}/me/categories$`), signedIn((viewer) => [200, list(viewer, { withEmpty: true })])],
    [
      'POST',
      new RegExp(`^${API}/me/categories$`),
      signedIn((viewer, _q, _m, body) => {
        const state = stateOf(viewer);
        if (state.categories.length >= MAX_CATEGORIES) return [400, problem(400, 'category.limit', 'You can have up to 50 categories.')];
        const checked = checkName(state, body?.name);
        if (checked.error) return checked.error;
        const category = create(state, viewer, checked.name);
        return [201, dto(viewer, category, state.categories.length)];
      }),
    ],
    [
      'PUT',
      new RegExp(`^${API}/me/categories/order$`),
      signedIn((viewer, _q, _m, body) => {
        const ids = body?.categoryIds;
        if (!Array.isArray(ids)) return [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { categoryIds: ['validation.required'] } }];
        if (ids.length > MAX_CATEGORIES) return [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { categoryIds: ['category.limit'] } }];
        const state = stateOf(viewer);
        const listed = [...new Set(ids)].map((id) => state.categories.find((c) => c.id === id)).filter(Boolean);
        state.categories = [...listed, ...state.categories.filter((c) => !listed.includes(c))];
        return [200, list(viewer, { withEmpty: true })];
      }),
    ],
    [
      'PATCH',
      new RegExp(`^${API}/me/categories/([^/]+)$`),
      own((viewer, state, category, body) => {
        const checked = checkName(state, body?.name, category.id);
        if (checked.error) return checked.error;
        category.name = checked.name;
        return [200, dto(viewer, category, state.categories.indexOf(category) + 1)];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/me/categories/([^/]+)$`),
      own((_viewer, state, category) => {
        state.categories = state.categories.filter((c) => c !== category);
        for (const [articleId, categoryId] of state.assigned) if (categoryId === category.id) state.assigned.delete(articleId);
        return [204, undefined];
      }),
    ],
    [
      'PUT',
      new RegExp(`^${API}/articles/([^/]+)/category$`),
      signedIn((viewer, _q, [, rawId], body) => {
        const id = decodeURIComponent(rawId);
        const fixture = articles().find((a) => a.id === id);
        const mine = editor.owns(viewer, id) || fixture?.author?.id === viewer;
        if (!mine) return fixture ? [403, problem(403, 'article.not_owner', 'This is not your article.')] : [404, problem(404, 'article.not_found', 'Article not found')];
        const state = stateOf(viewer);
        const categoryId = body?.categoryId ?? null;
        if (categoryId === null) {
          state.assigned.delete(id);
          return [204, undefined];
        }
        if (!state.categories.some((c) => c.id === categoryId)) return findAnywhere(categoryId) ? notOwner() : notFound();
        state.assigned.set(id, categoryId);
        return [204, undefined];
      }),
    ],
  ];

  /** `ArticleDetailsDto.category`: `{ slug, name }` of the author's category, or null. */
  function decorateArticle(details) {
    const owner = details.author?.id;
    if (!owner) return { ...details, category: null };
    const state = stateOf(owner);
    const category = state.categories.find((c) => c.id === state.assigned.get(details.id));
    return { ...details, category: category ? { slug: category.slug, name: category.name } : null };
  }

  /** `ArticleEditDto.categoryId` of one of the viewer's articles. */
  const categoryIdOf = (viewer, articleId) => {
    const state = stateOf(viewer);
    const id = state.assigned.get(articleId) ?? null;
    return id && state.categories.some((c) => c.id === id) ? id : null;
  };

  /** All of a user's categories, empty ones too (a moderator's user case). */
  const categoriesOf = (userId) => list(userId, { withEmpty: true }).items;

  return { routes, decorateArticle, categoryIdOf, categoriesOf };
}
