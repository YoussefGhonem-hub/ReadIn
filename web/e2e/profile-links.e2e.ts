import { expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, onApi, parkMouse, problem, reply, useVariant } from './support/mock-api';
import { signInWithLiveProfile } from './support/profile';

/* eslint-disable @typescript-eslint/no-explicit-any -- request bodies are plain JSON */

/**
 * The pre-production step on the profile (F14, F29), against the mock API (e2e/mock-api/profiles.mjs): the links
 * editor of Edit profile (pick a platform, reorder with the keyboard, Other with its own name, each error under its own
 * link, the server's errors by index, at most 8) and a writer's Reposts tab. profile.e2e.ts covers the title and the
 * link icons on the profile itself.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

test('links editor: reorder, Other with a name, the server’s errors by index, at most 8 (ar/light)', async ({ page, context, baseURL, request }) => {
  const variant = VARIANTS[0];
  await useVariant(context, baseURL!, variant);
  await signInWithLiveProfile(page, request, variant, 'fresh');
  const patches: any[] = [];
  page.on('request', (r) => {
    if (r.method() === 'PATCH' && r.url().endsWith('/api/v1/me')) patches.push(r.postDataJSON());
  });

  await page.goto('/settings/profile');
  const form = page.locator('[data-edit-profile-form]');
  await expect(form.locator('#edit-name')).toHaveValue('Sara Hassan', { timeout: FIRST_RENDER_MS });
  const rows = form.locator('[data-link-row]');
  await expect(rows).toHaveCount(0);
  const add = async (platform: string) => {
    await form.locator('[data-add-link]').click();
    const picker = form.locator('[data-link-picker]');
    await expect(picker).toBeVisible();
    await picker.locator(`[data-pick-platform="${platform}"]`).click();
  };

  // The picker, keyboard first: Enter opens it on the first platform, Enter picks it and the link's field takes the focus.
  await form.locator('[data-add-link]').focus();
  await page.keyboard.press('Enter');
  await expect(form.locator('[data-pick-platform="linkedin"]')).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(rows.nth(0).locator('[data-link-url]')).toBeFocused();
  await page.keyboard.type('www.linkedin.com/in/sara-hassan');
  await add('github');
  await rows.nth(1).locator('[data-link-url]').fill('https://github.com/sara-hassan');
  await add('other');
  // Other asks for its name first.
  await expect(rows.nth(2).locator('[data-link-label]')).toBeFocused();
  await page.keyboard.type('البودكاست');
  await rows.nth(2).locator('[data-link-url]').fill('podcasts.example/sara');
  // One link per named platform; Other may repeat.
  await form.locator('[data-add-link]').click();
  await expect(form.locator('[data-pick-platform="linkedin"]')).toBeDisabled();
  await expect(form.locator('[data-pick-platform="github"]')).toBeDisabled();
  await expect(form.locator('[data-pick-platform="other"]')).toBeEnabled();
  await form.locator('[data-link-picker-cancel]').click();
  await expect(form.locator('[data-add-link]')).toBeFocused();

  // Move Other to the top with the keyboard: the focus stays on the moved link.
  await rows.nth(2).locator('[data-link-up]').focus();
  await page.keyboard.press('Enter');
  await expect(rows.nth(1)).toHaveAttribute('data-platform', 'other');
  await expect(rows.nth(1).locator('[data-link-up]')).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(rows.nth(0)).toHaveAttribute('data-platform', 'other');
  await expect(rows.nth(0).locator('[data-link-up]')).toBeDisabled();
  await expect(rows.nth(0).locator('[data-link-down]')).toBeFocused();
  await expect(rows.nth(0).locator('[data-link-remove]')).toHaveAttribute('aria-label', 'إزالة رابط البودكاست');

  // A link on the wrong site and a name that's too short: each message under its own field, nothing is sent.
  await rows.nth(2).locator('[data-link-url]').fill('https://gitlab.com/sara');
  await rows.nth(0).locator('[data-link-label]').fill('ب');
  await form.locator('[data-submit]').click();
  await expect(rows.nth(2).locator('[data-link-error="url"]')).toHaveText('هذا الرابط لا ينتمي إلى المنصة التي اخترتها.');
  await expect(rows.nth(0).locator('[data-link-error="label"]')).toHaveText('يجب أن يتكون اسم الرابط من 2 إلى 30 حرفًا في سطر واحد.');
  await expect(rows.nth(0).locator('[data-link-label]')).toBeFocused();
  await expect(rows.nth(1).locator('[data-link-error="url"]')).toHaveCount(0);
  expect(patches).toHaveLength(0);
  await rows.nth(0).locator('[data-link-label]').fill('البودكاست');
  await rows.nth(2).locator('[data-link-url]').fill('https://github.com/sara-hassan');

  // What the server refuses lands under the link it names (links[1].url), and goes once that link changes.
  let refused = false;
  await onApi(page, 'PATCH', '/me', (route) => {
    if (refused) return route.fallback();
    refused = true;
    return reply(route, 400, problem(400, 'validation.failed', { 'links[1].url': ['link.url_invalid'] }));
  });
  await form.locator('[data-submit]').click();
  await expect(rows.nth(1).locator('[data-link-error="url"]')).toHaveText('هذا الرابط غير صالح.');
  await expect(rows.nth(1).locator('[data-link-url]')).toBeFocused();
  await expect(rows.nth(1).locator('[data-link-url]')).toHaveAttribute('aria-invalid', 'true');
  await expect(page.locator('[data-error]')).toHaveCount(0);
  await parkMouse(page);
  const editor = form.locator('rd-links-editor');
  await editor.scrollIntoViewIfNeeded();
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
  await expect(editor).toHaveScreenshot('links-editor-errors-ar-light.png', { stylePath: HIDE_APP_CHROME });
  await rows.nth(1).locator('[data-link-url]').fill('https://www.linkedin.com/in/sara-hassan');
  await expect(rows.nth(1).locator('[data-link-error="url"]')).toHaveCount(0);

  // Saved: the whole list in this order, Other with its name, a bare link with https://; no title (null).
  await form.locator('[data-submit]').click();
  await page.waitForURL('**/@sara');
  expect(patches.at(-1).links).toEqual([
    { platform: 'other', url: 'https://podcasts.example/sara', label: 'البودكاست' },
    { platform: 'linkedin', url: 'https://www.linkedin.com/in/sara-hassan' },
    { platform: 'github', url: 'https://github.com/sara-hassan' },
  ]);
  expect(patches.at(-1).headline).toBeNull();
  const header = page.locator('[data-profile-header]');
  await expect(header.locator('[data-profile-link]')).toHaveCount(3, { timeout: FIRST_RENDER_MS });
  expect(await header.locator('[data-profile-link]').evaluateAll((all) => all.map((a) => a.getAttribute('aria-label')))).toEqual(['البودكاست', 'LinkedIn', 'GitHub']);

  // At most 8: after five more there is no "Add link" any more.
  await header.locator('[data-edit-profile]').click();
  await expect(rows).toHaveCount(3, { timeout: FIRST_RENDER_MS });
  for (const platform of ['x', 'instagram', 'youtube', 'website', 'other']) await add(platform);
  await expect(rows).toHaveCount(8);
  await expect(form.locator('[data-add-link]')).toHaveCount(0);
  await expect(form.locator('[data-links-full]')).toContainText('8');
});

