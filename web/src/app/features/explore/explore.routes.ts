import { Routes } from '@angular/router';

/**
 * Explore (F15): public and server-rendered (app.routes.server.ts → `**`). Each page is its own chunk and stays alive
 * while you open an article from it (`keepOnBack`, F34). `/explore/{anything else}` is the app's 404.
 */
export default [
  {
    path: '',
    pathMatch: 'full',
    loadComponent: () => import('./explore.page').then((m) => m.ExplorePage),
    title: 'pageTitles.explore',
    data: { keepOnBack: true },
  },
  {
    path: 'trending',
    loadComponent: () => import('./ranking.page').then((m) => m.RankingPage),
    title: 'pageTitles.trending',
    data: { keepOnBack: true, ranking: 'trending' },
  },
  {
    path: 'most-saved',
    loadComponent: () => import('./ranking.page').then((m) => m.RankingPage),
    title: 'pageTitles.mostSaved',
    data: { keepOnBack: true, ranking: 'most-saved' },
  },
] satisfies Routes;
