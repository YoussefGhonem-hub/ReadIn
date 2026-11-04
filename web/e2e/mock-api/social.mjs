/**
 * Reactions (F10), saved articles + collections (F13) and follows (F12) for the mock API, per the wave 1 contract.
 *
 * State is kept per viewer, keyed by the `sub` claim of the bearer token, so parallel Playwright tests that sign in as
 * different users (e2e/support/social.ts gives each test its own id) never see each other's changes. Anonymous calls,
 * like every SSR request, see the base counts and no personal state. A viewer whose id starts with `u-new` starts with
 * nothing saved, followed or reacted; every other viewer starts from the same seed.
 */

const REACTION_TYPES = ['insightful', 'love', 'fire', 'mindBlown'];
const MAX_COLLECTIONS = 50;
const MAX_NAME = 60;

const FIRST = ['Ahmed', 'Nour', 'Youssef', 'Mariam', 'Hana', 'Mostafa', 'Laila', 'Tarek', 'Dina', 'Ali', 'Farida', 'Hassan'];
const FIRST_AR = ['أحمد', 'نور', 'يوسف', 'مريم', 'هنا', 'مصطفى', 'ليلى', 'طارق', 'دينا', 'علي', 'فريدة', 'حسن'];
const LAST = ['Samir', 'Fawzy', 'Nabil', 'Gamal'];
const LAST_AR = ['سمير', 'فوزي', 'نبيل', 'جمال'];

/** 48 readers who react and follow (half with Arabic names), deterministic. */
const READERS = Array.from({ length: 48 }, (_, i) => {
  const first = i % FIRST.length;
  const last = Math.floor(i / FIRST.length) % LAST.length;
  const arabic = i % 2 === 1;
  return {
    id: `u-reader-${String(i + 1).padStart(2, '0')}`,
    displayName: arabic ? `${FIRST_AR[first]} ${LAST_AR[last]}` : `${FIRST[first]} ${LAST[last]}`,
    username: `${FIRST[first].toLowerCase()}_${LAST[last].toLowerCase()}${i}`,
    avatarUrl: null,
    isVerified: false,
  };
});

const sum = (reactions) => REACTION_TYPES.reduce((total, type) => total + reactions[type], 0);
const author = ({ id, displayName, username, avatarUrl, isVerified }) => ({ id, displayName, username, avatarUrl, isVerified });

function hash(text) {
  let h = 2166136261;
  for (const ch of text) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return h >>> 0;
}

/** Arabic-insensitive matching like the API's collation: no diacritics or tatweel, one alef, ة = ه, ى = ي. */
function normalize(text) {
  return text
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي');
}

function page(items, q, map = (x) => x) {
  const offset = Number(q.get('cursor') ?? 0) || 0;
  const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
  const slice = items.slice(offset, offset + limit);
  return { items: slice.map(map), nextCursor: offset + limit < items.length ? String(offset + limit) : null };
}

/**
 * @param {{ articles: any[], writers: any[], problem: (status: number, code: string, title: string) => any }} catalog
 *   every published article (card DTOs with guest values) and the writers who can be followed.
 */
