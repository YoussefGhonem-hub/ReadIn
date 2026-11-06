import { DestroyRef, afterRenderEffect, inject } from '@angular/core';

/**
 * Infinite scroll for the app's lists (Home, the profile's lists, tag, category, search…): calls `loadMore` when the
 * sentinel comes within 600 px of the viewport. Follows the sentinel when it is recreated (tabs, states). Browser only;
 * call it in an injection context.
 *
 * Render the sentinel only under a loaded list that has a next page (`@if (nextCursor())`), never beside the loading
 * skeletons: a sentinel that is already near while page 1 loads reports it, and that report can arrive once page 1 is
 * shown, loading page 2 at once on open. Created under the list, its first report is about where the list really ends
 * (a short first page then loads the next one, as it should). Reports about a sentinel that has since been replaced or
 * removed are ignored for the same reason.
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
        if (entries.some((e) => e.isIntersecting && e.target === observed && e.target.isConnected)) loadMore();
      },
      { rootMargin: '600px 0px' },
    );
    observer.disconnect();
    if (element) observer.observe(element);
  });
  inject(DestroyRef).onDestroy(() => observer?.disconnect());
}
