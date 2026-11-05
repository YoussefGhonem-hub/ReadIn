import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, useVariant } from './support/mock-api';
import { signInAsModerator } from './support/moderation';

/**
 * A reported user's title and social links (F14, pre-production step) on their moderation case, in ar/light and
 * en/dark: the case shows the title and every link (the whole address), and the SuperAdmin clears them with
 * "امسح المسمى" / "امسح الروابط" (`clear_headline`, `clear_links`), each confirmed in the sheet with an optional note;
 * the open reports are resolved and the history logs it. The mock API (e2e/mock-api/moderation.mjs) gives u-reader-21
 * an abusive title and two spam links, per moderator.
 */
test.describe.configure({ timeout: 120_000 });

const FIRST_RENDER_MS = 30_000;

async function confirm(page: Page, note: string | null, toast: string): Promise<void> {
  const sheet = page.locator('[data-moderation-sheet]');
  await expect(sheet).toBeVisible();
  if (note) await sheet.locator('[data-moderation-note]').fill(note);
  await sheet.locator('[data-moderation-confirm]').click();
  await expect(sheet).toHaveCount(0);
  await expect(page.locator('rd-toast-host')).toContainText(toast);
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`moderation: clear a reported user's title and links — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsModerator(page, request, variant);
    const actions: unknown[] = [];
    page.on('request', (r) => {
      if (r.method() === 'POST' && r.url().endsWith('/moderation/actions')) actions.push(r.postDataJSON());
    });

    await page.goto('/moderation/user/u-reader-21');
    await expect(page.locator('[data-case-target]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    const section = page.locator('[data-case-profile]');
    await expect(section.locator('#case-profile-title')).toHaveText(ar ? 'المسمى والروابط' : 'Title and links');
    await expect(section.locator('[data-case-headline]')).toHaveText('بيع متابعين ولايكات | كلمني واتساب');
    await expect(section.locator('[data-case-headline]')).toHaveAttribute('dir', 'rtl');
    const links = section.locator('[data-case-link]');
    await expect(links).toHaveCount(2);
    await expect(links.nth(0)).toHaveAttribute('data-case-link', 'instagram');
    await expect(links.nth(0)).toContainText('Instagram');
    await expect(links.nth(1)).toContainText('اشتري متابعين');
    // The whole address, left to right, never followed by crawlers.
    await expect(links.nth(0).locator('[data-case-link-url]')).toHaveText('https://instagram.com/cheap.followers');
    await expect(links.nth(0).locator('[data-case-link-url]')).toHaveAttribute('dir', 'ltr');
    await expect(links.nth(0).locator('[data-case-link-url]')).toHaveAttribute('rel', /nofollow/);
    await parkMouse(page);
    await section.scrollIntoViewIfNeeded();
    if (hasScreenshot(variant)) await expect(section).toHaveScreenshot(`moderation-case-profile-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Clear title: confirmed first; Cancel sends nothing.
    await section.locator('[data-case-clear-headline]').click();
    const sheet = page.locator('[data-moderation-sheet]');
    await expect(sheet).toHaveAttribute('data-moderation-action', 'clear_headline');
    await expect(sheet.locator('#moderation-sheet-title')).toContainText(ar ? 'تمسح مسمى' : 'Clear');
    await expect(sheet.locator('#moderation-sheet-body')).toContainText(ar ? 'مش هيوصله إشعار' : "isn't notified");
    // The note is optional.
    await expect(sheet.locator('[data-moderation-confirm]')).toBeEnabled();
    await sheet.getByRole('button', { name: ar ? 'إلغاء' : 'Cancel', exact: true }).click();
    await expect(sheet).toHaveCount(0);
    expect(actions).toHaveLength(0);

    await section.locator('[data-case-clear-headline]').click();
    await confirm(page, null, ar ? 'المسمى اتمسح' : 'Title cleared');
    expect(actions).toEqual([{ action: 'clear_headline', targetType: 'user', targetId: 'u-reader-21' }]);
    await expect(section.locator('[data-case-no-headline]')).toHaveText(ar ? 'مفيش مسمى.' : 'No title.');
    await expect(section.locator('[data-case-clear-headline]')).toHaveCount(0);
    // The user's open report is resolved, and the history says what was removed.
    await expect(page.locator('[data-case-status]')).toHaveText(ar ? 'اتحل' : 'Resolved');
    const history = page.locator('[data-case-history] [data-log-entry]');
    await expect(history.first()).toHaveAttribute('data-log-action', 'user.clear_headline');
    await expect(history.first()).toContainText(ar ? 'مسح مسمى مستخدم' : "cleared a user's title");
    await expect(history.first()).toContainText('بيع متابعين ولايكات | كلمني واتساب');

    // Clear links, with a note.
    await section.locator('[data-case-clear-links]').click();
    await expect(page.locator('[data-moderation-sheet]')).toHaveAttribute('data-moderation-action', 'clear_links');
    await confirm(page, 'Spam links', ar ? 'الروابط اتمسحت' : 'Links cleared');
    expect(actions.at(-1)).toEqual({ action: 'clear_links', targetType: 'user', targetId: 'u-reader-21', note: 'Spam links' });
    await expect(section.locator('[data-case-no-links]')).toHaveText(ar ? 'مفيش روابط.' : 'No links.');
    await expect(section.locator('[data-case-clear-links]')).toHaveCount(0);
    await expect(history.first()).toHaveAttribute('data-log-action', 'user.clear_links');
    await expect(history.first()).toContainText('Spam links');
    await expect(history.first()).toContainText('https://instagram.com/cheap.followers https://cheap-followers.example/buy');
  });
}
