/**
 * Reposts (F29) for the mock API, per docs/api/contract-v1.md "Reposts": `PUT` / `GET` / `DELETE /articles/{id}/repost`
 * (idempotent, `400 repost.own_article` on your own article, guests 401), `repostCount` and `isReposted` on every card
 * and article (wrapping social.mjs's `personalize`), and the Following feed with the articles the writers you follow
 * reposted, each once, placed at the later of its publish (when you follow its author) and the newest followed repost,
 * with `repostedBy` when a repost placed it.
 *
 * Captions ("repost with your thoughts"): `PUT` takes an optional `{ caption }` (missing or null: none on a new repost,
 * unchanged on an existing one; "" clears it; trimmed, `\r\n` → `\n`, more than 500 characters →
 * `400 validation.failed` with `caption: ["repost.caption_too_long"]`), `GET` answers your repost with its caption, and
 * every `repostedBy` label carries its user's caption (`WRITER_CAPTIONS` for the writers, also on profiles.mjs's
 * Reposts tab).
 *
 * State is per signed-in viewer, like social.mjs. Readers' reposts give some articles a base count everyone sees. The
 * writers' own reposts (Karim and ReadIn) exist only for viewers whose id starts with `u-reposts`, so the Following feed
 * of every other spec stays as it was.
 */

const API = '/api/v1';
const CAPTION_MAX = 500;

/** Reposts by readers nobody follows: only the counts. */
const BASE_COUNTS = {
  'a-clean-architecture-whiteboard': 2,
  'a-dependency-injection-ar': 4,
  'a-aspnet-core-cheatsheet': 11,
  'a-how-readin-picks-your-daily-article': 7,
  'a-what-is-a-transformer-ar': 3,
};

/** Reposts by writers people follow (ReadIn and Karim), for `u-reposts…` viewers only. */
const WRITER_REPOSTS = [
  { userId: 'u-karim', articleId: 'a-sleep-and-memory', at: '2026-11-03T12:00:00Z' },
  { userId: 'u-readin', articleId: 'a-sleep-and-memory', at: '2026-11-03T08:00:00Z' },
  { userId: 'u-readin', articleId: 'a-react-server-components-explained', at: '2026-11-03T10:00:00Z' },
  { userId: 'u-karim', articleId: 'a-what-is-a-transformer-ar', at: '2026-11-02T20:00:00Z' },
];

/**
 * The writers' thoughts on their reposts (`userId:articleId`), on the Following feed's labels and the Reposts tab:
 * Karim's in Arabic on two lines, ReadIn's in English and long enough to be cut at 4 lines. The others have none.
 */
const WRITER_CAPTIONS = {
  'u-karim:a-sleep-and-memory': 'أحسن مقال قريته عن النوم السنة دي.\nالجزء بتاع الـ REM sleep لوحده يستاهل القراية.',
  'u-readin:a-react-server-components-explained':
    'Server Components finally explained without the hype. It walks through what runs on the server, what ships to the browser and why the boundary matters for your bundle, with small examples you can try today. If you build with React or Next.js, read the part about data fetching twice: it changes how you think about loading states, caching and the waterfalls you never noticed in your own app.',
};

/** The viewers who live in the world with the writers' reposts. */
export const REPOST_VIEWER_PREFIX = 'u-reposts';

function page(items, q, map) {
  const offset = Number(q.get('cursor') ?? 0) || 0;
  const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
  const slice = items.slice(offset, offset + limit);
  return { items: slice.map(map), nextCursor: offset + limit < items.length ? String(offset + limit) : null };
}

/** The contract's caption rules: trimmed, `\r\n` → `\n`, empty → null. */
const normalizeCaption = (caption) => caption.replace(/\r\n/g, '\n').trim() || null;

/**
 * @param {{
 *   articles: any[],
 *   writers: any[],
 *   social: any,
 *   authorOf: (id: string) => any,
 *   problem: (status: number, code: string, title: string) => any,
 * }} deps every published card (guest values), the writers, social.mjs (viewer, follows, personalize) and AuthorDto.
 */
