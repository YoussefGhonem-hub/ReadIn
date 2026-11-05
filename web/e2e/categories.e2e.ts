import { Locator, Page, expect, test } from '@playwright/test';
import { editorReady, seededIds, signInAsAuthor } from './support/editor';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, parkMouse, useVariant } from './support/mock-api';
import { signInAsModerator } from './support/moderation';
import { openProfile } from './support/profile';

/**
 * F31 Writer categories end to end in ar/light and en/dark: a writer's Categories tab as a guest (non-empty categories
 * in the writer's order, then "مقالات تانية"), the category pages (server-rendered with their title and canonical, an
 * Arabic slug, `_other`, an empty one with noindex, a 404), the reader's "في قسم {name}" link, your own tab (create,
 * the name rules, rename, reorder by keyboard and by dragging, delete with the article count), the editor's picker
 * (applied at once, "＋ قسم جديد", a new article saved first) and a moderator clearing an offensive name. The mock API
 * (e2e/mock-api/categories.mjs) keeps each writer's categories, so every owner test signs in as its own writer.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;
/** Cards say how long ago each article was published: a fixed clock keeps the shots stable. */
const NOW = new Date('2026-11-04T09:00:00Z');

const names = (rows: Locator) => rows.locator('[data-category-name]');

/**
 * Opens a page, waits for its content and for hydration (links and buttons respond). Returns the status and the
 * server-rendered HTML, read at once (the browser may drop the body later).
 */
async function open(page: Page, path: string, ready: string): Promise<{ status: number; html: string }> {
  await page.clock.setFixedTime(NOW);
  const response = (await page.goto(path))!;
  const html = await response.text();
  await expect(page.locator(ready).first()).toBeVisible({ timeout: FIRST_RENDER_MS });
  await page.waitForLoadState('networkidle');
  return { status: response.status(), html };
}

