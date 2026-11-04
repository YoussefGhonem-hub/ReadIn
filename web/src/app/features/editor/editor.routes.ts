import { Routes } from '@angular/router';

/**
 * `/write` (F05, permission `articles.create`, browser only): My articles, and the editor at `/write/new` and
 * `/write/:id`. The editor (Tiptap) is its own lazy chunk, loaded only when an article is opened. This file imports
 * nothing else, so it adds no chunk boundary to the initial bundle; the pages provide the editor icons.
 */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./my-articles.page').then((m) => m.MyArticlesPage) },
  { path: ':id', loadComponent: () => import('./editor.page').then((m) => m.EditorPage), data: { hideBottomNav: true } },
] satisfies Routes;
