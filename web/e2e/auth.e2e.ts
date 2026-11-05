import { Page, expect, test } from '@playwright/test';
import {
  API,
  HIDE_APP_CHROME,
  MOCK_PASSWORD,
  MOCK_PHONE,
  VARIANTS,
  Variant,
  hasScreenshot,
  onApi,
  problem,
  reply,
  restoreSessionAs,
  sessionFor,
  useVariant,
  writerMe,
} from './support/mock-api';

/* eslint-disable @typescript-eslint/no-explicit-any -- request bodies are plain JSON */

/**
 * Auth v1.1 end to end (SPEC §9, F01, F18) in ar/en × light/dark: Welcome → Sign in (generic error) → Forgot password
 * (phone + PIN → new password) → Sign in with the banner; Create account (3 steps) → Complete profile → Onboarding;
 * the mandatory change-password and set-PIN screens; Settings → Account. Every screen gets a screenshot in ar/light and
 * en/dark (SPEC §27).
 */
test.describe.configure({ timeout: 90_000 });

const STRONG_PASSWORD = 'Nile river 2026';
const NEW_PASSWORD = 'Cairo Tower 1961!';
const GOOD_PIN = '4829';
/** Auth screens render in the browser only; the first one may wait for the dev server to compile its chunk. */
const FIRST_RENDER_MS = 30_000;

/** Fixed default country (last used → Egypt) and clock, so screenshots don't depend on the machine's locale. */
async function prepare(page: Page, context: Parameters<typeof useVariant>[0], baseURL: string, variant: Variant): Promise<void> {
  await useVariant(context, baseURL, variant);
  await context.addInitScript(() => localStorage.setItem('readin.phoneCountry', 'EG'));
  await page.clock.setFixedTime(new Date('2026-11-03T09:00:00'));
}

/** Waits for the flags (SVG images) that are on screen, so a screenshot never catches an empty box. */
async function imagesSettled(page: Page): Promise<void> {
  await page.waitForFunction(() =>
    [...document.images].every((img) => {
      const r = img.getBoundingClientRect();
      const onScreen = r.width > 0 && r.bottom > 0 && r.top < innerHeight;
      return (img.loading === 'lazy' && !onScreen) || (img.complete && img.naturalWidth > 0);
    }),
  );
}

async function snap(page: Page, variant: Variant, name: string): Promise<void> {
  await page.mouse.move(1, 1);
  await imagesSettled(page);
  if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(name, { fullPage: true, stylePath: HIDE_APP_CHROME });
}

async function snapViewport(page: Page, variant: Variant, name: string): Promise<void> {
  await imagesSettled(page);
  if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(name, { stylePath: HIDE_APP_CHROME });
}

/** Types a PIN into the boxes (the focus moves on by itself). */
async function typePin(page: Page, idPrefix: string, pin: string): Promise<void> {
  await page.locator(`#${idPrefix}-0`).click();
  await page.keyboard.type(pin);
}