test('Reposts tab: a writer’s reposts as post cards, newest first; Mona has none (en/dark)', async ({ page, context, baseURL }) => {
  const variant = VARIANTS[1];
  await useVariant(context, baseURL!, variant);
  await page.clock.setFixedTime(new Date('2026-11-04T09:00:00Z'));
  await page.goto('/@karim');
  await expect(page.locator('[data-profile-header]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  await expect(page.locator('[data-profile-headline]')).toHaveText('Frontend lead · React & Angular');
  const reposts = page.waitForResponse((r) => new URL(r.url()).pathname.endsWith('/users/karim/reposts'));
  await page.locator('[data-profile-tab="reposts"]').click();
  await expect(page.locator('[data-profile-tab="reposts"]')).toHaveAttribute('aria-selected', 'true');
  expect((await reposts).status()).toBe(200);
  const cards = page.locator('[data-profile-reposts] rd-post-card');
  await expect(cards).toHaveCount(2, { timeout: FIRST_RENDER_MS });
  // Newest repost first: the sleep article (Nov 3), then the transformer one (Nov 2), each by its own author.
  await expect(cards.nth(0)).toContainText(/sleep/i);
  await expect(cards.nth(1)).toContainText('Transformer');
  await expect(page.locator('[data-reposts-end]')).toBeVisible();

  await page.goto('/@mona');
  await expect(page.locator('[data-profile-header]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.locator('[data-profile-tab="reposts"]').click();
  await expect(page.locator('[data-profile-reposts] [data-reposts-empty]')).toContainText('No reposts yet', { timeout: FIRST_RENDER_MS });
});
