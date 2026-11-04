import { Routes } from '@angular/router';

/** Learning paths (F09): the list and one path. Both are public and server-rendered; each page is its own chunk. */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./paths.page').then((m) => m.PathsPage) },
  { path: ':slug', loadComponent: () => import('./path.page').then((m) => m.PathPage) },
] satisfies Routes;
