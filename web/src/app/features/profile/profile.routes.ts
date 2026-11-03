import { Routes } from '@angular/router';

/**
 * Under `/@{username}` (app.routes.ts → profileMatcher, which passes `username` down): the profile (F14) and its
 * followers / following lists (F12). Each page is its own chunk; anything else under a profile is a 404.
 */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./profile.page').then((m) => m.ProfilePage) },
  { path: 'followers', loadComponent: () => import('./people.page').then((m) => m.PeoplePage), data: { list: 'followers' } },
  { path: 'following', loadComponent: () => import('./people.page').then((m) => m.PeoplePage), data: { list: 'following' } },
] satisfies Routes;
