import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, HIDE_COMMENTS, VARIANTS, imagesLoaded, parkMouse, useVariant } from './support/mock-api';
import { expectSignInPrompt, signInAsReader } from './support/social';

/**
 * F09 Learning paths and F03's Home cards end to end in ar/en × light/dark: the paths list (server-rendered, field
 * chips, My paths), a path as a guest, enrolled (Continue, Leave with a confirm, Start again) and completed (Read
 * again), Home's "Continue reading" and learning path cards, and the reader's "Next in path" block. The mock API keeps
 * each reader's enrollments (e2e/mock-api/paths.mjs): seeded readers are on "Web development foundations" (2 of 3),
 * finished "AI from scratch" and haven't joined "Learn how to learn".
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

/** Opens a paths page and waits for its content: signed in, the server-rendered (anonymous) copy loads again with your token. */
async function openPaths(page: Page, path: string, options: { signedIn?: boolean } = {}): Promise<void> {
  const personalized = options.signedIn
    ? page.waitForResponse((r) => r.request().method() === 'GET' && new URL(r.url()).pathname.endsWith(`/api/v1${path}`) && !!r.request().headers()['authorization'])
    : null;
  await page.goto(path);
  await personalized;
  await expect(page.locator(path === '/paths' ? '[data-path-card]' : '[data-path-header]').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`paths: the list as a guest, field chips, My paths asks to sign in — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);

    // Server-rendered for guests and crawlers.
    const response = await page.goto('/paths');
    expect(response!.status()).toBe(200);
    await page.waitForLoadState('networkidle'); // hydrated: the chips and tabs respond
    const html = await response!.text();
    expect(html).toContain(ar ? '<title>المسارات — ReadIn</title>' : '<title>Learning paths — ReadIn</title>');
    expect(html).toContain('data-path-card="web-foundations"');
    expect(html).toMatch(/<link rel="canonical" href="[^"]*\/paths"/);

    const cards = page.locator('[data-path-card]');
    await expect(cards).toHaveCount(3, { timeout: FIRST_RENDER_MS });
    await expect(cards.first()).toContainText(ar ? 'أساسيات تطوير الويب' : 'Web development foundations');
    await expect(cards.first().locator('[data-path-meta]')).toContainText(ar ? '3 مقالات' : '3 articles');
    // Guests see no progress.
    await expect(page.locator('[data-path-progress]')).toHaveCount(0);
    await imagesLoaded(page.locator('[data-paths-list]'));
    await parkMouse(page);
    await expect(page).toHaveScreenshot(`paths-list-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });

    // Field chips come from the paths in the list and filter it here.
    await page.locator('[data-path-field-chip="medicine"]').click();
    await expect(cards).toHaveCount(1);
    await expect(cards.first()).toHaveAttribute('data-path-card', 'learn-how-to-learn');
    await page.locator('[data-path-field-chips] .rd-chip').first().click();
    await expect(cards).toHaveCount(3);

    // My paths needs an account.
    await page.locator('[data-paths-tab="mine"]').click();
    await expectSignInPrompt(page);
    await expect(page.locator('[data-paths-tab="all"]')).toHaveAttribute('aria-selected', 'true');

    // A card opens its path; an unknown one is a real 404.
    await cards.nth(1).click();
    await page.waitForURL('**/paths/ai-from-scratch');
    await expect(page.locator('[data-path-title]')).toContainText(ar ? 'الـ AI من الصفر' : 'AI from scratch', { timeout: FIRST_RENDER_MS });
    const missing = await page.goto('/paths/no-such-path');
    expect(missing!.status()).toBe(404);
    await expect(page.locator('[data-path-not-found]')).toBeVisible();
  });

  test(`paths: a path as a guest — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const response = await page.goto('/paths/web-foundations');
    await page.waitForLoadState('networkidle');
    const html = await response!.text();
    expect(html).toContain(ar ? '<title>أساسيات تطوير الويب — ReadIn</title>' : '<title>Web development foundations — ReadIn</title>');
    expect(html).toContain('data-path-items');

    await expect(page.locator('[data-path-header]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    const items = page.locator('[data-path-item]');
    await expect(items).toHaveCount(3);
    await expect(page.locator('[data-read-tick]')).toHaveCount(0);
    await expect(page.locator('[data-path-progress]')).toHaveCount(0);
    await expect(page.locator('[data-path-menu]')).toHaveCount(0);
    await expect(items.first().locator('a')).toHaveAttribute('href', '/en/a/clean-architecture-whiteboard');
    await imagesLoaded(page.locator('[data-path-header]'));
    await parkMouse(page);
    await expect(page).toHaveScreenshot(`path-guest-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });

    await page.locator('[data-path-start]').click();
    await expectSignInPrompt(page);
  });

  test(`paths: enrolled — My paths, Continue, Leave, Start again — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);

    // My paths: the one in progress first, then the one you finished.
    await openPaths(page, '/paths', { signedIn: true });
    await page.locator('[data-paths-tab="mine"]').click();
    const mine = page.locator('[data-path-card]');
    await expect(mine).toHaveCount(2);
    await expect(mine.first()).toHaveAttribute('data-path-card', 'web-foundations');
    await expect(mine.first().locator('[data-path-progress]')).toContainText('2/3');
    await expect(mine.nth(1).locator('[data-path-completed]')).toBeVisible();

    // The path: your progress, ✓ on what you read, the next one highlighted, Continue with it.
    await openPaths(page, '/paths/web-foundations', { signedIn: true });
    await expect(page.locator('[data-path-progress]')).toContainText('2/3');
    await expect(page.locator('[data-read-tick]')).toHaveCount(2);
    await expect(page.locator('[data-path-item][data-next]')).toHaveAttribute('data-path-item', '3');
    const cont = page.locator('[data-path-continue]');
    await expect(cont).toHaveAttribute('href', '/en/a/aspnet-core-cheatsheet');
    await expect(cont).toContainText('ASP.NET Core cheat sheet (PDF)');
    await imagesLoaded(page.locator('[data-path-header]'));
    await parkMouse(page);
    await expect(page).toHaveScreenshot(`path-enrolled-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });

    // Leave path: ⋯ → Leave → confirm. The progress stays; Start is back, also after a reload.
    await page.locator('[data-path-menu]').click();
    await page.locator('[data-path-leave]').click();
    const sheet = page.locator('[data-leave-path]');
    await expect(sheet).toContainText(ar ? 'تسيب «أساسيات تطوير الويب»؟' : 'Leave “Web development foundations”?');
    const left = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().endsWith('/me/paths/p-web'));
    await sheet.locator('[data-confirm-leave]').click();
    expect((await left).status()).toBe(204);
    await expect(sheet).toHaveCount(0);
    await expect(page.locator('[data-path-start]')).toBeVisible();
    await expect(page.locator('[data-path-progress]')).toContainText('2/3');
    await openPaths(page, '/paths/web-foundations', { signedIn: true });
    await expect(page.locator('[data-path-start]')).toBeVisible();

    // Start path: enrolls and opens the first unread article.
    const enrolled = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith('/me/paths/p-web'));
    await page.locator('[data-path-start]').click();
    expect((await enrolled).status()).toBe(200);
    await page.waitForURL('**/en/a/aspnet-core-cheatsheet');
  });

  test(`paths: completed — badge, celebration, Read again — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openPaths(page, '/paths/ai-from-scratch', { signedIn: true });
    await expect(page.locator('[data-path-header] [data-path-completed]')).toBeVisible();
    await expect(page.locator('[data-path-celebration]')).toContainText(ar ? 'خلصت المسار 🎉' : 'Path completed 🎉');
    await expect(page.locator('[data-read-tick]')).toHaveCount(2);
    await expect(page.locator('[data-path-again]')).toHaveAttribute('href', '/ar/a/what-is-a-transformer-ar');
    await parkMouse(page);
    await expect(page).toHaveScreenshot(`path-completed-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });
  });

  test(`home: Continue reading and your learning path — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00'));
    await signInAsReader(page, request, variant);
    await page.goto('/');
    await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS }); // the session is restored

    // The most recent unfinished article, in the version you were reading.
    const resume = page.locator('[data-continue-reading]');
    await expect(resume).toHaveAttribute('href', '/en/a/react-server-components-explained');
    await expect(resume.locator('[role="progressbar"]')).toHaveAttribute('aria-valuenow', '42');
    // Your path in progress: read/total and the next article as the main action.
    const path = page.locator('[data-home-path]');
    await expect(path.locator('[data-home-path-count]')).toHaveText('2/3');
    await expect(page.locator('[data-home-path-next]')).toHaveAttribute('href', '/en/a/aspnet-core-cheatsheet');
    await expect(page.locator('[data-home-path-prompt]')).toHaveCount(0);
    await page.waitForLoadState('networkidle');
    await parkMouse(page);
    // The two cards (the greeting's 🔥 badge loads on its own schedule, so it stays out of the shot).
    const top = (await resume.boundingBox())!;
    const bottom = (await path.boundingBox())!;
    await expect(page).toHaveScreenshot(`home-signed-in-${suffix}.png`, {
      clip: { x: 0, y: top.y - 16, width: page.viewportSize()!.width, height: bottom.y + bottom.height + 32 - top.y },
      stylePath: HIDE_APP_CHROME,
    });

    // The card opens the path; Home again (fresh cards), and the next article opens the reader.
    await page.locator('[data-home-path-link]').click();
    await page.waitForURL('**/paths/web-foundations');
    await expect(page.locator('[data-path-header]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.goBack();
    await page.locator('[data-home-path-next]').click();
    await page.waitForURL('**/en/a/aspnet-core-cheatsheet');
  });

  test(`home: a reader with no path in progress sees the way to the paths — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant, 'fresh');
    await page.goto('/');
    await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS });
    const prompt = page.locator('[data-home-path-prompt]');
    await expect(prompt).toContainText(ar ? 'اتعلم خطوة بخطوة مع المسارات' : 'Learn step by step with learning paths');
    await expect(page.locator('[data-continue-reading]')).toHaveCount(0);
    await prompt.click();
    await page.waitForURL('**/paths');
    await expect(page.locator('[data-path-card]')).toHaveCount(3, { timeout: FIRST_RENDER_MS });
  });

  test(`reader: Next in path — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);

    // First of three: the path, "1 of 3" with your progress and the next article's card.
    const loaded = page.waitForResponse((r) => r.url().endsWith('/articles/a-clean-architecture-whiteboard/path') && !!r.request().headers()['authorization']);
    await page.goto('/en/a/clean-architecture-whiteboard');
    await loaded;
    const block = page.locator('[data-next-in-path-block]');
    await expect(block).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(block.locator('[data-next-path-link]')).toHaveAttribute('href', '/paths/web-foundations');
    await expect(block.locator('[data-next-position]')).toContainText(ar ? '1 من 3' : '1 of 3');
    await expect(block.locator('[data-next-progress]')).toContainText('2/3');
    await expect(block.locator('[data-next-article]')).toContainText('Dependency Injection');
    await expect(block.locator('[data-join-path]')).toHaveCount(0);
    // After the sources, before the comments.
    expect(await page.evaluate(() => {
      const sources = document.getElementById('sources-title')!.closest('rd-article-sources')!;
      const next = document.querySelector('rd-next-in-path')!;
      const comments = document.getElementById('comments')!;
      return sources.nextElementSibling === next && !!(next.compareDocumentPosition(comments) & Node.DOCUMENT_POSITION_FOLLOWING);
    })).toBe(true);
    await parkMouse(page);
    await expect(block).toHaveScreenshot(`next-in-path-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_COMMENTS] });

    // The last article of a finished path: no next card, and 🎉.
    await page.goto('/en/a/how-readin-picks-your-daily-article');
    await expect(block.locator('[data-next-last]')).toContainText(ar ? 'ده آخر مقال في المسار' : 'This is the last article in the path', { timeout: FIRST_RENDER_MS });
    await expect(block.locator('[data-next-completed]')).toBeVisible();

    // A path you haven't joined: Join path, then your progress.
    await page.goto('/en/a/sleep-and-memory');
    const join = block.locator('[data-join-path]');
    await expect(join).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(block.locator('[data-next-progress]')).toContainText('0/3');
    await join.click();
    await expect(join).toHaveCount(0);
    await expect(block.locator('[data-next-progress]')).toBeVisible();
  });

  test(`reader: a guest's Join path asks to sign in — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/ar/a/dependency-injection-ar');
    await page.waitForLoadState('networkidle');
    // The block loads as the end of the article nears the viewport.
    await page.locator('#sources-title').scrollIntoViewIfNeeded();
    const block = page.locator('[data-next-in-path-block]');
    await expect(block).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(block.locator('[data-next-position]')).toContainText(ar ? '2 من 3' : '2 of 3');
    await expect(block.locator('[data-next-progress]')).toHaveCount(0);
    await block.locator('[data-join-path]').click();
    await expectSignInPrompt(page);
  });
}
