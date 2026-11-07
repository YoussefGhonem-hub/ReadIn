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

    // The lists and the category pages (F31) under it are matched by the lazy profile routes.
    expect(profileMatcher(segments('@mona', 'followers'))!.consumed.map((s) => s.path)).toEqual(['@mona']);
    expect(profileMatcher(segments('@mona', 'c', 'asp-net-core'))!.consumed.map((s) => s.path)).toEqual(['@mona']);
    expect(profileRoutes.map((r) => r.path)).toEqual(['', 'followers', 'following', 'c/:slug']);
    expect(profileRoutes.map((r) => r.data?.['list'] ?? null)).toEqual([null, 'followers', 'following', null]);
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

  // F23: the verification queue moved into the admin console, which needs admin.access; the section needs its own permission.
  it('/admin (the console) needs admin.access: a member goes home, a guest signs in first; verification sits inside it', async () => {
    expect(route('admin').loadChildren).toBeDefined();
    expect(route('admin').data?.['hideFollowingDock']).toBe(true);
    expect(await guard('admin', testMe({ permissions: ['articles.read', 'articles.create', 'verification.manage'] }))).toBe('/');
    expect(await guard('admin', null)).toBe('/auth/sign-in?returnUrl=%2Fadmin');
    expect(await guard('admin', testMe({ permissions: ['articles.read', 'admin.access'] }))).toBe(true);
    expect(PLACEHOLDER_ROUTES.find((r) => r.path === 'admin')).toBeUndefined();

    const { default: group } = (await (route('admin').loadChildren as () => Promise<{ default: Routes }>)()) as { default: Routes };
    const sections = group[0].children!;
    const verification = sections.find((r) => r.path === 'verification')!;
    expect(verification.loadComponent).toBeDefined();
    const [canActivate] = verification.canActivate as CanActivateFn[];
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ providers: [provideRouter([]), { provide: PLATFORM_ID, useValue: 'browser' }, { provide: AuthService, useValue: { whenReady: async () => null } }] });
    TestBed.inject(SessionStore).setMe(testMe({ permissions: ['admin.access'] }));
    const denied = await TestBed.runInInjectionContext(() => canActivate({} as ActivatedRouteSnapshot, { url: '/admin/verification' } as RouterStateSnapshot));
    expect(TestBed.inject(Router).serializeUrl(denied as UrlTree)).toBe('/');
  });

  it('/moderation (F22) redirects into the console: the queue, the log and a case keep working', () => {
    const redirects = shell.children!.filter((r) => r.path?.startsWith('moderation')).map((r) => [r.path, r.redirectTo]);
    expect(redirects).toEqual([
      ['moderation', '/admin/reports'],
      ['moderation/log', '/admin/reports/log'],
      ['moderation/:type/:id', '/admin/reports/:type/:id'],
    ]);
  });
});

describe('Explore and field pages (F15)', () => {
  const shell = routes.find((r) => r.path === '' && r.children)!;
  const route = (path: string) => shell.children!.find((r) => r.path === path)!;

  it('/explore and its "See all" rankings are real pages (no more "coming soon"), each kept alive while you read', async () => {
    expect(PLACEHOLDER_ROUTES.map((r) => r.path)).not.toContain('explore');
    const { default: explore } = (await (route('explore').loadChildren as () => Promise<{ default: Routes }>)()) as { default: Routes };
    expect(explore.map((r) => r.path)).toEqual(['', 'trending', 'most-saved']);
    expect(explore.map((r) => r.data?.['ranking'] ?? null)).toEqual([null, 'trending', 'most-saved']);
    expect(explore.every((r) => r.loadComponent && r.data?.['keepOnBack'])).toBe(true);
  });

  it('/f/{slug} is the field page: its own chunk, kept alive while you read', () => {
    expect(route('f/:slug').loadComponent).toBeDefined();
    expect(route('f/:slug').data?.['keepOnBack']).toBe(true);
  });
});
