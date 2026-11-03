import { randomUUID } from 'node:crypto';
import { APIRequestContext, Locator, Page, expect } from '@playwright/test';
import { MockMe, Variant, restoreSessionAs, writerMe } from './mock-api';

/**
 * Reactions, saved and follow flows (F10, F12, F13). The mock API keeps that state per signed-in viewer (the bearer
 * token's `sub`, see e2e/mock-api/social.mjs), so every test signs in as its own reader and parallel tests never share
 * state. `seeded` readers start like the demo data (two reactions, five saved articles in two collections, following
 * ReadIn and Karim); `fresh` readers start with nothing.
 */
export async function signInAsReader(page: Page, request: APIRequestContext, variant: Variant, start: 'seeded' | 'fresh' = 'seeded'): Promise<MockMe> {
  const id = `${start === 'fresh' ? 'u-new' : 'u-viewer'}-${randomUUID().slice(0, 8)}`;
  const me = await writerMe(request, variant, {
    id,
    displayName: 'Sara Hassan',
    username: 'sara',
    isVerified: false,
    roles: ['Member'],
    permissions: ['articles.read', 'reactions.create', 'saved.manage', 'follows.manage'],
  });
  await restoreSessionAs(page, me);
  return me;
}

/**
 * Opens an article and waits until the reader has your reactions, save and follow state: SSR renders it anonymously
 * and the page loads it again with your token once the session is restored.
 */
export async function openArticle(page: Page, path: string): Promise<void> {
  const slug = path.split('/').pop()!;
  const personalized = page.waitForResponse(
    (r) => r.request().method() === 'GET' && new URL(r.url()).pathname.endsWith(`/articles/${slug}`) && !!r.request().headers()['authorization'],
  );
  await page.goto(path);
  await personalized;
  await expect(page.locator('rd-article-action-bar [data-react]')).toBeVisible();
}

/** The soft sign-in prompt (F01) opened, then closed with "Not now". */
export async function expectSignInPrompt(page: Page): Promise<void> {
  const dialog = page.locator('rd-sign-in-prompt [role="dialog"]');
  await expect(dialog).toBeVisible();
  await dialog.locator('.rd-btn-ghost').click();
  await expect(dialog).toHaveCount(0);
}

/** Text of a count, e.g. the reader's reaction total. */
export async function countOf(locator: Locator): Promise<number> {
  return Number((await locator.textContent())?.trim().replace(/[^\d]/g, ''));
}
