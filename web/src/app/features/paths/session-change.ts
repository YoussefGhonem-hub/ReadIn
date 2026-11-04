import { ApplicationRef, Injector, PLATFORM_ID, effect, inject, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { SessionStore } from '../../core/auth/session.store';
import { HydrationWindow } from '../../core/http/hydration-window';

/**
 * Calls `reload(signedIn)` when signing in or out changes what a paths page shows (progress, enrollment, My paths).
 * A server-rendered page is anonymous and hydration reuses that answer, so once the app is stable a signed-in session
 * counts as a change too. Browser only; call it in an injection context.
 */
export function reloadOnSessionChange(reload: (signedIn: boolean) => void): void {
  if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
  const session = inject(SessionStore);
  const injector = inject(Injector);
  const hydrating = inject(HydrationWindow).isOpen;
  let shown = hydrating ? false : session.isAuthenticated();
  const watch = () =>
    effect(
      () => {
        const signedIn = session.isAuthenticated();
        untracked(() => {
          if (signedIn === shown) return;
          shown = signedIn;
          reload(signedIn);
        });
      },
      { injector },
    );
  if (hydrating) void inject(ApplicationRef).whenStable().then(watch);
  else watch();
}
