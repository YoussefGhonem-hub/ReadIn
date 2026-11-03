import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { filter, map, startWith } from 'rxjs';
import { BottomNav } from './bottom-nav';
import { SideNav } from './side-nav';
import { TopBar } from './top-bar';

/** App shell: top bar, side nav (desktop), bottom nav (narrow screens). Routes can set `data.hideBottomNav`. */
@Component({
  selector: 'rd-shell',
  imports: [RouterOutlet, TranslocoPipe, TopBar, SideNav, BottomNav],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <a
      href="#main"
      class="sr-only focus:not-sr-only focus:fixed focus:start-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-surface focus:p-3"
      >{{ 'nav.skipToContent' | transloco }}</a
    >
    <rd-top-bar />
    <div class="mx-auto flex max-w-[1200px] gap-6 lg:px-6">
      <rd-side-nav class="sticky top-16 hidden h-[calc(100dvh-4rem)] w-[232px] shrink-0 overflow-y-auto lg:block" />
      <main id="main" class="min-w-0 flex-1 pb-28 lg:pb-12" tabindex="-1">
        <router-outlet />
      </main>
    </div>
    @if (!hideBottomNav()) {
      <rd-bottom-nav class="lg:hidden" />
    }
  `,
})
export class Shell {
  private readonly router = inject(Router);

  protected readonly hideBottomNav = toSignal(
    this.router.events.pipe(
      filter((e) => e instanceof NavigationEnd),
      startWith(null),
      map(() => {
        let snapshot = this.router.routerState.snapshot.root;
        while (snapshot.firstChild) snapshot = snapshot.firstChild;
        return !!snapshot.data['hideBottomNav'];
      }),
    ),
    { initialValue: false },
  );
}
