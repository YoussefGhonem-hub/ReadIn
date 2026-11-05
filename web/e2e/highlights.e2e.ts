import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { APIRequestContext, Page, expect, test } from '@playwright/test';
import { API, HIDE_APP_CHROME, HIDE_COMMENTS, HIDE_READER_BAR, MockMe, VARIANTS, Variant, hasScreenshot, onApi, parkMouse, reply, sessionFor, useVariant, writerMe } from './support/mock-api';
import { openProfile } from './support/profile';
import { expectSignInPrompt } from './support/social';

/**
 * F30 Highlights end to end in ar/light and en/dark: drawing yours and the popular ones (mixed Arabic/English text
 * whose isolated runs stay whole), Highlight and Remove from the selection toolbar (a real mouse drag, the keyboard,
 * and the shared fixtures' ranges), the popular count, no toolbar in code or for too little text, hiding them from the
 * "⋯" menu, `Ctrl + /` and Settings (synced), guests (sign-in prompt; hiding stays on the device), and the profile's
 * Saved → Highlights opening the article at the block. The mock API's "Highlights lab" article is the shared offsets
 * fixtures (shared/rdoc/highlight-fixtures.json), Arabic at /ar/a/highlights-lab and English at /en/a/highlights-lab
 * (e2e/mock-api/highlights.mjs); readers whose id starts with `u-hl` keep their highlights and setting there.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

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

/** What each variant reads: the Arabic version in ar/light, the English one in en/dark. */
const CASES = {
  ar: {
    doc: 'ar' as const,
    path: '/ar/a/highlights-lab',
    language: 'ar-EG',
    /** A popular range across a bold English run and a glossary term, 12 readers. */
    popular: { blockId: 'p1', text: 'ASP.NET Core، أكيد شفت الـ Dependency Injection', count: 12, run: 'ASP.NET Core' },
    /** Another popular one, tapped for the count. */
    tapped: { blockId: 'p3', count: 5 },
    create: expected('ar-mention-zwj-emoji'),
    mixed: expected('ar-bold-to-term'),
    /** Dragged with the mouse. */
    drag: { blockId: 'p4', from: 'جرّب', to: 'ده' },
    keyboard: expected('ar-heading'),
  },
  en: {
    doc: 'en' as const,
    path: '/en/a/highlights-lab',
    language: 'en',
    popular: { blockId: 'e1', text: 'Injection (الحقن) everywhere', count: 4, run: 'الحقن' },
    tapped: { blockId: 'e2', count: 3 },
    create: expected('en-arabic-at-end'),
    /** Exactly the popular range: drawn as yours. */
    mixed: expected('en-arabic-inside-english'),
    drag: { blockId: 'e1', from: 'makes', to: 'easy' },
    keyboard: expected('en-heading-link'),
  },
};

/** A reader who keeps highlights (`u-hl…`); the session restore asks the mock for their current `GET /me`. */
async function signInAsHighlighter(page: Page, request: APIRequestContext, variant: Variant): Promise<MockMe> {
  const id = `u-hl-${randomUUID().slice(0, 8)}`;
  const me = await writerMe(request, variant, { id, displayName: 'Sara Hassan', username: 'sara', isVerified: false, roles: ['Member'] });
  const token = sessionFor(me).accessToken;
  await onApi(page, 'POST', '/auth/refresh', async (route) => {
    const current = await (await request.get(`${API}/me`, { headers: { authorization: `Bearer ${token}` } })).json();
    await reply(route, 200, sessionFor({ ...current, uiLanguage: variant.lang, theme: variant.theme }));
  });
  return me;
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
/** The highlight a POST answered with, and what was sent. */
async function createdId(page: Page, click: () => Promise<void>): Promise<{ id: string; body: Range }> {
  const answered = page.waitForResponse((r) => r.request().method() === 'POST' && new URL(r.url()).pathname.endsWith('/highlights'));
  await click();
  const response = await answered;
  expect(response.status()).toBe(201);
  return { id: ((await response.json()) as { highlight: { id: string } }).highlight.id, body: response.request().postDataJSON() as Range };
}
const markText = (page: Page, blockId: string, selector: string) =>
  block(page, blockId)
    .locator(selector)
    .evaluateAll((els) => els.map((el) => el.textContent).join(''));

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
      seen += 1; // the "\n" between list items
    }
    document.getSelection()!.setBaseAndExtent(points[0].node, points[0].offset, points[1].node, points[1].offset);
  }, range);
}

