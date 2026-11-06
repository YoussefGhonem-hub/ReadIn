import { Page, Route, expect, test } from '@playwright/test';
import { VARIANTS, useVariant } from './support/mock-api';
import { signInAsReader } from './support/social';

/**
 * Infinite scroll on Home and the profile (leftovers 8): the next cursor page loads when the end of the list nears, not
 * at once on open (it used to on Home, signed in: the sentinel next to the loading skeletons reported "near" and that
 * report landed once page 1 was shown). A short first page with a next cursor does load the next one, as its end is on
 * screen. The mock API's lists have one page, so the first page here gets a next cursor and the second is empty.
 */
test.describe.configure({ timeout: 90_000 });

const FIRST_RENDER_MS = 30_000;
/** Long enough for a stray page-2 request after page 1 is shown. */
const SETTLE_MS = 1500;

/** Gives the list's first page a next cursor; records the page-2 requests (answered with an empty last page). */
async function pagedList(page: Page, pattern: string): Promise<string[]> {
  const pageTwo: string[] = [];
  await page.route(pattern, async (route: Route) => {
    const url = new URL(route.request().url());
    if (url.searchParams.get('cursor')) {
      pageTwo.push(url.searchParams.get('cursor')!);
      return route.fulfill({ json: { items: [], nextCursor: null } });
    }
    const response = await route.fetch();
    return route.fulfill({ response, json: { ...(await response.json()), nextCursor: 'p2' } });
  });
  return pageTwo;
}

for (const variant of VARIANTS) {
  const suffix = `${variant.lang}-${variant.theme}`;

  test(`infinite scroll: Home asks for page 2 near the end, not on open — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    const pageTwo = await pagedList(page, '**/api/v1/feed/for-you**');
    // Open Home from another page, so For you loads in the browser (skeletons first).
    await page.goto('/explore');
    await page.waitForLoadState('networkidle');
    await page.locator('a[href="/"]').first().click();
    const cards = page.locator('[data-feed] rd-post-card');
    await expect(cards.first()).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForTimeout(SETTLE_MS);
    expect(pageTwo).toEqual([]);

    // Near the end of the list, page 2 loads; it is the last, so the feed says so.
    await cards.last().scrollIntoViewIfNeeded();
    await page.mouse.wheel(0, 4000);
    await expect.poll(() => pageTwo).toEqual(['p2']);
    await expect(page.locator('#home-panel-forYou')).toContainText(variant.lang === 'ar' ? 'وصلت إلى النهاية' : "You're all caught up");
  });

  test(`infinite scroll: a short first page on a profile loads the next at once (its end is on screen) — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    const pageTwo = await pagedList(page, '**/api/v1/users/karim/articles**');
    await page.goto('/@karim');
    await expect(page.locator('[data-profile-articles] rd-post-card').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect.poll(() => pageTwo).toEqual(['p2']);
    await page.waitForTimeout(SETTLE_MS);
    // Once: the empty last page ends the list.
    expect(pageTwo).toEqual(['p2']);
    await expect(page.locator('[data-profile-articles]')).toContainText(variant.lang === 'ar' ? 'هذا كل شيء.' : 'That’s everything.');
  });
}
