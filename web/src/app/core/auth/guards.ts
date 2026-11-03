import { PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { SessionStore } from './session.store';

/**
 * Guards only decide in the browser. Routes that need a signed-in user are client-rendered
 * (see app.routes.server.ts), so the server never has to know about the Firebase session.
 */
function onServer(): boolean {
  return !isPlatformBrowser(inject(PLATFORM_ID));
}

export const authGuard: CanActivateFn = async (_route, state) => {
  if (onServer()) return true;
  const auth = inject(AuthService);
  const session = inject(SessionStore);
  const router = inject(Router);
  await auth.whenReady();
  return session.isAuthenticated() ? true : router.createUrlTree(['/auth/sign-in'], { queryParams: { returnUrl: state.url } });
};

/** Keeps signed-in users away from the sign-in/up pages. */
export const guestOnlyGuard: CanActivateFn = async () => {
  if (onServer()) return true;
  const auth = inject(AuthService);
  const session = inject(SessionStore);
  const router = inject(Router);
  await auth.whenReady();
  return session.isAuthenticated() && session.me() ? router.createUrlTree(['/']) : true;
};

/** Signed-in users who have not picked ≥ 3 interests go through onboarding first (F02). Guests pass. */
export const onboardingGuard: CanActivateFn = async () => {
  if (onServer()) return true;
  const auth = inject(AuthService);
  const session = inject(SessionStore);
  const router = inject(Router);
  await auth.whenReady();
  return session.needsOnboarding() ? router.createUrlTree(['/onboarding']) : true;
};

/** Endpoint-style permission check on the client (SPEC §10.2). The API still enforces it. */
export function permissionGuard(permission: string): CanActivateFn {
  return async (_route, state) => {
    if (onServer()) return true;
    const auth = inject(AuthService);
    const session = inject(SessionStore);
    const router = inject(Router);
    await auth.whenReady();
    if (session.hasPermission(permission)) return true;
    return session.isAuthenticated()
      ? router.createUrlTree(['/'])
      : router.createUrlTree(['/auth/sign-in'], { queryParams: { returnUrl: state.url } });
  };
}
