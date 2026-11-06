import { Locator, Page, expect, test } from '@playwright/test';
import {
  API,
  HIDE_APP_CHROME,
  MOCK_PHONE,
  MOCK_PASSWORD,
  VARIANTS,
  hasScreenshot,
  imagesLoaded,
  onApi,
  parkMouse,
  reply,
  sessionFor,
  useVariant,
  writerMe,
} from './support/mock-api';
import { signInAsReader } from './support/social';

/**
 * The post card (F34) on Home, in ar/en × light/dark, desktop and phone: the post itself, "Read more" growing it in
 * place with the preview, reacting and commenting from the feed (in place on wide screens, in a bottom sheet on
 * phones), the feed kept as you left it when you come back from the reader, a guest coming back to the card after
 * signing in, and an article read whole in the card counting as read. The mock API gives its articles excerpts, tags
 * and previews (e2e/mock-api/post-cards.mjs); comments are routed here.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** Cards say how long ago each article was published: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');
const CLEAN = 'a-clean-architecture-whiteboard';

const cardOf = (page: Page, id: string): Locator => page.locator(`rd-post-card[data-post-card="${id}"]`).first();
const isPhone = (page: Page) => page.viewportSize()!.width < 768;

async function openHome(page: Page): Promise<void> {
  await page.clock.setFixedTime(NOW);
  await page.goto('/');
  await expect(page.locator('rd-post-card').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle');
}

const NOUR = { id: 'u-nour', displayName: 'Nour Fawzy', username: 'nour_f', avatarUrl: null, isVerified: false };
const ALI = { id: 'u-ali', displayName: 'علي جمال', username: 'ali_g', avatarUrl: null, isVerified: false };

function comment(id: string, body: string, author = NOUR, patch: Record<string, unknown> = {}) {
  return {
    id,
    articleId: CLEAN,
    parentId: null,
    body,
    author,
    isArticleAuthor: false,
    mentions: [],
    likeCount: 2,
    likedByMe: false,
    replyCount: 0,
    isPinned: false,
    createdAt: '2026-11-03T18:00:00Z',
    editedAt: null,
    isDeleted: false,
    isHidden: false,
    canEdit: false,
    canDelete: false,
    canPin: false,
    canReport: true,
    canModerate: false,
    ...patch,
  };
}

/** Three comments under "Clean Architecture on one whiteboard", and yours once you post one. */
async function routeComments(page: Page, me: { id: string; displayName: string; username: string }): Promise<string[]> {
  const posted: string[] = [];
  const list = [
    comment('cm-1', 'The "dependencies point inwards" rule finally clicked for me. Thanks!'),
    comment('cm-2', 'جميل جدًا، بس إمتى نستخدم الـ use cases بدل الـ services؟', ALI, { createdAt: '2026-11-03T16:00:00Z' }),
    comment('cm-3', 'Would love a follow-up with a real project structure.', NOUR, { likeCount: 0, createdAt: '2026-11-03T12:00:00Z' }),
  ];
  await onApi(page, 'GET', new RegExp(`${API}/articles/${CLEAN}/comments\\?`), (route) =>
    reply(route, 200, { items: list, nextCursor: null, total: list.length + posted.length }),
  );
  await onApi(page, 'POST', `/articles/${CLEAN}/comments`, (route) => {
    const body = (route.request().postDataJSON() as { body: string }).body;
    posted.push(body);
    const author = { id: me.id, displayName: me.displayName, username: me.username, avatarUrl: null, isVerified: false };
    return reply(route, 201, comment(`cm-new-${posted.length}`, body, author, { likeCount: 0, canEdit: true, canDelete: true, canReport: false, createdAt: NOW.toISOString() }));
  });
  return posted;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`feed card: the post, "Read more" and "Show less" — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const previews: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/preview')) previews.push(new URL(r.url()).pathname + new URL(r.url()).search);
    });
    await openHome(page);

    // An Arabic article (mixed with English) as a post.
    const di = cardOf(page, 'a-dependency-injection-ar');
    await expect(di.locator('[data-card-author]')).toHaveAttribute('href', '/@mona');
    await expect(di.locator('[data-card-author]')).toContainText('Mona Adel');
    await expect(di.locator('[data-card-meta]')).toContainText(t('البرمجيات', 'Software'));
    await expect(di.locator('[data-card-meta]')).toContainText(t('6 دقائق للقراءة', '6 min read'));
    await expect(di.locator('[data-card-follow] [data-follow]')).toBeVisible(); // guests: the sign-in prompt
    await expect(di.locator('[data-card-title]')).toHaveAttribute('href', '/ar/a/dependency-injection-ar');
    const excerpt = di.locator('[data-card-excerpt]');
    await expect(excerpt).toHaveAttribute('dir', 'rtl');
    await expect(excerpt).toHaveAttribute('lang', 'ar-EG');
    const more = di.locator('[data-card-read-more]');
    await expect(more).toHaveAttribute('aria-expanded', 'false');
    await expect(more).toHaveText(t('… قراءة المزيد', '… Read more'));
    await expect(di.locator('[data-card-tags] li')).toHaveText(['#ASP.NET Core', '#DI', '#dotnet']);
    // Each tag opens its tag page (F32), by the slug the API gave it.
    expect(await di.locator('[data-card-tags] a').evaluateAll((links) => links.map((a) => a.getAttribute('href')))).toEqual([
      '/tags/asp-net-core',
      '/tags/di',
      '/tags/dotnet',
    ]);
    // The bar (F34): icons only, each count beside its icon (none at 0), Share without one, the reaction emojis on the
    // other side; every button named with its count.
    await expect(di.locator('[data-card-counts]')).toHaveCount(0);
    await expect(di.locator('[data-card-comment-count]')).toHaveText('3');
    await expect(di.locator('[data-card-comment]')).toHaveAttribute('aria-label', t('تعليق، 3', 'Comment, 3'));
    await expect(di.locator('[data-card-actions] button')).toHaveText(['12', '3', '4', '', '💡❤️🔥']);
    expect(await di.locator('[data-card-actions] button').evaluateAll((list) => list.map((b) => b.getAttribute('aria-label')))).toEqual([
      t('تفاعل، 12', 'React, 12'),
      t('تعليق، 3', 'Comment, 3'),
      t('إعادة نشر، 4', 'Repost, 4'),
      t('مشاركة', 'Share'),
      t('12 تفاعلًا، عرض من تفاعل', '12 reactions, see who reacted'),
    ]);
    // The label row comes from `repostedBy` (F29): For you has none.
    await expect(di.locator('[data-card-repost-label]')).toHaveCount(0);
    // No image: no attachments and no cover (the old placeholder is gone).
    await expect(di.locator('img')).toHaveCount(0);
    // Up to 3 tags, then "+N"; a short complete article has no "Read more".
    const photoTags = cardOf(page, 'a-one-photo').locator('[data-card-tags] li');
    await expect(photoTags).toHaveCount(4);
    await expect(photoTags.first()).toHaveText('#desk-setup');
    await expect(photoTags.last().locator('[aria-hidden="true"]')).toHaveText('+1');
    await expect(photoTags.last().locator('.sr-only')).toHaveText(t('وسم آخر', '1 more tag'));
    await expect(cardOf(page, 'a-aspnet-core-cheatsheet').locator('[data-card-read-more]')).toHaveCount(0);
    await di.scrollIntoViewIfNeeded();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(di).toHaveScreenshot(`feed-card-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // "Read more" from the keyboard: the card grows downwards, nothing above it moves, focus stays in its text.
    const titleTop = (await di.locator('[data-card-title]').boundingBox())!.y;
    await more.focus();
    await page.keyboard.press('Enter');
    await expect(di.locator('[data-card-preview]')).toBeVisible();
    expect(previews).toEqual(['/api/v1/articles/a-dependency-injection-ar/preview?lang=ar-EG']);
    expect(Math.abs((await di.locator('[data-card-title]').boundingBox())!.y - titleTop)).toBeLessThan(1);
    await expect(di.locator('[data-card-text]')).toBeFocused();
    // The reader's renderer: headings and glossary terms, then the way to the whole article.
    await expect(di.locator('[data-card-preview] h2').first()).toBeVisible();
    await expect(di.locator('[data-card-preview] [data-term="dependency-injection"]')).toBeVisible();
    await expect(di.locator('[data-card-read-full]')).toHaveAttribute('href', '/ar/a/dependency-injection-ar');
    await expect(di.locator('[data-card-read-full]')).toHaveText(t('قراءة المقال كاملًا', 'Read the full article'));

    // "Show less" from far below: the card's top comes back into view, focus goes back to "Read more".
    const less = di.locator('[data-card-show-less]');
    await expect(less).toHaveAttribute('aria-expanded', 'true');
    await less.click();
    await expect(di.locator('[data-card-preview]')).toHaveCount(0);
    await expect(more).toBeFocused();
    await expect.poll(async () => (await di.boundingBox())!.y).toBeGreaterThanOrEqual(0);

    // A whole article in the card (its heading made the excerpt shorter than the article): no "Read the full article".
    const photo = cardOf(page, 'a-one-photo');
    await photo.locator('[data-card-excerpt]').click(); // the text expands too
    await expect(photo.locator('[data-card-preview] h2')).toHaveText('Why paper?');
    await expect(photo.locator('[data-card-read-full]')).toHaveCount(0);
    expect(previews).toHaveLength(2);
    await photo.scrollIntoViewIfNeeded();
    await parkMouse(page);
    await imagesLoaded(photo);
    if (hasScreenshot(variant)) await expect(photo).toHaveScreenshot(`feed-card-expanded-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
  });

  test(`feed card: react and comment without leaving the feed — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsReader(page, request, variant);
    const posted = await routeComments(page, { id: me.id, displayName: 'Sara Hassan', username: 'sara' });
    await openHome(page);
    await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS }); // the session is restored
    const card = cardOf(page, CLEAN);

    // React: a tap gives 💡 at once; the four reactions open from the keyboard.
    const react = card.locator('[data-card-actions] [data-react]');
    await expect(react).not.toHaveAttribute('data-my-reaction');
    const reacted = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith(`/articles/${CLEAN}/reaction`));
    await react.click();
    await expect(react).toHaveAttribute('data-my-reaction', 'insightful');
    await expect(card.locator('[data-react-count]')).toHaveText('13');
    await expect(react).toHaveAttribute('aria-label', t('تفاعلت: مفيد، 13', 'Reacted: Insightful, 13'));
    await reacted;
    await react.focus();
    await page.keyboard.press('ArrowUp');
    await expect(card.locator('[data-reaction-picker] [role="menuitemradio"]')).toHaveCount(4);
    await page.keyboard.press('Escape');
    await expect(card.locator('[data-reaction-picker]')).toHaveCount(0);

    // Comment: in place under the card on wide screens, in a bottom sheet on phones; the feed stays where it was.
    const scrolled = await page.evaluate(() => scrollY);
    await card.locator('[data-card-comment]').click();
    await expect(card.locator('[data-card-comment]')).toHaveAttribute('aria-expanded', 'true');
    if (isPhone(page)) {
      const sheet = card.locator('rd-bottom-sheet section[role="dialog"]');
      await expect(sheet.locator('rd-comment-thread')).toHaveCount(3);
      await expect(sheet.locator('[data-comments-title]')).toHaveText(t('التعليقات (3)', 'Comments (3)'));
      await expect(sheet.locator('[data-comments-sort]')).toBeVisible();
      expect(await page.evaluate(() => scrollY)).toBe(scrolled);
      await parkMouse(page);
      if (hasScreenshot(variant)) await expect(sheet).toHaveScreenshot(`feed-card-comments-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
      await sheet.locator('[data-new-comment] textarea').fill(t('تعليق من الفيد عن Clean Architecture', 'A comment from the feed'));
      await sheet.locator('[data-new-comment] [data-comment-send]').click();
      await expect(sheet.locator('rd-comment-thread')).toHaveCount(4);
      await page.keyboard.press('Escape');
      await expect(sheet).toHaveCount(0);
    } else {
      const section = card.locator('[data-card-comments]');
      await expect(section.locator('rd-comment-thread')).toHaveCount(2);
      await expect(section.locator('[data-comments-sort]')).toHaveCount(0);
      await section.locator('[data-show-all-comments]').click();
      await expect(section.locator('rd-comment-thread')).toHaveCount(3);
      await card.scrollIntoViewIfNeeded();
      await parkMouse(page);
      if (hasScreenshot(variant)) await expect(card).toHaveScreenshot(`feed-card-comments-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
      await section.locator('[data-new-comment] textarea').fill(t('تعليق من الفيد عن Clean Architecture', 'A comment from the feed'));
      await section.locator('[data-new-comment] [data-comment-send]').click();
      await expect(section.locator('rd-comment-thread')).toHaveCount(4);
    }
    expect(posted).toEqual([t('تعليق من الفيد عن Clean Architecture', 'A comment from the feed')]);
  });

  test(`feed card: Back from the reader finds the feed as you left it — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsReader(page, request, variant);
    await routeComments(page, { id: me.id, displayName: 'Sara Hassan', username: 'sara' });
    await openHome(page);
    await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS });
    let feedCalls = 0;
    page.on('request', (r) => {
      if (r.url().includes('/feed/for-you')) feedCalls++;
    });

    // An expanded card and, on wide screens, open comments with text you haven't sent.
    const di = cardOf(page, 'a-dependency-injection-ar');
    await di.locator('[data-card-read-more]').click();
    await expect(di.locator('[data-card-preview]')).toBeVisible();
    const clean = cardOf(page, CLEAN);
    const draft = t('لسه بكتب…', 'Still typing…');
    if (!isPhone(page)) {
      await clean.locator('[data-card-comment]').click();
      await clean.locator('[data-card-comments] [data-new-comment] textarea').fill(draft);
    }
    const photo = cardOf(page, 'a-one-photo');
    await photo.locator('[data-card-title]').scrollIntoViewIfNeeded();
    const before = await page.evaluate(() => scrollY);

    await photo.locator('[data-card-title]').click();
    await page.waitForURL((url) => url.pathname === '/en/a/one-photo');
    await expect(page.locator('rd-article-page h1')).toContainText('My desk setup', { timeout: FIRST_RENDER_MS });
    await page.goBack();
    await page.waitForURL((url) => url.pathname === '/');

    // The same page: nothing reloads, the card is still expanded, the comments still open with your text.
    await expect(di.locator('[data-card-preview]')).toBeVisible();
    if (!isPhone(page)) await expect(clean.locator('[data-card-comments] [data-new-comment] textarea')).toHaveValue(draft);
    await expect.poll(() => page.evaluate(() => scrollY)).toBeGreaterThan(before - 4);
    expect(Math.abs((await page.evaluate(() => scrollY)) - before)).toBeLessThan(4);
    expect(feedCalls).toBe(0);
    await expect(page).toHaveTitle(/^ReadIn — /);

    // Home from a link is a fresh feed (the web's "pull to refresh"); unsent text survives that too.
    await photo.locator('[data-card-title]').click();
    await page.waitForURL((url) => url.pathname === '/en/a/one-photo');
    await page.locator('rd-top-bar [data-home-mark]').click();
    await page.waitForURL((url) => url.pathname === '/');
    await expect.poll(() => feedCalls).toBeGreaterThan(0);
    await expect(di.locator('[data-card-read-more]')).toBeVisible();
    await expect(di.locator('[data-card-preview]')).toHaveCount(0);
    if (!isPhone(page)) {
      await clean.locator('[data-card-comment]').click();
      await expect(clean.locator('[data-card-comments] [data-new-comment] textarea')).toHaveValue(draft);
    }
  });

  test(`feed card: a guest signs in from Comment and comes back to the card — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await writerMe(request, variant);
    await routeComments(page, { id: me.id, displayName: 'Mona Adel', username: 'mona' });
    await onApi(page, 'POST', '/auth/login', (route) => reply(route, 200, sessionFor(me)));
    await openHome(page);

    const card = cardOf(page, CLEAN);
    await card.locator('[data-card-comment]').click();
    const prompt = page.locator('rd-sign-in-prompt [role="dialog"]');
    await expect(prompt).toBeVisible();
    await prompt.locator('a.rd-btn-primary').click();
    await page.waitForURL((url) => url.pathname === '/auth/sign-in');
    await page.locator('#sign-in-phone').fill(MOCK_PHONE);
    await page.locator('#sign-in-password').fill(MOCK_PASSWORD);
    await page.locator('form [data-submit]').click();
    await page.waitForURL((url) => url.pathname === '/');

    // Back at the card, with its comments open.
    const comments = isPhone(page) ? card.locator('rd-bottom-sheet section[role="dialog"]') : card.locator('[data-card-comments]');
    await expect(comments.locator('rd-comment-thread').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(comments.locator('[data-new-comment] textarea')).toBeVisible();
    if (!isPhone(page)) await expect(card).toBeInViewport();
  });

  test(`feed card: an article read whole in the card counts as read — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    const reports: { id: string; language: string; percent: number; lastPosition: string | null }[] = [];
    await onApi(page, 'PUT', /\/api\/v1\/articles\/[^/]+\/progress$/, (route) => {
      const body = route.request().postDataJSON() as { language: string; percent: number; lastPosition: string | null };
      reports.push({ ...body, id: new URL(route.request().url()).pathname.split('/')[4] });
      return reply(route, 200, { percent: body.percent, completed: false, completedNow: false, streak: null, milestone: null });
    });
    await openHome(page);
    await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS });

    // Cut off ("Read the full article"): never from the card.
    const di = cardOf(page, 'a-dependency-injection-ar');
    await di.locator('[data-card-read-more]').click();
    await expect(di.locator('[data-card-read-full]')).toBeVisible();
    // Whole in the card: reported like the reader does, without a position (the reader's resume point stays).
    const photo = cardOf(page, 'a-one-photo');
    await photo.locator('[data-card-read-more]').click();
    await expect(photo.locator('[data-card-preview]')).toBeVisible();
    await photo.locator('[data-card-show-less]').scrollIntoViewIfNeeded();
    await expect.poll(() => reports.length).toBeGreaterThan(0);
    expect(reports.every((r) => r.id === 'a-one-photo')).toBe(true);
    expect(reports[0]).toMatchObject({ language: 'en', lastPosition: null });
  });
}
