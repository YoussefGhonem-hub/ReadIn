import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { FieldDto, SavedArticleDto } from '../../core/api/models';
import { SavedApi } from '../../core/api/saved.api';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { CollectionsStore } from '../../core/social/collections.store';

export type SavedStatus = 'idle' | 'loading' | 'loaded' | 'error';

const PAGE_SIZE = 20;

/**
 * The Saved page (F13): newest saved first, filtered by field, title search and one collection. Every filter change
 * starts a new list; responses for an older filter are dropped. Unsaving (from any card) or taking an article out of
 * the open collection hides it at once, and brings it back if the change fails.
 */
@Injectable()
export class SavedStore {
  private readonly api = inject(SavedApi);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly collections = inject(CollectionsStore);

  readonly fields = signal<FieldDto[]>([]);
  /** Field slug. */
  readonly field = signal<string | null>(null);
  /** The applied title search (the page debounces typing). */
  readonly query = signal('');
  /** Collection id. */
  readonly collection = signal<string | null>(null);
  readonly status = signal<SavedStatus>('idle');
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  private readonly items = signal<SavedArticleDto[]>([]);
  private generation = 0;

  readonly hasFilters = computed(() => !!this.field() || !!this.query() || !!this.collection());
  readonly visible = computed(() => {
    const collection = this.collection();
    return this.items().filter((item) => {
      if (!this.social.state(item.article).isSaved) return false;
      return !collection || (this.collections.collectionsOf(item.article.id)?.has(collection) ?? true);
    });
  });

  init(): Promise<unknown> {
    // Fresh collection counts every time the page opens (other pages only change them locally).
    return Promise.all([this.loadFields(), this.collections.load(true), this.load()]);
  }

  setField(slug: string | null): void {
    if (this.field() === slug) return;
    this.field.set(slug);
    void this.load();
  }

  setQuery(query: string): void {
    const trimmed = query.trim();
    if (this.query() === trimmed) return;
    this.query.set(trimmed);
    void this.load();
  }

  setCollection(id: string | null): void {
    if (this.collection() === id) return;
    this.collection.set(id);
    void this.load();
  }

  clearFilters(): void {
    this.field.set(null);
    this.query.set('');
    this.collection.set(null);
    void this.load();
  }

  async load(): Promise<void> {
    const generation = ++this.generation;
    this.status.set('loading');
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadMoreFailed.set(false);
    this.loadingMore.set(false);
    try {
      const page = await firstValueFrom(this.api.list({ ...this.filters(), limit: PAGE_SIZE }));
      if (generation !== this.generation) return; // a newer filter won
      this.accept(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
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
      const page = await firstValueFrom(this.api.list({ ...this.filters(), cursor, limit: PAGE_SIZE }));
      if (generation !== this.generation) return;
      const seen = new Set(this.items().map((i) => i.article.id));
      this.accept(page.items);
      this.items.update((items) => [...items, ...page.items.filter((i) => !seen.has(i.article.id))]);
      this.nextCursor.set(page.nextCursor);
    } catch {
      if (generation === this.generation) this.loadMoreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }

  private filters() {
    return { field: this.field(), q: this.query() || null, collection: this.collection() };
  }

  /** Fresh rows are the truth for save state and collection membership. */
  private accept(items: SavedArticleDto[]): void {
    this.social.absorb(items.map((i) => i.article));
    this.collections.learn(items);
  }

  private async loadFields(): Promise<void> {
    try {
      this.fields.set(await firstValueFrom(this.taxonomy.fields()));
    } catch {
      /* chips are optional; the list still works */
    }
  }
}
