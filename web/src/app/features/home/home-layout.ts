import { DestroyRef, Injectable, PLATFORM_ID, afterNextRender, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

/** Tailwind's `lg`: from here Home has its side columns. */
export const HOME_RAILS_QUERY = '(min-width: 64rem)';

/**
 * Whether Home's side columns are on screen. The server and the first browser render assume they are (so hydration
 * matches); after it, narrow screens drop them. `active` turns true once they are really shown in the browser: the
 * rails load their data only then, so phones never ask for it.
 */
@Injectable()
export class HomeLayout {
  readonly wide = signal(true);
  readonly active = signal(false);

  constructor() {
    if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      // Without media queries there's no telling the width: the columns stay as rendered, without their data.
      if (typeof matchMedia !== 'function') return;
      const query = matchMedia(HOME_RAILS_QUERY);
      const apply = () => {
        this.wide.set(query.matches);
        this.active.set(query.matches);
      };
      apply();
      query.addEventListener('change', apply);
      destroyRef.onDestroy(() => query.removeEventListener('change', apply));
    });
  }
}