/** The profile's Categories tab (its own chunk, loaded when the tab opens). */
async function openCategoriesTab(page: Page): Promise<void> {
  await page.locator('[data-profile-tab="categories"]').click();
  await expect(page.locator('[data-profile-categories] [data-category-card], [data-manage-categories] [data-category-row], [data-categories-empty]').first()).toBeVisible({
    timeout: FIRST_RENDER_MS,
  });
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const t = (ar: string, en: string) => (lang === 'ar' ? ar : en);

  test(`Categories tab as a guest: the writer's order, "مقالات تانية" last, empty ones hidden — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await open(page, '/@mona', '[data-profile-header]');
    const tabs = page.locator('[data-profile-tab]');
    await expect(tabs).toHaveText(t('المقالات الأقسام المسارات نبذة', 'Articles Categories Paths About').split(' '));
    await openCategoriesTab(page);

    const cards = page.locator('[data-profile-categories] [data-category-card]');
    await expect(cards).toHaveCount(3);
    // Mona's empty "أفكار جاية" is hers alone to see.
    expect(await cards.evaluateAll((list) => list.map((c) => c.getAttribute('data-category-card')))).toEqual(['asp-net-core', 'نصايح-البرمجة', '_other']);
    await expect(cards.locator('[data-category-card-name]')).toHaveText(['ASP.NET Core', 'نصايح البرمجة', t('مقالات تانية', 'Other articles')]);
    await expect(cards.locator('[data-category-card-count]')).toHaveText([t('مقالين', '2 articles'), t('مقال واحد', '1 article'), t('مقال واحد', '1 article')]);
    await expect(cards.first().locator('[data-category-card-name]')).toHaveAttribute('dir', 'auto');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('[data-profile-categories]')).toHaveScreenshot(`categories-tab-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // An Arabic slug travels percent-encoded.
    await cards.nth(1).click();
    await page.waitForURL((url) => url.pathname === `/@mona/c/${encodeURIComponent('نصايح-البرمجة')}`);
    await expect(page.locator('[data-category-name]')).toHaveText('نصايح البرمجة', { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-category-articles] rd-post-card')).toHaveCount(1);
    await expect(page).toHaveTitle('نصايح البرمجة · Mona Adel — ReadIn');
    // The writer's name leads back to the profile.
    await page.locator('[data-category-author]').click();
    await page.waitForURL((url) => url.pathname === '/@mona');

    // Karim has articles but no categories: the empty state, not "مقالات تانية" alone (it would repeat Articles).
    await open(page, '/@karim', '[data-profile-header]');
    await openCategoriesTab(page);
    await expect(page.locator('[data-profile-categories] [data-categories-empty]')).toContainText(
      t('لما الكاتب ده يرتّب مقالاته في أقسام، هتلاقيها هنا.', "When this writer groups their articles into categories, you'll find them here."),
    );
    await expect(page.locator('[data-profile-categories] [data-category-card]')).toHaveCount(0);
  });

  test(`category pages: server-rendered, the writer, the count and post cards; _other, empty and missing ones — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const { status, html } = await open(page, '/@mona/c/asp-net-core', '[data-category-header]');
    expect(status).toBe(200);
    expect(html).toContain('<title>ASP.NET Core · Mona Adel — ReadIn</title>');
    expect(html).toMatch(/<link rel="canonical" href="[^"]*\/@mona\/c\/asp-net-core"/);
    expect(html).not.toContain('noindex');
    expect(html).toContain('data-post-card="a-dependency-injection-ar"');

    await expect(page.locator('[data-category-name]')).toHaveText('ASP.NET Core');
    await expect(page.locator('[data-category-count]')).toHaveText(t('مقالين', '2 articles'));
    await expect(page.locator('[data-category-author]')).toContainText('Mona Adel');
    const cards = page.locator('[data-category-articles] rd-post-card');
    await expect(cards).toHaveCount(2);
    // Newest first.
    expect(await cards.evaluateAll((list) => list.map((c) => c.getAttribute('data-post-card')))).toEqual(['a-dependency-injection-ar', 'a-aspnet-core-cheatsheet']);
    await expect(page.locator('[data-category-end]')).toBeVisible();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`category-page-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // The slug is matched ignoring case; the canonical URL has the real one.
    const upper = await open(page, '/@mona/c/ASP-NET-Core', '[data-category-header]');
    expect(upper.status).toBe(200);
    expect(upper.html).toMatch(/<link rel="canonical" href="[^"]*\/@mona\/c\/asp-net-core"/);

    // "مقالات تانية": the articles without a category.
    await open(page, '/@mona/c/_other', '[data-category-header]');
    await expect(page.locator('[data-category-name]')).toHaveText(t('مقالات تانية', 'Other articles'));
    await expect(page.locator('[data-category-articles] rd-post-card')).toHaveCount(1);
    await expect(page.locator('[data-category-articles] rd-post-card')).toHaveAttribute('data-post-card', 'a-one-photo');
    await expect(page).toHaveTitle(t('مقالات تانية · Mona Adel — ReadIn', 'Other articles · Mona Adel — ReadIn'));

    // An empty category answers (its owner links to it), with the empty state, and is not indexed.
    const empty = await open(page, `/@mona/c/${encodeURIComponent('أفكار-جاية')}`, '[data-category-empty]');
    expect(empty.status).toBe(200);
    expect(empty.html).toContain('noindex');
    await expect(page.locator('[data-category-empty] a')).toHaveAttribute('href', '/@mona');

    // A slug the writer doesn't have is a real 404.
    const missing = await open(page, '/@mona/c/no-such-category', '[data-category-not-found]');
    expect(missing.status).toBe(404);
    await expect(page.locator('[data-category-not-found]')).toContainText(t('القسم ده مش موجود', "This category doesn't exist"));
    await expect(page.locator('[data-category-not-found] a')).toHaveAttribute('href', '/@mona');
  });

  test(`reader: the byline's "في قسم {name}" opens the category page — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await open(page, '/ar/a/dependency-injection-ar', '[data-byline]');
    const link = page.locator('[data-byline] [data-article-category]');
    await expect(link).toHaveText(t('في قسم ⁨ASP.NET Core⁩', 'In ⁨ASP.NET Core⁩'));
    await expect(link).toHaveAttribute('href', '/@mona/c/asp-net-core');
    await link.click();
    await page.waitForURL((url) => url.pathname === '/@mona/c/asp-net-core');
    await expect(page.locator('[data-category-name]')).toHaveText('ASP.NET Core', { timeout: FIRST_RENDER_MS });

    // An article without a category says nothing.
    await open(page, '/en/a/one-photo', '[data-byline]');
    await expect(page.locator('[data-byline] [data-article-category]')).toHaveCount(0);
  });

  test(`your Categories tab: create, the name rules, rename, reorder (keyboard and drag), delete with the count — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(NOW);
    await signInAsAuthor(page, request, variant);
    // A writer's own profile in the mock is "Sara Hassan" (@sara).
    await openProfile(page, '/@sara', { signedIn: true });
    await openCategoriesTab(page);

    const manage = page.locator('[data-manage-categories]');
    const rows = manage.locator('[data-category-row]');
    await expect(names(rows)).toHaveText(['ASP.NET Core', 'Clean Code بالعربي', 'أفكار جاية']);
    // Empty ones too (the draft in "Clean Code بالعربي" doesn't count), marked as hidden from visitors, then "مقالات تانية".
    const hidden = t('فاضي، والزوار مش شايفينه', "Empty: visitors don't see it");
    await expect(rows.locator('[data-category-count]')).toHaveText([t('مقال واحد', '1 article'), hidden, hidden]);
    await expect(manage.locator('[data-category-card="_other"] [data-category-card-count]')).toHaveText(t('مقال واحد', '1 article'));
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(manage).toHaveScreenshot(`categories-manage-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Create: a name you already have (case and spelling ignored) is caught as you type; a good one is added last.
    const create = manage.locator('[data-category-create]');
    const field = create.locator('[data-category-name-input]');
    await field.fill('asp.net CORE');
    await expect(create.locator('[data-category-name-error]')).toHaveText(t('عندك قسم بنفس الاسم بالفعل.', 'You already have a category with this name.'));
    await expect(create.locator('[data-category-name-submit]')).toBeDisabled();
    await field.fill('!!!');
    await expect(create.locator('[data-category-name-error]')).toHaveText(t('اسم القسم لازم يكون فيه حرف أو رقم على الأقل.', 'A category name needs at least one letter or digit.'));
    const posted = page.waitForRequest((r) => r.method() === 'POST' && r.url().endsWith('/me/categories'));
    await field.fill('  Docker   🐳 ');
    await field.press('Enter');
    expect((await posted).postDataJSON()).toEqual({ name: 'Docker 🐳' });
    await expect(names(rows)).toHaveText(['ASP.NET Core', 'Clean Code بالعربي', 'أفكار جاية', 'Docker 🐳']);
    await expect(field).toHaveValue('');

    // Rename in place; the slug (and every link) stays.
    const clean = rows.nth(1);
    const link = await clean.locator('[data-category-link]').getAttribute('href');
    await clean.locator('[data-category-rename]').click();
    const rename = clean.locator('[data-category-name-input]');
    await expect(rename).toBeFocused();
    await expect(rename).toHaveValue('Clean Code بالعربي');
    await rename.fill('Clean Code');
    await rename.press('Enter');
    await expect(names(rows)).toHaveText(['ASP.NET Core', 'Clean Code', 'أفكار جاية', 'Docker 🐳']);
    await expect(rows.nth(1).locator('[data-category-link]')).toHaveAttribute('href', link!);
    await expect(rows.nth(1).locator('[data-category-rename]')).toBeFocused();

    // Keyboard: "move up" moves it and keeps focus on the same button of the moved row.
    const order = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith('/me/categories/order'));
    await rows.nth(3).locator('[data-move="up"]').focus();
    await page.keyboard.press('Enter');
    expect(((await order).postDataJSON() as { categoryIds: string[] }).categoryIds).toHaveLength(4);
    await expect(names(rows)).toHaveText(['ASP.NET Core', 'Clean Code', 'Docker 🐳', 'أفكار جاية']);
    await expect(rows.nth(2).locator('[data-move="up"]')).toBeFocused();

    // Drag "أفكار جاية" by its handle to the top.
    const handle = rows.nth(3).locator('[data-category-drag]');
    const from = (await handle.boundingBox())!;
    const to = (await rows.nth(0).boundingBox())!;
    await page.mouse.move(from.x + from.width / 2, from.y + from.height / 2);
    await page.mouse.down();
    await page.mouse.move(from.x + from.width / 2, from.y + from.height / 2 - 10, { steps: 5 });
    await page.mouse.move(from.x + from.width / 2, to.y + 4, { steps: 20 });
    await page.mouse.up();
    await expect(names(rows)).toHaveText(['أفكار جاية', 'ASP.NET Core', 'Clean Code', 'Docker 🐳']);

    // Delete asks first, with the article count; its article joins "مقالات تانية".
    await rows.nth(1).locator('[data-category-delete]').click();
    const sheet = page.locator('[data-category-delete-sheet]');
    await expect(sheet.locator('[data-category-delete-body]')).toHaveText(
      t('القسم ده فيه مقال واحد، وهيفضل منشور من غير قسم.', 'This category has 1 article. It stays published, without a category.'),
    );
    await sheet.locator('[data-category-delete-confirm]').click();
    await expect(sheet).toHaveCount(0);
    await expect(names(rows)).toHaveText(['أفكار جاية', 'Clean Code', 'Docker 🐳']);
    await expect(manage.locator('[data-category-card="_other"] [data-category-card-count]')).toHaveText(t('مقالين', '2 articles'));

    // The server kept all of it.
    await openProfile(page, '/@sara', { signedIn: true });
    await openCategoriesTab(page);
    await expect(names(page.locator('[data-manage-categories] [data-category-row]'))).toHaveText(['أفكار جاية', 'Clean Code', 'Docker 🐳']);

    // With none left: the "رتّب مقالاتك" empty view holds the create field, and "مقالات تانية" waits for a category
    // (as visitors see it), though two articles have none.
    const left = page.locator('[data-manage-categories] [data-category-row]');
    for (let remaining = 3; remaining > 0; remaining--) {
      await left.first().locator('[data-category-delete]').click();
      await page.locator('[data-category-delete-sheet] [data-category-delete-confirm]').click();
      await expect(page.locator('[data-category-delete-sheet]')).toHaveCount(0);
      await expect(left).toHaveCount(remaining - 1);
    }
    const empty = page.locator('[data-manage-categories] [data-categories-empty]');
    await expect(empty).toContainText(t('رتّب مقالاتك', 'Organize your articles'));
    await expect(empty.locator('[data-category-create] [data-category-name-input]')).toBeVisible();
    await expect(page.locator('[data-manage-categories] [data-category-card="_other"]')).toHaveCount(0);
    await expect(page.locator('[data-manage-categories] [data-categories-hint]')).toHaveCount(0);
  });

  test(`editor: the القسم picker applies at once, "＋ قسم جديد" creates one, a new article is saved first — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    const me = await signInAsAuthor(page, request, variant);
    const { published } = seededIds(me);
    await page.goto(`/write/${published}`);
    await editorReady(page);

    const picker = page.locator('[data-category-picker]');
    const select = picker.locator('[data-category-select]');
    await expect(select).toBeEnabled({ timeout: FIRST_RENDER_MS });
    await expect(select.locator('option')).toHaveText([t('من غير قسم', 'No category'), 'ASP.NET Core', 'Clean Code بالعربي', 'أفكار جاية', t('＋ قسم جديد', '＋ New category')]);
    await expect(select).toHaveValue('');

    // A pick is sent at once: no save, nothing to Update.
    const put = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith(`/articles/${published}/category`));
    await select.selectOption(`${me.id}-c1`);
    expect((await put).postDataJSON()).toEqual({ categoryId: `${me.id}-c1` });
    await expect(picker.locator('[data-category-hint]')).toHaveText(t('اختياري: بيجمّع المقال مع مقالات زيه في بروفايلك. أي تغيير بيتطبق على طول.', 'Optional: groups the article with others on your profile. A change applies right away.'));
    await expect(page.locator('[data-publish]')).toBeDisabled();

    // "＋ قسم جديد": name it right there; it is created, then picked.
    await select.selectOption('__new');
    const create = picker.locator('[data-category-create]');
    const field = create.locator('[data-category-name-input]');
    await expect(field).toBeFocused();
    await expect(select).toHaveValue(`${me.id}-c1`);
    await field.fill('Testing');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(picker).toHaveScreenshot(`editor-category-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    const created = page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/me/categories'));
    const picked = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith(`/articles/${published}/category`));
    await field.press('Enter');
    const category = (await (await created).json()) as { id: string };
    expect((await picked).postDataJSON()).toEqual({ categoryId: category.id });
    await expect(create).toHaveCount(0);
    await expect(select).toHaveValue(category.id);

    // Kept by the server (it is the article's, not the draft's).
    await page.reload();
    await editorReady(page);
    await expect(page.locator('[data-category-select]')).toHaveValue(category.id, { timeout: FIRST_RENDER_MS });

    // A new article: picking a category saves it first (POST /articles), then sets it.
    await page.goto('/write/new');
    await editorReady(page);
    const fresh = page.locator('[data-category-select]');
    await expect(fresh).toBeEnabled({ timeout: FIRST_RENDER_MS });
    const saved = page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/api/v1/articles'));
    const set = page.waitForRequest((r) => r.method() === 'PUT' && /\/articles\/[^/]+\/category$/.test(r.url()));
    await fresh.selectOption(`${me.id}-c3`);
    const article = (await (await saved).json()) as { id: string };
    expect(new URL((await set).url()).pathname).toBe(`/api/v1/articles/${article.id}/category`);
    await page.waitForURL((url) => url.pathname === `/write/${article.id}`);
    await expect(fresh).toHaveValue(`${me.id}-c3`);
  });

  test(`moderation: a reported user's categories, and clearing an offensive name — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00Z'));
    await signInAsModerator(page, request, variant);
    await page.goto('/moderation/user/u-reader-21');
    const section = page.locator('[data-case-categories]');
    await expect(section.locator('[data-case-category]')).toHaveCount(2, { timeout: FIRST_RENDER_MS });
    await expect(section.locator('[data-case-category-name]')).toHaveText(['مقالات للأغبيا بس', 'Notes']);

    await section.locator('[data-case-category="c-dina-rude"] [data-case-clear-category]').click();
    const sheet = page.locator('[data-moderation-sheet]');
    await expect(sheet).toHaveAttribute('data-moderation-action', 'clear_category');
    const sent = page.waitForRequest((r) => r.method() === 'POST' && r.url().endsWith('/moderation/actions'));
    await sheet.locator('[data-moderation-confirm]').click();
    expect((await sent).postDataJSON()).toEqual({ action: 'clear_category', targetType: 'user', targetId: 'u-reader-21', categoryId: 'c-dina-rude' });
    await expect(sheet).toHaveCount(0);
    await expect(page.locator('rd-toast-host')).toContainText(t('اسم القسم اتمسح', 'Category name cleared'));
    await expect(section.locator('[data-case-category-name]')).toHaveText(['قسم 1', 'Notes']);
    // Logged with the old name; the case's reports are resolved.
    const entry = page.locator('[data-case-history] [data-log-entry]').first();
    await expect(entry).toHaveAttribute('data-log-action', 'user.clear_category');
    await expect(entry).toContainText('مقالات للأغبيا بس');
    await expect(page.locator('[data-case-status]')).toHaveText(t('اتحل', 'Resolved'));
  });
}
