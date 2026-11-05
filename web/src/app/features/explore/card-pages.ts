import { PendingTasks, inject, signal } from '@angular/core';
import { Observable, firstValueFrom } from 'rxjs';
import { ArticleCardDto, CursorPage } from '../../core/api/models';
import { ArticleSocialStore } from '../../core/social/article-social.store';

export type CardPagesStatus = 'loading' | 'loaded' | 'error';

/** One cursor page of cards from wherever the list comes from (`cursor` null: the first page). */
export type CardSource = (cursor: string | null) => Observable<CursorPage<ArticleCardDto>>;

/**
 * A list of post cards (F34) in cursor pages, for the Explore rankings and a field's articles (F15): the first page
 * (server-rendered: PendingTasks keeps SSR waiting for it), the next ones near the end (infinite scroll) with Retry
 * after a failure, and a quiet refresh with your token. Rankings move while people read, so a card already shown is
 * never added twice. A newer source or refresh drops older answers. Create it in an injection context.
 */
export class CardPages {
  private readonly social = inject(ArticleSocialStore);
  private readonly tasks = inject(PendingTasks);

  readonly status = signal<CardPagesStatus>('loading');
  /** Why the first page failed (an `ApiError`), for the page to tell a missing topic from a network error. */
  readonly error = signal<unknown>(null);
  readonly items = signal<ArticleCardDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  private source: CardSource | null = null;
  private generation = 0;

  /** The first page from `source` (or the current one again: the retry). */
  async load(source: CardSource | null = this.source): Promise<void> {
    if (!source) return;
    this.source = source;
    const generation = ++this.generation;
    this.status.set('loading');
    this.error.set(null);
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    // Keeps SSR waiting until the state is set, not just until the HTTP call ends.
    const done = this.tasks.add();
    try {
      const page = await firstValueFrom(source(null));
      if (generation !== this.generation) return;
      this.social.absorb(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
      this.status.set('loaded');
    } catch (error) {
      if (generation !== this.generation) return;
      this.error.set(error);
      this.status.set('error');
    } finally {
      done();
    }
  }

  /**
   * The first page again with your token (after hydration, or signing in or out), keeping the list on screen until it
   * answers; a list that had failed loads from scratch.
   */
  async refresh(): Promise<void> {
    const source = this.source;
    if (!source) return;
    if (this.status() !== 'loaded') return this.load(source);
    const generation = ++this.generation;
    try {
      const page = await firstValueFrom(source(null));
      if (generation !== this.generation) return;
      this.social.absorb(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
      this.loadingMore.set(false);
      this.loadMoreFailed.set(false);
    } catch {
      /* keep what is shown */
    }
  }

  /** The next page (infinite scroll, or "Retry" after a failure). */
  async loadMore(): Promise<void> {
    const cursor = this.nextCursor();
    const source = this.source;
    if (!cursor || !source || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(source(cursor));
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
