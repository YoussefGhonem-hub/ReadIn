/**
 * The article editor (F05) for the mock API: My articles, the working copy with versions (autosave, 409 conflicts),
 * publish / update with revisions, discard, restore, delete, tags and mention suggestions.
 *
 * State is kept per viewer (the bearer token's `sub`, like social.mjs), so parallel tests never share articles. A
 * viewer whose id starts with `u-author` starts with a few drafts and published articles (My articles); every other
 * viewer starts with none. Published articles are also served to everyone by the reader (`GET /articles/{slug}`).
 */

const PAGE_SIZE = 20;
const TAGS = ['dotnet', 'dependency-injection', 'architecture', 'angular', 'flutter', 'testing', 'performance', 'ai', 'sleep', 'docker'].map((slug, i) => ({
  slug,
  name: slug,
  articleCount: 40 - i * 3,
}));

const clone = (value) => JSON.parse(JSON.stringify(value));
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

function slugify(title, id) {
  const base = title
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
  return `${base || 'article'}-${id.replace(/[^a-z0-9]/gi, '').slice(-6).toLowerCase()}`;
}

function paragraph(id, text) {
  return { id, type: 'paragraph', content: [{ type: 'text', text }] };
}

function documentOf({ language = 'ar-EG', title, text, fieldId = 'f-software', tags = [] }) {
  return {
    sourceLanguage: language,
    translations: [{ language, title, subtitle: null, content: { version: 1, language, blocks: text ? [paragraph('p1', text)] : [] } }],
    fieldId,
    topicId: null,
    tags,
    sources: [],
    coverUrl: null,
    versionBadge: null,
    isAiAssisted: false,
    attachments: [],
  };
}

/**
 * @param {{ problem: Function, viewerOf: Function, fields: any[], assets: Map<string, any>, author: (viewer: string) => any, fieldRef: Function }} deps
 */
