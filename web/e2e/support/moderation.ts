import { randomUUID } from 'node:crypto';
import { APIRequestContext, Page } from '@playwright/test';
import { MOCK_ORIGIN, MockMe, Variant, restoreSessionAs, writerMe } from './mock-api';

/**
 * Reporting and moderation flows (F22). The mock API (e2e/mock-api/moderation.mjs) gives every moderator their own
 * copy of the seeded cases, so each test signs in as its own moderator (`u-mod-*`) and parallel tests never share a
 * queue. `u-warned-*` readers start with two moderation notices to acknowledge.
 *
 * The moderator is the SuperAdmin (SPEC §10: there is no Moderator role), with the permissions moderating needs; the
 * web only ever checks permissions.
 */
export async function signInAsModerator(page: Page, request: APIRequestContext, variant: Variant): Promise<MockMe> {
  const me = await writerMe(request, variant, {
    id: `u-mod-${randomUUID().slice(0, 8)}`,
    displayName: 'Hana Gamal',
    username: 'hana_mod',
    isVerified: false,
    roles: ['SuperAdmin'],
    permissions: ['articles.read', 'reactions.create', 'saved.manage', 'follows.manage', 'reports.create', 'moderation.manage', 'users.suspend'],
  });
  await restoreSessionAs(page, me);
  return me;
}

/** A reader with an unacknowledged warning and a hidden-article notice. */
export async function signInAsWarnedReader(page: Page, request: APIRequestContext, variant: Variant): Promise<MockMe> {
  const me = await writerMe(request, variant, {
    id: `u-warned-${randomUUID().slice(0, 8)}`,
    displayName: 'Sara Hassan',
    username: 'sara',
    isVerified: false,
    roles: ['Member'],
    permissions: ['articles.read', 'reactions.create', 'saved.manage', 'follows.manage', 'reports.create'],
  });
  await restoreSessionAs(page, me);
  return me;
}

/** What `viewer` reported about a target, as the mock API stored it (null when nothing was sent). */
export async function reportOf(request: APIRequestContext, viewer: string, type: string, id: string): Promise<{ reason: string; details: string | null } | null> {
  const response = await request.get(`${MOCK_ORIGIN}/__mock/reports?viewer=${encodeURIComponent(viewer)}&type=${type}&id=${encodeURIComponent(id)}`);
  return (await response.json()) as { reason: string; details: string | null } | null;
}
