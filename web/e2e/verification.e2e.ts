import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { runInNewContext } from 'node:vm';
import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, imagesLoaded, onApi, parkMouse, pngFile, problem, reply, restoreSessionAs, useVariant } from './support/mock-api';
import { VERIFICATION_NOW, badgesOf, requesterOf, reviewOf, signInAsRequester, signInAsVerificationAdmin } from './support/verification';

/**
 * F19 Writer verification end to end in ar/en × light/dark: a member asks to be verified from Settings (field, job
 * title, a proof file, a note; the form's own checks), sees the request under review and withdraws it; a rejected
 * request shows its reason and can be sent again; an approval found on page load refreshes the session; an admin
 * reviews requests (the proof file previewed with the session: an image inline, a PDF in a new tab), approves one and
 * rejects one with a reason, and removes the Verified badge of an approved writer (Verified is a badge, not a role:
 * SPEC §10); a member gets no admin entry and is sent home from the admin page. The mock API keeps each account's own
 * state (e2e/mock-api/verification.mjs), so parallel tests never share it.
 */
test.describe.configure({ timeout: 120_000 });

/** The first visit to a page may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

async function fontsReady(page: Page): Promise<void> {
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
}

test('the service worker opens readin://verification on the verification page, like the app', () => {
  const source = readFileSync(join(__dirname, '..', 'public', 'firebase-messaging-sw.js'), 'utf8');
  const sandbox = { self: { addEventListener: () => undefined, location: { origin: 'https://readin.app' } }, URL };
  const toPath = runInNewContext(`${source}\n;toPath`, sandbox) as (link: string, lang: 'ar' | 'en') => string | null;
  expect(toPath('readin://verification', 'ar')).toBe('/verification');
  expect(toPath('readin://settings/account', 'en')).toBe('/settings#account');
  expect(toPath('readin://a/x', 'en')).toBe('/en/a/x');
  expect(toPath('https://evil.example/verification', 'ar')).toBeNull();
});

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;
  const ar = lang === 'ar';

  test(`request: from Settings, with a file → under review → withdraw — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(VERIFICATION_NOW);
    const me = await signInAsRequester(page, request, variant);

    // Settings → Writer verification, with where it stands.
    await page.goto('/settings');
    const row = page.locator('[data-settings-verification]');
    await expect(row.locator('[data-verification-state]')).toHaveText(ar ? 'اطلبه' : 'Request it', { timeout: FIRST_RENDER_MS });
    await row.click();
    await page.waitForURL((url) => url.pathname === '/verification');

    const form = page.locator('[data-verification-form]');
    await expect(form).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(form.locator('[data-verification-field] option')).toHaveCount(3);

    // The form's own checks first: nothing is sent.
    await form.locator('[data-verification-submit]').click();
    await expect(form.locator('[data-error="fieldId"]')).toHaveText(ar ? 'اختار مجالك.' : 'Pick your field.');
    await expect(form.locator('[data-error="proof"]')).toHaveText(ar ? 'ضيف لينك أو ملف كإثبات.' : 'Add a link or a file as proof.');
    await expect(form.locator('[data-verification-field]')).toBeFocused();
    expect((await requesterOf(request, me.id)).submissions).toHaveLength(0);

    await form.locator('[data-verification-field]').selectOption('f-software');
    await form.locator('[data-verification-job-title]').fill(ar ? 'Backend engineer في Vodafone' : 'Backend engineer at Vodafone');
    // A file the API would refuse never gets in.
    await form.locator('[data-verification-file-input]').setInputFiles({ name: 'card.gif', mimeType: 'image/gif', buffer: Buffer.from('GIF89a') });
    await expect(form.locator('[data-error="proof"]')).toHaveText(ar ? 'اختار ملف PDF أو JPEG أو PNG أو WebP.' : 'Pick a PDF, JPEG, PNG or WebP file.');
    await form.locator('[data-verification-file-input]').setInputFiles(await pngFile(request, 'syndicate-card.png', 120, 80));
    await expect(form.locator('[data-verification-file-name]')).toHaveText('syndicate-card.png');
    await expect(form.locator('[data-error]')).toHaveCount(0);
    await form.locator('[data-verification-note]').fill(ar ? 'رقم القيد في النقابة 12345' : 'Syndicate registration number 12345');
    await fontsReady(page);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-verification-page')).toHaveScreenshot(`verification-form-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Sent as multipart: the fields and the file.
    await form.locator('[data-verification-submit]').click();
    const pending = page.locator('[data-verification-status="pending"]');
    await expect(pending).toBeVisible();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'اتبعت الطلب ✓' : 'Request sent ✓');
    const sent = (await requesterOf(request, me.id)).submissions.at(-1)!;
    expect(sent.fields).toEqual({
      fieldId: 'f-software',
      jobTitle: ar ? 'Backend engineer في Vodafone' : 'Backend engineer at Vodafone',
      note: ar ? 'رقم القيد في النقابة 12345' : 'Syndicate registration number 12345',
    });
    expect(sent.file).toMatchObject({ name: 'syndicate-card.png', type: 'image/png' });
    await expect(pending.locator('[data-verification-submitted]')).toContainText(ar ? '4 نوفمبر 2026' : 'November 4, 2026');
    await expect(pending.locator('[data-summary-proof-file]')).toHaveText('syndicate-card.png');
    await fontsReady(page);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-verification-page')).toHaveScreenshot(`verification-pending-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Settings says so too.
    await page.goBack();
    await expect(page.locator('[data-settings-verification] [data-verification-state]')).toHaveText(ar ? 'بيتراجع' : 'Under review', { timeout: FIRST_RENDER_MS });
    await page.locator('[data-settings-verification]').click();
    await expect(pending).toBeVisible({ timeout: FIRST_RENDER_MS });

    // Withdraw: asked first; then the form again.
    await pending.locator('[data-verification-withdraw]').click();
    const sheet = page.locator('[data-withdraw-sheet]');
    await expect(sheet).toContainText(ar ? 'تسحب طلبك؟' : 'Withdraw your request?');
    await sheet.locator('[data-withdraw-confirm]').click();
    await expect(page.locator('[data-verification-form]')).toBeVisible();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'اتسحب الطلب' : 'Request withdrawn');
    await expect.poll(async () => (await requesterOf(request, me.id)).requests).toEqual([]);
  });

  test(`rejected: the reason, then request again — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(VERIFICATION_NOW);
    const me = await signInAsRequester(page, request, variant, 'rejected');
    await page.goto('/verification');

    const rejected = page.locator('[data-verification-status="rejected"]');
    await expect(rejected).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(rejected).toContainText(ar ? 'طلبك ماتقبلش' : "Your request wasn't approved");
    const reason = rejected.locator('[data-verification-reason]');
    await expect(reason).toHaveText('The GitHub profile has no public projects yet. Add a certificate or a LinkedIn profile that shows your job.');
    await expect(reason).toHaveAttribute('dir', 'ltr');
    await fontsReady(page);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-verification-page')).toHaveScreenshot(`verification-rejected-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Request again: the form starts from the rejected request.
    await rejected.locator('[data-verification-again]').click();
    const form = page.locator('[data-verification-form]');
    await expect(form.locator('[data-verification-field]')).toHaveValue('f-software');
    await expect(form.locator('[data-verification-job-title]')).toHaveValue('Backend developer');
    await expect(form.locator('[data-verification-proof-url]')).toHaveValue('https://github.com/sara-hassan');

    // A plain http link is refused before sending.
    await form.locator('[data-verification-proof-url]').fill('http://www.linkedin.com/in/sara-hassan');
    await form.locator('[data-verification-submit]').click();
    await expect(form.locator('[data-error="proofUrl"]')).toHaveText(
      ar ? 'اكتب لينك كامل بيبدأ بـ https:// (لحد 500 حرف).' : 'Write a full link that starts with https:// (up to 500 characters).',
    );
    await expect(form.locator('[data-verification-proof-url]')).toHaveAttribute('aria-invalid', 'true');

    await form.locator('[data-verification-proof-url]').fill('https://www.linkedin.com/in/sara-hassan');
    await form.locator('[data-verification-submit]').click();
    await expect(page.locator('[data-verification-status="pending"]')).toBeVisible();
    const latest = (await requesterOf(request, me.id)).requests.at(-1)!;
    expect(latest).toMatchObject({ status: 'pending', fieldId: 'f-software', jobTitle: 'Backend developer', proofUrl: 'https://www.linkedin.com/in/sara-hassan', proofFile: null });
  });

  test(`approved: found on page load, the session is refreshed for the badge — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await signInAsRequester(page, request, variant, 'approved');
    const calls = { me: 0, status: 0 };
    page.on('request', (r) => {
      const path = new URL(r.url()).pathname;
      if (r.method() === 'GET' && path === '/api/v1/me') calls.me++;
      if (r.method() === 'GET' && path === '/api/v1/me/verification') calls.status++;
    });
    const meResponse = page.waitForResponse((r) => r.request().method() === 'GET' && new URL(r.url()).pathname === '/api/v1/me');
    await page.goto('/verification');
    const verified = page.locator('[data-verification-status="verified"]');
    await expect(verified).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(verified).toContainText(ar ? 'إنت كاتب موثّق ✓' : "You're a verified writer ✓");
    await expect.poll(() => calls.me).toBe(1);
    expect(calls.status).toBe(1);
    // The badge, not a role (SPEC §10): the account stays a Member.
    expect(await (await meResponse).json()).toMatchObject({ isVerified: true, roles: ['Member'] });

    // The session knows now: Settings shows it without asking the API again.
    await page.locator('[data-back-to-settings]').click();
    await expect(page.locator('[data-settings-verification] [data-verification-state]')).toHaveText(ar ? 'موثّق ✓' : 'Verified ✓', { timeout: FIRST_RENDER_MS });
    expect(calls.status).toBe(1);
  });

  test(`admin: the list, an image and a PDF proof, approve, reject with a reason — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(VERIFICATION_NOW);
    const admin = await signInAsVerificationAdmin(page, request, variant);
    const desktop = testInfo.project.name === 'desktop';

    // Desktop: the top bar's Me menu; narrow screens: Settings → Admin.
    await page.goto('/settings');
    if (desktop) {
      await page.locator('[data-me-trigger="stacked"]').click({ timeout: FIRST_RENDER_MS });
      const entry = page.locator('[data-me-menu] a[href="/admin/verification"]');
      await expect(entry).toHaveText(ar ? 'طلبات التوثيق' : 'Verification requests', { timeout: FIRST_RENDER_MS });
      await entry.click();
    } else {
      await page.locator('[data-settings-verification-requests]').click({ timeout: FIRST_RENDER_MS });
    }
    await page.waitForURL((url) => url.pathname === '/admin/verification');

    const rows = page.locator('[data-verification-row]');
    await expect(rows).toHaveCount(2, { timeout: FIRST_RENDER_MS });
    await expect(rows.nth(0)).toContainText('سلمى إبراهيم');
    await expect(rows.nth(1)).toContainText('Omar Fathy');

    // Salma: a link and a PNG certificate, previewed inline from a blob (never linked to the API).
    await rows.nth(0).click();
    await expect(page).toHaveURL(/\/admin\/verification\?id=vr-salma$/);
    const detail = page.locator('[data-verification-detail="vr-salma"]');
    await expect(detail).toBeVisible();
    const link = detail.locator('[data-detail-proof-url]');
    await expect(link).toHaveAttribute('href', 'https://www.linkedin.com/in/salma-ibrahim');
    await expect(link).toHaveAttribute('rel', 'noopener noreferrer');
    await expect(link).toHaveAttribute('target', '_blank');
    const image = detail.locator('[data-proof-image]');
    await expect(image).toHaveAttribute('src', /^blob:/);
    await imagesLoaded(detail.locator('rd-proof-preview'));
    await expect(page.locator('a[href*="/verification-requests/"]')).toHaveCount(0);
    await fontsReady(page);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-admin-verification-page')).toHaveScreenshot(`admin-verification-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    // "Open" shows the same blob in a new tab.
    const imageTab = page.waitForEvent('popup');
    await detail.locator('[data-proof-open]').click();
    const tab = await imageTab;
    await expect.poll(() => tab.url()).toBe(await image.getAttribute('src'));
    await tab.close();

    // Approve: asked, then off the list at once.
    await detail.locator('[data-detail-approve]').click();
    const sheet = page.locator('[data-decision-sheet]');
    await expect(sheet).toHaveAttribute('data-decision', 'approve');
    await sheet.locator('[data-decision-confirm]').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'بقى كاتب موثّق ✓' : 'is now a verified writer ✓');
    await expect(rows).toHaveCount(1);
    await expect.poll(async () => (await reviewOf(request, admin.id))['vr-salma'].status).toBe('approved');

    // Omar: a PDF, opened in a new tab from a blob.
    await rows.nth(0).click();
    const pdf = page.locator('[data-verification-detail="vr-omar"]');
    const open = pdf.locator('[data-proof-open]');
    await expect(open).toHaveAttribute('href', /^blob:/);
    await expect(open).toHaveAttribute('target', '_blank');
    await expect(open).toHaveAttribute('rel', 'noopener noreferrer');
    await expect(pdf.locator('[data-proof-image]')).toHaveCount(0);
    // It opens a new tab (headless Chromium shows no PDF there, so only the tab is checked; the image's tab is above).
    const popup = page.waitForEvent('popup');
    await open.click();
    await (await popup).close();

    // Reject: the reason is required (5+), and refusals keep the request on the list.
    await pdf.locator('[data-detail-reject]').click();
    await expect(sheet).toHaveAttribute('data-decision', 'reject');
    await expect(sheet.locator('[data-decision-confirm]')).toBeDisabled();
    await sheet.locator('[data-decision-reason]').fill('No.');
    await expect(sheet.locator('[data-decision-confirm]')).toBeDisabled();
    await sheet.locator('[data-decision-reason]').fill(ar ? 'الكارنيه مش باين فيه الاسم.' : 'The card does not show your name.');
    let refused = false;
    await onApi(page, 'POST', /\/admin\/verification-requests\/vr-omar\/reject$/, (route) => {
      if (refused) return route.fallback();
      refused = true;
      return reply(route, 500, problem(500, 'server.error'));
    });
    await sheet.locator('[data-decision-confirm]').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'السيرفر واجه مشكلة. حاول كمان شوية.' : 'The server ran into a problem. Please try again shortly.');
    await expect(rows).toHaveCount(1);
    expect(refused).toBe(true);
    await expect(page).toHaveURL(/id=vr-omar/);

    await page.locator('[data-verification-detail="vr-omar"] [data-detail-reject]').click();
    await sheet.locator('[data-decision-reason]').fill(ar ? 'الكارنيه مش باين فيه الاسم.' : 'The card does not show your name.');
    await sheet.locator('[data-decision-confirm]').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'الطلب اترفض' : 'Request rejected');
    await expect(page.locator('[data-verification-empty]')).toContainText(ar ? 'مفيش طلبات تتراجع' : 'No requests to review');
    expect((await reviewOf(request, admin.id))['vr-omar']).toEqual({ status: 'rejected', rejectionReason: ar ? 'الكارنيه مش باين فيه الاسم.' : 'The card does not show your name.' });

    // The Rejected tab: who decided and why; the file is gone.
    await page.locator('[data-verification-tab="rejected"]').click();
    await expect(page).toHaveURL(/status=rejected/);
    await expect(rows).toHaveCount(2);
    await page.locator('[data-verification-row="vr-omar"]').click();
    const decided = page.locator('[data-verification-detail="vr-omar"]');
    await expect(decided.locator('[data-detail-decision]')).toContainText('@hana_admin');
    await expect(decided.locator('[data-detail-reason]')).toHaveText(ar ? 'الكارنيه مش باين فيه الاسم.' : 'The card does not show your name.');
    await expect(decided.locator('[data-detail-no-file]')).toBeVisible();
    await expect(decided.locator('[data-detail-actions]')).toHaveCount(0);
  });

  test(`admin: remove an approved writer's badge (asked first; a second tab finds it gone) — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await useVariant(context, baseURL!, variant);
    await page.clock.setFixedTime(VERIFICATION_NOW);
    const admin = await signInAsVerificationAdmin(page, request, variant);
    // A second tab, opened before the badge goes: it still offers to remove it.
    const stale = await context.newPage();
    await stale.clock.setFixedTime(VERIFICATION_NOW);
    await restoreSessionAs(stale, admin);
    await stale.goto('/admin/verification?status=approved&id=vr-karim');
    await expect(stale.locator('[data-verification-detail="vr-karim"] [data-detail-remove-badge]')).toBeVisible({ timeout: FIRST_RENDER_MS });

    await page.goto('/admin/verification?status=approved');
    const row = page.locator('[data-verification-row="vr-karim"]');
    await expect(row).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(row.locator('svg[aria-label]')).toHaveAttribute('aria-label', ar ? 'كاتب موثّق' : 'Verified writer');
    await row.click();
    await expect(page).toHaveURL(/status=approved&id=vr-karim$/);
    const detail = page.locator('[data-verification-detail="vr-karim"]');
    const remove = detail.locator('[data-detail-remove-badge]');
    await expect(remove).toHaveText(ar ? 'شيل التوثيق' : 'Remove badge');
    await fontsReady(page);
    await parkMouse(page);
    if (hasScreenshot(variant)) await expect(page.locator('rd-admin-verification-page')).toHaveScreenshot(`admin-verification-approved-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // By keyboard: a confirmation first, with the focus on Cancel (the safe choice), which sends nothing.
    await remove.focus();
    await page.keyboard.press('Enter');
    const sheet = page.locator('[data-decision-sheet]');
    await expect(sheet).toHaveAttribute('data-decision', 'removeBadge');
    await expect(sheet.locator('#decision-title')).toContainText(ar ? 'تشيل التوثيق من' : 'Remove');
    await expect(sheet.locator('#decision-title')).toContainText('Karim Hassan');
    await expect(page.locator('section[role="alertdialog"]')).toHaveAttribute('aria-describedby', 'decision-body');
    const cancel = sheet.getByRole('button', { name: ar ? 'إلغاء' : 'Cancel' });
    await expect(cancel).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(sheet).toHaveCount(0);
    await expect(remove).toBeFocused();
    expect((await badgesOf(request, admin.id))['u-karim']).toBe(true);

    // Confirmed: the action goes at once, the request stays approved, and the toast says so.
    await page.keyboard.press('Enter');
    await sheet.locator('[data-decision-confirm]').click();
    await expect(page.locator('rd-toast-host')).toContainText(ar ? 'مبقاش موثّق' : "isn't verified anymore");
    await expect(remove).toHaveCount(0);
    await expect(detail.locator('[data-detail-badge-removed]')).toHaveText(ar ? 'مبقاش معاه علامة التوثيق.' : "They don't have the Verified badge anymore.");
    await expect(detail.locator('[data-detail-decision]')).toBeFocused();
    await expect(row.locator('svg[aria-label]')).toHaveCount(0);
    await expect.poll(async () => (await badgesOf(request, admin.id))['u-karim']).toBe(false);
    expect((await reviewOf(request, admin.id))['vr-karim'].status).toBe('approved');

    // The stale tab: the API says the user isn't verified (409), so the action goes there too.
    await stale.locator('[data-detail-remove-badge]').click();
    await stale.locator('[data-decision-confirm]').click();
    await expect(stale.locator('rd-toast-host')).toContainText(ar ? 'المستخدم ده مش موثّق.' : "This user isn't verified.");
    await expect(stale.locator('[data-detail-remove-badge]')).toHaveCount(0);
    await expect(stale.locator('[data-verification-detail="vr-karim"] [data-detail-badge-removed]')).toBeVisible();
    await stale.close();

    // Loaded again, the list agrees: no badge, nothing to remove.
    await page.reload();
    await expect(page.locator('[data-verification-detail="vr-karim"] [data-detail-badge-removed]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-detail-remove-badge]')).toHaveCount(0);
  });

  test(`a member: no admin entry, and the admin page sends them home — ${suffix}`, async ({ page, context, baseURL, request }, testInfo) => {
    await useVariant(context, baseURL!, variant);
    await signInAsRequester(page, request, variant);
    await page.goto('/settings');
    await expect(page.locator('[data-settings-verification]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page.locator('[data-settings-admin]')).toHaveCount(0);
    if (testInfo.project.name === 'desktop') {
      await page.locator('[data-me-trigger="stacked"]').click();
      await expect(page.locator('[data-me-menu] a[href="/settings"]')).toBeVisible();
      await expect(page.locator('[data-me-menu] a[href="/admin/verification"]')).toHaveCount(0);
      await page.keyboard.press('Escape');
    }
    await page.goto('/admin/verification');
    await page.waitForURL((url) => url.pathname === '/', { timeout: FIRST_RENDER_MS });
    await expect(page.locator('rd-admin-verification-page')).toHaveCount(0);
  });
}
