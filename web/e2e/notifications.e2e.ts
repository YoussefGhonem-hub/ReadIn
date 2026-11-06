import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, onApi, parkMouse, problem, reply, useVariant } from './support/mock-api';
import { NOTIFICATIONS_NOW, notificationsOf, signInAsNotifiedReader } from './support/notifications';

/**
 * F17 Notifications end to end in ar/en × light/dark: the badge (REST fallback: the Realtime Database isn't there in
 * e2e) clears when the center opens; Today / Earlier with every type (a mention in a comment and one in an article);
 * tapping a row marks it read and opens its link; "Mark all as read"; infinite scroll; Settings → Notifications (a mode
 * per type, quiet hours with validation). The mock API keeps each reader's own notifications
 * (e2e/mock-api/notifications.mjs), so parallel tests never share state.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

async function openCenter(page: Page): Promise<void> {
  await expect(page.locator('[data-notification]').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`center: the badge clears on open; Today / Earlier; a tap marks read and opens — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOTIFICATIONS_NOW);
    const me = await signInAsNotifiedReader(page, request, variant);

    // The badge: 4 unseen.
    await page.goto('/settings');
    // The bell of the bar on screen (the nav row's from md, the compact bar's below).
    const bell = page.locator('rd-top-bar [data-notifications-link]:visible');
    await expect(bell.locator('[data-unread-badge]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(bell).toHaveAttribute('aria-label', ar ? 'الإشعارات، 4 إشعارات جديدة' : 'Notifications, 4 new');
    if (testInfo.project.name === 'desktop') await expect(page.locator('[data-top-nav] [data-notifications-link] [data-unread-badge]')).toBeVisible();

    // Opening the bell's dropdown marks everything seen: the badge clears, on the server too. "See all" opens the center.
    await bell.click();
    const dropdown = page.locator('[data-notifications-dropdown]:visible');
    await expect(dropdown).toBeVisible();
    await dropdown.locator('[data-see-all]').click({ timeout: FIRST_RENDER_MS });
    await page.waitForURL((url) => url.pathname === '/notifications');
    await openCenter(page);
    await expect(bell.locator('[data-unread-badge]')).toHaveCount(0);
    await expect(bell).toHaveAttribute('aria-label', ar ? 'الإشعارات' : 'Notifications');
    await expect.poll(async () => (await notificationsOf(request, me.id)).unseen).toBe(0);

    const today = page.locator('[data-section="today"] [data-notification]');
    await expect(today).toHaveCount(6);
    await expect(page.locator('[data-section="earlier"] [data-notification]')).toHaveCount(14);
    await expect(page.locator('[data-notification][data-unread]')).toHaveCount(5);

    const row = (id: string) => page.locator(`[data-notification="${id}"]`);
    await expect(row('n-comments').locator('[data-notification-text]')).toHaveText(
      ar ? 'علّق Karim Hassan و9 آخرون على مقالك' : 'Karim Hassan and 9 others commented on your article',
    );
    await expect(row('n-comments').locator('[data-notification-article]')).toHaveAttribute('lang', 'ar-EG');
    await expect(row('n-followers').locator('[data-notification-text]')).toHaveText(
      ar ? 'بدأ Omar Fathy وشخصان آخران متابعتك' : 'Omar Fathy and 2 others started following you',
    );
    await expect(row('n-reply').locator('[data-notification-text]')).toHaveText(ar ? 'ردّ مستخدم محذوف على تعليقك' : 'Deleted user replied to your comment');
    // A mention in a comment, with its excerpt; a mention in an article: the article's title, no excerpt, no #comment.
    await expect(row('n-mention').locator('[data-notification-text]')).toHaveText(ar ? 'أشار إليك سلمى إبراهيم في تعليق' : 'سلمى إبراهيم mentioned you in a comment');
    await expect(row('n-mention').locator('[data-notification-comment]')).toHaveCount(1);
    const articleMention = row('n-article-mention');
    await expect(articleMention.locator('[data-notification-text]')).toHaveText(ar ? 'أشار إليك سلمى إبراهيم في مقال' : 'سلمى إبراهيم mentioned you in an article');
    await expect(articleMention.locator('[data-notification-text] bdi')).toHaveText('سلمى إبراهيم');
    await expect(articleMention.locator('[data-notification-article]')).toHaveText('يعني إيه Transformer في الـ AI؟');
    await expect(articleMention.locator('[data-notification-article]')).toHaveAttribute('lang', 'ar-EG');
    await expect(articleMention.locator('[data-notification-comment]')).toHaveCount(0);
    await expect(articleMention).toHaveAttribute('href', '/ar/a/what-is-a-transformer-ar');
    await expect(row('n-milestone').locator('[data-notification-text]')).toHaveText(ar ? 'بلغ مقالك 50 تفاعلًا 🎉' : 'Your article reached 50 reactions 🎉');
    await expect(row('n-security')).toContainText(ar ? 'تم تغيير كلمة مرورك' : 'Your password was changed');
    await expect(row('n-warning')).toContainText(ar ? 'تلقّيت تحذيرًا من فريق الإشراف' : 'You received a warning from the moderators');
    await expect(row('n-followers')).toHaveAttribute('href', '/@sara/followers');
    await expect(row('n-streak')).toHaveAttribute('href', '/me/stats');
    await expect(row('n-security')).toHaveAttribute('href', '/settings#account');

    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`notifications-center-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // A tap marks it read and opens the comment in the article's language.
    await row('n-mention').click();
    await page.waitForURL((url) => url.pathname === '/en/a/sleep-and-memory' && url.hash === '#comment-cm-question');
    await expect.poll(async () => (await notificationsOf(request, me.id)).read).toContain('n-mention');
    await page.goBack();
    await openCenter(page);
    await expect(row('n-mention')).not.toHaveAttribute('data-unread', /.*/);
    await expect(page.locator('[data-notification][data-unread]')).toHaveCount(4);
  });

  test(`center: infinite scroll, mark all read, the streak reminder opens your stats — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOTIFICATIONS_NOW);
    const me = await signInAsNotifiedReader(page, request, variant);
    await page.goto('/notifications');
    await openCenter(page);

    // 20 per page; the rest come near the end.
    const rows = page.locator('[data-notification]');
    await expect(rows).toHaveCount(20);
    await expect(page.locator('[data-notifications-end]')).toHaveCount(0);
    await rows.last().scrollIntoViewIfNeeded();
    await expect(rows).toHaveCount(25);
    await expect(page.locator('[data-notifications-end]')).toHaveText(ar ? 'هذه كل الإشعارات ✓' : "You're all caught up ✓");

    // Mark all as read.
    await page.locator('[data-mark-all-read]').click();
    await expect(page.locator('[data-notification][data-unread]')).toHaveCount(0);
    await expect(page.locator('[data-mark-all-read]')).toBeDisabled();
    await expect.poll(async () => (await notificationsOf(request, me.id)).read.length).toBe(25);
    await page.reload();
    await openCenter(page);
    await expect(page.locator('[data-notification][data-unread]')).toHaveCount(0);

    // readin://me/stats → your profile, where your reading stats are.
    await page.locator('[data-notification="n-streak"]').click();
    await page.waitForURL((url) => url.pathname === '/@sara');
  });

  test(`settings → notifications: a mode per type and quiet hours — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsNotifiedReader(page, request, variant);
    await page.goto('/settings');
    const preferences = page.locator('[data-settings-notification-preferences]');
    await expect(preferences).toBeVisible({ timeout: FIRST_RENDER_MS });
    await preferences.click();
    await page.waitForURL((url) => url.pathname === '/settings/notifications');

    const type = (name: string) => page.locator(`[data-notification-type="${name}"]`);
    await expect(type('mention')).toHaveAttribute('data-mode', 'all', { timeout: FIRST_RENDER_MS });
    // Mentions cover comments and articles.
    await expect(type('mention')).toContainText(ar ? 'عندما يشير إليك أحد في تعليق أو مقال' : 'When someone mentions you in a comment or an article');
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-notification-settings-page')).toHaveScreenshot(`notification-settings-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // A mode is saved at once, with only that type.
    await type('mention').getByRole('radio', { name: ar ? 'إيقاف' : 'Off' }).click();
    await expect(type('mention')).toHaveAttribute('data-mode', 'off');
    await expect
      .poll(async () => (await notificationsOf(request, me.id)).puts.at(-1))
      .toEqual({ quietHours: { enabled: true, start: '23:00', end: '07:00' }, types: { mention: 'off' } });
    await type('daily_article').getByRole('radio', { name: ar ? 'داخل التطبيق' : 'In app' }).click();
    await expect.poll(async () => (await notificationsOf(request, me.id)).settings.types['daily_article']).toBe('inApp');
    await page.reload();
    await expect(type('mention')).toHaveAttribute('data-mode', 'off', { timeout: FIRST_RENDER_MS });
    await expect(type('daily_article')).toHaveAttribute('data-mode', 'inApp');

    // Quiet hours: the same time twice is refused before anything is sent.
    const quiet = page.locator('[data-quiet-hours]');
    const putsBefore = (await notificationsOf(request, me.id)).puts.length;
    await quiet.locator('#quiet-start').fill('07:00');
    await quiet.locator('[data-quiet-save]').click();
    const error = quiet.locator('[data-quiet-error]');
    await expect(error).toHaveText(ar ? 'اختر وقتَي بداية ونهاية (HH:mm) مختلفين.' : 'Pick a start and an end time (HH:mm) that are different.');
    await expect(quiet.locator('#quiet-start')).toHaveAttribute('aria-invalid', 'true');
    expect((await notificationsOf(request, me.id)).puts).toHaveLength(putsBefore);

    // The API's refusal shows in the same place.
    await quiet.locator('#quiet-start').fill('22:00');
    await expect(error).toHaveCount(0);
    let refused = false;
    await onApi(page, 'PUT', '/me/notification-settings', (route) => {
      if (refused) return route.fallback();
      refused = true;
      return reply(route, 400, problem(400, 'notification.quiet_hours_invalid'));
    });
    await quiet.locator('[data-quiet-save]').click();
    await expect(error).toBeVisible();
    expect(refused).toBe(true);

    // Saved.
    await quiet.locator('[data-quiet-save]').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'تم حفظ الإعدادات ✓' : 'Settings saved ✓');
    await expect(error).toHaveCount(0);
    await expect.poll(async () => (await notificationsOf(request, me.id)).settings.quietHours).toEqual({ enabled: true, start: '22:00', end: '07:00' });

    // Off: the times go away.
    await quiet.locator('[data-quiet-toggle] [role="switch"]').click();
    await expect(quiet.locator('#quiet-start')).toHaveCount(0);
    await expect.poll(async () => (await notificationsOf(request, me.id)).settings.quietHours.enabled).toBe(false);
  });
}
