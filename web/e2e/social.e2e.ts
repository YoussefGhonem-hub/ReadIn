import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, HIDE_COMMENTS, VARIANTS, hasScreenshot, imagesLoaded, parkMouse, useVariant } from './support/mock-api';
import { expectSignInPrompt, openArticle, signInAsReader } from './support/social';

/**
 * Wave 1 social features end to end in ar/en × light/dark (SPEC F10 reactions, F12 follow, F13 saved): react, change and
 * remove a reaction (tap, picker, keyboard), who reacted; save, add to collections, follow and unfollow in the reader;
 * the Following tab and its suggested writers; the Saved page's chips, search and collections; the guests' sign-in
 * prompts. The mock API keeps the state per test reader (e2e/support/social.ts), so reloads show what the server saved.
 */
test.describe.configure({ timeout: 90_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

/** The reader's action bar plus the room above it, where the reaction picker opens. */
async function pickerArea(page: Page) {
  const box = (await page.locator('rd-article-action-bar').boundingBox())!;
  return { x: 0, y: box.y - 96, width: box.width, height: box.height + 96 };
}

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const suffix = `${lang}-${theme}`;

  test(`reader: react, change, remove, who reacted — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/react-server-components-explained');

    const bar = page.locator('rd-article-action-bar');
    const react = bar.locator('[data-react]');
    const total = bar.locator('[data-reaction-total]');
    const picker = bar.locator('[data-reaction-picker]');
    await expect(total).toHaveText('18');
    await expect(react).not.toHaveAttribute('data-my-reaction');

    // A tap reacts 💡.
    await react.click();
    await expect(react).toHaveAttribute('data-my-reaction', 'insightful');
    await expect(total).toHaveText('19');

    // The picker shows the four reactions with their counts; pick ❤️.
    await bar.locator('[data-reaction-picker-toggle]').click();
    await expect(picker).toBeVisible();
    await expect(picker.locator('[data-reaction="insightful"]')).toHaveAttribute('aria-checked', 'true');
    await expect(picker.locator('[data-reaction-count="insightful"]')).toHaveText('9');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`reaction-picker-${suffix}.png`, {
      clip: await pickerArea(page),
      stylePath: [HIDE_APP_CHROME, HIDE_COMMENTS],
    });
    await picker.locator('[data-reaction="love"]').click();
    await expect(picker).toHaveCount(0);
    await expect(react).toHaveAttribute('data-my-reaction', 'love');
    await expect(total).toHaveText('19');

    // The server kept it.
    await openArticle(page, '/en/a/react-server-components-explained');
    await expect(react).toHaveAttribute('data-my-reaction', 'love');

    // Keyboard: ArrowUp opens the picker on your reaction, arrows follow the reading direction, Enter picks.
    await react.focus();
    await page.keyboard.press('ArrowUp');
    await expect(picker.locator('[data-reaction="love"]')).toBeFocused();
    await page.keyboard.press(dir === 'rtl' ? 'ArrowLeft' : 'ArrowRight');
    await expect(picker.locator('[data-reaction="fire"]')).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(react).toHaveAttribute('data-my-reaction', 'fire');
    await expect(react).toBeFocused();

    // Tapping your reaction removes it. The removal goes out once the 🔥 request ends, so who reacted waits for it.
    const removed = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().endsWith('/reaction'));
    await react.click();
    await expect(react).not.toHaveAttribute('data-my-reaction');
    await expect(total).toHaveText('18');
    await removed;

    // Who reacted: everyone, and a tab per reaction with its count.
    await bar.locator('[data-reactions-summary]').click();
    const sheet = page.locator('[data-reactors-sheet]');
    await expect(sheet.locator('[data-reactor]')).toHaveCount(18);
    await expect(sheet.locator('[role="tab"]')).toHaveCount(5);
    await expect(sheet.locator('[data-reactors-tab="fire"]')).toContainText('5');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-reactors-sheet section[role="dialog"]')).toHaveScreenshot(`who-reacted-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await sheet.locator('[data-reactors-tab="fire"]').click();
    await expect(sheet.locator('[data-reactor]')).toHaveCount(5);
    await expect(sheet.locator('[data-reactors-tab="fire"]')).toHaveAttribute('aria-selected', 'true');
  });

  test(`reader: save, add to collections, follow — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/one-photo');

    const save = page.locator('rd-article-action-bar [data-save]');
    const follow = page.locator('[data-author-follow] [data-follow]');
    await expect(save).toHaveAttribute('aria-pressed', 'false');
    await save.click();
    await expect(save).toHaveAttribute('aria-pressed', 'true');

    // Add to collection: tick one, and create another (the article goes straight into it).
    await page.locator('[data-add-to-collection]').click();
    const collections = page.locator('[data-collection-picker]');
    const interview = collections.locator('[data-collection="c-interview"]');
    await expect(collections.locator('[data-collection]')).toHaveCount(2);
    await interview.locator('input').check();
    await expect(interview).toContainText(lang === 'ar' ? '3 مقالات' : '3 articles');
    await collections.locator('[data-new-collection]').click();
    await collections.locator('#new-collection-name').fill('Deep work');
    await collections.locator('[data-create-collection]').click();
    const deepWork = collections.locator('[data-collection]', { hasText: 'Deep work' });
    await expect(deepWork.locator('input')).toBeChecked();
    await expect(deepWork).toContainText(lang === 'ar' ? 'مقال واحد' : '1 article');
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-collection-picker-sheet section[role="dialog"]')).toHaveScreenshot(`add-to-collection-${suffix}.png`, {
      stylePath: HIDE_APP_CHROME,
    });
    await collections.locator('[data-collections-done]').click();
    await expect(collections).toHaveCount(0);

    // Follow the author.
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await expect(follow).toContainText(lang === 'ar' ? 'بتتابعه' : 'Following');

    // The server kept all of it: the sheet comes back ticked from ArticleDetailsDto.collectionIds.
    await openArticle(page, '/en/a/one-photo');
    await expect(save).toHaveAttribute('aria-pressed', 'true');
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    await page.locator('[data-add-to-collection]').click();
    await expect(interview.locator('input')).toBeChecked();
    await expect(deepWork.locator('input')).toBeChecked();
    await expect(collections.locator('[data-collection="c-weekend"] input')).not.toBeChecked();
    await collections.locator('[data-collections-done]').click();

    // Unfollow and unsave; unsaving also takes the article out of its collections.
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    const unsaved = page.waitForResponse((r) => r.request().method() === 'DELETE' && r.url().endsWith('/me/saved/a-one-photo'));
    await save.click();
    await expect(save).toHaveAttribute('aria-pressed', 'false');
    await unsaved;
    await openArticle(page, '/en/a/one-photo');
    await expect(follow).toHaveAttribute('aria-pressed', 'false');
    await page.locator('[data-add-to-collection]').click();
    await expect(interview).toContainText(lang === 'ar' ? 'مقالين' : '2 articles');
    await expect(interview.locator('input')).not.toBeChecked();
  });

  test(`home: Following tab with suggested writers when empty — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00'));
    await signInAsReader(page, request, variant, 'fresh');
    await page.goto('/');
    await expect(page.locator('h1')).toContainText('Sara', { timeout: FIRST_RENDER_MS }); // the session is restored

    await page.locator('[data-home-tab="following"]').click();
    await expect(page.locator('[data-home-tab="following"]')).toHaveAttribute('aria-selected', 'true');
    const panel = page.locator('#home-panel-following');
    const writers = panel.locator('[data-suggested-writer]');
    await expect(writers).toHaveCount(5);
    await expect(writers.first()).toHaveAttribute('data-user', 'u-readin'); // verified first, then by followers
    await expect(panel.locator('[data-user="u-salma"]')).toContainText(lang === 'ar' ? 'بيتابعك' : 'Follows you');
    await expect(panel.locator('[data-following-refresh]')).toHaveCount(0);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(panel).toHaveScreenshot(`following-empty-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Follow Karim, then show the feed: his article is in it.
    const karim = panel.locator('[data-user="u-karim"] [data-follow]');
    await karim.click();
    await expect(karim).toHaveAttribute('aria-pressed', 'true');
    await panel.locator('[data-following-refresh]').click();
    const cards = panel.locator('rd-article-card');
    await expect(cards).toHaveCount(1);
    await expect(cards.first()).toContainText('React Server Components');

    // Bookmark it from the card: it is in Saved.
    const saved = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith('/me/saved/a-react-server-components-explained'));
    await cards.first().locator('[data-card-save]').click();
    await expect(cards.first().locator('[data-card-save]')).toHaveAttribute('aria-pressed', 'true');
    await saved;
    await page.goto('/saved');
    await expect(page.locator('[data-saved-item]')).toHaveCount(1, { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-saved-item]')).toContainText('React Server Components');
  });

  test(`saved: field chips, search, collections — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00Z'));
    await signInAsReader(page, request, variant);
    await page.goto('/saved');

    const items = page.locator('[data-saved-item]');
    const allSaved = page.locator('[data-collection-chips] .rd-chip').first();
    await expect(items).toHaveCount(5, { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-collection-chip]')).toHaveCount(2);
    await expect(page.locator('[data-field-chip]')).toHaveCount(2);
    await parkMouse(page);
    await imagesLoaded(items.first());
    await page.evaluate(() => window.scrollTo(0, 0));
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`saved-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Field chips.
    await page.locator('[data-field-chip="medicine"]').click();
    await expect(items).toHaveCount(1);
    await expect(items.first()).toContainText('How sleep turns reading into memory');
    await page.locator('[data-field-chips] .rd-chip').first().click();
    await expect(items).toHaveCount(5);

    // Search (debounced, case-insensitive); nothing found offers to clear the filters.
    const search = page.locator('[data-saved-search]');
    await search.fill('TRANSFORMER');
    await expect(items).toHaveCount(1);
    await expect(items.first()).toContainText('Transformer');
    await search.fill('kubernetes');
    await expect(page.locator('[data-saved-no-results]')).toBeVisible();
    await page.locator('[data-saved-no-results] button').click();
    await expect(items).toHaveCount(5);
    await expect(search).toHaveValue('');

    // Filter by a collection, rename it, delete it: its articles stay saved.
    await page.locator('[data-collection-chip="c-interview"]').click();
    await expect(items).toHaveCount(2);
    await page.locator('[data-rename-collection]').click();
    await expect(page.locator('#collection-name')).toHaveValue('Interview prep');
    await page.locator('#collection-name').fill('Interviews');
    await page.locator('[data-collection-name-form] [data-submit]').click();
    await expect(page.locator('[data-collection-chip="c-interview"]')).toContainText('Interviews');
    await expect(page.locator('[data-collection-header]')).toContainText('Interviews');
    await page.locator('[data-delete-collection]').click();
    await page.locator('[data-confirm-delete]').click();
    await expect(page.locator('[data-collection-chip="c-interview"]')).toHaveCount(0);
    await expect(items).toHaveCount(5);

    // A new collection opens empty; add an article to it, then take it out again.
    await page.locator('[data-new-collection-chip]').click();
    await page.locator('#collection-name').fill('Weekend');
    await page.locator('[data-collection-name-form] [data-submit]').click();
    await expect(page.locator('[data-collection-empty]')).toBeVisible();
    await allSaved.click();
    await expect(items).toHaveCount(5);
    const picker = page.locator('[data-collection-picker]');
    const weekend = picker.locator('[data-collection]', { hasText: 'Weekend' });
    await items.first().locator('[data-item-collections]').click();
    await weekend.locator('input').check();
    await expect(weekend).toContainText(lang === 'ar' ? 'مقال واحد' : '1 article');
    await picker.locator('[data-collections-done]').click();
    await page.locator('[data-collection-chip]', { hasText: 'Weekend' }).click();
    await expect(items).toHaveCount(1);
    await items.first().locator('[data-item-collections]').click();
    await weekend.locator('input').uncheck();
    await picker.locator('[data-collections-done]').click();
    await expect(items).toHaveCount(0);
    await expect(page.locator('[data-collection-empty]')).toBeVisible();

    // Unsaving from the list removes the article at once.
    await allSaved.click();
    await expect(items).toHaveCount(5);
    await items.first().locator('[data-card-save]').click();
    await expect(items).toHaveCount(4);
  });

  test(`guests: sign-in prompts, who reacted is public — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/en/a/how-readin-picks-your-daily-article');
    await page.waitForLoadState('networkidle');

    const bar = page.locator('rd-article-action-bar');
    await bar.locator('[data-react]').click();
    await expectSignInPrompt(page);
    await bar.locator('[data-save]').click();
    await expectSignInPrompt(page);
    await page.locator('[data-add-to-collection]').click();
    await expectSignInPrompt(page);
    await page.locator('[data-author-follow] [data-follow]').click();
    await expectSignInPrompt(page);
    await expect(bar.locator('[data-react]')).not.toHaveAttribute('data-my-reaction');

    // Anyone can see who reacted, 20 at a time.
    await bar.locator('[data-reactions-summary]').click();
    const reactors = page.locator('[data-reactors-sheet] [data-reactor]');
    await expect(reactors).toHaveCount(20);
    await page.locator('[data-reactors-more]').click();
    await expect(reactors).toHaveCount(40);
    await page.locator('[data-reactors-more]').click();
    await expect(reactors).toHaveCount(45);
    await expect(page.locator('[data-reactors-more]')).toHaveCount(0);
    await page.keyboard.press('Escape');

    // Home: the Following tab and a card's bookmark ask to sign in; Saved needs an account.
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.locator('[data-home-tab="following"]').click();
    await expectSignInPrompt(page);
    await expect(page.locator('[data-home-tab="forYou"]')).toHaveAttribute('aria-selected', 'true');
    await page.locator('rd-article-card [data-card-save]').first().click();
    await expectSignInPrompt(page);
    await page.goto('/saved');
    await page.waitForURL((url) => url.pathname === '/auth/sign-in');
  });
}
