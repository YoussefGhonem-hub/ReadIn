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

/** The Terms of Use and Community Guidelines (F37): one page, one chunk. */
const legalPage = () => import('./features/legal/legal.page').then((m) => m.LegalPage);

export const routes: Routes = [
  // Welcome, sign in/up, forgot password and the mandatory setup screens (SPEC §9.2); each route has its own guard.
  { path: 'auth', loadChildren: () => import('./features/auth/auth.routes') },
  {
    path: 'onboarding',
    canActivate: [setupStepGuard('onboarding')],
    loadComponent: () => import('./features/onboarding/onboarding.page').then((m) => m.OnboardingPage),
    // Route titles are i18n keys (core/i18n/page-title.strategy.ts).
    title: 'pageTitles.onboarding',
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
        // Kept alive while you read; Back brings it back as you left it (features/feed/feed-route-reuse.ts, F34).
        data: { keepOnBack: true },
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
      // Search (F16): server-rendered without results, noindex (app.routes.server.ts). Kept alive while you open a result.
      {
        path: 'search',
        loadComponent: () => import('./features/search/search.page').then((m) => m.SearchPage),
        title: 'pageTitles.search',
        data: { keepOnBack: true, hideHeaderSearch: true },
      },
      // Tag pages (F32): public, server-rendered (`**`), their own chunk. `/tags` alone is a 404.
      { path: 'tags/:slug', loadComponent: () => import('./features/tags/tag.page').then((m) => m.TagPage) },
      // Explore and its "See all" rankings (F15): public, server-rendered (`**`), each page its own chunk.
      { path: 'explore', loadChildren: () => import('./features/explore/explore.routes') },
      // Field pages (F15), `/f/{slug}?topic=`: public, server-rendered (`**`), their own chunk. Kept alive while you read.
      {
        path: 'f/:slug',
        loadComponent: () => import('./features/explore/field.page').then((m) => m.FieldPage),
        data: { keepOnBack: true },
      },
      { path: 'settings', loadChildren: () => import('./features/settings/settings.routes') },
      // Reports queue, cases and log (F22) moved into the admin console (F23): old links and bookmarks keep working.
      { path: 'moderation', pathMatch: 'full', redirectTo: '/admin/reports' },
      { path: 'moderation/log', redirectTo: '/admin/reports/log' },
      { path: 'moderation/:type/:id', redirectTo: '/admin/reports/:type/:id' },
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
      // Writer verification (F19): your request; `readin://verification` lands here.
      {
        path: 'verification',
        canActivate: [authGuard],
        loadComponent: () => import('./features/verification/verification.page').then((m) => m.VerificationPage),
      },
      // The admin console (F23): `admin.access`, its own layout and lazy sections (Reports = F22, Verification = F19).
      // Client-rendered and noindex (app.routes.server.ts); the docked following panel stays off its tables.
      {
        path: 'admin',
        canActivate: [permissionGuard('admin.access')],
        data: { hideFollowingDock: true },
        loadChildren: () => import('./features/admin/admin.routes'),
      },
      // The Terms of Use and Community Guidelines (F37): public, server-rendered (`**`), indexable; their own chunk.
      { path: 'terms', loadComponent: legalPage, data: { page: 'terms' } },
      { path: 'community-guidelines', loadComponent: legalPage, data: { page: 'guidelines' } },
      // Help & support (F35): `/support` is public and server-rendered; My tickets and a ticket are signed in only.
      { path: 'support', loadChildren: () => import('./features/support/support.routes') },
      // My articles and the editor (F05).
      { path: 'write', canActivate: [permissionGuard('articles.create')], loadChildren: () => import('./features/editor/editor.routes') },
      ...PLACEHOLDER_ROUTES,
      { path: '**', loadComponent: () => import('./shared/ui/not-found.page').then((m) => m.NotFoundPage) },
    ],
  },
];
