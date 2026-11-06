import { Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, VARIANTS, hasScreenshot, onApi, parkMouse, reply, signInAsWriter, useVariant } from './support/mock-api';

/**
 * The LinkedIn-style top bar and Home's columns: from `md` the destinations as an icon above a label, the theme and
 * language toggles and Me (its menu); below it the compact bar. The toggles flip the theme or the interface language
 * (and direction) and a reload keeps them (the cookies, so the server renders them). Screenshots in ar/light and en/dark (SPEC §27).
 */
const FIRST_RENDER_MS = 30_000;

/**
 * Home's side columns read data other tests change on the shared mock (follows, reads, enrollments): fixed answers keep
 * their screenshots stable, and following here changes nothing there.
 */
async function fixRailData(page: Page, ar: boolean): Promise<void> {
  const writer = (id: string, displayName: string, username: string, bio: string | null, isVerified = false) => ({
    id,
    displayName,
    username,
    avatarUrl: null,
    isVerified,
    bio,
    isFollowing: false,
    followsYou: false,
  });
  await onApi(page, 'GET', new RegExp(`^${API}/users/suggested(\\?.*)?$`), (route) =>
    reply(route, 200, [
      writer('u-rail-1', ar ? 'سلمى إبراهيم' : 'Salma Ibrahim', 'salma', ar ? 'بكتب عن الذكاء الاصطناعي ببساطة.' : 'AI, explained simply.', true),
      writer('u-rail-2', 'Omar Fathy', 'omar', null),
      writer('u-rail-3', ar ? 'دينا فوزي' : 'Dina Fawzy', 'dina', ar ? 'طب وصحة عامة.' : 'Medicine and public health.'),
    ]),
  );
  await onApi(page, 'PUT', new RegExp(`^${API}/users/u-rail-[0-9]/follow$`), (route) => reply(route, 200, { isFollowing: true, followerCount: 1 }));
  await onApi(page, 'GET', '/me/stats', (route) =>
    reply(route, 200, {
      streak: { current: 6, longest: 12, readToday: true, freezeAvailable: true, freezePending: false, today: '2026-11-03' },
      totalArticles: 40,
      minutesRead: 320,
      articlesThisWeek: 4,
      minutesThisWeek: 31,
      articlesThisMonth: 15,
      topFields: [],
    }),
  );
  await onApi(page, 'GET', '/paths', (route) =>
    reply(route, 200, [
      {
        id: 'p-rail',
        slug: 'ai-from-scratch',
        title: ar ? 'الذكاء الاصطناعي من الصفر' : 'AI from scratch',
        description: null,
        field: { id: 'f-software', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software' },
        articleCount: 5,
        readingTimeMinutes: 34,
        coverUrl: null,
        progress: null,
        enrollment: null,
      },
    ]),
  );
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';
  const flipped = theme === 'dark' ? 'light' : 'dark';

  test(`theme toggle: one click flips the theme and a reload keeps it — ${suffix}`, async ({ page, context, baseURL }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/explore');
    const html = page.locator('html');
    await expect(html).toHaveAttribute('data-theme', theme);

    const toggle = page.locator('rd-top-bar [data-theme-toggle]:visible');
    await expect(toggle).toHaveCount(1);
    await expect(toggle).toHaveAttribute('aria-pressed', String(theme === 'dark'));
    const action = { ar: { dark: 'التبديل إلى الوضع الداكن', light: 'التبديل إلى الوضع الفاتح' }, en: { dark: 'Switch to dark mode', light: 'Switch to light mode' } }[lang];
    await expect(toggle).toHaveAttribute('aria-label', new RegExp(action[flipped]));

    // The bar itself: the nav row on wide screens, the compact bar on narrow ones.
    const desktop = testInfo.project.name === 'desktop';
    if (desktop) {
      await expect(page.locator('[data-top-nav] a[data-nav="explore"]')).toHaveAttribute('aria-current', 'page');
      await expect(page.locator('[data-header-search-input]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    } else {
      await expect(page.locator('[data-top-nav]')).toBeHidden();
      await expect(page.locator('rd-top-bar [data-search-link]')).toBeVisible();
    }
    await page.waitForLoadState('networkidle');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-top-bar')).toHaveScreenshot(`top-bar-guest-${suffix}.png`);

    await toggle.click();
    await expect(html).toHaveAttribute('data-theme', flipped);
    await expect(toggle).toHaveAttribute('aria-pressed', String(flipped === 'dark'));
    await expect(toggle).toHaveAttribute('aria-label', new RegExp(action[theme]));

    await page.reload();
    await expect(html).toHaveAttribute('data-theme', flipped);
  });

  test(`language toggle: one click switches the interface language and direction, and a reload keeps it — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/explore');
    const html = page.locator('html');
    const other = ar ? 'en' : 'ar';
    const endonym = { ar: 'العربية', en: 'English' };
    await expect(html).toHaveAttribute('lang', lang);

    const toggle = page.locator('rd-top-bar [data-language-toggle]:visible');
    await expect(toggle).toHaveCount(1);
    await expect(toggle).toHaveAttribute('aria-label', new RegExp(endonym[other]));

    await toggle.click();
    await expect(html).toHaveAttribute('lang', other);
    await expect(html).toHaveAttribute('dir', other === 'ar' ? 'rtl' : 'ltr');
    await expect(page.locator('rd-top-bar a[data-home-mark]')).toHaveAttribute('aria-label', other === 'ar' ? 'الرئيسية' : 'Home');
    await expect(toggle).toHaveAttribute('aria-label', new RegExp(endonym[lang]));

    await page.reload();
    await expect(html).toHaveAttribute('lang', other);
    await expect(html).toHaveAttribute('dir', other === 'ar' ? 'rtl' : 'ltr');
  });

  test(`Me menu: who you are, the links, Appearance; Escape gives the focus back — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await signInAsWriter(page, request, variant, '/');
    const desktop = testInfo.project.name === 'desktop';
    const me = page.locator(`[data-me-trigger="${desktop ? 'stacked' : 'icon'}"]`);
    await expect(me).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(me).toHaveAttribute('aria-expanded', 'false');

    await me.click();
    const menu = page.locator('[data-me-menu]');
    await expect(menu).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(me).toHaveAttribute('aria-expanded', 'true');
    await expect(menu.locator('[data-me-item="profile"]')).toBeFocused();
    await expect(menu.locator('[data-me-item="profile"]')).toHaveText(ar ? 'عرض الملف الشخصي' : 'View profile');
    await expect(menu.locator('[data-me-item="settings"]')).toHaveAttribute('href', '/settings');
    await expect(menu.locator('[data-me-item="myArticles"]')).toHaveAttribute('href', '/write');
    await expect(menu.locator('[data-me-item="myPaths"]')).toHaveAttribute('href', '/paths?tab=mine');
    await expect(menu.locator(`[data-me-theme="${theme}"]`)).toHaveAttribute('aria-checked', 'true');
    await page.keyboard.press('ArrowDown');
    await expect(menu.locator('[data-me-item="settings"]')).toBeFocused();
    await page.waitForLoadState('networkidle');
    if (hasScreenshot(variant)) await expect(menu).toHaveScreenshot(`me-menu-${suffix}.png`);

    // Appearance applies at once and keeps the menu open.
    await menu.locator(`[data-me-theme="${flipped}"]`).click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', flipped);
    await expect(menu.locator(`[data-me-theme="${flipped}"]`)).toHaveAttribute('aria-checked', 'true');

    await page.keyboard.press('Escape');
    await expect(menu).toHaveCount(0);
    await expect(me).toBeFocused();

    // "My paths" opens the paths page on its My paths tab.
    await me.click();
    await menu.locator('[data-me-item="myPaths"]').click();
    await page.waitForURL((url) => url.pathname === '/paths');
    await expect(page.locator('[data-paths-tab="mine"]')).toHaveAttribute('aria-selected', 'true', { timeout: FIRST_RENDER_MS });
  });

  test(`Home: three columns on wide screens, Start a post — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00'));
    await fixRailData(page, ar);
    await signInAsWriter(page, request, variant, '/');
    const start = page.locator('[data-start-post]');
    await expect(start).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(start.locator('[data-start-post-prompt]')).toHaveAttribute('href', '/write/new');

    if (testInfo.project.name !== 'desktop') {
      // Narrow screens: the feed alone.
      await expect(page.locator('[data-home-start]')).toHaveCount(0);
      await expect(page.locator('[data-home-end]')).toHaveCount(0);
      return;
    }
    const startColumn = page.locator('[data-home-start]');
    const endColumn = page.locator('[data-home-end]');
    await expect(startColumn.locator('[data-home-profile-card]')).toBeVisible();
    await expect(startColumn.locator('[data-home-reading-row="articles"] .rd-skeleton')).toHaveCount(0, { timeout: FIRST_RENDER_MS });
    await expect(startColumn.locator('[data-home-shortcut="myPaths"]')).toHaveAttribute('href', '/paths?tab=mine');
    await expect(endColumn.locator('[data-home-footer]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');
    await parkMouse(page);
    if (hasScreenshot(variant)) {
      await expect(startColumn).toHaveScreenshot(`home-start-column-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
      await expect(endColumn).toHaveScreenshot(`home-end-column-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    }

    // Following a suggested writer: "✓ Following" at once.
    const follow = endColumn.locator('[data-home-suggestion][data-user="u-rail-2"] [data-follow]');
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(follow).toContainText(ar ? 'تتابعه' : 'Following');
  });
}
