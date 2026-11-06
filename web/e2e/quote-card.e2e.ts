import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { APIRequestContext, Page, Request, Route, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, VARIANTS, Variant, hasScreenshot, onApi, parkMouse, problem, reply, sessionFor, useVariant, writerMe } from './support/mock-api';

/**
 * F24 Share quote end to end in ar/light and en/dark, against the mock API (e2e/mock-api/quote-card.mjs, which checks
 * the range like the API and answers a card-like PNG of the format's size): a real mouse selection in the "Highlights
 * lab" article offers **Share quote** next to Highlight; it opens the dialog with the card drawn in the app's theme,
 * square; Light/Dark and Square/Landscape each ask for their card once (switching back asks nothing); Download saves a
 * real PNG under the server's name; Share hands the file to the Web Share API, or downloads it when the browser can't
 * share files; Copy link copies the article's link; closing it gives focus back to the article. Guests get it too, with
 * no sign-in prompt. Failures say why, with "Try again" where it helps; a changed text also loads the article again;
 * offline says the internet is needed and asks nothing. Every text comes from public/i18n, as the screen shows it.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
const QUOTE_URL = /\/api\/v1\/articles\/[^/]+\/quote-card$/;
const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

interface Range {
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
}
interface Fixtures {
  blocks: Record<'ar' | 'en', { blockId: string; plainText: string | null }[]>;
  selections: { id: string; expected: Range | null }[];
}
const FIXTURES = JSON.parse(readFileSync(join(__dirname, '../../shared/rdoc/highlight-fixtures.json'), 'utf8')) as Fixtures;
const expected = (id: string) => FIXTURES.selections.find((s) => s.id === id)!.expected!;
const plainText = (doc: 'ar' | 'en', blockId: string) => FIXTURES.blocks[doc].find((b) => b.blockId === blockId)!.plainText!;

/** The app's own strings (public/i18n), so the test reads what the screen says whatever the wording of the day. */
interface Strings {
  common: { close: string; linkCopied: string };
  highlights: { create: string };
  settings: { theme: { light: string; dark: string } };
  errors: { quote: Record<'busy' | 'text_mismatch' | 'failed', string> };
  quoteCard: Record<'share' | 'title' | 'hint' | 'square' | 'landscape' | 'shareImage' | 'download' | 'copyLink' | 'retry' | 'offline', string>;
}
const strings = (lang: 'ar' | 'en') => JSON.parse(readFileSync(join(__dirname, `../public/i18n/${lang}.json`), 'utf8')) as Strings;
const textsOf = (s: Strings) => ({
  share: s.quoteCard.share,
  title: s.quoteCard.title,
  hint: s.quoteCard.hint,
  highlight: s.highlights.create,
  themes: [s.settings.theme.light, s.settings.theme.dark],
  formats: [s.quoteCard.square, s.quoteCard.landscape],
  shareImage: s.quoteCard.shareImage,
  download: s.quoteCard.download,
  copyLink: s.quoteCard.copyLink,
  linkCopied: s.common.linkCopied,
  close: s.common.close,
  retry: s.quoteCard.retry,
  busy: s.errors.quote.busy,
  mismatch: s.errors.quote.text_mismatch,
  failed: s.errors.quote.failed,
  offline: s.quoteCard.offline,
});
const TEXTS = { ar: textsOf(strings('ar')), en: textsOf(strings('en')) };

/** What each variant reads: the Arabic version in ar/light, the English one in en/dark (as highlights.e2e.ts). */
const CASES = {
  ar: { doc: 'ar' as const, path: '/ar/a/highlights-lab', language: 'ar-EG', drag: { blockId: 'p4', from: 'جرّب', to: 'ده' }, range: expected('ar-mention-zwj-emoji') },
  en: { doc: 'en' as const, path: '/en/a/highlights-lab', language: 'en', drag: { blockId: 'e1', from: 'makes', to: 'easy' }, range: expected('en-arabic-at-end') },
};

/**
 * Replaces the Web Share API and the clipboard with recorders (headless browsers differ there): `canShare` says yes to
 * files only once `window.__canShareFiles` is true.
 */
