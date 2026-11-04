import { expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, VARIANTS, fixture, hasScreenshot, imagesLoaded, onApi, parkMouse, pngFile, reply, signInAsWriter, uploadedFileName, useVariant } from './support/mock-api';
import { editorReady, publish, trackSavedDocument, typeInEditor } from './support/editor';

/* eslint-disable @typescript-eslint/no-explicit-any -- DTOs come from the mock API as plain JSON */

/**
 * F26 images, end to end (ar/en × light/dark): write an article with 3 images (client-side compression, upload,
 * alt text, caption) in the editor (F05) → publish → the article → the feed card carousel → the full-screen viewer
 * (keys, Back closes).
 */
// Full flows (sign-in, client-side compression, uploads, autosave, three screenshots) run in parallel with the other suites.
test.describe.configure({ timeout: 120_000 });

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;

  test(`post with 3 images → feed carousel → viewer — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);

    // Uploads answer by file name, so the result doesn't depend on which parallel upload finishes first. Fetching the
    // fixtures also tells the mock API about the assets, so the draft and the article can list them.
    const assets: Record<string, any> = {
      'workshop-1.png': await fixture(request, '/__mock/asset/image?seed=workshop-1&w=1600&h=1200'),
      'workshop-2.png': await fixture(request, '/__mock/asset/image?seed=workshop-2&w=1200&h=1600'),
      'workshop-3.png': await fixture(request, '/__mock/asset/image?seed=workshop-3&w=1600&h=1000'),
    };
    const uploaded: string[] = [];
    await onApi(page, 'POST', '/uploads/images', (route) => {
      const name = uploadedFileName(route)!;
      uploaded.push(name);
      return reply(route, 201, assets[name]);
    });
    const savedDocument = trackSavedDocument(page);
    await onApi(page, 'GET', `/feed/today`, (route) => reply(route, 204));

    await signInAsWriter(page, request, variant, '/write/new');
    await editorReady(page);

    // ── Editor ──
    await expect(page.locator('html')).toHaveAttribute('dir', dir);
    await page.locator('[data-field]').selectOption('f-software');
    await page.locator('[data-title]').fill('Three photos from the workshop');
    await typeInEditor(page, 'We sketched the whole system on a whiteboard.');
    await page.keyboard.press('Enter');
    await page.keyboard.type('The second photo shows the dependency rule.');
    await page
      .locator('[data-image-input]')
      .setInputFiles([await pngFile(request, 'workshop-1.png', 2400, 1800), await pngFile(request, 'workshop-2.png', 1200, 1600), await pngFile(request, 'workshop-3.png', 1600, 1000)]);
    await expect(page.locator('[data-image-item]')).toHaveCount(3);
    await expect(page.locator('[data-image-item] [data-status]')).toHaveCount(0, { timeout: 20_000 }); // all uploaded
    expect([...uploaded].sort()).toEqual(['workshop-1.png', 'workshop-2.png', 'workshop-3.png']);

    // A PDF can't be mixed in, and Publish waits for alt text on every image.
    await expect(page.locator('[data-add-pdf]')).toBeDisabled();
    await expect(page.locator('[data-publish]')).toBeDisabled();
    const alts = page.locator('[data-alt]');
    await alts.nth(0).fill('Whiteboard with the four layers');
    await alts.nth(1).fill('Arrows pointing inwards');
    await expect(page.locator('[data-publish]')).toBeDisabled();
    await alts.nth(2).fill('Use case flow');
    await page.locator('[data-caption]').first().fill('The four layers, outside in');
    await expect(page.locator('[data-publish]')).toBeEnabled({ timeout: 25_000 });

    await page.locator('[data-title]').focus(); // no focus ring on the cards
    await parkMouse(page);
    await imagesLoaded(page.locator('[data-image-list]'));
    if (hasScreenshot(variant)) await expect(page.locator('#ed-attachments')).toHaveScreenshot(`editor-images-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // ── Publish → article ──
    const result = await publish(page);
    await page.waitForURL((url) => url.pathname === `/en/a/${result.slug}`);
    const document = savedDocument();
    expect(document).toMatchObject({ fieldId: 'f-software', isAiAssisted: false });
    expect(document.translations[0].title).toBe('Three photos from the workshop');
    expect(document.translations[0].content.blocks.map((b: any) => b.type)).toEqual(['paragraph', 'paragraph']);
    expect(document.attachments.map((i: any) => [i.mediaAssetId, i.order, i.altText])).toEqual([
      ['asset-workshop-1', 0, 'Whiteboard with the four layers'],
      ['asset-workshop-2', 1, 'Arrows pointing inwards'],
      ['asset-workshop-3', 2, 'Use case flow'],
    ]);
    await expect(page.locator('rd-article-page rd-media-carousel [data-counter]')).toHaveText('1 / 3');

    // ── Feed card carousel: the published article (as the mock serves it) on a known card, as the feed shows it ──
    const base = await fixture<any>(request, '/api/v1/articles/clean-architecture-whiteboard');
    const written = await fixture<any>(request, `/api/v1/articles/${result.slug}?lang=en`);
    const card = { ...base, id: written.id, slug: written.slug, language: written.language, title: written.title, attachments: written.attachments };
    await onApi(page, 'GET', new RegExp(`${API}/feed/for-you`), (route) => reply(route, 200, { items: [card], nextCursor: null }));
    await page.locator('rd-article-page a[href="/"]').first().click();
    await page.waitForURL((url) => url.pathname === '/');
    const feedCard = page.locator('rd-article-card').filter({ has: page.locator('[data-attachments="images"]') });
    await expect(feedCard.locator('[data-counter]')).toHaveText('1 / 3');
    await expect(feedCard.locator('[data-slide]')).toHaveCount(3);
    await expect(feedCard.locator('[data-slide]').first()).toHaveAttribute('aria-label', lang === 'ar' ? 'صورة 1 من 3' : 'Image 1 of 3');
    await feedCard.scrollIntoViewIfNeeded();
    await parkMouse(page);
    await imagesLoaded(feedCard);
    if (hasScreenshot(variant)) await expect(feedCard).toHaveScreenshot(`feed-card-images-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // ── Full-screen viewer ──
    await feedCard.locator('[data-slide] > button').first().click();
    const viewer = page.locator('rd-media-viewer');
    await expect(viewer).toBeVisible();
    await expect(page.getByRole('dialog')).toBeVisible();
    await expect(viewer.locator('[data-viewer-counter]')).toHaveText('1 / 3');
    await expect(viewer.locator('[data-viewer-download]')).toHaveCount(0); // images have no download
    await imagesLoaded(viewer.locator('[data-viewer-current]'));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`viewer-images-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // Arrow keys follow the reading direction.
    await page.keyboard.press(dir === 'rtl' ? 'ArrowLeft' : 'ArrowRight');
    await expect(viewer.locator('[data-viewer-counter]')).toHaveText('2 / 3');
    await expect(viewer.locator('[aria-live="polite"]').first()).toHaveText(lang === 'ar' ? 'صورة 2 من 3' : 'Image 2 of 3');

    // Browser Back closes the viewer and stays on the feed; focus returns to the slide.
    await page.goBack();
    await expect(viewer).toHaveCount(0);
    expect(new URL(page.url()).pathname).toBe('/');
    await expect(feedCard.locator('[data-slide] > button').first()).toBeFocused();

    // Escape closes it too.
    await feedCard.locator('[data-slide] > button').first().click();
    await expect(viewer).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(viewer).toHaveCount(0);
    expect(new URL(page.url()).pathname).toBe('/');
  });
}
