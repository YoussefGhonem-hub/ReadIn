import { Locator, Page, Route, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, HIDE_READER_BAR, MOCK_ORIGIN, VARIANTS, hasScreenshot, onApi, parkMouse, reply, restoreSessionAs, sessionFor, useVariant, writerMe } from './support/mock-api';
import { openProfile } from './support/profile';
import { expectSignInPrompt, openArticle, signInAsReader } from './support/social';

/**
 * F28 Article menu, mute and "Show less" end to end in ar/light and en/dark: the "⋯" menu in its order (someone else's
 * article, your own, guests), Show less and Mute author with Undo on Home (the cards fold away and come back in place),
 * the "كتم المواضيع" sheet, the "انت كاتم الكاتب ده" banner in the reader and on a profile, comments by a muted writer
 * collapsed until "عرض", and Settings → Muted. The mock API keeps each reader's mutes (e2e/mock-api/mutes.mjs); the
 * flags a page loads with (`isAuthorMuted`, `ProfileDto.isMuted`, a card's `topic`) are routed here.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
const CLEAN = 'a-clean-architecture-whiteboard';
/** Mona's articles: the whole For you feed of the mock. */
const MONA = [CLEAN, 'a-dependency-injection-ar', 'a-aspnet-core-cheatsheet', 'a-one-photo'];
const OTHERS = ['showLess', 'follow', 'muteAuthor', 'muteTopics', 'report'];
/** The reader's menu adds Hide highlights (F30) after Show less; a post card's doesn't. */
const READER = ['showLess', 'highlights', 'follow', 'muteAuthor', 'muteTopics', 'report'];
const ARCHITECTURE = { id: 't-architecture', slug: 'architecture', name: 'Architecture', nameAr: 'المعمارية', nameEn: 'Architecture', isSensitive: false };

const cardOf = (page: Page, id: string): Locator => page.locator(`rd-post-card[data-post-card="${id}"]`).first();
const panel = (page: Page) => page.locator('[data-article-menu-panel]');
const actions = (page: Page) => panel(page).locator('[data-menu-action]');
const toast = (page: Page) => page.locator('rd-toast-host');

async function openMenu(scope: Locator, page: Page): Promise<void> {
  await scope.locator('[data-article-menu]').click();
  await expect(panel(page)).toBeVisible();
}

async function pick(page: Page, action: string): Promise<void> {
  await panel(page).locator(`[data-menu-action="${action}"]`).click();
  await expect(panel(page)).toHaveCount(0);
}

/** Answers a routed GET with the real mock response, changed by `patch`. */
async function patchJson(route: Route, patch: (body: Record<string, unknown>) => Record<string, unknown>): Promise<void> {
  if (route.request().method() !== 'GET') return route.fallback();
  const response = await route.fetch();
  await route.fulfill({ response, json: patch((await response.json()) as Record<string, unknown>) });
}