export function createEditor({ problem, viewerOf, fields, assets, author, fieldRef }) {
  const states = new Map();
  /** slug → { viewer, id } of every published editor article (the reader serves them). */
  const published = new Map();
  let nextId = 1;

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const notFound = () => [404, problem(404, 'article.not_found', 'Article not found')];
  const conflict = () => [409, problem(409, 'article.draft_conflict', 'The article was changed somewhere else.')];
  const validation = (field) => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors: { [field]: ['validation.invalid'] } }];

  function article(viewer, seed) {
    const id = seed.id ?? `art-${nextId++}`;
    return {
      id,
      status: 'draft',
      slug: null,
      publishedAt: null,
      version: 1,
      savedAt: seed.savedAt ?? new Date().toISOString(),
      document: seed.document,
      live: null,
      revisions: [],
      viewer,
    };
  }

  function publishNow(record, at) {
    const number = record.revisions.length + 1;
    const source = record.document.translations.find((t) => t.language === record.document.sourceLanguage) ?? record.document.translations[0];
    if (!record.slug) {
      record.slug = slugify(source.title, record.id);
      record.publishedAt = at;
      record.status = 'published';
    }
    record.revisions.unshift({ number, createdAt: at, title: source.title, languages: record.document.translations.map((t) => t.language), document: clone(record.document) });
    record.live = clone(record.document);
    published.set(record.slug, { viewer: record.viewer, id: record.id });
    return number;
  }

  function seed(viewer) {
    const articles = new Map();
    if (!viewer.startsWith('u-author')) return { articles };
    const add = (record) => articles.set(record.id, record);
    add(article(viewer, { id: `${viewer}-d1`, savedAt: '2026-11-03T09:30:00Z', document: documentOf({ title: 'يعني إيه Clean Architecture؟', text: 'مسودة لسه بكتبها.' }) }));
    add(article(viewer, { id: `${viewer}-d2`, savedAt: '2026-11-02T18:00:00Z', document: documentOf({ language: 'en', title: '', text: 'Notes for a post about Docker layers.', fieldId: null }) }));
    const live = article(viewer, { id: `${viewer}-p1`, savedAt: '2026-10-30T10:00:00Z', document: documentOf({ language: 'en', title: 'Dependency Injection in ASP.NET Core', text: 'DI makes code easier to test.', tags: ['dotnet'] }) });
    publishNow(live, '2026-10-30T10:00:00Z');
    live.document.translations[0].content.blocks.push(paragraph('p2', 'A second paragraph, not published yet.'));
    live.version = 2;
    live.savedAt = '2026-11-01T08:00:00Z';
    add(live);
    const old = article(viewer, { id: `${viewer}-p2`, savedAt: '2026-10-20T10:00:00Z', document: documentOf({ title: 'إزاي تكتب Unit Tests مفيدة', text: 'الـ unit tests بتحميك من الـ regressions.' }) });
    publishNow(old, '2026-10-20T10:00:00Z');
    add(old);
    return { articles };
  }

  function stateOf(viewer) {
    if (!states.has(viewer)) states.set(viewer, seed(viewer));
    return states.get(viewer);
  }

  function textOf(content) {
    return (content?.blocks ?? [])
      .flatMap((b) => [b.content ?? [], ...(b.items ?? []).map((i) => (Array.isArray(i) ? i : i.content ?? [])), ...(b.header ?? []), ...(b.rows ?? []).flat()])
      .flat()
      .filter((n) => n?.type === 'text')
      .map((n) => n.text)
      .join(' ');
  }

  function checksOf(document) {
    const problems = [];
    const add = (code, extra = {}) => problems.push({ code, language: null, blockId: null, mediaAssetId: null, ...extra });
    const field = fields.find((f) => f.id === document.fieldId);
    if (!field) add('article.field_required');
    for (const t of document.translations) {
      const length = t.title.trim().length;
      if (length < 5 || length > 150) add('article.title_length', { language: t.language });
      if (!textOf(t.content).trim()) add('article.content_empty', { language: t.language });
      for (const block of t.content.blocks ?? []) if (block.type === 'image' && !block.alt?.trim()) add('article.image_alt_required', { language: t.language, blockId: block.id });
    }
    if (field?.requiresSources && !document.sources.length) add('article.sources_required');
    for (const a of document.attachments) {
      const asset = assets.get(a.mediaAssetId);
      if (asset && asset.status !== 'ready') add('attachments.asset_not_ready', { mediaAssetId: a.mediaAssetId });
      else if (asset?.kind === 'image' && !a.altText?.trim()) add('attachments.alt_text_required', { mediaAssetId: a.mediaAssetId });
      else if (asset?.kind === 'document' && !a.title?.trim()) add('attachments.title_required', { mediaAssetId: a.mediaAssetId });
    }
    const readingTime = document.translations.map((t) => {
      const words = textOf(t.content).split(/\s+/).filter(Boolean).length;
      return { language: t.language, minutes: Math.max(1, Math.round(words / (t.language === 'en' ? 230 : 180))), words };
    });
    return { readingTime, problems };
  }

  function editDto(record) {
    return {
      id: record.id,
      status: record.status,
      slug: record.slug,
      publishedAt: record.publishedAt,
      version: record.version,
      savedAt: record.savedAt,
      hasUnpublishedChanges: record.status === 'published' && !same(record.document, record.live),
      document: record.document,
      media: record.document.attachments.map((a) => assets.get(a.mediaAssetId)).filter(Boolean),
      checks: checksOf(record.document),
    };
  }

  function myArticle(record) {
    const doc = record.status === 'published' ? record.live : record.document;
    const source = record.document.translations.find((t) => t.language === record.document.sourceLanguage) ?? record.document.translations[0];
    const field = fields.find((f) => f.id === record.document.fieldId);
    return {
      id: record.id,
      status: record.status,
      slug: record.slug,
      language: record.document.sourceLanguage,
      title: source.title,
      coverUrl: record.document.coverUrl,
      field: field ? fieldRef(field) : null,
      readingTimeMinutes: checksOf(doc).readingTime[0]?.minutes ?? 1,
      savedAt: record.savedAt,
      publishedAt: record.publishedAt,
      hasUnpublishedChanges: record.status === 'published' && !same(record.document, record.live),
      reactionCount: record.status === 'published' ? 4 : 0,
      commentCount: record.status === 'published' ? 1 : 0,
      readCount: record.status === 'published' ? 37 : 0,
    };
  }

  /** The body a save may carry; anything else is `validation.failed`, like the API. */
  function invalidDocument(document) {
    if (!document || typeof document !== 'object' || !Array.isArray(document.translations)) return 'document';
    const languages = document.translations.map((t) => t.language);
    if (!languages.length || languages.length > 2 || new Set(languages).size !== languages.length) return 'translations';
    if (!languages.includes(document.sourceLanguage)) return 'sourceLanguage';
    if (document.translations.some((t) => t.content?.language !== t.language)) return 'content';
    if ((document.tags ?? []).length > 5) return 'tags';
    if ((document.sources ?? []).some((s) => !s.title?.trim() || !/^https?:\/\//.test(s.url ?? ''))) return 'sources';
    return null;
  }

  const signedIn =
    (handler) =>
    (q, match, body, req) => {
      const viewer = viewerOf(req);
      return viewer ? handler(viewer, stateOf(viewer), q, match, body) : unauthorized();
    };

  /** The viewer's own article, or a 404 (someone else's articles are "not found" too). */
  const own =
    (handler) =>
    (q, match, body, req) => {
      const viewer = viewerOf(req);
      if (!viewer) return unauthorized();
      const record = stateOf(viewer).articles.get(decodeURIComponent(match[1]));
      return record ? handler(record, viewer, q, match, body) : notFound();
    };

  const API = '/api/v1';
  const routes = [
    [
      'GET',
      new RegExp(`^${API}/me/articles$`),
      signedIn((_viewer, state, q) => {
        const status = q.get('status') === 'published' ? 'published' : 'draft';
        const items = [...state.articles.values()]
          .filter((a) => a.status === status)
          .sort((a, b) => (status === 'published' ? b.publishedAt.localeCompare(a.publishedAt) : b.savedAt.localeCompare(a.savedAt)));
        const offset = Number(q.get('cursor') ?? 0) || 0;
        const limit = Math.min(50, Math.max(1, Number(q.get('limit') ?? PAGE_SIZE) || PAGE_SIZE));
        return [200, { items: items.slice(offset, offset + limit).map(myArticle), nextCursor: offset + limit < items.length ? String(offset + limit) : null }];
      }),
    ],
    [
      'POST',
      new RegExp(`^${API}/articles$`),
      signedIn((viewer, state, _q, _m, body) => {
        const invalid = invalidDocument(body);
        if (invalid) return validation(invalid);
        const record = article(viewer, { document: body });
        state.articles.set(record.id, record);
        return [201, editDto(record)];
      }),
    ],
    ['GET', new RegExp(`^${API}/articles/([^/]+)/edit$`), own((record) => [200, editDto(record)])],
    [
      'PUT',
      new RegExp(`^${API}/articles/([^/]+)/draft$`),
      own((record, _viewer, _q, _m, body) => {
        const invalid = invalidDocument(body?.document);
        if (invalid) return validation(invalid);
        if (body.baseVersion !== record.version) return conflict();
        record.document = body.document;
        record.version++;
        record.savedAt = new Date().toISOString();
        return [200, editDto(record)];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/articles/([^/]+)/draft$`),
      own((record) => {
        if (record.status !== 'published') return [409, problem(409, 'article.not_published', 'Not published')];
        record.document = clone(record.live);
        record.version++;
        record.savedAt = new Date().toISOString();
        return [200, editDto(record)];
      }),
    ],
    [
      'POST',
      new RegExp(`^${API}/articles/([^/]+)/publish$`),
      own((record, _viewer, _q, _m, body) => {
        if (body?.baseVersion !== record.version) return conflict();
        const { problems } = checksOf(record.document);
        if (problems.length) return [400, { ...problem(400, problems[0].code, 'The article has problems'), problems }];
        const firstPublish = record.status === 'draft';
        const at = new Date().toISOString();
        const revision = publishNow(record, at);
        return [200, { id: record.id, slug: record.slug, publishedAt: record.publishedAt, revision, firstPublish }];
      }),
    ],
    ['GET', new RegExp(`^${API}/articles/([^/]+)/revisions$`), own((record) => [200, record.revisions.map(({ document: _document, ...head }) => head)])],
    [
      'GET',
      new RegExp(`^${API}/articles/([^/]+)/revisions/(\\d+)$`),
      own((record, _viewer, _q, match) => {
        const revision = record.revisions.find((r) => r.number === Number(match[2]));
        if (!revision) return [404, problem(404, 'article.revision_not_found', 'Revision not found')];
        return [200, { ...revision, media: revision.document.attachments.map((a) => assets.get(a.mediaAssetId)).filter(Boolean) }];
      }),
    ],
    [
      'POST',
      new RegExp(`^${API}/articles/([^/]+)/revisions/(\\d+)/restore$`),
      own((record, _viewer, _q, match, body) => {
        const revision = record.revisions.find((r) => r.number === Number(match[2]));
        if (!revision) return [404, problem(404, 'article.revision_not_found', 'Revision not found')];
        if (body?.baseVersion !== record.version) return conflict();
        record.document = clone(revision.document);
        record.version++;
        record.savedAt = new Date().toISOString();
        return [200, editDto(record)];
      }),
    ],
    [
      'DELETE',
      new RegExp(`^${API}/articles/([^/]+)$`),
      own((record, viewer) => {
        stateOf(viewer).articles.delete(record.id);
        if (record.slug) published.delete(record.slug);
        return [204, undefined];
      }),
    ],
    [
      'GET',
      new RegExp(`^${API}/tags$`),
      (q) => {
        const prefix = (q.get('q') ?? '').trim().toLowerCase();
        const limit = Math.min(50, Number(q.get('limit') ?? 10) || 10);
        return [200, TAGS.filter((t) => t.slug.startsWith(prefix) || t.name.toLowerCase().startsWith(prefix)).slice(0, limit)];
      },
    ],
  ];

  /** Reader DTO (`GET /articles/{slug}`) of a published editor article, or null. */
  function readerArticle(slug, lang) {
    const ref = published.get(slug);
    const record = ref ? stateOf(ref.viewer).articles.get(ref.id) : null;
    if (!record?.live) return null;
    const live = record.live;
    const translation = live.translations.find((t) => t.language === lang) ?? live.translations.find((t) => t.language === live.sourceLanguage);
    const field = fields.find((f) => f.id === live.fieldId) ?? fields[0];
    const images = [];
    let documentAttachment = null;
    for (const a of [...live.attachments].sort((x, y) => x.order - y.order)) {
      const asset = assets.get(a.mediaAssetId);
      if (!asset) continue;
      if (asset.kind === 'image') {
        images.push({ assetId: asset.id, order: images.length, caption: a.caption ?? null, altText: a.altText ?? '', width: asset.width, height: asset.height, blurHash: asset.blurHash, variants: asset.variants });
      } else {
        documentAttachment = {
          assetId: asset.id,
          title: a.title ?? asset.title,
          pageCount: asset.pageCount,
          allowDownload: !!a.allowDownload,
          canDownload: !!a.allowDownload,
          downloadUrl: `http://localhost/api/v1/documents/${asset.id}/download`,
          pages: asset.pages,
        };
      }
    }
    const attachments = documentAttachment ? { kind: 'document', images: [], document: documentAttachment } : images.length ? { kind: 'images', images, document: null } : null;
    return {
      id: record.id,
      slug: record.slug,
      language: translation.language,
      title: translation.title,
      subtitle: translation.subtitle,
      coverUrl: live.coverUrl,
      field: fieldRef(field),
      author: author(record.viewer),
      readingTimeMinutes: checksOf(live).readingTime.find((r) => r.language === translation.language)?.minutes ?? 1,
      isAiAssisted: live.isAiAssisted,
      versionBadge: live.versionBadge,
      publishedAt: record.publishedAt,
      reactionCount: 0,
      reactions: { insightful: 0, love: 0, fire: 0, mindBlown: 0 },
      commentCount: 0,
      saveCount: 0,
      myReaction: null,
      isSaved: false,
      attachments,
      availableLanguages: live.translations.map((t) => t.language),
      summary: null,
      content: translation.content,
      topic: null,
      tags: live.tags,
      sources: live.sources,
      readCount: 0,
      isFollowingAuthor: false,
      collectionIds: [],
    };
  }

  return { routes, readerArticle };
}
