import { Route } from '@angular/router';
import { authGuard, permissionGuard } from '../core/auth/guards';

const comingSoon = () => import('../shared/ui/coming-soon.page').then((m) => m.ComingSoonPage);

/**
 * Features scheduled after this slice (SPEC §12, §30). Each renders a translated "coming soon" page and keeps
 * its final URL and guard so links and permissions are already right.
 */
export const PLACEHOLDER_ROUTES: Route[] = [
  { path: 'explore', loadComponent: comingSoon, data: { titleKey: 'nav.explore', phase: 2 } },
  { path: 'search', loadComponent: comingSoon, data: { titleKey: 'nav.search', phase: 2 } },
  { path: 'paths', loadComponent: comingSoon, data: { titleKey: 'nav.paths', phase: 2 } },
  { path: 'notifications', canActivate: [authGuard], loadComponent: comingSoon, data: { titleKey: 'nav.notifications', phase: 2 } },
  { path: 'verification', canActivate: [authGuard], loadComponent: comingSoon, data: { titleKey: 'nav.verification', phase: 2 } },
  { path: 'reviews', canActivate: [permissionGuard('articles.review')], loadComponent: comingSoon, data: { titleKey: 'nav.reviews', phase: 2 } },
  { path: 'admin', canActivate: [permissionGuard('taxonomy.manage')], loadComponent: comingSoon, data: { titleKey: 'nav.admin', phase: 2 } },
];