async function stubShareAndClipboard(page: Page): Promise<void> {
  await page.addInitScript(() => {
    const w = window as unknown as { __shared: unknown[]; __copied: string[]; __canShareFiles: boolean };
    w.__shared = [];
    w.__copied = [];
    w.__canShareFiles = false;
    Object.defineProperty(navigator, 'canShare', { configurable: true, value: (data?: ShareData) => w.__canShareFiles && !!data?.files?.length });
    Object.defineProperty(navigator, 'share', {
      configurable: true,
      value: async (data: ShareData) => {
        w.__shared.push({ files: (data.files ?? []).map((f) => ({ name: f.name, type: f.type, size: f.size })), text: data.text, title: data.title });
      },
    });
    Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText: async (text: string) => void w.__copied.push(text) } });
  });
}

/** A reader who keeps highlights (`u-hl…`, highlights.mjs): Highlight and Share quote in the toolbar. */
async function signInAsHighlighter(page: Page, request: APIRequestContext, variant: Variant): Promise<void> {
  const me = await writerMe(request, variant, { id: `u-hl-${randomUUID().slice(0, 8)}`, displayName: 'Sara Hassan', username: 'sara', isVerified: false, roles: ['Member'] });
  const token = sessionFor(me).accessToken;
  await onApi(page, 'POST', '/auth/refresh', async (route) => {
    const current = await (await request.get(`${API}/me`, { headers: { authorization: `Bearer ${token}` } })).json();
    await reply(route, 200, sessionFor({ ...current, uiLanguage: variant.lang, theme: variant.theme }));
  });
}

