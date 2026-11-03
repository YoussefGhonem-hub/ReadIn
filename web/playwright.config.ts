import { defineConfig, devices } from '@playwright/test';

/**
 * E2E + visual tests (SPEC §27): every screen is captured in ar/en × light/dark.
 * Run: `npm run e2e` (starts `ng serve`; point it at a running API on :5080 for real data).
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
    : { command: 'npm start', url: 'http://localhost:4200', reuseExistingServer: !process.env['CI'], timeout: 180_000 },
});
