import { Injectable, PendingTasks, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { WriterCategoriesApi } from '../../core/api/categories.api';
import { ArticleCardDto, WriterCategoryPageDto } from '../../core/api/models';
import { ArticleSocialStore } from '../../core/social/article-social.store';

export type CategoryPageStatus = 'loading' | 'loaded' | 'notFound' | 'error';

export const CATEGORY_PAGE_SIZE = 20;

/**
 * A category page (F31): the header (`GET /users/{username}/categories/{slug}`) and its articles, newest first, in
 * cursor pages. Both load together and are server-rendered (PendingTasks keeps SSR waiting for them). An unknown slug
 * (`category.not_found`) or writer (`user.not_found`) is `notFound`. A newer page or refresh drops older answers.
 */
@Injectable()
export class CategoryPageStore {
  private readonly api = inject(WriterCategoriesApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly tasks = inject(PendingTasks);

  readonly status = signal<CategoryPageStatus>('loading');
  /** `category.not_found` (the writer exists: link back to the profile) or `user.not_found`. */
  readonly notFoundCode = signal<string | null>(null);
  readonly category = signal<WriterCategoryPageDto | null>(null);
  readonly items = signal<ArticleCardDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  private key: { username: string; slug: string } | null = null;
  private generation = 0;

  /** The header and the first page (also the retry). */
  async load(username: string, slug: string): Promise<void> {
    this.key = { username, slug };
    const generation = ++this.generation;
    this.status.set('loading');
    this.notFoundCode.set(null);
    this.category.set(null);
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    // Keeps SSR waiting until the state is set, not just until the HTTP calls end.
    const done = this.tasks.add();
    try {
      const [header, page] = await Promise.allSettled([
        firstValueFrom(this.api.page(username, slug)),
        firstValueFrom(this.api.articles(username, slug, { limit: CATEGORY_PAGE_SIZE })),
      ]);
      if (generation !== this.generation) return;
      if (header.status === 'rejected' || page.status === 'rejected') {
        const error = header.status === 'rejected' ? header.reason : (page as PromiseRejectedResult).reason;
        const notFound = isApiError(error) && error.status === 404;
        this.notFoundCode.set(notFound ? error.code : null);
        this.status.set(notFound ? 'notFound' : 'error');
        return;
      }
      this.social.absorb(page.value.items);
      this.category.set(header.value);
      this.items.set(page.value.items);
      this.nextCursor.set(page.value.nextCursor);
      this.status.set('loaded');
    } finally {
      done();
    }
  }

  /** The first page again with your token (after hydration, signing in or out), keeping the list until it answers. */
  async refresh(): Promise<void> {
    const key = this.key;
    if (!key) return;
    if (this.status() !== 'loaded') return this.load(key.username, key.slug);
    const generation = ++this.generation;
    try {
      const page = await firstValueFrom(this.api.articles(key.username, key.slug, { limit: CATEGORY_PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.social.absorb(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
      this.loadMoreFailed.set(false);
    } catch {
      /* keep what is shown */
    }
  }

  /** The next page (infinite scroll, or "Retry" after a failure). */
  async loadMore(): Promise<void> {
    const cursor = this.nextCursor();
    const key = this.key;
    if (!cursor || !key || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.articles(key.username, key.slug, { cursor, limit: CATEGORY_PAGE_SIZE }));
      if (generation !== this.generation) return;
      const seen = new Set(this.items().map((a) => a.id));
      this.social.absorb(page.items);
      this.items.update((items) => [...items, ...page.items.filter((a) => !seen.has(a.id))]);
      this.nextCursor.set(page.nextCursor);
    } catch {
      if (generation === this.generation) this.loadMoreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }
}
