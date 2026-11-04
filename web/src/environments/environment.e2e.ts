import { environment as development } from './environment.development';
import { AppEnvironment } from './environment.model';

/** Defined by playwright.config.ts (`ng serve --define`) when the suite runs on other ports. */
declare const ngE2eAppPort: number | undefined;
declare const ngE2eMockPort: number | undefined;
const APP_PORT = typeof ngE2eAppPort === 'number' ? ngE2eAppPort : 4280;
const MOCK_PORT = typeof ngE2eMockPort === 'number' ? ngE2eMockPort : 5180;

/**
 * Playwright (`npm run e2e`): the development build against the mock API (e2e/mock-api/server.mjs) on its own port,
 * so the suite never talks to a local backend or dev server that is already running on :5080 / :4200.
 */
export const environment: AppEnvironment = {
  ...development,
  siteUrl: `http://localhost:${APP_PORT}`,
  apiBaseUrl: `http://localhost:${MOCK_PORT}/api/v1`,
  assetsBaseUrl: `http://localhost:${MOCK_PORT}`,
};
