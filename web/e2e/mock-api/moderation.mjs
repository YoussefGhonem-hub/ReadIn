/**
 * Reporting and moderation (F22) for the mock API, per the F22 contract: `POST /reports`, the moderation queue, cases,
 * actions and log, `GET /moderation/summary`, the affected user's notices, and the comments of one article (so a
 * comment can be reported from the reader).
 *
 * Moderators are viewers whose id starts with `u-mod` (e2e/support/moderation.ts signs in as one). Each moderator
 * works on their own copy of the seeded cases (3 + 1 open, 1 resolved, 1 dismissed), so parallel tests never see each
 * other's actions; an article a moderator hides is hidden (with the banner) for that moderator only. Viewers whose id
 * starts with `u-warned` start with two unacknowledged notices (a warning and a hidden article).
 *
 * A user case lists that user's writer categories (F31, from categories.mjs); `clear_category` renames one to "قسم {n}"
 * with a new slug, for that moderator only (like their other actions).
 */

const REASONS = ['spam', 'misinformation', 'harassment', 'copyright', 'other'];
const TYPES = ['article', 'comment', 'user'];
const ALLOWED = {
  comment: ['hide', 'unhide', 'delete', 'dismiss'],
  article: ['hide', 'unhide', 'dismiss'],
  user: ['warn', 'suspend', 'unsuspend', 'clear_category', 'dismiss'],
};
const NOW = '2026-11-03T09:00:00Z';
const SEED_MODERATOR = { id: 'u-mod-seed', displayName: 'Nour Fawzy', username: 'nour_mod', avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false };

/** The comments the mock knows: three under "How sleep turns reading into memory", one hidden under the transformer article. */
const COMMENTS = [
  { id: 'cm-question', articleId: 'a-sleep-and-memory', author: 'u-reader-04', body: 'Does this apply to short naps too, or only to a full night?', createdAt: '2026-11-02T20:00:00Z' },
  { id: 'cm-thanks', articleId: 'a-sleep-and-memory', author: 'u-reader-11', body: 'مقال جميل، شكرًا يا دكتور. هجرّب أقرا قبل النوم.', createdAt: '2026-11-02T22:30:00Z' },
  { id: 'cm-spam', articleId: 'a-sleep-and-memory', author: 'u-reader-30', body: 'Great read! Get 90% off every course at cheap-courses.example 👉 link in my bio', createdAt: '2026-11-03T05:10:00Z' },
  { id: 'cm-rude', articleId: 'a-what-is-a-transformer-ar', author: 'u-reader-17', body: 'إنت مش فاهم حاجة خالص، بطّل تكتب.', createdAt: '2026-10-30T09:00:00Z' },
];
/** The article whose comments the mock serves (others keep answering 404, as before F22). */
const COMMENTED_ARTICLE = 'a-sleep-and-memory';

const report = (id, reporter, reason, details, createdAt, closed = null) => ({ id, reporter, reason, details, createdAt, status: closed?.status ?? 'open', closedAt: closed?.at ?? null, closedBy: closed ? 'seed' : null });

