import { DestroyRef, ElementRef, Signal, afterNextRender, computed, effect, inject, signal, untracked } from '@angular/core';
import { LiveArticleCounts, RealtimeService } from './realtime.service';

/**
 * Live counters of the article `articleId()`, listening only while it returns an id. Returning null pauses the
 * listener (e.g. a card scrolled out of view) and keeps the last values. Must run in an injection context.
 */
export function injectLiveCounts(articleId: () => string | null | undefined): Signal<LiveArticleCounts | null> {
  const realtime = inject(RealtimeService);
  const counts = signal<LiveArticleCounts | null>(null);
  let lastId: string | null = null;
  effect((onCleanup) => {
    const id = articleId() ?? null;
    if (!id) return;
    if (id !== lastId) {
      lastId = id;
      untracked(() => counts.set(null));
    }
    onCleanup(realtime.watchArticle(id, (value) => counts.set(value)));
  });
  return counts.asReadonly();
}

/** True while the host element is in or near the viewport. Always false during SSR. */
export function injectInViewport(rootMargin = '200px 0px'): Signal<boolean> {
  const host = inject<ElementRef<HTMLElement>>(ElementRef);
  const destroyRef = inject(DestroyRef);
  const visible = signal(false);
  afterNextRender(() => {
    if (typeof IntersectionObserver === 'undefined') return;
    const observer = new IntersectionObserver((entries) => visible.set(entries.some((entry) => entry.isIntersecting)), { rootMargin });
    observer.observe(host.nativeElement);
    destroyRef.onDestroy(() => observer.disconnect());
  });
  return visible.asReadonly();
}

export interface NewArticlesSignal {
  /** True once an article was published after the feed was loaded. */
  readonly available: Signal<boolean>;
  /** Call when the feed is reloaded: the current latest article becomes the baseline. */
  acknowledge(): void;
}

/** Drives the "new articles ↑" banner from `/live/feed/latestPublishedAt` (F27). */
export function injectNewArticles(): NewArticlesSignal {
  const realtime = inject(RealtimeService);
  const latest = signal<number | null>(null);
  const baseline = signal<number | null>(null);
  const stop = realtime.watchLatestPublished((publishedAt) => {
    latest.set(publishedAt);
    // The first value describes what the feed already has (nothing published yet counts as 0).
    if (baseline() === null) baseline.set(publishedAt ?? 0);
  });
  inject(DestroyRef).onDestroy(stop);
  return {
    available: computed(() => {
      const current = latest();
      const seen = baseline();
      return current !== null && seen !== null && current > seen;
    }),
    acknowledge: () => baseline.set(latest() ?? 0),
  };
}