export function createReposts({ articles, social, authorOf, problem }) {
  const byId = new Map(articles.map((a) => [a.id, a]));
  /** viewer → the articles they reposted → their caption (or null). */
  const mine = new Map();
  const personalizeBase = social.personalize;

  const writerReposts = (viewer) => (viewer?.startsWith(REPOST_VIEWER_PREFIX) ? WRITER_REPOSTS : []);
  const repostsOf = (viewer) => {
    if (!mine.has(viewer)) mine.set(viewer, new Map());
    return mine.get(viewer);
  };

  function stateOf(articleId, viewer) {
    const reposts = viewer ? repostsOf(viewer) : new Map();
    const isReposted = reposts.has(articleId);
    const writers = writerReposts(viewer).filter((r) => r.articleId === articleId).length;
    return { repostCount: (BASE_COUNTS[articleId] ?? 0) + writers + (isReposted ? 1 : 0), isReposted, caption: reposts.get(articleId) ?? null };
  }

  /** `userId`'s thoughts on their repost of `articleId`: a writer's from the fixtures, or the viewer's own. */
  function captionOf(userId, articleId) {
    if (Object.hasOwn(WRITER_CAPTIONS, `${userId}:${articleId}`)) return WRITER_CAPTIONS[`${userId}:${articleId}`];
    return mine.get(userId)?.get(articleId) ?? null;
  }

  /** social.mjs's `personalize` plus the repost fields (`repostedBy` stays what the list set, else null; with its caption). */
  function personalize(dto, viewer) {
    const result = personalizeBase(dto, viewer);
    if (!byId.has(dto.id)) return result;
    const label = dto.repostedBy ?? null;
    const repostedBy = label && label.caption === undefined ? { ...label, caption: captionOf(label.user.id, dto.id) } : label;
    const { repostCount, isReposted } = stateOf(dto.id, viewer);
    return { ...result, repostCount, isReposted, repostedBy };
  }

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const signedIn = (handler) => (q, match, body, req) => {
    const viewer = social.viewerOf(req);
    return viewer ? handler(viewer, q, match, body) : unauthorized();
  };
  const notFound = () => [404, problem(404, 'article.not_found', 'Article not found')];
  const tooLong = () => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { caption: ['repost.caption_too_long'] } }];

  /** `PUT`: reposts, or only sets the caption when you already reposted (the count doesn't move). */
  const repost = signedIn((viewer, _q, [, id], body) => {
    const article = byId.get(decodeURIComponent(id));
    if (!article) return notFound();
    if (article.author?.id === viewer) return [400, problem(400, 'repost.own_article', "You can't repost your own article.")];
    const sent = body && typeof body === 'object' && typeof body.caption === 'string' ? normalizeCaption(body.caption) : undefined;
    if (sent && sent.length > CAPTION_MAX) return tooLong();
    const reposts = repostsOf(viewer);
    if (sent !== undefined) reposts.set(article.id, sent);
    else if (!reposts.has(article.id)) reposts.set(article.id, null);
    return [200, stateOf(article.id, viewer)];
  });

  const unrepost = signedIn((viewer, _q, [, id]) => {
    const article = byId.get(decodeURIComponent(id));
    if (!article) return notFound();
    repostsOf(viewer).delete(article.id);
    return [200, stateOf(article.id, viewer)];
  });

  /** `GET`: your repost of it now, with its caption (prefills "عدّل رأيك"). */
  const current = signedIn((viewer, _q, [, id]) => {
    const article = byId.get(decodeURIComponent(id));
    return article ? [200, stateOf(article.id, viewer)] : notFound();
  });

  /** The Following feed (contract "Reposts → The Following feed"); before social.mjs's own route. */
  function following(viewer, q) {
    const follows = (id) => social.isFollowing(viewer, id);
    const items = [];
    for (const article of articles) {
      if (article.author?.id === viewer) continue;
      const published = article.author && follows(article.author.id) ? article.publishedAt : null;
      const reposters = writerReposts(viewer)
        .filter((r) => r.articleId === article.id && follows(r.userId))
        .sort((a, b) => b.at.localeCompare(a.at));
      const reposted = reposters[0]?.at ?? null;
      if (!published && !reposted) continue;
      const labeled = !!reposted && (!published || reposted > published);
      items.push({
        article,
        feedAt: labeled ? reposted : published,
        // The newest followed reposter's thoughts; the others' aren't shown.
        repostedBy: labeled
          ? { user: authorOf(reposters[0].userId), othersCount: reposters.length - 1, repostedAt: reposted, caption: captionOf(reposters[0].userId, article.id) }
          : null,
      });
    }
    items.sort((a, b) => b.feedAt.localeCompare(a.feedAt) || a.article.id.localeCompare(b.article.id));
    return [200, page(items, q, ({ article, repostedBy }) => personalize({ ...article, repostedBy }, viewer))];
  }

  const routes = [
    ['PUT', new RegExp(`^${API}/articles/([^/]+)/repost$`), repost],
    ['GET', new RegExp(`^${API}/articles/([^/]+)/repost$`), current],
    ['DELETE', new RegExp(`^${API}/articles/([^/]+)/repost$`), unrepost],
    ['GET', new RegExp(`^${API}/feed/following$`), signedIn((viewer, q) => following(viewer, q))],
  ];

  return { routes, personalize };
}
