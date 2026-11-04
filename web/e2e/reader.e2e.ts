import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, HIDE_READER_BAR, VARIANTS, hasScreenshot, onApi, parkMouse, reply, useVariant } from './support/mock-api';
import { openArticle, signInAsReader } from './support/social';

/**
 * The reader's glossary sheet (F21), related articles and resuming where you left off (F04), in ar/en × light/dark.
 * The mock API's "يعني إيه Dependency Injection" article (e2e/mock-api/server.mjs) is long, uses two glossary terms and
 * one that isn't in the glossary, and has related articles.
 */
test.describe.configure({ timeout: 90_000 });

const ARTICLE = '/ar/a/dependency-injection-ar';
/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

/** Opens the article as a guest once it is hydrated (the term buttons and the sheet work from then on). */
async function openAsGuest(page: Page, path = ARTICLE): Promise<void> {
  await page.goto(path);
  await expect(page.locator('rd-article-action-bar [data-react]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle');
}

/** The reader's scroll position as the reading tracker measures it (features/article/reading-tracker.ts). */
function scrollFraction(page: Page): Promise<number> {
  return page.evaluate(() => {
    const rect = document.querySelector('rd-article-page article')!.getBoundingClientRect();
    return -rect.top / (rect.height - innerHeight);
  });
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`reader: glossary sheet — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const lookups: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/v1/glossary/')) lookups.push(new URL(r.url()).pathname + new URL(r.url()).search);
    });
    await openAsGuest(page);

    const term = page.locator('[data-term="dependency-injection"]');
    await expect(term).toHaveAttribute('aria-haspopup', 'dialog');
    await term.click();
    const dialog = page.locator('rd-term-sheet section[role="dialog"]');
    const sheet = dialog.locator('[data-term-sheet]');
    // The sheet's code loads on the first tapped term.
    await expect(sheet).toHaveAttribute('data-state', 'ready', { timeout: FIRST_RENDER_MS });
    await expect(dialog).toHaveAttribute('aria-labelledby', 'term-sheet-title');
    await expect(dialog.locator('#term-sheet-title bdi')).toHaveAttribute('dir', 'ltr');
    await expect(dialog.locator('#term-sheet-title')).toHaveText('Dependency Injection');
    await expect(dialog.locator('[data-term-explanation]')).toHaveAttribute('dir', 'rtl');
    await expect(dialog.locator('[data-term-definition]')).toHaveAttribute('dir', 'ltr');
    await expect(dialog).toContainText(t('بالإنجليزي', 'In English'));
    // The open article is left out of the articles that use the term.
    const rows = dialog.locator('[data-term-article]');
    await expect(rows).toHaveCount(3);
    await expect(rows.first()).toHaveAttribute('href', '/en/a/clean-architecture-whiteboard');
    expect(lookups).toEqual(['/api/v1/glossary/dependency-injection?lang=ar-EG']);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(dialog).toHaveScreenshot(`glossary-sheet-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Keyboard: focus stays inside, Escape closes and gives focus back to the term.
    for (let i = 0; i < 6; i++) {
      await page.keyboard.press('Tab');
      expect(await dialog.evaluate((el) => el.contains(document.activeElement))).toBe(true);
    }
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    await expect(term).toBeFocused();

    // Enter opens it again, answered from memory.
    await page.keyboard.press('Enter');
    await expect(sheet).toHaveAttribute('data-state', 'ready');
    expect(lookups).toHaveLength(1);

    // The scrim closes it too.
    await page.locator('rd-term-sheet .bg-scrim').click({ position: { x: 5, y: 5 } });
    await expect(dialog).toHaveCount(0);

    // A term that isn't in the glossary yet.
    await page.locator('[data-term="service-locator"]').click();
    await expect(sheet).toHaveAttribute('data-state', 'missing');
    await expect(dialog.locator('#term-sheet-title')).toHaveText('Service Locator');
    await expect(dialog.locator('[data-term-missing]')).toHaveText(t('المصطلح ده لسه مش في القاموس', "This term isn't in the glossary yet"));
    await page.keyboard.press('Escape');

    // An article from the list opens and the sheet closes.
    await term.click();
    await rows.first().click();
    await page.waitForURL((url) => url.pathname === '/en/a/clean-architecture-whiteboard');
    await expect(dialog).toHaveCount(0);
    await expect(page.locator('h1')).toContainText('Clean Architecture');
  });

  test(`reader: related articles — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const related: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/related')) related.push(new URL(r.url()).pathname + new URL(r.url()).search);
    });
    await openAsGuest(page);
    expect(related).toEqual([]); // nothing until the end of the article nears the viewport

    await page.locator('#sources-title').scrollIntoViewIfNeeded();
    const section = page.locator('[data-related]');
    await expect(section).toBeVisible();
    expect(related).toEqual(['/api/v1/articles/a-dependency-injection-ar/related?lang=ar-EG&limit=4']);
    await expect(section.locator('#related-title')).toHaveText(t('مقالات ذات صلة', 'Related articles'));
    await expect(section.locator('rd-article-card')).toHaveCount(4);
    // After the sources, before the comments.
    expect(await section.evaluate((el) => !!(document.querySelector('#sources-title')!.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING))).toBe(true);
    expect(await section.evaluate((el) => !!(el.compareDocumentPosition(document.querySelector('#comments')!) & Node.DOCUMENT_POSITION_FOLLOWING))).toBe(true);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(section).toHaveScreenshot(`related-articles-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_READER_BAR] });

    await section.locator('rd-article-card').first().locator('a').first().click();
    await page.waitForURL((url) => url.pathname === '/ar/a/what-is-a-transformer-ar');
  });

  test(`reader: picks up where you left off — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    // Your copy carries your progress: half way through the Arabic version.
    await page.route(/\/api\/v1\/articles\/dependency-injection-ar\?/, async (route) => {
      if (route.request().method() !== 'GET' || !route.request().headers()['authorization']) return route.fallback();
      const response = await route.fetch();
      const body = await response.json();
      return route.fulfill({ response, json: { ...body, myProgress: { language: 'ar-EG', percent: 60, lastPosition: '0.5000', completedAt: null } } });
    });
    const reports: { percent: number; lastPosition: string }[] = [];
    await onApi(page, 'PUT', /\/api\/v1\/articles\/a-dependency-injection-ar\/progress$/, (route) => {
      const body = route.request().postDataJSON() as { percent: number; lastPosition: string };
      reports.push(body);
      return reply(route, 200, { percent: body.percent, completed: false, completedNow: false, streak: null, milestone: null });
    });

    await openArticle(page, ARTICLE);
    const toast = page.locator('rd-toast-host > div', { hasText: t('كمّلنا من مكان ما وقفت', 'Picked up where you left off') });
    await expect(toast).toBeVisible();
    expect(Math.abs((await scrollFraction(page)) - 0.5)).toBeLessThan(0.002);
    // The tracker starts once you are placed: its first report keeps your position instead of the top.
    await expect.poll(() => reports.length).toBeGreaterThan(0);
    expect(Math.abs(Number(reports[0].lastPosition) - 0.5)).toBeLessThan(0.002);
    expect(reports[0].percent).toBe(50);
    if (hasScreenshot(variant)) await expect(toast).toHaveScreenshot(`resume-toast-${suffix}.png`);

    await toast.locator('[data-toast-action]').click();
    await expect(toast).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => scrollY)).toBe(0);

    // A link to a place in the article wins: no resume. (A fresh load: the same URL plus a fragment wouldn't reload.)
    await page.goto('about:blank');
    const personalized = page.waitForResponse((r) => r.url().includes('/articles/dependency-injection-ar?') && !!r.request().headers()['authorization']);
    await page.goto(`${ARTICLE}#comments`);
    await personalized;
    await page.waitForTimeout(1500);
    await expect(page.locator('rd-toast-host > div')).toHaveCount(0);
  });
}
