import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, CanActivateFn, Router, RouterStateSnapshot, Routes, UrlSegment, UrlTree, provideRouter } from '@angular/router';
import { testMe } from '../testing/auth-testing';
import { profileMatcher, routes } from './app.routes';
import { MeDto } from './core/api/models';
import { AuthService } from './core/auth/auth.service';
import { SessionStore } from './core/auth/session.store';
import { PLACEHOLDER_ROUTES } from './features/placeholders.routes';
import lazyProfileRoutes from './features/profile/profile.routes';

const profileRoutes: Routes = lazyProfileRoutes;

const segments = (...paths: string[]) => paths.map((path) => new UrlSegment(path, {}));

describe('profile URLs (SPEC §23)', () => {
  it('/@{username} takes the first segment and passes the username down', () => {
    const match = profileMatcher(segments('@mona'))!;
    expect(match.consumed.map((s) => s.path)).toEqual(['@mona']);
    expect(match.posParams!['username'].path).toBe('mona');

    // The lists under it are matched by the lazy profile routes.
    expect(profileMatcher(segments('@mona', 'followers'))!.consumed.map((s) => s.path)).toEqual(['@mona']);
    expect(profileRoutes.map((r) => r.path)).toEqual(['', 'followers', 'following']);
    expect(profileRoutes.map((r) => r.data?.['list'] ?? null)).toEqual([null, 'followers', 'following']);
  });

  it('is not a profile without a name after @', () => {
    expect(profileMatcher(segments('@'))).toBeNull();
    expect(profileMatcher(segments('mona'))).toBeNull();
    expect(profileMatcher([])).toBeNull();
  });
});

describe('writer verification routes (F19)', () => {
  const shell = routes.find((r) => r.path === '' && r.children)!;
  const route = (path: string) => shell.children!.find((r) => r.path === path)!;

  async function guard(path: string, me: MeDto | null): Promise<string | true> {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [provideRouter([]), { provide: PLATFORM_ID, useValue: 'browser' }, { provide: AuthService, useValue: { whenReady: async () => me } }],
    });
    const session = TestBed.inject(SessionStore);
    if (me) session.setMe(me);
    else session.setGuest();
    const [canActivate] = route(path).canActivate as CanActivateFn[];
    const result = await TestBed.runInInjectionContext(() => canActivate({} as ActivatedRouteSnapshot, { url: `/${path}` } as RouterStateSnapshot));
    return result === true ? true : TestBed.inject(Router).serializeUrl(result as UrlTree);
  }

  it('/verification is your own page: signed in only, its own chunk (no more "coming soon")', async () => {
    expect(route('verification').loadComponent).toBeDefined();
    expect(PLACEHOLDER_ROUTES.map((r) => r.path)).not.toContain('verification');
    expect(await guard('verification', null)).toBe('/auth/sign-in?returnUrl=%2Fverification');
    expect(await guard('verification', testMe())).toBe(true);
  });

  it('/admin/verification needs verification.manage: a member goes home, a guest signs in first', async () => {
    expect(route('admin/verification').loadComponent).toBeDefined();
    expect(await guard('admin/verification', testMe({ permissions: ['articles.read', 'articles.create'] }))).toBe('/');
    expect(await guard('admin/verification', null)).toBe('/auth/sign-in?returnUrl=%2Fadmin%2Fverification');
    expect(await guard('admin/verification', testMe({ permissions: ['articles.read', 'verification.manage'] }))).toBe(true);
    // The rest of /admin stays a placeholder for the other admin tools.
    expect(PLACEHOLDER_ROUTES.find((r) => r.path === 'admin')).toBeDefined();
  });
});
