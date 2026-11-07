/**
 * Search engines (SPEC §23): `/robots.txt`, and a dynamic `/sitemap.xml` split per language. The index points to
 * `/sitemap-ar.xml` and `/sitemap-en.xml` (one URL per article version) and `/sitemap-pages.xml` (home, Explore, the
 * paths, writers, their categories, fields and tags). The API lists the public pages (`GET /sitemap`, only what a guest
 * can open); this file builds the web's URLs from them, in the same shapes as the canonical URLs (article-link.ts,
 * category-rules.ts, the profile/field/tag/path SEO services). The SSR server (server.ts) serves them.
 *
 * The XML and robots builders are pure; `createSitemapSource` fetches and caches the API's answer.
 */

/** `GET /api/v1/sitemap` (`SitemapDto`). Dates are ISO strings. */
export interface SitemapData {
  articles: { slug: string; language: string; lastModified: string }[];
  writers: { username: string; lastModified: string }[];
  categories: { username: string; slug: string; lastModified: string }[];
  fields: { slug: string; lastModified: string | null }[];
  tags: { slug: string; lastModified: string | null }[];
  paths: { slug: string; lastModified: string | null }[];
}

export type SitemapPart = 'ar' | 'en' | 'pages';

export const SITEMAP_FILES = {
  index: '/sitemap.xml',
  ar: '/sitemap-ar.xml',
  en: '/sitemap-en.xml',
  pages: '/sitemap-pages.xml',
} as const;

/** Pages for the signed-in user only (rendered in the browser) and Search (`noindex`): not crawled. */
export const ROBOTS_DISALLOW = [
  '/auth/',
  '/onboarding',
  '/settings',
  '/write',
  '/saved',
  '/notifications',
  '/moderation',
  '/me/',
  '/verification',
  '/admin/',
  '/search',
] as const;

/** Pages that are always there, before the ones the API lists. */
const STATIC_PATHS = ['/', '/explore', '/paths'] as const;

interface Entry {
  path: string;
  lastModified?: string | null;
}

/** The article URL's language segment, as `urlLangFor` (article-link.ts): `en`, or `ar` for the Arabic version. */
export function urlLanguage(language: string): 'ar' | 'en' {
  return language === 'en' ? 'en' : 'ar';
}

export function robotsTxt(siteUrl: string): string {
  return [
    'User-agent: *',
    'Allow: /',
    ...ROBOTS_DISALLOW.map((path) => `Disallow: ${path}`),
    '',
    `Sitemap: ${origin(siteUrl)}${SITEMAP_FILES.index}`,
    '',
  ].join('\n');
}

/** The sitemap index: the two article files (when they have entries) and the pages file. */
export function sitemapIndexXml(siteUrl: string, data: SitemapData): string {
  const base = origin(siteUrl);
  const parts: SitemapPart[] = ['ar', 'en', 'pages'];
  const items = parts
    .map((part) => ({ part, entries: entriesOf(part, data) }))
    .filter(({ part, entries }) => part === 'pages' || entries.length > 0)
    .map(({ part, entries }) => {
      const lastModified = newest(entries.map((entry) => entry.lastModified));
      return `  <sitemap><loc>${escapeXml(base + SITEMAP_FILES[part])}</loc>${lastModified ? `<lastmod>${lastModified}</lastmod>` : ''}</sitemap>`;
    });
  return `<?xml version="1.0" encoding="UTF-8"?>\n<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${items.join('\n')}\n</sitemapindex>\n`;
}

/** One sitemap file: the article versions in one language, or every other public page. */
export function sitemapXml(siteUrl: string, part: SitemapPart, data: SitemapData): string {
  const base = origin(siteUrl);
  const urls = entriesOf(part, data).map((entry) => {
    const lastModified = isoDate(entry.lastModified);
    return `  <url><loc>${escapeXml(base + entry.path)}</loc>${lastModified ? `<lastmod>${lastModified}</lastmod>` : ''}</url>`;
  });
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.join('\n')}\n</urlset>\n`;
}

function entriesOf(part: SitemapPart, data: SitemapData): Entry[] {
  if (part !== 'pages') {
    return data.articles
      .filter((article) => urlLanguage(article.language) === part)
      .map((article) => ({ path: `/${part}/a/${encodeURIComponent(article.slug)}`, lastModified: article.lastModified }));
  }
  return [
    ...STATIC_PATHS.map((path) => ({ path })),
    ...data.writers.map((writer) => ({ path: `/@${encodeURIComponent(writer.username)}`, lastModified: writer.lastModified })),
    ...data.categories.map((category) => ({
      path: `/@${encodeURIComponent(category.username)}/c/${encodeURIComponent(category.slug)}`,
      lastModified: category.lastModified,
    })),
    ...data.fields.map((field) => ({ path: `/f/${encodeURIComponent(field.slug)}`, lastModified: field.lastModified })),
    ...data.tags.map((tag) => ({ path: `/tags/${encodeURIComponent(tag.slug)}`, lastModified: tag.lastModified })),
    ...data.paths.map((path) => ({ path: `/paths/${encodeURIComponent(path.slug)}`, lastModified: path.lastModified })),
  ];
}

/**
 * Fetches `GET {apiBaseUrl}/sitemap` at most once per `ttlMs` (the API caches it too). Concurrent requests share one
 * fetch; when the API fails, the last good answer is served, and with none the error goes to the caller (503).
 */
export function createSitemapSource(
  apiBaseUrl: string,
  options: { fetch?: typeof fetch; ttlMs?: number; now?: () => number } = {},
): () => Promise<SitemapData> {
  const fetchFn = options.fetch ?? fetch;
  const ttlMs = options.ttlMs ?? 15 * 60 * 1000;
  const now = options.now ?? Date.now;
  let cached: { data: SitemapData; at: number } | null = null;
  let pending: Promise<SitemapData> | null = null;

  const load = async (): Promise<SitemapData> => {
    const response = await fetchFn(`${apiBaseUrl}/sitemap`, {
      headers: { accept: 'application/json' },
      signal: AbortSignal.timeout(20_000),
    });
    if (!response.ok) throw new Error(`GET /sitemap answered ${response.status}`);
    return (await response.json()) as SitemapData;
  };

  return async () => {
    const at = now();
    if (cached && at - cached.at < ttlMs) return cached.data;
    pending ??= load().finally(() => (pending = null));
    try {
      const data = await pending;
      cached = { data, at };
      return data;
    } catch (error) {
      if (cached) return cached.data;
      throw error;
    }
  };
}

function origin(siteUrl: string): string {
  return siteUrl.replace(/\/+$/, '');
}

function isoDate(value: string | null | undefined): string | null {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function newest(values: (string | null | undefined)[]): string | null {
  const times = values.map((value) => isoDate(value)).filter((value): value is string => value !== null);
  return times.length > 0 ? times.reduce((a, b) => (a > b ? a : b)) : null;
}

function escapeXml(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
}
