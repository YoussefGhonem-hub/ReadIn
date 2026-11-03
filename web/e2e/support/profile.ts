import { APIRequestContext, Page, expect } from '@playwright/test';
import { API, MockMe, Variant, onApi, reply, sessionFor } from './mock-api';
import { signInAsReader } from './social';

/**
 * Profile flows (F14). The mock API keeps each viewer's own profile (e2e/mock-api/profiles.mjs); every test reader is
 * "Sara Hassan" (@sara) to themselves. The session restore asks the mock for the viewer's current `GET /me`, so a
 * reload after an edit shows what the server saved, like the real `POST /auth/refresh`.
 */
export async function signInWithLiveProfile(
  page: Page,
  request: APIRequestContext,
  variant: Variant,
  start: 'seeded' | 'fresh' = 'seeded',
): Promise<MockMe> {
  const me = await signInAsReader(page, request, variant, start);
  const token = sessionFor(me).accessToken;
  await onApi(page, 'POST', '/auth/refresh', async (route) => {
    const current = await (await request.get(`${API}/me`, { headers: { authorization: `Bearer ${token}` } })).json();
    // The variant's language and theme, so restoring the session changes neither.
    await reply(route, 200, sessionFor({ ...current, uiLanguage: variant.lang, theme: variant.theme }));
  });
  return me;
}

/**
 * Opens a profile and waits until it has loaded: signed in, the server-rendered (anonymous) profile is loaded again
 * with your token once the session is restored.
 */
export async function openProfile(page: Page, path: string, options: { signedIn?: boolean } = {}): Promise<void> {
  const username = path.slice(2).split('/')[0];
  const personalized = options.signedIn
    ? page.waitForResponse(
        (r) => r.request().method() === 'GET' && new URL(r.url()).pathname.endsWith(`/users/${username}`) && !!r.request().headers()['authorization'],
      )
    : null;
  await page.goto(path);
  await personalized;
  await expect(page.locator('[data-profile-header]')).toBeVisible({ timeout: 30_000 });
}

/** The reading stats card and heatmap have loaded (they render in the browser only). */
export async function readingStatsLoaded(page: Page): Promise<void> {
  const section = page.locator('[data-profile-reading]');
  await expect(section.locator('rd-reading-stats-card .rd-skeleton')).toHaveCount(0, { timeout: 30_000 });
  await expect(section.locator('rd-reading-heatmap [role="group"]')).toBeVisible();
}
