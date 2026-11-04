import { Location } from '@angular/common';
import { DestroyRef, Injectable, computed, inject, signal } from '@angular/core';
import { NavigationEnd, NavigationStart, Router } from '@angular/router';

/**
 * Where this tab's history stands within the app: how many entries of the app come before the current one. An in-app
 * Back (the reader's, F04) goes back in history when the previous entry is a page of the app, and somewhere sensible
 * otherwise (the page was opened from a link, a new tab, a notification or a reload). Created at start-up
 * (app.config.ts) so it sees the first navigation.
 */
@Injectable({ providedIn: 'root' })
export class AppHistory {
  private readonly router = inject(Router);
  private readonly location = inject(Location);
  /** The depth of each history entry, by the id of the navigation that made it (`history.state.navigationId`). */
  private readonly depths = new Map<number, number>();
  private readonly depth = signal(0);
  private pending: { id: number; depth: number } | null = null;

  /** The previous history entry is a page of the app. */
  readonly canGoBack = computed(() => this.depth() > 0);

  constructor() {
    const subscription = this.router.events.subscribe((event) => {
      if (event instanceof NavigationStart) {
        this.pending = { id: event.id, depth: this.depthOf(event) };
      } else if (event instanceof NavigationEnd && this.pending?.id === event.id) {
        this.depths.set(event.id, this.pending.depth);
        this.depth.set(this.pending.depth);
        this.pending = null;
      }
    });
    inject(DestroyRef).onDestroy(() => subscription.unsubscribe());
  }

  /** Back to the previous page of the app, or to `fallback` when there is none. */
  back(fallback = '/'): void {
    if (this.canGoBack()) this.location.back();
    else void this.router.navigateByUrl(fallback);
  }

  private depthOf(event: NavigationStart): number {
    if (event.navigationTrigger === 'popstate' || event.navigationTrigger === 'hashchange') {
      // Back or forward to an entry: as deep as when it was made (one from before a reload counts as the first page).
      const restored = event.restoredState?.navigationId;
      return restored === undefined ? 0 : (this.depths.get(restored) ?? 0);
    }
    // The first page replaces the entry the browser opened; `replaceUrl` and `skipLocationChange` add none.
    if (!this.router.navigated) return 0;
    const extras = this.router.currentNavigation()?.extras;
    return extras?.replaceUrl || extras?.skipLocationChange ? this.depth() : this.depth() + 1;
  }
}