/** Waits long enough for the toolbar to have shown if it were going to (it reads the selection after 60 ms). */
async function expectNoToolbar(page: Page): Promise<void> {
  await page.waitForTimeout(400);
  await expect(toolbar(page)).toHaveCount(0);
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);
  const c = CASES[lang];

  test(`highlights: popular ones, Highlight and Remove, mixed text — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsHighlighter(page, request, variant);
    await openLab(page, c.path, true);

    // Popular ranges are drawn with their counts; the isolated English (or Arabic) run inside stays one <bdi>.
    const popular = block(page, c.popular.blockId);
    expect(await markText(page, c.popular.blockId, '.rd-hl-popular')).toBe(c.popular.text);
    await expect(popular.locator('.rd-hl-popular').first()).toHaveAttribute('data-hl-count', String(c.popular.count));
    expect(await popular.locator('bdi').evaluateAll((els) => els.map((el) => el.textContent))).toContain(c.popular.run);
    expect(await popular.evaluate((el) => el.textContent)).toBe(plainText(c.doc, c.popular.blockId));

    // Select (the fixtures' range) → Highlight: saved with exactly those offsets, then drawn as yours.
    await selectText(page, c.create);
    await expect(toolbar(page)).toBeVisible();
    await expect(toolbar(page)).toHaveAttribute('aria-label', t('خيارات الـ Highlight', 'Highlight options'));
    const create = toolbar(page).locator('[data-highlight-create]');
    await expect(create).toHaveText(t('علّم', 'Highlight'));
    const created = await createdId(page, () => create.click());
    expect(created.body).toEqual({ language: c.language, ...c.create });
    const mine = `[data-hl-mine="${created.id}"]`;
    await expect(block(page, c.create.blockId).locator(mine).first()).toBeVisible();
    expect(await markText(page, c.create.blockId, mine)).toBe(c.create.text);
    await expect(toolbar(page)).toHaveCount(0);

    // Mixed text across marks, terms and mentions: the text and its isolated runs don't change.
    const runsBefore = await block(page, c.mixed.blockId).locator('bdi').evaluateAll((els) => els.map((el) => el.textContent));
    await selectText(page, c.mixed);
    const mixed = await createdId(page, () => toolbar(page).locator('[data-highlight-create]').click());
    expect(mixed.body).toEqual({ language: c.language, ...c.mixed });
    const mixedMark = `[data-hl-mine="${mixed.id}"]`;
    await expect(block(page, c.mixed.blockId).locator(mixedMark).first()).toBeVisible();
    expect(await markText(page, c.mixed.blockId, mixedMark)).toBe(c.mixed.text);
    expect(await block(page, c.mixed.blockId).locator('bdi').evaluateAll((els) => els.map((el) => el.textContent))).toEqual(runsBefore);
    expect(await block(page, c.mixed.blockId).evaluate((el) => el.textContent)).toBe(plainText(c.doc, c.mixed.blockId));

    // Tapping a popular one: "N readers highlighted this". Yours and popular ones on screen together.
    await block(page, c.popular.blockId).evaluate((el) => el.scrollIntoView({ block: 'start' }));
    await page.evaluate(() => window.scrollBy(0, -120));
    await block(page, c.tapped.blockId).locator('.rd-hl-popular').first().click();
    await expect(toolbar(page)).toHaveAttribute('data-kind', 'mark');
    await expect(toolbar(page).locator('[data-highlight-count]')).toHaveText(t(`${c.tapped.count} قارئ علّموا الجملة دي`, `${c.tapped.count} readers highlighted this`));
    await expect(toolbar(page).locator('button')).toHaveCount(0);
    // The toolbar takes no focus: screen readers hear the count from the live region.
    await expect(page.locator('[data-highlights-status]')).toHaveText(t(`${c.tapped.count} قارئ علّموا الجملة دي`, `${c.tapped.count} readers highlighted this`));
    await parkMouse(page);
    if (hasScreenshot(variant)) {
      // The marked blocks and the tapped one's toolbar (it floats over the page, so a viewport region, not an element).
      const clip = await page.evaluate(({ from, to }) => {
        const box = (selector: string) => document.querySelector(selector)!.getBoundingClientRect();
        const first = box(`rd-rdoc [data-block-id="${from}"]`);
        const last = box(`rd-rdoc [data-block-id="${to}"]`);
        const bar = box('[data-highlight-toolbar]');
        const content = box('rd-rdoc');
        const top = Math.max(0, Math.min(first.top, bar.top) - 8);
        const x = Math.max(0, content.left - 8);
        return { x, y: top, width: Math.min(innerWidth - x, content.width + 16), height: Math.max(last.bottom, bar.bottom) + 8 - top };
      }, { from: c.popular.blockId, to: c.tapped.blockId });
      await expect(page).toHaveScreenshot(`highlights-reader-${suffix}.png`, { clip, stylePath: [HIDE_APP_CHROME, HIDE_READER_BAR, HIDE_COMMENTS] });
    }

    // Selecting inside one of yours offers Remove, even fewer than 3 characters.
    const remove = toolbar(page).locator('[data-highlight-remove]');
    await selectText(page, { blockId: c.create.blockId, startOffset: c.create.startOffset + 3, endOffset: c.create.startOffset + 5 });
    await expect(remove).toHaveText(t('شيل العلامة', 'Remove highlight'));
    await expect(toolbar(page).locator('[data-highlight-create]')).toHaveCount(0);
    await selectText(page, { blockId: c.create.blockId, startOffset: c.create.startOffset + 1, endOffset: c.create.endOffset - 1 });
    await expect(remove).toHaveText(t('شيل العلامة', 'Remove highlight'));
    await expect(toolbar(page).locator('[data-highlight-create]')).toHaveCount(0);
    const deleted = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().includes('/highlights/'));
    await remove.click();
    expect((await deleted).status()).toBe(204);
    await expect(block(page, c.create.blockId).locator(mine)).toHaveCount(0);

    // A real mouse drag over a few words: the toolbar's Highlight sends what was selected, trimmed, at its offsets.
    await block(page, c.drag.blockId).evaluate((el) => el.scrollIntoView({ block: 'center' }));
    const ends = await block(page, c.drag.blockId).evaluate((el, { from, to }) => {
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
          const startSide = rtl !== last; // where this character's own edge is, in its direction
          return { x: startSide ? r.right - 1 : r.left + 1, y: r.top + r.height / 2 };
        }
        throw new Error(word);
      };
      return { start: edge(from, false), end: edge(to, true) };
    }, c.drag);
    await page.mouse.move(ends.start.x, ends.start.y);
    await page.mouse.down();
    await page.mouse.move(ends.end.x, ends.end.y, { steps: 8 });
    await page.mouse.up();
    await expect(toolbar(page).locator('[data-highlight-create]')).toBeVisible();
    const dragged = page.waitForRequest((r) => r.method() === 'POST' && r.url().endsWith('/highlights'));
    await toolbar(page).locator('[data-highlight-create]').click();
    const body = (await dragged).postDataJSON() as Range;
    expect(body.blockId).toBe(c.drag.blockId);
    expect(body.text).toBe(plainText(c.doc, c.drag.blockId).slice(body.startOffset, body.endOffset));
    expect(body.text.startsWith(c.drag.from), body.text).toBe(true);
    expect(body.text.endsWith(c.drag.to), body.text).toBe(true);
    await expect(block(page, c.drag.blockId).locator('[data-hl-mine]').first()).toBeVisible();

    // Keyboard: with a selection, Tab reaches the toolbar and Enter highlights.
    await selectText(page, c.keyboard);
    await expect(toolbar(page).locator('[data-highlight-create]')).toBeVisible();
    await page.keyboard.press('Tab');
    await expect(toolbar(page).locator('[data-highlight-create]')).toBeFocused();
    const typed = page.waitForRequest((r) => r.method() === 'POST' && r.url().endsWith('/highlights'));
    await page.keyboard.press('Enter');
    expect((await typed).postDataJSON()).toEqual({ language: c.language, ...c.keyboard });

    // Too little text, or code: no toolbar.
    await selectText(page, { blockId: c.create.blockId, startOffset: 0, endOffset: 2 });
    await expectNoToolbar(page);
    if (lang === 'ar') {
      await page.locator('[data-block-id="k1"]').evaluate((el) => {
        const text = [...el.querySelectorAll('code, pre')].map((n) => n.firstChild).find((n) => n && n.nodeType === Node.TEXT_NODE && (n as Text).data.length > 8) as Text | undefined;
        const node = text ?? (document.createTreeWalker(el, NodeFilter.SHOW_TEXT).nextNode() as Text);
        document.getSelection()!.setBaseAndExtent(node, 0, node, Math.min(8, node.data.length));
      });
      await expectNoToolbar(page);
    }

    // They are yours after a reload too.
    await openLab(page, c.path, true);
    await expect(block(page, c.mixed.blockId).locator(mixedMark).first()).toBeVisible();
  });

  test(`highlights: hide them from the "⋯" menu, Ctrl + / and Settings, synced — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsHighlighter(page, request, variant);
    await openLab(page, c.path, true);
    await expect(page.locator('rd-rdoc .rd-hl').first()).toBeVisible();

    // The "⋯" item, right after Show less: saved to your preferences.
    const menuButton = page.locator('rd-article-action-bar [data-article-menu]');
    const item = page.locator('[data-article-menu-panel] [data-menu-action="highlights"]');
    await menuButton.click();
    await expect(page.locator('[data-article-menu-panel] [data-menu-action]').nth(1)).toHaveAttribute('data-menu-action', 'highlights');
    await expect(item).toHaveText(t('إخفاء الـ Highlights', 'Hide highlights'));
    await expect(item).toHaveAttribute('aria-keyshortcuts', 'Control+/');
    const hidden = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith('/me/preferences'));
    await item.click();
    expect((await hidden).postDataJSON()).toMatchObject({ showHighlights: false, uiLanguage: lang });
    await expect(page.locator('rd-rdoc .rd-hl')).toHaveCount(0);
    // Hidden: selecting text offers nothing.
    await selectText(page, c.create);
    await expectNoToolbar(page);
    await page.evaluate(() => document.getSelection()!.removeAllRanges());

    await menuButton.click();
    await expect(item).toHaveText(t('إظهار الـ Highlights', 'Show highlights'));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('[data-article-menu-panel]')).toHaveScreenshot(`highlights-menu-${suffix}.png`);
    await page.keyboard.press('Escape');
    await expect(page.locator('[data-article-menu-panel]')).toHaveCount(0);

    // Ctrl + / shows them again, and hides them again.
    let saved = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith('/me/preferences'));
    await page.keyboard.press('Control+/');
    expect((await saved).postDataJSON()).toMatchObject({ showHighlights: true });
    await expect(page.locator('rd-rdoc .rd-hl').first()).toBeVisible();
    saved = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith('/me/preferences'));
    await page.keyboard.press('Control+/');
    expect((await saved).postDataJSON()).toMatchObject({ showHighlights: false });
    await expect(page.locator('rd-rdoc .rd-hl')).toHaveCount(0);

    // Kept by the server: still hidden after a reload, and Settings agrees.
    await page.reload();
    await expect(page.locator('rd-article-action-bar [data-react]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');
    await expect(page.locator('rd-rdoc .rd-hl')).toHaveCount(0);
    await page.goto('/settings');
    const toggle = page.locator('[data-settings-highlights] [role="switch"]');
    await expect(toggle).toHaveAttribute('aria-checked', 'false', { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-settings-highlights]')).toContainText(t('إظهار الـ Highlights', 'Show highlights'));
    saved = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith('/me/preferences'));
    await toggle.click();
    expect((await saved).postDataJSON()).toMatchObject({ showHighlights: true });
    await expect(toggle).toHaveAttribute('aria-checked', 'true');
    await openLab(page, c.path, true);
    await expect(page.locator('rd-rdoc .rd-hl').first()).toBeVisible();
  });

  test(`highlights: guests see popular ones, sign in to highlight, and hide them on this device — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await openLab(page, c.path, false);
    expect(await markText(page, c.popular.blockId, '.rd-hl-popular')).toBe(c.popular.text);

    // Highlight asks them to sign in; nothing is sent.
    let posts = 0;
    page.on('request', (r) => {
      if (r.method() === 'POST' && r.url().endsWith('/highlights')) posts++;
    });
    await selectText(page, c.create);
    await toolbar(page).locator('[data-highlight-create]').click();
    await expectSignInPrompt(page);
    expect(posts).toBe(0);

    // The popular count works for guests too.
    await block(page, c.tapped.blockId).locator('.rd-hl-popular').first().click();
    await expect(toolbar(page).locator('[data-highlight-count]')).toContainText(String(c.tapped.count));

    // Hide highlights: no sign-in prompt, no request; this device keeps it.
    let puts = 0;
    page.on('request', (r) => {
      if (r.method() === 'PUT' && r.url().endsWith('/me/preferences')) puts++;
    });
    await page.locator('rd-article-action-bar [data-article-menu]').click();
    await page.locator('[data-article-menu-panel] [data-menu-action="highlights"]').click();
    await expect(page.locator('rd-sign-in-prompt [role="dialog"]')).toHaveCount(0);
    await expect(page.locator('rd-rdoc .rd-hl')).toHaveCount(0);
    await page.reload();
    await expect(page.locator('rd-article-action-bar [data-react]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');
    await expect(page.locator('rd-rdoc .rd-hl')).toHaveCount(0);
    await page.keyboard.press('Control+/');
    await expect(page.locator('rd-rdoc .rd-hl').first()).toBeVisible();
    expect(puts).toBe(0);
  });

  test(`highlights: Saved → Highlights, grouped by article version, opens the article at the block — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsHighlighter(page, request, variant);
    const headers = { authorization: `Bearer ${sessionFor(me).accessToken}` };
    // English first, then two in Arabic: the Arabic version's group is the newest.
    for (const [language, id] of [
      ['en', 'en-arabic-inside-english'],
      ['ar-EG', 'ar-bold-to-term'],
      ['ar-EG', 'ar-tashkeel'],
      ['ar-EG', 'ar-ordered-second-item'],
    ] as const) {
      const response = await request.post(`${API}/articles/a-highlights-lab/highlights`, { headers, data: { language, ...expected(id) } });
      expect(response.status(), id).toBe(201);
    }

    await openProfile(page, '/@sara', { signedIn: true });
    await page.locator('[data-profile-tab="saved"]').click();
    const sections = page.locator('[data-saved-sections]');
    await sections.getByRole('radio', { name: t('الـ Highlights', 'Highlights') }).click();
    const list = page.locator('[data-saved-highlights]');
    const groups = list.locator('[data-highlight-group]');
    await expect(groups).toHaveCount(2, { timeout: FIRST_RENDER_MS });
    expect(await groups.evaluateAll((els) => els.map((el) => el.getAttribute('data-highlight-group')))).toEqual(['a-highlights-lab|ar-EG', 'a-highlights-lab|en']);
    await expect(groups.first().locator('[data-saved-highlight]')).toHaveText(['شغّل dotnet run', 'مُهِمّ جداً', 'ASP.NET Core، أكيد شفت الـ Dependency Injection']);
    await expect(groups.first().locator('[data-group-meta]')).toContainText(t('النسخة العربي', 'Arabic version'));
    await expect(groups.nth(1).locator('[data-saved-highlight]')).toHaveText(['Injection (الحقن) everywhere']);
    await expect(groups.first().locator('[data-saved-highlight]').first()).toHaveAttribute('href', '/ar/a/highlights-lab#b-o1');
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(list).toHaveScreenshot(`highlights-saved-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // A highlight opens its version scrolled to its block (further down the article).
    const opened = page.waitForResponse((r) => r.request().method() === 'GET' && new URL(r.url()).pathname.endsWith('/highlights') && !!r.request().headers()['authorization']);
    await groups.first().locator('[data-saved-highlight]').first().click();
    await page.waitForURL((url) => url.pathname === '/ar/a/highlights-lab' && url.hash === '#b-o1');
    await opened;
    await expect(block(page, 'o1')).toBeInViewport();
    await expect(block(page, 'o1').locator('[data-hl-mine]').first()).toBeVisible();
    expect(await page.evaluate(() => window.scrollY)).toBeGreaterThan(200);
  });

  test(`highlights: an empty Saved → Highlights — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsHighlighter(page, request, variant);
    await openProfile(page, '/@sara', { signedIn: true });
    await page.locator('[data-profile-tab="saved"]').click();
    await page.locator('[data-saved-sections]').getByRole('radio', { name: t('الـ Highlights', 'Highlights') }).click();
    await expect(page.locator('[data-highlights-empty]')).toContainText(t('لسه مفيش Highlights', 'No highlights yet'), { timeout: FIRST_RENDER_MS });
  });
}
