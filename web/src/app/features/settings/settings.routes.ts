import { Routes } from '@angular/router';
import { authGuard } from '../../core/auth/guards';

/** `/settings` (F18) and `/settings/profile`, Edit profile (F14, signed-in only). Both render in the browser. */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./settings.page').then((m) => m.SettingsPage) },
  { path: 'profile', canActivate: [authGuard], loadComponent: () => import('../profile/edit-profile.page').then((m) => m.EditProfilePage) },
] satisfies Routes;
