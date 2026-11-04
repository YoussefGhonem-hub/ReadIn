import { Routes, UrlMatchResult, UrlSegment } from '@angular/router';
import { accountSetupGuard, authGuard, permissionGuard, setupStepGuard } from './core/auth/guards';
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

/** `/@{username}` and the pages under it (SPEC §23); features/profile/profile.routes.ts matches the rest. */
export function profileMatcher(segments: UrlSegment[]): UrlMatchResult | null {
  const [first] = segments;
  if (first?.path.startsWith('@') && first.path.length > 1) {
    return { consumed: [first], posParams: { username: new UrlSegment(first.path.slice(1), {}) } };
  }
  return null;
}

export const routes: Routes = [
  // Welcome, sign in/up, forgot password and the mandatory setup screens (SPEC §9.2); each route has its own guard.
  { path: 'auth', loadChildren: () => import('./features/auth/auth.routes') },
  {
    path: 'onboarding',
    canActivate: [setupStepGuard('onboarding')],
    loadComponent: () => import('./features/onboarding/onboarding.page').then((m) => m.OnboardingPage),
  },
  {
    path: '',
    component: Shell,
    // Signed-in users finish their pending setup step first; guests browse freely.
    canActivateChild: [accountSetupGuard],
    children: [
      {
        path: '',
        pathMatch: 'full',
        loadComponent: () => import('./features/home/home.page').then((m) => m.HomePage),
      },
      {
        matcher: articleMatcher,
        loadComponent: () => import('./features/article/article.page').then((m) => m.ArticlePage),
        data: { hideBottomNav: true },
      },
      { matcher: profileMatcher, loadChildren: () => import('./features/profile/profile.routes') },
      {
        path: 'saved',
        canActivate: [authGuard],
        loadComponent: () => import('./features/saved/saved.page').then((m) => m.SavedPage),
      },
      { path: 'settings', loadChildren: () => import('./features/settings/settings.routes') },
      // My articles and the editor (F05).
      { path: 'write', canActivate: [permissionGuard('articles.create')], loadChildren: () => import('./features/editor/editor.routes') },
      ...PLACEHOLDER_ROUTES,
      { path: '**', loadComponent: () => import('./shared/ui/not-found.page').then((m) => m.NotFoundPage) },
    ],
  },
];
