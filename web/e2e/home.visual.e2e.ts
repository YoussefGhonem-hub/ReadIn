import { expect, test } from '@playwright/test';
import { VARIANTS, hasScreenshot } from './support/mock-api';

/**
 * Home in ar/light and en/dark (SPEC §15.5 rule 9, §27), each with a screenshot.
 * Theme and UI language come from the `theme` / `lang` cookies, exactly like a returning user, so the SSR
 * output is checked for flash-free theming as well.
 */
for (const { lang, theme, dir } of VARIANTS) {
  test(`home — ${lang}/${theme}`, async ({ page, context, baseURL }) => {
    const { hostname } = new URL(baseURL!);
    await context.addCookies([
      { name: 'lang', value: lang, domain: hostname, path: '/' },
      { name: 'theme', value: theme, domain: hostname, path: '/' },
    ]);

    // The greeting depends on the hour ("Good morning" / "Good evening"); pin the browser clock so the baseline is stable.
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00'));
    await page.goto('/');

    const html = page.locator('html');
    await expect(html).toHaveAttribute('lang', lang);
    await expect(html).toHaveAttribute('dir', dir);
    await expect(html).toHaveAttribute('data-theme', theme);

    // Wait for the feed to settle (articles, empty or error state), then capture.
    await page.waitForLoadState('networkidle');
    if (hasScreenshot({ lang, theme })) await expect(page).toHaveScreenshot(`home-${lang}-${theme}.png`, { fullPage: true });
  });
}
