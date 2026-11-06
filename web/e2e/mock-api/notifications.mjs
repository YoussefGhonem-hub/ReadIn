/**
 * The notification center and its settings (F17) for the mock API, per docs/handoff/f17-notifications.md: the list
 * (cursor pages, newest activity first), the unread badge's REST fallback, seen / read / read all, and the settings
 * with their validation.
 *
 * Viewers whose id starts with `u-notified` start with 25 notifications covering every type (aggregated followers and
 * comments, a mention in a comment and one in an article, a milestone, a followed writer's article, today's article, a
 * streak reminder, a security alert, a moderation warning, a reserved verification result, a deleted actor); 4 of them
 * are unseen (the badge) and 5 unread.
 * Viewers whose id starts with `u-notified-repost` also have two `article_reposted` entries (F29) on top: one reposter,
 * and one article five people reposted (aggregated); the other `u-notified` lists stay as they were.
 * Viewers whose id starts with `u-notified-readin` also have the official @readin account's day entries (leftovers 3):
 * today's with three articles (`data.articleCount: 3`, the profile link) and yesterday's with one.
 * Everyone else starts with none, so the badge of the other suites stays empty. State is per viewer, so parallel tests
 * never share it. The fixtures are relative to NOW (the tests fix the browser clock there): "today" is 2026-11-04 in
 * Africa/Cairo, the mock user's time zone.
 */

export const NOTIFICATIONS_NOW = '2026-11-04T10:00:00Z';
const CONFIGURABLE = ['new_follower', 'article_comment', 'comment_reply', 'mention', 'reactions_milestone', 'followed_writer_article', 'daily_article', 'streak_reminder', 'article_reposted'];
const MODES = ['all', 'inApp', 'off'];
const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;
const PAGE_LIMIT = 50;

const minutesBefore = (minutes) => new Date(Date.parse(NOTIFICATIONS_NOW) - minutes * 60_000).toISOString();

/**
 * @param {{ articles: any[], writers: any[], social: any, problem: (status: number, code: string, title: string) => any }} deps
 */
