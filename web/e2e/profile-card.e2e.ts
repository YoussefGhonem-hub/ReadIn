import { Locator, Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, HIDE_READER_BAR, VARIANTS, hasScreenshot, onApi, parkMouse, reply, useVariant } from './support/mock-api';
import { openArticle, signInAsReader } from './support/social';

/**
 * The profile card (web, F11/F14), LinkedIn's "mini profile", in ar/light and en/dark: a pointer resting on an @mention
 * or a commenter's name in the reader's comments opens a small card about the person (photo, name, @username, title,
 * "Follows you", followers and articles, Follow). It sits under the link on its start side, stays open while the
 * pointer moves onto it, follows through the shared follow store, and closes on Escape or when the pointer leaves. On
 * touch there is no card: a tap opens the profile as before.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** The comments say how long ago each one was written: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');
const CLEAN = 'a-clean-architecture-whiteboard';

/** Writers the mock API knows (so following them works); seeded readers follow Karim, not Salma. */
const SALMA = { id: 'u-salma', displayName: 'سلمى إبراهيم', username: 'salma', avatarUrl: null, isVerified: false, headline: 'ML Engineer | بحب أبسّط الـ AI' };
const KARIM = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true, headline: 'Frontend lead · React & Angular' };

/** Salma's profile as the card reads it, fixed so the shot doesn't move with the mock's follower counts. */
const SALMA_PROFILE = {
  ...SALMA,
  avatarVariants: null,
  bio: 'ML engineer بتحب تبسّط الـ AI.',
  links: [],
  expertise: [],
  joinedAt: '2026-02-14T09:00:00Z',
  stats: { articles: 12, followers: 430, following: 51, totalReads: 9100 },
  isMe: false,
  isFollowing: false,
  followsYou: true,
  readingStatsVisible: false,
};

function comment(id: string, body: string, author: object, patch: Record<string, unknown> = {}) {
  return {
    id,
    articleId: CLEAN,
    parentId: null,
    body,
    author,
    isArticleAuthor: false,
    mentions: [],
    likeCount: 0,
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
    isFollowingAuthor: true,
    ...patch,
  };
}

const isPhone = (page: Page) => page.viewportSize()!.width < 768;
const cardOf = (page: Page): Locator => page.locator('.cdk-overlay-container [data-profile-card]');

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`a pointer resting on a mention or a name in the comments opens the person's card — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    const body = t('شكرًا @salma على الشرح، الفكرة وصلت', 'Thanks @salma, that made it click');
    const list = [comment('cm-1', body, KARIM, { mentions: [{ userId: SALMA.id, username: SALMA.username }] })];
    await onApi(page, 'GET', new RegExp(`${API}/articles/${CLEAN}/comments\\?`), (route) => reply(route, 200, { items: list, nextCursor: null, total: 1 }));
    const profiles: string[] = [];
    await onApi(page, 'GET', `/users/${SALMA.username}`, (route) => {
      profiles.push(SALMA.username);
      return reply(route, 200, SALMA_PROFILE);
    });
    await page.clock.setFixedTime(NOW);
    await openArticle(page, '/en/a/clean-architecture-whiteboard');
    await page.locator('#comments').scrollIntoViewIfNeeded();
    const mention = page.locator('[data-comment="cm-1"] a[data-mention]');
    await expect(mention).toHaveText('@salma', { timeout: FIRST_RENDER_MS });
    await expect(mention).not.toHaveAttribute('aria-haspopup', /.*/); // the link stays a plain link
    const card = cardOf(page);

    if (isPhone(page)) {
      // Touch: no card; a tap opens the profile as before.
      await mention.hover();
      await page.waitForTimeout(1000);
      await expect(card).toHaveCount(0);
      await mention.tap();
      await expect(page).toHaveURL(/\/@salma$/);
      return;
    }

    // Resting on the mention opens the card under it, on its start side, without taking the focus.
    await mention.hover();
    await expect(card).toBeVisible();
    await expect(card).toHaveAttribute('role', 'dialog');
    await expect(card).toHaveAttribute('aria-label', SALMA.displayName);
    await expect(card.locator('[data-profile-card-name]')).toHaveText(SALMA.displayName);
    await expect(card.locator('[data-profile-card-name]')).toHaveAttribute('href', '/@salma');
    await expect(card.locator('[data-profile-card-username]')).toHaveText('@salma');
    await expect(card.locator('[data-profile-card-headline]')).toHaveText(SALMA.headline);
    await expect(card.locator('[data-profile-card-follows-you]')).toHaveText(t('يتابعك', 'Follows you'));
    await expect(card.locator('[data-profile-card-stats]')).toHaveText(t('430 متابِعًا · 12 مقالًا', '430 followers · 12 articles'));
    const follow = card.locator('[data-follow]');
    await expect(follow).toContainText(t('متابعة', 'Follow'));
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    expect(await card.evaluate((el) => el.contains(document.activeElement))).toBe(false); // it never takes the focus

    const link = (await mention.boundingBox())!;
    const box = (await card.boundingBox())!;
    expect(box.y - (link.y + link.height)).toBeGreaterThanOrEqual(6);
    expect(box.y - (link.y + link.height)).toBeLessThanOrEqual(10);
    if (dir === 'ltr') expect(Math.abs(box.x - link.x)).toBeLessThan(2);
    else expect(Math.abs(box.x + box.width - (link.x + link.width))).toBeLessThan(2);
    expect(Math.round(box.width)).toBe(320);
    if (hasScreenshot(variant)) await expect(card).toHaveScreenshot(`profile-card-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_READER_BAR] });

    // Moving onto the card keeps it open; Follow there follows through the shared store.
    await card.hover();
    await page.waitForTimeout(600);
    await expect(card).toBeVisible();
    const followed = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith(`/users/${SALMA.id}/follow`));
    await follow.click();
    expect((await followed).status()).toBe(200);
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(follow).toContainText(t('تتابعه', 'Following'));
    await expect(card.locator('[data-profile-card-stats]')).toContainText(t('431 متابِعًا', '431 followers'));

    // Escape closes it.
    await page.keyboard.press('Escape');
    await expect(card).toHaveCount(0);

    // The commenter's name opens their card too; leaving it closes the card after a short grace.
    await page.locator('[data-comment="cm-1"] [data-comment-author]').hover();
    await expect(card.locator('[data-profile-card-name]')).toHaveText(KARIM.displayName);
    await expect(card.locator('[data-follow]')).toHaveAttribute('aria-pressed', 'true'); // seeded readers follow Karim
    await parkMouse(page);
    await expect(card).toHaveCount(0);

    // A card shown again within 2 minutes comes from memory.
    await mention.hover();
    await expect(card.locator('[data-profile-card-name]')).toHaveText(SALMA.displayName);
    expect(profiles).toHaveLength(1);
  });
}
