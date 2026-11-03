import { Routes, UrlMatchResult, UrlSegment } from '@angular/router';
import { authGuard, guestOnlyGuard, onboardingGuard } from './core/auth/guards';
import { PLACEHOLDER_ROUTES } from './features/placeholders.routes';
import { Shell } from './layout/shell';

/** `/ar/a/{slug}` and `/en/a/{slug}` (SPEC §23). */
export function articleMatcher(segments: UrlSegment[]): UrlMatchResult | null {
  const [lang, a, slug] = segments;
  if (segments.length === 3 && (lang.path === 'ar' || lang.path === 'en') && a.path === 'a' && slug.path) {
    return { consumed: segments, posParams: { lang, slug } };
  }
  return null;
}

/** `/@{username}` (SPEC §23). */
export function profileMatcher(segments: UrlSegment[]): UrlMatchResult | null {
  const [first] = segments;
  if (segments.length === 1 && first.path.startsWith('@') && first.path.length > 1) {
    return { consumed: segments, posParams: { username: new UrlSegment(first.path.slice(1), {}) } };
  }
  return null;
}

export const routes: Routes = [
  { path: 'auth', canActivate: [guestOnlyGuard], loadChildren: () => import('./features/auth/auth.routes') },
  {
    path: 'onboarding',
    canActivate: [authGuard],
    loadComponent: () => import('./features/onboarding/onboarding.page').then((m) => m.OnboardingPage),
  },
  {
    path: '',
    component: Shell,
    children: [
      {
        path: '',
        pathMatch: 'full',
        canActivate: [onboardingGuard],
        loadComponent: () => import('./features/home/home.page').then((m) => m.HomePage),
      },
      {
        matcher: articleMatcher,
        loadComponent: () => import('./features/article/article.page').then((m) => m.ArticlePage),
        data: { hideBottomNav: true },
      },
      {
        matcher: profileMatcher,
        loadComponent: () => import('./shared/ui/coming-soon.page').then((m) => m.ComingSoonPage),
        data: { titleKey: 'nav.profile', phase: 1 },
      },
      { path: 'settings', loadComponent: () => import('./features/settings/settings.page').then((m) => m.SettingsPage) },
      ...PLACEHOLDER_ROUTES,
      { path: '**', loadComponent: () => import('./shared/ui/not-found.page').then((m) => m.NotFoundPage) },
    ],
  },
];
