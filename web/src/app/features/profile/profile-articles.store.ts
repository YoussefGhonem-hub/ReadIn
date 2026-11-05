import { Injectable, PendingTasks, inject, signal } from '@angular/core';
import { Observable, firstValueFrom } from 'rxjs';
import { ArticleCardDto, CursorPage } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { ArticleSocialStore } from '../../core/social/article-social.store';

export type LoadStatus = 'idle' | 'loading' | 'loaded' | 'error';

const PAGE_SIZE = 20;

/**
 * The profile's Articles tab (F14): published articles, newest first, in cursor pages. Server-rendered with the
 * profile (PendingTasks keeps SSR waiting for it); a newer username or refresh drops older answers.
 */
@Injectable()
export class ProfileArticlesStore {
  protected readonly api = inject(ProfilesApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly tasks = inject(PendingTasks);

  readonly status = signal<LoadStatus>('idle');
  readonly items = signal<ArticleCardDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly loadMoreFailed = signal(false);
  private username: string | null = null;
  private generation = 0;

  /** First page for `username` (also the retry and the refresh after sign in). */
  async load(username: string): Promise<void> {
    this.username = username;
    const generation = ++this.generation;
    this.status.set('loading');
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.loadMoreFailed.set(false);
    // Keeps SSR waiting until the state is set, not just until the HTTP call ends.
    const done = this.tasks.add();
    try {
      const page = await firstValueFrom(this.page(username, { limit: PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.social.absorb(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) {
        this.items.set([]);
        this.status.set('error');
      }
    } finally {
      done();
    }
  }

  /**
   * Loads the first page again (with your token after hydration), keeping the current list on screen until it answers;
   * a list that had failed loads from scratch.
   */
  async refresh(): Promise<void> {
    const username = this.username;
    if (!username) return;
    if (this.status() !== 'loaded') return this.load(username);
    const generation = ++this.generation;
    try {
      const page = await firstValueFrom(this.page(username, { limit: PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.social.absorb(page.items);
      this.items.set(page.items);
      this.nextCursor.set(page.nextCursor);
      this.loadMoreFailed.set(false);
    } catch {
      /* keep what is shown */
    }
  }

  async loadMore(): Promise<void> {
    const cursor = this.nextCursor();
    const username = this.username;
    if (!cursor || !username || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.page(username, { cursor, limit: PAGE_SIZE }));
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

  /** One page of the list (the Reposts tab's store reads another endpoint). */
  protected page(username: string, query: { cursor?: string | null; limit: number }): Observable<CursorPage<ArticleCardDto>> {
    return this.api.articles(username, query);
  }
}
