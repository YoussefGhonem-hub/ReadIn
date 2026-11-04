/* eslint-disable @typescript-eslint/no-explicit-any -- DTOs come from the mock API as plain JSON */
import { randomUUID } from 'node:crypto';
import { APIRequestContext, Locator, Page, expect } from '@playwright/test';
import { MockMe, Variant, restoreSessionAs, writerMe } from './mock-api';

/**
 * The article editor (F05). The mock API keeps each writer's articles (e2e/mock-api/editor.mjs), so every test signs
 * in as its own writer: `seeded` writers start with two drafts (one untitled) and two published articles (one with
 * unpublished changes); `fresh` writers start with nothing.
 */
export async function signInAsAuthor(page: Page, request: APIRequestContext, variant: Variant, start: 'seeded' | 'fresh' = 'seeded'): Promise<MockMe> {
  const id = `${start === 'seeded' ? 'u-author' : 'u-writer-new'}-${randomUUID().slice(0, 8)}`;
  const me = await writerMe(request, variant, {
    id,
    displayName: 'Mona Adel',
    username: 'mona',
    isVerified: true,
    roles: ['Member', 'VerifiedWriter'],
    permissions: ['articles.read', 'articles.create'],
  });
  await restoreSessionAs(page, me);
  return me;
}

/** The ids the seeded writer's articles have (`{writer}-d1` …). */
export function seededIds(me: MockMe) {
  return { draft: `${me.id}-d1`, untitled: `${me.id}-d2`, changed: `${me.id}-p1`, published: `${me.id}-p2` };
}

/** The editor finished loading (content editable, settings and checks rendered). */
export async function editorReady(page: Page): Promise<void> {
  await expect(page.locator('[data-editor]')).toBeVisible({ timeout: 30_000 });
  await expect(page.locator('[data-editor]')).toHaveAttribute('contenteditable', 'true');
}

/** Waits for the autosave (10 s after the first change) to reach the server. */
export async function savedToServer(page: Page): Promise<void> {
  await expect(page.locator('[data-save-status]')).toHaveAttribute('data-state', 'saved', { timeout: 25_000 });
}

/** Types into the block editor at the end of the content. */
export async function typeInEditor(page: Page, text: string): Promise<void> {
  const editor = page.locator('[data-editor]');
  await editor.click();
  await page.keyboard.press('ControlOrMeta+End');
  await page.keyboard.type(text);
}

/** Picks a block from the slash menu (`/` then the query, then Enter). */
export async function insertBlock(page: Page, query: string, option: string): Promise<void> {
  await page.keyboard.type(`/${query}`);
  const menu = page.locator('[data-slash-menu]');
  await expect(menu.locator(`[data-block-option="${option}"]`)).toBeVisible();
  await expect(menu.locator('[aria-selected="true"]')).toHaveAttribute('data-block-option', option);
  await page.keyboard.press('Enter');
  await expect(menu).toHaveCount(0);
}

/** Problems listed by the live checks (their codes). */
export async function problemCodes(page: Page): Promise<string[]> {
  return page.locator('[data-problems] [data-problem]').evaluateAll((items) => items.map((i) => i.getAttribute('data-problem') ?? ''));
}

export function myArticle(page: Page, id: string): Locator {
  return page.locator(`[data-my-article="${id}"]`);
}

/** The draft document the editor last sent (`POST /articles` or `PUT /articles/{id}/draft`). */
export function trackSavedDocument(page: Page): () => any {
  let last: any = null;
  page.on('request', (request) => {
    const { pathname } = new URL(request.url());
    if (request.method() === 'POST' && pathname.endsWith('/api/v1/articles')) last = request.postDataJSON();
    else if (request.method() === 'PUT' && /\/api\/v1\/articles\/[^/]+\/draft$/.test(pathname)) last = request.postDataJSON()?.document;
  });
  return () => last;
}

/** Presses Publish (or Update) and resolves with the `PublishedArticleDto`. */
export async function publish(page: Page): Promise<any> {
  const response = page.waitForResponse((r) => r.request().method() === 'POST' && r.url().endsWith('/publish') && r.status() === 200, { timeout: 30_000 });
  await page.locator('[data-publish]').click();
  return (await response).json();
}
