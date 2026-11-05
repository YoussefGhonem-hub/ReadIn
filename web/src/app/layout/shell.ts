import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { filter, map, startWith } from 'rxjs';
import { BottomNav } from './bottom-nav';
import { TopBar } from './top-bar';

/**
 * App shell: the top bar (the destinations, theme toggle and Me menu from `md`) and the bottom nav below `md`. Each page
 * sets its own max width and centers itself. Routes can set `data.hideBottomNav`, and `data.hideHeaderSearch` (the
 * search page has its own box).
 */
@Component({
  selector: 'rd-shell',
  imports: [RouterOutlet, TranslocoPipe, TopBar, BottomNav],
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
  `,
})
export class Shell {
  private readonly router = inject(Router);

  /** The deepest route's layout flags. */
  protected readonly routeData = toSignal(
    this.router.events.pipe(
      filter((e) => e instanceof NavigationEnd),
      startWith(null),
      map(() => {
        let snapshot = this.router.routerState.snapshot.root;
        while (snapshot.firstChild) snapshot = snapshot.firstChild;
        return { hideBottomNav: !!snapshot.data['hideBottomNav'], hideHeaderSearch: !!snapshot.data['hideHeaderSearch'] };
      }),
    ),
    { initialValue: { hideBottomNav: false, hideHeaderSearch: false } },
  );
}
