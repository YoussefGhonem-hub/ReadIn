import {
  AngularNodeAppEngine,
  createNodeRequestHandler,
  isMainModule,
  writeResponseToNodeResponse,
} from '@angular/ssr/node';
import express from 'express';
import { join } from 'node:path';
import { environment } from './environments/environment';
import { appLinksConfig, appleAppSiteAssociation, assetLinks } from './server/app-links';
import { LEGAL_STATIC_PAGES, legalStaticFile } from './server/legal-pages';
import { SITEMAP_FILES, SitemapData, createSitemapSource, robotsTxt, sitemapIndexXml, sitemapXml } from './server/sitemap';

const browserDistFolder = join(import.meta.dirname, '../browser');

const app = express();
const angularApp = new AngularNodeAppEngine();

/**
 * App Links and Universal Links (SPEC F24, docs/setup/app-links.md): Android and iOS read these files before they let
 * the app open this domain's article links. Built from the environment (ANDROID_APP_ID, ANDROID_CERT_SHA256,
 * IOS_APP_IDS), served as JSON at their exact paths with no redirect; 404 while unconfigured.
 */
const appLinks = appLinksConfig(process.env);
for (const value of appLinks.ignored) console.warn(`App links: ignored ${value}`);
const wellKnown = (body: unknown) => (_req: express.Request, res: express.Response) => {
  if (body === null) {
    res.status(404).end();
    return;
  }
  res.set('Cache-Control', 'public, max-age=3600').type('application/json').send(JSON.stringify(body));
};
app.get('/.well-known/assetlinks.json', wellKnown(assetLinks(appLinks)));
app.get('/.well-known/apple-app-site-association', wellKnown(appleAppSiteAssociation(appLinks)));

/**
 * Search engines (SPEC §23, server/sitemap.ts): robots.txt and the sitemaps, built on this build's `siteUrl` from the
 * API's list of public pages (cached here 15 minutes). 503 while the API has never answered.
 */
app.get('/robots.txt', (_req, res) => {
  res.set('Cache-Control', 'public, max-age=3600').type('text/plain').send(robotsTxt(environment.siteUrl));
});
const sitemapData = createSitemapSource(environment.apiBaseUrl);
const sitemap = (build: (data: SitemapData) => string) => async (_req: express.Request, res: express.Response) => {
  try {
    const xml = build(await sitemapData());
    res.set('Cache-Control', 'public, max-age=900').type('application/xml').send(xml);
  } catch (error) {
    console.error('Sitemap: the API did not answer', error);
    res.status(503).set('Retry-After', '600').end();
  }
};
app.get(SITEMAP_FILES.index, sitemap((data) => sitemapIndexXml(environment.siteUrl, data)));
app.get(SITEMAP_FILES.ar, sitemap((data) => sitemapXml(environment.siteUrl, 'ar', data)));
app.get(SITEMAP_FILES.en, sitemap((data) => sitemapXml(environment.siteUrl, 'en', data)));
app.get(SITEMAP_FILES.pages, sitemap((data) => sitemapXml(environment.siteUrl, 'pages', data)));

/**
 * The privacy policy and "Delete your account" (server/legal-pages.ts): the static pages from the repo's public/,
 * served here as they are, so the apps and the stores open them on this domain. Short cache: the text changes with the
 * policy.
 */
for (const path of LEGAL_STATIC_PAGES) {
  app.get(path, (_req, res, next) => {
    res.set('Cache-Control', 'public, max-age=600');
    res.sendFile(legalStaticFile(path), { root: browserDistFolder }, (error) => error && next(error));
  });
}

/**
 * Serve static files from /browser
 */
app.use(
  express.static(browserDistFolder, {
    maxAge: '1y',
    index: false,
    redirect: false,
  }),
);

/**
 * Handle all other requests by rendering the Angular application.
 */
app.use((req, res, next) => {
  angularApp
    .handle(req)
    .then((response) =>
      response ? writeResponseToNodeResponse(response, res) : next(),
    )
    .catch(next);
});

/**
 * Start the server if this module is the main entry point, or it is ran via PM2.
 * The server listens on the port defined by the `PORT` environment variable, or defaults to 4000.
 */
if (isMainModule(import.meta.url) || process.env['pm_id']) {
  const port = process.env['PORT'] || 4000;
  app.listen(port, (error) => {
    if (error) {
      throw error;
    }

    console.log(`Node Express server listening on http://localhost:${port}`);
  });
}

/**
 * Request handler used by the Angular CLI (for dev-server and during build) or Firebase Cloud Functions.
 */
export const reqHandler = createNodeRequestHandler(app);
