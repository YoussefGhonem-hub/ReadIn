import { Routes } from '@angular/router';

/**
 * `/moderation` (F22): the reports queue (`?status=open|resolved|dismissed&type=article|comment|user`), the log and
 * one case per reported target. Guarded by `moderation.manage` in app.routes.ts and rendered in the browser.
 */
export default [
  { path: '', pathMatch: 'full', loadComponent: () => import('./moderation-queue.page').then((m) => m.ModerationQueuePage) },
  { path: 'log', loadComponent: () => import('./moderation-log.page').then((m) => m.ModerationLogPage) },
  { path: ':type/:id', loadComponent: () => import('./moderation-case.page').then((m) => m.ModerationCasePage) },
] satisfies Routes;
