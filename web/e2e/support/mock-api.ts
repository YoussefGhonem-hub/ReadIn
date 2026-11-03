import { join } from 'node:path';
import { APIRequestContext, BrowserContext, Locator, Page, Route, expect } from '@playwright/test';

/**
 * E2E helpers. `e2e/mock-api/server.mjs` answers SSR and browser API calls with fixtures; tests add per-flow state
 * (uploads, create/publish, the new post in the feed) with `page.route`, and sign in through a mocked Firebase Auth
 * emulator, so nothing depends on a running backend.
 */
export const MOCK_ORIGIN = 'http://localhost:5080';
export const API = `${MOCK_ORIGIN}/api/v1`;
const AUTH_EMULATOR = 'http://127.0.0.1:9099';

export interface Variant {
  lang: 'ar' | 'en';
  theme: 'light' | 'dark';
  dir: 'rtl' | 'ltr';
}

/** SPEC §15.5 rule 9: every screen in ar/en × light/dark. */
export const VARIANTS: readonly Variant[] = [
  { lang: 'ar', theme: 'light', dir: 'rtl' },
  { lang: 'ar', theme: 'dark', dir: 'rtl' },
  { lang: 'en', theme: 'light', dir: 'ltr' },
  { lang: 'en', theme: 'dark', dir: 'ltr' },
];

export async function useVariant(context: BrowserContext, baseURL: string, { lang, theme }: Variant): Promise<void> {
  const { hostname } = new URL(baseURL);
  await context.addCookies([
    { name: 'lang', value: lang, domain: hostname, path: '/' },
    { name: 'theme', value: theme, domain: hostname, path: '/' },
  ]);
}

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
};

