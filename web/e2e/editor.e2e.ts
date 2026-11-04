import { expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, restoreSessionAs, useVariant } from './support/mock-api';
import { editorReady, insertBlock, myArticle, problemCodes, savedToServer, seededIds, signInAsAuthor, trackSavedDocument, typeInEditor } from './support/editor';

/**
 * The article editor (F05) against the mock API, which keeps each writer's articles (e2e/mock-api/editor.mjs):
 * My articles, write → autosave → publish, edit a published article → Update, discard changes, restore a revision,
 * and the block editor's direction handling. Screens are captured in ar/en × light/dark.
 */
// Autosave runs 10 s after a change, and some flows save more than once.
test.describe.configure({ timeout: 120_000 });

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const ar = lang === 'ar';

  test(`My articles: drafts and published tabs, delete with confirmation — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const ids = seededIds(me);
    // Relative edit times ("Edited 2 days ago") against a fixed today.
    await page.clock.setFixedTime(new Date('2026-11-03T12:00:00Z'));
    await page.goto('/write');
    await expect(page.locator('html')).toHaveAttribute('dir', dir);

    // Drafts, newest edit first; an untitled draft says so.
    await expect(page.locator('[data-my-tab="draft"]')).toHaveAttribute('aria-selected', 'true');
    await expect(page.locator('[data-my-article]')).toHaveCount(2);
    await expect(myArticle(page, ids.draft).locator('[data-my-title]')).toHaveText('يعني إيه Clean Architecture؟');
    await expect(myArticle(page, ids.untitled).locator('[data-my-title]')).toHaveText(ar ? 'بدون عنوان' : 'Untitled');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-my-articles-page')).toHaveScreenshot(`my-articles-drafts-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // Published, with the "unpublished changes" chip.
    await page.locator('[data-my-tab="published"]').click();
    await expect(page).toHaveURL(/\/write\?tab=published$/);
    await expect(page.locator('[data-my-article]')).toHaveCount(2);
    await expect(myArticle(page, ids.changed).locator('[data-unpublished-chip]')).toHaveText(ar ? 'تعديلات مش منشورة' : 'Unpublished changes');
    await expect(myArticle(page, ids.published).locator('[data-unpublished-chip]')).toHaveCount(0);
    // Its counts read as words for screen readers, in the right plural form (4 reactions, 1 comment, 37 reads).
    await expect
      .poll(() => myArticle(page, ids.published).locator('span[aria-label]').evaluateAll((spans) => spans.map((s) => s.getAttribute('aria-label'))))
      .toEqual(ar ? ['4 تفاعلات', 'تعليق واحد', '37 قراءة'] : ['4 reactions', '1 comment', '37 reads']);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-my-articles-page')).toHaveScreenshot(`my-articles-published-${lang}-${theme}.png`, { stylePath: HIDE_APP_CHROME });

    // Delete asks in the page first; Cancel keeps the article.
    await page.locator('[data-my-tab="draft"]').click();
    await myArticle(page, ids.untitled).locator('[data-delete-article]').click();
    const sheet = page.locator('[data-delete-sheet]');
    await expect(sheet).toBeVisible();
    await sheet.getByRole('button', { name: ar ? 'إلغاء' : 'Cancel' }).click();
    await expect(myArticle(page, ids.untitled)).toBeVisible();
    await myArticle(page, ids.untitled).locator('[data-delete-article]').click();
    await sheet.locator('[data-confirm-delete]').click();
    await expect(myArticle(page, ids.untitled)).toHaveCount(0);
    await page.reload();
    await expect(page.locator('[data-my-article]')).toHaveCount(1);
  });

  test(`write → autosave → publish, with blocks, markdown and live checks — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsAuthor(page, request, variant, 'fresh');
    await page.goto('/write');
    await expect(page.locator('[data-my-empty]')).toBeVisible();
    await page.locator('[data-new-article]').click();
    await page.waitForURL((url) => url.pathname === '/write/new');
    await editorReady(page);

    // The language defaults to the writer's article language (en); write in Arabic.
    await page.locator('[data-source-language]').getByRole('radio').first().click();
    await page.locator('[data-title]').fill('يعني إيه Dependency Injection؟');
    await typeInEditor(page, 'لو انت شغال بـ **ASP.NET Core** ');
    await page.keyboard.type('أكيد شفت الـ `DI` في كل حتة.');
    await page.keyboard.press('Enter');
    await page.keyboard.type('## ليه نستخدمه؟');
    await page.keyboard.press('Enter');
    await insertBlock(page, 'code', 'code');
    await page.keyboard.type('builder.Services.AddScoped<IClock, Clock>();');

    // First autosave creates the draft: the URL gets its id.
    await savedToServer(page);
    await page.waitForURL((url) => /^\/write\/art-\d+$/.test(url.pathname));
    await expect.poll(() => problemCodes(page), { timeout: 15_000 }).toEqual(['article.field_required']);
    await expect(page.locator('[data-publish]')).toBeDisabled();

    // A problem jumps to its field; fixing it enables Publish after the next save.
    await page.locator('[data-problem="article.field_required"]').click();
    await expect(page.locator('#ed-field')).toBeFocused();
    await page.locator('[data-field]').selectOption('f-software');
    await expect(page.locator('[data-checks-ready]')).toBeVisible({ timeout: 15_000 });
    await expect(page.locator('[data-publish]')).toBeEnabled();

    // BiDi: Arabic blocks are RTL, the English-first heading would be LTR, code is always LTR.
    const blocks = page.locator('[data-editor] > [data-block-id]');
    await expect(blocks.nth(0)).toHaveAttribute('dir', 'rtl');
    await expect(blocks.nth(1)).toHaveAttribute('dir', 'rtl');
    await expect(page.locator('[data-editor] [data-block-type="code"]')).toHaveAttribute('dir', 'ltr');
    await expect(page.locator('[data-editor] strong')).toHaveText('ASP.NET Core');
    await expect(page.locator('[data-editor] code.rd-inline-code')).toHaveText('DI');

    await page.locator('[data-title]').focus();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-article-editor')).toHaveScreenshot(`editor-${lang}-${theme}.png`, {
      stylePath: HIDE_APP_CHROME,
      mask: [page.locator('[data-save-status]')],
    });

    // Preview: the reader's layout, in the other theme too.
    await page.locator('[data-preview-toggle]').click();
    const preview = page.locator('rd-article-preview');
    await expect(preview.locator('h1')).toHaveText('يعني إيه Dependency Injection؟');
    await expect(preview.locator('rd-rdoc h3')).toHaveText('ليه نستخدمه؟'); // "## " is a subheading (H1 is the title)
    const other = theme === 'light' ? 'dark' : 'light';
    await page.locator('[data-preview-theme]').getByRole('radio').nth(other === 'light' ? 0 : 1).click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', other);
    await page.locator('[data-preview-toggle]').click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', theme);

    // Publish → the article.
    const published = page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/publish'));
    await page.locator('[data-publish]').click();
    const result = await (await published).json();
    await page.waitForURL((url) => url.pathname === `/ar/a/${result.slug}`);
    await expect(page.locator('rd-article-page h1')).toHaveText('يعني إيه Dependency Injection؟');
    await expect(page.locator('rd-article-page rd-rdoc [data-block-type="code"]')).toContainText('AddScoped');

    // My articles → Published.
    await page.goto('/write?tab=published');
    await expect(page.locator('[data-my-article]')).toHaveCount(1);
    await expect(page.locator('[data-my-article] [data-my-title]')).toHaveText('يعني إيه Dependency Injection؟');
  });

  test(`the tab title, and the preview's health disclaimer for a sensitive field — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsAuthor(page, request, variant, 'fresh');
    await page.goto('/write/new');
    await editorReady(page);
    await expect(page).toHaveTitle(ar ? 'مقال جديد — ReadIn' : 'New article — ReadIn');
    await page.locator('[data-title]').fill('How sleep turns reading into memory');
    await expect(page).toHaveTitle('How sleep turns reading into memory — ReadIn');

    // Software: no disclaimer in the preview.
    await page.locator('[data-field]').selectOption('f-software');
    await page.locator('[data-preview-toggle]').click();
    const preview = page.locator('rd-article-preview');
    await expect(preview.locator('h1')).toHaveText('How sleep turns reading into memory');
    await expect(preview.locator('[data-health-disclaimer]')).toHaveCount(0);
    await page.locator('[data-preview-toggle]').click();

    // Medicine is sensitive: the preview shows the disclaimer readers will see, below the trust row.
    await page.locator('[data-field]').selectOption('f-medicine');
    await page.locator('[data-preview-toggle]').click();
    await expect(preview.locator('[data-health-disclaimer]')).toHaveText(
      ar ? 'المعلومات دي للتوعية ولا تغني عن استشارة الطبيب.' : "This information is for awareness only and is not a substitute for a doctor's advice.",
    );
  });

  test(`glossary term: select words, search the glossary, mark, change and remove — ${lang}/${theme}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsAuthor(page, request, variant, 'fresh');
    const savedDocument = trackSavedDocument(page);
    await page.goto('/write/new');
    await editorReady(page);
    await page.locator('[data-source-language]').getByRole('radio').first().click(); // Arabic
    await page.locator('[data-title]').fill('يعني إيه Dependency Injection؟');
    await typeInEditor(page, 'استخدم Dependency Injection في كل حتة.');

    // A caret isn't enough: the writer selects the words first.
    const termButton = page.locator('[data-toolbar] [data-term]');
    await expect(termButton).toBeDisabled();
    // Selects the words in the DOM (the text can be split over several text nodes); ProseMirror follows the selection.
    await page.locator('[data-editor] p').first().evaluate((paragraph, words) => {
      const walker = document.createTreeWalker(paragraph, NodeFilter.SHOW_TEXT);
      const nodes: Text[] = [];
      while (walker.nextNode()) nodes.push(walker.currentNode as Text);
      const at = (offset: number): [Text, number] => {
        for (const node of nodes) {
          if (offset <= node.length) return [node, offset];
          offset -= node.length;
        }
        throw new Error('offset');
      };
      const start = nodes.map((n) => n.data).join('').indexOf(words);
      const range = document.createRange();
      range.setStart(...at(start));
      range.setEnd(...at(start + words.length));
      getSelection()!.removeAllRanges();
      getSelection()!.addRange(range);
    }, 'Dependency Injection');
    await expect(termButton).toBeEnabled();
    await termButton.click();

    // The picker searches for the selected words.
    const bar = page.locator('[data-term-bar]');
    await expect(bar.locator('[data-term-for] bdi').first()).toHaveText('Dependency Injection');
    await expect(bar.locator('input[type="search"]')).toBeFocused();
    await expect(bar.locator('input[type="search"]')).toHaveValue('Dependency Injection');
    await expect(bar.locator('[data-term-option]')).toHaveCount(1);
    await expect(bar.locator('[data-term-option="dependency-injection"]')).toContainText('Dependency Injection');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(bar).toHaveScreenshot(`editor-term-picker-${lang}-${theme}.png`);

    // Another search, a miss, then the pick.
    await bar.locator('input[type="search"]').fill('ioc');
    await expect(bar.locator('[data-term-option]')).toHaveCount(1);
    await expect(bar.locator('[data-term-option="ioc-container"]')).toBeVisible();
    await bar.locator('input[type="search"]').fill('kubernetes');
    await expect(bar.locator('[data-term-status]')).toHaveText(ar ? 'مفيش مصطلح زي كده في القاموس. جرّب المصطلح بالإنجليزي.' : 'No glossary term matches. Try the English term.');
    await bar.locator('input[type="search"]').fill('dependency');
    await bar.locator('[data-term-option="dependency-injection"]').click();
    await expect(bar).toHaveCount(0);
    const term = page.locator('[data-editor] .rd-term');
    await expect(term).toHaveText('Dependency Injection');
    await expect(term).toHaveAttribute('data-term', 'dependency-injection');

    // The draft keeps it as an RDoc term node, with the spaces around it as text.
    await savedToServer(page);
    const paragraph = () => savedDocument().translations[0].content.blocks[0].content;
    expect(paragraph()).toEqual([
      { type: 'text', text: 'استخدم ' },
      { type: 'term', termId: 'dependency-injection', text: 'Dependency Injection' },
      { type: 'text', text: ' في كل حتة.' },
    ]);

    // Selecting the term opens it again: Remove term keeps the words as text.
    await term.click();
    await expect(termButton).toHaveAttribute('aria-pressed', 'true');
    await termButton.click();
    await expect(bar.locator('[data-term-for]')).toContainText('dependency-injection');
    await expect(bar.locator('[data-term-option="dependency-injection"]')).toHaveAttribute('aria-current', 'true');
    await bar.locator('[data-term-remove]').click();
    await expect(term).toHaveCount(0);
    await expect(page.locator('[data-editor] p').first()).toHaveText('استخدم Dependency Injection في كل حتة.');
  });
}

test.describe('published articles', () => {
  const variant = VARIANTS[1]; // en/dark

  test('edit a published article → Update; readers see the new version', async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const { published } = seededIds(me);
    await page.goto('/write?tab=published');
    await myArticle(page, published).locator('[data-edit-article]').click();
    await page.waitForURL((url) => url.pathname === `/write/${published}`);
    await editorReady(page);
    await expect(page.locator('[data-publish]')).toHaveText(/Update/);
    await expect(page.locator('[data-publish]')).toBeDisabled(); // readers already see this version

    await page.locator('[data-title]').fill('إزاي تكتب Unit Tests مفيدة فعلاً');
    await savedToServer(page);
    await expect(page.locator('[data-publish]')).toBeEnabled();
    await expect(page.locator('[data-discard]')).toBeVisible();

    const update = page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/publish'));
    await page.locator('[data-publish]').click();
    const result = await (await update).json();
    expect(result.firstPublish).toBe(false);
    expect(result.revision).toBe(2);
    await page.waitForURL((url) => url.pathname.endsWith(`/a/${result.slug}`));
    await expect(page.locator('rd-article-page h1')).toHaveText('إزاي تكتب Unit Tests مفيدة فعلاً');
  });

  test('discard the unpublished changes of a published article', async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const { changed } = seededIds(me);
    await page.goto(`/write/${changed}`);
    await editorReady(page);
    await expect(page.locator('[data-editor]')).toContainText('A second paragraph, not published yet.');

    await page.locator('[data-discard]').click();
    const sheet = page.locator('[data-confirm-sheet][data-confirm="discard"]');
    await expect(sheet).toBeVisible();
    await sheet.locator('[data-confirm-action]').click();
    await expect(sheet).toHaveCount(0);
    await expect(page.locator('[data-editor]')).not.toContainText('A second paragraph');
    await expect(page.locator('[data-discard]')).toHaveCount(0);
    await expect(page.locator('[data-publish]')).toBeDisabled();

    await page.goto('/write?tab=published');
    await expect(myArticle(page, changed).locator('[data-unpublished-chip]')).toHaveCount(0);
  });

  test('restore an earlier revision into the working copy, then Update', async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const { published } = seededIds(me);
    await page.goto(`/write/${published}`);
    await editorReady(page);

    // A second revision with a new title.
    await page.locator('[data-title]').fill('Unit tests that actually help');
    await savedToServer(page);
    const update = page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/publish'));
    await page.locator('[data-publish]').click();
    await update;
    await page.goto(`/write/${published}`);
    await editorReady(page);

    await page.locator('[data-history-toggle]').click();
    await expect(page.locator('[data-revision]')).toHaveCount(2);
    await page.locator('[data-revision="1"]').click();
    await expect(page.locator('[data-revisions] rd-article-preview h1')).toHaveText('إزاي تكتب Unit Tests مفيدة');
    await page.locator('[data-restore-revision]').click();
    await page.locator('[data-confirm-sheet][data-confirm="restore"] [data-confirm-action]').click();
    await expect(page.locator('[data-title]')).toHaveValue('إزاي تكتب Unit Tests مفيدة');
    await expect(page.locator('[data-publish]')).toBeEnabled(); // restored, not live until Update
    await expect(page.locator('[data-discard]')).toBeVisible();
  });

  test('two tabs: the second save is a conflict, and "keep mine" wins', async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const { draft } = seededIds(me);
    const other = await context.newPage();
    await restoreSessionAs(other, me);
    await page.goto(`/write/${draft}`);
    await other.goto(`/write/${draft}`);
    await editorReady(page);
    await editorReady(other);

    await other.locator('[data-title]').fill('Saved from the other tab');
    await savedToServer(other);
    await page.locator('[data-title]').fill('Saved from this tab');
    await expect(page.locator('[data-conflict]')).toBeVisible({ timeout: 25_000 });
    await page.locator('[data-conflict-keep]').click();
    await savedToServer(page);

    await other.reload();
    await editorReady(other);
    await expect(other.locator('[data-title]')).toHaveValue('Saved from this tab');
  });
});

test('RTL: per-block direction is automatic, can be overridden, and the toolbar mirrors', async ({ page, context, baseURL, request }) => {
  const variant = VARIANTS[0]; // ar/light
  await useVariant(context, baseURL!, variant);
  await signInAsAuthor(page, request, variant, 'fresh');
  await page.goto('/write/new');
  await editorReady(page);
  await page.locator('[data-source-language]').getByRole('radio').first().click();

  await typeInEditor(page, 'React ولا Angular؟ الاتنين كويسين.');
  const first = page.locator('[data-editor] > [data-block-id]').first();
  await expect(first).toHaveAttribute('dir', 'ltr'); // the first strong character is Latin (shared BiDi fixture)
  await expect(first.locator('bdi').first()).toHaveText('ولا'); // Arabic inside an LTR block is isolated

  // Manual override: RTL, then back to automatic.
  await page.locator('[data-dir-option="rtl"]').click();
  await expect(first).toHaveAttribute('dir', 'rtl');
  await expect(first.locator('bdi').first()).toHaveText('React');
  await page.locator('[data-dir-option="auto"]').click();
  await expect(first).toHaveAttribute('dir', 'ltr');

  // The editor area follows the article language; undo/redo icons mirror in RTL.
  await expect(page.locator('[data-editor-surface]')).toHaveAttribute('dir', 'rtl');
  await expect(page.locator('[data-toolbar] svg.rd-flip-rtl').first()).toHaveCSS('transform', 'matrix(-1, 0, 0, 1, 0, 0)');
});
