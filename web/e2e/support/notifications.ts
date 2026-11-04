import { randomUUID } from 'node:crypto';
import { APIRequestContext, Page } from '@playwright/test';
import { MOCK_ORIGIN, MockMe, Variant, restoreSessionAs, writerMe } from './mock-api';

/**
 * Notification flows (F17). The mock API (e2e/mock-api/notifications.mjs) gives every `u-notified-*` reader their own
 * 25 notifications (4 unseen, 5 unread), relative to NOTIFICATIONS_NOW, so each test signs in as its own reader.
 */
export const NOTIFICATIONS_NOW = new Date('2026-11-04T10:00:00Z');

export async function signInAsNotifiedReader(page: Page, request: APIRequestContext, variant: Variant): Promise<MockMe> {
  const me = await writerMe(request, variant, {
    id: `u-notified-${randomUUID().slice(0, 8)}`,
    displayName: 'Sara Hassan',
    username: 'sara',
    isVerified: false,
    roles: ['Member'],
    permissions: ['articles.read', 'reactions.create', 'saved.manage', 'follows.manage', 'reports.create'],
  });
  await restoreSessionAs(page, me);
  return me;
}

export interface NotificationsState {
  read: string[];
  unseen: number;
  settings: { quietHours: { enabled: boolean; start: string; end: string }; types: Record<string, string> };
  puts: unknown[];
}

/** The viewer's notifications and settings as the mock API holds them now. */
export async function notificationsOf(request: APIRequestContext, viewer: string): Promise<NotificationsState> {
  const response = await request.get(`${MOCK_ORIGIN}/__mock/notifications?viewer=${encodeURIComponent(viewer)}`);
  return (await response.json()) as NotificationsState;
}
