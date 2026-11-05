import { Routes } from '@angular/router';
import { authGuard } from '../../core/auth/guards';

/**
 * `/settings` (F18), `/settings/profile`, Edit profile (F14), `/settings/notifications`, what you get notified about and
 * quiet hours (F17), `/settings/interests`, the fields and topics you follow (F12), and `/settings/muted`, what you
 * muted (F28); all but the first are signed-in only. All render in the browser.
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
  // The writers, fields and topics you muted (F28), with unmute.
  {
    path: 'muted',
    canActivate: [authGuard],
    loadComponent: () => import('./muted/muted.page').then((m) => m.MutedPage),
    title: 'mute.settings.title',
  },
] satisfies Routes;
