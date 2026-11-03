import { expect, test } from '@playwright/test';
import { VARIANTS, useVariant } from './support/mock-api';

interface ShiftLog {
  cls: number;
  shifts: { value: number; sources: string[] }[];
}

/**
 * Layout stability of media in the feed (F26: "always reserve the image size, no layout shift"). A stand-in for a
 * Lighthouse CLS audit: the server-rendered feed (carousels, a single image, a PDF) hydrates, images load and lazy
 * ones arrive while scrolling, and the cumulative layout-shift score from `PerformanceObserver('layout-shift')`
 * must stay under 0.01.
 */
// Scrolling the whole feed takes a while when the full suite shares the dev server; the CLS score doesn't depend on it.
test.describe.configure({ timeout: 60_000 });

for (const variant of [VARIANTS[0], VARIANTS[3]]) {
  test(`feed with image attachments has CLS < 0.01 — ${variant.lang}/${variant.theme}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.addInitScript(() => {
      const log: ShiftLog = { cls: 0, shifts: [] };
      (window as unknown as { __rdShifts: ShiftLog }).__rdShifts = log;
      new PerformanceObserver((list) => {
        for (const entry of list.getEntries() as (PerformanceEntry & { value: number; hadRecentInput: boolean; sources?: { node?: Node | null }[] })[]) {
          if (entry.hadRecentInput) continue;
          log.cls += entry.value;
          log.shifts.push({
            value: entry.value,
            sources: (entry.sources ?? []).map((s) => (s.node instanceof Element ? `${s.node.tagName.toLowerCase()}.${s.node.className}` : String(s.node?.nodeName))),
          });
        }
      }).observe({ type: 'layout-shift', buffered: true });
    });

    await page.goto('/');
    await expect(page.locator('rd-article-attachments').first()).toBeVisible();
    await page.waitForLoadState('networkidle');

    // Scroll through the feed so lazy images load into their reserved boxes, then come back up.
    const height = await page.evaluate(() => document.documentElement.scrollHeight);
    for (let y = 0; y < height; y += 250) {
      await page.evaluate((top) => window.scrollTo(0, top), y);
      await page.waitForTimeout(120);
    }
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const log = await page.evaluate(() => (window as unknown as { __rdShifts: ShiftLog }).__rdShifts);
    const loadedImages = await page.locator('rd-article-attachments img').evaluateAll((imgs) => imgs.filter((img) => (img as HTMLImageElement).naturalWidth > 0).length);
    expect(loadedImages).toBeGreaterThan(3);
    test.info().annotations.push({ type: 'CLS', description: log.cls.toFixed(4) });
    console.log(`CLS ${variant.lang}/${variant.theme} [${test.info().project.name}]: ${log.cls.toFixed(4)} (${loadedImages} images loaded)`);
    expect(log.cls, JSON.stringify(log.shifts, null, 2)).toBeLessThan(0.01);
  });
}
