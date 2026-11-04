import { PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { ActivatedRouteSnapshot, CanActivateChildFn, CanActivateFn, Router, RouterStateSnapshot, UrlTree } from '@angular/router';
import { SETUP_ORDER, SETUP_PATHS, SetupStep, nextSetupStep, postAuthTarget, safeReturnUrl } from './account-setup';
import { AuthService } from './auth.service';
import { SessionStore } from './session.store';

/**
 * Guards only decide in the browser. The server renders public pages anonymously, and routes that need a signed-in
 * user are client-rendered (see app.routes.server.ts), so the server never needs the session.
 */
function onServer(): boolean {
  return !isPlatformBrowser(inject(PLATFORM_ID));
}

function signInTree(router: Router, returnUrl: string): UrlTree {
  return router.createUrlTree(['/auth/sign-in'], { queryParams: { returnUrl } });
}

function stepTree(router: Router, step: SetupStep, returnUrl: string | null | undefined): UrlTree {
  const target = safeReturnUrl(returnUrl);
  return router.createUrlTree([SETUP_PATHS[step]], { queryParams: target === '/' ? {} : { returnUrl: target } });
}

/** Signed-in users only; guests go to Sign in and come back afterwards. */
export const authGuard: CanActivateFn = async (_route, state) => {
  if (onServer()) return true;
  const router = inject(Router);
  const session = inject(SessionStore);
  await inject(AuthService).whenReady();
  return session.isAuthenticated() ? true : signInTree(router, state.url);
};

/** Welcome, Sign in, Create account, Forgot password: a signed-in user goes on to their next step or home. */
export const guestOnlyGuard: CanActivateFn = async (route) => {
  if (onServer()) return true;
  const router = inject(Router);
  const session = inject(SessionStore);
  await inject(AuthService).whenReady();
  if (!session.isAuthenticated()) return true;
  const { path, queryParams } = postAuthTarget(session.me(), route.queryParamMap.get('returnUrl'));
  return router.createUrlTree([path], { queryParams });
};

/**
 * The app-wide order of SPEC §9.2 for signed-in users: change password → set recovery PIN → complete profile →
 * onboarding → the requested page. Guests pass (they can browse and read).
 */
export const accountSetupGuard: CanActivateFn & CanActivateChildFn = async (
  _route: ActivatedRouteSnapshot,
  state: RouterStateSnapshot,
) => {
  if (onServer()) return true;
  const router = inject(Router);
  const session = inject(SessionStore);
  await inject(AuthService).whenReady();
  const me = session.me();
  const step = session.isAuthenticated() && me ? nextSetupStep(me) : null;
  return step ? stepTree(router, step, state.url) : true;
};

/**
 * Guards one setup screen: it opens only when it is the account's current step. Earlier pending steps come first
 * (a PIN can't be skipped by typing the profile URL); a finished step moves on. Onboarding can be revisited.
 */
export function setupStepGuard(step: SetupStep): CanActivateFn {
  return async (route, state) => {
    if (onServer()) return true;
    const router = inject(Router);
    const session = inject(SessionStore);
    await inject(AuthService).whenReady();
    const me = session.me();
    if (!session.isAuthenticated() || !me) return signInTree(router, state.url);

    const returnUrl = route.queryParamMap.get('returnUrl');
    const pending = nextSetupStep(me);
    if (pending === step) return true;
    if (pending && SETUP_ORDER.indexOf(pending) < SETUP_ORDER.indexOf(step)) return stepTree(router, pending, returnUrl);
    if (step === 'onboarding') return true;
    return pending ? stepTree(router, pending, returnUrl) : router.parseUrl(safeReturnUrl(returnUrl));
  };
}

/**
 * `/me/stats`, where the streak reminder's `readin://me/stats` lands (F17): the web shows your reading stats on your own
 * profile, so it redirects there. Guests sign in first.
 */
export const myStatsGuard: CanActivateFn = async (_route, state) => {
  if (onServer()) return true;
  const router = inject(Router);
  const session = inject(SessionStore);
  await inject(AuthService).whenReady();
  const username = session.isAuthenticated() ? session.username() : null;
  return username ? router.createUrlTree([`/@${username}`]) : signInTree(router, state.url);
};

/** Endpoint-style permission check on the client (SPEC §10.2). The API still enforces it. */
export function permissionGuard(permission: string): CanActivateFn {
  return async (_route, state) => {
    if (onServer()) return true;
    const router = inject(Router);
    const session = inject(SessionStore);
    await inject(AuthService).whenReady();
    if (session.hasPermission(permission)) return true;
    return session.isAuthenticated() ? router.createUrlTree(['/']) : signInTree(router, state.url);
  };
}
