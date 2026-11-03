import { Injectable, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { FollowsApi } from '../../core/api/follows.api';
import { UserSummaryDto } from '../../core/api/models';
import { FollowStore } from '../../core/social/follow.store';
import { LoadStatus } from './profile-articles.store';

export type PeopleList = 'followers' | 'following';

const PAGE_SIZE = 20;

/**
 * Followers / Following of one user (F12, F14): newest first, searched by name or @username, in cursor pages. A new
 * user, list or search starts over; answers for an older one are dropped.
 */
@Injectable()
export class PeopleStore {
  private readonly api = inject(FollowsApi);
  private readonly follows = inject(FollowStore);

  readonly status = signal<LoadStatus>('idle');
  readonly items = signal<UserSummaryDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  /** The applied search (the page debounces typing). */
  readonly query = signal('');
  private target: { userId: string; list: PeopleList } | null = null;
  private generation = 0;

  /** Shows `list` of `userId`; another user or list starts without a search. */
  open(userId: string, list: PeopleList): Promise<void> {
    if (this.target?.userId === userId && this.target.list === list && this.status() !== 'idle') return Promise.resolve();
    this.target = { userId, list };
    this.query.set('');
    return this.load();
  }

  setQuery(query: string): void {
    const trimmed = query.trim();
    if (this.query() === trimmed) return;
    this.query.set(trimmed);
    void this.load();
  }

  async load(): Promise<void> {
    const target = this.target;
    if (!target) return;
    const generation = ++this.generation;
    this.status.set('loading');
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.fetch(target, null));
      if (generation !== this.generation) return;
      this.accept(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) this.status.set('error');
    }
  }

  async loadMore(): Promise<void> {
    const target = this.target;
    const cursor = this.nextCursor();
    if (!target || !cursor || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.fetch(target, cursor));
      if (generation !== this.generation) return;
      const seen = new Set(this.items().map((u) => u.id));
      this.accept(page.items);
      this.items.update((items) => [...items, ...page.items.filter((u) => !seen.has(u.id))]);
      this.nextCursor.set(page.nextCursor);
    } catch {
      if (generation === this.generation) this.loadMoreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }

  private fetch(target: { userId: string; list: PeopleList }, cursor: string | null) {
    const query = { q: this.query() || null, cursor, limit: PAGE_SIZE };
    return target.list === 'followers' ? this.api.followers(target.userId, query) : this.api.following(target.userId, query);
  }

  /** Fresh rows are the truth for who you follow. */
  private accept(users: UserSummaryDto[]): void {
    for (const user of users) this.follows.absorb(user.id, user.isFollowing);
  }
}
