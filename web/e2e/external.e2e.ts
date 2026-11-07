import { Page, expect, test } from '@playwright/test';
import { HIDE_APP_CHROME, VARIANTS, hasScreenshot, onApi, problem, reply, restoreSessionAs, sessionFor, useVariant, writerMe } from './support/mock-api';

/* eslint-disable @typescript-eslint/no-explicit-any -- request bodies are plain JSON */

/**
 * Continue with Google / Apple (SPEC §9.2, F18, ADR 0012). Real Google tokens can't be minted here, so Google Identity
 * Services is replaced by a stub script that renders a plain button and hands the page a fake ID token (or, for our own
 * button, a fake one-time code); the mocked API decides what it means. The development build has a Google client id and no Apple Services ID, so Apple stays
 * hidden even when the API lists it.
 */
test.describe.configure({ timeout: 90_000 });

const FIRST_RENDER_MS = 30_000;
const GOOGLE_TOKEN = 'e2e-google-id-token';
const GOOGLE_CODE = 'e2e-google-auth-code';

/** Stands in for https://accounts.google.com/gsi/client (`google.accounts.id` and the code flow, `google.accounts.oauth2`). */
const FAKE_GIS = `
  window.google = { accounts: {
  oauth2: {
    initCodeClient(config) {
      window.__gisCode = config;
      return { requestCode() { window.__gisCodeRequests = (window.__gisCodeRequests || 0) + 1; config.callback({ code: '${GOOGLE_CODE}' }); } };
    },
  },
  id: {
    initialize(config) { window.__gis = config; },
    renderButton(parent, options) {
      const button = document.createElement('button');
      button.type = 'button';
      button.dataset.fakeGis = options.theme + ' ' + options.locale;
      button.textContent = 'Google';
      button.style.cssText = 'width:100%;height:40px;border:1px solid #888;border-radius:4px;background:transparent;color:inherit';
      button.onclick = () => window.__gis.callback({ credential: '${GOOGLE_TOKEN}' });
      parent.appendChild(button);
    },
  } } };
`;

async function prepare(
  page: Page,
  context: Parameters<typeof useVariant>[0],
  baseURL: string,
  variant: (typeof VARIANTS)[number],
  providers: string[],
  googleCodeSignIn = false,
) {
  await useVariant(context, baseURL, variant);
  await context.addInitScript(() => localStorage.setItem('readin.phoneCountry', 'EG'));
  await page.clock.setFixedTime(new Date('2026-11-03T09:00:00'));
  let gisLoads = 0;
  await page.route('https://accounts.google.com/gsi/client', (route) => {
    gisLoads++;
    return route.fulfill({ status: 200, contentType: 'text/javascript', body: FAKE_GIS });
  });
  await page.route('https://appleid.cdn-apple.com/**', (route) => route.abort());
  await onApi(page, 'GET', '/auth/config', (route) =>
    reply(route, 200, {
      pinLength: 4,
      password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true },
      externalProviders: providers,
      googleCodeSignIn,
    }),
  );
  return { gisLoads: () => gisLoads };
}

