import { expect, test } from '@playwright/test';
import { API, VARIANTS, hasScreenshot, onApi, parkMouse, reply, restoreSessionAs, signInAsWriter, useVariant, writerMe } from './support/mock-api';

/**
 * The people you follow, in the panel docked at the bottom corner (wide screens, signed in): closed to its header bar,
 * open on a click, then the list, a search, and writers you might like when you follow only a few. Not on phones, not
 * in the editor (`/write/:id`). Screenshots in ar/light and en/dark (SPEC §27).
 */
const FIRST_RENDER_MS = 30_000;

// Signs in, reloads and opens the editor: more than the default 30 s on a busy machine.
test.describe.configure({ timeout: 90_000 });

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const ar = lang === 'ar';
  const suffix = `${lang}-${theme}`;

  test(`Following panel: the people you follow, a search, writers you might like — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    const person = (id: string, displayName: string, username: string, bio: string | null, extra: { isVerified?: boolean; followsYou?: boolean; isFollowing?: boolean } = {}) => ({
      id,
      displayName,
      username,
      avatarUrl: null,
      isVerified: extra.isVerified ?? false,
      bio,
      isFollowing: extra.isFollowing ?? true,
      followsYou: extra.followsYou ?? false,
    });
    // Fixed answers: the shared mock's follows change with other tests, and following here changes nothing there.
    const following = [
      person('u-dock-1', ar ? 'سلمى إبراهيم' : 'Salma Ibrahim', 'salma', ar ? 'أكتب عن الذكاء الاصطناعي ببساطة.' : 'AI, explained simply.', { isVerified: true, followsYou: true }),
      person('u-dock-2', 'Omar Fathy', 'omar', null),
    ];
    await onApi(page, 'GET', new RegExp(`^${API}/users/[^/]+/following(\\?.*)?$`), (route) => {
      const q = (new URL(route.request().url()).searchParams.get('q') ?? '').toLowerCase();
      const items = following.filter((u) => !q || u.displayName.toLowerCase().includes(q) || u.username.includes(q));
      return reply(route, 200, { items, nextCursor: null });
    });
    await onApi(page, 'GET', new RegExp(`^${API}/users/suggested(\\?.*)?$`), (route) =>
      reply(route, 200, [
        person('u-dock-3', ar ? 'دينا فوزي' : 'Dina Fawzy', 'dina', ar ? 'طب وصحة عامة.' : 'Medicine and public health.', { isFollowing: false }),
        person('u-dock-4', 'Karim Adel', 'karim', null, { isFollowing: false, isVerified: true }),
        person('u-dock-5', ar ? 'نور حسن' : 'Nour Hassan', 'nour', ar ? 'تصميم المنتجات.' : 'Product design.', { isFollowing: false }),
      ]),
    );
    await onApi(page, 'PUT', new RegExp(`^${API}/users/u-dock-[0-9]/follow$`), (route) => reply(route, 200, { isFollowing: true, followerCount: 1 }));

    await signInAsWriter(page, request, variant, '/');
    const dock = page.locator('[data-following-dock]');
    if (testInfo.project.name !== 'desktop') {
      // Phones and narrow windows: no docked panel.
      await page.waitForLoadState('networkidle');
      await expect(dock).toHaveCount(0);
      return;
    }

    const toggle = dock.locator('[data-dock-toggle]');
    await expect(toggle).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await expect(dock.locator('#rd-dock-title')).toHaveText(ar ? 'المتابَعون' : 'Following');
    await expect(dock.locator('[data-dock-panel]')).toHaveCount(0);

    await toggle.click();
    await expect(toggle).toHaveAttribute('aria-expanded', 'true');
    const people = dock.locator('[data-dock-person]');
    await expect(people).toHaveCount(2);
    await expect(people.first()).toHaveAttribute('href', '/@salma');
    await expect(people.first().locator('[data-dock-follows-you]')).toHaveText(ar ? 'يتابعك' : 'Follows you');
    // Following only two: writers you might like, from your interests.
    const suggestions = dock.locator('[data-dock-suggestion]');
    await expect(suggestions).toHaveCount(3);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(dock).toHaveScreenshot(`following-dock-${suffix}.png`);

    const follow = suggestions.first().locator('[data-follow]');
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'true');

    const search = dock.locator('[data-dock-search]');
    await search.fill(ar ? 'سلمى' : 'salma');
    await expect(people).toHaveCount(1);
    await expect(dock.locator('[data-dock-suggestions]')).toHaveCount(0);
    await search.fill('zzz');
    await expect(dock.locator('[data-dock-empty]')).toContainText('zzz');

    // Escape closes it, and a reload keeps it as you left it.
    await page.keyboard.press('Escape');
    await expect(dock.locator('[data-dock-panel]')).toHaveCount(0);
    await expect(toggle).toBeFocused();
    await restoreSessionAs(page, await writerMe(request, variant)); // the reload restores the session
    await page.reload();
    await expect(toggle).toHaveAttribute('aria-expanded', 'false', { timeout: FIRST_RENDER_MS });

    // The editor uses the whole window: no panel there.
    await page.goto('/write/new');
    await expect(page.locator('rd-article-editor')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');
    await expect(dock).toHaveCount(0);
  });
}
