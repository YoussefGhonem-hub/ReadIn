import { BrowserContext, Page, expect, test } from '@playwright/test';
import { VARIANTS, hasScreenshot, parkMouse, useVariant } from './support/mock-api';
import { signInAsReader } from './support/social';

/**
 * Reading mode in the reader (F04, leftovers 1), in ar/light and en/dark on desktop and phone: a toggle in the reader's
 * toolbar hides the top bar, the floating action bar and the docked Following panel; the article and its reading
 * progress bar stay. A small floating control or Escape turns it off (an open sheet takes its Escape first), and the
 * text stays where it was on screen. The choice is this device's (the `reading_mode` cookie, which the server reads, so
 * the reader is rendered in reading mode from the start) and only the reader hides anything.
 */
test.describe.configure({ timeout: 90_000 });

const ARTICLE = '/ar/a/dependency-injection-ar';
/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

async function openReader(page: Page, path = ARTICLE): Promise<void> {
  await page.goto(path);
  await expect(page.locator('[data-reading-mode-toggle]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle');
}

async function readingCookie(context: BrowserContext): Promise<string | null> {
  return (await context.cookies()).find((c) => c.name === 'reading_mode')?.value ?? null;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`reader: reading mode hides the chrome and keeps the text — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await openReader(page);
    const topBar = page.locator('rd-top-bar');
    const actionBar = page.locator('rd-article-action-bar');
    await expect(actionBar.locator('[data-react]')).toBeVisible();
    await expect(topBar).toBeVisible();

    // A real toggle button with one name; its pressed state says which.
    const toggle = page.getByRole('button', { name: t('وضع القراءة', 'Reading mode'), exact: true });
    await expect(toggle).toHaveAttribute('aria-pressed', 'false');
    await toggle.click();
    await expect(toggle).toHaveAttribute('aria-pressed', 'true');
    await expect(topBar).toBeHidden();
    await expect(actionBar).toBeHidden();
    await expect(page.locator('rd-article-page h1')).toBeVisible();
    await expect(page.locator('rd-article-page rd-rdoc')).toBeVisible();
    await expect(page.locator('[data-reading-progress]')).toBeVisible();
    await expect(page.locator('[data-reading-mode-status]')).toHaveText(t('تم تفعيل وضع القراءة.', 'Reading mode is on.'));
    expect(await readingCookie(context)).toBe('1');

    // The small floating control, in the bottom corner on the reading side's end.
    const exit = page.getByRole('button', { name: t('الخروج من وضع القراءة', 'Exit reading mode'), exact: true });
    await expect(exit).toBeVisible();
    await expect(exit).toHaveAttribute('aria-keyshortcuts', 'Escape');
    // Measured once its short fade-in (a 6px rise) is over.
    await exit.evaluate((el) => Promise.all(el.getAnimations().map((a) => a.finished)));
    const box = (await exit.boundingBox())!;
    const viewport = page.viewportSize()!;
    expect(box.y + box.height).toBeLessThanOrEqual(viewport.height - 8);
    expect(box.y + box.height).toBeGreaterThan(viewport.height - 64);
    if (lang === 'ar') expect(box.x).toBeLessThan(viewport.width / 2);
    else expect(box.x + box.width).toBeGreaterThan(viewport.width / 2);
    // It doesn't move with the page.
    await page.mouse.wheel(0, 500);
    await expect.poll(() => page.evaluate(() => scrollY)).toBeGreaterThan(0);
    expect((await exit.boundingBox())!.y).toBeCloseTo(box.y, 0);
    await page.evaluate(() => scrollTo({ top: 0, behavior: 'instant' }));

    await parkMouse(page);
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`reading-mode-${suffix}.png`);

    // Further down the progress bar fills; Escape brings the chrome back without moving the text on screen.
    const paragraph = page.locator('rd-article-page rd-rdoc p').nth(6);
    await paragraph.evaluate((el) => el.scrollIntoView({ block: 'center', behavior: 'instant' }));
    await expect
      .poll(() => page.locator('[data-reading-progress] > div').evaluate((el) => parseFloat((el as HTMLElement).style.width)))
      .toBeGreaterThan(0);
    const before = (await paragraph.boundingBox())!.y;
    await page.keyboard.press('Escape');
    await expect(toggle).toHaveAttribute('aria-pressed', 'false');
    await expect(topBar).toBeVisible();
    await expect(actionBar).toBeVisible();
    await expect(exit).toHaveCount(0);
    expect(Math.abs((await paragraph.boundingBox())!.y - before)).toBeLessThanOrEqual(2);
    await expect(page.locator('[data-reading-mode-status]')).toHaveText(t('تم إيقاف وضع القراءة.', 'Reading mode is off.'));
    expect(await readingCookie(context)).toBe('0');

    // From the keyboard: the toggle is a real button.
    await toggle.focus();
    await page.keyboard.press('Enter');
    await expect(toggle).toHaveAttribute('aria-pressed', 'true');
    await expect(topBar).toBeHidden();

    // An open sheet takes its Escape first: the glossary sheet closes, reading mode stays.
    await page.locator('[data-term="dependency-injection"]').click();
    const sheet = page.locator('rd-term-sheet section[role="dialog"]');
    await expect(sheet.locator('[data-term-sheet]')).toHaveAttribute('data-state', 'ready', { timeout: FIRST_RENDER_MS });
    await page.keyboard.press('Escape');
    await expect(sheet).toHaveCount(0);
    await expect(toggle).toHaveAttribute('aria-pressed', 'true');
    await expect(topBar).toBeHidden();

    // The floating control turns it off, and the focus goes back to the toggle.
    await exit.click();
    await expect(toggle).toHaveAttribute('aria-pressed', 'false');
    await expect(toggle).toBeFocused();
    await expect(topBar).toBeVisible();
    await expect(actionBar).toBeVisible();
  });

  test(`reader: reading mode is remembered on this device, rendered by the server, and only the reader hides anything — ${suffix}`, async ({
    page,
    context,
    baseURL,
    request,
  }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    const { hostname } = new URL(baseURL!);
    await context.addCookies([{ name: 'reading_mode', value: '1', domain: hostname, path: '/' }]);

    // The server's HTML is already in reading mode (no flash of the chrome).
    const html = await (await request.get(ARTICLE, { headers: { cookie: `lang=${lang}; theme=${theme}; reading_mode=1` } })).text();
    expect(html).toContain('data-reading-mode="on"');
    expect(html).toContain('data-reading-mode-exit');
    const plain = await (await request.get(ARTICLE, { headers: { cookie: `lang=${lang}; theme=${theme}` } })).text();
    expect(plain).not.toContain('data-reading-mode="on"');

    await openReader(page);
    const toggle = page.locator('[data-reading-mode-toggle]');
    await expect(toggle).toHaveAttribute('aria-pressed', 'true');
    await expect(page.locator('rd-top-bar')).toBeHidden();
    await expect(page.locator('rd-article-action-bar')).toBeHidden();
    // Opening the reader in reading mode isn't announced (only switching is).
    await expect(page.locator('[data-reading-mode-status]')).toHaveText('');
    // The docked Following panel (wide screens, signed in) hides too.
    if (testInfo.project.name === 'desktop') {
      await expect(page.locator('rd-following-dock')).toBeAttached({ timeout: FIRST_RENDER_MS });
      await expect(page.locator('rd-following-dock')).toBeHidden();
    }

    // The fade-in of the floating control follows "reduce motion".
    const animation = () => page.locator('[data-reading-mode-exit]').evaluate((el) => getComputedStyle(el).animationName);
    expect(await animation()).toBe('rd-reading-exit-in');
    await page.emulateMedia({ reducedMotion: 'reduce' });
    expect(await animation()).toBe('none');
    await page.emulateMedia({ reducedMotion: 'no-preference' });

    // Another article opens in reading mode too.
    await openReader(page, '/en/a/sleep-and-memory');
    await expect(page.locator('[data-reading-mode-toggle]')).toHaveAttribute('aria-pressed', 'true');
    await expect(page.locator('rd-top-bar')).toBeHidden();

    // Outside the reader the chrome is there, and the choice is kept for the next article.
    await page.goto('/');
    await expect(page.locator('rd-top-bar')).toBeVisible({ timeout: FIRST_RENDER_MS });
    if (testInfo.project.name === 'desktop') await expect(page.locator('rd-following-dock')).toBeVisible({ timeout: FIRST_RENDER_MS });
    else await expect(page.locator('rd-bottom-nav')).toBeVisible();
    expect(await readingCookie(context)).toBe('1');
  });
}
