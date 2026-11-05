import { Route } from '@angular/router';
import { permissionGuard } from '../core/auth/guards';

const comingSoon = () => import('../shared/ui/coming-soon.page').then((m) => m.ComingSoonPage);

/**
 * Features scheduled after this slice (SPEC §12, §30). Each renders a translated "coming soon" page and keeps
 * its final URL and guard so links and permissions are already right.
 */
export const PLACEHOLDER_ROUTES: Route[] = [
  { path: 'admin', canActivate: [permissionGuard('taxonomy.manage')], loadComponent: comingSoon, data: { titleKey: 'nav.admin', phase: 2 } },
];
