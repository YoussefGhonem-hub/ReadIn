import { Page, expect, test } from '@playwright/test';
import { API, VARIANTS, fixture, onApi, reply, useVariant } from './support/mock-api';

/* eslint-disable @typescript-eslint/no-explicit-any -- DTOs come from the mock API as plain JSON */

/**
 * Coming back from the full-screen viewer (SPEC F26, pre-production step H), in ar/light and en/dark: open an image
 * from a post far down the feed, close the viewer with ✕, with Esc and with the browser Back, and the page is still at
 * the same scroll position with the focus on the image that opened it; the URL never changes, and the viewer leaves no
 * history behind (Back afterwards leaves the page as usual).
 *
 * The cause it guards against: the viewer's history entry has the page's own URL, and the router treated the popstate
 * of leaving it as a same-URL navigation, whose scroll event scrolled the page to the top.
 */
test.describe.configure({ timeout: 120_000 });

const FIRST_RENDER_MS = 30_000;

/** Lets the router's scroll handling (a timeout and an animation frame after a popstate) run, so a jump would show. */
async function settle(page: Page): Promise<void> {
  await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => setTimeout(resolve, 400)))));
}

const scrollY = (page: Page) => page.evaluate(() => Math.round(window.scrollY));

for (const variant of VARIANTS) {
  const { lang, theme } = variant;

  test(`closing the viewer keeps the scroll position and the focus (✕, Esc, Back) — ${lang}-${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // A long feed (14 posts); the 12th has one image.
    const base = (await fixture<any>(request, '/api/v1/feed/for-you')).items;
    const items = Array.from({ length: 14 }, (_, i) => {
      const article = base[i % base.length];
      return { ...article, id: `${article.id}-${i}` };
    });
    expect(items[11].attachments?.images).toHaveLength(1);
    await onApi(page, 'GET', new RegExp(`${API}/feed/for-you`), (route) => reply(route, 200, { items, nextCursor: null }));

    // Home through the router, so the routed feed is used (a server-rendered "/" reuses the SSR answer).
    await page.goto('/settings');
    await page.locator('rd-top-bar a[href="/"]:visible').first().click();
    await page.waitForURL((url) => url.pathname === '/');
    const cards = page.locator('rd-post-card');
    await expect(cards).toHaveCount(14, { timeout: FIRST_RENDER_MS });

    const opener = cards.nth(11).locator('[data-single-image]');
    await opener.scrollIntoViewIfNeeded();
    await settle(page);
    const before = await scrollY(page);
    expect(before).toBeGreaterThan(1000);
    const url = page.url();
    const viewer = page.locator('rd-media-viewer');

    for (const how of ['close button', 'Escape', 'browser Back'] as const) {
      await opener.click();
      await expect(viewer).toBeVisible();
      await expect(viewer.locator('[data-viewer-close]')).toBeVisible();
      if (how === 'close button') await viewer.locator('[data-viewer-close]').click();
      else if (how === 'Escape') await page.keyboard.press('Escape');
      else await page.goBack();
      await expect(viewer, how).toHaveCount(0);
      await settle(page);
      expect(await scrollY(page), `scroll position after closing with the ${how}`).toBe(before);
      await expect(opener, `focus after closing with the ${how}`).toBeFocused();
      expect(page.url()).toBe(url);
    }

    // The viewer left nothing in the history: Back leaves Home for the page before it.
    await page.goBack();
    await page.waitForURL((u) => u.pathname === '/settings');
  });
}
