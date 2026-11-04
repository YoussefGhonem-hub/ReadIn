/**
 * Profiles (F14) for the mock API, per the F14 contract: public profiles, the Articles tab, public reading stats,
 * `PATCH /me` and `PUT /me/privacy` (public reading stats and "who can mention me", step 6.3), plus `GET /me` and
 * `/me/stats` for whoever is signed in.
 *
 * Like social.mjs, state is kept per viewer (the bearer token's `sub`), so parallel tests never see each other's
 * edits. A viewer's own profile is only visible to that viewer (as `isMe`); everyone else sees the seeded writers and
 * readers. Viewers start as the persona e2e/support/social.ts signs in with, "Sara Hassan" (@sara): `u-new-*` viewers
 * with an empty profile, every other `u-viewer-*` with a bio, a link and a field; `u-writer` is the demo writer Mona.
 */

const TODAY = '2026-11-03';
const MAX_BIO = 300;
const MAX_EXPERTISE = 5;
const USERNAME = /^[a-z0-9_]{3,30}$/;
const MENTION_POLICIES = ['everyone', 'following', 'nobody'];

/** What the seeded writers add on their profiles (bios come from server.mjs). About a third have public stats. */
const WRITER_PROFILES = {
  'u-writer': {
    links: { github: 'https://github.com/mona-adel', linkedin: 'https://www.linkedin.com/in/mona-adel', website: 'https://mona.dev' },
    expertise: ['f-software'],
    joinedAt: '2026-01-10T09:00:00Z',
    totalReads: 5120,
    publicReadingStats: true,
  },
  'u-readin': { links: { website: 'https://readin.app' }, expertise: ['f-software', 'f-medicine'], joinedAt: '2025-12-01T09:00:00Z', totalReads: 48200, publicReadingStats: false },
  'u-karim': { links: { github: 'https://github.com/karim-hassan' }, expertise: ['f-software'], joinedAt: '2026-02-14T09:00:00Z', totalReads: 2310, publicReadingStats: false },
  'u-salma': { links: { linkedin: 'https://www.linkedin.com/in/salma-ibrahim' }, expertise: ['f-software'], joinedAt: '2026-03-02T09:00:00Z', totalReads: 1890, publicReadingStats: true },
  'u-omar': { links: {}, expertise: ['f-medicine'], joinedAt: '2026-05-20T09:00:00Z', totalReads: 640, publicReadingStats: false },
};

const READER_PERMISSIONS = ['articles.read', 'reactions.create', 'saved.manage', 'follows.manage'];

function hash(text) {
  let h = 2166136261;
  for (const ch of text) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return h >>> 0;
}

