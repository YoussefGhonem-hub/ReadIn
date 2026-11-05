import { Routes } from '@angular/router';

/**
 * Under `/@{username}` (app.routes.ts → profileMatcher, which passes `username` down): the profile (F14), its
 * followers / following lists (F12) and the writer's category pages (F31, `/c/{slug}`; `/c/_other` is "مقالات تانية"),
 * server-rendered like the profile. Each page is its own chunk; anything else under a profile is a 404.
 */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./profile.page').then((m) => m.ProfilePage) },
  { path: 'followers', loadComponent: () => import('./people.page').then((m) => m.PeoplePage), data: { list: 'followers' } },
  { path: 'following', loadComponent: () => import('./people.page').then((m) => m.PeoplePage), data: { list: 'following' } },
  { path: 'c/:slug', loadComponent: () => import('../categories/category.page').then((m) => m.CategoryPage) },
] satisfies Routes;
