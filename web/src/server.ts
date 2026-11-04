import {
  AngularNodeAppEngine,
  createNodeRequestHandler,
  isMainModule,
  writeResponseToNodeResponse,
} from '@angular/ssr/node';
import express from 'express';
import { join } from 'node:path';
import { appLinksConfig, appleAppSiteAssociation, assetLinks } from './server/app-links';

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
