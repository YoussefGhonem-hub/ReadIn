import { expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, useVariant } from './support/mock-api';
import { NOTIFICATIONS_NOW, notificationsOf, signInAsNotifiedReader } from './support/notifications';

/**
 * The repost notification (F29, `article_reposted`) in ar/light and en/dark: the row in the notification center and in
 * the bell's dropdown ("{name} reposted your article", "{name} and N others…", the reposter's avatar with the repost
 * icon, the article's title, a link to the article), and its type in Settings → Notifications ("Reposts"). The mock
 * API (e2e/mock-api/notifications.mjs) gives `u-notified-repost-*` readers two repost entries on top of their 25.
 */
test.describe.configure({ timeout: 120_000 });

const FIRST_RENDER_MS = 30_000;

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`notifications: a repost of your article — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOTIFICATIONS_NOW);
    const me = await signInAsNotifiedReader(page, request, variant, 'u-notified-repost');

    await page.goto('/notifications');
    const single = page.locator('[data-notification="n-repost"]');
    const group = page.locator('[data-notification="n-reposts"]');
    await expect(single).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(single).toHaveAttribute('data-type', 'article_reposted');
    await expect(single.locator('[data-notification-text]')).toHaveText(ar ? 'Karim Hassan أعاد نشر مقالك' : 'Karim Hassan reposted your article');
    // The reposter's name is bold and isolated; the article's title in its own language and direction.
    await expect(single.locator('[data-notification-text] strong bdi')).toHaveText('Karim Hassan');
    await expect(single.locator('[data-notification-article]')).toHaveText('يعني إيه Dependency Injection في ASP.NET Core؟');
    await expect(single.locator('[data-notification-article]')).toHaveAttribute('lang', 'ar-EG');
    await expect(single.locator('[data-notification-comment]')).toHaveCount(0);
    // An avatar (the reposter's initial: no photo) with the repost icon on it.
    await expect(single.locator('rd-avatar')).toBeVisible();
    await expect(single.locator('svg[class*="repeat"]')).toBeVisible();
    await expect(single).toHaveAttribute('href', '/ar/a/dependency-injection-ar');
    await expect(group.locator('[data-notification-text]')).toHaveText(
      ar ? 'سلمى إبراهيم و4 غيره أعادوا نشر مقالك' : 'سلمى إبراهيم and 4 others reposted your article',
    );
    await expect(group).toHaveAttribute('href', /\/a\/clean-architecture-whiteboard$/);
    await parkMouse(page);
    if (hasScreenshot(variant)) {
      await expect(page.locator('[data-section="today"] [data-notification]').first()).toBeVisible();
      await expect(single).toHaveScreenshot(`notification-repost-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    }

    // The same row in the bell's dropdown.
    await page.goto('/settings');
    const bell = page.locator('rd-top-bar [data-notifications-link]:visible');
    await expect(bell).toBeVisible({ timeout: FIRST_RENDER_MS });
    await bell.click();
    const dropdown = page.locator('[data-notifications-dropdown]:visible');
    const inMenu = dropdown.locator('[data-notification="n-repost"]');
    await expect(inMenu.locator('[data-notification-text]')).toHaveText(ar ? 'Karim Hassan أعاد نشر مقالك' : 'Karim Hassan reposted your article', {
      timeout: FIRST_RENDER_MS,
    });

    // A tap marks it read and opens the article.
    await inMenu.click();
    await page.waitForURL((url) => url.pathname === '/ar/a/dependency-injection-ar');
    await expect.poll(async () => (await notificationsOf(request, me.id)).read).toContain('n-repost');

    // Settings → Notifications: "Reposts" is a type of its own, All by default; Off is saved with only that type.
    await page.goto('/settings/notifications');
    const type = page.locator('[data-notification-type="article_reposted"]');
    await expect(type).toHaveAttribute('data-mode', 'all', { timeout: FIRST_RENDER_MS });
    await expect(type).toContainText(ar ? 'إعادة النشر' : 'Reposts');
    await expect(type).toContainText(ar ? 'لما حد يعيد نشر مقالك' : 'When someone reposts your article');
    await expect(page.locator('[data-notification-type]').last()).toHaveAttribute('data-notification-type', 'article_reposted');
    await type.getByRole('radio', { name: ar ? 'مقفول' : 'Off' }).click();
    await expect(type).toHaveAttribute('data-mode', 'off');
    await expect
      .poll(async () => (await notificationsOf(request, me.id)).puts.at(-1))
      .toEqual({ quietHours: { enabled: true, start: '23:00', end: '07:00' }, types: { article_reposted: 'off' } });
    await page.reload();
    await expect(page.locator('[data-notification-type="article_reposted"]')).toHaveAttribute('data-mode', 'off', { timeout: FIRST_RENDER_MS });
  });
}
