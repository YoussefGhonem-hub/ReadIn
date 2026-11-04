import { defineConfig, devices } from '@playwright/test';

/**
 * The suite runs on its own ports, so a local API on :5080 or `npm start` on :4200 can keep running. Another checkout
 * running the suite at the same time picks others: `E2E_APP_PORT=4310 E2E_MOCK_PORT=5310 npm run e2e` (the app gets
 * them through `--define`, see src/environments/environment.e2e.ts).
 */
const APP_PORT = Number(process.env['E2E_APP_PORT'] ?? 4280);
const MOCK_API_PORT = Number(process.env['E2E_MOCK_PORT'] ?? 5180);

/**
 * E2E + visual tests (SPEC §27): every screen is captured in ar/en × light/dark.
 * Run: `npm run e2e`. It starts the mock API (e2e/mock-api/server.mjs) on :5180, which answers SSR and browser calls
 * with fixtures, and `ng serve --configuration e2e` on :4280 (the development build pointed at the mock, see
 * src/environments/environment.e2e.ts).
 */
export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.e2e.ts',
  fullyParallel: true,
  forbidOnly: !!process.env['CI'],
  retries: process.env['CI'] ? 2 : 0,
  reporter: process.env['CI'] ? [['html', { open: 'never' }], ['github']] : 'list',
  expect: { toHaveScreenshot: { maxDiffPixelRatio: 0.01, animations: 'disabled' } },
  use: {
    baseURL: process.env['E2E_BASE_URL'] ?? `http://localhost:${APP_PORT}`,
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['Pixel 7'] } },
  ],
  webServer: process.env['E2E_BASE_URL']
    ? undefined
    : [
        {
          command: 'node e2e/mock-api/server.mjs',
          env: { MOCK_API_PORT: String(MOCK_API_PORT) },
          // Anything else on that port answers 404 here, so Playwright never mistakes it for the mock.
          url: `http://localhost:${MOCK_API_PORT}/__mock/health`,
          reuseExistingServer: !process.env['CI'],
          timeout: 30_000,
        },
        {
          command: `npx ng serve --configuration e2e --port ${APP_PORT} --define ngE2eAppPort=${APP_PORT} --define ngE2eMockPort=${MOCK_API_PORT}`,
          url: `http://localhost:${APP_PORT}`,
          reuseExistingServer: !process.env['CI'],
          timeout: 180_000,
        },
      ],
});
