/* eslint-disable @typescript-eslint/no-explicit-any -- DTOs come from the mock API as plain JSON */
import { APIRequestContext, Locator, Page, Route, expect, test } from '@playwright/test';
import { API, MockMe, VARIANTS, hasScreenshot, parkMouse, problem, reply, restoreSessionAs, sessionFor, useVariant, writerMe } from './support/mock-api';
import { myArticle, seededIds, signInAsAuthor } from './support/editor';
import { openArticle, signInAsReader } from './support/social';

/**
 * Download article PDF (F33) in My articles → Published, against the mock API (e2e/mock-api/pdf.mjs): only published
 * rows have it; one version downloads at once under the server's file name (`{slug}-{lang}.pdf`, RFC 5987, Arabic
 * too); two versions ask "أنهي نسخة؟" first; while the file is built the button says "بنجهز الـ PDF…" and is disabled;
 * each error has its message, with "حاول تاني" where trying again helps. In the reader, the "⋯" menu (F28) has the
 * same action on your own article only, for the version on screen.
 */
test.describe.configure({ timeout: 120_000 });

const TEXTS = {
  ar: {
    download: 'تحميل PDF',
    building: 'بنجهز الـ PDF…',
    question: 'أنهي نسخة؟',
    versions: ['العربي', 'الإنجليزي'],
    retry: 'حاول تاني',
    close: 'إغلاق',
    notFound: 'المقال مش موجود.',
    hidden: 'المشرفين خفّوا المقال ده، فمينفعش يتحمّل PDF.',
    limit: 'حمّلت PDFs كتير الساعة دي. حاول تاني بعد شوية.',
    busy: 'فيه PDFs كتير بتتجهز دلوقتي. حاول تاني كمان شوية.',
    failed: 'معرفناش نجهّز الـ PDF. حاول تاني.',
    offline: 'محتاج إنترنت عشان تحمّل الـ PDF.',
  },
  en: {
    download: 'Download PDF',
    building: 'Preparing the PDF…',
    question: 'Which version?',
    versions: ['Arabic', 'English'],
    retry: 'Try again',
    close: 'Close',
    notFound: 'Article not found.',
    hidden: "Moderators hid this article, so it can't be downloaded as a PDF.",
    limit: "You've downloaded many PDFs this hour. Try again later.",
    busy: 'Many PDFs are being prepared right now. Try again in a moment.',
    failed: "We couldn't prepare the PDF. Try again.",
    offline: 'You need an internet connection to download the PDF.',
  },
} as const;

const PDF_URL = /\/api\/v1\/articles\/[^/]+\/pdf(\?.*)?$/;

/** The writer's own call to the mock API (their articles are kept per bearer token). */
function asWriter(request: APIRequestContext, me: MockMe) {
  const headers = { authorization: `Bearer ${sessionFor(me).accessToken}` };
  return {
    get: async (path: string) => (await request.get(`${API}${path}`, { headers })).json(),
    post: async (path: string, data: unknown) => {
      const response = await request.post(`${API}${path}`, { headers, data });
      expect(response.ok(), path).toBe(true);
      return response.json();
    },
  };
}

/** Publishes an article with an Arabic (source) and an English version through the mock editor API. */
async function publishTwoVersions(request: APIRequestContext, me: MockMe): Promise<{ id: string; slug: string }> {
  const api = asWriter(request, me);
  const version = (language: 'ar-EG' | 'en', title: string, text: string) => ({
    language,
    title,
    subtitle: null,
    content: { version: 1, language, blocks: [{ id: 'p1', type: 'paragraph', content: [{ type: 'text', text }] }] },
  });
  const created = await api.post('/articles', {
    sourceLanguage: 'ar-EG',
    translations: [version('ar-EG', 'مقال بنسختين: عربي وEnglish', 'المقال ده منشور بلغتين.'), version('en', 'An article in two versions', 'This article is published in two languages.')],
    fieldId: 'f-software',
    topicId: null,
    tags: [],
    sources: [],
    coverUrl: null,
    versionBadge: null,
    isAiAssisted: false,
    attachments: [],
  });
  const published = await api.post(`/articles/${created.id}/publish`, { baseVersion: created.version });
  return { id: created.id, slug: published.slug };
}

/** GET requests for article PDFs the page sent. */
function countPdfRequests(page: Page): () => number {
  let count = 0;
  page.on('request', (r) => {
    if (r.method() === 'GET' && PDF_URL.test(r.url())) count++;
  });
  return () => count;
}

