import { SitemapData, createSitemapSource, robotsTxt, sitemapIndexXml, sitemapXml, urlLanguage } from './sitemap';

const SITE = 'https://readin.online/';

const DATA: SitemapData = {
  articles: [
    { slug: 'clean-architecture', language: 'en', lastModified: '2026-11-05T10:00:00Z' },
    { slug: 'clean-architecture', language: 'ar-EG', lastModified: '2026-11-05T10:00:00Z' },
    { slug: 'الذكاء-الاصطناعي', language: 'ar-EG', lastModified: '2026-11-06T08:30:00Z' },
  ],
  writers: [{ username: 'readin', lastModified: '2026-11-06T08:30:00Z' }],
  categories: [{ username: 'readin', slug: 'ai & ml', lastModified: '2026-11-04T00:00:00Z' }],
  fields: [{ slug: 'dotnet', lastModified: null }],
  tags: [{ slug: 'البرمجة', lastModified: '2026-11-03T00:00:00Z' }],
  paths: [{ slug: 'llms', lastModified: '2026-11-01T00:00:00Z' }],
};

describe('search engines (SPEC §23)', () => {
  it('robots.txt keeps crawlers out of private pages and points to the sitemap', () => {
    const robots = robotsTxt(SITE);
    expect(robots).toContain('User-agent: *\nAllow: /\n');
    for (const path of ['/auth/', '/settings', '/write', '/saved', '/search', '/admin/']) {
      expect(robots).toContain(`Disallow: ${path}\n`);
    }
    expect(robots).toContain('Sitemap: https://readin.online/sitemap.xml\n');
    expect(robots).not.toMatch(/^Disallow: \/$/m);
  });

  it('maps an article version to its URL language like urlLangFor', () => {
    expect(urlLanguage('en')).toBe('en');
    expect(urlLanguage('ar-EG')).toBe('ar');
  });

  it('splits the articles per language, one URL per version, escaped and with lastmod', () => {
    const arabic = sitemapXml(SITE, 'ar', DATA);
    expect(arabic).toContain('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    expect(arabic).toContain(
      '<url><loc>https://readin.online/ar/a/clean-architecture</loc><lastmod>2026-11-05T10:00:00.000Z</lastmod></url>',
    );
    expect(arabic).toContain(`https://readin.online/ar/a/${encodeURIComponent('الذكاء-الاصطناعي')}</loc>`);
    expect(arabic).not.toContain('/en/a/');

    const english = sitemapXml(SITE, 'en', DATA);
    expect(english.match(/<url>/g)).toHaveLength(1);
    expect(english).toContain('<loc>https://readin.online/en/a/clean-architecture</loc>');
  });

  it('lists home, Explore, the paths, writers, categories, fields and tags in the pages file', () => {
    const pages = sitemapXml(SITE, 'pages', DATA);
    for (const loc of [
      'https://readin.online/</loc>',
      'https://readin.online/explore</loc>',
      'https://readin.online/paths</loc>',
      'https://readin.online/@readin</loc>',
      'https://readin.online/@readin/c/ai%20%26%20ml</loc>',
      'https://readin.online/f/dotnet</loc>',
      `https://readin.online/tags/${encodeURIComponent('البرمجة')}</loc>`,
      'https://readin.online/paths/llms</loc>',
    ]) {
      expect(pages).toContain(loc);
    }
    expect(pages).toContain('<loc>https://readin.online/f/dotnet</loc></url>');
    expect(pages).not.toContain('/a/');
  });

  it('escapes what XML reserves', () => {
    const data: SitemapData = { ...DATA, categories: [{ username: "o'neil", slug: 'x', lastModified: '2026-11-04T00:00:00Z' }] };
    expect(sitemapXml(SITE, 'pages', data)).toContain('https://readin.online/@o&apos;neil/c/x</loc>');
  });

  it('indexes the files that have entries, each with its newest lastmod', () => {
    const index = sitemapIndexXml(SITE, DATA);
    expect(index).toContain('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    expect(index).toContain('<loc>https://readin.online/sitemap-ar.xml</loc><lastmod>2026-11-06T08:30:00.000Z</lastmod>');
    expect(index).toContain('<loc>https://readin.online/sitemap-en.xml</loc><lastmod>2026-11-05T10:00:00.000Z</lastmod>');
    expect(index).toContain('<loc>https://readin.online/sitemap-pages.xml</loc>');

    const noEnglish = sitemapIndexXml(SITE, { ...DATA, articles: DATA.articles.filter((a) => a.language !== 'en') });
    expect(noEnglish).not.toContain('sitemap-en.xml');
    expect(noEnglish).toContain('sitemap-pages.xml');
  });

  describe('createSitemapSource', () => {
    const ok = (data: SitemapData) => Promise.resolve(new Response(JSON.stringify(data), { status: 200 }));

    it('asks the API once per cache period and shares a request in flight', async () => {
      let calls = 0;
      let time = 0;
      const source = createSitemapSource('https://api.readin.online/api/v1', {
        fetch: ((url: string) => {
          calls++;
          expect(url).toBe('https://api.readin.online/api/v1/sitemap');
          return ok(DATA);
        }) as typeof fetch,
        ttlMs: 1000,
        now: () => time,
      });

      await Promise.all([source(), source()]);
      expect(calls).toBe(1);
      time = 500;
      await source();
      expect(calls).toBe(1);
      time = 1500;
      expect((await source()).writers[0].username).toBe('readin');
      expect(calls).toBe(2);
    });

    it('keeps serving the last answer when the API fails, and fails with none', async () => {
      let fail = false;
      let time = 0;
      const source = createSitemapSource('https://api', {
        fetch: (() => (fail ? Promise.resolve(new Response('', { status: 503 })) : ok(DATA))) as typeof fetch,
        ttlMs: 10,
        now: () => time,
      });
      await source();
      fail = true;
      time = 100;
      expect((await source()).articles).toHaveLength(3);

      const empty = createSitemapSource('https://api', {
        fetch: (() => Promise.resolve(new Response('', { status: 500 }))) as typeof fetch,
      });
      await expect(empty()).rejects.toThrow('GET /sitemap answered 500');
    });
  });
});
