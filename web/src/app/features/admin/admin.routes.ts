import { PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { CanActivateFn, Router, Routes } from '@angular/router';
import { AuthService } from '../../core/auth/auth.service';
import { permissionGuard } from '../../core/auth/guards';
import { SessionStore } from '../../core/auth/session.store';

/** Any of these permissions opens the route; without them the console's dashboard opens instead. */
export function anyPermissionGuard(...permissions: string[]): CanActivateFn {
  return async () => {
    if (!isPlatformBrowser(inject(PLATFORM_ID))) return true;
    const session = inject(SessionStore);
    const router = inject(Router);
    await inject(AuthService).whenReady();
    return permissions.some((p) => session.hasPermission(p)) ? true : router.createUrlTree(['/admin']);
  };
}

/**
 * The admin console (F23), `/admin/**`: its layout with the side menu, and one lazy page per section. The group needs
 * `admin.access` (app.routes.ts) and each section its own permission (contract: "Permissions and sections"). Reports
 * are the F22 queue (`/moderation` redirects here) and Verification the F19 one. Client-rendered and `noindex`
 * (app.routes.server.ts). Titles are i18n keys.
 */
export default [
  {
    path: '',
    loadComponent: () => import('./admin-layout').then((m) => m.AdminLayout),
    children: [
      { path: '', pathMatch: 'full', title: 'admin.nav.dashboard', loadComponent: () => import('./dashboard/dashboard.page').then((m) => m.AdminDashboardPage) },
      {
        path: 'users',
        canActivate: [permissionGuard('users.read')],
        title: 'admin.nav.users',
        loadComponent: () => import('./users/users.page').then((m) => m.AdminUsersPage),
      },
      {
        path: 'users/:id',
        canActivate: [permissionGuard('users.read')],
        loadComponent: () => import('./users/user.page').then((m) => m.AdminUserPage),
      },
      {
        path: 'content',
        canActivate: [permissionGuard('moderation.manage')],
        title: 'admin.nav.content',
        loadComponent: () => import('./content/content.page').then((m) => m.AdminContentPage),
      },
      {
        path: 'content/:id',
        canActivate: [permissionGuard('moderation.manage')],
        loadComponent: () => import('./content/article.page').then((m) => m.AdminArticlePage),
      },
      // The F22 reports queue, its cases and the moderation log; each page sets its own title.
      { path: 'reports', canActivate: [permissionGuard('moderation.manage')], loadChildren: () => import('../moderation/moderation.routes') },
      {
        path: 'tickets',
        canActivate: [permissionGuard('support.manage')],
        title: 'admin.nav.tickets',
        loadComponent: () => import('./tickets/tickets.page').then((m) => m.AdminTicketsPage),
      },
      {
        path: 'tickets/:id',
        canActivate: [permissionGuard('support.manage')],
        loadComponent: () => import('./tickets/ticket.page').then((m) => m.AdminTicketPage),
      },
      {
        path: 'verification',
        canActivate: [permissionGuard('verification.manage')],
        loadComponent: () => import('./verification/admin-verification.page').then((m) => m.AdminVerificationPage),
      },
      {
        path: 'taxonomy',
        canActivate: [permissionGuard('taxonomy.manage')],
        title: 'admin.nav.taxonomy',
        loadComponent: () => import('./taxonomy/taxonomy.page').then((m) => m.AdminTaxonomyPage),
      },
      {
        path: 'paths',
        canActivate: [anyPermissionGuard('paths.manage', 'articles.feature')],
        title: 'admin.nav.paths',
        loadComponent: () => import('./paths/paths.page').then((m) => m.AdminPathsPage),
      },
      {
        path: 'announcements',
        canActivate: [permissionGuard('notifications.broadcast')],
        title: 'admin.nav.announcements',
        loadComponent: () => import('./announcements/announcements.page').then((m) => m.AdminAnnouncementsPage),
      },
      {
        path: 'audit',
        canActivate: [permissionGuard('audit.read')],
        title: 'admin.nav.audit',
        loadComponent: () => import('./audit/audit.page').then((m) => m.AdminAuditPage),
      },
      {
        path: 'system',
        canActivate: [permissionGuard('system.settings')],
        title: 'admin.nav.system',
        loadComponent: () => import('./system/system.page').then((m) => m.AdminSystemPage),
      },
      { path: '**', loadComponent: () => import('../../shared/ui/not-found.page').then((m) => m.NotFoundPage) },
    ],
  },
] satisfies Routes;
