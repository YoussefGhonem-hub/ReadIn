import { environment as development } from './environment.development';
import { AppEnvironment } from './environment.model';

/**
 * Playwright (`npm run e2e`): the development build against the mock API (e2e/mock-api/server.mjs) on its own port,
 * so the suite never talks to a local backend or dev server that is already running on :5080 / :4200.
 */
export const environment: AppEnvironment = {
  ...development,
  siteUrl: 'http://localhost:4280',
  apiBaseUrl: 'http://localhost:5180/api/v1',
  assetsBaseUrl: 'http://localhost:5180',
};
