import { expect, test } from '@playwright/test';
import { VARIANTS, useVariant } from './support/mock-api';
import { openArticle, signInAsReader } from './support/social';

/**
 * A deleted account's published articles stay up (SPEC F01, §9.6): the API sends `author: null` and the reader shows
 * "Deleted user" with a neutral avatar, and no name, photo, profile link, @username, verified mark or Follow. The mock
 * API's `sql-indexes-in-plain-words` is such an article (e2e/mock-api/server.mjs).
 */
test.describe.configure({ timeout: 90_000 });

const PATH = '/en/a/sql-indexes-in-plain-words';
const LABEL = { ar: 'مستخدم محذوف', en: 'Deleted user' };
const VERIFIED = { ar: 'كاتب موثّق', en: 'Verified writer' };

for (const variant of VARIANTS) {
  const { lang, theme } = variant;

  test(`reader: an article whose author deleted their account — ${lang}-${theme}`, async ({ page, context, baseURL, request }) => {
    const errors: Error[] = [];
    page.on('pageerror', (error) => errors.push(error));
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openArticle(page, PATH);

    const article = page.locator('article');
    const byline = page.locator('[data-byline]');
    await expect(article.locator('h1')).toHaveText('SQL indexes in plain words');
    await expect(byline.locator('[data-deleted-author]')).toHaveText(LABEL[lang]);
    await expect(byline.locator('rd-avatar[data-generic-avatar]')).toBeVisible();
    await expect(byline.locator('rd-avatar')).toHaveText('');

    // Nothing that leads to the person: no profile link, @username, verified mark or Follow.
    await expect(byline.locator('a')).toHaveCount(0);
    await expect(article.locator('a[href*="/@"]')).toHaveCount(0);
    await expect(page.locator('[data-author-follow], [data-follow]')).toHaveCount(0);
    await expect(article).not.toContainText(VERIFIED[lang]);
    for (const text of ['undefined', 'null']) await expect(article).not.toContainText(text);

    // The rest of the reader works as usual.
    await expect(page.locator('rd-article-action-bar [data-reaction-total]')).toHaveText('7');
    expect(errors).toEqual([]);
  });
}

test.describe('server-rendered, as crawlers and guests see it', () => {
  test.use({ javaScriptEnabled: false });

  test('shows “Deleted user” and leaves the author out of the structured data', async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, VARIANTS[1]); // en/dark
    const response = await page.goto(PATH);
    expect(response!.status()).toBe(200);
    await expect(page.locator('[data-byline] [data-deleted-author]')).toHaveText('Deleted user');
    await expect(page.locator('[data-follow]')).toHaveCount(0);
    await expect(page.locator('article a[href*="/@"]')).toHaveCount(0);

    const jsonLd = JSON.parse((await page.locator('script[type="application/ld+json"]').textContent())!) as Record<string, unknown>;
    expect(jsonLd['headline']).toBe('SQL indexes in plain words');
    expect(jsonLd).not.toHaveProperty('author');
  });
});