async function openHome(page: Page): Promise<void> {
  await page.goto('/');
  await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS }); // the session is restored
  await expect(cardOf(page, CLEAN)).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle');
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`feed: the "⋯" menu, Show less and Mute author with Undo — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-04T09:00:00Z'));
    const me = await signInAsReader(page, request, variant);
    await openHome(page);

    // Someone else's article: Show less, Follow, Mute author, Mute topics, then Report in the error color.
    const clean = cardOf(page, CLEAN);
    await openMenu(clean, page);
    await expect(actions(page)).toHaveText([
      t('قلّل من النوع ده', 'Show less like this'),
      t('تابع الكاتب', 'Follow author'),
      t('كتم الكاتب', 'Mute author'),
      t('كتم المواضيع', 'Mute topics'),
      t('الإبلاغ عن المقال', 'Report article'),
    ]);
    expect(await actions(page).evaluateAll((items) => items.map((i) => i.getAttribute('data-menu-action')))).toEqual(OTHERS);
    await expect(panel(page).locator('[data-menu-action="report"]')).toHaveClass(/text-error/);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(panel(page)).toHaveScreenshot(`article-menu-${suffix}.png`);

    // Show less: the card folds away; Undo brings it back in place.
    const order = () => page.locator('rd-post-card:visible').evaluateAll((cards) => cards.map((c) => c.getAttribute('data-post-card')));
    const before = await order();
    await pick(page, 'showLess');
    await expect(clean).toBeHidden();
    await expect(toast(page)).toContainText(t('تمام، هتشوف مقالات أقل من النوع ده', "Got it. You'll see fewer articles like this."));
    expect(await (await request.get(`${MOCK_ORIGIN}/__mock/show-less?viewer=${me.id}`)).json()).toEqual([CLEAN]);
    const undone = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().endsWith(`/articles/${CLEAN}/show-less`));
    await toast(page).locator('[data-toast-action]').click();
    await undone;
    await expect(clean).toBeVisible();
    expect(await order()).toEqual(before);

    // Mute author: every card by Mona leaves; Undo puts them all back where they were.
    await openMenu(cardOf(page, 'a-one-photo'), page);
    await pick(page, 'muteAuthor');
    for (const id of MONA) await expect(cardOf(page, id)).toBeHidden();
    await expect(toast(page)).toContainText(t('كتمت', 'You muted'));
    await expect(toast(page)).toContainText('Mona Adel');
    await toast(page).locator('[data-toast-action]').click();
    for (const id of MONA) await expect(cardOf(page, id)).toBeVisible();
    expect(await order()).toEqual(before);
    // The mock kept nothing muted.
    const mutes = await (await request.get(`${API}/me/mutes`, { headers: { authorization: `Bearer ${sessionFor(me).accessToken}` } })).json();
    expect(mutes.users).toEqual([]);
  });

  test(`menu: your own article keeps Mute topics (and Download PDF, F33); guests sign in first — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // Guests: every item, each asking to sign in.
    await page.goto('/en/a/clean-architecture-whiteboard');
    const bar = page.locator('rd-article-action-bar');
    await expect(bar.locator('[data-react]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await openMenu(bar, page);
    expect(await actions(page).evaluateAll((items) => items.map((i) => i.getAttribute('data-menu-action')))).toEqual(READER);
    await pick(page, 'muteAuthor');
    await expectSignInPrompt(page);
    await openMenu(bar, page);
    await pick(page, 'showLess');
    await expectSignInPrompt(page);

    // The writer on their own article.
    const writer = await writerMe(request, variant);
    await restoreSessionAs(page, writer);
    await openArticle(page, '/en/a/clean-architecture-whiteboard');
    await openMenu(bar, page);
    await expect(actions(page)).toHaveText([t('إخفاء الـ Highlights', 'Hide highlights'), t('كتم المواضيع', 'Mute topics'), t('تحميل PDF', 'Download PDF')]);
  });

  test(`reader: the topics sheet, the muted-writer banner and collapsed comments — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-04T09:00:00Z'));
    await signInAsReader(page, request, variant);
    // The article has a topic (Architecture), and one of its comments is by a writer you muted.
    await page.route(new RegExp(`${API}/articles/clean-architecture-whiteboard(\\?.*)?$`), (route) => patchJson(route, (a) => ({ ...a, topic: ARCHITECTURE })));
    const omar = { id: 'u-omar', displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false };
    const comment = (id: string, body: string, patch: Record<string, unknown> = {}) => ({
      id,
      articleId: CLEAN,
      parentId: null,
      body,
      author: omar,
      isAuthorMuted: true,
      isArticleAuthor: false,
      mentions: [],
      likeCount: 1,
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
    });
    const reply1 = comment('cm-r', 'Agreed, the use cases layer is the heart of it.', {
      parentId: 'cm-muted',
      author: { id: 'u-salma', displayName: 'سلمى إبراهيم', username: 'salma', avatarUrl: null, isVerified: false },
      isAuthorMuted: false,
    });
    const list = [comment('cm-muted', 'Entities first, frameworks last. Always.', { replyCount: 1, replies: [reply1] })];
    await onApi(page, 'GET', new RegExp(`${API}/articles/${CLEAN}/comments\\?`), (route) => reply(route, 200, { items: list, nextCursor: null, total: 2 }));
    await openArticle(page, '/en/a/clean-architecture-whiteboard');
    const bar = page.locator('rd-article-action-bar');

    // Mute topics: the field and the topic, each saved at once.
    await openMenu(bar, page);
    await pick(page, 'muteTopics');
    const sheet = page.locator('[data-mute-topics-sheet]');
    await expect(sheet).toBeVisible({ timeout: FIRST_RENDER_MS });
    const field = sheet.locator('[data-mute-field="f-software"] [role="switch"]');
    const topic = sheet.locator('[data-mute-topic="t-architecture"] [role="switch"]');
    await expect(sheet.locator('[data-mute-field="f-software"] label')).toContainText(t('البرمجيات', 'Software'));
    await expect(sheet.locator('[data-mute-topic="t-architecture"] label')).toContainText(t('المعمارية', 'Architecture'));
    await expect(field).toHaveAttribute('aria-checked', 'false');
    const saved = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith('/me/mutes/topics/t-architecture'));
    await topic.click();
    expect((await saved).status()).toBe(200);
    await expect(topic).toHaveAttribute('aria-checked', 'true');
    await expect(topic).toBeEnabled();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-mute-topics-sheet section[role="dialog"]')).toHaveScreenshot(`mute-topics-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await sheet.locator('[data-mute-topics-done]').click();
    await expect(sheet).toHaveCount(0);

    // Mute author from the reader: the banner instead of leaving the page.
    const banner = page.locator('[data-muted-banner]');
    await expect(banner).toHaveCount(0);
    await openMenu(bar, page);
    await pick(page, 'muteAuthor');
    await expect(banner).toBeVisible();
    await expect(banner).toContainText(t('انت كاتم الكاتب ده', 'You muted this writer'));
    await expect(toast(page)).toContainText('Mona Adel');
    await page.locator('rd-toast-host button').last().click(); // close the toast
    await page.evaluate(() => window.scrollTo(0, 0));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(banner).toHaveScreenshot(`muted-banner-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await openMenu(bar, page);
    await expect(panel(page).locator('[data-menu-action="muteAuthor"]')).toHaveText(t('إلغاء كتم الكاتب', 'Unmute author'));
    await page.keyboard.press('Escape');

    // "إلغاء الكتم" unmutes without following again.
    const unmuted = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().includes('/users/u-writer/mute'));
    await banner.locator('[data-muted-unmute]').click();
    expect(new URL((await unmuted).url()).search).toBe('');
    await expect(banner).toHaveCount(0);

    // A comment by Omar (muted) is collapsed; its reply stays; "عرض" shows it here.
    await page.locator('#comments').scrollIntoViewIfNeeded();
    const muted = page.locator('[data-comment="cm-muted"]');
    await expect(muted.locator('[data-comment-muted]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(muted.locator('[data-comment-muted]')).toContainText(t('تعليق من شخص كتمته', 'Comment from someone you muted'));
    await expect(page.locator('[data-comment="cm-r"] [data-comment-body]')).toBeVisible();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-comment-thread').first()).toHaveScreenshot(`muted-comment-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_READER_BAR] });
    await muted.locator('[data-comment-reveal]').click();
    await expect(muted.locator('[data-comment-body]')).toHaveText('Entities first, frameworks last. Always.');
    await expect(muted.locator('[data-comment-author]')).toBeFocused();
  });

  test(`profile: a muted writer's page says so, with Unmute — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await page.route(new RegExp(`${API}/users/omar_dev$`), (route) =>
      patchJson(route, (p) => ({ ...p, isMuted: route.request().headers()['authorization'] ? true : false })),
    );
    await openProfile(page, '/@omar_dev', { signedIn: true });
    const banner = page.locator('[data-muted-banner]');
    await expect(banner).toBeVisible();
    // Their articles stay listed: you opened their page on purpose.
    await expect(page.locator('rd-post-card[data-post-card="a-sleep-and-memory"]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    const unmuted = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().includes('/users/u-omar/mute'));
    await banner.locator('[data-muted-unmute]').click();
    await unmuted;
    await expect(banner).toHaveCount(0);
    await expect(toast(page)).toContainText('Omar Fathy');
  });

  test(`settings → muted: one list with Unmute, and the empty state — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsReader(page, request, variant);
    const headers = { authorization: `Bearer ${sessionFor(me).accessToken}` };
    // Muted elsewhere (oldest first): Omar, then Medicine, then the .NET topic, then Karim.
    for (const path of ['/users/u-omar/mute', '/me/mutes/fields/f-medicine', '/me/mutes/topics/t-dotnet', '/users/u-karim/mute']) {
      expect((await request.put(`${API}${path}`, { headers })).ok()).toBe(true);
    }

    await page.goto('/settings');
    const row = page.locator('[data-settings-muted]');
    await expect(row).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(row).toContainText(t('اللي كتمته', 'Muted'));
    await row.click();
    await page.waitForURL((url) => url.pathname === '/settings/muted');
    await expect(page).toHaveTitle(t('اللي كتمته — ReadIn', 'Muted — ReadIn'));
    const list = page.locator('[data-muted-list]');
    await expect(list).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(list.locator('[data-muted-user]')).toHaveCount(2);
    expect(await list.locator('[data-muted-user]').evaluateAll((rows) => rows.map((r) => r.getAttribute('data-muted-id')))).toEqual(['u-karim', 'u-omar']);
    await expect(list.locator('[data-muted-field]')).toContainText(t('الطب', 'Medicine'));
    await expect(list.locator('[data-muted-topic]')).toContainText('.NET');
    await expect(list.locator('[data-muted-topic]')).toContainText(t('البرمجيات', 'Software'));
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-muted-page')).toHaveScreenshot(`settings-muted-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Unmute each: the row leaves once saved; nothing left → the empty state.
    const rows = list.locator('[data-muted-user], [data-muted-field], [data-muted-topic]');
    for (let left = 4; left > 0; left--) {
      await rows.first().locator('[data-muted-unmute]').click();
      await expect(rows).toHaveCount(left - 1);
    }
    const empty = page.locator('[data-muted-empty]');
    await expect(empty).toBeVisible();
    await expect(empty).toContainText(t('مكتمتش حاجة لسه', "You haven't muted anything"));
    const mutes = await (await request.get(`${API}/me/mutes`, { headers })).json();
    expect(mutes).toEqual({ users: [], fields: [], topics: [] });
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-muted-page')).toHaveScreenshot(`settings-muted-empty-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
  });
}

