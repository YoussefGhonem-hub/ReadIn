import { randomUUID } from 'node:crypto';
import { APIRequestContext, Page } from '@playwright/test';
import { MOCK_ORIGIN, MockMe, Variant, restoreSessionAs, writerMe } from './mock-api';

/**
 * Writer verification flows (F19). The mock API (e2e/mock-api/verification.mjs) keeps each requester's own requests
 * and gives every admin their own copy of the seeded review queue, so each test signs in as its own account.
 */
export const VERIFICATION_NOW = new Date('2026-11-04T10:00:00Z');

const READER_PERMISSIONS = ['articles.read', 'articles.create', 'reactions.create', 'saved.manage', 'follows.manage', 'reports.create'];

/** A member who can ask to be verified: `u-verify-*` (nothing yet), `u-verify-rejected-*` or `u-verify-approved-*`. */
export async function signInAsRequester(page: Page, request: APIRequestContext, variant: Variant, kind: 'new' | 'rejected' | 'approved' = 'new'): Promise<MockMe> {
  const prefix = kind === 'new' ? 'u-verify' : `u-verify-${kind}`;
  const me = await writerMe(request, variant, {
    id: `${prefix}-${randomUUID().slice(0, 8)}`,
    displayName: 'Sara Hassan',
    username: 'sara',
    isVerified: false,
    roles: ['Member'],
    permissions: READER_PERMISSIONS,
  });
  await restoreSessionAs(page, me);
  return me;
}

/**
 * An admin (`verification.manage`) with their own copy of the seeded requests: 2 pending, 1 approved, 1 rejected. The
 * admin is the SuperAdmin (SPEC §10: there is no Admin role), with the permissions this page needs.
 */
export async function signInAsVerificationAdmin(page: Page, request: APIRequestContext, variant: Variant): Promise<MockMe> {
  const me = await writerMe(request, variant, {
    id: `u-admin-${randomUUID().slice(0, 8)}`,
    displayName: 'Hana Gamal',
    username: 'hana_admin',
    isVerified: false,
    roles: ['SuperAdmin'],
    permissions: [...READER_PERMISSIONS, 'verification.manage', 'taxonomy.manage'],
  });
  await restoreSessionAs(page, me);
  return me;
}

export interface RequesterState {
  verified: boolean;
  requests: { id: string; status: string; fieldId: string; jobTitle: string; proofUrl: string | null; proofFile: { fileName: string; contentType: string } | null; note: string | null }[];
  submissions: { fields: Record<string, string>; file: { name: string; type: string; size: number } | null }[];
}

/** What the mock API holds for a requester: their requests and every form they sent. */
export async function requesterOf(request: APIRequestContext, viewer: string): Promise<RequesterState> {
  return (await (await request.get(`${MOCK_ORIGIN}/__mock/verification?viewer=${encodeURIComponent(viewer)}`)).json()) as RequesterState;
}

/** An admin's requests by id: their status and rejection reason now. */
export async function reviewOf(request: APIRequestContext, admin: string): Promise<Record<string, { status: string; rejectionReason: string | null }>> {
  const body = (await (await request.get(`${MOCK_ORIGIN}/__mock/verification?viewer=${encodeURIComponent(admin)}`)).json()) as {
    requests: Record<string, { status: string; rejectionReason: string | null }>;
  };
  return body.requests;
}

/** Who has the Verified badge for an admin now, by user id (the writers of that admin's requests). */
export async function badgesOf(request: APIRequestContext, admin: string): Promise<Record<string, boolean>> {
  const body = (await (await request.get(`${MOCK_ORIGIN}/__mock/verification?viewer=${encodeURIComponent(admin)}`)).json()) as { verified: Record<string, boolean> };
  return body.verified;
}
