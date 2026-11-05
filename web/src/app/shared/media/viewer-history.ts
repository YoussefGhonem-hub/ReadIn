import { Injectable, PLATFORM_ID, Provider, inject } from '@angular/core';
import { BrowserPlatformLocation, LocationChangeListener, PlatformLocation, isPlatformBrowser } from '@angular/common';

/** Marks the history entry the full-screen viewer pushes (`history.state[MEDIA_VIEWER_HISTORY_KEY]`). */
export const MEDIA_VIEWER_HISTORY_KEY = 'rdMediaViewer';

function isViewerState(state: unknown): boolean {
  return !!state && typeof state === 'object' && !!(state as Record<string, unknown>)[MEDIA_VIEWER_HISTORY_KEY];
}

/**
 * Which history entry the tab is on: one the full-screen viewer pushed (F26) or not, and the URL the app last knew.
 *
 * The viewer pushes an entry of its own, on the page's own URL, so the browser Back closes it. Moving into or out of
 * that entry is not a navigation, and the router must not hear it: for a `popstate` that lands on the URL it is already
 * on, the router skips the navigation (`NavigationSkipped`) but its scroller still emits a `Scroll` event with no saved
 * position, and `withInMemoryScrolling` then scrolls the page to the top. That is why closing the viewer used to leave
 * the reader at the top of the feed. {@link ViewerAwarePlatformLocation} asks this service about every `popstate`
 * before the router sees it.
 */
@Injectable({ providedIn: 'root' })
export class MediaViewerHistory {
  private onViewerEntry = false;
  private href: string | null = null;
  private leave: (() => void) | null = null;

  /** Where the tab starts (a reload can land on an entry the viewer pushed before). */
  start(state: unknown, href: string): void {
    this.onViewerEntry = isViewerState(state);
    this.href = href;
  }

  /** The viewer pushed its entry (same URL). */
  pushed(href: string): void {
    this.onViewerEntry = true;
    this.href = href;
  }

  /** The app pushed or replaced an entry (a router navigation): not the viewer's. */
  navigated(href: string): void {
    this.onViewerEntry = false;
    this.href = href;
  }

  /** While a viewer is open: what to do when a popstate leaves its entry (Back closes it); null once it is closed. */
  onLeave(listener: (() => void) | null): void {
    this.leave = listener;
  }

  /**
   * A `popstate` (the browser is already on the entry it names). True when it only enters or leaves the viewer's entry
   * on the same URL: not a navigation, so the router must not hear it. Leaving the entry closes an open viewer.
   */
  popped(state: unknown, href: string): boolean {
    const toViewer = isViewerState(state);
    const fromViewer = this.onViewerEntry;
    const sameUrl = href === this.href;
    this.onViewerEntry = toViewer;
    this.href = href;
    if (!toViewer) this.leave?.();
    return (toViewer || fromViewer) && sameUrl;
  }
}

/**
 * The browser's PlatformLocation, except that the viewer's own history moves (see {@link MediaViewerHistory}) never
 * reach Angular's Location, so the router neither navigates nor scrolls for them. Everything else is untouched.
 */
@Injectable()
export class ViewerAwarePlatformLocation extends BrowserPlatformLocation {
  private readonly viewerHistory = inject(MediaViewerHistory);

  constructor() {
    super();
    this.viewerHistory.start(this.getState(), this.href);
  }

  override onPopState(fn: LocationChangeListener): VoidFunction {
    return super.onPopState((event) => {
      if (this.viewerHistory.popped((event as PopStateEvent).state, this.href)) return;
      fn(event);
    });
  }

  override pushState(state: unknown, title: string, url: string): void {
    super.pushState(state, title, url);
    this.viewerHistory.navigated(this.href);
  }

  override replaceState(state: unknown, title: string, url: string): void {
    super.replaceState(state, title, url);
    this.viewerHistory.navigated(this.href);
  }
}

/**
 * App config: in the browser, the PlatformLocation that keeps the full-screen viewer's history moves from the router
 * (F26); on the server, the server's own (there is no history there).
 */
export function provideMediaViewerHistory(): Provider {
  return {
    provide: PlatformLocation,
    useFactory: () => (isPlatformBrowser(inject(PLATFORM_ID)) ? new ViewerAwarePlatformLocation() : inject(PlatformLocation, { skipSelf: true })),
  };
}
