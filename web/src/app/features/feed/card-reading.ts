import { DOCUMENT, PLATFORM_ID, Signal, computed, effect, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TrackedArticle, injectReadingTracker } from '../article/reading-tracker';

/** How much of `el` has been above the bottom of the viewport (0..1): 1 once its end has been on screen. */
export function seenFraction(el: HTMLElement, viewportHeight: number): number {
  const rect = el.getBoundingClientRect();
  if (rect.height <= 0) return 0;
  return Math.min(1, Math.max(0, (viewportHeight - rect.top) / rect.height));
}

/**
 * Counting as read from a post card (F34, C7): an article shown whole in the card (`article()` set: expanded, with a
 * complete preview) counts under the F04 rule, ≥ 70% seen and ≥ 30 s active, through the reader's own reporting
 * (`PUT /articles/{id}/progress`, reading-tracker.ts). Progress is the share of the card's text that has been on
 * screen; time counts only while the card is in view, and no position is sent, so the reader's resume point stays.
 * A cut-off article never counts from the card. Browser only, signed-in users only (the tracker checks).
 */
export function injectCardReading(article: Signal<TrackedArticle | null>, element: () => HTMLElement, inView: Signal<boolean>): void {
  if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
  const window = inject(DOCUMENT).defaultView;
  if (!window) return;
  const progress = signal(0);
  const tracked = computed(() => (inView() ? article() : null), { equal: (a, b) => a?.id === b?.id && a?.language === b?.language });

  // The highest share seen while the card is tracked; a new article (or version) starts again.
  let frame = 0;
  const measure = () => {
    frame = 0;
    progress.update((seen) => Math.max(seen, seenFraction(element(), window.innerHeight)));
  };
  const onScroll = () => {
    if (!frame) frame = window.requestAnimationFrame(measure);
  };
  let measuredFor: string | null = null;
  effect((onCleanup) => {
    const current = tracked();
    if (!current) return;
    const key = `${current.id}|${current.language}`;
    if (key !== measuredFor) {
      measuredFor = key;
      progress.set(0);
    }
    measure();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll, { passive: true });
    onCleanup(() => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
      if (frame) window.cancelAnimationFrame(frame);
      frame = 0;
    });
  });
  injectReadingTracker(tracked, progress, undefined, undefined, { reportPosition: false });
}
