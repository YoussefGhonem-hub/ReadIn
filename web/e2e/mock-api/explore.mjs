/**
 * Explore and field pages (F15) for the mock API, following docs/api/contract-v1.md → Explore and field pages:
 * `GET /explore` (every section), the two rankings in full (`/explore/trending`, `/explore/most-saved`, offset cursor
 * pages of cards), and a field's header with its topics, its articles (newest first, `?topic=`) and its top writers.
 * Cards are personalized like every feed (your reactions and saves); writers and paths carry your follows and
 * progress. Following a field or a topic goes through the F12 interests endpoints (social.mjs), so the header's
 * `isFollowing` and `followerCount` follow them.
 *
 * The mock has no reading history: "this week" is the fixed {@link THIS_WEEK} activity, and articles without any
 * follow newest first (the API's fallback is the quality score).
 */

const API = '/api/v1';
const RANKING_MAX = 100;

/** A field only Explore knows (no article, no topic): an empty field page (`noindex`). Not in `GET /fields`, so Home's chips don't change. */
const DESIGN = { id: 'f-design', slug: 'design', name: 'Design', nameAr: 'التصميم', nameEn: 'Design', icon: 'palette', color: 'accent', isSensitive: false };

/** Followers of each field besides the viewer (the viewer's own follow adds 1). */
const FOLLOWERS = { software: 86, medicine: 12, design: 0 };

/** The articles of each topic (the search mock counts them the same: `.NET` 2, Architecture 1). */
const TOPIC_ARTICLES = {
  dotnet: ['dependency-injection-ar', 'aspnet-core-cheatsheet'],
  architecture: ['clean-architecture-whiteboard'],
};

/** Completed reads, reactions, comments and saves in the last 7 days, not by the authors. */
const THIS_WEEK = {
  'dependency-injection-ar': [40, 12, 5, 6],
  'readin-streaks-ar': [25, 8, 2, 4],
  'one-photo': [18, 9, 1, 1],
  'sql-indexes-in-plain-words': [12, 4, 2, 3],
  'react-server-components-explained': [10, 3, 1, 2],
};

/** "Top writers in this field", best first. */
const TOP_WRITERS = { software: ['u-writer', 'u-karim', 'u-salma'], medicine: ['u-omar'], design: [] };
/** First article in the last 30 days, latest first. */
const NEW_WRITERS = ['u-omar', 'u-salma', 'u-karim'];

const engagement = (slug) => {
  const [reads, reactions, comments, saves] = THIS_WEEK[slug] ?? [0, 0, 0, 0];
  return reads + 2 * reactions + 4 * comments + 6 * saves;
};
const newestFirst = (a, b) => b.publishedAt.localeCompare(a.publishedAt) || b.id.localeCompare(a.id);

/**
 * @param {{ articles: () => any[], fields: any[], topics: Record<string, any[]>, writers: any[], social: any,
 *   paths: any, problem: Function }} deps `articles`: every published card (guest values).
 */
