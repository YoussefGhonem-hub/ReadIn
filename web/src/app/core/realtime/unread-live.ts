import { Injectable, signal } from '@angular/core';

/**
 * The signed-in user's unread-notifications count from the Realtime Database (`/live/users/{id}/unreadNotifications`),
 * kept by RealtimeService and read by the top bar's badge (NotificationBadge). A store of its own, so the badge is in
 * the initial bundle while RealtimeService and the Firebase SDK load after the first page.
 */
@Injectable({ providedIn: 'root' })
export class UnreadLive {
  /** 0 for guests and until the first value arrives. */
  readonly count = signal(0);
  /** True once the count has a value from the Realtime Database. */
  readonly live = signal(false);
}
