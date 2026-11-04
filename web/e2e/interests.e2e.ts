import { randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, restoreSessionAs, useVariant, writerMe } from './support/mock-api';

/**
 * Settings → Your interests (F12) in ar/en × light/dark: the fields and topics you follow after onboarding, with the
 * same chips as onboarding. Every tap is saved at once (`PUT`/`DELETE /me/interests/…`); the API keeps at least 3, and a
 * refusal undoes the tap. The mock API keeps each reader's interests (e2e/mock-api/social.mjs) and reports them in
 * `GET /me`, so every test signs in as its own reader.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`settings → your interests: follow and unfollow at once, at least 3 — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // Every reader starts like the mock: Software, with its two topics (.NET and Architecture).
    const me = await writerMe(request, variant, {
      id: `u-viewer-${randomUUID().slice(0, 8)}`,
      displayName: 'Sara Hassan',
      username: 'sara',
      isVerified: false,
      roles: ['Member'],
      permissions: ['articles.read', 'follows.manage'],
      interests: { fieldIds: ['f-software'], topicIds: ['t-dotnet', 't-architecture'] },
    });
    await restoreSessionAs(page, me);
    const saves: string[] = [];
    page.on('request', (r) => {
      if (/\/api\/v1\/me\/interests\//.test(r.url()) && r.method() !== 'OPTIONS') saves.push(`${r.method()} ${new URL(r.url()).pathname.replace('/api/v1/me/interests/', '')}`);
    });

    await page.goto('/settings');
    const row = page.locator('[data-settings-interests]');
    await expect(row).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(row).toContainText(t('اهتماماتك', 'Your interests'));
    await row.click();
    await page.waitForURL((url) => url.pathname === '/settings/interests');
    await expect(page).toHaveTitle(t('اهتماماتك — ReadIn', 'Your interests — ReadIn'));

    const field = (id: string) => page.locator(`[data-interest-field="${id}"]`);
    const topic = (id: string) => page.locator(`[data-interest-topic="${id}"]`);
    const count = page.locator('[data-interest-count]');
    await expect(field('f-software')).toHaveAttribute('aria-pressed', 'true', { timeout: FIRST_RENDER_MS });
    await expect(field('f-medicine')).toHaveAttribute('aria-pressed', 'false');
    await expect(topic('t-dotnet')).toHaveAttribute('aria-pressed', 'true');
    await expect(topic('t-architecture')).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText(t('متابع 3 اهتمامات', 'Following 3 interests'));
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-interests-page')).toHaveScreenshot(`interests-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Follow a field, unfollow a topic: each saved at once.
    await field('f-medicine').click();
    await expect(field('f-medicine')).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText(t('متابع 4 اهتمامات', 'Following 4 interests'));
    await expect(field('f-medicine')).not.toHaveAttribute('aria-busy', 'true');
    await topic('t-dotnet').click();
    await expect(topic('t-dotnet')).toHaveAttribute('aria-pressed', 'false');
    await expect(count).toHaveText(t('متابع 3 اهتمامات', 'Following 3 interests'));
    await expect(topic('t-dotnet')).not.toHaveAttribute('aria-busy', 'true');
    expect(saves).toEqual(['PUT fields/f-medicine', 'DELETE topics/t-dotnet']);

    // A fourth tap would leave 2: the API refuses, the chip comes back, and the page says why.
    await topic('t-architecture').click();
    await expect(page.locator('rd-toast-host')).toContainText(t('خليك متابع 3 اهتمامات على الأقل', 'Keep at least 3 interests'));
    await expect(topic('t-architecture')).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText(t('متابع 3 اهتمامات', 'Following 3 interests'));

    // Saved on the account: back to Settings and in again (a fresh GET /me), the page shows the same.
    await page.locator('[data-back-to-settings]').click();
    await page.waitForURL((url) => url.pathname === '/settings');
    await row.click();
    await expect(field('f-medicine')).toHaveAttribute('aria-pressed', 'true', { timeout: FIRST_RENDER_MS });
    await expect(topic('t-dotnet')).toHaveAttribute('aria-pressed', 'false');
    await expect(topic('t-architecture')).toHaveAttribute('aria-pressed', 'true');
  });

  test(`settings → your interests is for signed-in readers — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/settings');
    await expect(page.locator('h1')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-settings-interests]')).toHaveCount(0);
    await page.goto('/settings/interests');
    await page.waitForURL((url) => url.pathname.startsWith('/auth'));
  });
}