/** Fulfills a routed call (and its CORS preflight) with JSON, or an empty body for `204`. */
export function reply(route: Route, status: number, body?: unknown): Promise<void> {
  if (route.request().method() === 'OPTIONS') return route.fulfill({ status: 204, headers: CORS });
  return route.fulfill({
    status,
    headers: { ...CORS, ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
    body: body === undefined ? '' : JSON.stringify(body),
  });
}

/** Routes one API endpoint for a single HTTP method; preflights are answered, other methods fall through. */
export async function onApi(page: Page, method: string, path: string | RegExp, handler: (route: Route) => Promise<void>): Promise<void> {
  const url = typeof path === 'string' ? `${API}${path}` : path;
  await page.route(url, (route) => {
    const requestMethod = route.request().method();
    if (requestMethod === 'OPTIONS') return reply(route, 204);
    return requestMethod === method ? handler(route) : route.fallback();
  });
}

function base64Url(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

/**
 * Firebase Auth emulator REST endpoints (the dev build connects to http://127.0.0.1:9099). The ID token is an
 * unsigned JWT, which is what the emulator issues too; the mock API never verifies it.
 */
export async function mockFirebaseAuth(page: Page): Promise<void> {
  const now = Math.floor(Date.now() / 1000);
  const user = { localId: 'firebase-writer', email: 'writer@readin.test', displayName: 'Mona Adel' };
  const idToken = [
    base64Url({ alg: 'none', typ: 'JWT' }),
    base64Url({
      iss: 'https://securetoken.google.com/demo-readin',
      aud: 'demo-readin',
      auth_time: now,
      user_id: user.localId,
      sub: user.localId,
      iat: now,
      exp: now + 3600,
      email: user.email,
      email_verified: true,
      name: user.displayName,
      firebase: { identities: { email: [user.email] }, sign_in_provider: 'password' },
    }),
    'mock',
  ].join('.');

  await page.route(`${AUTH_EMULATOR}/**`, (route) => {
    const url = route.request().url();
    if (url.includes('accounts:signInWithPassword')) {
      return reply(route, 200, { kind: 'identitytoolkit#VerifyPasswordResponse', ...user, idToken, registered: true, refreshToken: 'mock-refresh', expiresIn: '3600' });
    }
    if (url.includes('accounts:lookup')) {
      return reply(route, 200, {
        kind: 'identitytoolkit#GetAccountInfoResponse',
        users: [
          {
            ...user,
            emailVerified: true,
            providerUserInfo: [{ providerId: 'password', email: user.email, federatedId: user.email, rawId: user.email, displayName: user.displayName }],
            validSince: String(now),
            lastLoginAt: String(now * 1000),
            createdAt: String(now * 1000),
          },
        ],
      });
    }
    if (url.includes('securetoken.googleapis.com')) {
      return reply(route, 200, { access_token: idToken, expires_in: '3600', token_type: 'Bearer', refresh_token: 'mock-refresh', id_token: idToken, user_id: user.localId, project_id: 'demo-readin' });
    }
    return reply(route, 404, { error: { message: 'NOT_MOCKED' } });
  });
}

/** Signs in as a verified writer (permission `articles.create`) through the real sign-in page, then lands on `returnUrl`. */
export async function signInAsWriter(page: Page, request: APIRequestContext, variant: Variant, returnUrl = '/write'): Promise<void> {
  await mockFirebaseAuth(page);
  const me = { ...(await (await request.get(`${API}/me`)).json()), uiLanguage: variant.lang, theme: variant.theme };
  await onApi(page, 'POST', '/auth/sync', (route) => reply(route, 200, me));
  await page.goto(`/auth/sign-in?returnUrl=${encodeURIComponent(returnUrl)}`);
  await page.locator('#email').fill(me.email);
  await page.locator('#password').fill('a-long-demo-password');
  await page.locator('form button[type="submit"]').click();
  await page.waitForURL((url) => url.pathname === returnUrl);
}

export async function fixture<T>(request: APIRequestContext, path: string): Promise<T> {
  const response = await request.get(`${MOCK_ORIGIN}${path}`);
  expect(response.ok(), path).toBe(true);
  return (await response.json()) as T;
}

/** A generated PNG to pick in the composer (the same pictures the mock media URLs serve). */
export async function pngFile(request: APIRequestContext, name: string, width: number, height: number) {
  const response = await request.get(`${MOCK_ORIGIN}/__mock/png?seed=${encodeURIComponent(name)}&w=${width}&h=${height}`);
  return { name, mimeType: 'image/png', buffer: await response.body() };
}

/** The multipart `filename` of an upload (images keep their name through client-side compression). */
export function uploadedFileName(route: Route): string | null {
  return /filename="([^"]+)"/.exec(route.request().postDataBuffer()?.toString('latin1') ?? '')?.[1] ?? null;
}

export function multipartField(route: Route, name: string): string | null {
  const body = route.request().postDataBuffer()?.toString('utf8') ?? '';
  return new RegExp(`name="${name}"\\r\\n\\r\\n([^\\r]*)\\r\\n`).exec(body)?.[1] ?? null;
}

/**
 * Waits until the images inside `scope` that intersect the viewport have loaded (lazy ones off-screen are skipped),
 * and at least `min` of them are visible, so a collapsed (zero-size) image can't pass unnoticed.
 */
export async function imagesLoaded(scope: Locator, min = 1): Promise<void> {
  await scope.scrollIntoViewIfNeeded(); // lazy images only load near the viewport
  await expect
    .poll(
      () =>
        scope.evaluate((root, minimum) => {
          const visible = [...root.querySelectorAll('img')].filter((img) => {
            const r = img.getBoundingClientRect();
            return r.width > 1 && r.height > 1 && r.bottom > 0 && r.right > 0 && r.top < innerHeight && r.left < innerWidth;
          });
          return visible.length >= minimum && visible.every((img) => img.complete && img.naturalWidth > 0);
        }, min),
      { timeout: 15_000 },
    )
    .toBe(true);
}

/** `stylePath` for screenshots: hides the sticky top bar, bottom nav and toasts so they don't overlap the element. */
export const HIDE_APP_CHROME = join(__dirname, 'hide-app-chrome.css');

/** Moves the pointer off any card so hover-only UI (carousel arrows) isn't captured. */
export async function parkMouse(page: Page): Promise<void> {
  await page.mouse.move(1, 1);
}