export function createNotifications({ articles, writers, social, problem }) {
  const people = new Map([...writers, ...social.readers].map((u) => [u.id, u]));
  const bySlug = new Map(articles.map((a) => [a.slug, a]));
  const states = new Map();

  const actor = (id) => {
    const { displayName, username, avatarUrl, isVerified } = people.get(id);
    return { id, displayName, username, avatarUrl, isVerified };
  };
  const article = (slug) => {
    const { id, title, language } = bySlug.get(slug);
    return { id, slug, title, language };
  };

  /** A notification as the API sends it, plus the mock's own `seen` flag. */
  function item(id, type, at, { actorId = null, actorCount = actorId ? 1 : 0, slug = null, comment = null, data = {}, link, isRead = true, seen = true }) {
    return {
      id,
      type,
      createdAt: at,
      updatedAt: at,
      isRead,
      actor: actorId ? actor(actorId) : null,
      actorCount,
      article: slug ? article(slug) : null,
      comment,
      data,
      link,
      seen,
    };
  }

  function seed(viewer) {
    if (!viewer.startsWith('u-notified')) return [];
    const me = 'sara';
    const fresh = { isRead: false, seen: false };
    const list = [
      // Today (Cairo): the four unseen ones (the badge) first.
      item('n-comments', 'article_comment', minutesBefore(20), {
        ...fresh,
        actorId: 'u-karim',
        actorCount: 10,
        slug: 'dependency-injection-ar',
        comment: { id: 'cm-scoped', parentId: null, excerpt: 'شرح ممتاز، بس ممكن مثال على Scoped vs Transient؟' },
        link: 'readin://a/dependency-injection-ar#comment-cm-scoped',
      }),
      item('n-mention', 'mention', minutesBefore(65), {
        ...fresh,
        actorId: 'u-salma',
        slug: 'sleep-and-memory',
        comment: { id: 'cm-question', parentId: null, excerpt: `@${me} the part about naps answers your question from yesterday.` },
        link: 'readin://a/sleep-and-memory#comment-cm-question',
      }),
      item('n-followers', 'new_follower', minutesBefore(130), { ...fresh, actorId: 'u-omar', actorCount: 3, link: `readin://u/${me}/followers` }),
      // A mention in an article (step 6.3): no comment, the article's link; the actor's name is Arabic.
      item('n-article-mention', 'mention', minutesBefore(180), {
        actorId: 'u-salma',
        slug: 'what-is-a-transformer-ar',
        link: 'readin://a/what-is-a-transformer-ar',
      }),
      item('n-daily', 'daily_article', minutesBefore(240), { ...fresh, slug: 'how-readin-picks-your-daily-article', link: 'readin://a/how-readin-picks-your-daily-article' }),
      // Its replier deleted their account: "Deleted user" (actor null, still one actor).
      item('n-reply', 'comment_reply', minutesBefore(300), {
        actorCount: 1,
        slug: 'what-is-a-transformer-ar',
        comment: { id: 'cm-agree', parentId: 'cm-mine', excerpt: 'متفق معاك جدًا، الـ attention هو كل الحكاية.' },
        link: 'readin://a/what-is-a-transformer-ar#comment-cm-agree',
      }),
      // Earlier.
      item('n-writer', 'followed_writer_article', '2026-11-03T15:00:00Z', {
        actorId: 'u-karim',
        slug: 'react-server-components-explained',
        link: 'readin://a/react-server-components-explained',
      }),
      item('n-milestone', 'reactions_milestone', '2026-11-03T12:00:00Z', {
        isRead: false,
        slug: 'dependency-injection-ar',
        data: { threshold: 50 },
        link: 'readin://a/dependency-injection-ar',
      }),
      item('n-streak', 'streak_reminder', '2026-11-02T18:00:00Z', { data: { streakDays: 6 }, link: 'readin://me/stats' }),
      item('n-security', 'security_alert', '2026-11-02T09:00:00Z', { data: { securityChange: 'passwordChanged' }, link: 'readin://settings/account' }),
      item('n-warning', 'moderation_notice', '2026-11-01T10:00:00Z', { link: 'readin://notifications' }),
      item('n-verification', 'verification_result', '2026-10-31T10:00:00Z', { link: 'readin://notifications' }),
    ];
    // F29: reposts of your articles (only for the repost suite's readers).
    if (viewer.startsWith('u-notified-repost')) {
      list.unshift(
        item('n-repost', 'article_reposted', minutesBefore(5), { ...fresh, actorId: 'u-karim', slug: 'dependency-injection-ar', link: 'readin://a/dependency-injection-ar' }),
        item('n-reposts', 'article_reposted', minutesBefore(10), {
          ...fresh,
          actorId: 'u-salma',
          actorCount: 5,
          slug: 'clean-architecture-whiteboard',
          link: 'readin://a/clean-architecture-whiteboard',
        }),
      );
    }
    // Leftovers 3: the official @readin account gives one entry per day, `data.articleCount` its new articles that day,
    // `article` the newest, and with 2 or more the account's profile as `link` (only for that suite's readers).
    if (viewer.startsWith('u-notified-readin')) {
      list.unshift(
        item('n-readin-day', 'followed_writer_article', minutesBefore(8), {
          ...fresh,
          actorId: 'u-readin',
          slug: 'readin-streaks-ar',
          data: { articleCount: 3 },
          link: 'readin://u/readin',
        }),
        item('n-readin-one', 'followed_writer_article', '2026-11-03T16:00:00Z', {
          actorId: 'u-readin',
          slug: 'how-readin-picks-your-daily-article',
          data: { articleCount: 1 },
          link: 'readin://a/how-readin-picks-your-daily-article',
        }),
      );
    }
    // Older ones, so the list has a second page.
    for (let i = 1; i <= 13; i++) {
      const at = new Date(Date.parse('2026-10-30T12:00:00Z') - i * 86_400_000).toISOString();
      const reader = `u-reader-${String(i + 10).padStart(2, '0')}`;
      list.push(
        i % 2
          ? item(`n-old-${i}`, 'new_follower', at, { actorId: reader, link: `readin://u/${people.get(reader).username}` })
          : item(`n-old-${i}`, 'article_comment', at, {
              actorId: reader,
              slug: 'clean-architecture-whiteboard',
              comment: { id: `cm-old-${i}`, parentId: null, excerpt: `Comment number ${i} on the whiteboard post.` },
              link: `readin://a/clean-architecture-whiteboard#comment-cm-old-${i}`,
            }),
      );
    }
    return list;
  }

  const defaultSettings = () => ({
    quietHours: { enabled: true, start: '23:00', end: '07:00' },
    types: Object.fromEntries(CONFIGURABLE.map((type) => [type, 'all'])),
  });

  function stateOf(viewer) {
    if (!states.has(viewer)) states.set(viewer, { items: seed(viewer), settings: defaultSettings(), puts: [] });
    return states.get(viewer);
  }

  const dto = ({ seen: _seen, ...rest }) => rest;
  const sorted = (items) => [...items].sort((a, b) => b.updatedAt.localeCompare(a.updatedAt) || b.id.localeCompare(a.id));
  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const invalid = (code, title) => [400, problem(400, code, title)];

  /** Wraps a handler that needs a signed-in viewer. */
  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = social.viewerOf(req);
      return viewer ? handler(stateOf(viewer), q, match, body) : unauthorized();
    };

  function validate(body) {
    const quiet = body?.quietHours;
    if (!quiet || typeof quiet.enabled !== 'boolean' || !TIME.test(quiet.start ?? '') || !TIME.test(quiet.end ?? '') || quiet.start === quiet.end) {
      return invalid('notification.quiet_hours_invalid', 'Quiet hours need a start and an end (HH:mm) that are different.');
    }
    for (const [type, mode] of Object.entries(body.types ?? {})) {
      if (!CONFIGURABLE.includes(type)) return invalid('notification.type_invalid', `Unknown notification type: ${type}`);
      if (!MODES.includes(mode)) return invalid('notification.mode_invalid', `Unknown mode: ${mode}`);
    }
    return null;
  }

  const routes = [
    [
      'GET',
      /^\/api\/v1\/me\/notifications$/,
      signedIn((state, q) => {
        const offset = Math.max(0, Number(q.get('cursor') ?? 0) || 0);
        const limit = Math.min(PAGE_LIMIT, Math.max(1, Number(q.get('limit') ?? 20) || 20));
        const all = sorted(state.items);
        const items = all.slice(offset, offset + limit).map(dto);
        return [200, { items, nextCursor: offset + limit < all.length ? String(offset + limit) : null }];
      }),
    ],
    ['GET', /^\/api\/v1\/me\/notifications\/unread-count$/, signedIn((state) => [200, { unread: state.items.filter((n) => !n.seen).length }])],
    [
      'POST',
      /^\/api\/v1\/me\/notifications\/seen$/,
      signedIn((state) => {
        state.items.forEach((n) => (n.seen = true));
        return [204, undefined];
      }),
    ],
    [
      'POST',
      /^\/api\/v1\/me\/notifications\/read-all$/,
      signedIn((state) => {
        state.items.forEach((n) => Object.assign(n, { isRead: true, seen: true }));
        return [204, undefined];
      }),
    ],
    [
      'POST',
      /^\/api\/v1\/me\/notifications\/([^/]+)\/read$/,
      signedIn((state, _q, [, id]) => {
        const found = state.items.find((n) => n.id === decodeURIComponent(id));
        if (!found) return [404, problem(404, 'notification.not_found', 'This notification no longer exists.')];
        Object.assign(found, { isRead: true, seen: true });
        return [204, undefined];
      }),
    ],
    ['GET', /^\/api\/v1\/me\/notification-settings$/, signedIn((state) => [200, state.settings])],
    [
      'PUT',
      /^\/api\/v1\/me\/notification-settings$/,
      signedIn((state, _q, _m, body) => {
        state.puts.push(body);
        const error = validate(body);
        if (error) return error;
        state.settings = { quietHours: { ...body.quietHours }, types: { ...state.settings.types, ...body.types } };
        return [204, undefined];
      }),
    ],
    // For the tests: what the viewer's notifications and settings look like now, and every PUT body they sent.
    [
      'GET',
      /^\/__mock\/notifications$/,
      (q) => {
        const state = stateOf(q.get('viewer') ?? '');
        return [200, { read: state.items.filter((n) => n.isRead).map((n) => n.id), unseen: state.items.filter((n) => !n.seen).length, settings: state.settings, puts: state.puts }];
      },
    ],
  ];

  return { routes };
}
