import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, VARIANTS, fixture, hasScreenshot, imagesLoaded, multipartField, onApi, parkMouse, reply, useVariant } from './support/mock-api';
import { editorReady, signInAsAuthor } from './support/editor';

/* eslint-disable @typescript-eslint/no-explicit-any -- DTOs come from the mock API as plain JSON */

/**
 * PDF attachment download (F26, pre-production step G), in ar/light and en/dark: "Allow download" starts on for a new
 * PDF (and is sent with the upload); a download icon in the PDF's title strip on the post card and the "Download" button
 * of the full-screen viewer save the original for real, from `GET /documents/{assetId}/download` (the mock answers
 * `Content-Disposition: attachment` with a real one-page PDF); with downloads off there is neither.
 */
test.describe.configure({ timeout: 120_000 });

const FIRST_RENDER_MS = 30_000;

/** Home through the router (a server-rendered "/" would reuse the SSR answer, which `page.route` can't change). */
async function feedWith(page: Page, item: any): Promise<void> {
  await onApi(page, 'GET', new RegExp(`${API}/feed/for-you`), (route) => reply(route, 200, { items: [item], nextCursor: null }));
  await page.goto('/settings');
  await page.locator('rd-top-bar a[href="/"]:visible').first().click();
  await page.waitForURL((url) => url.pathname === '/');
}

/** The feed's PDF post, with the download settings given. */
async function documentPost(request: Parameters<typeof fixture>[0], patch: Record<string, unknown>): Promise<any> {
  const feed = await fixture<any>(request, '/api/v1/feed/for-you');
  const item = feed.items.find((a: any) => a.attachments?.kind === 'document');
  item.attachments.document = { ...item.attachments.document, ...patch };
  return item;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`PDF download: the title strip's icon and the viewer save the file — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-04T09:00:00Z'));
    const item = await documentPost(request, { allowDownload: true, canDownload: true });
    const downloads: string[] = [];
    page.on('request', (r) => {
      if (r.method() === 'GET' && /\/documents\/[^/]+\/download$/.test(new URL(r.url()).pathname)) downloads.push(new URL(r.url()).pathname);
    });
    await feedWith(page, item);

    const card = page.locator('rd-post-card').filter({ has: page.locator('[data-attachments="document"]') });
    const strip = card.locator('[data-document-header]');
    const icon = strip.locator('[data-document-download]');
    await expect(icon).toBeVisible({ timeout: FIRST_RENDER_MS });
    // A named button: "Download {title}".
    await expect(icon).toHaveAttribute('aria-label', new RegExp(`${ar ? 'تنزيل' : 'Download'} .*ASP\\.NET Core cheat sheet`));
    await card.scrollIntoViewIfNeeded();
    await parkMouse(page);
    await imagesLoaded(card);
    if (hasScreenshot(variant)) await expect(strip).toHaveScreenshot(`pdf-strip-download-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // The card's icon saves the original under the document's title.
    const [fromCard] = await Promise.all([page.waitForEvent('download'), icon.click()]);
    expect(fromCard.suggestedFilename()).toBe('ASP.NET Core cheat sheet.pdf');
    expect((await readFile((await fromCard.path())!)).subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(downloads).toEqual([`/api/v1/documents/${item.attachments.document.assetId}/download`]);
    await expect(icon).toBeEnabled();

    // The full-screen viewer's Download does too.
    await card.locator('[data-slide] > button').first().click();
    const viewer = page.locator('rd-media-viewer');
    await expect(viewer).toBeVisible();
    const button = viewer.locator('[data-viewer-download]');
    await expect(button).toBeVisible();
    const [fromViewer] = await Promise.all([page.waitForEvent('download'), button.click()]);
    expect(fromViewer.suggestedFilename()).toBe('ASP.NET Core cheat sheet.pdf');
    expect((await readFile((await fromViewer.path())!)).subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(downloads).toHaveLength(2);
    await viewer.locator('[data-viewer-close]').click();
    await expect(viewer).toHaveCount(0);
  });
}

test('PDF download: off for this reader, so neither the strip nor the viewer offers it (en/dark)', async ({ page, context, baseURL, request }) => {
  await useVariant(context, baseURL!, VARIANTS[1]);
  await feedWith(page, await documentPost(request, { allowDownload: false, canDownload: false }));
  const card = page.locator('rd-post-card').filter({ has: page.locator('[data-attachments="document"]') });
  await expect(card.locator('[data-document-header]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  await expect(card.locator('[data-document-download]')).toHaveCount(0);
  await card.locator('[data-slide] > button').first().click();
  await expect(page.locator('rd-media-viewer [data-viewer-share]')).toBeVisible();
  await expect(page.locator('rd-media-viewer [data-viewer-download]')).toHaveCount(0);
});

test('the owner of a PDF can download it even with downloads off (canDownload) (ar/light)', async ({ page, context, baseURL, request }) => {
  await useVariant(context, baseURL!, VARIANTS[0]);
  await feedWith(page, await documentPost(request, { allowDownload: false, canDownload: true }));
  const card = page.locator('rd-post-card').filter({ has: page.locator('[data-attachments="document"]') });
  const [file] = await Promise.all([page.waitForEvent('download'), card.locator('[data-document-download]').click({ timeout: FIRST_RENDER_MS })]);
  expect(file.suggestedFilename()).toBe('ASP.NET Core cheat sheet.pdf');
});

test('composer: "Allow download" starts on for a new PDF and is sent with the upload; the writer can turn it off (en/dark)', async ({ page, context, baseURL, request }) => {
  const variant = VARIANTS[1];
  await useVariant(context, baseURL!, variant);
  await signInAsAuthor(page, request, variant, 'fresh');
  const assetId = `asset-dl-${randomUUID()}`;
  const accepted = await fixture<any>(request, `/__mock/asset/document?seed=dl&id=${assetId}&pages=3&ready=0&status=processing&title=Slides`);
  const ready = await fixture<any>(request, `/__mock/asset/document?seed=dl&id=${assetId}&pages=3&ready=3&status=ready&title=Slides&allowDownload=true`);
  let allowDownload: string | null = null;
  await onApi(page, 'POST', '/uploads/documents', (route) => {
    allowDownload = multipartField(route, 'allowDownload');
    return reply(route, 202, accepted);
  });
  await onApi(page, 'GET', `/uploads/${assetId}`, (route) => reply(route, 200, ready));

  await page.goto('/write/new');
  await editorReady(page);
  await page
    .locator('[data-pdf-input]')
    .setInputFiles({ name: 'Slides.pdf', mimeType: 'application/pdf', buffer: Buffer.from('%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n') });
  const toggle = page.locator('[data-allow-download]');
  await expect(toggle).toBeChecked();
  await expect.poll(() => allowDownload).toBe('true');
  await toggle.uncheck();
  await expect(toggle).not.toBeChecked();
});
