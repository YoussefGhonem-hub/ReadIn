import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot, UrlTree, convertToParamMap, provideRouter } from '@angular/router';
import { testMe } from '../../../testing/auth-testing';
import { MeDto } from '../api/models';
import { nextSetupStep, postAuthUrl, safeReturnUrl } from './account-setup';
import { AuthService } from './auth.service';
import { accountSetupGuard, authGuard, guestOnlyGuard, permissionGuard, setupStepGuard } from './guards';
import { SessionStore } from './session.store';

type Guard = (route: ActivatedRouteSnapshot, state: RouterStateSnapshot) => unknown;

function setup(me: MeDto | null, platform = 'browser') {
  TestBed.configureTestingModule({
    providers: [
      provideRouter([]),
      { provide: PLATFORM_ID, useValue: platform },
      { provide: AuthService, useValue: { whenReady: async () => me } },
    ],
  });
  const session = TestBed.inject(SessionStore);
  if (me) session.setMe(me);
  else session.setGuest();
  return TestBed.inject(Router);
}

async function run(guard: Guard, url: string, query: Record<string, string> = {}): Promise<string | true> {
  const route = { queryParamMap: convertToParamMap(query) } as ActivatedRouteSnapshot;
  const result = await TestBed.runInInjectionContext(() => guard(route, { url } as RouterStateSnapshot));
  if (result === true) return true;
  return TestBed.inject(Router).serializeUrl(result as UrlTree);
}

describe('account-setup order (SPEC §9.2)', () => {
  it('goes change password → set PIN → complete profile → onboarding → done', () => {
    const all = { mustChangePassword: true, mustSetRecoveryPin: true, isProfileComplete: false, onboardingCompleted: false };
    expect(nextSetupStep(testMe(all))).toBe('password');
    expect(nextSetupStep(testMe({ ...all, mustChangePassword: false }))).toBe('pin');
    expect(nextSetupStep(testMe({ ...all, mustChangePassword: false, mustSetRecoveryPin: false }))).toBe('profile');
    expect(nextSetupStep(testMe({ onboardingCompleted: false }))).toBe('onboarding');
    expect(nextSetupStep(testMe())).toBeNull();
  });

  it('keeps the requested page through the steps, never an outside or auth URL', () => {
    expect(postAuthUrl(testMe({ mustSetRecoveryPin: true }), '/write')).toBe('/auth/recovery-pin?returnUrl=%2Fwrite');
    expect(postAuthUrl(testMe(), '/write')).toBe('/write');
    expect(postAuthUrl(testMe(), null)).toBe('/');
    expect(safeReturnUrl('https://evil.example')).toBe('/');
    expect(safeReturnUrl('//evil.example')).toBe('/');
    expect(safeReturnUrl('/\\evil.example')).toBe('/');
    expect(safeReturnUrl('/auth/sign-in')).toBe('/');
    expect(safeReturnUrl('/@mona')).toBe('/@mona');
  });
});

describe('guards', () => {
  beforeEach(() => TestBed.resetTestingModule());

  describe('accountSetupGuard (the whole app)', () => {
    it('lets guests browse', async () => {
      setup(null);
      expect(await run(accountSetupGuard, '/ar/a/some-article')).toBe(true);
    });

    it('sends a signed-in account to its first pending step, in order, keeping the page', async () => {
      setup(testMe({ mustChangePassword: true, mustSetRecoveryPin: true, isProfileComplete: false, onboardingCompleted: false }));
      expect(await run(accountSetupGuard, '/settings')).toBe('/auth/change-password?returnUrl=%2Fsettings');
    });

    it.each([
      [{ mustSetRecoveryPin: true, isProfileComplete: false }, '/auth/recovery-pin?returnUrl=%2Fsaved'],
      [{ isProfileComplete: false, onboardingCompleted: false }, '/auth/complete-profile?returnUrl=%2Fsaved'],
      [{ onboardingCompleted: false }, '/onboarding?returnUrl=%2Fsaved'],
    ])('%o → %s', async (flags, target) => {
      setup(testMe(flags));
      expect(await run(accountSetupGuard, '/saved')).toBe(target);
    });

    it('opens the page when every step is done', async () => {
      setup(testMe());
      expect(await run(accountSetupGuard, '/')).toBe(true);
    });

    it('never decides on the server', async () => {
      setup(testMe({ mustSetRecoveryPin: true }), 'server');
      expect(await run(accountSetupGuard, '/')).toBe(true);
    });
  });

  describe('setupStepGuard (one setup screen)', () => {
    it('opens the current step', async () => {
      setup(testMe({ mustSetRecoveryPin: true }));
      expect(await run(setupStepGuard('pin'), '/auth/recovery-pin')).toBe(true);
    });

    it('cannot skip an earlier step (the PIN before the profile)', async () => {
      setup(testMe({ mustSetRecoveryPin: true, isProfileComplete: false }));
      expect(await run(setupStepGuard('profile'), '/auth/complete-profile', { returnUrl: '/write' })).toBe(
        '/auth/recovery-pin?returnUrl=%2Fwrite',
      );
    });

    it('moves on from a finished step', async () => {
      setup(testMe({ onboardingCompleted: false }));
      expect(await run(setupStepGuard('pin'), '/auth/recovery-pin')).toBe('/onboarding');
      TestBed.resetTestingModule();
      setup(testMe());
      expect(await run(setupStepGuard('password'), '/auth/change-password', { returnUrl: '/write' })).toBe('/write');
    });

    it('lets a finished account revisit onboarding', async () => {
      setup(testMe());
      expect(await run(setupStepGuard('onboarding'), '/onboarding')).toBe(true);
    });

    it('sends guests to sign in', async () => {
      setup(null);
      expect(await run(setupStepGuard('pin'), '/auth/recovery-pin')).toBe('/auth/sign-in?returnUrl=%2Fauth%2Frecovery-pin');
    });
  });

  it('guestOnlyGuard sends a signed-in user on to the next step or the requested page', async () => {
    setup(testMe({ isProfileComplete: false }));
    expect(await run(guestOnlyGuard, '/auth/sign-in', { returnUrl: '/write' })).toBe('/auth/complete-profile?returnUrl=%2Fwrite');
    TestBed.resetTestingModule();
    setup(testMe());
    expect(await run(guestOnlyGuard, '/auth/sign-in')).toBe('/');
    TestBed.resetTestingModule();
    setup(null);
    expect(await run(guestOnlyGuard, '/auth/sign-in')).toBe(true);
  });

  it('authGuard and permissionGuard send guests to sign in and back', async () => {
    setup(null);
    expect(await run(authGuard, '/saved')).toBe('/auth/sign-in?returnUrl=%2Fsaved');
    expect(await run(permissionGuard('articles.create'), '/write')).toBe('/auth/sign-in?returnUrl=%2Fwrite');
    TestBed.resetTestingModule();
    setup(testMe({ permissions: ['articles.read'] }));
    expect(await run(permissionGuard('articles.create'), '/write')).toBe('/');
    expect(await run(authGuard, '/saved')).toBe(true);
  });
});