for (const variant of VARIANTS) {
  const { lang, theme, dir } = variant;
  const suffix = `${lang}-${theme}`;

  test(`welcome → sign in → forgot password → sign in again — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await prepare(page, context, baseURL!, variant);
    const me = await writerMe(request, variant);
    let loginAttempts = 0;
    const loginBodies: any[] = [];
    await onApi(page, 'POST', '/auth/login', (route) => {
      loginBodies.push(route.request().postDataJSON());
      return ++loginAttempts === 1
        ? reply(route, 401, problem(401, 'auth.invalid_credentials'))
        : reply(route, 200, sessionFor(me));
    });
    let verifyBody: any = null;
    await onApi(page, 'POST', '/auth/recovery/verify-pin', (route) => {
      verifyBody = route.request().postDataJSON();
      return reply(route, 200, { resetToken: 'reset-token-1', expiresAt: '2026-11-03T09:10:00Z' });
    });
    let resetBody: any = null;
    await onApi(page, 'POST', '/auth/recovery/reset-password', (route) => {
      resetBody = route.request().postDataJSON();
      return reply(route, 204);
    });

    // ── Welcome ──
    await page.goto('/auth');
    await expect(page.locator('html')).toHaveAttribute('dir', dir);
    await expect(page.locator('[data-welcome]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    // Every auth screen has its own tab title, in the UI language.
    await expect(page).toHaveTitle(lang === 'ar' ? 'أهلاً بيك — ReadIn' : 'Welcome — ReadIn');
    await snap(page, variant, `welcome-${suffix}.png`);

    // ── Sign in: the country picker, then one generic error for a wrong password ──
    await page.locator('[data-sign-in]').click();
    await page.waitForURL('**/auth/sign-in');
    await expect(page).toHaveTitle(lang === 'ar' ? 'تسجيل الدخول — ReadIn' : 'Sign in — ReadIn');
    await page.locator('rd-phone-field [aria-haspopup="dialog"]').click();
    const picker = page.locator('rd-country-picker');
    await expect(picker).toBeVisible();
    await picker.locator('[role="combobox"]').fill(lang === 'ar' ? 'السعو' : 'sau');
    await expect(picker.locator('[role="option"]').first()).toHaveAttribute('data-country', 'SA');
    await snapViewport(page, variant, `country-picker-${suffix}.png`);
    await page.keyboard.press('Escape');
    await expect(picker).toHaveCount(0);

    // Arabic-Indic digits and the trunk prefix: "٠١٠٠١٢٣٤٥٦٧" is +201001234567.
    await page.locator('#sign-in-phone').fill('٠١٠٠١٢٣٤٥٦٧');
    await expect(page.locator('#sign-in-phone')).toHaveValue('10 01234567');
    await page.locator('#sign-in-password').fill('wrong-password-1');
    await page.locator('form [data-submit]').click();
    await expect(page.locator('[data-error]')).toBeVisible();
    expect(loginBodies[0]).toEqual({ phoneNumber: MOCK_PHONE, password: 'wrong-password-1' });
    await snap(page, variant, `sign-in-error-${suffix}.png`);

    // ── Forgot password: the number comes along ──
    await page.locator('[data-forgot]').click();
    await page.waitForURL('**/auth/forgot-password');
    await expect(page.locator('#forgot-phone')).toHaveValue('10 01234567');
    await expect(page).toHaveTitle(lang === 'ar' ? 'نسيت كلمة السر — ReadIn' : 'Forgot password — ReadIn');
    await page.locator('[data-forgot-pin]').click();
    await expect(page.locator('[data-support]')).toBeVisible();
    await snapViewport(page, variant, `contact-support-${suffix}.png`);
    await page.keyboard.press('Escape');
    await expect(page.locator('[data-support]')).toHaveCount(0);

    await typePin(page, 'forgot-pin', GOOD_PIN);
    await snap(page, variant, `forgot-verify-${suffix}.png`);
    await page.locator('[data-step-verify] [data-submit]').click();
    await expect(page.locator('[data-step-reset]')).toBeVisible();
    expect(verifyBody).toEqual({ phoneNumber: MOCK_PHONE, pin: GOOD_PIN });

    await page.locator('#forgot-new-password').fill(NEW_PASSWORD);
    await page.locator('#forgot-confirm').fill(NEW_PASSWORD);
    await expect(page.locator('[data-rule][data-met="true"]')).toHaveCount(3);
    await snap(page, variant, `forgot-reset-${suffix}.png`);
    await page.locator('[data-step-reset] [data-submit]').click();

    // ── Back on Sign in: number pre-filled, banner, then in with the new password ──
    await page.waitForURL('**/auth/sign-in');
    await expect(page.locator('[data-banner]')).toBeVisible();
    await expect(page.locator('#sign-in-phone')).toHaveValue('10 01234567');
    expect(resetBody).toEqual({ resetToken: 'reset-token-1', newPassword: NEW_PASSWORD });
    await snap(page, variant, `sign-in-reset-${suffix}.png`);

    await page.locator('#sign-in-password').fill(NEW_PASSWORD);
    await page.locator('form [data-submit]').click();
    await page.waitForURL((url) => url.pathname === '/');
    expect(loginBodies[1]).toEqual({ phoneNumber: MOCK_PHONE, password: NEW_PASSWORD });
  });

  test(`create account (3 steps) → complete profile → onboarding — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await prepare(page, context, baseURL!, variant);
    const placeholder = 'reader_k3j9x0p2qa';
    const created = await writerMe(request, variant, {
      displayName: placeholder,
      username: placeholder,
      isProfileComplete: false,
      onboardingCompleted: false,
      isVerified: false,
      interests: { fieldIds: [], topicIds: [] },
    });
    let registerBody: any = null;
    let registerCalls = 0;
    await onApi(page, 'POST', '/auth/register', (route) => {
      registerBody = route.request().postDataJSON();
      return ++registerCalls === 1
        ? reply(route, 409, problem(409, 'auth.phone_taken'))
        : reply(route, 200, sessionFor(created));
    });
    let profileBody: any = null;
    await onApi(page, 'PUT', '/me/profile/complete', (route) => {
      profileBody = route.request().postDataJSON();
      return reply(route, 200, { ...created, ...profileBody, isProfileComplete: true });
    });

    await page.goto('/auth/sign-up');
    await expect(page.locator('[data-step]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(page).toHaveTitle(lang === 'ar' ? 'حساب جديد — ReadIn' : 'Create an account — ReadIn');

    // Step 1: phone + password (strength meter, live rules) + confirm
    await page.locator('#sign-up-phone').fill('01001234567');
    await page.locator('#sign-up-password').fill(STRONG_PASSWORD);
    await page.locator('#sign-up-confirm').fill(STRONG_PASSWORD);
    await expect(page.locator('[data-rule][data-met="true"]')).toHaveCount(3);
    await snap(page, variant, `sign-up-account-${suffix}.png`);
    await page.locator('[data-step-1] [data-submit]').click();

    // Step 2: the recovery PIN; a weak one is refused live
    await expect(page.locator('[data-step-2]')).toBeVisible();
    await typePin(page, 'sign-up-pin', '1234');
    await expect(page.locator('#sign-up-pin-error')).toBeVisible();
    await page.locator('#sign-up-pin-0').click();
    await page.keyboard.type(GOOD_PIN);
    await typePin(page, 'sign-up-pin-confirm', GOOD_PIN);
    await expect(page.locator('#sign-up-pin-error')).toHaveCount(0);
    await snap(page, variant, `sign-up-pin-${suffix}.png`);
    await page.locator('[data-step-2] [data-submit]').click();

    // Step 3: confirm the number (large, LTR)
    const dialog = page.locator('[data-confirm-phone]');
    await expect(dialog).toBeVisible();
    await expect(dialog.locator('[data-phone]')).toHaveText('+20 10 01234567');
    await snapViewport(page, variant, `sign-up-confirm-${suffix}.png`);

    // The number is taken → back to step 1 with a Sign in action; "Edit" keeps everything typed.
    await dialog.locator('[data-confirm]').click();
    await expect(page.locator('[data-phone-taken]')).toBeVisible();
    await page.locator('#sign-up-phone').fill('01001234568');
    await page.locator('[data-step-1] [data-submit]').click();
    await page.locator('[data-step-2] [data-submit]').click();
    await dialog.locator('[data-confirm]').click();

    await page.waitForURL('**/auth/complete-profile');
    await expect(page).toHaveTitle(lang === 'ar' ? 'كمّل بروفايلك — ReadIn' : 'Complete your profile — ReadIn');
    expect(registerBody).toMatchObject({ phoneNumber: '+201001234568', password: STRONG_PASSWORD, recoveryPin: GOOD_PIN, uiLanguage: lang });
    expect(typeof registerBody.timeZone).toBe('string');

    // Complete profile: name + live @username check
    await expect(page.locator('#profile-name')).toHaveValue('');
    await page.locator('#profile-name').fill(lang === 'ar' ? 'منى عادل' : 'Mona Adel');
    await page.locator('#profile-username').fill('Mona_Adel!');
    await expect(page.locator('#profile-username')).toHaveValue('mona_adel');
    await expect(page.locator('[data-username-status]')).toHaveClass(/text-success/);
    // The optional title (F14) is empty: the screenshot shows the field with its hint.
    await expect(page.locator('#profile-headline')).toHaveValue('');
    await snap(page, variant, `complete-profile-${suffix}.png`);
    // One line, up to 120: past the limit it can't be sent; trimmed when it is.
    await page.locator('#profile-headline').fill('x'.repeat(121));
    await page.locator('[data-complete-profile] [data-submit]').click();
    await expect(page.locator('[data-complete-profile] [data-field-error="headline"]')).toHaveText(
      lang === 'ar' ? 'المسمى لازم يكون 120 حرف أو أقل.' : 'A title has at most 120 characters.',
    );
    expect(profileBody).toBeNull();
    await page.locator('#profile-headline').fill('  Backend engineer | .NET  ');
    await page.locator('[data-complete-profile] [data-submit]').click();

    await page.waitForURL('**/onboarding');
    await expect(page).toHaveTitle(lang === 'ar' ? 'يلا نبدأ — ReadIn' : 'Get started — ReadIn');
    expect(profileBody).toEqual({ displayName: lang === 'ar' ? 'منى عادل' : 'Mona Adel', username: 'mona_adel', avatarUrl: null, headline: 'Backend engineer | .NET' });
  });

  test(`mandatory change password → set recovery PIN — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await prepare(page, context, baseURL!, variant);
    const reset = await writerMe(request, variant, { mustChangePassword: true, mustSetRecoveryPin: true, hasRecoveryPin: false });
    // The account as the API currently sees it (a reload restores this session).
    let current = reset;
    await onApi(page, 'POST', '/auth/refresh', (route) => reply(route, 200, sessionFor(current)));
    let passwordBody: any = null;
    await onApi(page, 'PUT', '/me/password', (route) => {
      passwordBody = route.request().postDataJSON();
      current = { ...reset, mustChangePassword: false };
      return reply(route, 200, sessionFor(current));
    });
    let pinBody: any = null;
    await onApi(page, 'POST', '/me/recovery-pin', (route) => {
      pinBody = route.request().postDataJSON();
      return reply(route, 200, { ...reset, mustChangePassword: false, mustSetRecoveryPin: false, hasRecoveryPin: true });
    });

    // The guards send a reset account to "change password" first, wherever it was going.
    await page.goto('/settings');
    await page.waitForURL('**/auth/change-password?returnUrl=%2Fsettings');
    await expect(page).toHaveTitle(lang === 'ar' ? 'غيّر كلمة السر — ReadIn' : 'Change your password — ReadIn');
    await page.locator('#must-current').fill('Temp-Pass-9912');
    await page.locator('#must-new').fill(NEW_PASSWORD);
    await page.locator('#must-confirm').fill(NEW_PASSWORD);
    await snap(page, variant, `must-change-password-${suffix}.png`);
    await page.locator('[data-change-password] [data-submit]').click();

    // Then the PIN, which can't be skipped (the last digits of the number are refused).
    await page.waitForURL('**/auth/recovery-pin?returnUrl=%2Fsettings');
    await expect(page).toHaveTitle(lang === 'ar' ? 'PIN الطوارئ — ReadIn' : 'Recovery PIN — ReadIn');
    expect(passwordBody).toEqual({ currentPassword: 'Temp-Pass-9912', newPassword: NEW_PASSWORD });
    // A later step can't be opened first.
    await page.goto('/auth/complete-profile');
    await page.waitForURL((url) => url.pathname === '/auth/recovery-pin');
    await typePin(page, 'set-pin', '4567');
    await expect(page.locator('#set-pin-error')).toBeVisible();
    await snap(page, variant, `set-pin-${suffix}.png`);
    await page.locator('#set-pin-0').click();
    await page.keyboard.type(GOOD_PIN);
    await typePin(page, 'set-pin-confirm', GOOD_PIN);
    await page.locator('[data-set-pin] [data-submit]').click();
    await page.waitForURL((url) => url.pathname === '/');
    expect(pinBody).toEqual({ pin: GOOD_PIN });
  });

  test(`settings → account: change number, change PIN, sign out — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await prepare(page, context, baseURL!, variant);
    const me = await writerMe(request, variant);
    await restoreSessionAs(page, me);
    let phoneBody: any = null;
    await onApi(page, 'PUT', '/me/phone', (route) => {
      phoneBody = route.request().postDataJSON();
      return reply(route, 200, sessionFor({ ...me, phoneNumber: phoneBody.newPhoneNumber }));
    });
    await onApi(page, 'PUT', '/me/recovery-pin', (route) => reply(route, 400, problem(400, 'auth.wrong_password')));
    let loggedOut = false;
    await onApi(page, 'POST', '/auth/logout', (route) => {
      loggedOut = true;
      return reply(route, 204);
    });

    await page.goto('/settings');
    const account = page.locator('[data-account]');
    await expect(account.locator('[data-account-phone]')).toHaveText('+20 10 01234567', { timeout: FIRST_RENDER_MS });
    // Scroll only once the web fonts are in: a late font swap moves the cards above by a pixel or two, and the
    // change-number shot below shows the page behind its sheet.
    await page.evaluate(() => document.fonts.ready.then(() => undefined));
    await account.scrollIntoViewIfNeeded();
    await imagesSettled(page);
    if (hasScreenshot(variant)) await expect(account).toHaveScreenshot(`settings-account-${suffix}.png`, { stylePath: HIDE_APP_CHROME });

    // Change number: new number + password → the confirm-number dialog → saved
    await account.locator('[data-open="phone"]').click();
    await page.locator('#change-phone-number').fill('+966501234567');
    await page.locator('#change-phone-password').fill(MOCK_PASSWORD);
    await page.locator('[data-change-phone] [data-submit]').click();
    const dialog = page.locator('[data-confirm-phone]');
    await expect(dialog.locator('[data-phone]')).toHaveText('+966 50 123 4567');
    await snapViewport(page, variant, `settings-change-phone-${suffix}.png`);
    await dialog.locator('[data-confirm]').click();
    await expect(dialog).toHaveCount(0);
    expect(phoneBody).toEqual({ newPhoneNumber: '+966501234567', currentPassword: MOCK_PASSWORD });
    await expect(account.locator('[data-account-phone]')).toHaveText('+966 50 123 4567');

    // Change PIN: a wrong current password is shown under that field
    await account.locator('[data-open="pin"]').click();
    await page.locator('#change-pin-password').fill('not-my-password-1');
    await typePin(page, 'change-pin-new', GOOD_PIN);
    await typePin(page, 'change-pin-confirm', GOOD_PIN);
    await page.locator('[data-change-pin] [data-submit]').click();
    await expect(page.locator('#change-pin-password-error')).toBeVisible();
    await snapViewport(page, variant, `settings-change-pin-${suffix}.png`);
    await page.keyboard.press('Escape');

    // Sign out (the API no longer restores the session afterwards)
    await page.unroute(`${API}/auth/refresh`);
    await account.locator('[data-sign-out]').click();
    await page.waitForURL((url) => url.pathname === '/');
    expect(loggedOut).toBe(true);
    await page.goto('/settings');
    await expect(page.locator('[data-account] a[href^="/auth/sign-in"]')).toBeVisible({ timeout: FIRST_RENDER_MS });
  });
}
