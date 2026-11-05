/**
 * Profiles (F14) for the mock API, per the F14 contract: public profiles, the Articles tab, public reading stats,
 * `PATCH /me` and `PUT /me/privacy` (public reading stats and "who can mention me", step 6.3), plus `GET /me` and
 * `/me/stats` for whoever is signed in.
 *
 * Like social.mjs, state is kept per viewer (the bearer token's `sub`), so parallel tests never see each other's
 * edits. A viewer's own profile is only visible to that viewer (as `isMe`); everyone else sees the seeded writers and
 * readers. Viewers start as the persona e2e/support/social.ts signs in with, "Sara Hassan" (@sara): `u-new-*` viewers
 * with an empty profile, every other `u-viewer-*` with a bio, a link and a field; `u-writer` is the demo writer Mona.
 *
 * Pre-production step (F14, F29): the title (`headline`, from server.mjs's writers) and the social links as an ordered
 * array of `{ platform, url, label }`, with `PATCH /me`'s rules (contract: Profile → "Title and social links"), and the
 * Reposts tab (`GET /users/{username}/reposts`).
 */

const TODAY = '2026-11-03';
const MAX_BIO = 300;
const MAX_EXPERTISE = 5;
const USERNAME = /^[a-z0-9_]{3,30}$/;
const MENTION_POLICIES = ['everyone', 'following', 'nobody'];

const link = (platform, url, label = null) => ({ platform, url, label });

/** What the seeded writers add on their profiles (bios and titles come from server.mjs). About a third have public stats. */
const WRITER_PROFILES = {
  'u-writer': {
    links: [
      link('linkedin', 'https://www.linkedin.com/in/mona-adel'),
      link('github', 'https://github.com/mona-adel'),
      link('x', 'https://x.com/mona_adel'),
      link('youtube', 'https://youtube.com/@mona-adel'),
      link('website', 'https://mona.dev'),
      link('other', 'https://podcasts.example/mona', 'بودكاست Backend'),
    ],
    expertise: ['f-software'],
    joinedAt: '2026-01-10T09:00:00Z',
    totalReads: 5120,
    publicReadingStats: true,
  },
  'u-readin': { links: [link('website', 'https://readin.app')], expertise: ['f-software', 'f-medicine'], joinedAt: '2025-12-01T09:00:00Z', totalReads: 48200, publicReadingStats: false },
  'u-karim': { links: [link('github', 'https://github.com/karim-hassan')], expertise: ['f-software'], joinedAt: '2026-02-14T09:00:00Z', totalReads: 2310, publicReadingStats: false },
  'u-salma': { links: [link('linkedin', 'https://www.linkedin.com/in/salma-ibrahim')], expertise: ['f-software'], joinedAt: '2026-03-02T09:00:00Z', totalReads: 1890, publicReadingStats: true },
  'u-omar': { links: [], expertise: ['f-medicine'], joinedAt: '2026-05-20T09:00:00Z', totalReads: 640, publicReadingStats: false },
};

/**
 * The writers' reposts (F29) on their profiles' Reposts tab, newest first there. The same reposts web1's reposts.mjs
 * puts in the Following feed of its own viewers.
 */
const PROFILE_REPOSTS = {
  'u-karim': [
    { articleId: 'a-sleep-and-memory', at: '2026-11-03T12:00:00Z' },
    { articleId: 'a-what-is-a-transformer-ar', at: '2026-11-02T20:00:00Z' },
  ],
  'u-readin': [
    { articleId: 'a-sleep-and-memory', at: '2026-11-03T08:00:00Z' },
    { articleId: 'a-react-server-components-explained', at: '2026-11-03T10:00:00Z' },
  ],
};

// ── Links and title: PATCH /me's rules (contract "Title and social links") ──

const PLATFORMS = ['linkedin', 'x', 'instagram', 'facebook', 'youtube', 'tiktok', 'snapchat', 'threads', 'telegram', 'github', 'medium', 'behance', 'website', 'other'];
const HOSTS = {
  linkedin: ['linkedin.com', 'lnkd.in'],
  x: ['x.com', 'twitter.com'],
  instagram: ['instagram.com', 'instagr.am'],
  facebook: ['facebook.com', 'fb.com', 'fb.me'],
  youtube: ['youtube.com', 'youtu.be'],
  tiktok: ['tiktok.com'],
  snapchat: ['snapchat.com'],
  threads: ['threads.net', 'threads.com'],
  telegram: ['t.me', 'telegram.me'],
  github: ['github.com'],
  medium: ['medium.com'],
  behance: ['behance.net'],
};
/** Control, direction and isolate characters (by code point): a title or a label is one clean line. */
const UNCLEAN = [
  [0x00, 0x1f],
  [0x7f, 0x9f],
  [0x200e, 0x200f],
  [0x2028, 0x2029],
  [0x202a, 0x202e],
  [0x2066, 0x2069],
];
const cleanLine = (text) => [...text].every((ch) => !UNCLEAN.some(([from, to]) => ch.codePointAt(0) >= from && ch.codePointAt(0) <= to));

function urlProblem(platform, url) {
  if (!url) return 'validation.required';
  if (url.length > 500) return 'link.too_long';
  if (url.slice(0, url.indexOf('://')).toLowerCase() !== 'https') return 'link.https_required';
  if (/\s/.test(url) || !cleanLine(url)) return 'link.url_invalid';
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return 'link.url_invalid';
  }
  if (parsed.username || parsed.password || parsed.port) return 'link.url_invalid';
  const host = parsed.hostname.replace(/\.+$/, '').toLowerCase();
  if (!host.includes('.') || host.startsWith('[') || /^\d+(\.\d+){3}$/.test(host)) return 'link.url_invalid';
  const hosts = HOSTS[platform];
  return hosts && !hosts.some((h) => host === h || host.endsWith(`.${h}`)) ? 'link.host_mismatch' : null;
}

