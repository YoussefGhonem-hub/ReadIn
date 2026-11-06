import { randomUUID } from 'node:crypto';
import { APIRequestContext, Locator, Page, expect, test } from '@playwright/test';
import {
  API,
  HIDE_APP_CHROME,
  HIDE_COMMENTS,
  VARIANTS,
  Variant,
  hasScreenshot,
  onApi,
  parkMouse,
  problem,
  reply,
  restoreSessionAs,
  useVariant,
  writerMe,
} from './support/mock-api';
import { expectSignInPrompt, openArticle, signInAsReader } from './support/social';

/**
 * The post's action bar, the reactions bar, Repost and the comment box (pre-production step, SPEC F10, F11, F14, F29,
 * F34) in ar/light and en/dark, desktop and phone:
 * - the card's bar: icons only with their counts (none at 0), names with the counts, the reaction emojis on the other
 *   side; the writer's title under the name;
 * - the floating reactions bar (LinkedIn-style): hover, keyboard, staggered entry, grow and lift, the pick animation,
 *   and all of it instant with "reduce motion";
 * - Repost: its menu's "أعد النشر" / "إلغاء إعادة النشر", optimistic, kept by the server, rollback with the error; your
 *   own article, guests; the Following feed's "أعاد نشره {name}" / "{name} و N غيره" labels (the mock's `u-reposts…`
 *   viewers follow writers who reposted, some with their thoughts under the label); the caption dialog is in
 *   repost-caption.e2e.ts;
 * - the reader: the title in the author row, Repost in the bar;
 * - comments: the box (avatar, rounded field, emoji picker, send icon), the rows (title, Follow, ⋯) and Reply's mention.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** Cards say how long ago each article was published: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');
const CLEAN = 'a-clean-architecture-whiteboard';

const cardOf = (page: Page, id: string): Locator => page.locator(`rd-post-card[data-post-card="${id}"]`).first();

/** Records every reaction the bar marks as picked (its animation plays for 300 ms), for {@link picksSeen}. */
async function recordPicks(bar: Locator): Promise<void> {
  await bar.evaluate((el) => {
    const seen: string[] = [];
    (window as unknown as { picksSeen: string[] }).picksSeen = seen;
    new MutationObserver(() => {
      const picked = el.getAttribute('data-picked');
      if (picked && seen.at(-1) !== picked) seen.push(picked);
    }).observe(el, { attributes: true, attributeFilter: ['data-picked'] });
  });
}

const picksSeen = (page: Page) => page.evaluate(() => (window as unknown as { picksSeen: string[] }).picksSeen);
const isPhone = (page: Page) => page.viewportSize()!.width < 768;

async function openHome(page: Page, signedIn = true): Promise<void> {
  await page.clock.setFixedTime(NOW);
  await page.goto('/');
  await expect(page.locator('rd-post-card').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
  if (signedIn) await expect(page.locator('h1')).toContainText(/Sara|Mona/, { timeout: FIRST_RENDER_MS }); // the session is restored
  await page.waitForLoadState('networkidle');
}

/** A reader who follows ReadIn and Karim, in the mock's world where those two reposted articles (reposts.mjs). */
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

/** Writers the mock API knows (so following them works); the seeded reader follows Karim, not Salma. */
const SALMA = { id: 'u-salma', displayName: 'سلمى إبراهيم', username: 'salma', avatarUrl: null, isVerified: false, headline: 'ML Engineer | بحب أبسّط الـ AI' };
const KARIM = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true, headline: 'Frontend lead · React & Angular' };

function comment(id: string, body: string, author: object, patch: Record<string, unknown> = {}) {
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
    isFollowingAuthor: false,
    ...patch,
  };
}

