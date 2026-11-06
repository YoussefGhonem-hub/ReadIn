import { ChangeDetectionStrategy, Component, DestroyRef, afterNextRender, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { filter, map, startWith } from 'rxjs';
import { SessionStore } from '../core/auth/session.store';
import { BottomNav } from './bottom-nav';
import { FollowingDock } from './following-dock';
import { TopBar } from './top-bar';

/** From this width the people you follow get their docked panel (the screen has room beside the page). */
export const FOLLOWING_DOCK_QUERY = '(min-width: 64rem)';

/**
 * App shell: the top bar (the destinations, theme toggle and Me menu from `md`) and the bottom nav below `md`. Each page
 * sets its own max width and centers itself. Routes can set `data.hideBottomNav`, `data.hideHeaderSearch` (the search
 * page has its own box) and `data.hideFollowingDock` (the editor). Signed-in members on wide screens get the people
 * they follow in a panel docked at the bottom corner, loaded in its own chunk once the page is idle.
 */
@Component({
  selector: 'rd-shell',
  imports: [RouterOutlet, TranslocoPipe, TopBar, BottomNav, FollowingDock],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <a
      href="#main"
      class="sr-only focus:not-sr-only focus:fixed focus:start-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-surface focus:p-3"
      >{{ 'nav.skipToContent' | transloco }}</a
    >
    <rd-top-bar [searchBox]="!routeData().hideHeaderSearch" />
    <main id="main" class="block min-w-0 pb-28 md:pb-12" tabindex="-1">
      <router-outlet />
    </main>
    @if (!routeData().hideBottomNav) {
      <rd-bottom-nav class="md:hidden" />
    }
    @if (showDock()) {
      @defer (on idle) {
        <rd-following-dock />
      }
    }
  `,
})
export class Shell {
  private readonly router = inject(Router);
  private readonly session = inject(SessionStore);
  /** Wide enough for the docked panel; false on the server and until the browser knows. */
  private readonly wide = signal(false);

  /** The deepest route's layout flags. */
  protected readonly routeData = toSignal(
    this.router.events.pipe(
      filter((e) => e instanceof NavigationEnd),
      startWith(null),
      map(() => {
        let snapshot = this.router.routerState.snapshot.root;
        while (snapshot.firstChild) snapshot = snapshot.firstChild;
        const data = snapshot.data;
        return { hideBottomNav: !!data['hideBottomNav'], hideHeaderSearch: !!data['hideHeaderSearch'], hideFollowingDock: !!data['hideFollowingDock'] };
      }),
    ),
    { initialValue: { hideBottomNav: false, hideHeaderSearch: false, hideFollowingDock: false } },
  );

  protected readonly showDock = computed(() => this.wide() && this.session.isAuthenticated() && !this.routeData().hideFollowingDock);

  constructor() {
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      if (typeof matchMedia !== 'function') return;
      const query = matchMedia(FOLLOWING_DOCK_QUERY);
      const apply = () => this.wide.set(query.matches);
      apply();
      query.addEventListener('change', apply);
      destroyRef.onDestroy(() => query.removeEventListener('change', apply));
    });
  }
}
