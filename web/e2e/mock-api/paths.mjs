/**
 * Learning paths (F09) and Home's "Continue reading" (F03) for the mock API, per the F09 contract.
 *
 * Like social.mjs, state is kept per viewer (the bearer token's `sub`): which articles they read and which paths they
 * joined. Seeded readers (`u-viewer-*`) are on "Web development foundations" (2 of 3 read, enrolled), finished
 * "AI from scratch" (completed) and haven't joined "Learn how to learn"; they have two unfinished articles to continue.
 * `u-new-*` readers start with nothing. Guests get no progress. On profiles, Mona (public stats) finished the web path
 * and is on the learning one; Salma (public stats) is on the AI path.
 */

const NOW = '2026-11-03T09:00:00Z';

const PATHS = [
  {
    id: 'p-web',
    slug: 'web-foundations',
    fieldId: 'f-software',
    titleAr: 'أساسيات تطوير الويب',
    titleEn: 'Web development foundations',
    descriptionAr: 'من الـ Clean Architecture لحد الـ Dependency Injection في ASP.NET Core، خطوة بخطوة.',
    descriptionEn: 'From Clean Architecture to dependency injection in ASP.NET Core, one step at a time.',
    cover: true,
    // Not the article the reaction-picker shots use (react-server-components-explained): its baseline stays as it is.
    slugs: ['clean-architecture-whiteboard', 'dependency-injection-ar', 'aspnet-core-cheatsheet'],
  },
  {
    id: 'p-ai',
    slug: 'ai-from-scratch',
    fieldId: 'f-software',
    titleAr: 'الـ AI من الصفر',
    titleEn: 'AI from scratch',
    descriptionAr: 'إزاي الموديلات بتفهم الكلام، من غير رياضيات تقيلة.',
    descriptionEn: 'How language models understand text, without the heavy math.',
    slugs: ['what-is-a-transformer-ar', 'how-readin-picks-your-daily-article'],
  },
  {
    id: 'p-learn',
    slug: 'learn-how-to-learn',
    fieldId: 'f-medicine',
    titleAr: 'اتعلم إزاي تتعلم',
    titleEn: 'Learn how to learn',
    descriptionAr: null,
    descriptionEn: null,
    slugs: ['sleep-and-memory', 'readin-streaks-ar', 'one-photo'],
  },
];

/** Who read what and joined which path; `activity` orders "latest activity first". */
function seed(userId) {
  const state = (read, enrolled) => ({ read: new Set(read), enrolled: new Map(Object.entries(enrolled)) });
  if (userId === 'u-writer') {
    return state(['clean-architecture-whiteboard', 'dependency-injection-ar', 'aspnet-core-cheatsheet', 'sleep-and-memory'], {
      'p-learn': { enrolledAt: '2026-10-28T09:00:00Z', completedAt: null, activity: '2026-11-02T20:00:00Z' },
      'p-web': { enrolledAt: '2026-09-01T09:00:00Z', completedAt: '2026-09-20T18:00:00Z', activity: '2026-09-20T18:00:00Z' },
    });
  }
  if (userId === 'u-salma') {
    return state(['what-is-a-transformer-ar'], { 'p-ai': { enrolledAt: '2026-10-15T09:00:00Z', completedAt: null, activity: '2026-10-30T09:00:00Z' } });
  }
  if (userId.startsWith('u-viewer')) {
    return state(['clean-architecture-whiteboard', 'dependency-injection-ar', 'what-is-a-transformer-ar', 'how-readin-picks-your-daily-article'], {
      'p-web': { enrolledAt: '2026-10-25T09:00:00Z', completedAt: null, activity: '2026-11-02T19:00:00Z' },
      'p-ai': { enrolledAt: '2026-10-10T09:00:00Z', completedAt: '2026-10-20T21:00:00Z', activity: '2026-10-20T21:00:00Z' },
    });
  }
  return state([], {});
}

