import { Injectable, Injector, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import {
  ActivatedRouteSnapshot,
  BaseRouteReuseStrategy,
  DetachedRouteHandle,
  Route,
  Router,
  destroyDetachedRouteHandle,
} from '@angular/router';
import { SessionStore } from '../../core/auth/session.store';

/** Route data flag: keep the page alive while you read, and give it back on Back (F34). */
export const KEEP_ON_BACK = 'keepOnBack';
/** Pages kept at once (the oldest is dropped). */
const MAX_KEPT = 3;

interface Kept {
  config: Route;
  key: string;
  user: string;
  handle: DetachedRouteHandle;
}

/**
 * Keeps feed pages (Home, routes with `data.keepOnBack`) alive while you open an article or a profile from them, and
 * puts them back as they were when you come back with Back (F34 "While scrolling"): expanded cards, open comments,
 * loaded pages, and the scroll position, which the router restores once the page is back. Any other way of coming
 * back (a link, the nav, a reload) builds a fresh page, which is the web's "pull to refresh". A page kept for another
 * account (you signed in or out meanwhile) is dropped. Browser only; the server never detaches anything.
 */
@Injectable({ providedIn: 'root' })
export class FeedRouteReuse extends BaseRouteReuseStrategy {
  /** The router injects this strategy, so it is looked up when needed. */
  private readonly injector = inject(Injector);
  private readonly session = inject(SessionStore);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private kept: Kept[] = [];

  override shouldDetach(route: ActivatedRouteSnapshot): boolean {
    return this.isBrowser && !!route.routeConfig && !!route.data[KEEP_ON_BACK];
  }

  override store(route: ActivatedRouteSnapshot, handle: DetachedRouteHandle | null): void {
    const config = route.routeConfig;
    if (!config) return;
    const key = keyOf(route);
    const existing = this.kept.find((k) => k.config === config && k.key === key);
    // Called with null once a kept page is attached again: it is no longer kept.
    this.kept = this.kept.filter((k) => k !== existing);
    if (!handle) return;
    if (existing && existing.handle !== handle) destroyDetachedRouteHandle(existing.handle);
    this.kept.push({ config, key, user: this.user(), handle });
    while (this.kept.length > MAX_KEPT) destroyDetachedRouteHandle(this.kept.shift()!.handle);
  }

  override shouldAttach(route: ActivatedRouteSnapshot): boolean {
    const kept = this.find(route);
    if (!kept) return false;
    if (this.injector.get(Router).currentNavigation()?.trigger === 'popstate' && kept.user === this.user()) return true;
    // Not a Back (or another account): this page starts fresh.
    this.kept = this.kept.filter((k) => k !== kept);
    destroyDetachedRouteHandle(kept.handle);
    return false;
  }

  override retrieve(route: ActivatedRouteSnapshot): DetachedRouteHandle | null {
    return this.find(route)?.handle ?? null;
  }

  private find(route: ActivatedRouteSnapshot): Kept | undefined {
    const config = route.routeConfig;
    if (!config || !this.isBrowser) return undefined;
    const key = keyOf(route);
    return this.kept.find((k) => k.config === config && k.key === key);
  }

  private user(): string {
    return this.session.isAuthenticated() ? (this.session.me()?.id ?? 'user') : 'guest';
  }
}

/** The page's own address: the same route with other parameters (another profile) is another page. */
function keyOf(route: ActivatedRouteSnapshot): string {
  return JSON.stringify(route.params);
}