/** A fresh copy of the seeded cases for one moderator. */
function seedCases() {
  return [
    {
      targetType: 'article',
      targetId: 'a-sleep-and-memory',
      state: 'visible',
      reports: [
        report('r-1', 'u-reader-03', 'misinformation', 'The study it cites found the opposite for adults over 60.', '2026-11-03T07:40:00Z'),
        report('r-2', 'u-reader-08', 'misinformation', null, '2026-11-02T21:10:00Z'),
        report('r-3', 'u-reader-12', 'other', 'العنوان مبالغ فيه شوية.', '2026-11-02T18:00:00Z'),
      ],
    },
    {
      targetType: 'comment',
      targetId: 'cm-spam',
      state: 'visible',
      reports: [
        report('r-4', 'u-reader-05', 'spam', 'Same link under every article this week.', '2026-11-03T08:20:00Z'),
        report('r-5', 'u-reader-14', 'spam', null, '2026-11-03T06:00:00Z'),
      ],
    },
    {
      targetType: 'user',
      targetId: 'u-reader-21',
      state: 'active',
      warningCount: 1,
      reports: [report('r-6', 'u-reader-09', 'harassment', 'بيرد بشتايم على كل تعليقاتي.', '2026-11-02T16:30:00Z')],
    },
    {
      targetType: 'article',
      targetId: 'a-readin-streaks-ar',
      state: 'visible',
      reports: [report('r-7', 'u-reader-15', 'spam', null, '2026-11-01T12:00:00Z')],
    },
    {
      targetType: 'comment',
      targetId: 'cm-rude',
      state: 'hidden',
      reports: [report('r-8', 'u-reader-02', 'harassment', null, '2026-10-30T10:00:00Z', { status: 'resolved', at: '2026-10-31T09:00:00Z' })],
    },
    {
      targetType: 'article',
      targetId: 'a-how-readin-picks-your-daily-article',
      state: 'visible',
      reports: [report('r-9', 'u-reader-06', 'copyright', 'Looks copied from a blog post.', '2026-10-29T12:00:00Z', { status: 'dismissed', at: '2026-10-30T08:00:00Z' })],
    },
  ];
}

function seedLog() {
  return [
    { id: 'log-2', action: 'comment.hide', targetType: 'comment', targetId: 'cm-rude', note: 'Insults another reader.', suspendedUntil: null, reportsClosed: 1, createdAt: '2026-10-31T09:00:00Z', moderator: SEED_MODERATOR },
    {
      id: 'log-1',
      action: 'reports.dismiss',
      targetType: 'article',
      targetId: 'a-how-readin-picks-your-daily-article',
      note: 'Original content by the ReadIn team.',
      suspendedUntil: null,
      reportsClosed: 1,
      createdAt: '2026-10-30T08:00:00Z',
      moderator: SEED_MODERATOR,
    },
  ];
}

/** A name `clear_category` gives (or leaves alone): "قسم {n}" / "Category {n}". */
const PLACEHOLDER = /^(قسم|Category) (\d+)$/;

/**
 * @param {{ articles: any[], writers: any[], social: any, problem: (status: number, code: string, title: string) => any,
 *   categoriesOf: (userId: string) => any[] }} deps
 */
