import { Locator, Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, imagesLoaded, parkMouse, useVariant } from './support/mock-api';
import { expectSignInPrompt, signInAsReader } from './support/social';

/**
 * F15 Explore and field pages end to end in ar/light and en/dark. Explore (server-rendered): every field, the first
 * three trending and most saved articles with "See all" (the whole ranking as post cards, infinite scroll), new
 * writers and featured paths; Back from a ranking finds Explore as it was. A field page (server-rendered with title,
 * canonical and counts): topic chips that filter (also the `?topic=` link Search gives a topic), top writers, post cards
 * with infinite scroll; following the field and a topic (the follower count moves by 1, at least 3 interests stay);
 * the health note on a sensitive field; an empty field (noindex), an unknown field and an unknown topic (404). The
 * mock API (e2e/mock-api/explore.mjs) has 32 Software articles (two of them .NET, one Architecture), one Medicine
 * article and an empty Design field.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** Cards say how long ago each article was published: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');

const cards = (page: Page): Locator => page.locator('[data-card-list] rd-post-card');
const ids = (list: Locator) => list.evaluateAll((items) => items.map((c) => c.getAttribute('data-post-card')));
const titles = (list: Locator) => list.evaluateAll((items) => items.map((c) => c.querySelector('h3')?.textContent?.trim() ?? ''));

async function open(page: Page, path: string, ready: string) {
  await page.clock.setFixedTime(NOW);
  const response = await page.goto(path);
  await expect(page.locator(ready).first()).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle'); // hydrated: links, follow buttons and infinite scroll respond
  return response!;
}

/** A field page with your follow state: SSR renders it anonymously, then it loads again with your token. */
async function openFieldSignedIn(page: Page, path: string) {
  const slug = new URL(path, 'http://x').pathname.split('/').pop()!;
  const personalized = page.waitForResponse(
    (r) => r.request().method() === 'GET' && new URL(r.url()).pathname.endsWith(`/fields/${slug}`) && !!r.request().headers()['authorization'],
  );
  await open(page, path, '[data-field-header]');
  await personalized;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`explore: server-rendered sections; "See all" opens the ranking as post cards; Back keeps Explore — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const response = await open(page, '/explore', '[data-explore-fields]');
    expect(response.status()).toBe(200);
    const html = await response.text();
    expect(html).toContain(`<title>${t('استكشاف', 'Explore')} — ReadIn</title>`);
    expect(html).toContain('data-field-tile="software"');
    expect(html).toContain('data-explore-trending');

    const tiles = page.locator('[data-field-tile]');
    await expect(tiles).toHaveCount(3);
    await expect(tiles.first()).toHaveAttribute('href', '/f/software');
    await expect(page.locator('[data-field-tile="software"] [data-field-count]')).toHaveText(t('32 مقالًا', '32 articles'));
    await expect(page.locator('[data-field-tile="design"] [data-field-count]')).toHaveText(t('0 مقال', '0 articles'));
    // The most engaging this week, then the most saved: three of each.
    expect(await titles(page.locator('[data-explore-trending] rd-article-card'))).toEqual([
      'يعني إيه Dependency Injection في ASP.NET Core؟',
      'إزاي الـ streak بيساعدك تقرا كل يوم',
      'My desk setup for focused reading',
    ]);
    expect(await titles(page.locator('[data-explore-most-saved] rd-article-card'))).toEqual([
      'How ReadIn picks your daily article',
      'يعني إيه Transformer في الـ AI؟',
      'React Server Components, explained without the hype',
    ]);
    await expect(page.locator('[data-explore-new-writers] [data-writer]')).toHaveCount(3);
    await expect(page.locator('[data-explore-new-writers] [data-writer]').first()).toContainText('@omar_dev');
    await expect(page.locator('[data-explore-paths] rd-path-card')).toHaveCount(3);
    // Narrow screens get the way into Search here; wide ones have the header's box.
    await expect(page.locator('[data-explore-search]')).toBeVisible({ visible: page.viewportSize()!.width < 768 });

    await imagesLoaded(page.locator('[data-explore-trending]'));
    await page.evaluate(() => window.scrollTo(0, 0));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`explore-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // "See all": the whole ranking as post cards, best first, 20 at a time.
    await page.locator('[data-see-all="trending"]').click();
    await page.waitForURL((url) => url.pathname === '/explore/trending');
    await expect(page.locator('h1')).toHaveText(t('الأكثر رواجًا هذا الأسبوع', 'Trending this week'));
    await expect(page).toHaveTitle(t('الأكثر رواجًا هذا الأسبوع — ReadIn', 'Trending this week — ReadIn'));
    await expect(cards(page)).toHaveCount(20, { timeout: FIRST_RENDER_MS });
    expect((await ids(cards(page))).slice(0, 3)).toEqual(['a-dependency-injection-ar', 'a-readin-streaks-ar', 'a-one-photo']);
    await cards(page).last().scrollIntoViewIfNeeded();
    await expect(cards(page)).toHaveCount(33);
    await expect(page.locator('[data-list-end]')).toHaveText(t('هذه كل المقالات الرائجة هذا الأسبوع.', "That's everything trending this week."));

    // Back: Explore as it was (kept alive), without loading again.
    let reloaded = false;
    page.on('request', (r) => {
      if (new URL(r.url()).pathname.endsWith('/api/v1/explore')) reloaded = true;
    });
    await page.goBack();
    await page.waitForURL((url) => url.pathname === '/explore');
    await expect(page.locator('[data-explore-trending] rd-article-card')).toHaveCount(3);
    await expect(page).toHaveTitle(t('استكشاف — ReadIn', 'Explore — ReadIn'));
    expect(reloaded).toBe(false);

    // Most saved has its own page.
    await page.locator('[data-see-all="most-saved"]').click();
    await page.waitForURL((url) => url.pathname === '/explore/most-saved');
    await expect(cards(page).first()).toHaveAttribute('data-post-card', 'a-how-readin-picks-your-daily-article', { timeout: FIRST_RENDER_MS });
  });

  test(`field page: server-rendered header, topic chips, top writers, post cards with infinite scroll; a chip filters — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const response = await open(page, '/f/software', '[data-field-header]');
    expect(response.status()).toBe(200);
    const html = await response.text();
    expect(html).toContain(`<title>${t('البرمجيات', 'Software')} — ReadIn</title>`);
    expect(html).toMatch(/<link rel="canonical" href="[^"]*\/f\/software"/);
    expect(html).not.toContain('noindex');
    expect(html).toContain('data-post-card="a-how-readin-picks-your-daily-article"');

    await expect(page.locator('[data-field-name]')).toHaveText(t('البرمجيات', 'Software'));
    await expect(page.locator('[data-field-name]')).toHaveAttribute('dir', 'auto');
    await expect(page.locator('[data-field-count]')).toHaveText(t('32 مقالًا', '32 articles'));
    await expect(page.locator('[data-field-followers]')).toHaveText(t('86 متابعًا', '86 followers'));
    await expect(page.locator('[data-follow-field]')).toHaveAttribute('aria-pressed', 'false');
    expect(await page.locator('[data-topic-chip]').evaluateAll((chips) => chips.map((c) => c.getAttribute('data-topic-chip')))).toEqual(['', 'dotnet', 'architecture']);
    await expect(page.locator('[data-topic-chip=""]')).toHaveAttribute('aria-current', 'page');
    await expect(page.locator('[data-field-writers] [data-writer]')).toHaveCount(3);
    await expect(page.locator('[data-health-disclaimer]')).toHaveCount(0);
    // Newest first.
    await expect(cards(page)).toHaveCount(20);
    await expect(cards(page).first()).toHaveAttribute('data-post-card', 'a-how-readin-picks-your-daily-article');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`field-page-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    await cards(page).last().scrollIntoViewIfNeeded();
    await expect(cards(page)).toHaveCount(32);
    await expect(page.locator('[data-list-end]')).toHaveText(t('اطّلعت على كل مقالات هذا المجال.', "You've seen every article in this field."));

    // A chip filters the articles; the topic can be followed from its bar.
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.locator('[data-topic-chip="dotnet"]').click();
    await page.waitForURL((url) => url.searchParams.get('topic') === 'dotnet');
    await expect(page.locator('[data-topic-chip="dotnet"]')).toHaveAttribute('aria-current', 'page');
    await expect(cards(page)).toHaveCount(2);
    expect(await ids(cards(page))).toEqual(['a-dependency-injection-ar', 'a-aspnet-core-cheatsheet']);
    await expect(page.locator('[data-topic-bar]')).toContainText(t('مقالان', '2 articles'));
    await expect(page).toHaveTitle(t('.NET · البرمجيات — ReadIn', '.NET · Software — ReadIn'));

    // Search's link for a topic, opened directly: server-rendered with that topic.
    const topic = await open(page, '/f/software?topic=architecture', '[data-topic-bar]');
    expect(topic.status()).toBe(200);
    expect(await topic.text()).toMatch(/<link rel="canonical" href="[^"]*\/f\/software\?topic=architecture"/);
    await expect(page.locator('[data-topic-chip="architecture"]')).toHaveAttribute('aria-current', 'page');
    await expect(cards(page)).toHaveCount(1);
    await expect(cards(page).first()).toHaveAttribute('data-post-card', 'a-clean-architecture-whiteboard');
    // "All" goes back to the whole field.
    await page.locator('[data-topic-chip=""]').click();
    await page.waitForURL((url) => url.pathname === '/f/software' && !url.searchParams.has('topic'));
    await expect(cards(page)).toHaveCount(20);
  });

  test(`field page: follow the field and a topic, at least 3 interests stay; the health note; guests sign in first — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // A guest: Follow asks to sign in. Medicine is sensitive: its page has the health note.
    await open(page, '/f/medicine', '[data-field-header]');
    await expect(page.locator('[data-health-disclaimer]')).toBeVisible();
    await page.locator('[data-follow-field]').click();
    await expectSignInPrompt(page);

    // Signed in, following Software, .NET and Architecture (3 interests): unfollowing Software is refused.
    await signInAsReader(page, request, variant);
    const follow = page.locator('[data-follow-field]');
    const followers = page.locator('[data-field-followers]');
    await openFieldSignedIn(page, '/f/software');
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(follow).toContainText(t('تتابعه', 'Following'));
    await expect(followers).toHaveText(t('87 متابعًا', '87 followers'));
    await follow.click();
    await expect(page.locator('rd-toast-host')).toContainText(t('يجب أن تتابع 3 اهتمامات على الأقل', 'Keep at least 3 interests'));
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(followers).toHaveText(t('87 متابعًا', '87 followers'));

    // Follow Medicine: at once, one more follower.
    await openFieldSignedIn(page, '/f/medicine');
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    await expect(followers).toHaveText(t('12 متابعًا', '12 followers'));
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(followers).toHaveText(t('13 متابعًا', '13 followers'));
    await expect(follow).not.toHaveAttribute('aria-busy', 'true');

    // A topic, from its bar: unfollow, follow again.
    await openFieldSignedIn(page, '/f/software?topic=dotnet');
    const topic = page.locator('[data-follow-topic]');
    await expect(topic).toHaveAttribute('aria-pressed', 'true');
    await topic.click();
    await expect(topic).toHaveAttribute('aria-pressed', 'false');
    await expect(topic).toContainText(t('متابعة الموضوع', 'Follow topic'));
    await expect(topic).not.toHaveAttribute('aria-busy', 'true');
    await topic.click();
    await expect(topic).toHaveAttribute('aria-pressed', 'true');
    await expect(topic).not.toHaveAttribute('aria-busy', 'true');

    // Now 4 interests: Software can go, one follower less; saved on the account.
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    await expect(followers).toHaveText(t('86 متابعًا', '86 followers'));
    await expect(follow).not.toHaveAttribute('aria-busy', 'true');
    await openFieldSignedIn(page, '/f/software');
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    await expect(followers).toHaveText(t('86 متابعًا', '86 followers'));
  });

  test(`an empty field is noindex; an unknown field or topic is a 404 — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const empty = await open(page, '/f/design', '[data-field-header]');
    expect(empty.status()).toBe(200);
    expect(await empty.text()).toMatch(/<meta name="robots" content="noindex"/);
    await expect(page.locator('[data-field-count]')).toHaveText(t('0 مقال', '0 articles'));
    await expect(page.locator('[data-list-empty] h3')).toHaveText(t('لا توجد مقالات في هذا المجال بعد', 'No articles in this field yet'));
    await expect(page.locator('[data-field-topics]')).toHaveCount(0);

    const missing = await open(page, '/f/no-such-field', '[data-field-not-found]');
    expect(missing.status()).toBe(404);
    expect(await missing.text()).toMatch(/<meta name="robots" content="noindex"/);
    await expect(page.locator('[data-field-not-found] h3')).toHaveText(t('هذا المجال غير موجود', "This field doesn't exist"));

    const topic = await open(page, '/f/software?topic=cobol', '[data-topic-not-found]');
    expect(topic.status()).toBe(404);
    expect(await topic.text()).toMatch(/<meta name="robots" content="noindex"/);
    await expect(page.locator('[data-field-header]')).toBeVisible();
    await expect(page.locator('[data-topic-not-found] h3')).toHaveText(t('هذا الموضوع غير موجود', "This topic doesn't exist"));
    await page.locator('[data-topic-not-found] a').click();
    await page.waitForURL((url) => url.pathname === '/f/software' && !url.searchParams.has('topic'));
    await expect(cards(page)).toHaveCount(20);
  });
}