/** Unfinished articles of seeded readers, most recent first. */
const CONTINUE = [
  { slug: 'react-server-components-explained', language: 'en', percent: 42, updatedAt: '2026-11-03T07:30:00Z' },
  { slug: 'aspnet-core-cheatsheet', language: 'en', percent: 18, updatedAt: '2026-11-01T21:10:00Z' },
];

/**
 * @param {{
 *   articles: any[], fields: any[], social: any, profiles: any, mediaUrl: (kind: string, seed: string, w: number, h: number) => string,
 *   problem: (status: number, code: string, title: string) => any,
 * }} deps
 */
export function createPaths({ articles, fields, social, profiles, mediaUrl, problem }) {
  const bySlug = new Map(articles.map((a) => [a.slug, a]));
  const byId = new Map(articles.map((a) => [a.id, a]));
  const fieldById = new Map(fields.map((f) => [f.id, f]));
  const states = new Map();

  const stateOf = (userId) => {
    if (!states.has(userId)) states.set(userId, seed(userId));
    return states.get(userId);
  };
  const lang = (req) => (/^ar/i.test(req.headers['accept-language'] ?? '') ? 'ar' : 'en');
  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const pathNotFound = () => [404, problem(404, 'path.not_found', 'Path not found')];
  const fieldRef = ({ id, slug, name, nameAr, nameEn, isSensitive }) => ({ id, slug, name, nameAr, nameEn, isSensitive });
  const itemsOf = (path) => path.slugs.map((slug) => bySlug.get(slug));

  function ref(article, position) {
    return { id: article.id, slug: article.slug, title: article.title, language: article.language, position, readingTimeMinutes: article.readingTimeMinutes };
  }

  /** `PathCardDto`: progress and enrollment are `subject`'s (the viewer, or the profile's owner on `/users/{u}/paths`). */
  function card(path, subject, uiLang) {
    const items = itemsOf(path);
    const state = subject ? stateOf(subject) : null;
    const readCount = state ? items.filter((a) => state.read.has(a.slug)).length : 0;
    const nextIndex = state ? items.findIndex((a) => !state.read.has(a.slug)) : -1;
    const enrollment = state?.enrolled.get(path.id) ?? null;
    return {
      id: path.id,
      slug: path.slug,
      title: uiLang === 'ar' ? path.titleAr : path.titleEn,
      description: uiLang === 'ar' ? path.descriptionAr : path.descriptionEn,
      field: fieldRef(fieldById.get(path.fieldId)),
      articleCount: items.length,
      readingTimeMinutes: items.reduce((total, a) => total + a.readingTimeMinutes, 0),
      coverUrl: path.cover ? mediaUrl('photo', `path-${path.slug}`, 800, 450) : null,
      progress: state
        ? { readCount, total: items.length, percent: Math.floor((readCount * 100) / items.length), next: nextIndex >= 0 ? ref(items[nextIndex], nextIndex + 1) : null }
        : null,
      enrollment: enrollment ? { enrolledAt: enrollment.enrolledAt, completedAt: enrollment.completedAt } : null,
    };
  }

  function details(path, viewer, uiLang) {
    const state = viewer ? stateOf(viewer) : null;
    return {
      ...card(path, viewer, uiLang),
      items: itemsOf(path).map((article, i) => ({ position: i + 1, article: social.personalize(article, viewer), isRead: !!state?.read.has(article.slug) })),
    };
  }

  const isDone = (path, userId) => itemsOf(path).every((a) => stateOf(userId).read.has(a.slug));

  /** Enrolled paths: in progress first (latest activity first), then completed (latest completion first). */
  function enrolledOf(userId, uiLang) {
    const state = stateOf(userId);
    const joined = PATHS.filter((p) => state.enrolled.has(p.id));
    const active = joined.filter((p) => !isDone(p, userId)).sort((a, b) => state.enrolled.get(b.id).activity.localeCompare(state.enrolled.get(a.id).activity));
    const done = joined
      .filter((p) => isDone(p, userId))
      .sort((a, b) => (state.enrolled.get(b.id).completedAt ?? '').localeCompare(state.enrolled.get(a.id).completedAt ?? ''));
    return [...active, ...done].map((p) => card(p, userId, uiLang));
  }

  /** The path shown under an article: the enrolled one with the latest activity, else the first in editorial order. */
  function articlePath(articleId, viewer, uiLang) {
    const article = byId.get(articleId);
    if (!article) return null;
    const containing = PATHS.filter((p) => p.slugs.includes(article.slug));
    if (!containing.length) return null;
    const state = viewer ? stateOf(viewer) : null;
    const enrolled = containing.filter((p) => state?.enrolled.has(p.id)).sort((a, b) => state.enrolled.get(b.id).activity.localeCompare(state.enrolled.get(a.id).activity));
    const path = enrolled[0] ?? containing[0];
    const items = itemsOf(path);
    const index = path.slugs.indexOf(article.slug);
    return {
      path: card(path, viewer, uiLang),
      position: index + 1,
      total: items.length,
      previous: index > 0 ? ref(items[index - 1], index) : null,
      next: index < items.length - 1 ? social.personalize(items[index + 1], viewer) : null,
    };
  }

  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = social.viewerOf(req);
      return viewer ? handler(viewer, q, match, req) : unauthorized();
    };

  const API = '/api/v1';
  const routes = [
    [
      'GET',
      new RegExp(`^${API}/paths$`),
      (q, _m, _body, req) => {
        const field = q.get('field');
        const viewer = social.viewerOf(req);
        return [200, PATHS.filter((p) => !field || fieldById.get(p.fieldId).slug === field).map((p) => card(p, viewer, lang(req)))];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/paths/([^/]+)$`),
      (_q, [, slug], _body, req) => {
        const path = PATHS.find((p) => p.slug === decodeURIComponent(slug));
        return path ? [200, details(path, social.viewerOf(req), lang(req))] : pathNotFound();
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/articles/([^/]+)/path$`),
      (_q, [, id], _body, req) => {
        const block = articlePath(decodeURIComponent(id), social.viewerOf(req), lang(req));
        return block ? [200, block] : [204, undefined];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/users/([^/]+)/paths$`),
      (_q, [, username], _body, req) => {
        const viewer = social.viewerOf(req);
        const record = profiles.lookup(username, viewer);
        if (!record) return [404, problem(404, 'user.not_found', 'User not found')];
        if (!profiles.statsVisible(record, viewer)) return [403, problem(403, 'profile.stats_private', 'These reading stats are private.')];
        return [200, enrolledOf(record.id, lang(req))];
      },
    ],
    ['GET', new RegExp(`^${API}/me/paths$`), signedIn((viewer, _q, _m, req) => [200, enrolledOf(viewer, lang(req))])],
    [
      'GET',
      new RegExp(`^${API}/me/paths/active$`),
      signedIn((viewer, _q, _m, req) => {
        const [first] = enrolledOf(viewer, lang(req));
        return first && first.progress.readCount < first.progress.total ? [200, first] : [204, undefined];
      }),
    ],
    [
      'PUT',
      new RegExp(`^${API}/me/paths/([^/]+)$`),
      signedIn((viewer, _q, [, id], req) => {
        const path = PATHS.find((p) => p.id === decodeURIComponent(id));
        if (!path) return pathNotFound();
        const state = stateOf(viewer);
        if (!state.enrolled.has(path.id)) state.enrolled.set(path.id, { enrolledAt: NOW, completedAt: isDone(path, viewer) ? NOW : null, activity: NOW });
        return [200, card(path, viewer, lang(req))];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/me/paths/([^/]+)$`),
      signedIn((viewer, _q, [, id]) => {
        stateOf(viewer).enrolled.delete(decodeURIComponent(id));
        return [204, undefined];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/me/continue-reading$`),
      signedIn((viewer, q) => {
        const limit = Math.min(10, Math.max(1, Number(q.get('limit') ?? 3) || 3));
        const list = viewer.startsWith('u-new') ? [] : CONTINUE;
        return [200, list.slice(0, limit).map((c) => ({ article: social.personalize(bySlug.get(c.slug), viewer), percent: c.percent, language: c.language, updatedAt: c.updatedAt }))];
      }),
    ],
  ];

  return { routes };
}
