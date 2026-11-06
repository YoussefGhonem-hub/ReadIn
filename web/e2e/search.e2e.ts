import { Locator, Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, VARIANTS, hasScreenshot, imagesLoaded, onApi, parkMouse, problem, reply, useVariant } from './support/mock-api';
import { expectSignInPrompt, signInAsReader } from './support/social';

/**
 * F16 Search end to end in ar/light and en/dark: the search page (server-rendered without results and `noindex`, as
 * you type and on Enter, the four tabs, the Articles filters, infinite scroll, a hit inside an attached PDF, Arabic
 * spelling variants, empty and error states, Back from a result), recent searches on the device (newest first,
 * remove one, clear all), and the header's search box on wide screens (recent searches, suggestions, the keyboard)
 * or its icon on narrow ones. The mock API (e2e/mock-api/search.mjs) searches the fixtures: `kestrel` is only in the
 * cheat sheet's PDF, `c` finds 23 articles (two pages), `mona` is a writer, `arch` a topic, `#c` five tags.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

const box = (page: Page): Locator => page.locator('[data-search-input]');
const results = (page: Page): Locator => page.locator('[data-search-results]');
const articleRows = (page: Page): Locator => page.locator('[data-search-article]');
const tab = (page: Page, type: string): Locator => page.locator(`[data-search-tab="${type}"]`);
const query = (page: Page, name: string): string | null => new URL(page.url()).searchParams.get(name);
/** The recent searches on the page, newest first (polled: the list follows the URL). */
const recentList = (page: Page) => expect.poll(() => page.locator('[data-recent]').evaluateAll((list) => list.map((r) => r.getAttribute('data-recent'))));
/** The header's recent-search options, newest first. */
const recentOptions = (page: Page) =>
  expect.poll(() => page.locator('[data-header-search-popup] [data-recent-option]').evaluateAll((list) => list.map((o) => o.getAttribute('data-recent-option'))));

/** Opens the search page and waits until it is hydrated (the idle state and results only render in the browser). */
async function openSearch(page: Page, path = '/search') {
  const response = await page.goto(path);
  await expect(page.locator('[data-search-start], [data-recent-searches], [data-search-results][data-status="loaded"], [data-search-results][data-status="error"]').first()).toBeVisible({
    timeout: FIRST_RENDER_MS,
  });
  await page.waitForLoadState('networkidle');
  return response!;
}

/** Waits for the URL's `q` (and other parameters) after typing or a click. */
async function urlHas(page: Page, params: Record<string, string | null>) {
  await page.waitForURL((url) => url.pathname === '/search' && Object.entries(params).every(([k, v]) => url.searchParams.get(k) === v));
}

async function loaded(page: Page) {
  await expect(results(page)).toHaveAttribute('data-status', 'loaded');
}