export function createExplore({ articles, fields, topics, writers, social, paths, problem }) {
  const allFields = [...fields, DESIGN];
  const people = new Map(writers.map((w) => [w.id, w]));
  const fieldNotFound = () => [404, problem(404, 'field.not_found', "This field doesn't exist.")];
  const topicNotFound = () => [404, problem(404, 'topic.not_found', 'Topic not found.')];
  const fieldOf = (slug) => allFields.find((f) => f.slug === decodeURIComponent(slug).toLowerCase()) ?? null;
  const topicsOf = (field) => topics[field.slug] ?? [];
  const inField = (field) => articles().filter((a) => a.field.slug === field.slug);
  const inTopic = (topic) => articles().filter((a) => (TOPIC_ARTICLES[topic.slug] ?? []).includes(a.slug));

  const rankings = {
    trending: () => [...articles()].sort((a, b) => engagement(b.slug) - engagement(a.slug) || newestFirst(a, b)).slice(0, RANKING_MAX),
    'most-saved': () =>
      articles()
        .filter((a) => a.saveCount > 0)
        .sort((a, b) => b.saveCount - a.saveCount || newestFirst(a, b))
        .slice(0, RANKING_MAX),
  };

  function page(items, q, viewer) {
    const offset = Number(q.get('cursor') ?? 0) || 0;
    const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
    return {
      items: items.slice(offset, offset + limit).map((a) => social.personalize(a, viewer)),
      nextCursor: offset + limit < items.length ? String(offset + limit) : null,
    };
  }

  const summaries = (ids, viewer) => ids.map((id) => people.get(id)).filter(Boolean).map((u) => social.summary(u, viewer));

  function fieldPage(field, viewer) {
    const interests = viewer ? social.interestsOf(viewer) : { fieldIds: [], topicIds: [] };
    const isFollowing = interests.fieldIds.includes(field.id);
    const { id, slug, name, nameAr, nameEn, icon, color, isSensitive } = field;
    return {
      id,
      slug,
      name,
      nameAr,
      nameEn,
      icon,
      color,
      isSensitive,
      articleCount: inField(field).length,
      followerCount: (FOLLOWERS[slug] ?? 0) + (isFollowing ? 1 : 0),
      isFollowing,
      topics: topicsOf(field).map((t) => ({
        id: t.id,
        slug: t.slug,
        name: t.name,
        nameAr: t.nameAr,
        nameEn: t.nameEn,
        articleCount: inTopic(t).length,
        isFollowing: interests.topicIds.includes(t.id),
      })),
    };
  }

  const routes = [
    [
      'GET',
      new RegExp(`^${API}/explore$`),
      (_q, _m, _body, req) => {
        const viewer = social.viewerOf(req);
        return [
          200,
          {
            fields: allFields.map(({ id, slug, name, nameAr, nameEn, icon, color }) => ({ id, slug, name, nameAr, nameEn, icon, color, articleCount: inField({ slug }).length })),
            trending: rankings.trending().slice(0, 6).map((a) => social.personalize(a, viewer)),
            mostSaved: rankings['most-saved']().slice(0, 6).map((a) => social.personalize(a, viewer)),
            newWriters: summaries(NEW_WRITERS, viewer),
            featuredPaths: paths.featured(req),
          },
        ];
      },
    ],
    ['GET', new RegExp(`^${API}/explore/(trending|most-saved)$`), (q, [, ranking], _body, req) => [200, page(rankings[ranking](), q, social.viewerOf(req))]],
    [
      'GET',
      new RegExp(`^${API}/fields/([^/]+)$`),
      (_q, [, slug], _body, req) => {
        const field = fieldOf(slug);
        return field ? [200, fieldPage(field, social.viewerOf(req))] : fieldNotFound();
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/fields/([^/]+)/articles$`),
      (q, [, slug], _body, req) => {
        const field = fieldOf(slug);
        if (!field) return fieldNotFound();
        const topicSlug = (q.get('topic') ?? '').trim().toLowerCase();
        let items = inField(field);
        if (topicSlug) {
          const topic = topicsOf(field).find((t) => t.slug === topicSlug);
          if (!topic) return topicNotFound();
          items = inTopic(topic);
        }
        return [200, page(items.sort(newestFirst), q, social.viewerOf(req))];
      },
    ],
    [
      'GET',
      new RegExp(`^${API}/fields/([^/]+)/writers$`),
      (q, [, slug], _body, req) => {
        const field = fieldOf(slug);
        if (!field) return fieldNotFound();
        const limit = Math.min(10, Math.max(1, Number(q.get('limit') ?? 10) || 10));
        return [200, summaries(TOP_WRITERS[field.slug] ?? [], social.viewerOf(req)).slice(0, limit)];
      },
    ],
  ];

  return { routes };
}
