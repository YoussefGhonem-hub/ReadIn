import { Routes, UrlMatchResult, UrlSegment } from '@angular/router';
import { accountSetupGuard, authGuard, myStatsGuard, permissionGuard, setupStepGuard } from './core/auth/guards';
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
      // Learning paths (F09): public, server-rendered (app.routes.server.ts → `**`).
      { path: 'paths', loadChildren: () => import('./features/paths/paths.routes') },
      { path: 'settings', loadChildren: () => import('./features/settings/settings.routes') },
      // Reports queue, cases and log (F22): moderators only, client-rendered, its own chunk.
      {
        path: 'moderation',
        canActivate: [permissionGuard('moderation.manage')],
        loadChildren: () => import('./features/moderation/moderation.routes'),
      },
      {
        // Delete account (SPEC F01): in the app, two taps from Settings, as the stores require.
        path: 'settings/delete-account',
        canActivate: [authGuard],
        loadComponent: () => import('./features/settings/account/delete-account.page').then((m) => m.DeleteAccountPage),
      },
      // The notification center (F17): signed-in only, client-rendered, its own chunk.
      {
        path: 'notifications',
        canActivate: [authGuard],
        loadComponent: () => import('./features/notifications/notifications.page').then((m) => m.NotificationsPage),
      },
      // `readin://me/stats` (the streak reminder, F17): your reading stats are on your own profile.
      { path: 'me/stats', canActivate: [myStatsGuard], children: [] },
      // My articles and the editor (F05).
      { path: 'write', canActivate: [permissionGuard('articles.create')], loadChildren: () => import('./features/editor/editor.routes') },
      ...PLACEHOLDER_ROUTES,
      { path: '**', loadComponent: () => import('./shared/ui/not-found.page').then((m) => m.NotFoundPage) },
    ],
  },
];