for (const variant of VARIANTS) {
  const { lang, theme } = variant;
  const suffix = `${lang}-${theme}`;

  test(`Google button shows only when the API offers it; not linked → create account — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await prepare(page, context, baseURL!, variant, ['google', 'apple']);
    const bodies: any[] = [];
    const created = await writerMe(request, variant, {
      displayName: 'reader_q8w7e6r5t4',
      username: 'reader_q8w7e6r5t4',
      phoneNumber: null,
      email: 'mona@gmail.com',
      isProfileComplete: false,
      onboardingCompleted: false,
      hasPassword: false,
      hasRecoveryPin: false,
      externalLogins: [{ provider: 'google', email: 'mona@gmail.com', linkedAt: '2026-11-03T09:00:00Z' }],
    });
    await onApi(page, 'POST', '/auth/external', (route) => {
      const body = route.request().postDataJSON();
      bodies.push(body);
      return body.createAccount ? reply(route, 200, sessionFor(created)) : reply(route, 404, problem(404, 'auth.external_not_linked'));
    });

    // Welcome: Google (official button, in the UI theme and language), no Apple without a Services ID
    await page.goto('/auth');
    const google = page.locator('[data-google-button] [data-fake-gis]');
    await expect(google).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(google).toHaveAttribute('data-fake-gis', `${theme === 'dark' ? 'filled_black' : 'outline'} ${lang}`);
    await expect(page.locator('[data-apple-button]')).toHaveCount(0);

    // Sign in: after "or"
    await page.goto('/auth/sign-in');
    await expect(google).toBeVisible({ timeout: FIRST_RENDER_MS });
    await google.click();

    // Not linked yet → the sheet; "create a new account" resends the same token
    const sheet = page.locator('[data-not-linked]');
    await expect(sheet).toBeVisible();
    expect(bodies[0]).toMatchObject({ provider: 'google', idToken: GOOGLE_TOKEN, uiLanguage: lang });
    if (hasScreenshot(variant)) await expect(page).toHaveScreenshot(`google-not-linked-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    await sheet.locator('[data-create]').click();
    await page.waitForURL('**/auth/complete-profile');
    expect(bodies[1]).toMatchObject({ provider: 'google', idToken: GOOGLE_TOKEN, createAccount: true });
  });

  test(`our own Google button sends Google's one-time code; not linked → create account resends it — ${suffix}`, async ({
    page,
    context,
    baseURL,
    request,
  }) => {
    const { gisLoads } = await prepare(page, context, baseURL!, variant, ['google'], true);
    const bodies: any[] = [];
    const created = await writerMe(request, variant, {
      displayName: 'reader_q8w7e6r5t4',
      username: 'reader_q8w7e6r5t4',
      phoneNumber: null,
      email: 'mona@gmail.com',
      isProfileComplete: false,
      onboardingCompleted: false,
      hasPassword: false,
      hasRecoveryPin: false,
      externalLogins: [{ provider: 'google', email: 'mona@gmail.com', linkedAt: '2026-11-03T09:00:00Z' }],
    });
    await onApi(page, 'POST', '/auth/external', (route) => {
      const body = route.request().postDataJSON();
      bodies.push(body);
      return body.createAccount ? reply(route, 200, sessionFor(created)) : reply(route, 404, problem(404, 'auth.external_not_linked'));
    });

    // Sign in: our button (the form's height, corners and border), not Google's; Google's script is loaded ahead of the click
    await page.goto('/auth/sign-in');
    const google = page.locator('button[data-google-code]');
    await expect(google).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(google).toHaveText(lang === 'ar' ? 'المتابعة باستخدام Google' : 'Continue with Google');
    await expect(page.locator('[data-fake-gis]')).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => !!(window as any).__gisCode)).toBe(true);
    expect(gisLoads()).toBe(1);
    const [signIn, button] = await Promise.all([page.locator('rd-submit-button button').boundingBox(), google.boundingBox()]);
    expect(Math.round(button!.height)).toBe(Math.round(signIn!.height));
    expect(Math.round(button!.width)).toBe(Math.round(signIn!.width)); // the whole form row, like "Sign in"
    if (hasScreenshot(variant)) {
      await expect(page.locator('rd-external-sign-in')).toHaveScreenshot(`google-code-button-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
    }

    await google.click();
    const sheet = page.locator('[data-not-linked]');
    await expect(sheet).toBeVisible();
    expect(bodies[0]).toMatchObject({ provider: 'google', authorizationCode: GOOGLE_CODE, uiLanguage: lang });
    expect(bodies[0].idToken).toBeUndefined();
    expect(await page.evaluate(() => (window as any).__gisCode.scope)).toBe('openid email profile');

    // The API keeps the token it traded the code for, so the same code goes again
    await sheet.locator('[data-create]').click();
    await page.waitForURL('**/auth/complete-profile');
    expect(bodies[1]).toMatchObject({ provider: 'google', authorizationCode: GOOGLE_CODE, createAccount: true });
  });

  test(`no providers → no buttons, no Google script — ${suffix}`, async ({ page, context, baseURL }) => {
    const { gisLoads } = await prepare(page, context, baseURL!, variant, []);
    await page.goto('/auth/sign-in');
    await expect(page.locator('#sign-in-phone')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await page.waitForLoadState('networkidle');
    await expect(page.locator('[data-external-buttons]')).toHaveCount(0);
    expect(gisLoads()).toBe(0);
  });

  test(`settings for a Google-only account: linked accounts, add phone sign in — ${suffix}`, async ({ page, context, baseURL, request }) => {
    await prepare(page, context, baseURL!, variant, ['google']);
    const me = await writerMe(request, variant, {
      phoneNumber: null,
      hasPassword: false,
      hasRecoveryPin: false,
      externalLogins: [{ provider: 'google', email: 'mona@gmail.com', linkedAt: '2026-11-03T09:00:00Z' }],
    });
    await restoreSessionAs(page, me);

    await page.goto('/settings');
    const account = page.locator('[data-account]');
    await expect(account.locator('[data-add-phone-row]')).toBeVisible({ timeout: FIRST_RENDER_MS });
    await expect(account.locator('[data-open="phone"]')).toHaveCount(0);
    await expect(account.locator('[data-provider="google"] [data-provider-status]')).toHaveText('mona@gmail.com');
    await account.scrollIntoViewIfNeeded();
    if (hasScreenshot(variant)) await expect(account).toHaveScreenshot(`settings-google-only-${suffix}.png`, { stylePath: HIDE_APP_CHROME });
  });
}
