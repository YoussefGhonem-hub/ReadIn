import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, MOCK_PASSWORD, MOCK_PHONE, VARIANTS, hasScreenshot, onApi, parkMouse, problem, reply, useVariant } from './support/mock-api';
import { reportOf, signInAsModerator, signInAsWarnedReader } from './support/moderation';
import { openProfile } from './support/profile';
import { expectSignInPrompt, openArticle, signInAsReader } from './support/social';

/**
 * F22 Reporting & Moderation end to end in ar/en × light/dark: reporting an article and a comment from the reader and
 * a user from their profile (one shared sheet), the moderator's queue (Open / Resolved / Dismissed, type filter) and
 * cases (hide, warn, suspend, dismiss) and log, hiding an article from the reader (banner), the notices a warned user
 * acknowledges, and the suspended-account message on Sign in. The mock API keeps each moderator's own queue
 * (e2e/mock-api/moderation.mjs), so parallel tests never share state.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** The seeded reports are from the hours before this; relative times ("an hour ago") stay the same in screenshots. */
const NOW = new Date('2026-11-03T09:00:00Z');

/** Opens a case from the queue and waits for it. */
async function openCase(page: Page, key: string): Promise<void> {
  await page.locator(`[data-case="${key}"]`).click();
  await expect(page.locator('[data-case-target]')).toBeVisible({ timeout: FIRST_RENDER_MS });
}