export function createSocial({ articles, writers, problem }) {
  const byId = new Map(articles.map((a) => [a.id, a]));
  const people = new Map([...writers, ...READERS].map((u) => [u.id, u]));
  const states = new Map();
  let nextId = 1;

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const articleNotFound = () => [404, problem(404, 'article.not_found', 'Article not found')];
  const validation = (field, code) => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { [field]: [code] } }];

  function seed(userId) {
    if (userId.startsWith('u-new')) return { reactions: new Map(), saved: new Map(), collections: [], follows: new Set(), interests: { fieldIds: ['f-software'], topicIds: ['t-dotnet', 't-architecture'] } };
    return {
      reactions: new Map([
        ['a-how-readin-picks-your-daily-article', 'insightful'],
        ['a-dependency-injection-ar', 'love'],
      ]),
      saved: new Map([
        ['a-aspnet-core-cheatsheet', '2026-11-03T07:30:00Z'],
        ['a-react-server-components-explained', '2026-11-02T18:00:00Z'],
        ['a-what-is-a-transformer-ar', '2026-11-01T12:00:00Z'],
        ['a-sleep-and-memory', '2026-10-30T09:00:00Z'],
        ['a-clean-architecture-whiteboard', '2026-10-28T20:00:00Z'],
      ]),
      collections: [
        { id: 'c-interview', name: 'Interview prep', createdAt: '2026-10-20T10:00:00Z', articleIds: new Set(['a-aspnet-core-cheatsheet', 'a-clean-architecture-whiteboard']) },
        { id: 'c-weekend', name: 'قراءة الويك إند', createdAt: '2026-10-25T10:00:00Z', articleIds: new Set(['a-what-is-a-transformer-ar']) },
      ],
      follows: new Set(['u-readin', 'u-karim'].filter((id) => id !== userId)),
      interests: { fieldIds: ['f-software'], topicIds: ['t-dotnet', 't-architecture'] },
    };
  }

  function stateOf(viewer) {
    if (!states.has(viewer)) states.set(viewer, seed(viewer));
    return states.get(viewer);
  }

  /** The viewer's id from `Authorization: Bearer <unsigned JWT>` (nothing verifies it), or null for guests. */
  function viewerOf(req) {
    const token = /^Bearer (.+)$/.exec(req.headers.authorization ?? '')?.[1];
    if (!token) return null;
    try {
      return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8')).sub ?? null;
    } catch {
      return null;
    }
  }

  function countsOf(articleId, viewer) {
    const base = byId.get(articleId);
    const state = viewer ? stateOf(viewer) : null;
    const myReaction = state?.reactions.get(articleId) ?? null;
    const reactions = { ...base.reactions };
    if (myReaction) reactions[myReaction] += 1;
    const isSaved = state?.saved.has(articleId) ?? false;
    return { reactions, reactionCount: sum(reactions), myReaction, isSaved, saveCount: base.saveCount + (isSaved ? 1 : 0) };
  }

  /** A card or details DTO as `viewer` sees it. */
  function personalize(dto, viewer) {
    if (!byId.has(dto.id)) return dto;
    const result = { ...dto, ...countsOf(dto.id, viewer) };
    if ('isFollowingAuthor' in dto) {
      // `author` is null once the writer deleted their account: nobody follows them.
      result.isFollowingAuthor = !!viewer && !!dto.author && viewer !== dto.author.id && stateOf(viewer).follows.has(dto.author.id);
    }
    if ('collectionIds' in dto) {
      // The viewer's collections containing the article (empty for guests and unsaved articles).
      const state = viewer ? stateOf(viewer) : null;
      result.collectionIds = state?.saved.has(dto.id) ? state.collections.filter((c) => c.articleIds.has(dto.id)).map((c) => c.id) : [];
    }
    return result;
  }

  function followerCount(userId, viewer) {
    const base = people.get(userId)?.followerCount ?? 0;
    return base + (viewer && viewer !== userId && stateOf(viewer).follows.has(userId) ? 1 : 0);
  }

  /** Followers / following of `id` as `viewer` sees them: readers picked by a hash; your own Following is your follows. */
  function listOf(id, list, viewer) {
    if (list === 'following' && viewer && id === viewer) return writers.filter((w) => stateOf(viewer).follows.has(w.id));
    const start = hash(`${id}:${list}`) % READERS.length;
    const count = list === 'followers' ? 30 : 12;
    const users = Array.from({ length: count }, (_, i) => READERS[(start + i) % READERS.length]);
    if (list === 'followers' && viewer && viewer !== id && stateOf(viewer).follows.has(id)) {
      return [people.get(viewer) ?? { id: viewer, displayName: 'You', username: 'you', avatarUrl: null, isVerified: false }, ...users];
    }
    return users;
  }

  function summary(user, viewer) {
    return {
      ...author(user),
      bio: user.bio ?? null,
      isFollowing: !!viewer && stateOf(viewer).follows.has(user.id),
      followsYou: !!viewer && !!user.followsEveryone,
    };
  }

  /** Who reacted: the base reactions spread over the readers (types interleaved), the viewer's own first. */
  function reactorsOf(articleId, viewer) {
    const base = byId.get(articleId);
    const queues = REACTION_TYPES.map((type) => Array.from({ length: base.reactions[type] }, () => type));
    const types = [];
    while (queues.some((q) => q.length)) for (const q of queues) if (q.length) types.push(q.shift());
    const start = hash(articleId) % READERS.length;
    const list = types.map((type, i) => ({
      user: author(READERS[(start + i) % READERS.length]),
      type,
      reactedAt: new Date(Date.parse('2026-11-03T08:00:00Z') - (i + 1) * 37 * 60_000).toISOString(),
    }));
    const mine = viewer ? stateOf(viewer).reactions.get(articleId) : null;
    if (mine) {
      const me = people.get(viewer) ?? { id: viewer, displayName: 'You', username: 'you', avatarUrl: null, isVerified: false };
      list.unshift({ user: author(me), type: mine, reactedAt: '2026-11-03T08:30:00Z' });
    }
    return list;
  }

  function reactionsResult(articleId, viewer) {
    const { reactions, reactionCount, myReaction } = countsOf(articleId, viewer);
    return { reactions, total: reactionCount, myReaction };
  }

  function collectionDto(collection, state) {
    const articleCount = [...collection.articleIds].filter((id) => state.saved.has(id)).length;
    return { id: collection.id, name: collection.name, articleCount, createdAt: collection.createdAt };
  }

  function collectionsOf(state) {
    return [...state.collections].sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' })).map((c) => collectionDto(c, state));
  }

  function checkName(state, body, exceptId = null) {
    const name = typeof body?.name === 'string' ? body.name.trim() : '';
    // The API's generic validation codes (FluentValidation), like every other form field.
    if (!name) return { error: validation('name', 'validation.required') };
    if (name.length > MAX_NAME) return { error: validation('name', 'validation.max_length') };
    const taken = state.collections.some((c) => c.id !== exceptId && c.name.toLowerCase() === name.toLowerCase());
    if (taken) return { error: [409, problem(409, 'collection.name_taken', 'You already have a collection with this name.')] };
    return { name };
  }

  /** Wraps a handler that needs a signed-in viewer: `(viewer, state, ...rest)`. */
  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = viewerOf(req);
      return viewer ? handler(viewer, stateOf(viewer), q, match, body) : unauthorized();
    };

  const API = '/api/v1';
  const routes = [
    // ── F10 Reactions ──
    [
      'PUT',
      new RegExp(`^${API}/articles/([^/]+)/reaction$`),
      signedIn((viewer, state, _q, [, id], body) => {
        if (!byId.has(id)) return articleNotFound();
        if (!REACTION_TYPES.includes(body?.type)) return validation('type', 'reaction.invalid');
        state.reactions.set(id, body.type);
        return [200, reactionsResult(id, viewer)];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/articles/([^/]+)/reaction$`),
      signedIn((viewer, state, _q, [, id]) => {
        if (!byId.has(id)) return articleNotFound();
        state.reactions.delete(id);
        return [200, reactionsResult(id, viewer)];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/articles/([^/]+)/reactions$`),
      (q, [, id], _body, req) => {
        if (!byId.has(id)) return articleNotFound();
        const type = q.get('type');
        const all = reactorsOf(id, viewerOf(req));
        return [200, page(type ? all.filter((r) => r.type === type) : all, q)];
      },
    ],

    // ── F13 Saved ──
    [
      'PUT',
      new RegExp(`^${API}/me/saved/([^/]+)$`),
      signedIn((viewer, state, _q, [, id]) => {
        if (!byId.has(id)) return articleNotFound();
        if (!state.saved.has(id)) state.saved.set(id, new Date().toISOString());
        const { isSaved, saveCount } = countsOf(id, viewer);
        return [200, { isSaved, saveCount }];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/me/saved/([^/]+)$`),
      signedIn((viewer, state, _q, [, id]) => {
        if (!byId.has(id)) return articleNotFound();
        state.saved.delete(id);
        for (const c of state.collections) c.articleIds.delete(id);
        const { isSaved, saveCount } = countsOf(id, viewer);
        return [200, { isSaved, saveCount }];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/me/saved$`),
      signedIn((viewer, state, q) => {
        const field = q.get('field');
        const text = normalize(q.get('q') ?? '').trim();
        const collectionId = q.get('collection');
        const collection = collectionId ? state.collections.find((c) => c.id === collectionId) : null;
        if (collectionId && !collection) return [404, problem(404, 'collection.not_found', 'Collection not found')];
        const items = [...state.saved]
          .sort((a, b) => b[1].localeCompare(a[1]))
          .map(([id, savedAt]) => ({ id, savedAt, article: byId.get(id) }))
          .filter(({ id, article }) => article && (!field || article.field.slug === field) && (!text || normalize(article.title).includes(text)) && (!collection || collection.articleIds.has(id)));
        return [
          200,
          page(items, q, ({ id, savedAt, article }) => ({
            savedAt,
            collectionIds: state.collections.filter((c) => c.articleIds.has(id)).map((c) => c.id),
            article: personalize(article, viewer),
          })),
        ];
      }),
    ],
    ['GET', new RegExp(`^${API}/me/collections$`), signedIn((_viewer, state) => [200, collectionsOf(state)])],
    [
      'POST',
      new RegExp(`^${API}/me/collections$`),
      signedIn((_viewer, state, _q, _m, body) => {
        const { name, error } = checkName(state, body);
        if (error) return error;
        if (state.collections.length >= MAX_COLLECTIONS) return [400, problem(400, 'collection.limit', 'You can have up to 50 collections.')];
        const collection = { id: `c-new-${nextId++}`, name, createdAt: new Date().toISOString(), articleIds: new Set() };
        state.collections.push(collection);
        return [201, collectionDto(collection, state)];
      }),
    ],
    [
      'PATCH',
      new RegExp(`^${API}/me/collections/([^/]+)$`),
      signedIn((_viewer, state, _q, [, id], body) => {
        const collection = state.collections.find((c) => c.id === id);
        if (!collection) return [404, problem(404, 'collection.not_found', 'Collection not found')];
        const { name, error } = checkName(state, body, id);
        if (error) return error;
        collection.name = name;
        return [200, collectionDto(collection, state)];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/me/collections/([^/]+)$`),
      signedIn((_viewer, state, _q, [, id]) => {
        const index = state.collections.findIndex((c) => c.id === id);
        if (index < 0) return [404, problem(404, 'collection.not_found', 'Collection not found')];
        state.collections.splice(index, 1);
        return [204, undefined];
      }),
    ],
    [
      'PUT',
      new RegExp(`^${API}/me/collections/([^/]+)/articles/([^/]+)$`),
      signedIn((_viewer, state, _q, [, id, articleId]) => {
        const collection = state.collections.find((c) => c.id === id);
        if (!collection) return [404, problem(404, 'collection.not_found', 'Collection not found')];
        if (!byId.has(articleId)) return articleNotFound();
        if (!state.saved.has(articleId)) state.saved.set(articleId, new Date().toISOString());
        collection.articleIds.add(articleId);
        return [204, undefined];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/me/collections/([^/]+)/articles/([^/]+)$`),
      signedIn((_viewer, state, _q, [, id, articleId]) => {
        const collection = state.collections.find((c) => c.id === id);
        if (!collection) return [404, problem(404, 'collection.not_found', 'Collection not found')];
        collection.articleIds.delete(articleId);
        return [204, undefined];
      }),
    ],

    // ── F12 Follow ──
    [
      'GET',
      new RegExp(`^${API}/users/suggested$`),
      signedIn((viewer, state, q) => {
        const limit = Math.min(50, Number(q.get('limit') ?? 10) || 10);
        const list = writers
          .filter((u) => u.id !== viewer && !state.follows.has(u.id))
          .sort((a, b) => Number(b.isVerified) - Number(a.isVerified) || b.followerCount - a.followerCount)
          .slice(0, limit)
          .map((u) => summary(u, viewer));
        return [200, list];
      }),
    ],
    [
      'PUT',
      new RegExp(`^${API}/users/([^/]+)/follow$`),
      signedIn((viewer, state, _q, [, id]) => {
        if (id === viewer) return [400, problem(400, 'follow.self', "You can't follow yourself.")];
        if (!people.has(id)) return [404, problem(404, 'user.not_found', 'User not found')];
        state.follows.add(id);
        return [200, { isFollowing: true, followerCount: followerCount(id, viewer) }];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/users/([^/]+)/follow$`),
      signedIn((viewer, state, _q, [, id]) => {
        if (!people.has(id)) return [404, problem(404, 'user.not_found', 'User not found')];
        state.follows.delete(id);
        return [200, { isFollowing: false, followerCount: followerCount(id, viewer) }];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/users/([^/]+)/(followers|following)$`),
      (q, [, id, list], _body, req) => {
        const viewer = viewerOf(req);
        // Your own lists work too (your profile, F14), though you aren't one of the seeded people.
        if (!people.has(id) && id !== viewer) return [404, problem(404, 'user.not_found', 'User not found')];
        const text = normalize(q.get('q') ?? '').trim();
        let users = listOf(id, list, viewer);
        if (text) users = users.filter((u) => normalize(u.displayName).includes(text) || u.username.includes(text.replace(/^@/, '')));
        return [200, page(users, q, (u) => summary(u, viewer))];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/feed/following$`),
      signedIn((viewer, state, q) => {
        const items = articles.filter((a) => a.author && state.follows.has(a.author.id)).sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
        return [200, page(items, q, (a) => personalize(a, viewer))];
      }),
    ],
    ...['PUT', 'DELETE'].map((method) => [
      method,
      new RegExp(`^${API}/me/interests/(fields|topics)/([^/]+)$`),
      signedIn((_viewer, state, _q, [, kind, id]) => {
        const list = kind === 'fields' ? state.interests.fieldIds : state.interests.topicIds;
        if (method === 'PUT') {
          if (!list.includes(id)) list.push(id);
        } else if (list.includes(id)) {
          if (state.interests.fieldIds.length + state.interests.topicIds.length <= 3) {
            return [400, problem(400, 'user.interests.min_three', 'Pick at least 3 interests.')];
          }
          list.splice(list.indexOf(id), 1);
        }
        return [200, { fieldIds: [...state.interests.fieldIds], topicIds: [...state.interests.topicIds] }];
      }),
    ]),
  ];

  return {
    routes,
    personalize,
    viewerOf,
    readers: READERS,
    // Profiles (profiles.mjs) count and show the same follows.
    isFollowing: (viewer, id) => !!viewer && stateOf(viewer).follows.has(id),
    // `GET /me` (profiles.mjs) reports the interests that `PUT`/`DELETE /me/interests/…` change.
    interestsOf: (viewer) => ({ fieldIds: [...stateOf(viewer).interests.fieldIds], topicIds: [...stateOf(viewer).interests.topicIds] }),
    followerCount,
    listCount: (id, list, viewer) => listOf(id, list, viewer).length,
  };
}