/** Comments under "Clean Architecture on one whiteboard": Salma (not followed), Karim (followed) and yours; replies are kept. */
async function routeComments(page: Page, me: { id: string; displayName: string; username: string }) {
  const replies: { target: string; body: string }[] = [];
  const mine = { id: me.id, displayName: me.displayName, username: me.username, avatarUrl: null, isVerified: false, headline: null };
  const list = [
    comment('cm-1', 'الـ "dependencies point inwards" وضحت معايا أخيرًا. شكرًا!', SALMA),
    comment('cm-2', 'Great write-up. When would you pick use cases over services?', KARIM, { createdAt: '2026-11-03T16:00:00Z', isFollowingAuthor: true, likeCount: 0 }),
    comment('cm-3', 'My own note on this.', mine, { createdAt: '2026-11-03T12:00:00Z', likeCount: 0, canEdit: true, canDelete: true, canReport: false }),
  ];
  await onApi(page, 'GET', new RegExp(`${API}/articles/${CLEAN}/comments\\?`), (route) => reply(route, 200, { items: list, nextCursor: null, total: list.length }));
  await onApi(page, 'POST', /\/api\/v1\/comments\/[^/]+\/replies$/, (route) => {
    const target = new URL(route.request().url()).pathname.split('/')[4];
    const body = (route.request().postDataJSON() as { body: string }).body;
    replies.push({ target, body });
    const mentions = body.startsWith('@salma') ? [{ userId: SALMA.id, username: SALMA.username }] : [];
    return reply(route, 201, comment(`r-new-${replies.length}`, body, mine, { parentId: target, mentions, likeCount: 0, canEdit: true, canDelete: true, canReport: false, createdAt: NOW.toISOString() }));
  });
  return replies;
}

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);
  const forward = dir === 'rtl' ? 'ArrowLeft' : 'ArrowRight';

  test(`post bar: icons with their counts, the title under the name — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await openHome(page, false);
    const card = cardOf(page, 'a-dependency-injection-ar');

    // The writer's title, one line, in its own direction, between the name and field · time · reading time.
    const headline = card.locator('[data-card-headline]');
    await expect(headline).toHaveText('Senior Backend Engineer | .NET | Architecture');
    await expect(headline.locator('bdi')).toHaveAttribute('dir', 'auto');
    // The line is in the UI's direction and the title sits on its start side (the right in Arabic), even in the other
    // script; the title itself is laid out and cut ("…") in its own direction, so it keeps its beginning.
    expect(await headline.evaluate((el) => getComputedStyle(el).direction)).toBe(dir);
    expect(await headline.locator('bdi').evaluate((el) => getComputedStyle(el).direction)).toBe('ltr');
    expect(await headline.locator('bdi').evaluate((el) => getComputedStyle(el).textOverflow)).toBe('ellipsis');
    const line = (await headline.boundingBox())!;
    const title = (await headline.locator('bdi').boundingBox())!;
    expect(Math.abs(dir === 'rtl' ? line.x + line.width - (title.x + title.width) : title.x - line.x)).toBeLessThan(1);
    expect(line.y).toBeLessThan((await card.locator('[data-card-meta]').boundingBox())!.y);

    // Icons only: the numbers beside them and nothing else; each named with its count.
    const bar = card.locator('[data-card-actions]');
    const buttons = bar.locator('button');
    await expect(buttons).toHaveText(['12', '3', '4', '', '💡❤️🔥']);
    expect(await buttons.evaluateAll((list) => list.map((b) => b.getAttribute('aria-label')))).toEqual([
      t('تفاعل، 12', 'React, 12'),
      t('تعليق، 3', 'Comment, 3'),
      t('إعادة نشر، 4', 'Repost, 4'),
      t('مشاركة', 'Share'),
      t('12 تفاعل، شوف مين اتفاعل', '12 reactions, see who reacted'),
    ]);
    // The old counts row ("3 تعليقات") is gone; a count of 0 shows no number.
    await expect(card.locator('[data-card-counts]')).toHaveCount(0);
    await expect(cardOf(page, 'a-one-photo').locator('[data-repost-count]')).toHaveCount(0);
    await expect(cardOf(page, 'a-one-photo').locator('[data-repost]')).toHaveAttribute('aria-label', t('إعادة نشر', 'Repost'));
    // The reaction emojis sit on the other side and open who reacted.
    const summary = bar.locator('[data-reactions-summary]');
    const shareBox = (await bar.locator('[data-card-share]').boundingBox())!;
    const summaryBox = (await summary.boundingBox())!;
    expect(dir === 'rtl' ? summaryBox.x < shareBox.x : summaryBox.x > shareBox.x).toBe(true);
    await card.scrollIntoViewIfNeeded();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(card.locator('header')).toHaveScreenshot(`post-header-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    if (hasScreenshot(variant)) await expect(bar).toHaveScreenshot(`post-bar-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await summary.click();
    await expect(page.locator('[data-reactors-sheet]')).toBeVisible();
  });

  test(`reactions bar: hover, staggered entry, grow and lift, pick, keyboard — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openHome(page);
    const card = cardOf(page, CLEAN);
    const react = card.locator('[data-card-actions] [data-react]');
    const bar = card.locator('[data-reaction-picker]');
    await card.locator('[data-card-actions]').evaluate((el) => el.scrollIntoView({ block: 'center' }));

    if (isPhone(page)) {
      // Phones: a long press opens it (and its release is not a tap).
      await react.dispatchEvent('pointerdown', { pointerType: 'touch', isPrimary: true });
      await expect(bar).toBeVisible();
      await react.dispatchEvent('pointerup', { pointerType: 'touch', isPrimary: true });
    } else {
      // A mouse hovering React opens it after a moment.
      await react.hover();
      await expect(bar).toBeVisible();
    }
    // Four reactions, no numbers or text; each enters after the one before it.
    const reactions = bar.locator('[role="menuitemradio"]');
    await expect(reactions).toHaveCount(4);
    await expect(bar).not.toContainText(/\d|[A-Za-z؀-ۿ]/);
    expect(await reactions.evaluateAll((list) => list.map((b) => getComputedStyle(b).animationDelay))).toEqual(['0s', '0.05s', '0.1s', '0.15s']);
    expect(await reactions.first().evaluate((b) => getComputedStyle(b).animationName)).not.toBe('none');
    expect(await reactions.evaluateAll((list) => list.map((b) => b.getAttribute('aria-label')))).toEqual(
      lang === 'ar' ? ['مفيد', 'حبيته', 'نار', 'مبهر'] : ['Insightful', 'Love', 'Fire', 'Mind-blown'],
    );

    // The one under the pointer grows and lifts.
    const love = bar.locator('[data-reaction="love"]');
    const loveEmoji = love.locator('.reaction-emoji');
    if (!isPhone(page)) {
      // The reactions are still entering: hover once they've landed.
      await bar.evaluate((el) => Promise.all(el.getAnimations({ subtree: true }).map((a) => a.finished)));
      await love.hover();
      await expect.poll(() => loveEmoji.evaluate((el) => getComputedStyle(el).transform)).not.toBe('none');
      if (hasScreenshot(variant)) {
        // The floating bar and the React button under it (on the right in Arabic).
        const a = (await bar.boundingBox())!;
        const b = (await react.boundingBox())!;
        const x = Math.min(a.x, b.x) - 16;
        const y = a.y - 24;
        const clip = { x, y, width: Math.max(a.x + a.width, b.x + b.width) + 16 - x, height: b.y + b.height + 8 - y };
        await expect(page).toHaveScreenshot(`reactions-bar-${suffix}.png`, { clip, stylePath: HIDE_APP_CHROME });
      }
    }

    // A pick plays its short animation, then the bar closes and the icon shows the reaction.
    await recordPicks(bar);
    await love.click();
    await expect(bar).toHaveCount(0);
    expect(await picksSeen(page)).toContain('love');
    await expect(react).toHaveAttribute('data-my-reaction', 'love');
    await expect(react).toHaveAttribute('aria-pressed', 'true');
    await expect(react).toHaveAttribute('aria-label', t('تفاعلت: حبيته، 13', 'Reacted: Love, 13'));
    await expect(react.locator('[data-react-icon]')).toHaveText('❤️');

    // Keyboard: ArrowUp opens it on your reaction, arrows follow the reading direction, Enter picks, focus comes back.
    await react.focus();
    await page.keyboard.press('ArrowUp');
    await expect(love).toBeFocused();
    await page.keyboard.press(forward);
    await expect(bar.locator('[data-reaction="fire"]')).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(bar).toHaveCount(0);
    await expect(react).toHaveAttribute('data-my-reaction', 'fire');
    await expect(react).toBeFocused();

    // A tap removes your reaction: the 💡 line icon comes back.
    const removed = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().endsWith(`/articles/${CLEAN}/reaction`));
    await react.click();
    await expect(react).not.toHaveAttribute('data-my-reaction');
    await expect(react.locator('svg[data-react-icon]')).toBeVisible();
    await removed;
  });

  test(`reactions bar: reduce motion makes it instant — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await signInAsReader(page, request, variant);
    await openHome(page);
    const card = cardOf(page, CLEAN);
    const react = card.locator('[data-card-actions] [data-react]');
    const bar = card.locator('[data-reaction-picker]');
    await card.scrollIntoViewIfNeeded();
    await react.focus();
    await page.keyboard.press('ArrowUp');
    await expect(bar).toBeVisible();

    // No entry animation, no stagger, no grow or lift.
    expect(await bar.evaluate((el) => getComputedStyle(el).animationName)).toBe('none');
    const reactions = bar.locator('[role="menuitemradio"]');
    expect(await reactions.evaluateAll((list) => list.map((b) => getComputedStyle(b).animationName))).toEqual(['none', 'none', 'none', 'none']);
    const fire = bar.locator('[data-reaction="fire"]');
    if (!isPhone(page)) await fire.hover();
    else await fire.focus();
    expect(await fire.locator('.reaction-emoji').evaluate((el) => getComputedStyle(el).transform)).toBe('none');

    // A pick closes the bar at once: it never enters the picked (animating) state.
    await recordPicks(bar);
    await fire.click();
    await expect(bar).toHaveCount(0);
    expect(await picksSeen(page)).toEqual([]);
    await expect(react).toHaveAttribute('data-my-reaction', 'fire');
    expect(await react.locator('[data-react-icon]').evaluate((el) => getComputedStyle(el).animationName)).toBe('none');
  });

  test(`repost: toggle the server keeps, rollback with the error, guests — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openHome(page);
    const card = cardOf(page, CLEAN);
    const repost = card.locator('[data-repost]');
    const count = card.locator('[data-repost-count]');
    await expect(count).toHaveText('2');
    await expect(repost).toHaveAttribute('aria-pressed', 'false');

    // A tap opens the Repost menu; "أعد النشر" is optimistic: pressed and counted at once, then the server confirms
    // (the caption dialog has its own spec, repost-caption.e2e.ts).
    const put = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith(`/articles/${CLEAN}/repost`));
    await repost.click();
    await page.locator('[data-repost-menu] [data-repost-action="repost"]').click();
    await expect(repost).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText('3');
    await expect(repost).toHaveAttribute('aria-label', t('إعادة نشر، 3', 'Repost, 3'));
    expect((await put).status()).toBe(200);

    // The server kept it.
    await openHome(page);
    await expect(repost).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText('3');

    // Undo refused (rate limit): back to reposted, with the translated error.
    await onApi(page, 'DELETE', `/articles/${CLEAN}/repost`, (route) => reply(route, 429, problem(429, 'rate_limited')));
    await repost.click();
    await page.locator('[data-repost-menu] [data-repost-action="undo"]').click();
    await expect(page.locator('rd-toast-host')).toContainText(t('طلبات كتير، استنى شوية وجرّب تاني.', 'Too many requests. Wait a little and try again.'));
    await expect(repost).toHaveAttribute('aria-pressed', 'true');
    await expect(count).toHaveText('3');

    // Guests: the sign-in prompt, and nothing is sent.
    await context.clearCookies({ name: 'readin_refresh' });
    await page.unrouteAll({ behavior: 'ignoreErrors' });
    const sent: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/repost')) sent.push(r.method());
    });
    await page.goto('/');
    await expect(page.locator('rd-post-card').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');
    await cardOf(page, CLEAN).locator('[data-repost]').click();
    await expectSignInPrompt(page);
    expect(sent).toEqual([]);
  });

  test(`repost: your own article can't be reposted — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await restoreSessionAs(page, await writerMe(request, variant)); // Mona, who wrote the For you articles
    await openHome(page);
    const repost = cardOf(page, 'a-dependency-injection-ar').locator('[data-repost]');
    const sent: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/repost')) sent.push(r.method());
    });
    await expect(repost).toHaveAttribute('aria-disabled', 'true');
    await expect(repost).toHaveAttribute('title', t('مينفعش تعيد نشر مقالك', "You can't repost your own article"));
    await expect(repost).toHaveAccessibleDescription(t('مينفعش تعيد نشر مقالك', "You can't repost your own article"));
    await expect(repost).toBeDisabled(); // aria-disabled, but it stays focusable and answers with the hint
    // From the keyboard (it stays focusable): Enter answers with the hint.
    await repost.focus();
    await expect(repost).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page.locator('rd-toast-host')).toContainText(t('مينفعش تعيد نشر مقالك', "You can't repost your own article"));
    expect(sent).toEqual([]);
  });

  test(`repost: Home → Following labels the cards a repost placed — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsRepostsReader(page, request, variant);
    await openHome(page);
    await page.locator('[data-home-tab="following"]').click();
    const panel = page.locator('#home-panel-following');
    const cards = panel.locator('rd-post-card');
    await expect(cards.first()).toBeVisible({ timeout: FIRST_RENDER_MS });

    // Newest placement first: Omar's article that Karim and ReadIn reposted (Karim's the newest), labeled once.
    expect(await cards.evaluateAll((list) => list.slice(0, 4).map((c) => c.getAttribute('data-post-card')))).toEqual([
      'a-sleep-and-memory',
      'a-react-server-components-explained',
      'a-how-readin-picks-your-daily-article',
      'a-what-is-a-transformer-ar',
    ]);
    const sleep = cards.nth(0).locator('[data-card-repost-label]');
    await expect(sleep).toHaveText(t('Karim Hassan وشخص تاني أعادوا نشره', 'Karim Hassan and 1 other reposted this'));
    await expect(sleep.locator('[data-card-reposter]')).toHaveAttribute('href', '/@karim');
    await expect(sleep.locator('[data-card-reposter]')).toHaveAttribute('dir', 'auto');
    // Karim's own article, moved up by ReadIn's later repost: "أعاد نشره ReadIn".
    await expect(cards.nth(1).locator('[data-card-repost-label]')).toHaveText(t('أعاد نشره ReadIn', 'ReadIn reposted this'));
    // ReadIn's own article, which no one reposted: no label.
    await expect(cards.nth(2).locator('[data-card-repost-label]')).toHaveCount(0);
    await expect(cards.nth(3).locator('[data-card-repost-label]')).toHaveText(t('أعاد نشره Karim Hassan', 'Karim Hassan reposted this'));
    // Each article once.
    const ids = await cards.evaluateAll((list) => list.map((c) => c.getAttribute('data-post-card')));
    expect(new Set(ids).size).toBe(ids.length);

    await cards.nth(0).scrollIntoViewIfNeeded();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(cards.nth(0).locator('article > div').first()).toHaveScreenshot(`repost-label-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await sleep.locator('[data-card-reposter]').click();
    await page.waitForURL((url) => url.pathname === '/@karim');
  });

  test(`reader: the title in the author row, Repost in the bar — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/react-server-components-explained');

    const headline = page.locator('[data-byline] [data-author-headline]');
    await expect(headline).toHaveText('Frontend lead · React & Angular');
    await expect(headline.locator('bdi')).toHaveAttribute('dir', 'auto');
    expect(await headline.locator('bdi').evaluate((el) => getComputedStyle(el).textOverflow)).toBe('ellipsis');

    const bar = page.locator('rd-article-action-bar');
    const repost = bar.locator('[data-repost]');
    await expect(repost).toHaveAttribute('aria-label', t('إعادة نشر', 'Repost'));
    await expect(bar.locator('[data-repost-count]')).toHaveCount(0);
    // The bar's Repost opens the same menu as the card's, placed inside the screen above the bar.
    await repost.click();
    const repostNow = page.locator('[data-repost-menu] [data-repost-action="repost"]');
    await expect(repostNow).toBeInViewport({ ratio: 1 });
    await repostNow.click();
    await expect(repost).toHaveAttribute('aria-pressed', 'true');
    await expect(bar.locator('[data-repost-count]')).toHaveText('1');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(bar).toHaveScreenshot(`reader-bar-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_COMMENTS] });
    if (hasScreenshot(variant)) await expect(page.locator('[data-byline]')).toHaveScreenshot(`reader-byline-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    // The bar fits on phones down to 360 px: who reacted and the comment count never overlap.
    const viewport = page.viewportSize()!;
    for (const width of [412, 360]) {
      await page.setViewportSize({ width, height: viewport.height });
      const gap = await bar.evaluate((el) => {
        const a = el.querySelector('[data-reactions-summary]')!.getBoundingClientRect();
        const b = el.querySelector('[data-comment-count]')!.getBoundingClientRect();
        return a.left < b.left ? b.left - a.right : a.left - b.right;
      });
      expect(gap, `${width}px`).toBeGreaterThanOrEqual(0);
    }
    await page.setViewportSize(viewport);
    // The server kept it.
    await openArticle(page, '/en/a/react-server-components-explained');
    await expect(repost).toHaveAttribute('aria-pressed', 'true');
  });

  test(`comments: the box, the emoji picker, the rows and Reply's mention — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsReader(page, request, variant);
    const replies = await routeComments(page, { id: me.id, displayName: 'Sara Hassan', username: 'sara' });
    await openHome(page);
    const card = cardOf(page, CLEAN);
    await card.locator('[data-card-comment]').click();
    const section = isPhone(page) ? card.locator('rd-bottom-sheet section[role="dialog"]') : card.locator('[data-card-comments]');
    await expect(section.locator('rd-comment-thread').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
    if (!isPhone(page)) await section.locator('[data-show-all-comments]').click();
    await expect(section.locator('rd-comment-thread')).toHaveCount(3);

    // The box: your avatar, a rounded field, the emoji and send icons inside it; send waits for text.
    const box = section.locator('[data-new-comment]');
    await expect(box.locator('[data-composer-avatar]')).toBeVisible();
    const field = box.locator('textarea');
    await expect(field).toHaveAttribute('placeholder', t('اكتب تعليق…', 'Add a comment…'));
    const send = box.locator('[data-comment-field] [data-comment-send]');
    await expect(send).toBeDisabled();
    await expect(send).toHaveAttribute('aria-label', t('ابعت التعليق', 'Post comment'));
    await expect(box.locator('input[type="file"]')).toHaveCount(0);
    expect(await box.locator('[data-comment-field]').evaluate((el) => parseFloat(getComputedStyle(el).borderTopLeftRadius))).toBeGreaterThan(16);

    // The emoji picker (its own lazy chunk in the build, imported when the button is pressed): the emoji goes in at the
    // caret, Escape closes it.
    await field.fill(t('فكرة حلوة', 'Great idea'));
    await expect(send).toBeEnabled();
    const emojiButton = box.locator('[data-comment-emoji]');
    await expect(page.locator('rd-emoji-picker')).toHaveCount(0);
    await emojiButton.click();
    const picker = box.locator('[data-emoji-picker]');
    await expect(picker).toBeVisible();
    await expect(emojiButton).toHaveAttribute('aria-expanded', 'true');
    await expect(picker.locator('[role="tab"]')).toHaveCount(9);
    await picker.locator('[data-emoji-category="people"]').click();
    await picker.locator('[data-emoji="👏"]').click();
    await expect(field).toHaveValue(t('فكرة حلوة👏', 'Great idea👏'));
    await parkMouse(page);
    if (hasScreenshot(variant)) {
      // The box and the open picker under it.
      await picker.scrollIntoViewIfNeeded();
      const a = (await box.boundingBox())!;
      const b = (await picker.boundingBox())!;
      const x = Math.min(a.x, b.x);
      const y = Math.min(a.y, b.y);
      const clip = { x, y, width: Math.max(a.x + a.width, b.x + b.width) - x, height: Math.max(a.y + a.height, b.y + b.height) - y };
      await expect(page).toHaveScreenshot(`comment-box-emoji-${suffix}.png`, { clip, stylePath: HIDE_APP_CHROME });
    }
    await page.keyboard.press('Escape');
    await expect(picker).toHaveCount(0);
    await expect(emojiButton).toBeFocused();
    await field.fill('');

    // Each row: the title under the name (not the @username); Follow only for someone you don't follow, not yourself.
    const salma = section.locator('[data-comment="cm-1"]');
    await expect(salma.locator('[data-comment-headline]')).toHaveText('ML Engineer | بحب أبسّط الـ AI');
    await expect(salma.locator('[data-comment-headline] bdi')).toHaveAttribute('dir', 'auto');
    await expect(salma).not.toContainText('@salma');
    await expect(salma.locator('[data-comment-follow] [data-follow]')).toBeVisible();
    await expect(section.locator('[data-comment="cm-2"] [data-comment-follow]')).toHaveCount(0);
    await expect(section.locator('[data-comment="cm-3"] [data-comment-follow]')).toHaveCount(0);
    await expect(salma.locator('[data-comment-menu]')).toBeVisible();
    await expect(salma.locator('[data-comment-actions] button')).toHaveCount(2); // Like, Reply
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(salma).toHaveScreenshot(`comment-row-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Reply: "@salma " is in the box with the caret after it; the reply goes out with the mention.
    await salma.locator('[data-reply]').click();
    const replyBox = section.locator('[data-reply-composer]');
    const replyField = replyBox.locator('textarea');
    await expect(replyField).toBeFocused();
    await expect(replyField).toHaveValue('@salma ');
    expect(await replyField.evaluate((el: HTMLTextAreaElement) => [el.selectionStart, el.selectionEnd])).toEqual([7, 7]);
    await expect(replyBox.locator('[data-comment-cancel]')).toHaveAttribute('aria-label', t('إلغاء الرد', 'Cancel reply'));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(replyBox).toHaveScreenshot(`reply-box-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await page.keyboard.type(t('عندك حق', 'you are right'));
    await replyBox.locator('[data-comment-send]').click();
    await expect(section.locator('[data-comment="r-new-1"] a[data-mention]')).toHaveAttribute('href', '/@salma');
    expect(replies).toEqual([{ target: 'cm-1', body: `@salma ${t('عندك حق', 'you are right')}` }]);

    // Replying to yourself puts no mention; ✕ cancels.
    await section.locator('[data-comment="cm-3"] [data-reply]').click();
    await expect(section.locator('[data-reply-composer] textarea')).toHaveValue('');
    await section.locator('[data-reply-composer] [data-comment-cancel]').click();
    await expect(section.locator('[data-reply-composer]')).toHaveCount(0);

    // Follow from a row: the shared follow store, so the button turns to "Following".
    await salma.locator('[data-comment-follow] [data-follow]').click();
    await expect(salma.locator('[data-comment-follow] [data-follow]')).toHaveAttribute('aria-pressed', 'true');
  });

  test(`a title in the other script keeps its beginning, cut at its own end — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    // Far longer than the row: English in the Arabic UI, Arabic in the English UI (cards and the reader's author row use
    // the same markup, see post-card.spec.ts and article.page.spec.ts).
    const long = t(
      'Senior Full Stack .NET Engineer | .NET | Angular | Azure | SQL Server | Clean Architecture | Mentor',
      'مهندسة برمجيات أولى | بحب أبسّط الـ AI والـ Machine Learning للناس اللي لسه بادئة في المجال ده',
    );
    const own = t('ltr', 'rtl');
    await onApi(page, 'GET', new RegExp(`${API}/articles/${CLEAN}/comments\\?`), (route) =>
      reply(route, 200, { items: [comment('cm-long', 'Nice one.', { ...SALMA, headline: long })], nextCursor: null, total: 1 }),
    );
    await openHome(page);
    const card = cardOf(page, CLEAN);
    await card.locator('[data-card-comment]').click();
    const section = isPhone(page) ? card.locator('rd-bottom-sheet section[role="dialog"]') : card.locator('[data-card-comments]');
    const headline = section.locator('[data-comment="cm-long"] [data-comment-headline]');
    await expect(headline).toHaveText(long, { timeout: FIRST_RENDER_MS });

    const layout = await headline.evaluate((line) => {
      const text = line.querySelector('bdi')!;
      const node = Array.from(text.childNodes).find((n) => n.nodeType === Node.TEXT_NODE && n.textContent!.trim())!;
      const first = document.createRange();
      const at = node.textContent!.search(/\S/);
      first.setStart(node, at);
      first.setEnd(node, at + 1);
      const box = line.getBoundingClientRect();
      const glyph = first.getBoundingClientRect();
      return {
        line: getComputedStyle(line).direction,
        own: getComputedStyle(text).direction,
        overflow: getComputedStyle(text).textOverflow,
        cut: text.scrollWidth > text.clientWidth,
        firstShown: glyph.width > 0 && glyph.left >= box.left - 0.5 && glyph.right <= box.right + 0.5,
      };
    });
    // The line keeps the UI's direction; the title runs in its own and is cut ("…") at its own end, so its first
    // letter is on screen (it used to be the end of the title that showed).
    expect(layout).toEqual({ line: dir, own, overflow: 'ellipsis', cut: true, firstShown: true });
  });
}
