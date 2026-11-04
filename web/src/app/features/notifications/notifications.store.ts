import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { NotificationDto } from '../../core/api/models';
import { NotificationsApi } from '../../core/api/notifications.api';
import { NotificationBadge } from '../../core/notifications/notification-badge';

export type NotificationsStatus = 'idle' | 'loading' | 'loaded' | 'error';

export const NOTIFICATIONS_PAGE_SIZE = 20;

/**
 * The notification center (F17): newest activity first, in cursor pages. Opening it marks everything seen (the badge
 * goes to 0); items stay unread until opened or "Mark all as read". Provided by the page.
 */
@Injectable()
export class NotificationsStore {
  private readonly api = inject(NotificationsApi);
  private readonly badge = inject(NotificationBadge);

  readonly status = signal<NotificationsStatus>('idle');
  readonly items = signal<NotificationDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  readonly markingAll = signal(false);
  readonly hasUnread = computed(() => this.items().some((n) => !n.isRead));
  /** When the first page arrived: "Today" is decided against it, so the sections don't move while you read. */
  readonly loadedAt = signal(new Date());
  private generation = 0;

  /** The center was opened: the first page, and `POST /me/notifications/seen` at the same time. */
  open(): Promise<void> {
    void this.badge.markSeen();
    return this.load();
  }

  /** New notifications arrived while the center is open: show them, and they are seen too. */
  refresh(): Promise<void> {
    void this.badge.markSeen();
    return this.load();
  }

  async load(): Promise<void> {
    const generation = ++this.generation;
    this.status.set('loading');
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.list({ limit: NOTIFICATIONS_PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.items.set(page.items ?? []);
      this.nextCursor.set(page.nextCursor ?? null);
      this.loadedAt.set(new Date());
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) this.status.set('error');
    }
  }

  async loadMore(): Promise<void> {
    const cursor = this.nextCursor();
    if (!cursor || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.list({ cursor, limit: NOTIFICATIONS_PAGE_SIZE }));
      if (generation !== this.generation) return;
      // An aggregated row that moved up while paging is already on screen: keep the first copy.
      const seen = new Set(this.items().map((n) => n.id));
      this.items.update((items) => [...items, ...(page.items ?? []).filter((n) => !seen.has(n.id))]);
      this.nextCursor.set(page.nextCursor ?? null);
    } catch {
      if (generation === this.generation) this.loadMoreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }

  /** Opened: read at once on screen, then `POST /me/notifications/{id}/read` (failures are ignored). */
  markRead(id: string): void {
    const item = this.items().find((n) => n.id === id);
    if (!item || item.isRead) return;
    this.setRead((n) => n.id === id);
    void this.badge.markRead(id);
  }

  /** `POST /me/notifications/read-all`; shown at once, undone (and rethrown) when it fails. */
  async markAllRead(): Promise<void> {
    if (this.markingAll()) return;
    const unread = new Set(this.items().filter((n) => !n.isRead).map((n) => n.id));
    this.markingAll.set(true);
    this.setRead(() => true);
    try {
      await firstValueFrom(this.api.markAllRead());
    } catch (error) {
      this.items.update((items) => items.map((n) => (unread.has(n.id) ? { ...n, isRead: false } : n)));
      throw error;
    } finally {
      this.markingAll.set(false);
    }
  }

  private setRead(which: (n: NotificationDto) => boolean): void {
    this.items.update((items) => items.map((n) => (!n.isRead && which(n) ? { ...n, isRead: true } : n)));
  }
}