/** The `/search` API calls the page makes, as their query strings. */
function trackSearches(page: Page): URLSearchParams[] {
  const calls: URLSearchParams[] = [];
  page.on('request', (r) => {
    const url = new URL(r.url());
    if (r.method() === 'GET' && url.pathname === '/api/v1/search') calls.push(url.searchParams);
  });
  return calls;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`search page: noindex, as you type, a PDF hit, tabs, Arabic spellings, Back from a result — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const errors: string[] = [];
    page.on('console', (m) => {
      if (m.type() === 'error' && /NG0\d+/.test(m.text())) errors.push(m.text());
    });

    // Server-rendered without results (the browser searches), never indexed.
    const ssr = await openSearch(page, '/search?q=kestrel');
    expect(ssr.status()).toBe(200);
    expect(ssr.headers()['x-robots-tag']).toBe('noindex');
    const html = await ssr.text();
    expect(html).toMatch(/<meta name="robots" content="noindex"/);
    expect(html).toContain('data-search-loading');
    expect(html).not.toContain('data-search-article');
    await expect(page).toHaveTitle(t('بحث — ReadIn', 'Search — ReadIn'));
    await expect(box(page)).toHaveValue('kestrel');
    await expect(box(page)).toHaveAttribute('dir', 'auto');

    // Only the attached PDF has the word: the compact row says so.
    await expect(articleRows(page)).toHaveCount(1);
    const row = articleRows(page).first();
    await expect(row).toHaveAttribute('data-article', 'a-aspnet-core-cheatsheet');
    await expect(row).toHaveAttribute('data-matched-in', 'attachment');
    await expect(row.locator('[data-in-attachment]')).toHaveText(t('وُجدت في ملف PDF المرفق', 'Found in the attached PDF'));
    // No full-width PDF pages in a search row: the first page is the thumbnail.
    await expect(row.locator('rd-article-attachments')).toHaveCount(0);
    await expect(page.locator('[data-search-end]')).toHaveText(t('هذه كل النتائج.', "That's everything we found."));
    await imagesLoaded(row);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`search-results-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Another tab keeps the query; nothing there.
    await tab(page, 'users').click();
    await urlHas(page, { q: 'kestrel', type: 'users' });
    await expect(tab(page, 'users')).toHaveAttribute('aria-selected', 'true');
    await expect(page.locator('[data-search-empty] h3')).toHaveText(t('لا توجد نتائج لـ «⁨kestrel⁩»', 'No results for “⁨kestrel⁩”'));

    // As you type (after a pause), on the tab you are on: a writer, with Follow (guests are asked to sign in).
    await box(page).fill('mona');
    await urlHas(page, { q: 'mona', type: 'users' });
    await loaded(page);
    const mona = page.locator('[data-search-user][data-user="mona"]');
    await expect(mona).toContainText('Mona Adel');
    await mona.locator('[data-follow]').click();
    await expectSignInPrompt(page);

    // Topics open the field page (F15) with the topic.
    await tab(page, 'topics').click();
    await box(page).fill('arch');
    await urlHas(page, { q: 'arch', type: 'topics' });
    const topic = page.locator('[data-search-topic]');
    await expect(topic).toHaveCount(1);
    await expect(topic).toHaveAttribute('href', '/f/software?topic=architecture');
    await expect(topic).toHaveAttribute('data-kind', 'topic');
    await expect(topic).toContainText(t('المعمارية', 'Architecture'));

    // Arabic spellings don't matter: "ازاي" finds "إزاي".
    await tab(page, 'articles').click();
    await box(page).fill('ازاي streak');
    await urlHas(page, { q: 'ازاي streak', type: null });
    await expect(articleRows(page)).toHaveCount(1);
    await expect(articleRows(page).first()).toHaveAttribute('data-article', 'a-readin-streaks-ar');

    // Tags (a leading # is dropped); one opens its page, and Back brings the results back as they were.
    await tab(page, 'tags').click();
    await box(page).fill('#C#');
    await urlHas(page, { q: 'C#', type: 'tags' });
    const tags = page.locator('[data-search-tag]');
    await expect(tags.first()).toHaveAttribute('data-tag', 'csharp');
    await expect(tags.first()).toContainText('#C#');
    // The row follows the page's direction: an English tag starts on the page's start side, not next to the count.
    // The rows sit inside the results card with their own start padding, so the name starts right after it.
    const tagName = (await tags.first().locator('bdi').boundingBox())!;
    const tagRow = (await tags.first().boundingBox())!;
    const rowPadding = await tags.first().evaluate((row) => parseFloat(getComputedStyle(row).paddingInlineStart));
    const fromStart = lang === 'ar' ? tagRow.x + tagRow.width - (tagName.x + tagName.width) : tagName.x - tagRow.x;
    expect(Math.abs(fromStart - rowPadding)).toBeLessThan(2);
    await tags.first().click();
    await page.waitForURL((url) => url.pathname === '/tags/csharp');
    await expect(page.locator('[data-tag-name]')).toHaveText('#C#', { timeout: FIRST_RENDER_MS });
    await page.goBack();
    await urlHas(page, { q: 'C#', type: 'tags' });
    await expect(tags.first()).toHaveAttribute('data-tag', 'csharp');
    await expect(tab(page, 'tags')).toHaveAttribute('aria-selected', 'true');

    // Opening the tag kept "C#" in your recent searches; the ✕ empties the box.
    await page.locator('[data-search-clear]').click();
    await urlHas(page, { q: null, type: 'tags' });
    await expect(box(page)).toBeFocused();
    await recentList(page).toEqual(['C#']);
    expect(errors).toEqual([]);
  });

  test(`search page: Enter from one character, infinite scroll to the end, filters — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const calls = trackSearches(page);
    await openSearch(page);
    await expect(box(page)).toBeFocused();

    // One character waits for Enter.
    await box(page).fill('c');
    await page.waitForTimeout(600);
    expect(query(page, 'q')).toBeNull();
    expect(calls).toHaveLength(0);
    await box(page).press('Enter');
    await urlHas(page, { q: 'c' });
    await loaded(page);
    await expect(articleRows(page)).toHaveCount(20);
    expect(calls.at(-1)?.get('limit')).toBe('20');

    // The next cursor page near the end, then the end.
    await articleRows(page).last().scrollIntoViewIfNeeded();
    await expect(articleRows(page)).toHaveCount(23);
    await expect(page.locator('[data-search-end]')).toBeVisible();
    expect(calls.at(-1)?.get('cursor')).toBe('20');

    // Article language: only the Arabic versions (the same ones the API finds).
    const filters = page.locator('[data-search-filters]');
    await filters.locator('[data-filter="lang"]').selectOption('ar-EG');
    await urlHas(page, { q: 'c', lang: 'ar-EG' });
    await loaded(page);
    const arabic = (await (await request.get(`${API}/search?q=c&lang=ar-EG`)).json()) as { items: { article: { id: string } }[] };
    expect(arabic.items.length).toBeGreaterThan(0);
    await expect(articleRows(page)).toHaveCount(arabic.items.length);
    expect(await articleRows(page).evaluateAll((list) => list.map((r) => r.getAttribute('data-article')))).toEqual(arabic.items.map((i) => i.article.id));
    expect(calls.at(-1)?.get('lang')).toBe('ar-EG');

    // Reading time: the chips' ranges.
    const time = filters.locator('[data-filter="time"]');
    await time.selectOption('short');
    await urlHas(page, { time: 'short' });
    await loaded(page);
    expect([calls.at(-1)?.get('minMinutes'), calls.at(-1)?.get('maxMinutes')]).toEqual([null, '5']);
    await time.selectOption('medium');
    await urlHas(page, { time: 'medium' });
    await loaded(page);
    expect([calls.at(-1)?.get('minMinutes'), calls.at(-1)?.get('maxMinutes')]).toEqual(['6', '10']);
    await time.selectOption('long');
    await urlHas(page, { time: 'long' });
    await loaded(page);
    expect([calls.at(-1)?.get('minMinutes'), calls.at(-1)?.get('maxMinutes')]).toEqual(['11', null]);

    // Nothing that long in Arabic: the empty state offers to clear the filters.
    const empty = page.locator('[data-search-empty="filtered"]');
    await expect(empty.locator('h3')).toHaveText(t('لا توجد نتائج تطابق عوامل التصفية هذه', 'No results with these filters'));
    await empty.locator('button').click();
    await urlHas(page, { q: 'c', lang: null, time: null });
    await loaded(page);
    await expect(articleRows(page)).toHaveCount(20);
    await expect(filters.locator('[data-clear-filters]')).toHaveCount(0);
  });

  test(`recent searches: newest first, one per query, remove one, clear all; empty results — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await openSearch(page);
    await expect(page.locator('[data-search-start] h2')).toHaveText(t('عمّ تريد أن تقرأ؟', 'What do you want to read about?'));

    // A search with no results says so, with a tip.
    await box(page).fill('docker');
    await box(page).press('Enter');
    await urlHas(page, { q: 'docker' });
    const empty = page.locator('[data-search-empty]');
    await expect(empty.locator('h3')).toHaveText(t('لا توجد نتائج لـ «⁨docker⁩»', 'No results for “⁨docker⁩”'));
    await expect(empty).toContainText(t('جرّب كلمة أخرى أو كلمة أقصر، أو ابحث في تبويب آخر.', 'Try another word or a shorter one, or look in another tab.'));

    for (const q of ['Kestrel', 'يعني إيه Transformer']) {
      await box(page).fill(q);
      await box(page).press('Enter');
      await urlHas(page, { q });
      await loaded(page);
    }
    // Emptying the box shows them, newest first; mixed Arabic and English keeps its own direction.
    await box(page).fill('');
    await urlHas(page, { q: null });
    const recent = page.locator('[data-recent]');
    await recentList(page).toEqual(['يعني إيه Transformer', 'Kestrel', 'docker']);
    await expect(recent.first().locator('bdi')).toHaveAttribute('dir', 'auto');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('[data-recent-searches]')).toHaveScreenshot(`search-recent-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // The same query in another case moves to the top instead of repeating.
    await box(page).fill('KESTREL');
    await box(page).press('Enter');
    await urlHas(page, { q: 'KESTREL' });
    await loaded(page);
    await box(page).fill('');
    await recentList(page).toEqual(['KESTREL', 'يعني إيه Transformer', 'docker']);

    // Remove one (focus stays in the list); they stay on the device after a reload; clear all.
    await recent.nth(1).locator('[data-recent-remove]').click();
    await recentList(page).toEqual(['KESTREL', 'docker']);
    await expect(page.locator('[data-recent-open]').first()).toBeFocused();
    await openSearch(page);
    await recentList(page).toEqual(['KESTREL', 'docker']);
    // A recent search runs again.
    await recent.nth(1).locator('[data-recent-open]').click();
    await urlHas(page, { q: 'docker' });
    await expect(box(page)).toHaveValue('docker');
    await box(page).fill('');
    await page.locator('[data-recent-clear]').click();
    await expect(recent).toHaveCount(0);
    await expect(page.locator('[data-search-start]')).toBeVisible();
    await expect(box(page)).toBeFocused();
  });

  test(`a failed search shows Retry; signed in, Follow a writer from the results — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant, 'fresh');
    let failures = 1;
    await onApi(page, 'GET', /\/api\/v1\/search\?/, (route) => (failures-- > 0 ? reply(route, 500, problem(500, 'server.error')) : route.fallback()));

    await openSearch(page, '/search?q=mona&type=users');
    const error = page.locator('[data-search-error]');
    await expect(error).toContainText(t('تعذّر إجراء البحث الآن.', "We couldn't search right now."));
    await error.locator('button').click();
    await loaded(page);
    const mona = page.locator('[data-search-user][data-user="mona"]');
    const follow = mona.locator('[data-follow]');
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    const followed = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith('/users/u-writer/follow'));
    await follow.click();
    await followed;
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(follow).toContainText(t('تتابعه', 'Following'));
  });

  test(`header: the search box with recent searches and suggestions (wide), the search icon (narrow) — ${suffix}`, async ({ page, context, baseURL }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/');
    if (testInfo.project.name === 'mobile') {
      // Narrow screens: the icon opens the search page, ready to type.
      const icon = page.locator('rd-top-bar [data-search-link]');
      await expect(icon).toBeVisible({ timeout: FIRST_RENDER_MS });
      await expect(page.locator('rd-top-bar [data-header-search-placeholder], rd-top-bar [data-header-search-input]')).toBeHidden();
      await page.waitForLoadState('networkidle');
      await icon.click();
      await page.waitForURL((url) => url.pathname === '/search');
      await expect(box(page)).toBeFocused({ timeout: FIRST_RENDER_MS });
      await expect(page.locator('rd-top-bar [data-search-link]')).toHaveCount(0);
      return;
    }

    const input = page.locator('[data-header-search-input]');
    await expect(input).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('rd-top-bar [data-search-link]')).toBeHidden();
    const popup = page.locator('[data-header-search-popup]');
    const options = popup.locator('[role="option"]');

    // Nothing searched yet: focusing opens nothing.
    await input.focus();
    await expect(popup).toHaveCount(0);

    // As you type: writers, topics… then "See all results"; the keyboard picks one.
    await input.fill('mona');
    await expect(popup.locator('[data-group="users"] [data-option="user"]')).toHaveCount(1);
    await expect(popup.locator('[data-group="users"]')).toContainText('Mona Adel');
    await expect(options.last()).toHaveAttribute('data-option', 'all');
    await expect(options.last()).toContainText(t('عرض كل نتائج «⁨mona⁩»', 'See all results for “⁨mona⁩”'));
    await expect(input).toHaveAttribute('aria-expanded', 'true');
    await parkMouse(page);
    if (hasScreenshot(variant)) {
      const bar = (await page.locator('rd-top-bar').boundingBox())!;
      const list = (await popup.boundingBox())!;
      await expect(page).toHaveScreenshot(`header-search-${suffix}.png`, {
        clip: { x: 0, y: 0, width: page.viewportSize()!.width, height: list.y + list.height + 16 - bar.y },
      });
    }
    await input.press('ArrowDown');
    await expect(input).toHaveAttribute('aria-activedescendant', /header-search-list-0/);
    await input.press('Enter');
    await page.waitForURL((url) => url.pathname === '/@mona');

    // Enter without a pick opens the search page, which has its own box.
    await page.goto('/');
    await expect(input).toBeVisible({ timeout: FIRST_RENDER_MS });
    await input.fill('kestrel');
    await expect(options.last()).toHaveAttribute('data-option', 'all');
    await input.press('Enter');
    await urlHas(page, { q: 'kestrel' });
    await expect(box(page)).toHaveValue('kestrel');
    await expect(page.locator('[data-header-search-input], [data-header-search-placeholder]')).toHaveCount(0);
    await loaded(page);

    // Back home, the empty box lists both searches; Delete removes the chosen one, Escape closes.
    await page.goBack();
    await page.waitForURL((url) => url.pathname === '/');
    await input.click();
    await expect(options).toHaveCount(2);
    await recentOptions(page).toEqual(['kestrel', 'mona']);
    await input.press('ArrowDown');
    await input.press('ArrowDown');
    await input.press('Delete');
    await recentOptions(page).toEqual(['kestrel']);
    await input.press('Escape');
    await expect(popup).toHaveCount(0);
    // A recent search opens the search page.
    await input.press('ArrowDown');
    await expect(options).toHaveCount(1);
    await input.press('Enter');
    await urlHas(page, { q: 'kestrel' });
  });
}
