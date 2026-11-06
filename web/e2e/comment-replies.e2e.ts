import { Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, HIDE_READER_BAR, VARIANTS, hasScreenshot, onApi, parkMouse, reply, useVariant } from './support/mock-api';
import { openArticle, signInAsReader } from './support/social';

/**
 * A comment thread in the reader (F11), compact like LinkedIn and Facebook, in ar/light and en/dark, desktop and phone:
 * the first reply shows; "show N more replies" shows up to 5 more per tap (the loaded one first, then
 * `GET /comments/{id}/replies?limit=5`); "Hide replies" folds the thread back to its first reply and a later "show more"
 * shows the loaded replies again without asking the API.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** The comments say how long ago each one was written: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');
const CLEAN = 'a-clean-architecture-whiteboard';

const SALMA = { id: 'u-salma', displayName: 'سلمى إبراهيم', username: 'salma', avatarUrl: null, isVerified: false, headline: 'ML Engineer | بحب أبسّط الـ AI' };
const KARIM = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true, headline: 'Frontend lead · React & Angular' };
const OMAR = { id: 'u-omar', displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false, headline: null };
const PEOPLE = [SALMA, OMAR, KARIM];

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

/** Reply `n` of the thread, oldest first, by Salma, Omar and Karim in turn. */
function replyOf(n: number) {
  return comment(`r${n}`, `Reply ${n}: agreed, the use cases layer is the heart of it.`, PEOPLE[(n - 1) % PEOPLE.length], {
    parentId: 'cm-1',
    createdAt: new Date(Date.parse('2026-11-03T19:00:00Z') + n * 60_000).toISOString(),
    likeCount: n === 1 ? 3 : 0,
    isFollowingAuthor: PEOPLE[(n - 1) % PEOPLE.length] === KARIM,
  });
}
const range = (from: number, to: number) => Array.from({ length: to - from + 1 }, (_, i) => replyOf(from + i));

const shownReplies = (page: Page) => page.locator('[data-thread="cm-1"] [data-replies] [data-comment]');

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`a thread shows its first reply, 5 more per tap, and folds back — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    const thread = comment('cm-1', t('أخيرًا فهمت ليه الـ dependencies بتشاور لجوه.', 'Finally clicked why dependencies point inwards.'), KARIM, {
      likeCount: 12,
      replyCount: 8,
      replies: range(1, 2),
    });
    await onApi(page, 'GET', new RegExp(`${API}/articles/${CLEAN}/comments\\?`), (route) => reply(route, 200, { items: [thread], nextCursor: null, total: 9 }));
    const pages: string[] = [];
    await onApi(page, 'GET', new RegExp(`${API}/comments/cm-1/replies\\?`), (route) => {
      const url = new URL(route.request().url());
      const cursor = url.searchParams.get('cursor');
      pages.push(`${cursor}|${url.searchParams.get('limit')}`);
      return reply(route, 200, cursor === 'p2' ? { items: range(6, 8), nextCursor: null } : { items: range(1, 5), nextCursor: 'p2' });
    });
    await page.clock.setFixedTime(NOW);
    await openArticle(page, '/en/a/clean-architecture-whiteboard');
    await page.locator('#comments').scrollIntoViewIfNeeded();
    const threadEl = page.locator('[data-thread="cm-1"]');
    const more = threadEl.locator('[data-more-replies]');
    const hide = threadEl.locator('[data-hide-replies]');

    // Folded: the first reply, then "show 7 more replies"; nothing to hide yet.
    await expect(more).toHaveText(t('عرض 7 ردود إضافية', 'Show 7 more replies'), { timeout: FIRST_RENDER_MS });
    await expect(shownReplies(page)).toHaveCount(1);
    await expect(hide).toHaveCount(0);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(threadEl).toHaveScreenshot(`comment-thread-folded-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_READER_BAR] });

    // A tap: the loaded reply and the first page of 5 (the 2 the list gave are deduped).
    await more.click();
    await expect(shownReplies(page)).toHaveCount(5);
    await expect(more).toHaveText(t('عرض 3 ردود إضافية', 'Show 3 more replies'));
    await expect(hide).toHaveText(t('إخفاء الردود', 'Hide replies'));
    expect(pages).toEqual(['null|5']);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(threadEl).toHaveScreenshot(`comment-thread-more-${suffix}.png`, { stylePath: [HIDE_APP_CHROME, HIDE_READER_BAR] });

    // The rest; then "Hide replies" folds back, and the loaded replies show again without a request.
    await more.click();
    await expect(shownReplies(page)).toHaveCount(8);
    await expect(more).toHaveCount(0);
    expect(pages).toEqual(['null|5', 'p2|5']);
    await hide.click();
    await expect(shownReplies(page)).toHaveCount(1);
    await expect(more).toHaveText(t('عرض 7 ردود إضافية', 'Show 7 more replies'));
    await more.click();
    await expect(shownReplies(page)).toHaveCount(6);
    await more.click();
    await expect(shownReplies(page)).toHaveCount(8);
    expect(pages).toEqual(['null|5', 'p2|5']);
  });
}
