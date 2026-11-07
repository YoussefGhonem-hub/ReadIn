import { Injectable, PendingTasks, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { ExploreApi } from '../../core/api/explore.api';
import { ExploreDto } from '../../core/api/models';
import { ArticleSocialStore } from '../../core/social/article-social.store';

export type ExploreStatus = 'loading' | 'loaded' | 'error';

/** Article rows each ranking shows on Explore; "See all" opens the rest as post cards. */
export const EXPLORE_PREVIEW_SIZE = 3;

/**
 * Explore (F15): every section in one call (`GET /explore`), server-rendered (PendingTasks keeps SSR waiting for it).
 * A refresh (your token after hydration, signing in or out) keeps the page on screen until it answers.
 */
@Injectable()
export class ExploreStore {
  private readonly api = inject(ExploreApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly tasks = inject(PendingTasks);

  readonly status = signal<ExploreStatus>('loading');
  readonly data = signal<ExploreDto | null>(null);
  private generation = 0;

  readonly fields = computed(() => this.data()?.fields ?? []);
  readonly trending = computed(() => (this.data()?.trending ?? []).slice(0, EXPLORE_PREVIEW_SIZE));
  readonly mostSaved = computed(() => (this.data()?.mostSaved ?? []).slice(0, EXPLORE_PREVIEW_SIZE));
  readonly newWriters = computed(() => this.data()?.newWriters ?? []);
  readonly featuredPaths = computed(() => this.data()?.featuredPaths ?? []);
  /** F23: the articles an admin featured (≤ 6, most recently featured first); `[]` or missing hides the section. */
  readonly featuredArticles = computed(() => this.data()?.featuredArticles ?? []);
  /** Every section is empty (a new install): the page says so instead of showing nothing. */
  readonly isEmpty = computed(() => {
    const data = this.data();
    return !!data && !data.fields.length && !data.trending.length && !data.mostSaved.length && !data.newWriters.length && !data.featuredPaths.length;
  });

  /** Everything (also the retry). */
  async load(): Promise<void> {
    const generation = ++this.generation;
    this.status.set('loading');
    this.data.set(null);
    const done = this.tasks.add();
    try {
      const data = await firstValueFrom(this.api.explore());
      if (generation !== this.generation) return;
      this.show(data);
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) this.status.set('error');
    } finally {
      done();
    }
  }

  /** Again with your token, keeping the page as it is until it answers; a page that had failed loads from scratch. */
  async refresh(): Promise<void> {
    if (this.status() !== 'loaded') return this.load();
    const generation = ++this.generation;
    try {
      const data = await firstValueFrom(this.api.explore());
      if (generation === this.generation) this.show(data);
    } catch {
      /* keep what is shown */
    }
  }

  private show(data: ExploreDto): void {
    this.social.absorb([...(data.featuredArticles ?? []), ...data.trending, ...data.mostSaved]);
    this.data.set(data);
  }
}
