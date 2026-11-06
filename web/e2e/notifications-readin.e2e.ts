import { expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, useVariant } from './support/mock-api';
import { NOTIFICATIONS_NOW, notificationsOf, signInAsNotifiedReader } from './support/notifications';

/**
 * The official @readin account's articles, one notification per day (leftovers 3, contract-v1 Notifications): the type
 * stays `followed_writer_article`, `data.articleCount` says how many new articles the day holds and `article` is the
 * newest. Two or more read «نشر ReadIn 3 مقالات جديدة» / "ReadIn published 3 new articles" above the newest title and
 * open the account's profile; one reads as any writer's new article and opens it. The mock API
 * (e2e/mock-api/notifications.mjs) gives `u-notified-readin-*` readers both entries on top of their 25.
 */
test.describe.configure({ timeout: 120_000 });

const FIRST_RENDER_MS = 30_000;

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`notifications: the @readin account's articles of the day in one row — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOTIFICATIONS_NOW);
    const me = await signInAsNotifiedReader(page, request, variant, 'u-notified-readin');

    await page.goto('/notifications');
    const day = page.locator('[data-notification="n-readin-day"]');
    const one = page.locator('[data-notification="n-readin-one"]');
    await expect(day).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(day).toHaveAttribute('data-type', 'followed_writer_article');
    // Verb first, the count in its plural form, the account's name bold and isolated; then the newest article's title.
    await expect(day.locator('[data-notification-text]')).toHaveText(ar ? 'نشر ReadIn 3 مقالات جديدة' : 'ReadIn published 3 new articles');
    await expect(day.locator('[data-notification-text] strong bdi')).toHaveText('ReadIn');
    await expect(day.locator('[data-notification-article]')).toHaveText('إزاي الـ streak بيساعدك تقرا كل يوم');
    await expect(day.locator('[data-notification-article]')).toHaveAttribute('lang', 'ar-EG');
    // Two or more articles open the account's profile (its articles, newest first).
    await expect(day).toHaveAttribute('href', '/@readin');
    // One article: the usual line, and the article itself.
    await expect(one.locator('[data-notification-text]')).toHaveText(ar ? 'نشر ReadIn مقالًا جديدًا' : 'ReadIn published a new article');
    await expect(one.locator('[data-notification-article]')).toHaveText('How ReadIn picks your daily article');
    await expect(one).toHaveAttribute('href', '/en/a/how-readin-picks-your-daily-article');
    await parkMouse(page);
    if (hasScreenshot(variant)) {
      await expect(day).toHaveScreenshot(`notification-readin-day-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    }

    // A tap marks it read and opens @readin's profile.
    await day.click();
    await page.waitForURL((url) => url.pathname === '/@readin');
    await expect(page.locator('[data-profile-header] [data-profile-username]')).toHaveText('@readin', { timeout: FIRST_RENDER_MS });
    await expect.poll(async () => (await notificationsOf(request, me.id)).read).toContain('n-readin-day');
  });
}
