import { computed, signal } from '@angular/core';
import { Observable, firstValueFrom } from 'rxjs';
import { CursorPage } from '../../core/api/models';

export type ListStatus = 'loading' | 'loaded' | 'error';

/**
 * A cursor-paged list (the moderation queue and log): `load` starts over (a newer load wins over a slower older one),
 * `loadMore` appends the next page without duplicates and can be retried after a failure.
 */
export class CursorList<T> {
  private readonly _items = signal<T[]>([]);
  private readonly _status = signal<ListStatus>('loading');
  private readonly _next = signal<string | null>(null);
  private readonly _loadingMore = signal(false);
  private readonly _moreFailed = signal(false);
  private generation = 0;

  readonly items = this._items.asReadonly();
  readonly status = this._status.asReadonly();
  readonly hasMore = computed(() => this._next() !== null);
  readonly loadingMore = this._loadingMore.asReadonly();
  readonly moreFailed = this._moreFailed.asReadonly();

  constructor(
    private readonly fetch: (cursor: string | null) => Observable<CursorPage<T>>,
    private readonly key: (item: T) => string,
  ) {}

  async load(): Promise<void> {
    const generation = ++this.generation;
    this._status.set('loading');
    this._items.set([]);
    this._next.set(null);
    this._loadingMore.set(false);
    this._moreFailed.set(false);
    try {
      const page = await firstValueFrom(this.fetch(null));
      if (generation !== this.generation) return;
      this._items.set(page.items);
      this._next.set(page.nextCursor);
      this._status.set('loaded');
    } catch {
      if (generation === this.generation) this._status.set('error');
    }
  }

  async loadMore(): Promise<void> {
    const cursor = this._next();
    if (!cursor || this._loadingMore() || this._status() !== 'loaded') return;
    const generation = this.generation;
    this._loadingMore.set(true);
    this._moreFailed.set(false);
    try {
      const page = await firstValueFrom(this.fetch(cursor));
      if (generation !== this.generation) return;
      const seen = new Set(this._items().map(this.key));
      this._items.update((items) => [...items, ...page.items.filter((item) => !seen.has(this.key(item)))]);
      this._next.set(page.nextCursor);
    } catch {
      if (generation === this.generation) this._moreFailed.set(true);
    } finally {
      if (generation === this.generation) this._loadingMore.set(false);
    }
  }
}
