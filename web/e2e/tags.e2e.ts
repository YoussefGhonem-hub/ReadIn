import { Locator, Page, expect, test } from '@playwright/test';
import { editorReady, problemCodes, savedToServer, signInAsAuthor, trackSavedDocument, typeInEditor } from './support/editor';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, useVariant } from './support/mock-api';

/**
 * F32 Tags end to end in ar/light and en/dark: a tag page (server-rendered with its title, canonical and article count,
 * post cards, infinite scroll to the end), tag links on post cards and in the reader, an empty tag (noindex), a missing
 * or hidden tag (404), and the editor's tag field (suggestions, a new tag, the rules, at most 5, a hidden tag flagged
 * by the checks). The mock API (e2e/mock-api/tags.mjs) has 23 notes tagged `C#` (two pages of 20), `dotnet` on two
 * articles, `عادات` on one, an empty `kotlin` and a hidden `spam-links`.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** Cards say how long ago each article was published: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');

const cards = (page: Page): Locator => page.locator('[data-tag-articles] rd-post-card');

async function openTag(page: Page, path: string) {
  await page.clock.setFixedTime(NOW);
  const response = await page.goto(path);
  await expect(page.locator('[data-tag-header], [data-tag-not-found]').first()).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle'); // hydrated: links and infinite scroll respond
  return response!;
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`tag page: server-rendered, "#name" and its count, post cards, infinite scroll to the end — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const response = await openTag(page, '/tags/csharp');
    expect(response.status()).toBe(200);
    const html = await response.text();
    expect(html).toContain('<title>#C# — ReadIn</title>');
    expect(html).toMatch(/<link rel="canonical" href="[^"]*\/tags\/csharp"/);
    expect(html).not.toContain('noindex');
    expect(html).toContain('data-post-card="a-csharp-note-1"');

    await expect(page.locator('[data-tag-name]')).toHaveText('#C#');
    await expect(page.locator('[data-tag-name]')).toHaveAttribute('dir', 'auto');
    await expect(page.locator('[data-tag-count]')).toHaveText(t('23 مقالًا', '23 articles'));
    // Newest first, from every writer; a hidden tag (`spam-links` on note 4) is left off its card.
    await expect(cards(page)).toHaveCount(20);
    await expect(cards(page).first()).toHaveAttribute('data-post-card', 'a-csharp-note-1');
    await expect(page.locator('rd-post-card[data-post-card="a-csharp-note-4"] [data-card-tags] a')).toHaveText(['#C#']);
    await expect(page.locator('[data-tag-end]')).toHaveCount(0);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`tag-page-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Near the end the next cursor page loads, then the list says that was all.
    await cards(page).last().scrollIntoViewIfNeeded();
    await expect(cards(page)).toHaveCount(23);
    await expect(page.locator('[data-tag-end]')).toHaveText(t('اطّلعت على كل المقالات التي تحمل هذا الوسم.', "You've seen every article with this tag."));
  });

  test(`tag links: a card's tag on Home and a tag in the reader open the tag page — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOW);
    await page.goto('/');
    const di = page.locator('rd-post-card[data-post-card="a-dependency-injection-ar"]').first();
    await expect(di).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');

    // `dotnet` is on the article and on a C# note by another writer: both, newest first.
    await di.locator('[data-card-tag="dotnet"]').click();
    await page.waitForURL((url) => url.pathname === '/tags/dotnet');
    await expect(page.locator('[data-tag-name]')).toHaveText('#dotnet');
    await expect(page.locator('[data-tag-count]')).toHaveText(t('مقالان', '2 articles'));
    await expect(cards(page)).toHaveCount(2);
    expect(await cards(page).evaluateAll((list) => list.map((c) => c.getAttribute('data-post-card')))).toEqual(['a-dependency-injection-ar', 'a-csharp-note-1']);
    await expect(page).toHaveTitle('#dotnet — ReadIn');

    // An Arabic tag in the reader: its slug is percent-encoded in the URL; Back returns to the article.
    await page.goto('/ar/a/readin-streaks-ar');
    const tag = page.locator('[data-article-tags] a', { hasText: '#عادات' });
    await expect(tag).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(tag).toHaveAttribute('href', `/tags/${encodeURIComponent('عادات')}`);
    await page.waitForLoadState('networkidle');
    await tag.click();
    await page.waitForURL((url) => decodeURIComponent(url.pathname) === '/tags/عادات');
    await expect(page.locator('[data-tag-name]')).toHaveText('#عادات');
    await expect(page.locator('[data-tag-count]')).toHaveText(t('مقال واحد', '1 article'));
    await expect(cards(page)).toHaveCount(1);
    await page.locator('[data-tag-back]').click();
    await page.waitForURL((url) => url.pathname === '/ar/a/readin-streaks-ar');
  });

  test(`an empty tag is noindex; a missing or hidden tag is a 404 — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const empty = await openTag(page, '/tags/kotlin');
    expect(empty.status()).toBe(200);
    expect(await empty.text()).toMatch(/<meta name="robots" content="noindex"/);
    await expect(page.locator('[data-tag-count]')).toHaveText(t('0 مقال', '0 articles'));
    await expect(page.locator('[data-tag-empty] h3')).toHaveText(t('لا توجد مقالات تحمل هذا الوسم بعد', 'No articles with this tag yet'));

    for (const path of ['/tags/no-such-tag', '/tags/spam-links']) {
      const missing = await openTag(page, path);
      expect(missing.status(), path).toBe(404);
      expect(await missing.text()).toMatch(/<meta name="robots" content="noindex"/);
      await expect(page.locator('[data-tag-not-found] h3')).toHaveText(t('هذا الوسم غير موجود', "This tag doesn't exist"));
    }
  });

  test(`editor tag field: suggestions, a new tag, the rules, at most 5 and a hidden tag — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsAuthor(page, request, variant, 'fresh');
    const saved = trackSavedDocument(page);
    await page.goto('/write/new');
    await editorReady(page);
    await page.locator('[data-title]').fill('Tags in ReadIn');
    await typeInEditor(page, 'A short post about tags.');
    await page.locator('[data-field]').selectOption('f-software');

    const tags = page.locator('#ed-tags');
    const field = tags.locator('[data-tag-input]');
    const chips = tags.locator('[data-tag]');
    const create = tags.locator('[data-tag-create]');

    // Existing tags while typing, most used first; the keyboard picks one.
    await field.fill('c');
    await expect(tags.locator('[data-tag-option]').first()).toHaveAttribute('data-tag-option', 'C#');
    expect(await tags.locator('[data-tag-option]').evaluateAll((list) => list.map((o) => o.getAttribute('data-tag-option')))).toEqual([
      'C#',
      'C++',
      'ASP.NET Core',
      'cheatsheet',
      'CI/CD',
    ]);
    await field.press('ArrowDown');
    await field.press('Enter');
    await expect(chips).toHaveText(['#C#']);

    // An existing tag older than the rules is added as it is.
    await field.fill('ci');
    await tags.locator('[data-tag-option="CI/CD"]').click();
    await expect(chips).toHaveText(['#C#', '#CI/CD']);

    // A new name follows the rules, with the reason inline.
    await field.fill('a/b');
    await expect(tags.locator('[data-tag-problem]')).toHaveText(t('يقبل الوسم الحروف والأرقام والمسافات و ⁦- _ . + #⁩ فقط.', 'Use only letters, digits, spaces and - _ . + # in a tag.'));
    await expect(field).toHaveAttribute('aria-invalid', 'true');

    // No tag is "Clean Code" yet: the list offers to create it.
    await field.fill('#Clean   Code');
    await expect(create).toHaveAttribute('data-tag-create', 'Clean Code');
    await expect(create).toContainText(t('إنشاء وسم جديد:', 'Create new tag:'));
    await expect(tags.locator('[data-tag-problem]')).toHaveCount(0);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-metadata-panel')).toHaveScreenshot(`editor-tags-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await create.click();
    await expect(chips).toHaveText(['#C#', '#CI/CD', '#Clean Code']);

    // A hidden tag is never suggested; added anyway, the checks flag it after the save.
    await field.fill('spam-links');
    await expect(create).toHaveAttribute('data-tag-create', 'spam-links');
    await field.press('Enter');
    // "ai" is the existing "AI": a comma adds that spelling. Five tags: the input is disabled.
    await field.fill('ai');
    await expect(tags.locator('[data-tag-option="AI"]')).toBeVisible();
    await field.press(',');
    await expect(chips).toHaveText(['#C#', '#CI/CD', '#Clean Code', '#spam-links', '#AI']);
    await expect(field).toBeDisabled();
    await expect(tags.locator('[data-tags-hint]')).toContainText(t('هذه 5 وسوم', "That's 5 tags"));

    await savedToServer(page);
    await expect.poll(() => problemCodes(page), { timeout: 15_000 }).toEqual(['tag.hidden']);
    await expect(page.locator('[data-problem="tag.hidden"] [data-problem-tag]')).toHaveText('#spam-links');
    await expect(tags.locator('[data-flagged]')).toHaveAttribute('data-tag', 'spam-links');
    // The problem jumps to the chip's remove button: Enter removes it, and the input is back.
    await page.locator('[data-problem="tag.hidden"]').click();
    await expect(tags.locator('[data-tag="spam-links"] [data-tag-remove]')).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(chips).toHaveText(['#C#', '#CI/CD', '#Clean Code', '#AI']);
    await expect(field).toBeEnabled();
    await expect(page.locator('[data-checks-ready]')).toBeVisible({ timeout: 25_000 });
    expect(saved().tags).toEqual(['C#', 'CI/CD', 'Clean Code', 'AI']);
  });
}