function addDays(date, days) {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

const isHttps = (url) => {
  if (typeof url !== 'string' || url.length > 2048) return false;
  try {
    return new URL(url).protocol === 'https:';
  } catch {
    return false;
  }
};

/**
 * @param {{
 *   origin: string, me: () => any, articles: any[], writers: any[], fields: any[], social: any,
 *   problem: (status: number, code: string, title: string) => any,
 *   avatarVariants: (seed: string) => Record<'64' | '128' | '256' | '512', string>,
 * }} deps
 */
export function createProfiles({ me, articles, writers, fields, social, problem, avatarVariants }) {
  const fieldById = new Map(fields.map((f) => [f.id, f]));
  const own = new Map();

  const validation = (errors) => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors }];
  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const notFound = () => [404, problem(404, 'user.not_found', 'User not found')];
  const lang = (req) => (/^ar/i.test(req.headers['accept-language'] ?? '') ? 'ar' : 'en');

  /** Your own profile: seeded on first use, then whatever you saved. */
  function ownProfile(viewer) {
    if (!own.has(viewer)) {
      if (viewer === 'u-writer') {
        const mona = writers.find((w) => w.id === 'u-writer');
        const extra = WRITER_PROFILES['u-writer'];
        own.set(viewer, { ...mona, links: { ...extra.links }, expertise: [...extra.expertise], joinedAt: extra.joinedAt, totalReads: extra.totalReads, avatarSeed: null, publicReadingStats: extra.publicReadingStats, whoCanMention: 'everyone' });
      } else {
        const fresh = viewer.startsWith('u-new');
        own.set(viewer, {
          id: viewer,
          displayName: 'Sara Hassan',
          username: 'sara',
          isVerified: false,
          bio: fresh ? null : 'بقرا كل يوم عن الـ backend والـ system design.',
          links: fresh ? {} : { github: 'https://github.com/sara-hassan' },
          expertise: fresh ? [] : ['f-software'],
          joinedAt: '2026-09-01T09:00:00Z',
          totalReads: 0,
          avatarSeed: null,
          publicReadingStats: false,
          whoCanMention: 'everyone',
        });
      }
    }
    return own.get(viewer);
  }

  /** The public record for a username (case-insensitive, a leading @ ignored), or your own when it's you. */
  function lookup(username, viewer) {
    const name = decodeURIComponent(username).replace(/^@/, '').toLowerCase();
    if (viewer && ownProfile(viewer).username === name) return ownProfile(viewer);
    const writer = writers.find((w) => w.username === name);
    if (writer) {
      if (viewer === writer.id) return ownProfile(viewer);
      const extra = WRITER_PROFILES[writer.id] ?? {};
      return { ...writer, links: extra.links ?? {}, expertise: extra.expertise ?? [], joinedAt: extra.joinedAt ?? '2026-01-01T09:00:00Z', totalReads: extra.totalReads ?? 0, avatarSeed: null, publicReadingStats: !!extra.publicReadingStats };
    }
    const reader = social.readers.find((r) => r.username === name);
    if (reader) return { ...reader, bio: null, links: {}, expertise: [], joinedAt: '2026-06-01T09:00:00Z', totalReads: 0, avatarSeed: null, publicReadingStats: false };
    return null;
  }

  const visible = (record, viewer) => viewer === record.id || record.publicReadingStats;
  const avatarOf = (record) => {
    if (record.avatarSeed) {
      const variants = avatarVariants(record.avatarSeed);
      return { avatarUrl: variants['256'], avatarVariants: variants };
    }
    return { avatarUrl: record.avatarUrl ?? null, avatarVariants: null };
  };

  function profileDto(record, viewer, uiLang) {
    const isMe = viewer === record.id;
    const published = articles.filter((a) => a.author?.id === record.id).length;
    const followsYou = !!viewer && !isMe && !!record.followsEveryone;
    return {
      id: record.id,
      displayName: record.displayName,
      username: record.username,
      ...avatarOf(record),
      isVerified: record.isVerified,
      bio: record.bio ?? null,
      links: { github: record.links.github ?? null, linkedin: record.links.linkedin ?? null, website: record.links.website ?? null },
      expertise: record.expertise.flatMap((id) => {
        const f = fieldById.get(id);
        return f ? [{ id: f.id, slug: f.slug, name: uiLang === 'ar' ? f.nameAr : f.nameEn, icon: f.icon, color: f.color }] : [];
      }),
      joinedAt: record.joinedAt,
      stats: {
        articles: published,
        followers: record.followerCount !== undefined ? social.followerCount(record.id, viewer) : social.listCount(record.id, 'followers', viewer),
        following: social.listCount(record.id, 'following', viewer),
        totalReads: record.totalReads,
      },
      isMe,
      isFollowing: !isMe && social.isFollowing(viewer, record.id),
      followsYou,
      readingStatsVisible: visible(record, viewer),
    };
  }

  const privacyOf = (record) => ({ publicReadingStats: record.publicReadingStats, whoCanMention: record.whoCanMention });

  /** `GET /me` for the signed-in viewer (the base `me()` for calls without a token, like e2e's writerMe()). */
  function meOf(viewer) {
    const base = me();
    if (!viewer) return base;
    const record = ownProfile(viewer);
    // The demo writer stays the account the auth suites expect; no test edits it.
    if (viewer === 'u-writer') return { ...base, privacy: privacyOf(record) };
    return {
      ...base,
      id: viewer,
      isVerified: false,
      roles: ['Member'],
      permissions: READER_PERMISSIONS,
      displayName: record.displayName,
      username: record.username,
      avatarUrl: avatarOf(record).avatarUrl,
      bio: record.bio ?? null,
      links: { ...record.links },
      privacy: privacyOf(record),
    };
  }

  // ── Reading stats (deterministic per user; every test reader is the same Sara, whatever their random id) ──

  function heatmapOf(userId, days = 365) {
    const fresh = userId.startsWith('u-new');
    const seed = userId.startsWith('u-viewer') ? 'sara' : userId;
    const from = addDays(TODAY, -(days - 1));
    const list = [];
    if (!fresh) {
      for (let i = 0; i < days; i++) {
        const date = addDays(from, i);
        const recent = i >= days - 12; // the current 12-day streak
        const h = hash(`${seed}:${date}`) % 100;
        if (recent || h < 42) {
          const articlesRead = 1 + (h % 4 === 0 ? 2 : h % 3 === 0 ? 1 : 0);
          list.push({ date, articles: articlesRead, minutes: articlesRead * 6 + (h % 5), frozen: false });
        } else if (h > 97) {
          list.push({ date, articles: 0, minutes: 0, frozen: true });
        }
      }
    }
    return { from, to: TODAY, days: list };
  }

  function statsOf(userId, uiLang) {
    const year = heatmapOf(userId, 365).days;
    const since = (n) => year.filter((d) => d.date > addDays(TODAY, -n));
    const sum = (days, key) => days.reduce((total, d) => total + d[key], 0);
    const fresh = userId.startsWith('u-new');
    const total = sum(year, 'articles');
    const software = fieldById.get('f-software');
    const medicine = fieldById.get('f-medicine');
    const top = (f, n) => ({ id: f.id, slug: f.slug, name: uiLang === 'ar' ? f.nameAr : f.nameEn, icon: f.icon, color: f.color, articles: n });
    return {
      streak: { current: fresh ? 0 : 12, longest: fresh ? 0 : 30, readToday: !fresh, freezeAvailable: true, freezePending: false, today: TODAY },
      totalArticles: total,
      minutesRead: sum(year, 'minutes'),
      articlesThisWeek: sum(since(7), 'articles'),
      minutesThisWeek: sum(since(7), 'minutes'),
      articlesThisMonth: sum(since(30), 'articles'),
      topFields: fresh ? [] : [top(software, Math.round(total * 0.7)), top(medicine, Math.round(total * 0.2))],
    };
  }

  const heatmapDays = (q) => Math.min(371, Math.max(1, Number(q.get('days') ?? 365) || 365));

  // ── PATCH /me ──

  function updateProfile(viewer, body) {
    const record = ownProfile(viewer);
    const errors = {};
    const displayName = typeof body?.displayName === 'string' ? body.displayName.trim() : '';
    const username = typeof body?.username === 'string' ? body.username.trim() : '';
    if (displayName.length < 2 || displayName.length > 60) errors.displayName = ['validation.length'];
    if (!USERNAME.test(username)) errors.username = ['user.username_invalid'];
    if (typeof body?.bio === 'string' && body.bio.length > MAX_BIO) errors.bio = ['validation.max_length'];
    // The API's property paths (C# GitHub / LinkedIn), camelCased.
    const linkKeys = { github: 'links.gitHub', linkedin: 'links.linkedIn', website: 'links.website' };
    for (const [kind, key] of Object.entries(linkKeys)) {
      const url = body?.links?.[kind];
      if (url !== null && url !== undefined && !isHttps(url)) errors[key] = ['validation.url'];
    }
    if (Object.keys(errors).length) return validation(errors);

    const taken = username !== record.username && (username === 'taken' || writers.some((w) => w.username === username && w.id !== viewer) || social.readers.some((r) => r.username === username));
    if (taken) return [409, problem(409, 'user.username_taken', 'That username is taken.')];

    // avatarAssetId: left out = keep, null = remove, an id = an image you uploaded with purpose=avatar.
    let avatarSeed = record.avatarSeed;
    let avatarUrl = record.avatarUrl ?? null;
    if (body && 'avatarAssetId' in body) {
      if (body.avatarAssetId === null) {
        avatarSeed = null;
        avatarUrl = null;
      } else {
        const seed = /^asset-avatar-([a-z0-9-]+)$/.exec(String(body.avatarAssetId))?.[1];
        if (!seed) return [400, { ...problem(400, 'profile.avatar_invalid', 'This photo can’t be used.'), errors: { avatarAssetId: ['profile.avatar_invalid'] } }];
        avatarSeed = seed;
      }
    }

    // expertiseFieldIds: left out = unchanged, [] clears, repeats count once; unknown ids or more than 5 → 400.
    let expertise = record.expertise;
    if (body && Array.isArray(body.expertiseFieldIds)) {
      const ids = [...new Set(body.expertiseFieldIds)];
      if (ids.length > MAX_EXPERTISE || ids.some((id) => !fieldById.has(id))) {
        return [400, { ...problem(400, 'profile.expertise_invalid', 'Pick up to 5 fields.'), errors: { expertiseFieldIds: ['profile.expertise_invalid'] } }];
      }
      expertise = ids;
    }

    Object.assign(record, {
      displayName,
      username,
      bio: typeof body.bio === 'string' && body.bio.trim() ? body.bio.trim() : null,
      links: Object.fromEntries(Object.keys(linkKeys).flatMap((kind) => (body.links?.[kind] ? [[kind, body.links[kind]]] : []))),
      avatarSeed,
      avatarUrl,
      expertise,
    });
    return [204, undefined];
  }

  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = social.viewerOf(req);
      return viewer ? handler(viewer, q, match, body, req) : unauthorized();
    };

  const API = '/api/v1';
  // Not /users/suggested or /users/username-available (other modules answer those).
  const USER = '(?!suggested$|username-available$)([^/]+)';
  const routes = [
    ['GET', new RegExp(`^${API}/me$`), (_q, _m, _body, req) => [200, meOf(social.viewerOf(req))]],
    ['PATCH', new RegExp(`^${API}/me$`), signedIn((viewer, _q, _m, body) => updateProfile(viewer, body))],
    [
      'PUT',
      new RegExp(`^${API}/me/privacy$`),
      // Each setting is optional (left out = unchanged) but one is required; the clients send them all.
      signedIn((viewer, _q, _m, body) => {
        const { publicReadingStats, whoCanMention } = body ?? {};
        if (publicReadingStats === undefined && whoCanMention === undefined) return validation({ '': ['validation.required'] });
        if (publicReadingStats !== undefined && typeof publicReadingStats !== 'boolean') return validation({ publicReadingStats: ['validation.invalid'] });
        if (whoCanMention !== undefined && !MENTION_POLICIES.includes(whoCanMention)) return validation({ whoCanMention: ['validation.invalid'] });
        const record = ownProfile(viewer);
        if (publicReadingStats !== undefined) record.publicReadingStats = publicReadingStats;
        if (whoCanMention !== undefined) record.whoCanMention = whoCanMention;
        return [204, undefined];
      }),
    ],
    ['GET', new RegExp(`^${API}/me/stats$`), signedIn((viewer, _q, _m, _body, req) => [200, statsOf(viewer, lang(req))])],
    ['GET', new RegExp(`^${API}/me/stats/heatmap$`), signedIn((viewer, q) => [200, heatmapOf(viewer, heatmapDays(q))])],
    [
      'GET',
      new RegExp(`^${API}/users/${USER}$`),
      (_q, [, username], _body, req) => {
        const viewer = social.viewerOf(req);
        const record = lookup(username, viewer);
        return record ? [200, profileDto(record, viewer, lang(req))] : notFound();
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/users/${USER}/articles$`),
      (q, [, username], _body, req) => {
        const viewer = social.viewerOf(req);
        const record = lookup(username, viewer);
        if (!record) return notFound();
        const items = articles.filter((a) => a.author?.id === record.id).sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
        const offset = Number(q.get('cursor') ?? 0) || 0;
        const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
        return [200, { items: items.slice(offset, offset + limit).map((a) => social.personalize(a, viewer)), nextCursor: offset + limit < items.length ? String(offset + limit) : null }];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/users/${USER}/stats(/heatmap)?$`),
      (q, [, username, heatmap], _body, req) => {
        const viewer = social.viewerOf(req);
        const record = lookup(username, viewer);
        if (!record) return notFound();
        if (!visible(record, viewer)) return [403, problem(403, 'profile.stats_private', 'These reading stats are private.')];
        return [200, heatmap ? heatmapOf(record.id, heatmapDays(q)) : statsOf(record.id, lang(req))];
      },
    ],
  ];

  // paths.mjs answers `/users/{username}/paths` under the same visibility rule as the reading stats.
  return { routes, lookup, statsVisible: visible };
}
