import { Routes, UrlSegment } from '@angular/router';
import { profileMatcher } from './app.routes';
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
