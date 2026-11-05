import { randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import {
  API,
  HIDE_APP_CHROME,
  VARIANTS,
  fixture,
  hasScreenshot,
  imagesLoaded,
  multipartField,
  onApi,
  parkMouse,
  reply,
  sessionFor,
  signInAsWriter,
  useVariant,
  writerMe,
} from './support/mock-api';
import { editorReady, publish, trackSavedDocument, typeInEditor } from './support/editor';

/* eslint-disable @typescript-eslint/no-explicit-any -- DTOs come from the mock API as plain JSON */

const PAGE_COUNT = 12;
/** A minimal PDF: the client only checks type and size; pages are counted and rendered by the server. */
const PDF_BYTES = Buffer.from('%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n');

/**
 * F26 PDF, end to end (ar/en × light/dark): upload a PDF in the editor (F05) → "Preparing pages…" while
 * `GET /uploads/{id}` polls → preview → publish → the feed card page carousel (+N pages card) → the document viewer.
 * The author turns "Allow download" off (it starts on), yet still gets the download icon on the strip and Download in the
 * viewer: like the API, the owner can always download (other readers can't; pdf-download.e2e.ts downloads).
 */
// Full flows (sign-in, client-side compression, uploads, three screenshots) run in parallel with the other suites.
test.describe.configure({ timeout: 120_000 });

for (const variant of VARIANTS) {
  const { lang, theme } = variant;

  test(`post with a PDF → processing → page carousel → viewer (the owner's download) — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // The same pictures in every run, but an asset id of its own: the mock API keeps the latest state of each asset, and a
    // run in parallel registering "processing" must not turn this run's ready asset back (attachments.asset_not_ready).
    const assetId = `asset-k8s-${randomUUID()}`;
    const doc = (query: string) =>
      fixture<any>(request, `/__mock/asset/document?seed=k8s&id=${assetId}&pages=${PAGE_COUNT}&title=Kubernetes%20basics&${query}`);
    const accepted = await doc('ready=0&status=processing');
    const pollStates = [await doc('ready=3&status=processing'), await doc('ready=12&status=ready')];

    let uploadFields: Record<string, string | null> = {};
    await onApi(page, 'POST', '/uploads/documents', (route) => {
      uploadFields = { title: multipartField(route, 'title'), allowDownload: multipartField(route, 'allowDownload') };
      return reply(route, 202, accepted);
    });
    let polls = 0;
    await onApi(page, 'GET', `/uploads/${accepted.id}`, (route) => reply(route, 200, pollStates[Math.min(polls++, pollStates.length - 1)]));

    const savedDocument = trackSavedDocument(page);
    const ready = pollStates[1];
    let articleFetches = 0;
    page.on('request', (r) => {
      if (r.method() === 'GET' && /\/articles\/kubernetes-basics[^/?]*\?/.test(r.url())) articleFetches++;
    });
    await onApi(page, 'GET', '/feed/today', (route) => reply(route, 204));

    await signInAsWriter(page, request, variant, '/write/new');
    await editorReady(page);

    // ── Editor: upload + processing ──
    await page.locator('[data-field]').selectOption('f-software');
    await page.locator('[data-title]').fill('Kubernetes basics in 12 slides');
    await typeInEditor(page, 'My slides from the meetup.');
    await page.locator('[data-pdf-input]').setInputFiles({ name: 'Kubernetes_basics.pdf', mimeType: 'application/pdf', buffer: PDF_BYTES });

    await expect(page.locator('[data-doc-title]')).toHaveValue('Kubernetes basics'); // from the file name
    // The file's size in the UI language ("1 كيلو"), its name as it is.
    await expect(page.locator('[data-doc-size]')).toHaveText(lang === 'ar' ? /^Kubernetes_basics\.pdf · \d+ كيلو$/ : /^Kubernetes_basics\.pdf · \d+ KB$/);
    // "Allow download" starts on (pre-production step G) and is sent with the upload; this writer turns it off.
    await expect(page.locator('[data-allow-download]')).toBeChecked();
    await expect(page.locator('[data-processing]')).toHaveText(lang === 'ar' ? 'بنجهز الصفحات…' : 'Preparing pages…');
    await expect(page.locator('[data-publish]')).toBeDisabled();
    await expect(page.locator('[data-add-images]')).toBeDisabled(); // no mixing
    expect(uploadFields).toEqual({ title: 'Kubernetes basics', allowDownload: 'true' });
    await page.locator('[data-allow-download]').uncheck();
    await expect(page.locator('[data-allow-download]')).not.toBeChecked();

    await expect(page.locator('[data-doc-preview] li')).toHaveCount(3); // first poll: 3 pages ready
    await expect(page.locator('[data-document]')).toHaveAttribute('data-status', 'ready', { timeout: 10_000 });
    await expect(page.locator('[data-doc-preview] li')).toHaveCount(4); // preview of the first pages
    await expect(page.locator('[data-publish]')).toBeEnabled({ timeout: 25_000 });
    expect(polls).toBe(2); // polling stops once ready

    await page.locator('[data-title]').focus();
    await parkMouse(page);
    await imagesLoaded(page.locator('[data-doc-preview]'));
    if (hasScreenshot(variant)) await expect(page.locator('#ed-attachments')).toHaveScreenshot(`editor-pdf-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // ── Publish ──
    const result = await publish(page);
    await page.waitForURL((url) => url.pathname.endsWith(`/a/${result.slug}`));
    expect(savedDocument().attachments).toEqual([{ mediaAssetId: ready.id, order: 0, title: 'Kubernetes basics', allowDownload: false }]);

    // The published article as its writer gets it, on a known card; feed cards carry at most the first 10 pages.
    // "Allow download" is off, but the owner can always download (contract, Media → "Allow download"); a guest can't.
    const base = await fixture<any>(request, '/api/v1/articles/aspnet-core-cheatsheet');
    const asWriter = { authorization: `Bearer ${sessionFor(await writerMe(request, variant)).accessToken}` };
    const written = await (await request.get(`${API}/articles/${result.slug}?lang=en`, { headers: asWriter })).json();
    expect(written.attachments.document).toMatchObject({ allowDownload: false, canDownload: true });
    const asGuest = await fixture<any>(request, `/api/v1/articles/${result.slug}?lang=en`);
    expect(asGuest.attachments.document).toMatchObject({ allowDownload: false, canDownload: false });
    const feedItem = { ...base, id: written.id, slug: written.slug, language: written.language, title: written.title, attachments: written.attachments };
    feedItem.attachments.document = { ...feedItem.attachments.document, pages: feedItem.attachments.document.pages.slice(0, 10), downloadUrl: `${API}/documents/${ready.id}/download` };
    await onApi(page, 'GET', new RegExp(`${API}/feed/for-you`), (route) => reply(route, 200, { items: [feedItem], nextCursor: null }));

    // ── Feed card: header strip + page carousel + "+2 pages" ──
    // Home from the top bar (the reader's Back would return to the editor the article was published from). The post
    // card says how long ago the article was published: a fixed clock keeps the shot stable.
    await page.clock.setFixedTime(new Date('2026-11-04T09:00:00Z'));
    await page.locator('rd-top-bar [data-home-mark]').click();
    await page.waitForURL((url) => url.pathname === '/');
    const card = page.locator('rd-post-card').filter({ has: page.locator('[data-attachments="document"]') });
    await expect(card.locator('[data-document-header]')).toContainText('Kubernetes basics');
    await expect(card.locator('[data-document-header]')).toContainText(lang === 'ar' ? '12 صفحة' : '12 pages');
    await expect(card.locator('[data-counter]')).toHaveText(`1 / ${PAGE_COUNT}`);
    await expect(card.locator('[data-slide]')).toHaveCount(11);
    await expect(card.locator('[data-more]')).toHaveText(lang === 'ar' ? '+صفحتين، افتح الملف' : '+2 pages, open document');
    // The owner's download icon in the title strip.
    await expect(card.locator('[data-document-header] [data-document-download]')).toBeVisible();
    await card.scrollIntoViewIfNeeded();
    await parkMouse(page);
    await imagesLoaded(card);
    if (hasScreenshot(variant)) await expect(card).toHaveScreenshot(`feed-card-pdf-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // ── Document viewer ──
    const fetchesBefore = articleFetches;
    await card.locator('[data-slide] > button').first().click();
    const viewer = page.locator('rd-media-viewer');
    await expect(viewer).toBeVisible();
    await expect(viewer.locator('[data-viewer-counter]')).toHaveText(`1 / ${PAGE_COUNT}`);
    await expect(viewer.locator('[data-viewer-download]')).toBeVisible(); // the owner may always download
    await expect(viewer.locator('[data-viewer-share]')).toBeVisible();
    await expect(viewer.locator('[data-viewer-thumbnails] button')).toHaveCount(PAGE_COUNT); // pages 11–12 loaded on demand
    expect(articleFetches).toBe(fetchesBefore + 1);
    await expect(viewer.locator('[data-viewer-thumbnails] button').first()).toHaveAttribute('aria-current', 'true');
    await imagesLoaded(viewer.locator('[data-viewer-current]'));
    await imagesLoaded(viewer.locator('[data-viewer-thumbnails]'));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`viewer-pdf-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    await viewer.locator('[data-viewer-thumbnails] button').nth(11).click();
    await expect(viewer.locator('[data-viewer-counter]')).toHaveText(`12 / ${PAGE_COUNT}`);
    await expect(viewer.locator('[data-viewer-item="11"]')).toHaveAttribute('aria-label', lang === 'ar' ? 'صفحة 12 من 12' : 'Page 12 of 12');

    await viewer.locator('[data-viewer-close]').click();
    await expect(viewer).toHaveCount(0);
    expect(new URL(page.url()).pathname).toBe('/');
  });
}

test('the document viewer offers Download when allowed and saves the original under its title', async ({ page, context, baseURL, request }) => {
  await useVariant(context, baseURL!, VARIANTS[1]); // en/dark
  const feed = await fixture<any>(request, '/api/v1/feed/for-you');
  const item = feed.items.find((a: any) => a.attachments?.kind === 'document');
  item.attachments.document = { ...item.attachments.document, allowDownload: true, canDownload: true };
  await onApi(page, 'GET', new RegExp(`${API}/feed/for-you`), (route) => reply(route, 200, { items: [item], nextCursor: null }));

  // Client-side navigation, so the feed comes from the routed call (a server-rendered "/" reuses the SSR response).
  await page.goto('/settings');
  await page.locator('rd-top-bar [data-home-mark]').click();
  await page.waitForURL((url) => url.pathname === '/');
  const card = page.locator('rd-post-card').filter({ has: page.locator('[data-attachments="document"]') });
  await card.locator('[data-slide] > button').first().click();
  const download = page.locator('[data-viewer-download]');
  await expect(download).toBeVisible();
  const [file] = await Promise.all([page.waitForEvent('download'), download.click()]);
  expect(file.suggestedFilename()).toBe('ASP.NET Core cheat sheet.pdf');
});
