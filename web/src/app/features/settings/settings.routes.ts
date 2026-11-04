import { Routes } from '@angular/router';
import { authGuard } from '../../core/auth/guards';

/**
 * `/settings` (F18), `/settings/profile`, Edit profile (F14), and `/settings/notifications`, what you get notified about
 * and quiet hours (F17); the last two are signed-in only. All render in the browser.
 */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./settings.page').then((m) => m.SettingsPage) },
  { path: 'profile', canActivate: [authGuard], loadComponent: () => import('../profile/edit-profile.page').then((m) => m.EditProfilePage) },
  {
    path: 'notifications',
    canActivate: [authGuard],
    loadComponent: () => import('./notifications/notification-settings.page').then((m) => m.NotificationSettingsPage),
  },
] satisfies Routes;