/** Confirms the open moderation sheet, with a note when given, and waits for the success toast. */
async function confirmAction(page: Page, note: string | null, toast: string): Promise<void> {
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

  test(`report: an article and a comment from the reader — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/sleep-and-memory');

    // The "⋯" menu: only Report on someone else's article, in the error color.
    await page.locator('rd-article-action-bar [data-article-menu]').click();
    const menu = page.locator('[data-article-menu-panel]');
    await expect(menu.locator('[data-menu-action]')).toHaveCount(1);
    const report = menu.locator('[data-menu-action="report"]');
    await expect(report).toHaveText(ar ? 'الإبلاغ عن المقال' : 'Report article');
    await expect(report).toHaveClass(/text-error/);
    await report.click();

    const sheet = page.locator('[data-report-sheet]');
    await expect(sheet).toHaveAttribute('data-report-target', 'article');
    await expect(sheet.locator('[data-report-submit]')).toBeDisabled();
    await sheet.locator('[data-reason="misinformation"]').check();
    await sheet.locator('[data-report-details]').fill('The study it cites found the opposite.');
    await expect(sheet.locator('[data-report-count]')).toHaveText('38/500');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-report-sheet section[role="dialog"]')).toHaveScreenshot(`report-sheet-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await sheet.locator('[data-report-submit]').click();
    await expect(sheet).toHaveCount(0);
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'شكرًا، هنراجع البلاغ' : "Thanks, we'll review it");
    expect(await reportOf(request, me.id, 'article', 'a-sleep-and-memory')).toEqual({ reason: 'misinformation', details: 'The study it cites found the opposite.' });

    // A comment, through the same sheet.
    await page.locator('#comments').scrollIntoViewIfNeeded();
    const comment = page.locator('[data-comment="cm-spam"]');
    await expect(comment).toBeVisible({ timeout: FIRST_RENDER_MS });
    await comment.locator('[data-comment-menu]').click();
    await page.locator('[data-comment-menu-panel] [data-menu-action="report"]').click();
    await expect(sheet).toHaveAttribute('data-report-target', 'comment');
    await expect(sheet.locator('#report-sheet-title')).toHaveText(ar ? 'الإبلاغ عن التعليق' : 'Report comment');
    await sheet.locator('[data-reason="spam"]').check();
    await sheet.locator('[data-report-submit]').click();
    await expect(sheet).toHaveCount(0);
    expect(await reportOf(request, me.id, 'comment', 'cm-spam')).toEqual({ reason: 'spam', details: null });
  });

  test(`report: a user from the profile; guests sign in first — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);

    // A guest gets the sign-in prompt.
    await openProfile(page, '/@omar_dev');
    await page.locator('[data-profile-menu]').click();
    await page.locator('[data-profile-menu-panel] [data-menu-action="report"]').click();
    await expectSignInPrompt(page);

    const me = await signInAsReader(page, request, variant);
    await openProfile(page, '/@omar_dev', { signedIn: true });
    await page.locator('[data-profile-menu]').click();
    const menu = page.locator('[data-profile-menu-panel]');
    await expect(menu.locator('[data-menu-action]')).toHaveCount(1);
    await menu.locator('[data-menu-action="report"]').click();
    const sheet = page.locator('[data-report-sheet]');
    await expect(sheet).toHaveAttribute('data-report-target', 'user');
    await sheet.locator('[data-reason="harassment"]').check();
    await sheet.locator('[data-report-submit]').click();
    await expect(sheet).toHaveCount(0);
    expect(await reportOf(request, me.id, 'user', 'u-omar')).toEqual({ reason: 'harassment', details: null });
  });

  test(`moderation: the queue, a case, hide, warn, suspend, dismiss and the log — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOW);
    await signInAsModerator(page, request, variant);
    await page.goto('/moderation');

    const queue = page.locator('[data-moderation-queue]');
    const cases = queue.locator('[data-case]');
    await expect(cases).toHaveCount(4, { timeout: FIRST_RENDER_MS });
    await expect(cases).toHaveText([/sleep/, /cheap-courses/, /Dina Fawzy/, /streak/]);
    if (testInfo.project.name === 'desktop') await expect(page.locator('rd-side-nav [data-moderation-badge]')).toHaveText('4');
    await expect(page.locator('[data-type-chip="article"]')).toContainText('2');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-moderation-queue-page')).toHaveScreenshot(`moderation-queue-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // The type filter is in the URL.
    await page.locator('[data-type-chip="comment"]').click();
    await expect(page).toHaveURL(/\/moderation\?type=comment$/);
    await expect(cases).toHaveCount(1);
    await page.locator('[data-type-chip="all"]').click();
    await expect(cases).toHaveCount(4);

    // An article case: hide it with a note.
    await openCase(page, 'article:a-sleep-and-memory');
    await expect(page).toHaveURL(/\/moderation\/article\/a-sleep-and-memory$/);
    await expect(page.locator('[data-report]')).toHaveCount(3);
    await expect(page.locator('[data-case-link]')).toHaveAttribute('href', '/en/a/sleep-and-memory');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-moderation-case-page')).toHaveScreenshot(`moderation-case-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await page.locator('[data-case-action="hide"]').click();
    await confirmAction(page, 'Misleading health claims.', ar ? 'اتخفى' : 'Hidden');
    await expect(page.locator('[data-case-status]')).toHaveText(ar ? 'اتحل' : 'Resolved');
    await expect(page.locator('[data-case-target] [data-target-state="hidden"]')).toBeVisible();
    await expect(page.locator('[data-case-history] [data-log-entry]')).toHaveCount(1);
    await expect(page.locator('[data-case-history]')).toContainText('Misleading health claims.');

    // A comment case: warn its author (the note is required).
    await page.locator('[data-case-back]').click();
    await expect(cases).toHaveCount(3);
    await openCase(page, 'comment:cm-spam');
    await page.locator('[data-case-action="warnAuthor"]').click();
    await expect(page.locator('[data-moderation-confirm]')).toBeDisabled();
    await confirmAction(page, 'No ads in the comments, please.', ar ? 'التحذير اتبعت' : 'Warning sent');
    await expect(page.locator('[data-case-status]')).toHaveText(ar ? 'اتحل' : 'Resolved');

    // A user case: suspend for 7 days.
    await page.locator('[data-case-back]').click();
    await openCase(page, 'user:u-reader-21');
    await page.locator('[data-case-action="suspend"]').click();
    await expect(page.locator('[data-duration="7"]')).toBeChecked();
    await confirmAction(page, 'Insults other readers after a warning.', ar ? 'الحساب اتوقف' : 'Account suspended');
    await expect(page.locator('[data-case-target] [data-target-state="suspended"]')).toBeVisible();
    await expect(page.locator('[data-case-action="unsuspend"]')).toBeVisible();

    // The last open case: dismiss.
    await page.locator('[data-case-back]').click();
    await openCase(page, 'article:a-readin-streaks-ar');
    await page.locator('[data-case-action="dismiss"]').click();
    await confirmAction(page, null, ar ? 'البلاغات اترفضت' : 'Reports dismissed');
    await expect(page.locator('[data-case-status]')).toHaveText(ar ? 'اترفض' : 'Dismissed');

    // Nothing open any more; the closed tabs and the log have them.
    await page.locator('[data-case-back]').click();
    await expect(page.locator('[data-queue-empty]')).toBeVisible();
    if (testInfo.project.name === 'desktop') await expect(page.locator('rd-side-nav [data-moderation-badge]')).toHaveCount(0);
    await page.locator('[data-moderation-tab="resolved"]').click();
    await expect(page).toHaveURL(/status=resolved/);
    await expect(cases).toHaveCount(4);
    await page.locator('[data-moderation-tab="dismissed"]').click();
    await expect(cases).toHaveCount(2);
    await page.locator('[data-moderation-tab="log"]').click();
    // The log is its own lazy chunk.
    await expect(page).toHaveURL(/\/moderation\/log$/, { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-log-entry]')).toHaveCount(6, { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-log-entry]').first()).toHaveAttribute('data-log-action', 'reports.dismiss');
  });

  test(`moderation: hide and unhide an article from the reader — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsModerator(page, request, variant);
    await openArticle(page, '/ar/a/what-is-a-transformer-ar');
    const banner = page.locator('[data-hidden-banner]');
    await expect(banner).toHaveCount(0);

    await page.locator('rd-article-action-bar [data-article-menu]').click();
    await expect(page.locator('[data-article-menu-panel] [data-menu-action]')).toHaveCount(2);
    await page.locator('[data-article-menu-panel] [data-menu-action="hide"]').click();
    await confirmAction(page, 'Copied from another site without credit.', ar ? 'اتخفى' : 'Hidden');
    await expect(banner).toBeVisible();
    await expect(banner).toContainText('Copied from another site without credit.');

    // The server kept it: moderators (and the author) still open it, with the banner.
    await openArticle(page, '/ar/a/what-is-a-transformer-ar');
    await expect(banner).toBeVisible();
    await expect(banner).toContainText(ar ? 'المقال ده متخفي من فريق الإشراف' : 'Hidden by moderators');

    await page.locator('rd-article-action-bar [data-article-menu]').click();
    await page.locator('[data-article-menu-panel] [data-menu-action="unhide"]').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'رجع ظاهر' : 'Visible again');
    await expect(banner).toHaveCount(0);
  });

  test(`notices: a warning and a hidden article, each acknowledged — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsWarnedReader(page, request, variant);
    await page.goto('/saved');

    const notice = page.locator('[data-moderation-notice]');
    await expect(notice).toHaveAttribute('data-notice-kind', 'warning', { timeout: FIRST_RENDER_MS });
    await expect(notice.locator('[data-notice-title]')).toHaveText(ar ? 'وصلك تحذير من فريق الإشراف' : "You've received a warning from the moderators");
    await expect(notice.locator('[data-notice-note]')).toContainText('Please keep the comments respectful');
    // It can't be closed without "Got it".
    await page.keyboard.press('Escape');
    await expect(notice).toBeVisible();
    const ack = page.waitForResponse((r) => r.url().endsWith('/me/moderation-notices/n-1/acknowledge'));
    await notice.locator('[data-notice-ack]').click();
    expect((await ack).status()).toBe(204);

    await expect(notice).toHaveAttribute('data-notice-kind', 'article_hidden');
    await expect(notice.locator('[data-notice-title]')).toContainText('Dependency Injection');
    await notice.locator('[data-notice-ack]').click();
    await expect(notice).toHaveCount(0);

    // Acknowledged on the server: not shown again.
    const reloaded = page.waitForResponse((r) => r.url().endsWith('/me/moderation-notices'));
    await page.reload();
    await reloaded;
    await expect(page.locator('[data-saved-list]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(notice).toHaveCount(0);
  });

  test(`suspended: Sign in and a call that bounces to Sign in say until when — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);

    // Signing in.
    let until: string | null = '2026-11-10T14:30:00Z';
    await onApi(page, 'POST', '/auth/login', (route) => reply(route, 403, { ...problem(403, 'user.suspended'), suspendedUntil: until }));
    await page.goto('/auth/sign-in');
    await page.locator('#sign-in-phone').fill(MOCK_PHONE);
    await page.locator('#sign-in-password').fill(MOCK_PASSWORD);
    await page.locator('form [data-submit]').click();
    const error = page.locator('[data-error]');
    await expect(error).toContainText(ar ? 'الحساب ده موقوف لحد' : 'This account is suspended until', { timeout: FIRST_RENDER_MS });
    await expect(error).toContainText('2026');
    until = null;
    await page.locator('form [data-submit]').click();
    await expect(error).toHaveText(ar ? 'الحساب ده موقوف نهائيًا. تواصل مع الدعم.' : 'This account is suspended permanently. Contact support.');

    // Suspended while signed in: the next call ends the session and opens Sign in with the message.
    await page.unrouteAll({ behavior: 'ignoreErrors' });
    await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/sleep-and-memory');
    await onApi(page, 'PUT', /\/articles\/[^/]+\/reaction$/, (route) => reply(route, 403, { ...problem(403, 'user.suspended'), suspendedUntil: '2026-11-10T14:30:00Z' }));
    await page.locator('rd-article-action-bar [data-react]').click();
    // Sign in's chunk may still have to load: this page was opened straight on the article.
    await expect(page).toHaveURL(/\/auth\/sign-in\?returnUrl=%2Fen%2Fa%2Fsleep-and-memory/, { timeout: FIRST_RENDER_MS });
    await expect(error).toContainText(ar ? 'الحساب ده موقوف لحد' : 'This account is suspended until');
  });
}
