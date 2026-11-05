/**
 * Reposts (F29) for the mock API, per docs/api/contract-v1.md "Reposts": `PUT` / `DELETE /articles/{id}/repost`
 * (idempotent, `400 repost.own_article` on your own article, guests 401), `repostCount` and `isReposted` on every card
 * and article (wrapping social.mjs's `personalize`), and the Following feed with the articles the writers you follow
 * reposted, each once, placed at the later of its publish (when you follow its author) and the newest followed repost,
 * with `repostedBy` when a repost placed it.
 *
 * State is per signed-in viewer, like social.mjs. Readers' reposts give some articles a base count everyone sees. The
 * writers' own reposts (Karim and ReadIn) exist only for viewers whose id starts with `u-reposts`, so the Following feed
 * of every other spec stays as it was.
 */

const API = '/api/v1';

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

/** The viewers who live in the world with the writers' reposts. */
export const REPOST_VIEWER_PREFIX = 'u-reposts';

function page(items, q, map) {
  const offset = Number(q.get('cursor') ?? 0) || 0;
  const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
  const slice = items.slice(offset, offset + limit);
  return { items: slice.map(map), nextCursor: offset + limit < items.length ? String(offset + limit) : null };
}

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
  /** viewer → ids of the articles they reposted. */
  const mine = new Map();
  const personalizeBase = social.personalize;

  const writerReposts = (viewer) => (viewer?.startsWith(REPOST_VIEWER_PREFIX) ? WRITER_REPOSTS : []);
  const repostsOf = (viewer) => {
    if (!mine.has(viewer)) mine.set(viewer, new Set());
    return mine.get(viewer);
  };

  function stateOf(articleId, viewer) {
    const isReposted = !!viewer && repostsOf(viewer).has(articleId);
    const writers = writerReposts(viewer).filter((r) => r.articleId === articleId).length;
    return { repostCount: (BASE_COUNTS[articleId] ?? 0) + writers + (isReposted ? 1 : 0), isReposted };
  }

  /** social.mjs's `personalize` plus the repost fields (`repostedBy` stays what the list set, else null). */
  function personalize(dto, viewer) {
    const result = personalizeBase(dto, viewer);
    if (!byId.has(dto.id)) return result;
    return { ...result, ...stateOf(dto.id, viewer), repostedBy: dto.repostedBy ?? null };
  }

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const signedIn = (handler) => (q, match, body, req) => {
    const viewer = social.viewerOf(req);
    return viewer ? handler(viewer, q, match, body) : unauthorized();
  };

  const toggle = (on) =>
    signedIn((viewer, _q, [, id]) => {
      const article = byId.get(decodeURIComponent(id));
      if (!article) return [404, problem(404, 'article.not_found', 'Article not found')];
      if (on && article.author?.id === viewer) return [400, problem(400, 'repost.own_article', "You can't repost your own article.")];
      if (on) repostsOf(viewer).add(article.id);
      else repostsOf(viewer).delete(article.id);
      return [200, stateOf(article.id, viewer)];
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
        repostedBy: labeled ? { user: authorOf(reposters[0].userId), othersCount: reposters.length - 1, repostedAt: reposted } : null,
      });
    }
    items.sort((a, b) => b.feedAt.localeCompare(a.feedAt) || a.article.id.localeCompare(b.article.id));
    return [200, page(items, q, ({ article, repostedBy }) => personalize({ ...article, repostedBy }, viewer))];
  }

  const routes = [
    ['PUT', new RegExp(`^${API}/articles/([^/]+)/repost$`), toggle(true)],
    ['DELETE', new RegExp(`^${API}/articles/([^/]+)/repost$`), toggle(false)],
    ['GET', new RegExp(`^${API}/feed/following$`), signedIn((viewer, q) => following(viewer, q))],
  ];

  return { routes, personalize };
}
