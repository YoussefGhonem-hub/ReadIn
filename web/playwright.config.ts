import { defineConfig, devices } from '@playwright/test';

/**
 * E2E + visual tests (SPEC §27): every screen is captured in ar/en × light/dark.
 * Run: `npm run e2e`. It starts the mock API (e2e/mock-api/server.mjs) on the API's dev address :5080, which answers
 * SSR and browser calls with fixtures, and `ng serve`. Stop a local backend on :5080 first (the mock fails to bind).
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
    baseURL: process.env['E2E_BASE_URL'] ?? 'http://localhost:4200',
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
          // A real API on :5080 answers 404 here, so Playwright never mistakes it for the mock.
          url: 'http://localhost:5080/__mock/health',
          reuseExistingServer: !process.env['CI'],
          timeout: 30_000,
        },
        { command: 'npm start', url: 'http://localhost:4200', reuseExistingServer: !process.env['CI'], timeout: 180_000 },
      ],
});