/** `links` of `PATCH /me` → `{ links }` normalized, or `{ errors }` keyed like the API (`links[2].url`). */
function checkLinks(input) {
  const errors = {};
  if (!Array.isArray(input)) return { errors: { links: ['validation.invalid'] } };
  if (input.length > 8) errors.links = ['link.too_many'];
  const seen = new Set();
  const links = input.map((item, i) => {
    const platform = item?.platform;
    if (!PLATFORMS.includes(platform)) errors[`links[${i}].platform`] = ['link.platform_invalid'];
    else if (platform !== 'other' && seen.has(platform)) errors[`links[${i}].platform`] = ['link.duplicate_platform'];
    seen.add(platform);
    const raw = typeof item?.url === 'string' ? item.url.trim() : '';
    const url = raw && !raw.includes('://') ? `https://${raw}` : raw;
    const urlCode = urlProblem(platform, url);
    if (urlCode) errors[`links[${i}].url`] = [urlCode];
    const label = typeof item?.label === 'string' && item.label.trim() ? item.label.trim() : null;
    let labelCode = null;
    if (platform === 'other') {
      if (!label) labelCode = 'link.label_required';
      else if (label.length < 2 || label.length > 30 || !cleanLine(label)) labelCode = 'link.label_invalid';
    } else if (label && PLATFORMS.includes(platform)) labelCode = 'link.label_not_allowed';
    if (labelCode) errors[`links[${i}].label`] = [labelCode];
    return { platform, url, label: platform === 'other' ? label : null };
  });
  return Object.keys(errors).length ? { errors } : { links };
}

/** `headline` of `PATCH /me` / complete profile: trimmed, blank → null, ≤ 120, one clean line. */
function checkHeadline(value) {
  const headline = typeof value === 'string' && value.trim() ? value.trim() : null;
  if (headline && headline.length > 120) return { error: 'profile.headline_too_long' };
  if (headline && !cleanLine(headline)) return { error: 'profile.headline_invalid' };
  return { headline };
}

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
        own.set(viewer, { ...mona, links: extra.links.map((l) => ({ ...l })), expertise: [...extra.expertise], joinedAt: extra.joinedAt, totalReads: extra.totalReads, avatarSeed: null, publicReadingStats: extra.publicReadingStats, whoCanMention: 'everyone' });
      } else {
        const fresh = viewer.startsWith('u-new');
        own.set(viewer, {
          id: viewer,
          displayName: 'Sara Hassan',
          username: 'sara',
          isVerified: false,
          bio: fresh ? null : 'بقرا كل يوم عن الـ backend والـ system design.',
          headline: null,
          links: fresh ? [] : [link('github', 'https://github.com/sara-hassan')],
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
      return { ...writer, links: extra.links ?? [], expertise: extra.expertise ?? [], joinedAt: extra.joinedAt ?? '2026-01-01T09:00:00Z', totalReads: extra.totalReads ?? 0, avatarSeed: null, publicReadingStats: !!extra.publicReadingStats };
    }
    const reader = social.readers.find((r) => r.username === name);
    if (reader) return { ...reader, bio: null, headline: reader.headline ?? null, links: [], expertise: [], joinedAt: '2026-06-01T09:00:00Z', totalReads: 0, avatarSeed: null, publicReadingStats: false };
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
      headline: record.headline ?? null,
      links: (record.links ?? []).map((l) => ({ ...l })),
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
    if (viewer === 'u-writer') {
      return { ...base, headline: record.headline ?? null, links: record.links.map((l) => ({ ...l })), privacy: privacyOf(record), interests: social.interestsOf(viewer) };
    }
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
      headline: record.headline ?? null,
      links: record.links.map((l) => ({ ...l })),
      privacy: privacyOf(record),
      interests: social.interestsOf(viewer),
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
    // headline: left out keeps it, null or blank clears it.
    const title = body && 'headline' in body ? checkHeadline(body.headline) : { headline: record.headline ?? null };
    if (title.error) errors.headline = [title.error];
    // links: left out or null keeps them, an array replaces the whole list ([] clears), in the order sent.
    const checked = Array.isArray(body?.links) ? checkLinks(body.links) : { links: record.links };
    if (checked.errors) Object.assign(errors, checked.errors);
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
      headline: title.headline,
      links: checked.links,
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
      // F29: the Reposts tab, newest repost first; each card's `repostedBy` is this user.
      'GET',
      new RegExp(`^${API}/users/${USER}/reposts$`),
      (q, [, username], _body, req) => {
        const viewer = social.viewerOf(req);
        const record = lookup(username, viewer);
        if (!record) return notFound();
        const user = { id: record.id, displayName: record.displayName, username: record.username, avatarUrl: avatarOf(record).avatarUrl, isVerified: record.isVerified, headline: record.headline ?? null };
        const items = (PROFILE_REPOSTS[record.id] ?? [])
          .flatMap(({ articleId, at }) => {
            const article = articles.find((a) => a.id === articleId);
            return article ? [{ article, at }] : [];
          })
          .sort((a, b) => b.at.localeCompare(a.at));
        const offset = Number(q.get('cursor') ?? 0) || 0;
        const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
        return [
          200,
          {
            items: items.slice(offset, offset + limit).map(({ article, at }) => social.personalize({ ...article, repostedBy: { user, othersCount: 0, repostedAt: at } }, viewer)),
            nextCursor: offset + limit < items.length ? String(offset + limit) : null,
          },
        ];
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
  return { routes, lookup, statsVisible: visible, meOf };
}
