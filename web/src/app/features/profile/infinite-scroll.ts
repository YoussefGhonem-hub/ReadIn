import { DestroyRef, afterRenderEffect, inject } from '@angular/core';

/**
 * Infinite scroll for the profile lists: calls `loadMore` when the sentinel comes within 600 px of the viewport.
 * Follows the sentinel when it is recreated (tabs, states). Browser only; call it in an injection context.
 */
export function loadMoreNearEnd(sentinel: () => HTMLElement | undefined, loadMore: () => void): void {
  let observer: IntersectionObserver | null = null;
  let observed: HTMLElement | undefined;
  afterRenderEffect(() => {
    const element = sentinel();
    if (element === observed || typeof IntersectionObserver === 'undefined') return;
    observed = element;
    observer ??= new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) loadMore();
      },
      { rootMargin: '600px 0px' },
    );
    observer.disconnect();
    if (element) observer.observe(element);
  });
  inject(DestroyRef).onDestroy(() => observer?.disconnect());
}
