import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticlesApi } from '../../core/api/articles.api';
import { ArticleStatus, MyArticleDto } from '../../core/api/models';

export type MyArticlesStatus = 'idle' | 'loading' | 'loaded' | 'error';

const PAGE_SIZE = 20;

interface TabState {
  status: MyArticlesStatus;
  items: MyArticleDto[];
  nextCursor: string | null;
  loadingMore: boolean;
  loadMoreFailed: boolean;
}

const EMPTY_TAB: TabState = { status: 'idle', items: [], nextCursor: null, loadingMore: false, loadMoreFailed: false };

/**
 * "My articles" (F05, `GET /me/articles`): the Drafts and Published tabs, each paged with its own cursor and loaded
 * the first time it is shown. Deleting removes the row at once and puts it back if the request fails.
 */
@Injectable()
export class MyArticlesStore {
  private readonly api = inject(ArticlesApi);

  readonly tab = signal<ArticleStatus>('draft');
  private readonly tabs = signal<Record<ArticleStatus, TabState>>({ draft: EMPTY_TAB, published: EMPTY_TAB });
  /** Bumped on every reload, so responses for an older list are dropped. */
  private generation: Record<ArticleStatus, number> = { draft: 0, published: 0 };

  readonly current = computed(() => this.tabs()[this.tab()]);
  readonly items = computed(() => this.current().items);
  readonly status = computed(() => this.current().status);
  readonly hasMore = computed(() => !!this.current().nextCursor);
  readonly deleting = signal<string | null>(null);

  /** Shows a tab, loading it the first time. */
  select(tab: ArticleStatus): void {
    this.tab.set(tab);
    if (this.tabs()[tab].status === 'idle') void this.load(tab);
  }

  async load(tab: ArticleStatus = this.tab()): Promise<void> {
    const generation = ++this.generation[tab];
    this.patch(tab, { ...EMPTY_TAB, status: 'loading' });
    try {
      const page = await firstValueFrom(this.api.mine({ status: tab, limit: PAGE_SIZE }));
      if (generation !== this.generation[tab]) return;
      this.patch(tab, { status: 'loaded', items: page.items, nextCursor: page.nextCursor });
    } catch {
      if (generation === this.generation[tab]) this.patch(tab, { status: 'error' });
    }
  }

  async loadMore(): Promise<void> {
    const tab = this.tab();
    const state = this.tabs()[tab];
    if (!state.nextCursor || state.loadingMore || state.status !== 'loaded') return;
    const generation = this.generation[tab];
    this.patch(tab, { loadingMore: true, loadMoreFailed: false });
    try {
      const page = await firstValueFrom(this.api.mine({ status: tab, cursor: state.nextCursor, limit: PAGE_SIZE }));
      if (generation !== this.generation[tab]) return;
      const seen = new Set(this.tabs()[tab].items.map((i) => i.id));
      this.patch(tab, { items: [...this.tabs()[tab].items, ...page.items.filter((i) => !seen.has(i.id))], nextCursor: page.nextCursor, loadingMore: false });
    } catch {
      if (generation === this.generation[tab]) this.patch(tab, { loadingMore: false, loadMoreFailed: true });
    }
  }

  /** Deletes an article (`DELETE /articles/{id}`). Resolves with the error code, or null when deleted. */
  async delete(article: MyArticleDto): Promise<string | null> {
    const tab = article.status;
    const before = this.tabs()[tab].items;
    const index = before.findIndex((i) => i.id === article.id);
    this.deleting.set(article.id);
    this.patch(tab, { items: before.filter((i) => i.id !== article.id) });
    try {
      await firstValueFrom(this.api.delete(article.id));
      return null;
    } catch (error) {
      const code = isApiError(error) ? error.code : 'unknown';
      if (code === 'article.not_found') return null; // already gone
      const items = [...this.tabs()[tab].items];
      items.splice(Math.min(index, items.length), 0, article);
      this.patch(tab, { items });
      return code;
    } finally {
      this.deleting.set(null);
    }
  }

  private patch(tab: ArticleStatus, patch: Partial<TabState>): void {
    this.tabs.update((tabs) => ({ ...tabs, [tab]: { ...tabs[tab], ...patch } }));
  }
}
