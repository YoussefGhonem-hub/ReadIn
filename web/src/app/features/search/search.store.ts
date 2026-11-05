import { Injectable, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { CursorPage, SearchArticleDto, SearchTopicDto, SearchType, TagDto, UserSummaryDto } from '../../core/api/models';
import { SearchApi, SearchResultOf } from '../../core/api/search.api';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { SEARCH_PAGE_SIZE, SearchRequest, filtersOf, hasFilters, isSearchable, sameSearch } from './search-query';

/**
 * `idle`: no query (the page shows recent searches). `invalid`: nothing to search for (no letter or digit, or the API
 * said `search.query_invalid`). `loading` also stays on the server, which never searches: results are personal and
 * the rate limit counts per IP, so the browser asks once hydrated.
 */
export type SearchStatus = 'idle' | 'invalid' | 'loading' | 'loaded' | 'error';

type SearchResult = SearchResultOf[SearchType];

/** One id per result, to drop a repeat when results shift between pages. */
function idOf(type: SearchType, item: SearchResult): string {
  switch (type) {
    case 'articles':
      return (item as SearchArticleDto).article.id;
    case 'users':
      return (item as UserSummaryDto).id;
    case 'topics':
      return `${(item as SearchTopicDto).kind}:${(item as SearchTopicDto).id}`;
    case 'tags':
      return (item as TagDto).slug;
  }
}

/**
 * The search page's results (F16): one tab of `GET /search` for the URL's query, in cursor pages. A new query, tab or
 * filter starts a new list and drops answers to the older one. Articles feed the shared reaction/save state, so the
 * compact rows show yours.
 */
@Injectable()
export class SearchStore {
  private readonly api = inject(SearchApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly request = signal<SearchRequest | null>(null);
  readonly status = signal<SearchStatus>('idle');
  /** Why the last search failed (`rate_limited`, a network error…), for the error state's message. */
  readonly error = signal<unknown>(null);
  private readonly items = signal<readonly SearchResult[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  private generation = 0;

  private readonly typed = <T extends SearchType>(type: T) => computed(() => (this.request()?.type === type ? (this.items() as readonly SearchResultOf[T][]) : []));
  readonly articles = this.typed('articles');
  readonly users = this.typed('users');
  readonly topics = this.typed('topics');
  readonly tags = this.typed('tags');
  readonly count = computed(() => this.items().length);
  readonly hasFilters = computed(() => hasFilters(this.request()));

  /** Shows `request`; the search already shown (or loading) stays as it is. */
  open(request: SearchRequest | null): void {
    if (sameSearch(request, this.request()) && this.status() !== 'error') return;
    this.request.set(request);
    void this.load();
  }

  /** The first page (also the error state's Retry). */
  async load(): Promise<void> {
    const request = this.request();
    const generation = ++this.generation;
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    this.error.set(null);
    if (!request) return this.status.set('idle');
    if (!isSearchable(request.q)) return this.status.set('invalid');
    this.status.set('loading');
    if (!this.isBrowser) return;
    try {
      const page = await this.fetch(request, null);
      if (generation !== this.generation) return;
      this.accept(request.type, page.items);
      this.items.set(this.unique(request.type, [], page.items));
      this.nextCursor.set(page.nextCursor);
      this.status.set('loaded');
    } catch (error) {
      if (generation !== this.generation) return;
      this.error.set(error);
      this.status.set(isApiError(error) && error.code === 'search.query_invalid' ? 'invalid' : 'error');
    }
  }

  /** The first page again with your token (you signed in or out), keeping the list on screen until it answers. */
  async refresh(): Promise<void> {
    const request = this.request();
    if (!request || this.status() !== 'loaded') return this.load();
    const generation = ++this.generation;
    try {
      const page = await this.fetch(request, null);
      if (generation !== this.generation) return;
      this.accept(request.type, page.items);
      this.items.set(this.unique(request.type, [], page.items));
      this.nextCursor.set(page.nextCursor);
      this.loadingMore.set(false);
      this.loadMoreFailed.set(false);
    } catch {
      /* keep what is shown */
    }
  }

  /** The next page (infinite scroll, or Retry after a failure). */
  async loadMore(): Promise<void> {
    const request = this.request();
    const cursor = this.nextCursor();
    if (!request || !cursor || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await this.fetch(request, cursor);
      if (generation !== this.generation) return;
      this.accept(request.type, page.items);
      this.items.update((items) => this.unique(request.type, items, page.items));
      this.nextCursor.set(page.nextCursor);
    } catch {
      if (generation === this.generation) this.loadMoreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }

  private fetch(request: SearchRequest, cursor: string | null): Promise<CursorPage<SearchResult>> {
    return firstValueFrom(this.api.search(request.q, request.type, { filters: filtersOf(request), cursor, limit: SEARCH_PAGE_SIZE }));
  }

  /** `items` followed by the new ones it doesn't have yet. */
  private unique(type: SearchType, items: readonly SearchResult[], incoming: readonly SearchResult[]): SearchResult[] {
    const seen = new Set(items.map((item) => idOf(type, item)));
    const result = [...items];
    for (const item of incoming) {
      const id = idOf(type, item);
      if (seen.has(id)) continue;
      seen.add(id);
      result.push(item);
    }
    return result;
  }

  private accept(type: SearchType, items: readonly SearchResult[]): void {
    if (type === 'articles') this.social.absorb((items as SearchArticleDto[]).map((r) => r.article));
  }
}
