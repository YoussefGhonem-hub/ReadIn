/**
 * Mute & feedback (F28) for the mock API, per docs/api/contract-v1.md "Mute & feedback": mute and unmute writers (a mute
 * ends your follow; `DELETE ?restoreFollow=true` follows again; following a muted writer ends the mute), mute fields and
 * topics, "Show less" marks, and `GET /me/mutes` for Settings → Muted. State is kept per signed-in viewer, like
 * social.mjs, so parallel tests never share it. The lists don't apply mutes here: the web removes the cards itself, and
 * the e2e tests route the flags (`isAuthorMuted`, `ProfileDto.isMuted`, `CommentDto.isAuthorMuted`) they need.
 */

const API = '/api/v1';
const MAX_MUTED_WRITERS = 500;
const SYSTEM_ACCOUNT = 'u-readin';

/**
 * @param {{
 *   social: any,
 *   writers: any[],
 *   fields: any[],
 *   topics: Record<string, any[]>,
 *   articles: () => any[],
 *   problem: (status: number, code: string, title: string) => any,
 * }} deps social.mjs (viewer, follows, summaries) and the fixtures.
 */
export function createMutes({ social, writers, fields, topics, articles, problem }) {
  const states = new Map();
  const people = () => new Map([...writers, ...social.readers].map((u) => [u.id, u]));
  const allTopics = () => Object.values(topics).flat();
  let clock = 0;

  function stateOf(viewer) {
    if (!states.has(viewer)) states.set(viewer, { users: new Map(), fields: new Map(), topics: new Map(), less: new Set() });
    return states.get(viewer);
  }

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const signedIn = (handler) => (q, match, body, req) => {
    const viewer = social.viewerOf(req);
    return viewer ? handler(viewer, stateOf(viewer), q, match, req) : unauthorized();
  };

  /** Runs social.mjs's own follow route, so its state and counts stay the one truth for follows. */
  function follow(req, method, id) {
    const path = `${API}/users/${encodeURIComponent(id)}/follow`;
    const route = social.routes.find(([m, pattern]) => m === method && pattern.test(path));
    return route[2](new URLSearchParams(), route[1].exec(path), null, req);
  }

  const contentDto = (state) => ({ fieldIds: [...state.fields.keys()], topicIds: [...state.topics.keys()] });
  const newestFirst = (map) => [...map.entries()].sort((a, b) => b[1] - a[1]).map(([id]) => id);
  const mutedField = ({ id, slug, name, nameAr, nameEn, icon, color }) => ({ id, slug, name, nameAr, nameEn, icon, color });

  const routes = [
    [
      'PUT',
      new RegExp(`^${API}/users/([^/]+)/mute$`),
      signedIn((viewer, state, _q, [, id], req) => {
        if (id === viewer) return [400, problem(400, 'mute.self', "You can't mute yourself.")];
        if (id === SYSTEM_ACCOUNT) return [400, problem(400, 'mute.system_account', "You can't mute the official ReadIn account.")];
        if (!people().has(id)) return [404, problem(404, 'user.not_found', 'User not found')];
        if (!state.users.has(id) && state.users.size >= MAX_MUTED_WRITERS) return [400, problem(400, 'mute.limit', 'Too many muted writers.')];
        const followRemoved = social.isFollowing(viewer, id);
        if (followRemoved) follow(req, 'DELETE', id);
        if (!state.users.has(id)) state.users.set(id, ++clock);
        return [200, { isMuted: true, isFollowing: false, followerCount: social.followerCount(id, viewer), followRemoved }];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/users/([^/]+)/mute$`),
      signedIn((viewer, state, q, [, id], req) => {
        if (!people().has(id)) return [404, problem(404, 'user.not_found', 'User not found')];
        state.users.delete(id);
        if (q.get('restoreFollow') === 'true') follow(req, 'PUT', id);
        return [200, { isMuted: false, isFollowing: social.isFollowing(viewer, id), followerCount: social.followerCount(id, viewer), followRemoved: false }];
      }),
    ],
    // Before social.mjs's own route: following a writer you muted ends the mute, then social.mjs follows.
    [
      'PUT',
      new RegExp(`^${API}/users/([^/]+)/follow$`),
      signedIn((_viewer, state, _q, [, id], req) => {
        const result = follow(req, 'PUT', id);
        if (result[0] === 200) state.users.delete(id);
        return result;
      }),
    ],
    ...['PUT', 'DELETE'].map((method) => [
      method,
      new RegExp(`^${API}/me/mutes/(fields|topics)/([^/]+)$`),
      signedIn((_viewer, state, _q, [, kind, id]) => {
        const list = kind === 'fields' ? state.fields : state.topics;
        if (method === 'PUT') {
          const known = kind === 'fields' ? fields.some((f) => f.id === id) : allTopics().some((t) => t.id === id);
          if (!known) return [404, problem(404, kind === 'fields' ? 'field.not_found' : 'topic.not_found', 'Not found')];
          if (!list.has(id)) list.set(id, ++clock);
        } else {
          list.delete(id);
        }
        return [200, contentDto(state)];
      }),
    ]),
    [
      'GET',
      new RegExp(`^${API}/me/mutes$`),
      signedIn((viewer, state) => {
        const users = newestFirst(state.users)
          .map((id) => people().get(id))
          .filter(Boolean)
          .map((user) => ({ ...social.summary(user, viewer), isFollowing: false }));
        const mutedFields = newestFirst(state.fields)
          .map((id) => fields.find((f) => f.id === id))
          .filter(Boolean)
          .map(mutedField);
        const mutedTopics = newestFirst(state.topics)
          .map((id) => allTopics().find((t) => t.id === id))
          .filter(Boolean)
          .map(({ id, slug, name, nameAr, nameEn, fieldId }) => ({ id, slug, name, nameAr, nameEn, field: mutedField(fields.find((f) => f.id === fieldId)) }));
        return [200, { users, fields: mutedFields, topics: mutedTopics }];
      }),
    ],
    [
      'PUT',
      new RegExp(`^${API}/articles/([^/]+)/show-less$`),
      signedIn((viewer, state, _q, [, id]) => {
        const article = articles().find((a) => a.id === id);
        if (!article) return [404, problem(404, 'article.not_found', 'Article not found')];
        if (article.author?.id === viewer) return [400, problem(400, 'mute.own_article', 'This is your own article.')];
        state.less.add(id);
        return [204, undefined];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/articles/([^/]+)/show-less$`),
      signedIn((_viewer, state, _q, [, id]) => {
        state.less.delete(id);
        return [204, undefined];
      }),
    ],
    // What a viewer marked "Show less", for the tests.
    ['GET', /^\/__mock\/show-less$/, (q) => [200, [...(states.get(q.get('viewer'))?.less ?? [])]]],
  ];

  return { routes };
}
