/**
 * Deterministic stand-in for the ReadIn API (docs/api/contract-v1.md) for Playwright. No backend runs in e2e, and
 * SSR fetches data from Node where `page.route` can't intercept it, so this server answers both the SSR and the
 * browser calls on the API's dev address (http://localhost:5080/api/v1, from environment.development.ts).
 *
 * Content is stateless: per-test flows (create post, uploads, polling, publish) are stubbed in the browser with
 * `page.route` (e2e/support). Reactions, saved articles, collections and follows (social.mjs) keep state per signed-in
 * viewer, so those flows run against it end to end. It also serves generated PNGs for every media URL and fixture
 * builders under `/__mock`.
 *
 * Run: `node e2e/mock-api/server.mjs` (playwright.config.ts starts it). Port: MOCK_API_PORT (default 5080).
 */
import { createServer } from 'node:http';
import { crc32, deflateSync } from 'node:zlib';
import { encode } from 'blurhash';
import { createSocial } from './social.mjs';

const PORT = Number(process.env.MOCK_API_PORT ?? 5080);
const ORIGIN = `http://localhost:${PORT}`;
const API = '/api/v1';

// ── PNG generation ─────────────────────────────────────────────

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body) >>> 0);
  return Buffer.concat([length, body, crc]);
}

/** RGB PNG from a pixel function `(u, v) => [r, g, b]` over normalized coordinates (same picture at any size). */
function png(width, height, pixel) {
  const raw = Buffer.alloc((width * 3 + 1) * height);
  let offset = 0;
  for (let y = 0; y < height; y++) {
    raw[offset++] = 0;
    for (let x = 0; x < width; x++) {
      const [r, g, b] = pixel((x + 0.5) / width, (y + 0.5) / height);
      raw[offset++] = r;
      raw[offset++] = g;
      raw[offset++] = b;
    }
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header.set([8, 2, 0, 0, 0], 8);
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

function hash(text) {
  let h = 2166136261;
  for (const ch of text) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return h >>> 0;
}

function hsl(h, s, l) {
  const k = (n) => (n + h / 30) % 12;
  const a = s * Math.min(l, 1 - l);
  const f = (n) => l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
  return [Math.round(f(0) * 255), Math.round(f(8) * 255), Math.round(f(4) * 255)];
}

/** A "photo": diagonal two-hue gradient, a sun and a horizon band. */
function photoPixel(seed) {
  const hue = hash(seed) % 360;
  return (u, v) => {
    const t = (u + v) / 2;
    let [r, g, b] = hsl((hue + t * 70) % 360, 0.55, 0.42 + 0.25 * (1 - v));
    const dx = u - 0.7;
    const dy = v - 0.32;
    if (dx * dx + dy * dy < 0.018) [r, g, b] = hsl((hue + 180) % 360, 0.7, 0.75);
    if (v > 0.72) [r, g, b] = hsl((hue + 30) % 360, 0.35, 0.25 + 0.1 * Math.sin(u * 18));
    return [r, g, b];
  };
}

/** A "PDF page": paper, a colored title bar, text lines and a page band (each page looks different). */
function pagePixel(seed) {
  const hue = hash(seed) % 360;
  const pageNo = Number(/p(\d+)$/.exec(seed)?.[1] ?? 1);
  return (u, v) => {
    if (u < 0.08 || u > 0.92 || v < 0.06 || v > 0.94) return [246, 244, 239];
    if (v < 0.16) return hsl(hue, 0.45, 0.35);
    const line = Math.floor((v - 0.2) / 0.045);
    const inLine = (v - 0.2) % 0.045 < 0.018 && v > 0.2 && v < 0.86;
    const lineEnd = 0.84 - ((line * 37 + pageNo * 11) % 30) / 100;
    if (inLine && u < lineEnd) return [150, 150, 146];
    if (v > 0.88 && u > 0.12 + (pageNo % 10) * 0.07 && u < 0.18 + (pageNo % 10) * 0.07) return hsl((hue + 40) % 360, 0.6, 0.5);
    return [252, 251, 248];
  };
}

const pngCache = new Map();
function mediaPng(kind, seed, width, height) {
  const key = `${kind}|${seed}|${width}x${height}`;
  if (!pngCache.has(key)) pngCache.set(key, png(width, height, kind === 'page' ? pagePixel(seed) : photoPixel(seed)));
  return pngCache.get(key);
}

/** BlurHash of the same picture (encoded from a tiny render, like the backend does from the original). */
function blurHashOf(kind, seed, width, height) {
  const w = 32;
  const h = Math.max(1, Math.round((32 * height) / width));
  const pixel = kind === 'page' ? pagePixel(seed) : photoPixel(seed);
  const data = new Uint8ClampedArray(w * h * 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) data.set([...pixel((x + 0.5) / w, (y + 0.5) / h), 255], (y * w + x) * 4);
  return encode(data, w, h, 4, 3);
}

// ── DTO builders (contract-v1) ─────────────────────────────────

const mediaUrl = (kind, seed, width, height) => `${ORIGIN}/uploads/mock/${kind}/${encodeURIComponent(seed)}/${width}x${height}.png`;
const IMAGE_WIDTHS = [320, 640, 1080, 1600];

function variants(seed, width, height) {
  const widths = IMAGE_WIDTHS.filter((w) => w < width);
  widths.push(Math.min(width, 1600));
  return [...new Set(widths)].map((w) => {
    const h = Math.round((w * height) / width);
    return { width: w, height: h, url: mediaUrl('photo', seed, w, h), bytes: Math.round(w * h * 0.12) };
  });
}

function page(docSeed, pageNo) {
  const seed = `${docSeed}-p${pageNo}`;
  return {
    pageNo,
    width: 1080,
    height: 1527,
    blurHash: blurHashOf('page', seed, 1080, 1527),
    thumbUrl: mediaUrl('page', seed, 400, 566),
    viewUrl: mediaUrl('page', seed, 1080, 1527),
  };
}

function imageAsset(seed, width = 1600, height = 1200) {
  return {
    id: `asset-${seed}`,
    kind: 'image',
    purpose: 'image',
    status: 'ready',
    failureReason: null,
    width,
    height,
    blurHash: blurHashOf('photo', seed, width, height),
    sizeBytes: 480_000,
    variants: variants(seed, width, height),
    title: null,
    pageCount: null,
    pagesReady: 0,
    pages: [],
    allowDownload: false,
    createdAt: '2026-11-03T08:00:00Z',
  };
}

function documentAsset(seed, { pageCount = 12, pagesReady = pageCount, status = 'ready', title = 'ASP.NET Core cheat sheet', allowDownload = false } = {}) {
  const pages = Array.from({ length: pagesReady }, (_, i) => page(seed, i + 1));
  return {
    id: `asset-${seed}`,
    kind: 'document',
    purpose: 'document',
    status,
    failureReason: null,
    width: 1080,
    height: 1527,
    blurHash: pages[0]?.blurHash ?? null,
    sizeBytes: 2_400_000,
    variants: [],
    title,
    pageCount,
    pagesReady,
    pages,
    allowDownload,
    createdAt: '2026-11-03T08:00:00Z',
  };
}

/** Writers people can follow (F12); `followsEveryone` makes `followsYou` true for every viewer. */
const WRITERS = [
  { id: 'u-writer', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: true, followerCount: 1280, bio: 'Backend engineer. بكتب عن .NET والـ architecture.' },
  { id: 'u-readin', displayName: 'ReadIn', username: 'readin', avatarUrl: null, isVerified: true, followerCount: 5400, bio: 'The official ReadIn account — مقال كل يوم يفرق معاك.' },
  { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true, followerCount: 860, bio: 'Frontend lead: React, Angular and web performance.' },
  { id: 'u-salma', displayName: 'سلمى إبراهيم', username: 'salma', avatarUrl: null, isVerified: false, followerCount: 430, bio: 'ML engineer بتحب تبسّط الـ AI.', followsEveryone: true },
  { id: 'u-omar', displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false, followerCount: 210, bio: 'Sleep, memory and learning, from a medical student.' },
];
const authorOf = (id) => {
  const { displayName, username, avatarUrl, isVerified } = WRITERS.find((w) => w.id === id);
  return { id, displayName, username, avatarUrl, isVerified };
};
const AUTHOR = authorOf('u-writer');
const FIELDS = [
  { id: 'f-software', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software', icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, topicCount: 2 },
  { id: 'f-medicine', slug: 'medicine', name: 'Medicine', nameAr: 'الطب', nameEn: 'Medicine', icon: 'stethoscope', color: 'primary', isSensitive: true, requiresSources: true, topicCount: 0 },
];
const TOPICS = {
  software: [
    { id: 't-dotnet', fieldId: 'f-software', slug: 'dotnet', name: '.NET', nameAr: '.NET', nameEn: '.NET' },
    { id: 't-architecture', fieldId: 'f-software', slug: 'architecture', name: 'Architecture', nameAr: 'المعمارية', nameEn: 'Architecture' },
  ],
};
const fieldRef = ({ id, slug, name, nameAr, nameEn }) => ({ id, slug, name, nameAr, nameEn });

function imageAttachment(asset, order, altText, caption = null) {
  return { assetId: asset.id, order, caption, altText, width: asset.width, height: asset.height, blurHash: asset.blurHash, variants: asset.variants };
}

function documentAttachment(asset, { canDownload = asset.allowDownload, maxPages = Infinity } = {}) {
  return {
    assetId: asset.id,
    title: asset.title,
    pageCount: asset.pageCount,
    allowDownload: asset.allowDownload,
    canDownload,
    downloadUrl: `${ORIGIN}${API}/documents/${asset.id}/download`,
    pages: asset.pages.slice(0, maxPages),
  };
}

/** A card as a guest sees it; `reactions` and `saves` are everyone else's (social.mjs adds the viewer's own). */
function card({
  slug,
  language = 'en',
  title,
  attachments = null,
  minutes = 4,
  reactions = { insightful: 6, love: 3, fire: 2, mindBlown: 1 },
  saves = 4,
  comments = 3,
  author = AUTHOR,
  field = FIELDS[0],
  publishedAt = '2026-11-02T08:00:00Z',
}) {
  return {
    id: `a-${slug}`,
    slug,
    language,
    title,
    subtitle: null,
    coverUrl: null,
    field: fieldRef(field),
    author,
    readingTimeMinutes: minutes,
    isReviewed: true,
    isAiAssisted: false,
    versionBadge: null,
    publishedAt,
    reactionCount: Object.values(reactions).reduce((a, b) => a + b, 0),
    reactions,
    commentCount: comments,
    saveCount: saves,
    myReaction: null,
    isSaved: false,
    attachments,
  };
}

function details(cardDto, paragraphs = ['A short post about the attached media.']) {
  return {
    ...cardDto,
    availableLanguages: [cardDto.language],
    summary: null,
    content: {
      version: 1,
      language: cardDto.language,
      blocks: paragraphs.map((text, i) => ({ id: `p${i + 1}`, type: 'paragraph', dir: 'auto', content: [{ type: 'text', text }] })),
    },
    topic: null,
    tags: [],
    sources: [{ title: 'Microsoft Learn', url: 'https://learn.microsoft.com/aspnet/core' }],
    reviewedBy: null,
    lastReviewedAt: null,
    readCount: 0,
    isFollowingAuthor: false,
    collectionIds: [],
  };
}

const whiteboard = [imageAsset('whiteboard', 1600, 1200), imageAsset('layers', 1200, 1600), imageAsset('diagram', 1600, 900)];
const cheatSheet = documentAsset('cheatsheet', { pageCount: 12 });
const portrait = imageAsset('portrait', 1200, 1600);

const ARTICLES = [
  card({
    slug: 'clean-architecture-whiteboard',
    title: 'Clean Architecture on one whiteboard',
    attachments: {
      kind: 'images',
      images: [
        imageAttachment(whiteboard[0], 0, 'Whiteboard with the four layers', 'The four layers, outside in'),
        imageAttachment(whiteboard[1], 1, 'Dependency arrows pointing inwards', 'Dependencies point inwards'),
        imageAttachment(whiteboard[2], 2, 'Use case flow diagram', null),
      ],
      document: null,
    },
  }),
  card({
    slug: 'dependency-injection-ar',
    language: 'ar-EG',
    title: 'يعني إيه Dependency Injection في ASP.NET Core؟',
    minutes: 6,
    reactions: { insightful: 5, love: 4, fire: 2, mindBlown: 1 },
    saves: 9,
  }),
  card({
    slug: 'aspnet-core-cheatsheet',
    title: 'ASP.NET Core cheat sheet (PDF)',
    attachments: { kind: 'document', images: [], document: documentAttachment(cheatSheet, { maxPages: 10 }) },
    reactions: { insightful: 7, love: 2, fire: 3, mindBlown: 0 },
    saves: 23,
  }),
  card({
    slug: 'one-photo',
    title: 'My desk setup for focused reading',
    attachments: { kind: 'images', images: [imageAttachment(portrait, 0, 'A tidy desk with a laptop and a notebook', 'Less is more')], document: null },
    reactions: { insightful: 2, love: 7, fire: 2, mindBlown: 1 },
    saves: 2,
  }),
];

/** Published by the other writers: in the Following feed, Saved and the reader, never in For you (its baselines). */
const MORE_ARTICLES = [
  card({
    slug: 'how-readin-picks-your-daily-article',
    title: 'How ReadIn picks your daily article',
    author: authorOf('u-readin'),
    publishedAt: '2026-11-03T06:00:00Z',
    minutes: 3,
    reactions: { insightful: 31, love: 9, fire: 4, mindBlown: 1 },
    saves: 57,
    comments: 14,
  }),
  card({
    slug: 'react-server-components-explained',
    title: 'React Server Components, explained without the hype',
    author: authorOf('u-karim'),
    publishedAt: '2026-11-02T15:00:00Z',
    minutes: 7,
    reactions: { insightful: 8, love: 2, fire: 5, mindBlown: 3 },
    saves: 31,
    comments: 6,
  }),
  card({
    slug: 'readin-streaks-ar',
    language: 'ar-EG',
    title: 'إزاي الـ streak بيساعدك تقرا كل يوم',
    author: authorOf('u-readin'),
    publishedAt: '2026-11-01T09:00:00Z',
    minutes: 4,
    reactions: { insightful: 4, love: 6, fire: 1, mindBlown: 0 },
    saves: 12,
    comments: 2,
  }),
  card({
    slug: 'what-is-a-transformer-ar',
    language: 'ar-EG',
    title: 'يعني إيه Transformer في الـ AI؟',
    author: authorOf('u-salma'),
    publishedAt: '2026-10-31T11:00:00Z',
    minutes: 8,
    reactions: { insightful: 10, love: 3, fire: 2, mindBlown: 6 },
    saves: 40,
    comments: 9,
  }),
  card({
    slug: 'sleep-and-memory',
    title: 'How sleep turns reading into memory',
    author: authorOf('u-omar'),
    field: FIELDS[1],
    publishedAt: '2026-10-29T19:00:00Z',
    minutes: 5,
    reactions: { insightful: 3, love: 1, fire: 0, mindBlown: 2 },
    saves: 8,
    comments: 1,
  }),
];
const ALL_ARTICLES = [...ARTICLES, ...MORE_ARTICLES];

const DETAILS = new Map(
  ALL_ARTICLES.map((a) => {
    const full = a.attachments?.kind === 'document' ? { ...a, attachments: { ...a.attachments, document: documentAttachment(cheatSheet) } } : a;
    return [a.slug, details(full)];
  }),
);

/** The demo account (a fictional Egyptian mobile number). Sign in with MOCK_PASSWORD. */
const MOCK_PHONE = '+201001234567';
const MOCK_PASSWORD = 'Readin2026!';

function me({ uiLanguage = 'ar', theme = 'system' } = {}) {
  return {
    id: 'u-writer',
    phoneNumber: MOCK_PHONE,
    email: null,
    displayName: 'Mona Adel',
    username: 'mona',
    avatarUrl: null,
    bio: null,
    links: {},
    uiLanguage,
    articleLanguage: 'en',
    theme,
    timeZone: 'Africa/Cairo',
    reminderTime: '08:00',
    isVerified: true,
    onboardingCompleted: true,
    mustChangePassword: false,
    mustSetRecoveryPin: false,
    isProfileComplete: true,
    hasRecoveryPin: true,
    hasPassword: true,
    externalLogins: [],
    roles: ['Member', 'VerifiedWriter'],
    permissions: ['articles.read', 'articles.create'],
    interests: { fieldIds: ['f-software'], topicIds: [] },
  };
}

// ── Sessions (SPEC §9.3) ───────────────────────────────────────

const base64Url = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');

/** An unsigned JWT with the claims the web reads (`iat`/`exp` decide when it refreshes); nothing verifies it. */
function accessToken(userId) {
  const iat = Math.floor(Date.now() / 1000);
  const jti = `${userId}-${iat}-${Math.random().toString(36).slice(2)}`;
  return [base64Url({ alg: 'none', typ: 'JWT' }), base64Url({ sub: userId, iat, exp: iat + 900, jti }), 'mock'].join('.');
}

/** `SessionDto` as the web gets it: the refresh token travels in the HttpOnly cookie, never in the body. */
function session(user) {
  const now = Date.now();
  return {
    accessToken: accessToken(user.id),
    accessTokenExpiresAt: new Date(now + 15 * 60_000).toISOString(),
    refreshToken: null,
    refreshTokenExpiresAt: new Date(now + 30 * 24 * 3_600_000).toISOString(),
    user,
  };
}

const REFRESH_COOKIE = 'readin_refresh';
/** Like the API's cookie, minus `Secure` (the mock is plain http). */
const setRefreshCookie = (value) => ({ 'set-cookie': `${REFRESH_COOKIE}=${value}; HttpOnly; SameSite=Strict; Path=/api/v1/auth; Max-Age=2592000` });
const clearRefreshCookie = { 'set-cookie': `${REFRESH_COOKIE}=; HttpOnly; SameSite=Strict; Path=/api/v1/auth; Max-Age=0` };

function cookie(req, name) {
  for (const part of (req.headers.cookie ?? '').split(';')) {
    const [key, ...value] = part.trim().split('=');
    if (key === name) return decodeURIComponent(value.join('='));
  }
  return null;
}

// ── HTTP ───────────────────────────────────────────────────────

/** Credentialed CORS (the web sends the refresh cookie to /auth/*): the origin is echoed, never `*`. */
function cors(req) {
  return {
    'access-control-allow-origin': req.headers.origin ?? '*',
    'access-control-allow-credentials': 'true',
    'access-control-allow-headers': 'authorization, content-type, accept-language, x-requested-with, x-readin-client',
    'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'access-control-expose-headers': 'content-disposition',
    vary: 'Origin',
  };
}

function send(req, res, status, body, headers = {}) {
  const isJson = body !== undefined && !Buffer.isBuffer(body);
  res.writeHead(status, { ...cors(req), ...(isJson ? { 'content-type': 'application/json; charset=utf-8' } : {}), ...headers });
  res.end(isJson ? JSON.stringify(body) : body);
}

const problem = (status, code, title) => ({ type: `https://readin.app/errors/${code}`, title, status, code, traceId: '00-mock' });

/** A tiny valid one-page PDF for the download endpoint. */
const PDF = Buffer.from(
  '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n',
);

const social = createSocial({ articles: ALL_ARTICLES, writers: WRITERS, problem });

const routes = [
  ...social.routes,
  ['GET', /^\/__mock\/health$/, () => [200, { ok: true }]],
  ['GET', /^\/__mock\/asset\/image$/, (q) => [200, imageAsset(q.get('seed') ?? 'upload', Number(q.get('w') ?? 1600), Number(q.get('h') ?? 1200))]],
  [
    'GET',
    /^\/__mock\/asset\/document$/,
    (q) => [
      200,
      documentAsset(q.get('seed') ?? 'doc', {
        pageCount: Number(q.get('pages') ?? 12),
        pagesReady: Number(q.get('ready') ?? q.get('pages') ?? 12),
        status: q.get('status') ?? 'ready',
        title: q.get('title') ?? 'Document',
        allowDownload: q.get('allowDownload') === 'true',
      }),
    ],
  ],
  ['GET', /^\/__mock\/png$/, (q) => [200, mediaPng('photo', q.get('seed') ?? 'x', Number(q.get('w') ?? 800), Number(q.get('h') ?? 600)), { 'content-type': 'image/png' }]],
  [
    'GET',
    /^\/uploads\/mock\/(photo|page)\/([^/]+)\/(\d+)x(\d+)\.png$/,
    (_q, [, kind, seed, w, h]) => [
      200,
      mediaPng(kind, decodeURIComponent(seed), Math.min(2048, Number(w)), Math.min(2048, Number(h))),
      { 'content-type': 'image/png', 'cache-control': 'public, max-age=31536000, immutable' },
    ],
  ],
  ['GET', new RegExp(`^${API}/fields$`), () => [200, FIELDS]],
  ['GET', new RegExp(`^${API}/fields/([^/]+)/topics$`), (_q, [, slug]) => [200, TOPICS[slug] ?? []]],
  ['GET', new RegExp(`^${API}/feed/today$`), () => [204, undefined]],
  [
    'GET',
    new RegExp(`^${API}/feed/for-you$`),
    (q, _m, _body, req) => [200, { items: q.get('cursor') ? [] : ARTICLES.map((a) => social.personalize(a, social.viewerOf(req))), nextCursor: null }],
  ],
  [
    'GET',
    new RegExp(`^${API}/articles/([^/]+)$`),
    (_q, [, slug], _body, req) =>
      DETAILS.has(slug) ? [200, social.personalize(DETAILS.get(slug), social.viewerOf(req))] : [404, problem(404, 'article.not_found', 'Article not found')],
  ],
  // Phone + password sessions (docs/api/contract-v1.md → Auth). The cookie is the whole session: `readin_refresh=writer`.
  ['GET', new RegExp(`^${API}/auth/config$`), () => [200, { pinLength: 4, password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true }, externalProviders: [] }]],
  [
    'POST',
    new RegExp(`^${API}/auth/login$`),
    (_q, _m, body) =>
      body?.phoneNumber === MOCK_PHONE && body?.password === MOCK_PASSWORD
        ? [200, session(me()), setRefreshCookie('writer')]
        : [401, problem(401, 'auth.invalid_credentials', 'The phone number or password is incorrect.')],
  ],
  [
    'POST',
    new RegExp(`^${API}/auth/refresh$`),
    (_q, _m, _body, req) =>
      cookie(req, REFRESH_COOKIE) === 'writer' && req.headers['x-readin-client'] === 'web'
        ? [200, session(me()), setRefreshCookie('writer')]
        : [401, problem(401, 'auth.refresh_invalid', 'Your session has ended. Sign in again.'), clearRefreshCookie],
  ],
  ['POST', new RegExp(`^${API}/auth/logout$`), () => [204, undefined, clearRefreshCookie]],
  ['POST', new RegExp(`^${API}/auth/logout-all$`), () => [200, session(me()), setRefreshCookie('writer')]],
  [
    'GET',
    new RegExp(`^${API}/users/username-available$`),
    (q) => [200, { username: q.get('u') ?? '', valid: /^[a-z0-9_]{3,30}$/.test(q.get('u') ?? ''), available: q.get('u') !== 'taken' }],
  ],
  ['GET', new RegExp(`^${API}/me$`), () => [200, me()]],
  ['DELETE', new RegExp(`^${API}/me/devices/[^/]+$`), () => [204, undefined]],
  ['PUT', new RegExp(`^${API}/me/(preferences|interests)$`), () => [204, undefined]],
  ['PATCH', new RegExp(`^${API}/me$`), () => [204, undefined]],
  ['POST', new RegExp(`^${API}/me/devices$`), () => [204, undefined]],
  [
    'GET',
    new RegExp(`^${API}/documents/([^/]+)/download$`),
    () => [200, PDF, { 'content-type': 'application/pdf', 'content-disposition': 'attachment; filename="document.pdf"' }],
  ],
];

async function readJson(req) {
  if (req.method === 'GET' || req.method === 'HEAD') return null;
  const chunks = [];
  for await (const part of req) chunks.push(part);
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8') || 'null');
  } catch {
    return null;
  }
}

const server = createServer(async (req, res) => {
  try {
    if (req.method === 'OPTIONS') return send(req, res, 204, Buffer.alloc(0));
    const url = new URL(req.url ?? '/', ORIGIN);
    for (const [method, pattern, handler] of routes) {
      const match = method === req.method ? pattern.exec(url.pathname) : null;
      if (!match) continue;
      const [status, body, headers] = handler(url.searchParams, match, await readJson(req), req);
      return send(req, res, status, status === 204 ? Buffer.alloc(0) : body, headers);
    }
    send(req, res, 404, problem(404, 'not_found', `No mock for ${req.method} ${url.pathname}`));
  } catch (error) {
    send(req, res, 500, problem(500, 'server.error', String(error)));
  }
});

server.listen(PORT, () => console.log(`ReadIn mock API on ${ORIGIN}${API}`));