/** Opens the lab article and waits for its highlights (yours too when signed in). */
async function openLab(page: Page, path: string, signedIn: boolean): Promise<void> {
  const loaded = page.waitForResponse(
    (r) => r.request().method() === 'GET' && new URL(r.url()).pathname.endsWith('/highlights') && (!signedIn || !!r.request().headers()['authorization']),
  );
  await page.goto(path);
  await loaded;
  await expect(page.locator('rd-article-action-bar [data-react]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
}

const block = (page: Page, id: string) => page.locator(`rd-article-page rd-rdoc [data-block-id="${id}"]`);
const toolbar = (page: Page) => page.locator('[data-highlight-toolbar]');
const dialog = (page: Page) => page.locator('rd-quote-card-dialog [role="dialog"]');
const preview = (page: Page) => page.locator('[data-quote-preview]');
const image = (page: Page) => page.locator('[data-quote-image]');

/** Drags the mouse from the start of `from` to the end of `to` in a block, as a reader selects. */
async function dragSelect(page: Page, drag: { blockId: string; from: string; to: string }): Promise<void> {
  await block(page, drag.blockId).evaluate((el) => el.scrollIntoView({ block: 'center' }));
  const ends = await block(page, drag.blockId).evaluate((el, { from, to }) => {
    const rtl = getComputedStyle(el).direction === 'rtl';
    /** Just inside the edge where a character starts (or ends), so the caret lands before (or after) it. */
    const edge = (word: string, last: boolean) => {
      const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
      for (let node = walker.nextNode() as Text | null; node; node = walker.nextNode() as Text | null) {
        const at = node.data.indexOf(word);
        if (at < 0) continue;
        const range = document.createRange();
        const index = last ? at + word.length - 1 : at;
        range.setStart(node, index);
        range.setEnd(node, index + 1);
        const r = range.getBoundingClientRect();
        const startSide = rtl !== last;
        return { x: startSide ? r.right - 1 : r.left + 1, y: r.top + r.height / 2 };
      }
      throw new Error(word);
    };
    return { start: edge(from, false), end: edge(to, true) };
  }, drag);
  await page.mouse.move(ends.start.x, ends.start.y);
  await page.mouse.down();
  await page.mouse.move(ends.end.x, ends.end.y, { steps: 8 });
  await page.mouse.up();
}

/** Selects a range of a block's plain text (text nodes and <br>s of its `rd-inline`s, list items joined by "\n"). */
async function selectText(page: Page, range: Pick<Range, 'blockId' | 'startOffset' | 'endOffset'>): Promise<void> {
  await page.evaluate(({ blockId, startOffset, endOffset }) => {
    const root = document.querySelector(`rd-article-page rd-rdoc [data-block-id="${blockId}"]`)!;
    const points: { node: Node; offset: number }[] = [];
    let seen = 0;
    const want = [startOffset, endOffset];
    for (const inline of root.querySelectorAll('rd-inline')) {
      const walker = document.createTreeWalker(inline, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
      for (let node = walker.nextNode(); node; node = walker.nextNode()) {
        if (node.nodeType === Node.TEXT_NODE) {
          const length = (node as Text).data.length;
          while (points.length < 2 && want[points.length] <= seen + length) points.push({ node, offset: want[points.length] - seen });
          seen += length;
        } else if (node.nodeName === 'BR') seen += 1;
      }
      seen += 1;
    }
    document.getSelection()!.setBaseAndExtent(points[0].node, points[0].offset, points[1].node, points[1].offset);
  }, range);
}

/** The quote card requests the page sent, as they were asked. */
function recordCards(page: Page): Request[] {
  const sent: Request[] = [];
  page.on('request', (r) => {
    if (r.method() === 'POST' && QUOTE_URL.test(r.url())) sent.push(r);
  });
  return sent;
}
const bodyOf = (r: Request) => r.postDataJSON() as Range & { language: string; theme: string; format: string };

/** The picture on screen, once it has loaded: [naturalWidth, naturalHeight]. */
async function expectImage(page: Page, size: [number, number]): Promise<void> {
  await expect(preview(page)).toHaveAttribute('data-state', 'ready', { timeout: 15_000 });
  await expect.poll(() => image(page).evaluate((el: HTMLImageElement) => (el.complete ? [el.naturalWidth, el.naturalHeight] : null))).toEqual(size);
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = TEXTS[lang];
  const c = CASES[lang];
  const other = theme === 'light' ? 'dark' : 'light';
  const themeIndex = theme === 'light' ? 0 : 1;

  test(`Share quote: from a mouse selection, light/dark and square/landscape, Download, Share and Copy link — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await stubShareAndClipboard(page);
    await signInAsHighlighter(page, request, variant);
    await openLab(page, c.path, true);
    const sent = recordCards(page);

    // A real mouse drag over a few words: Highlight, then Share quote.
    await dragSelect(page, c.drag);
    const open = toolbar(page).locator('[data-quote-share-open]');
    await expect(open).toHaveText(t.share);
    await expect(toolbar(page).locator('button')).toHaveText([t.highlight, t.share]);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(toolbar(page)).toHaveScreenshot(`quote-toolbar-${suffix}.png`);

    // The dialog: the card of exactly that range, in the app's theme, square.
    await open.click();
    await expect(dialog(page)).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(toolbar(page)).toHaveCount(0);
    await expect.poll(() => sent.length).toBe(1);
    const first = bodyOf(sent[0]);
    expect(first).toMatchObject({ language: c.language, blockId: c.drag.blockId, theme, format: 'square' });
    expect(first.text).toBe(plainText(c.doc, c.drag.blockId).slice(first.startOffset, first.endOffset));
    expect(first.text.startsWith(c.drag.from) && first.text.endsWith(c.drag.to), first.text).toBe(true);
    expect(sent[0].headers()['authorization']).toMatch(/^Bearer /);
    await expectImage(page, [1080, 1080]);
    await expect(dialog(page).locator('#rd-quote-card-title')).toHaveText(t.title);
    await expect(dialog(page).locator('[data-quote-hint]')).toHaveText(t.hint);
    await expect(dialog(page).locator('[data-quote-theme] [role="radio"]')).toHaveText([...t.themes]);
    await expect(dialog(page).locator('[data-quote-theme] [role="radio"]').nth(themeIndex)).toHaveAttribute('aria-checked', 'true');
    await expect(dialog(page).locator('[data-quote-format] [role="radio"]')).toHaveText([...t.formats]);
    await expect(dialog(page).locator('[data-quote-share]')).toHaveText(t.shareImage);
    await expect(dialog(page).locator('[data-quote-download]')).toHaveText(t.download);
    await expect(dialog(page).locator('[data-quote-copy-link]')).toHaveText(t.copyLink);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(dialog(page)).toHaveScreenshot(`quote-dialog-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Landscape, then the other theme: one new card each; back to the first: nothing asked.
    await dialog(page).locator('[data-quote-format] [role="radio"]').nth(1).click();
    await expect.poll(() => sent.length).toBe(2);
    expect(bodyOf(sent[1])).toMatchObject({ theme, format: 'landscape', text: first.text, startOffset: first.startOffset });
    await expectImage(page, [1200, 630]);
    await dialog(page).locator('[data-quote-theme] [role="radio"]').nth(1 - themeIndex).click();
    await expect.poll(() => sent.length).toBe(3);
    expect(bodyOf(sent[2])).toMatchObject({ theme: other, format: 'landscape' });
    await expectImage(page, [1200, 630]);
    await dialog(page).locator('[data-quote-theme] [role="radio"]').nth(themeIndex).click();
    await dialog(page).locator('[data-quote-format] [role="radio"]').nth(0).click();
    await expectImage(page, [1080, 1080]);
    await page.waitForTimeout(300);
    expect(sent).toHaveLength(3);

    // Download: a real PNG under the server's name, from the bytes on screen.
    const [file] = await Promise.all([page.waitForEvent('download'), dialog(page).locator('[data-quote-download]').click()]);
    expect(file.suggestedFilename()).toBe('readin-quote-highlights-lab.png');
    const bytes = readFileSync((await file.path())!);
    expect([...bytes.subarray(0, 8)]).toEqual(PNG_SIGNATURE);
    expect([bytes.readUInt32BE(16), bytes.readUInt32BE(20)]).toEqual([1080, 1080]);

    // Share without file sharing: downloaded instead. With it: the PNG and the article's link go to the share sheet.
    const [fallback] = await Promise.all([page.waitForEvent('download'), dialog(page).locator('[data-quote-share]').click()]);
    expect(fallback.suggestedFilename()).toBe('readin-quote-highlights-lab.png');
    await page.evaluate(() => ((window as unknown as { __canShareFiles: boolean }).__canShareFiles = true));
    await dialog(page).locator('[data-quote-share]').click();
    await expect
      .poll(() => page.evaluate(() => (window as unknown as { __shared: unknown[] }).__shared))
      .toEqual([{ files: [{ name: 'readin-quote-highlights-lab.png', type: 'image/png', size: bytes.length }], text: `${baseURL}${c.path}`, title: 'ReadIn' }]);

    // Copy link: the article's link, and a toast.
    await dialog(page).locator('[data-quote-copy-link]').click();
    await expect(page.locator('rd-toast-host', { hasText: t.linkCopied })).toBeVisible();
    expect(await page.evaluate(() => (window as unknown as { __copied: string[] }).__copied)).toEqual([`${baseURL}${c.path}`]);
    expect(sent).toHaveLength(3);

    // Escape closes it, and focus goes back to the quoted block (not the top of the page).
    await page.keyboard.press('Escape');
    await expect(dialog(page)).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => document.activeElement?.closest('[data-block-id]')?.getAttribute('data-block-id') ?? null)).toBe(c.drag.blockId);
  });

  test(`Share quote: guests too, with no sign-in prompt; not for code or too little text — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await openLab(page, c.path, false);
    const sent = recordCards(page);

    await selectText(page, c.range);
    await expect(toolbar(page).locator('button')).toHaveText([t.highlight, t.share]);
    await toolbar(page).locator('[data-quote-share-open]').click();
    await expect(dialog(page)).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('rd-sign-in-prompt [role="dialog"]')).toHaveCount(0);
    await expectImage(page, [1080, 1080]);
    expect(sent).toHaveLength(1);
    expect(bodyOf(sent[0])).toEqual({ language: c.language, ...c.range, theme, format: 'square' });
    expect(sent[0].headers()['authorization']).toBeUndefined();
    await dialog(page).getByRole('button', { name: t.close }).click();
    await expect(dialog(page)).toHaveCount(0);

    // Fewer than 3 characters, or a code block: no toolbar at all.
    await selectText(page, { blockId: c.range.blockId, startOffset: c.range.startOffset, endOffset: c.range.startOffset + 2 });
    await page.waitForTimeout(400);
    await expect(toolbar(page)).toHaveCount(0);
    if (lang === 'ar') {
      await page.locator('[data-block-id="k1"]').evaluate((el) => {
        const node = document.createTreeWalker(el, NodeFilter.SHOW_TEXT).nextNode() as Text;
        document.getSelection()!.setBaseAndExtent(node, 0, node, Math.min(8, node.data.length));
      });
      await page.waitForTimeout(400);
      await expect(toolbar(page)).toHaveCount(0);
    }
    expect(sent).toHaveLength(1);
  });

  test(`Share quote: errors say why, with "${t.retry}" where it helps, and offline — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await openLab(page, c.path, false);
    const sent = recordCards(page);

    // The next card call answers this, then the mock answers again.
    let next: ((route: Route) => Promise<void>) | null = null;
    await page.route(QUOTE_URL, async (route) => {
      const answer = next;
      if (route.request().method() !== 'POST' || !answer) return route.fallback();
      next = null;
      return answer(route);
    });
    const error = page.locator('[data-quote-error] [role="alert"]');
    const retry = page.locator('[data-quote-retry]');
    const radios = (group: 'theme' | 'format') => dialog(page).locator(`[data-quote-${group}] [role="radio"]`);

    // Busy: "Try again" draws it.
    next = (route) => reply(route, 503, problem(503, 'quote.busy'));
    await selectText(page, c.range);
    await toolbar(page).locator('[data-quote-share-open]').click();
    await expect(error).toHaveText(t.busy, { timeout: FIRST_RENDER_MS });
    await expect(retry).toHaveText(t.retry);
    await expect(dialog(page).locator('[data-quote-share]')).toBeDisabled();
    await expect(dialog(page).locator('[data-quote-download]')).toBeDisabled();
    await retry.click();
    await expectImage(page, [1080, 1080]);
    expect(sent).toHaveLength(2);

    // The text changed meanwhile: said, with nothing to try again, and the article and its highlights load again (as
    // after highlight.text_mismatch) while the dialog stays.
    const get = (path: RegExp) => page.waitForResponse((r) => r.request().method() === 'GET' && path.test(new URL(r.url()).pathname));
    const reloaded = Promise.all([get(/\/articles\/highlights-lab$/), get(/\/articles\/[^/]+\/highlights$/)]);
    next = (route) => reply(route, 400, problem(400, 'quote.text_mismatch'));
    await radios('format').nth(1).click();
    await expect(error).toHaveText(t.mismatch);
    await expect(retry).toHaveCount(0);
    await reloaded;
    await expect(error).toHaveText(t.mismatch);

    // Offline: said, and nothing is asked; back online, "Try again" asks; the connection drops during the call.
    await context.setOffline(true);
    await radios('theme').nth(1 - themeIndex).click();
    await expect(error).toHaveText(t.offline);
    await expect(retry).toHaveText(t.retry);
    expect(sent).toHaveLength(3);
    await context.setOffline(false);
    next = (route) => route.abort('internetdisconnected');
    await retry.click();
    await expect.poll(() => sent.length).toBe(4);
    await expect(error).toHaveText(t.offline);
    await retry.click();
    await expectImage(page, [1200, 630]);
    expect(sent).toHaveLength(5);

    // A failed drawing: "Try again" draws it. The first card is still there.
    next = (route) => reply(route, 500, problem(500, 'quote.failed'));
    await radios('format').nth(0).click();
    await expect(error).toHaveText(t.failed);
    await retry.click();
    await expectImage(page, [1080, 1080]);
    await radios('theme').nth(themeIndex).click();
    await expectImage(page, [1080, 1080]);
    expect(sent).toHaveLength(7);
  });
}
