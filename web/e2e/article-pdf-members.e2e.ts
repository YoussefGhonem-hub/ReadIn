import { Page, expect, test } from '@playwright/test';
import { readFile } from 'node:fs/promises';
import { VARIANTS, hasScreenshot, parkMouse, problem, reply, useVariant } from './support/mock-api';
import { expectSignInPrompt, openArticle, signInAsReader } from './support/social';

/**
 * Download article PDF (F33) for every member (user decision 2026-11-06), against the mock API (e2e/mock-api/pdf.mjs):
 * a signed-in reader who didn't write the article finds "Download PDF" in the reader's "⋯" menu, right before Report,
 * and gets the published version on screen as `{slug}-{lang}.pdf`; a guest sees the item too and gets the sign-in
 * prompt, with no request; an article the API won't print for them (archived, hidden: `404`) says it isn't found.
 * Your own article's flow (building state, errors, My articles) is e2e/article-pdf.e2e.ts.
 */
test.describe.configure({ timeout: 120_000 });

const TEXTS = {
  ar: { download: 'تنزيل PDF', notFound: 'المقال غير موجود.' },
  en: { download: 'Download PDF', notFound: 'Article not found.' },
} as const;

const PDF_URL = /\/api\/v1\/articles\/[^/]+\/pdf(\?.*)?$/;
const ARTICLE = '/en/a/clean-architecture-whiteboard';
const FIRST_RENDER_MS = 30_000;

function countPdfRequests(page: Page): () => number {
  let count = 0;
  page.on('request', (r) => {
    if (r.method() === 'GET' && PDF_URL.test(r.url())) count++;
  });
  return () => count;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const t = TEXTS[lang];

  test(`Reader: a member who didn't write the article downloads its PDF from "⋯" — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openArticle(page, ARTICLE);

    const panel = page.locator('[data-article-menu-panel]');
    const item = panel.locator('[data-menu-action="downloadPdf"]');
    await page.locator('rd-article-action-bar [data-article-menu]').click();
    // Show less, Hide highlights, Follow, Mute author, Mute topics, Download PDF, then Report last.
    await expect(panel.locator('[data-menu-action]')).toHaveCount(7);
    await expect(panel.locator('[data-menu-action]').nth(5)).toHaveAttribute('data-menu-action', 'downloadPdf');
    await expect(panel.locator('[data-menu-action]').last()).toHaveAttribute('data-menu-action', 'report');
    await expect(item).toHaveText(t.download);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(panel).toHaveScreenshot(`pdf-menu-member-${lang}-${theme}.png`);

    const requests = countPdfRequests(page);
    const [download] = await Promise.all([page.waitForEvent('download'), item.click()]);
    expect(download.suggestedFilename()).toBe('clean-architecture-whiteboard-en.pdf');
    const bytes = await readFile((await download.path())!);
    expect(bytes.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(requests()).toBe(1);
    await expect(page.locator('rd-toast-host [data-toast-action]')).toHaveCount(0);
  });

  test(`Reader: guests see Download PDF and get the sign-in prompt, with no request — ${lang}/${theme}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const requests = countPdfRequests(page);
    await page.goto(ARTICLE);
    const bar = page.locator('rd-article-action-bar');
    await expect(bar.locator('[data-react]')).toBeVisible({ timeout: FIRST_RENDER_MS });

    await bar.locator('[data-article-menu]').click();
    const item = page.locator('[data-article-menu-panel] [data-menu-action="downloadPdf"]');
    await expect(item).toHaveText(t.download);
    await item.click();
    await expectSignInPrompt(page);
    expect(requests()).toBe(0);
  });

  test(`Reader: an article the API won't print for you (404) says it isn't found, with no retry — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openArticle(page, ARTICLE);
    // E.g. archived or hidden by moderators since the page loaded: the API answers 404 to anyone but the writer.
    await page.route(PDF_URL, (route) => reply(route, 404, problem(404, 'article.not_found')));

    await page.locator('rd-article-action-bar [data-article-menu]').click();
    await page.locator('[data-article-menu-panel] [data-menu-action="downloadPdf"]').click();
    const toast = page.locator('rd-toast-host > div', { hasText: t.notFound });
    await expect(toast).toBeVisible();
    await expect(toast.locator('[data-toast-action]')).toHaveCount(0);
  });
}
