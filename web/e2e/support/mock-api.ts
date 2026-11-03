import { join } from 'node:path';
import { APIRequestContext, BrowserContext, Locator, Page, Route, expect } from '@playwright/test';

/**
 * E2E helpers. `e2e/mock-api/server.mjs` answers SSR and browser API calls with fixtures; tests add per-flow state
 * (uploads, create/publish, sessions, the new post in the feed) with `page.route`, so nothing depends on a running
 * backend. Sign in is the real phone + password page against the mocked `/auth/login`.
 */
/** The mock API (playwright.config.ts → MOCK_API_PORT; src/environments/environment.e2e.ts points the app at it). */
export const MOCK_ORIGIN = 'http://localhost:5180';
export const API = `${MOCK_ORIGIN}/api/v1`;
/** The mock API's demo account (e2e/mock-api/server.mjs). */
export const MOCK_PHONE = '+201001234567';
export const MOCK_PASSWORD = 'Readin2026!';

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

/** Credentialed CORS: the web sends cookies to `/auth/*`, so the origin is echoed (never `*`). */
function cors(route: Route): Record<string, string> {
  return {
    'access-control-allow-origin': route.request().headers()['origin'] ?? '*',
    'access-control-allow-credentials': 'true',
    'access-control-allow-headers': 'authorization, content-type, accept-language, x-requested-with, x-readin-client',
    'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    vary: 'Origin',
  };
}

/** Fulfills a routed call (and its CORS preflight) with JSON, or an empty body for `204`. */
export function reply(route: Route, status: number, body?: unknown): Promise<void> {
  if (route.request().method() === 'OPTIONS') return route.fulfill({ status: 204, headers: cors(route) });
  return route.fulfill({
    status,
    headers: { ...cors(route), ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
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

/** ProblemDetails with a stable `code` (and validation `errors`), like the API's. */
export function problem(status: number, code: string, errors?: Record<string, string[]>) {
  return { type: `https://readin.app/errors/${code}`, title: code, status, code, traceId: '00-e2e', ...(errors ? { errors } : {}) };
}

function base64Url(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

/** A `SessionDto` for `user`, as the API sends it to the web (the refresh token lives in a cookie: null here). */
export function sessionFor<T extends { id: string }>(user: T) {
  const iat = Math.floor(Date.now() / 1000);
  const accessToken = [base64Url({ alg: 'none', typ: 'JWT' }), base64Url({ sub: user.id, iat, exp: iat + 900 }), 'mock'].join('.');
  return {
    accessToken,
    accessTokenExpiresAt: new Date((iat + 900) * 1000).toISOString(),
    refreshToken: null,
    refreshTokenExpiresAt: new Date((iat + 30 * 86_400) * 1000).toISOString(),
    user,
  };
}

export type MockMe = Record<string, unknown> & { id: string };

/** The mock API's signed-in user (`GET /me`), in the variant's language and theme so signing in changes neither. */
export async function writerMe(request: APIRequestContext, variant: Variant, patch: Record<string, unknown> = {}): Promise<MockMe> {
  const me = (await (await request.get(`${API}/me`)).json()) as MockMe;
  return { ...me, uiLanguage: variant.lang, theme: variant.theme, ...patch };
}

/** Starts the page already signed in as `user`: `POST /auth/refresh` (the session restore on start) returns it. */
export async function restoreSessionAs(page: Page, user: { id: string }): Promise<void> {
  await onApi(page, 'POST', '/auth/refresh', (route) => reply(route, 200, sessionFor(user)));
}

/** Signs in as a verified writer (permission `articles.create`) through the real sign-in page, then lands on `returnUrl`. */
export async function signInAsWriter(page: Page, request: APIRequestContext, variant: Variant, returnUrl = '/write'): Promise<void> {
  const me = await writerMe(request, variant);
  await onApi(page, 'POST', '/auth/login', (route) => reply(route, 200, sessionFor(me)));
  await page.goto(`/auth/sign-in?returnUrl=${encodeURIComponent(returnUrl)}`);
  await page.locator('#sign-in-phone').fill(MOCK_PHONE);
  await page.locator('#sign-in-password').fill(MOCK_PASSWORD);
  await page.locator('form [data-submit]').click();
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

/** `stylePath` for shots of the reader's action bar: hides the comments section, which may still be loading. */
export const HIDE_COMMENTS = join(__dirname, 'hide-comments.css');

/** Moves the pointer off any card so hover-only UI (carousel arrows) isn't captured. */
export async function parkMouse(page: Page): Promise<void> {
  await page.mouse.move(1, 1);
}