/** Clicks and resolves with the file name the browser saves the download under. */
async function downloadName(page: Page, trigger: Locator): Promise<string> {
  const [file] = await Promise.all([page.waitForEvent('download'), trigger.click()]);
  return file.suggestedFilename();
}

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const t = TEXTS[lang];

  test(`My articles: Download PDF on published articles, one version at once, "building" while it is made — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const ids = seededIds(me);
    await page.clock.setFixedTime(new Date('2026-11-03T12:00:00Z'));

    // Drafts have no PDF.
    await page.goto('/write');
    await expect(page.locator('html')).toHaveAttribute('dir', dir);
    await expect(page.locator('[data-my-article]')).toHaveCount(2);
    await expect(page.locator('[data-pdf-download]')).toHaveCount(0);

    // Every published article has it; each of these has one version (the mock sends publishedLanguages).
    await page.locator('[data-my-tab="published"]').click();
    await expect(page.locator('[data-my-article]')).toHaveCount(2);
    await expect(page.locator('[data-pdf-download]')).toHaveCount(2);
    const mine = await asWriter(request, me).get('/me/articles?status=published');
    const arabic = mine.items.find((a: any) => a.id === ids.published);
    const english = mine.items.find((a: any) => a.id === ids.changed);
    expect(arabic.publishedLanguages).toEqual(['ar-EG']);
    expect(english.publishedLanguages).toEqual(['en']);

    // Hold the build, to see the button while it runs.
    let release!: () => void;
    const held = new Promise<void>((resolve) => (release = resolve));
    await page.route(PDF_URL, async (route) => {
      if (route.request().method() === 'GET') await held;
      await route.fallback();
    });
    const requests = countPdfRequests(page);
    const row = myArticle(page, ids.published);
    const button = row.locator('[data-pdf-download]');
    await expect(button).toHaveText(t.download);
    const download = page.waitForEvent('download');
    await button.click();
    await expect(button).toHaveAttribute('data-state', 'building');
    await expect(button).toHaveText(t.building);
    await expect(button).toBeDisabled();
    await expect(page.locator('[data-pdf-languages]')).toHaveCount(0); // one version: no question
    await button.click({ force: true }); // a second tap does nothing
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(row).toHaveScreenshot(`pdf-building-${lang}-${theme}.png`);
    release();

    // The server's name: {slug}-{lang}.pdf, for the source language.
    expect((await download).suggestedFilename()).toBe(`${arabic.slug}-ar-EG.pdf`);
    await expect(button).toHaveAttribute('data-state', 'idle');
    await expect(button).toHaveText(t.download);
    expect(requests()).toBe(1);
    await page.unroute(PDF_URL);

    // The English article prints its English version.
    expect(await downloadName(page, myArticle(page, ids.changed).locator('[data-pdf-download]'))).toBe(`${english.slug}-en.pdf`);
  });

  test(`My articles: two versions ask which first, then download the one picked — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant, 'fresh');
    const article = await publishTwoVersions(request, me);
    await page.goto('/write?tab=published');
    const button = myArticle(page, article.id).locator('[data-pdf-download]');
    await expect(button).toBeVisible();
    const requests = countPdfRequests(page);

    await button.click();
    const sheet = page.locator('[data-pdf-languages]');
    await expect(sheet).toBeVisible();
    const dialog = page.getByRole('dialog', { name: t.question });
    await expect(dialog).toBeVisible();
    // Source language first, then the other, in the UI's language.
    await expect(sheet.locator('[data-pdf-language]')).toHaveText([...t.versions]);
    await expect(sheet.locator('[data-pdf-language]').first()).toHaveAttribute('data-pdf-language', 'ar-EG');
    await expect(sheet.locator('[data-pdf-language]').first()).toBeFocused();
    expect(requests()).toBe(0);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(dialog).toHaveScreenshot(`pdf-language-question-${lang}-${theme}.png`);

    // Escape closes it without a download, and gives focus back to the button.
    await page.keyboard.press('Escape');
    await expect(sheet).toHaveCount(0);
    await expect(button).toBeFocused();
    expect(requests()).toBe(0);

    // The English version, then the Arabic one (from the keyboard).
    await button.click();
    expect(await downloadName(page, sheet.locator('[data-pdf-language="en"]'))).toBe(`${article.slug}-en.pdf`);
    await expect(sheet).toHaveCount(0);
    await expect(button).toHaveAttribute('data-state', 'idle');
    await button.focus();
    await page.keyboard.press('Enter');
    await expect(sheet.locator('[data-pdf-language="ar-EG"]')).toBeFocused();
    const [file] = await Promise.all([page.waitForEvent('download'), page.keyboard.press('Enter')]);
    expect(file.suggestedFilename()).toBe(`${article.slug}-ar-EG.pdf`);
    expect(requests()).toBe(2);
  });

  test(`My articles: PDF errors, with "${t.retry}" where it helps, and offline — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const ids = seededIds(me);
    await page.goto('/write?tab=published');
    const button = myArticle(page, ids.published).locator('[data-pdf-download]');
    await expect(button).toBeVisible();

    // The next PDF call answers this, then the mock answers again.
    let next: ((route: Route) => Promise<void>) | null = null;
    await page.route(PDF_URL, async (route) => {
      const answer = next;
      if (route.request().method() !== 'GET' || !answer) return route.fallback();
      next = null;
      return answer(route);
    });
    const toast = (text: string) => page.locator('rd-toast-host > div', { hasText: text });
    const failWith = async (status: number, code: string, message: string, retry: boolean) => {
      next = (route) => reply(route, status, problem(status, code));
      await button.click();
      await expect(toast(message)).toBeVisible();
      await expect(toast(message).locator('[data-toast-action]')).toHaveCount(retry ? 1 : 0);
      if (retry) await expect(toast(message).locator('[data-toast-action]')).toHaveText(t.retry);
      await expect(button).toHaveAttribute('data-state', 'idle');
      await toast(message).getByRole('button', { name: t.close }).click();
      await expect(toast(message)).toHaveCount(0);
    };

    await failWith(404, 'article.not_found', t.notFound, false);
    await failWith(409, 'article.pdf_hidden', t.hidden, false);
    await failWith(429, 'article.pdf_limit', t.limit, true);
    await failWith(500, 'article.pdf_failed', t.failed, true);
    await failWith(500, 'server.error', t.failed, true);

    // Busy, then "Try again" downloads it.
    next = (route) => reply(route, 503, problem(503, 'article.pdf_busy'));
    await button.click();
    await expect(toast(t.busy).locator('[data-toast-action]')).toHaveText(t.retry);
    const [file] = await Promise.all([page.waitForEvent('download'), toast(t.busy).locator('[data-toast-action]').click()]);
    expect(file.suggestedFilename()).toMatch(/-ar-EG\.pdf$/);
    await expect(toast(t.busy)).toHaveCount(0);

    // The connection drops during the call.
    next = (route) => route.abort('internetdisconnected');
    await button.click();
    await expect(toast(t.offline).locator('[data-toast-action]')).toHaveText(t.retry);
    await toast(t.offline).getByRole('button', { name: t.close }).click();

    // Offline before the call: no request at all; back online, "Try again" works.
    const requests = countPdfRequests(page);
    await context.setOffline(true);
    await button.click();
    await expect(toast(t.offline).locator('[data-toast-action]')).toHaveText(t.retry);
    expect(requests()).toBe(0);
    await context.setOffline(false);
    const [again] = await Promise.all([page.waitForEvent('download'), toast(t.offline).locator('[data-toast-action]').click()]);
    expect(again.suggestedFilename()).toMatch(/-ar-EG\.pdf$/);
    expect(requests()).toBe(1);
  });

  test(`Reader: "⋯" → Download PDF on your own article only, for the version on screen — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // The writer of the reader fixture (the mock's /me), on their own article.
    await restoreSessionAs(page, await writerMe(request, variant));
    await openArticle(page, '/en/a/clean-architecture-whiteboard');
    const menuButton = page.locator('rd-article-action-bar [data-article-menu]');
    const panel = page.locator('[data-article-menu-panel]');
    const item = panel.locator('[data-menu-action="downloadPdf"]');
    await menuButton.click();
    await expect(panel.locator('[data-menu-action]')).toHaveCount(2);
    await expect(panel.locator('[data-menu-action]').last()).toHaveAttribute('data-menu-action', 'downloadPdf');
    await expect(item).toHaveText(t.download);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(panel).toHaveScreenshot(`pdf-menu-${lang}-${theme}.png`);

    // Hold the build: the item says so and is disabled; a second press asks for nothing more.
    let release!: () => void;
    const held = new Promise<void>((resolve) => (release = resolve));
    await page.route(PDF_URL, async (route) => {
      if (route.request().method() === 'GET') await held;
      await route.fallback();
    });
    const requests = countPdfRequests(page);
    const download = page.waitForEvent('download');
    await item.click();
    await expect(panel).toHaveCount(0);
    await menuButton.click();
    await expect(item).toHaveText(t.building);
    await expect(item).toHaveAttribute('aria-disabled', 'true');
    await item.click({ force: true });
    release();
    expect((await download).suggestedFilename()).toBe('clean-architecture-whiteboard-en.pdf');
    expect(requests()).toBe(1);
    await page.unroute(PDF_URL);

    // Someone else reading it: no Download PDF.
    await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/clean-architecture-whiteboard');
    await menuButton.click();
    await expect(panel.locator('[data-menu-action="report"]')).toBeVisible();
    await expect(item).toHaveCount(0);
  });
}

test('the file name comes from filename* (RFC 5987), so an Arabic slug stays Arabic', async ({ page, context, baseURL, request }) => {
  await useVariant(context, baseURL!, VARIANTS[0]); // ar/light
  const me = await signInAsAuthor(page, request, VARIANTS[0]);
  const ids = seededIds(me);
  const name = 'إزاي-تكتب-unit-tests-مفيدة-ar-EG.pdf';
  await page.route(PDF_URL, async (route) => {
    if (route.request().method() !== 'GET') return route.fallback();
    const response = await route.fetch();
    await route.fulfill({
      response,
      headers: {
        ...response.headers(),
        'content-disposition': `attachment; filename="readin-article.pdf"; filename*=UTF-8''${encodeURIComponent(name)}`,
      },
    });
  });
  await page.goto('/write?tab=published');
  expect(await downloadName(page, myArticle(page, ids.published).locator('[data-pdf-download]'))).toBe(name);
});
