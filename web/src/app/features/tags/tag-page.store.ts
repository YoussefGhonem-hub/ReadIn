import { Injectable, PendingTasks, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticleCardDto, TagDto } from '../../core/api/models';
import { TagsApi } from '../../core/api/tags.api';
import { ArticleSocialStore } from '../../core/social/article-social.store';

export type TagPageStatus = 'loading' | 'loaded' | 'notFound' | 'error';

export const TAG_PAGE_SIZE = 20;

const isNotFound = (error: unknown) => isApiError(error) && error.status === 404;

/**
 * A tag page (F32): the tag (`GET /tags/{slug}`) and its articles, newest first, in cursor pages
 * (`GET /tags/{slug}/articles`). Both load together and are server-rendered (PendingTasks keeps SSR waiting for them);
 * an unknown or hidden tag is `notFound`. A newer slug or refresh drops older answers.
 */
@Injectable()
export class TagPageStore {
  private readonly api = inject(TagsApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly tasks = inject(PendingTasks);

  readonly status = signal<TagPageStatus>('loading');
  readonly tag = signal<TagDto | null>(null);
  readonly items = signal<ArticleCardDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  private slug: string | null = null;
  private generation = 0;

  /** The tag and its first page (also the retry). */
  async load(slug: string): Promise<void> {
    this.slug = slug;
    const generation = ++this.generation;
    this.status.set('loading');
    this.tag.set(null);
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    // Keeps SSR waiting until the state is set, not just until the HTTP calls end.
    const done = this.tasks.add();
    try {
      const [tag, page] = await Promise.allSettled([firstValueFrom(this.api.tag(slug)), firstValueFrom(this.api.articles(slug, { limit: TAG_PAGE_SIZE }))]);
      if (generation !== this.generation) return;
      if (tag.status === 'rejected' || page.status === 'rejected') {
        const error = tag.status === 'rejected' ? tag.reason : (page as PromiseRejectedResult).reason;
        this.status.set(isNotFound(error) ? 'notFound' : 'error');
        return;
      }
      this.social.absorb(page.value.items);
      this.tag.set(tag.value);
      this.items.set(page.value.items);
      this.nextCursor.set(page.value.nextCursor);
      this.status.set('loaded');
    } finally {
      done();
    }
  }

  /**
   * The first page again with your token (after hydration, or signing in or out), keeping the list on screen until it
   * answers; a page that had failed loads from scratch.
   */
  async refresh(): Promise<void> {
    const slug = this.slug;
    if (!slug) return;
    if (this.status() !== 'loaded') return this.load(slug);
    const generation = ++this.generation;
    try {
      const page = await firstValueFrom(this.api.articles(slug, { limit: TAG_PAGE_SIZE }));
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
    const slug = this.slug;
    if (!cursor || !slug || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.articles(slug, { cursor, limit: TAG_PAGE_SIZE }));
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
