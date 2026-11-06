import { randomUUID } from 'node:crypto';
import { APIRequestContext, Locator, Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, VARIANTS, Variant, hasScreenshot, parkMouse, restoreSessionAs, sessionFor, useVariant, writerMe } from './support/mock-api';
import { signInAsReader } from './support/social';

/**
 * "Repost with your thoughts" (F29 caption) in ar/light and en/dark, desktop and phone:
 * - the Repost button's menu: "أعد النشر" / "أعد النشر مع رأيك" before you repost, "عدّل رأيك" / "إلغاء إعادة النشر"
 *   after; keyboard, Escape and focus back on the button;
 * - the caption dialog (a centred dialog on desktop, a bottom sheet on phones): the article's preview, a field that
 *   grows and never scrolls inside itself, the counter (red over 500, which disables Repost), `PUT { caption }`, the
 *   toast; editing prefilled from `GET`, "احفظ"; then Undo;
 * - the reposter's thoughts on the Following feed's cards, under the label line: plain text in its own direction, line
 *   breaks kept, cut at 4 lines with "… اقرأ المزيد" (the mock's `u-reposts…` viewers follow Karim and ReadIn, whose
 *   reposts have captions, e2e/mock-api/reposts.mjs).
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
const NOW = new Date('2026-11-04T09:00:00Z');
const CLEAN = 'a-clean-architecture-whiteboard';

const cardOf = (page: Page, id: string): Locator => page.locator(`rd-post-card[data-post-card="${id}"]`).first();

async function openHome(page: Page): Promise<void> {
  await page.clock.setFixedTime(NOW);
  await page.goto('/');
  await expect(page.locator('rd-post-card').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
  await expect(page.locator('h1')).toContainText(/Sara/, { timeout: FIRST_RENDER_MS }); // the session is restored
  await page.waitForLoadState('networkidle');
}

/** A reader who follows ReadIn and Karim, in the mock's world where those two reposted articles with their thoughts. */
async function signInAsRepostsReader(page: Page, request: APIRequestContext, variant: Variant) {
  const me = await writerMe(request, variant, {
    id: `u-reposts-${randomUUID().slice(0, 8)}`,
    displayName: 'Sara Hassan',
    username: 'sara',
    isVerified: false,
    roles: ['Member'],
    permissions: ['articles.read', 'reactions.create', 'saved.manage', 'follows.manage', 'reposts.create'],
  });
  await restoreSessionAs(page, me);
  return me;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`repost with your thoughts: the menu, the dialog, edit, undo — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsReader(page, request, variant);
    await openHome(page);
    const card = cardOf(page, CLEAN);
    const repost = card.locator('[data-repost]');
    const count = card.locator('[data-repost-count]');
    await expect(count).toHaveText('2');
    await expect(repost).toHaveAttribute('aria-haspopup', 'menu');
    await expect(repost).toHaveAttribute('aria-label', t('إعادة نشر، 2', 'Repost, 2'));

    // The menu from the keyboard: Enter opens it on its first item, Escape closes it and gives focus back.
    const menu = page.locator('[data-repost-menu]');
    const items = menu.locator('[data-repost-action]');
    await repost.focus();
    await page.keyboard.press('Enter');
    await expect(menu).toBeVisible();
    await expect(items).toHaveText([t('أعد النشر', 'Repost'), t('أعد النشر مع رأيك', 'Repost with your thoughts')]);
    await expect(items.first()).toBeFocused();
    await page.keyboard.press('ArrowDown');
    await expect(items.nth(1)).toBeFocused();
    await page.keyboard.press('Escape');
    await expect(menu).toHaveCount(0);
    await expect(repost).toBeFocused();
    await expect(repost).toHaveAttribute('aria-pressed', 'false');

    // "Repost with your thoughts": the dialog, its field focused; Escape closes it and nothing is sent.
    const sent: string[] = [];
    page.on('request', (r) => {
      if (r.url().endsWith(`/articles/${CLEAN}/repost`)) sent.push(r.method());
    });
    await repost.click();
    await menu.locator('[data-repost-action="thoughts"]').click();
    const dialog = page.locator('[data-repost-dialog]');
    await expect(dialog).toBeVisible({ timeout: FIRST_RENDER_MS });
    const sheet = page.locator('rd-repost-dialog section[role="dialog"]');
    await expect(sheet).toHaveAccessibleName(t('أعد نشر المقال', 'Repost this article'));
    await expect(dialog.locator('[data-repost-preview-title]')).toHaveText('Clean Architecture on one whiteboard');
    await expect(dialog.locator('[data-repost-preview-author]')).toHaveText('Mona Adel');
    const field = dialog.locator('[data-repost-caption]');
    await expect(field).toBeFocused();
    await expect(field).toHaveAttribute('placeholder', t('قول رأيك في المقال… (اختياري)', 'Add your thoughts… (optional)'));
    await expect(field).toHaveAccessibleName(t('رأيك في المقال', 'Your thoughts on the article'));
    await expect(dialog.locator('[data-repost-count]')).toHaveText('0/500');
    const submit = dialog.locator('[data-repost-submit]');
    await expect(submit).toHaveText(t('انشر', 'Repost'));
    await expect(submit).toBeEnabled();
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    await expect(repost).toBeFocused();
    expect(sent).toEqual([]);

    await repost.click();
    await menu.locator('[data-repost-action="thoughts"]').click();
    await expect(field).toBeFocused({ timeout: FIRST_RENDER_MS });

    // The field grows with its text and never scrolls inside itself (no scrollbar or arrows).
    const before = await field.evaluate((el) => el.getBoundingClientRect().height);
    await field.fill(Array.from({ length: 10 }, (_, i) => t(`سطر ${i + 1}`, `Line ${i + 1}`)).join('\n'));
    const grown = await field.evaluate((el) => ({ height: el.getBoundingClientRect().height, overflowY: getComputedStyle(el).overflowY, fits: el.scrollHeight <= el.clientHeight + 1 }));
    expect(grown.height).toBeGreaterThan(before);
    expect(grown.overflowY).toBe('hidden');
    expect(grown.fits).toBe(true);

    // Over 500 characters: the counter turns red and Repost waits.
    await field.fill('x'.repeat(501));
    await expect(dialog.locator('[data-repost-count]')).toHaveText('501/500');
    await expect(dialog.locator('[data-repost-count]')).toHaveAttribute('data-over', 'true');
    await expect(field).toHaveAttribute('aria-invalid', 'true');
    await expect(submit).toBeDisabled();

    const caption = t('أحسن شرح للـ Clean Architecture قريته.\nالرسمة لوحدها تستاهل.', 'The clearest take on Clean Architecture I have read.\nThe whiteboard alone is worth it.');
    await field.fill(caption);
    await expect(submit).toBeEnabled();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(sheet).toHaveScreenshot(`repost-dialog-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    const put = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith(`/articles/${CLEAN}/repost`));
    await submit.click();
    expect((await put).postDataJSON()).toEqual({ caption });
    await expect(dialog).toHaveCount(0);
    await expect(page.locator('rd-toast-host')).toContainText(t('أعدت نشر المقال.', 'You reposted this article.'));
    await expect(repost).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText('3');

    // Reposted: "Edit your thoughts" (prefilled from GET, "Save") and "Undo repost".
    await repost.click();
    await expect(items).toHaveText([t('عدّل رأيك', 'Edit your thoughts'), t('إلغاء إعادة النشر', 'Undo repost')]);
    const get = page.waitForResponse((r) => r.request().method() === 'GET' && r.url().endsWith(`/articles/${CLEAN}/repost`));
    await menu.locator('[data-repost-action="edit"]').click();
    expect((await get).status()).toBe(200);
    await expect(field).toHaveValue(caption);
    await expect(dialog).toHaveAttribute('data-mode', 'edit');
    await expect(submit).toHaveText(t('احفظ', 'Save'));
    const edited = t('رأيي اتغيّر شوية.', 'Changed my mind a little.');
    await field.fill(edited);
    const save = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith(`/articles/${CLEAN}/repost`));
    await submit.click();
    expect((await save).postDataJSON()).toEqual({ caption: edited });
    await expect(dialog).toHaveCount(0);
    await expect(page.locator('rd-toast-host')).toContainText(t('اتحفظ رأيك.', 'Your thoughts were saved.'));
    await expect(count).toHaveText('3'); // editing doesn't count again

    // Undo: at once; the caption goes with the repost.
    const del = page.waitForRequest((r) => r.method() === 'DELETE' && r.url().endsWith(`/articles/${CLEAN}/repost`));
    await repost.click();
    await menu.locator('[data-repost-action="undo"]').click();
    await expect(repost).toHaveAttribute('aria-pressed', 'false');
    await expect(count).toHaveText('2');
    await del;
    const now = await request.get(`${API}/articles/${CLEAN}/repost`, { headers: { authorization: `Bearer ${sessionFor(me).accessToken}` } });
    expect(await now.json()).toEqual({ repostCount: 2, isReposted: false, caption: null });
  });

  test(`a card shows the reposter's thoughts under the label — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsRepostsReader(page, request, variant);
    await openHome(page);
    await page.locator('[data-home-tab="following"]').click();
    const cards = page.locator('#home-panel-following rd-post-card');
    await expect(cards.first()).toBeVisible({ timeout: FIRST_RENDER_MS });

    // Karim's thoughts in Arabic on two lines, under "Karim Hassan and 1 other reposted this" and above the header.
    const sleep = cards.nth(0);
    const thoughts = sleep.locator('[data-card-repost-caption]');
    await expect(sleep.locator('[data-card-repost-label]')).toHaveText(t('Karim Hassan وشخص تاني أعادوا نشره', 'Karim Hassan and 1 other reposted this'));
    await expect(thoughts).toHaveText('أحسن مقال قريته عن النوم السنة دي.\nالجزء بتاع الـ REM sleep لوحده يستاهل القراية.', { useInnerText: true });
    await expect(thoughts).toHaveAttribute('dir', 'rtl');
    expect(await thoughts.evaluate((el) => getComputedStyle(el).whiteSpace)).toBe('pre-line');
    const order = await sleep.evaluate((el) => {
      const label = el.querySelector('[data-card-repost-label]')!.getBoundingClientRect().bottom;
      const text = el.querySelector('[data-card-repost-caption]')!.getBoundingClientRect();
      const header = el.querySelector('header')!.getBoundingClientRect().top;
      return { underLabel: text.top >= label - 1, aboveHeader: text.bottom <= header + 1 };
    });
    expect(order).toEqual({ underLabel: true, aboveHeader: true });
    await expect(sleep.locator('[data-card-caption-more]')).toHaveCount(0);

    // ReadIn's long English thoughts: cut at 4 lines with "… Read more", which shows them all.
    const rsc = cards.nth(1);
    const long = rsc.locator('[data-card-repost-caption]');
    await expect(long).toHaveAttribute('dir', 'ltr');
    const more = rsc.locator('[data-card-caption-more]');
    await expect(more).toBeVisible();
    await expect(more).toHaveText(t('… اقرأ المزيد', '… Read more'));
    await expect(more).toHaveAccessibleName(t('اقرأ رأي ReadIn كله', "Read all of ReadIn's thoughts"));
    const lines = await long.evaluate((el) => Math.round(el.clientHeight / parseFloat(getComputedStyle(el).lineHeight)));
    expect(lines).toBe(4);

    // A repost without thoughts: the label line alone.
    await expect(cards.nth(3).locator('[data-card-repost-label]')).toHaveText(t('أعاد نشره Karim Hassan', 'Karim Hassan reposted this'));
    await expect(cards.nth(3).locator('[data-card-repost-caption]')).toHaveCount(0);

    await sleep.scrollIntoViewIfNeeded();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(sleep.locator('[data-card-repost]')).toHaveScreenshot(`repost-caption-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await rsc.scrollIntoViewIfNeeded();
    if (hasScreenshot(variant)) await expect(rsc.locator('[data-card-repost]')).toHaveScreenshot(`repost-caption-cut-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    await more.click();
    await expect(more).toHaveCount(0);
    await expect(long).toBeFocused();
    expect(await long.evaluate((el) => el.scrollHeight <= el.clientHeight + 1)).toBe(true);
    await expect(long).toContainText('the waterfalls you never noticed in your own app.');
  });
}
