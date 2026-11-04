import { expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, fixture, hasScreenshot, onApi, parkMouse, pngFile, problem, reply, useVariant } from './support/mock-api';
import { openProfile, readingStatsLoaded, signInWithLiveProfile } from './support/profile';
import { expectSignInPrompt, openArticle, signInAsReader } from './support/social';

/* eslint-disable @typescript-eslint/no-explicit-any -- request bodies are plain JSON */

/**
 * F14 Profile end to end in ar/en × light/dark: someone else's profile (server-rendered with its meta tags, public
 * reading stats, tabs, keyboard), your own profile (Edit profile, Saved tab, the "Show on my public profile" switch and
 * Settings → Privacy, with "Who can mention me"), Edit profile (photo upload and removal, username check, bio counter, links, expertise, server
 * errors on their fields) and the followers / following lists (search, infinite scroll, follow). The mock API keeps
 * each reader's profile (e2e/mock-api/profiles.mjs), so reloads show what the server saved.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`profile: a writer, as a guest — ${suffix}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00Z'));

    // Server-rendered for crawlers: title, Open Graph profile tags and the header are in the HTML.
    const response = await page.goto('/@mona');
    expect(response!.status()).toBe(200);
    const html = await response!.text();
    expect(html).toContain('<title>Mona Adel (@mona) — ReadIn</title>');
    expect(html).toMatch(/<meta property="og:type" content="profile"/);
    expect(html).toMatch(/<link rel="canonical" href="[^"]*\/@mona"/);
    expect(html).toContain('"@type":"ProfilePage"');
    expect(html).toContain('data-profile-header');

    const header = page.locator('[data-profile-header]');
    await expect(header.locator('[data-profile-name]')).toContainText('Mona Adel', { timeout: FIRST_RENDER_MS });
    await expect(header.locator('[data-profile-username]')).toHaveText('@mona');
    await expect(header.locator('[data-profile-username]')).toHaveAttribute('dir', 'ltr');
    // Mixed text takes the direction of its first strong character: an English bio stays LTR in the Arabic UI.
    await expect(header.locator('[data-profile-bio]')).toHaveAttribute('dir', 'ltr');
    await expect(header.locator('[data-profile-link]')).toHaveCount(3);
    await expect(header.locator('[data-profile-link="github"]')).toHaveAttribute('target', '_blank');
    await expect(header.locator('[data-stat="articles"]')).toContainText('4');
    await expect(header.locator('[data-edit-profile]')).toHaveCount(0);
    await expect(header.locator('[data-follows-you]')).toHaveCount(0);

    // Mona's reading stats are public: the card without the owner's coaching, no switch.
    const reading = page.locator('[data-profile-reading]');
    await readingStatsLoaded(page);
    await expect(reading.locator('[data-public-stats]')).toHaveCount(0);
    await expect(reading.locator('rd-reading-stats-card')).toContainText(ar ? '12 يوم' : '12 days');

    // Articles / Paths / About (Saved is only on your own profile).
    const tabs = page.locator('[data-profile-tab]');
    await expect(tabs).toHaveCount(3);
    await expect(page.locator('[data-profile-articles] rd-article-card')).toHaveCount(4);

    // About: bio, links, fields of expertise, join date. The screenshot shows this tab (the cards' media is lazy).
    await page.locator('[data-profile-tab="about"]').click();
    const about = page.locator('[data-profile-about]');
    await expect(about.locator('[data-profile-expertise] li')).toHaveCount(1);
    await expect(about.locator('[data-profile-expertise]')).toContainText(ar ? 'البرمجيات' : 'Software');
    await expect(about.locator('[data-profile-joined]')).toContainText(ar ? 'يناير' : 'January 2026');
    await parkMouse(page);
    await page.evaluate(() => window.scrollTo(0, 0));
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`profile-other-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });

    // Follow asks a guest to sign in.
    await header.locator('[data-profile-follow] [data-follow]').click();
    await expectSignInPrompt(page);

    // Home / End and the arrow keys (they follow the reading direction).
    await page.locator('[data-profile-tab="about"]').focus();
    await page.keyboard.press('Home');
    await expect(page.locator('[data-profile-tab="articles"]')).toBeFocused();
    await page.keyboard.press(dir === 'rtl' ? 'ArrowLeft' : 'ArrowRight');
    await expect(page.locator('[data-profile-tab="paths"]')).toBeFocused();
    await expect(page.locator('[data-profile-tab="paths"]')).toHaveAttribute('aria-selected', 'true');
    // Mona's stats are public, so are her paths (F09): the one in progress first, then the one she finished.
    const paths = page.locator('[data-profile-paths] [data-path-card]');
    await expect(paths).toHaveCount(2);
    await expect(paths.first()).toHaveAttribute('data-path-card', 'learn-how-to-learn');
    await expect(paths.first().locator('[data-path-progress]')).toContainText('1/3');
    await expect(paths.nth(1).locator('[data-path-completed]')).toBeVisible();
    await page.keyboard.press('End');
    await expect(page.locator('[data-profile-tab="about"]')).toBeFocused();
    await expect(about).toBeVisible();

    // Followers open the list.
    await header.locator('[data-stat="followers"]').click();
    await page.waitForURL('**/@mona/followers');
    await expect(page.locator('[data-person]').nth(19)).toBeVisible({ timeout: FIRST_RENDER_MS });
  });

  test(`profile: yours, with the public-stats switch and Saved — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(new Date('2026-11-03T09:00:00Z'));
    await signInWithLiveProfile(page, request, variant);
    await openProfile(page, '/@sara', { signedIn: true });

    const header = page.locator('[data-profile-header]');
    await expect(header.locator('[data-edit-profile]')).toBeVisible();
    await expect(header.locator('[data-profile-follow]')).toHaveCount(0);
    await expect(header.locator('[data-stat="following"]')).toContainText('2');
    await expect(page.locator('[data-profile-tab]')).toHaveCount(4);
    await expect(page.locator('[data-articles-empty]')).toBeVisible();
    await expect(header.locator('[data-profile-bio]')).toHaveAttribute('dir', 'rtl');

    // Your stats, with the coaching line and the switch (off by default).
    await readingStatsLoaded(page);
    const toggle = page.locator('[data-profile-reading] [data-public-stats] [role="switch"]');
    await expect(toggle).toHaveAttribute('aria-checked', 'false');
    await expect(page.locator('[data-profile-reading] rd-reading-stats-card')).toContainText(ar ? 'قريت النهارده' : 'You read today');
    await parkMouse(page);
    await page.evaluate(() => window.scrollTo(0, 0));
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`profile-own-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });

    // Turn public stats on: PUT /me/privacy (the whole settings object), kept after a reload.
    const saved = page.waitForRequest((r) => r.method() === 'PUT' && r.url().endsWith('/me/privacy'));
    await toggle.click();
    expect((await saved).postDataJSON()).toEqual({ publicReadingStats: true, whoCanMention: 'everyone' });
    await expect(toggle).toHaveAttribute('aria-checked', 'true');
    await openProfile(page, '/@sara', { signedIn: true });
    await expect(page.locator('[data-profile-reading] [data-public-stats] [role="switch"]')).toHaveAttribute('aria-checked', 'true');

    // The Saved tab is yours only: your saved articles, with a way to the Saved page.
    await page.locator('[data-profile-tab="saved"]').click();
    await expect(page.locator('[data-profile-saved] [data-saved-item]')).toHaveCount(5);

    // Settings → Privacy shows the same switch; turning it off there is kept too.
    await page.goto('/settings');
    const privacy = page.locator('[data-settings-privacy] [role="switch"]');
    await expect(privacy).toHaveAttribute('aria-checked', 'true', { timeout: FIRST_RENDER_MS });
    await privacy.click();
    await expect(privacy).toHaveAttribute('aria-checked', 'false');
    await page.reload();
    await expect(page.locator('[data-settings-privacy] [role="switch"]')).toHaveAttribute('aria-checked', 'false', { timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-settings-edit-profile]')).toHaveAttribute('href', '/settings/profile');
  });

  test(`settings → privacy: who can mention me — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInWithLiveProfile(page, request, variant);
    const privacySaved = () => page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith('/me/privacy'));
    const label = ar ? { everyone: 'أي حد', following: 'الناس اللي بتابعهم', nobody: 'محدش' } : { everyone: 'Everyone', following: 'People I follow', nobody: 'Nobody' };

    await page.goto('/settings');
    const card = page.locator('[data-settings-privacy]');
    const mention = card.locator('[data-who-can-mention]');
    const group = mention.getByRole('radiogroup', { name: ar ? 'مين يقدر يعمل لك منشن' : 'Who can mention me' });
    const choice = (policy: keyof typeof label) => group.getByRole('radio', { name: label[policy], exact: true });
    // Everyone by default, next to the public-stats switch.
    await expect(mention).toHaveAttribute('data-value', 'everyone', { timeout: FIRST_RENDER_MS });
    await expect(choice('everyone')).toHaveAttribute('aria-checked', 'true');
    await expect(card.locator('[data-public-stats] [role="switch"]')).toHaveAttribute('aria-checked', 'false');
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    await card.scrollIntoViewIfNeeded();
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(card).toHaveScreenshot(`settings-privacy-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // "People I follow": saved at once with the whole settings object, kept after a reload.
    let response = privacySaved();
    await choice('following').click();
    expect((await response).request().postDataJSON()).toEqual({ publicReadingStats: false, whoCanMention: 'following' });
    expect((await response).status()).toBe(204);
    await expect(choice('following')).toHaveAttribute('aria-checked', 'true');
    await page.reload();
    await expect(mention).toHaveAttribute('data-value', 'following', { timeout: FIRST_RENDER_MS });
    await expect(choice('following')).toHaveAttribute('aria-checked', 'true');

    // The public-stats switch sends it back as it is.
    response = privacySaved();
    await card.locator('[data-public-stats] [role="switch"]').click();
    expect((await response).request().postDataJSON()).toEqual({ publicReadingStats: true, whoCanMention: 'following' });
    await expect(choice('nobody')).toBeEnabled();

    // Refused once: the choice goes back, with the translated error.
    let refused = false;
    await onApi(page, 'PUT', '/me/privacy', (route) => {
      if (refused) return route.fallback();
      refused = true;
      return reply(route, 500, problem(500, 'server.error'));
    });
    await choice('nobody').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'السيرفر واجه مشكلة. حاول كمان شوية.' : 'The server ran into a problem. Please try again shortly.');
    await expect(choice('following')).toHaveAttribute('aria-checked', 'true');
    await expect(choice('nobody')).toHaveAttribute('aria-checked', 'false');
    await expect(mention).toHaveAttribute('data-value', 'following');

    // "Nobody", once the API takes it again.
    expect(refused).toBe(true);
    response = privacySaved();
    await choice('nobody').click();
    expect((await response).request().postDataJSON()).toEqual({ publicReadingStats: true, whoCanMention: 'nobody' });
    await page.reload();
    await expect(mention).toHaveAttribute('data-value', 'nobody', { timeout: FIRST_RENDER_MS });
    await expect(card.locator('[data-public-stats] [role="switch"]')).toHaveAttribute('aria-checked', 'true');
  });

  test(`edit profile: photo, username, bio, links, expertise, errors — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInWithLiveProfile(page, request, variant);
    const avatar = await fixture<any>(request, '/__mock/asset/avatar?seed=sara-new');
    let uploads = 0;
    await onApi(page, 'POST', '/uploads/images', (route) => {
      uploads++;
      return reply(route, 201, avatar);
    });
    const patches: any[] = [];
    page.on('request', (r) => {
      if (r.method() === 'PATCH' && r.url().endsWith('/api/v1/me')) patches.push(r.postDataJSON());
    });

    await page.goto('/settings/profile');
    const form = page.locator('[data-edit-profile-form]');
    await expect(form.locator('#edit-name')).toHaveValue('Sara Hassan', { timeout: FIRST_RENDER_MS });
    await expect(form.locator('#edit-username')).toHaveValue('sara');
    await expect(form.locator('[data-link-input="github"]')).toHaveValue('https://github.com/sara-hassan');
    await expect(form.locator('[data-expertise="software"]')).toHaveAttribute('aria-pressed', 'true');
    await expect(form.locator('[data-bio-count]')).toHaveText(/^\s*\d+ \/ 300\s*$/);
    await parkMouse(page);
    await page.evaluate(() => window.scrollTo(0, 0));
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`edit-profile-${suffix}.png`, { fullPage: true, stylePath: HIDE_APP_CHROME });

    // A new photo: uploaded with purpose=avatar, previewed from its 256 px variant.
    await form.locator('[data-avatar-input]').setInputFiles(await pngFile(request, 'portrait.png', 600, 600));
    await expect(form.locator('[data-avatar-preview] img')).toHaveAttribute('src', /avatar-sara-new\/256x256/);
    expect(uploads).toBe(1);

    // The live username check, and a bio over 300 characters can't be saved.
    const username = form.locator('#edit-username');
    await username.fill('taken');
    await expect(form.locator('[data-username-status]')).toHaveText(ar ? 'اسم المستخدم ده محجوز.' : 'That username is taken.');
    await username.fill('Sara Hassan!');
    await expect(username).toHaveValue('sarahassan');
    await expect(form.locator('[data-username-status]')).toHaveText(ar ? 'متاح ✓' : 'Available ✓');
    const bio = form.locator('#edit-bio');
    await bio.fill('x'.repeat(301));
    await expect(form.locator('[data-bio-count]')).toHaveText('301 / 300');
    await form.locator('[data-submit]').click();
    await expect(form.locator('[data-field-error="bio"]')).toBeVisible();
    expect(patches).toHaveLength(0);
    await bio.fill('بكتب عن الـ backend و system design (.NET).');

    // A bare link gets https://; a link that isn't https is refused.
    await form.locator('[data-link-input="linkedin"]').fill('linkedin.com/in/sara');
    await form.locator('[data-link-input="website"]').fill('ftp://sara.dev');
    await form.locator('[data-link-input="website"]').blur();
    await expect(form.locator('[data-link-input="linkedin"]')).toHaveValue('https://linkedin.com/in/sara');
    await form.locator('[data-submit]').click();
    await expect(form.locator('[data-field-error="website"]')).toBeVisible();
    await expect(form.locator('[data-link-input="website"]')).toBeFocused();
    await form.locator('[data-link-input="website"]').fill('');

    // Expertise keeps the order you pick.
    await form.locator('[data-expertise="medicine"]').click();
    await expect(form.locator('[data-expertise="medicine"]')).toHaveAttribute('aria-pressed', 'true');
    await expect(form.locator('[data-expertise-count]')).toContainText(ar ? '2 من 5' : '2 of 5');

    // A handle the server says is taken lands on the username field.
    await username.fill('karim');
    await expect(form.locator('[data-username-status]')).toHaveText(ar ? 'متاح ✓' : 'Available ✓');
    await form.locator('[data-submit]').click();
    await expect(form.locator('[data-username-status]')).toHaveText(ar ? 'اسم المستخدم ده محجوز.' : 'That username is taken.');
    expect(patches).toHaveLength(1);

    // Save: one PATCH with the new photo's asset id, then your new profile.
    await username.fill('sara_hassan');
    await expect(form.locator('[data-username-status]')).toHaveText(ar ? 'متاح ✓' : 'Available ✓');
    await form.locator('[data-submit]').dblclick();
    await page.waitForURL('**/@sara_hassan');
    expect(patches).toHaveLength(2);
    expect(patches[1]).toEqual({
      displayName: 'Sara Hassan',
      username: 'sara_hassan',
      bio: 'بكتب عن الـ backend و system design (.NET).',
      links: { github: 'https://github.com/sara-hassan', linkedin: 'https://linkedin.com/in/sara', website: null },
      expertiseFieldIds: ['f-software', 'f-medicine'],
      avatarAssetId: 'asset-avatar-sara-new',
    });
    const header = page.locator('[data-profile-header]');
    await expect(header.locator('[data-profile-username]')).toHaveText('@sara_hassan', { timeout: FIRST_RENDER_MS });
    await expect(header.locator('img')).toHaveAttribute('src', /avatar-sara-new\/256x256/);
    await expect(header.locator('[data-edit-profile]')).toBeVisible();

    // Remove the photo: avatarAssetId null. A save that doesn't touch the photo leaves the key out.
    await header.locator('[data-edit-profile]').click();
    await expect(form.locator('#edit-username')).toHaveValue('sara_hassan', { timeout: FIRST_RENDER_MS });
    await form.locator('[data-avatar-remove]').click();
    await expect(form.locator('[data-avatar-preview] img')).toHaveCount(0);
    await form.locator('[data-submit]').click();
    await page.waitForURL('**/@sara_hassan');
    expect(patches[2].avatarAssetId).toBeNull();
    await expect(page.locator('[data-profile-header] img')).toHaveCount(0);
    await page.locator('[data-profile-header] [data-edit-profile]').click();
    await form.locator('#edit-name').fill('Sara H.');
    await form.locator('[data-submit]').click();
    await page.waitForURL('**/@sara_hassan');
    expect('avatarAssetId' in patches[3]).toBe(false);
    expect('avatarUrl' in patches[3]).toBe(false);
    await expect(page.locator('[data-profile-name]')).toContainText('Sara H.');
  });

  test(`followers: search, infinite scroll, follow — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsReader(page, request, variant);
    // 20 a page; the second one comes with infinite scroll (it may already start near the end of a short list).
    const secondPage = page.waitForRequest((r) => new URL(r.url()).pathname.endsWith('/users/u-writer/followers') && new URL(r.url()).searchParams.get('cursor') === '20');
    await page.goto('/@mona/followers');

    const people = page.locator('[data-person]');
    await expect(people.nth(19)).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-people-list="followers"]')).toHaveAttribute('aria-current', 'page');
    await parkMouse(page);
    await page.evaluate(() => window.scrollTo(0, 0));
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`followers-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Follow someone from the list.
    const first = people.first();
    const follow = first.locator('[data-follow]');
    const followed = page.waitForResponse((r) => r.request().method() === 'PUT' && r.url().endsWith('/follow'));
    await follow.click();
    await expect(follow).toHaveAttribute('aria-pressed', 'true');
    expect((await followed).status()).toBe(200);

    // Infinite scroll: the rest of the 30 followers.
    await page.locator('[data-people]').evaluate((el) => el.lastElementChild?.scrollIntoView());
    await secondPage;
    await expect(people).toHaveCount(30);
    await expect(page.locator('[data-people]')).toContainText(ar ? 'دول كل الناس.' : 'That’s everyone.');

    // Search by @username (debounced), then something nobody matches.
    const handle = (await people.nth(4).locator('bdi[dir="ltr"]').textContent())!.trim().replace(/^@/, '');
    const search = page.locator('[data-people-search]');
    await search.fill(handle);
    await expect.poll(async () => {
      const rows = await people.allTextContents();
      return rows.length > 0 && rows.length < 30 && rows.every((row) => row.includes(`@${handle}`));
    }).toBe(true);
    await search.fill('zzzz');
    await expect(page.locator('[data-people-no-results]')).toBeVisible();

    // Following, then a row opens that profile.
    await page.locator('[data-people-list="following"]').click();
    await page.waitForURL('**/@mona/following');
    await expect(search).toHaveValue('');
    await expect(people).toHaveCount(12);
    const target = (await people.first().locator('bdi[dir="ltr"]').textContent())!.trim();
    await people.first().locator('rd-user-row a').first().click();
    await page.waitForURL(`**/${target}`);
    await expect(page.locator('[data-profile-username]')).toHaveText(target, { timeout: FIRST_RENDER_MS });
  });
}

test.describe('profile links and states (en/light)', () => {
  const variant = VARIANTS[2];

  test('author names and photos open the profile', async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    // Feed card → author.
    await page.goto('/');
    await page.locator('rd-article-card [data-card-author]').first().click();
    await page.waitForURL('**/@mona');
    await expect(page.locator('[data-profile-name]')).toContainText('Mona Adel', { timeout: FIRST_RENDER_MS });

    // Reader → the author's photo; who reacted → a reader's profile.
    await signInAsReader(page, request, variant);
    await openArticle(page, '/en/a/react-server-components-explained');
    await page.locator('[data-author-avatar]').click();
    await page.waitForURL('**/@karim');
    await openArticle(page, '/en/a/react-server-components-explained');
    await page.locator('rd-article-action-bar [data-reactions-summary]').click();
    const reactor = page.locator('[data-reactors-sheet] [data-reactor]').first();
    const handle = (await reactor.locator('bdi[dir="ltr"]').textContent())!.trim();
    await reactor.locator('a').first().click();
    await page.waitForURL(`**/${handle}`);
    await expect(page.locator('[data-profile-username]')).toHaveText(handle, { timeout: FIRST_RENDER_MS });
  });

  test('an unknown username is a 404, private stats stay hidden', async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    const response = await page.goto('/@nobody_here');
    expect(response!.status()).toBe(404);
    await expect(page.locator('[data-profile-not-found]')).toBeVisible();
    await expect(page).toHaveTitle(/doesn’t exist/);

    await page.goto('/@karim');
    await expect(page.locator('[data-profile-header]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-profile-reading]')).toHaveCount(0);
    await expect(page.locator('[data-profile-articles] rd-article-card')).toHaveCount(1);
  });
});
