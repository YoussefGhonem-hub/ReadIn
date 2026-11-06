import { DestroyRef, Injectable, PLATFORM_ID, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import type { TranslocoService } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { translatePlural } from '../../shared/pipes/intl';
import { NotificationsApi } from '../api/notifications.api';
import { SessionStore } from '../auth/session.store';
import type { UiLanguage } from '../i18n/language.service';
import { UnreadLive } from '../realtime/unread-live';

/** How often the REST fallback asks for the count while the tab is visible. */
export const UNREAD_POLL_MS = 60_000;

/**
 * The unread-notifications badge (F17, SPEC §21.1) of the top bar and side nav: the live
 * `/live/users/{id}/unreadNotifications` value, or `GET /me/notifications/unread-count` while the Realtime Database
 * is unavailable (connecting, no custom token, SDK blocked) — then it is fetched on sign-in, every minute while the tab
 * is visible, when the tab comes back and after a push. Opening the center clears it at once. In the initial bundle.
 */
@Injectable({ providedIn: 'root' })
export class NotificationBadge {
  private readonly api = inject(NotificationsApi);
  /** The live count RealtimeService keeps (that service and the Firebase SDK load after the first page). */
  private readonly live = inject(UnreadLive);
  private readonly session = inject(SessionStore);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly restCount = signal(0);
  /** Bumped by every change of user and by "seen", so an older answer never overwrites a newer state. */
  private generation = 0;
  /** The `POST /me/notifications/seen` in flight, if any. */
  private seen: Promise<unknown> | null = null;

  /** The signed-in account, once its setup steps are done (before that the API refuses the calls). */
  private readonly userId = computed(() => (this.session.isAuthenticated() && !this.session.setupStep() ? (this.session.me()?.id ?? null) : null));

  /** Notifications not seen yet: what the badge shows. 0 for guests. */
  readonly count = computed(() => {
    if (!this.userId()) return 0;
    return this.live.live() ? this.live.count() : this.restCount();
  });

  constructor() {
    if (!this.isBrowser) return;
    let lastUser: string | null = null;
    effect((onCleanup) => {
      const userId = this.userId();
      const live = this.live.live();
      untracked(() => {
        if (userId !== lastUser) {
          lastUser = userId;
          this.generation++;
          this.restCount.set(0);
        }
      });
      if (!userId || live) return;

      untracked(() => void this.refresh());
      const refreshIfVisible = () => {
        if (document.visibilityState === 'visible') void this.refresh();
      };
      const timer = setInterval(refreshIfVisible, UNREAD_POLL_MS);
      document.addEventListener('visibilitychange', refreshIfVisible);
      onCleanup(() => {
        clearInterval(timer);
        document.removeEventListener('visibilitychange', refreshIfVisible);
      });
    });
    inject(DestroyRef).onDestroy(() => this.generation++);
  }

  /** Asks the API for the count when the live value is unavailable. Never throws. */
  async refresh(): Promise<void> {
    const userId = this.userId();
    if (!this.isBrowser || !userId || this.live.live()) return;
    if (this.seen) await this.seen; // a count asked for before "seen" lands would bring the old number back
    const generation = this.generation;
    try {
      const { unread } = await firstValueFrom(this.api.unreadCount());
      if (generation === this.generation && this.userId() === userId) this.restCount.set(toCount(unread));
    } catch {
      /* offline or an older API: keep the last count */
    }
  }

  /** The center was opened: the badge shows 0 at once, then `POST /me/notifications/seen`. Never throws. */
  async markSeen(): Promise<void> {
    if (!this.userId()) return;
    this.generation++;
    this.restCount.set(0);
    this.live.count.set(0); // the live count too (RealtimeService.clearUnreadNotifications)
    // Failing is fine: the count comes back with the next refresh and nothing else depends on it.
    const seen = firstValueFrom(this.api.markSeen()).catch(() => undefined);
    this.seen = seen;
    await seen;
    if (this.seen === seen) this.seen = null;
  }

  /**
   * `POST /me/notifications/{id}/read`, from the center or a tapped push. Idempotent; an id that is gone or someone
   * else's (`404 notification.not_found`) has nothing left to mark, so failures are ignored. Never throws.
   */
  async markRead(id: string): Promise<void> {
    if (!this.userId()) return;
    try {
      await firstValueFrom(this.api.markRead(id));
    } catch {
      /* gone, offline: it stays unread in the center, where it can be opened again */
    }
    void this.refresh();
  }
}

/** "Notifications", or "Notifications, 3 new" when there are unseen ones (the badge dot says nothing to a screen reader). */
export function notificationsLabel(transloco: TranslocoService, lang: UiLanguage, count: number): string {
  return count > 0 ? translatePlural(transloco, 'notifications.badgeLabel', count, lang) : transloco.translate('nav.notifications', {}, lang);
}

function toCount(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) && value > 0 ? Math.floor(value) : 0;
}
