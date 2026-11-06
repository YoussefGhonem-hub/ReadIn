import { Injectable } from '@angular/core';

/**
 * The query parameter the service worker adds when a tapped push opens a new tab, so the page can mark that
 * notification read (`POST /me/notifications/{id}/read`) once the session is restored. The page removes it at once.
 */
export const NOTIFICATION_PARAM = 'notification';

/**
 * A tapped push opened this tab: an app initializer takes `?notification={id}` off the address before the router reads
 * it ({@link capture}), and PushService, which loads after the first page, takes the id to mark it read. Browser only.
 */
@Injectable({ providedIn: 'root' })
export class TappedNotification {
  private captured = false;
  private id: string | null = null;

  /** Removes the parameter from the address and keeps its id. Only the first call reads the address. */
  capture(): void {
    if (this.captured) return;
    this.captured = true;
    const url = new URL(location.href);
    if (!url.searchParams.has(NOTIFICATION_PARAM)) return;
    this.id = url.searchParams.get(NOTIFICATION_PARAM)?.trim() || null;
    url.searchParams.delete(NOTIFICATION_PARAM);
    history.replaceState(history.state, '', `${url.pathname}${url.search}${url.hash}`);
  }

  /** The tapped notification's id, once (null when the tab wasn't opened by a tap). */
  take(): string | null {
    this.capture();
    const id = this.id;
    this.id = null;
    return id;
  }
}
