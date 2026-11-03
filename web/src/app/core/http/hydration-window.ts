import { ApplicationRef, DOCUMENT, Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

/**
 * True in the browser from bootstrap until the app first becomes stable, on pages that were server-rendered —
 * the window in which Angular serves GET requests from the SSR transfer cache. Requests made then must not wait on
 * Firebase (async) or carry a token, otherwise they miss the cache and the first client render differs from the
 * server HTML (hydration mismatch). Client-rendered routes (RenderMode.Client) are never in this window.
 */
@Injectable({ providedIn: 'root' })
export class HydrationWindow {
  private readonly hydrating: boolean;
  private stable = false;

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    // Angular marks server-rendered root components with `ng-server-context`.
    this.hydrating = isBrowser && !!inject(DOCUMENT).querySelector('[ng-server-context]');
    if (this.hydrating) void inject(ApplicationRef).whenStable().then(() => (this.stable = true));
  }

  get isOpen(): boolean {
    return this.hydrating && !this.stable;
  }
}
