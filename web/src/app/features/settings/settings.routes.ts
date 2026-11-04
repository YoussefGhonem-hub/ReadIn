import { Routes } from '@angular/router';
import { authGuard } from '../../core/auth/guards';

/**
 * `/settings` (F18), `/settings/profile`, Edit profile (F14), `/settings/notifications`, what you get notified about and
 * quiet hours (F17), and `/settings/interests`, the fields and topics you follow (F12); the last three are signed-in
 * only. All render in the browser.
 */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./settings.page').then((m) => m.SettingsPage) },
  { path: 'profile', canActivate: [authGuard], loadComponent: () => import('../profile/edit-profile.page').then((m) => m.EditProfilePage) },
  {
    path: 'notifications',
    canActivate: [authGuard],
    loadComponent: () => import('./notifications/notification-settings.page').then((m) => m.NotificationSettingsPage),
  },
  {
    path: 'interests',
    canActivate: [authGuard],
    loadComponent: () => import('./interests/interests.page').then((m) => m.InterestsPage),
    // An i18n key (core/i18n/page-title.strategy.ts).
    title: 'settings.interests.title',
  },
] satisfies Routes;