export function createModeration({ articles, writers, social, problem, categoriesOf }) {
  const articleById = new Map(articles.map((a) => [a.id, a]));
  const people = new Map([...writers, ...social.readers].map((u) => [u.id, u]));
  const commentById = new Map(COMMENTS.map((c) => [c.id, c]));
  const moderators = new Map();
  const notices = new Map();
  /** Reports readers sent (`viewer|type|id`), for the tests. */
  const reports = new Map();
  let nextId = 1;

  const isModerator = (viewer) => !!viewer && viewer.startsWith('u-mod');
  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const forbidden = () => [403, problem(403, 'auth.forbidden', 'You are not allowed to do this.')];
  const validation = (field, code) => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { [field]: [code] } }];

  const author = (id) => {
    const user = people.get(id);
    return user ? { id, displayName: user.displayName, username: user.username, avatarUrl: user.avatarUrl ?? null, isVerified: !!user.isVerified } : null;
  };
  const summaryOf = (id, viewer) => {
    if (id === 'seed') return SEED_MODERATOR;
    if (id === viewer && isModerator(viewer)) return { id, displayName: 'Hana Gamal', username: 'hana_mod', avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false };
    const user = people.get(id);
    return user ? { ...author(id), bio: user.bio ?? null, isFollowing: false, followsYou: false } : null;
  };

  function stateOf(viewer) {
    if (!moderators.has(viewer)) moderators.set(viewer, { cases: new Map(seedCases().map((c) => [`${c.targetType}:${c.targetId}`, c])), log: seedLog(), cleared: new Map() });
    return moderators.get(viewer);
  }

  /** The case of a target, created on first action (an article hidden from the reader has no reports). */
  function caseOf(state, targetType, targetId) {
    const key = `${targetType}:${targetId}`;
    if (!state.cases.has(key)) {
      const initial = targetType === 'user' ? 'active' : 'visible';
      state.cases.set(key, { targetType, targetId, state: initial, reports: [], warningCount: 0 });
    }
    return state.cases.get(key);
  }

  function exists(targetType, targetId) {
    if (targetType === 'article') return articleById.has(targetId);
    if (targetType === 'comment') return commentById.has(targetId);
    return people.has(targetId) || targetId.startsWith('u-');
  }

  function ownerOf(targetType, targetId) {
    if (targetType === 'article') return articleById.get(targetId)?.author.id ?? null;
    if (targetType === 'comment') return commentById.get(targetId)?.author ?? null;
    return targetId;
  }

  /** Like the API: every field is there, and the ones that don't apply to the target type are null. */
  function targetDto(c) {
    const empty = { title: null, slug: null, language: null, body: null, articleId: null, articleSlug: null, articleTitle: null, suspendedUntil: null, warningCount: null };
    if (c.targetType === 'article') {
      const a = articleById.get(c.targetId);
      return { ...empty, state: c.state, author: a ? (author(a.author.id) ?? a.author) : null, title: a?.title ?? null, slug: a?.slug ?? null, language: a?.language ?? null };
    }
    if (c.targetType === 'comment') {
      const comment = commentById.get(c.targetId);
      const a = articleById.get(comment?.articleId);
      return {
        ...empty,
        state: c.state,
        author: author(comment?.author),
        body: comment?.body ?? null,
        articleId: a?.id ?? null,
        articleSlug: a?.slug ?? null,
        articleTitle: a?.title ?? null,
      };
    }
    return { ...empty, state: c.state, author: author(c.targetId), suspendedUntil: c.state === 'suspended' ? (c.suspendedUntil ?? null) : null, warningCount: c.warningCount ?? 0 };
  }

  function itemOf(c, status) {
    const inStatus = c.reports.filter((r) => r.status === status);
    if (!inStatus.length) return null;
    const reasons = {};
    for (const r of inStatus) reasons[r.reason] = (reasons[r.reason] ?? 0) + 1;
    const times = inStatus.map((r) => r.createdAt).sort();
    const closed = inStatus.map((r) => r.closedAt).filter(Boolean).sort();
    return {
      targetType: c.targetType,
      targetId: c.targetId,
      status,
      reportCount: inStatus.length,
      reasons,
      firstReportedAt: times[0],
      lastReportedAt: times[times.length - 1],
      closedAt: status === 'open' ? null : (closed[closed.length - 1] ?? null),
      target: targetDto(c),
    };
  }

  function caseStatus(c) {
    if (c.reports.some((r) => r.status === 'open')) return 'open';
    const latest = [...c.reports].filter((r) => r.closedAt).sort((a, b) => b.closedAt.localeCompare(a.closedAt))[0];
    return latest?.status ?? null;
  }

  function labelOf(c) {
    if (c.targetType === 'article') return articleById.get(c.targetId)?.title ?? null;
    if (c.targetType === 'comment') return commentById.get(c.targetId)?.body.slice(0, 80) ?? null;
    const user = people.get(c.targetId);
    return user ? `@${user.username}` : null;
  }

  /** A user's categories as this moderator sees them: with the names they cleared. */
  function userCategories(state, userId) {
    return categoriesOf(userId).map((c) => ({ ...c, ...(state.cleared.get(c.id) ?? {}) }));
  }

  function actionDto(entry, viewer) {
    const c = { targetType: entry.targetType, targetId: entry.targetId };
    const owner = ownerOf(entry.targetType, entry.targetId);
    return {
      id: entry.id,
      action: entry.action,
      targetType: entry.targetType,
      targetId: entry.targetId,
      // A cleared category's old name (F31), else the target's label.
      targetLabel: entry.label ?? labelOf(c),
      targetUser: owner ? summaryOf(owner, viewer) : null,
      moderator: entry.moderator ?? summaryOf(viewer, viewer),
      note: entry.note ?? null,
      suspendedUntil: entry.suspendedUntil ?? null,
      reportsClosed: entry.reportsClosed ?? 0,
      createdAt: entry.createdAt,
    };
  }

  function reportDto(r, viewer) {
    return {
      id: r.id,
      reporter: summaryOf(r.reporter, viewer),
      reason: r.reason,
      details: r.details,
      status: r.status,
      createdAt: r.createdAt,
      closedAt: r.closedAt,
      closedBy: r.closedBy ? summaryOf(r.closedBy, viewer) : null,
    };
  }

  const closeOpen = (c, status, viewer, at) => {
    let closed = 0;
    for (const r of c.reports) {
      if (r.status !== 'open') continue;
      Object.assign(r, { status, closedAt: at, closedBy: viewer });
      closed++;
    }
    return closed;
  };

  function page(items, q) {
    const offset = Number(q.get('cursor') ?? 0) || 0;
    const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? 20) || 20));
    return { items: items.slice(offset, offset + limit), nextCursor: offset + limit < items.length ? String(offset + limit) : null };
  }

  function act(viewer, body) {
    const { action, targetType, targetId } = body ?? {};
    if (!TYPES.includes(targetType) || !ALLOWED[targetType].includes(action)) return [400, problem(400, 'moderation.action_invalid', 'This action is not allowed here.')];
    if (typeof body.note === 'string' && body.note.length > 500) return validation('note', 'validation.max_length');
    if (!exists(targetType, targetId)) return [404, problem(404, `${targetType}.not_found`, 'Not found')];
    // Clearing a category name (F31) is allowed on any user, like hiding content.
    if (targetType === 'user' && action !== 'clear_category') {
      if (targetId === viewer) return [400, problem(400, 'moderation.self', 'You cannot moderate yourself.')];
      if (targetId.startsWith('u-mod') && action !== 'dismiss') return [403, problem(403, 'moderation.staff_target', 'Staff are protected.')];
    }
    if ((action === 'warn' || action === 'suspend') && !body.note?.trim()) return [400, problem(400, 'moderation.note_required', 'A note is required.')];
    if (action === 'suspend' && body.durationDays != null && !(Number.isInteger(body.durationDays) && body.durationDays >= 1 && body.durationDays <= 365)) {
      return [400, problem(400, 'moderation.duration_invalid', 'Pick 1 to 365 days.')];
    }

    const state = stateOf(viewer);
    let label = null;
    if (action === 'clear_category') {
      if (!body.categoryId) return validation('categoryId', 'validation.required');
      const categories = userCategories(state, targetId);
      const category = categories.find((x) => x.id === body.categoryId);
      if (!category) return [404, problem(404, 'category.not_found', 'Category not found')];
      if (PLACEHOLDER.test(category.name)) return [204, undefined];
      const used = new Set(categories.map((x) => Number(PLACEHOLDER.exec(x.name)?.[2] ?? 0)));
      let n = 1;
      while (used.has(n)) n++;
      state.cleared.set(category.id, { name: `قسم ${n}`, slug: `قسم-${n}` });
      label = category.name;
    }
    const c = caseOf(state, targetType, targetId);
    const at = new Date().toISOString();
    let reportsClosed = 0;
    let suspendedUntil = null;
    switch (action) {
      case 'hide':
        if (c.state === 'hidden') return [204, undefined];
        c.state = 'hidden';
        c.hiddenAt = at;
        c.note = body.note ?? null;
        reportsClosed = closeOpen(c, 'resolved', viewer, at);
        break;
      case 'unhide':
        if (c.state !== 'hidden') return [204, undefined];
        c.state = 'visible';
        break;
      case 'delete':
        c.state = 'deleted';
        reportsClosed = closeOpen(c, 'resolved', viewer, at);
        break;
      case 'warn':
        c.warningCount = (c.warningCount ?? 0) + 1;
        reportsClosed = closeOpen(c, 'resolved', viewer, at);
        break;
      case 'suspend':
        c.state = 'suspended';
        suspendedUntil = body.durationDays == null ? null : new Date(Date.parse(at) + body.durationDays * 86_400_000).toISOString();
        c.suspendedUntil = suspendedUntil;
        reportsClosed = closeOpen(c, 'resolved', viewer, at);
        break;
      case 'unsuspend':
        if (c.state !== 'suspended') return [204, undefined];
        c.state = 'active';
        break;
      case 'clear_category':
        reportsClosed = closeOpen(c, 'resolved', viewer, at);
        break;
      case 'dismiss':
        reportsClosed = closeOpen(c, 'dismissed', viewer, at);
        if (!reportsClosed) return [204, undefined];
        break;
    }
    if (body.resolveReportsOf && TYPES.includes(body.resolveReportsOf.targetType)) {
      reportsClosed += closeOpen(caseOf(state, body.resolveReportsOf.targetType, body.resolveReportsOf.targetId), 'resolved', viewer, at);
    }
    const logged = action === 'dismiss' ? 'reports.dismiss' : `${targetType}.${action}`;
    state.log.unshift({ id: `log-${viewer}-${nextId++}`, action: logged, targetType, targetId, note: body.note?.trim() || null, suspendedUntil, reportsClosed, createdAt: at, label });
    return [204, undefined];
  }

  function seededNotices(viewer) {
    if (!notices.has(viewer)) {
      notices.set(
        viewer,
        viewer.startsWith('u-warned')
          ? [
              { id: 'n-1', kind: 'warning', note: 'Please keep the comments respectful: no insults, even when you disagree.', article: null, createdAt: '2026-11-02T10:00:00Z' },
              {
                id: 'n-2',
                kind: 'article_hidden',
                note: 'المقال فيه أجزاء منسوخة من مصدر تاني من غير ما تذكره. ضيف المصدر وكلّمنا.',
                article: { id: 'a-dependency-injection-ar', slug: 'dependency-injection-ar', title: 'يعني إيه Dependency Injection في ASP.NET Core؟' },
                createdAt: '2026-11-02T12:00:00Z',
              },
            ]
          : [],
      );
    }
    return notices.get(viewer);
  }

  function commentDto(comment, viewer) {
    const c = isModerator(viewer) ? stateOf(viewer).cases.get(`comment:${comment.id}`) : null;
    const isHidden = c?.state === 'hidden';
    const deleted = c?.state === 'deleted';
    const mine = viewer === comment.author;
    return {
      id: comment.id,
      articleId: comment.articleId,
      parentId: null,
      body: deleted ? null : comment.body,
      author: deleted ? null : author(comment.author),
      isArticleAuthor: false,
      mentions: [],
      likeCount: 0,
      likedByMe: false,
      replyCount: 0,
      isPinned: false,
      createdAt: comment.createdAt,
      editedAt: null,
      isDeleted: deleted,
      isHidden,
      canEdit: mine,
      canDelete: mine,
      canPin: false,
      canReport: !!viewer && !mine,
      canModerate: isModerator(viewer),
      replies: [],
    };
  }

  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = social.viewerOf(req);
      return viewer ? handler(viewer, q, match, body, req) : unauthorized();
    };
  const moderatorOnly = (handler) => signedIn((viewer, ...rest) => (isModerator(viewer) ? handler(viewer, ...rest) : forbidden()));

  const API = '/api/v1';
  const routes = [
    [
      'POST',
      new RegExp(`^${API}/reports$`),
      signedIn((viewer, _q, _m, body) => {
        if (!TYPES.includes(body?.targetType)) return validation('targetType', 'report.target_invalid');
        if (!REASONS.includes(body?.reason)) return validation('reason', 'report.reason_invalid');
        if (typeof body.details === 'string' && body.details.length > 500) return validation('details', 'validation.max_length');
        if (!exists(body.targetType, body.targetId)) return [404, problem(404, 'report.target_not_found', 'Not found')];
        if (ownerOf(body.targetType, body.targetId) === viewer) return [400, problem(400, 'report.own_content', 'You cannot report your own content.')];
        reports.set(`${viewer}|${body.targetType}|${body.targetId}`, { reason: body.reason, details: body.details ?? null });
        return [204, undefined];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/moderation/summary$`),
      moderatorOnly((viewer) => {
        const open = { article: 0, comment: 0, user: 0, total: 0 };
        for (const c of stateOf(viewer).cases.values()) {
          if (c.reports.some((r) => r.status === 'open')) {
            open[c.targetType]++;
            open.total++;
          }
        }
        return [200, { open }];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/moderation/reports$`),
      moderatorOnly((viewer, q) => {
        const status = q.get('status') ?? 'open';
        const type = q.get('type');
        if (!['open', 'resolved', 'dismissed'].includes(status)) return validation('status', 'report.status_invalid');
        if (type && !TYPES.includes(type)) return validation('type', 'report.target_invalid');
        const items = [...stateOf(viewer).cases.values()]
          .filter((c) => !type || c.targetType === type)
          .map((c) => itemOf(c, status))
          .filter(Boolean)
          .sort((a, b) =>
            status === 'open' ? b.reportCount - a.reportCount || b.lastReportedAt.localeCompare(a.lastReportedAt) : b.closedAt.localeCompare(a.closedAt),
          );
        return [200, page(items, q)];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/moderation/reports/(article|comment|user)/([^/]+)$`),
      moderatorOnly((viewer, _q, [, targetType, targetId]) => {
        const c = stateOf(viewer).cases.get(`${targetType}:${decodeURIComponent(targetId)}`);
        const status = c ? caseStatus(c) : null;
        if (!c || !status) return [404, problem(404, 'report.target_not_found', 'Not found')];
        const state = stateOf(viewer);
        return [
          200,
          {
            item: itemOf(c, status),
            reports: [...c.reports].sort((a, b) => b.createdAt.localeCompare(a.createdAt)).map((r) => reportDto(r, viewer)),
            history: state.log.filter((e) => e.targetType === c.targetType && e.targetId === c.targetId).map((e) => actionDto(e, viewer)),
            // F31: a user's categories, empty ones too, so an offensive name can be cleared.
            categories: c.targetType === 'user' ? userCategories(state, c.targetId) : [],
          },
        ];
      }),
    ],
    ['POST', new RegExp(`^${API}/moderation/actions$`), moderatorOnly((viewer, _q, _m, body) => act(viewer, body))],
    [
      'GET',
      new RegExp(`^${API}/moderation/actions$`),
      moderatorOnly((viewer, q) => {
        const type = q.get('targetType');
        const entries = stateOf(viewer).log.filter((e) => !type || e.targetType === type);
        const result = page(entries, q);
        return [200, { ...result, items: result.items.map((e) => actionDto(e, viewer)) }];
      }),
    ],
    ['GET', new RegExp(`^${API}/me/moderation-notices$`), signedIn((viewer) => [200, { items: seededNotices(viewer) }])],
    [
      'POST',
      new RegExp(`^${API}/me/moderation-notices/([^/]+)/acknowledge$`),
      signedIn((viewer, _q, [, id]) => {
        const list = seededNotices(viewer);
        const at = list.findIndex((n) => n.id === id);
        if (at === -1) return [404, problem(404, 'moderation.notice_not_found', 'Notice not found')];
        list.splice(at, 1);
        return [204, undefined];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/articles/${COMMENTED_ARTICLE}/comments$`),
      (_q, _m, _body, req) => {
        const viewer = social.viewerOf(req);
        const items = COMMENTS.filter((c) => c.articleId === COMMENTED_ARTICLE)
          .map((c) => commentDto(c, viewer))
          .filter((c) => !c.isDeleted)
          .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
        return [200, { items, nextCursor: null, total: items.length }];
      },
    ],
    // What a reader reported, for the tests.
    ['GET', /^\/__mock\/reports$/, (q) => [200, reports.get(`${q.get('viewer')}|${q.get('type')}|${q.get('id')}`) ?? null]],
  ];

  /** A details DTO as `viewer` sees it: hidden articles (by this moderator) carry `moderation`, everyone else's don't. */
  function decorateArticle(dto, viewer) {
    const c = isModerator(viewer) ? stateOf(viewer).cases.get(`article:${dto.id}`) : null;
    return { ...dto, moderation: c?.state === 'hidden' ? { hiddenAt: c.hiddenAt ?? NOW, note: c.note ?? null } : null };
  }

  return { routes, decorateArticle };
}
