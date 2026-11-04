import { RenderMode, ServerRoute } from '@angular/ssr';

/**
 * Public, crawlable pages render on the server per request (the `theme`/`lang` cookies decide `<html>` attributes).
 * Pages that only make sense for a signed-in user render in the browser, where the session lives (SPEC §9.3).
 */
export const serverRoutes: ServerRoute[] = [
  { path: 'auth/**', renderMode: RenderMode.Client },
  { path: 'onboarding', renderMode: RenderMode.Client },
  { path: 'settings', renderMode: RenderMode.Client },
  { path: 'settings/**', renderMode: RenderMode.Client },
  { path: 'write', renderMode: RenderMode.Client },
  { path: 'write/**', renderMode: RenderMode.Client },
  { path: 'saved', renderMode: RenderMode.Client },
  { path: 'moderation', renderMode: RenderMode.Client },
  { path: 'moderation/**', renderMode: RenderMode.Client },
  { path: 'notifications', renderMode: RenderMode.Client },
  { path: 'me/**', renderMode: RenderMode.Client },
  { path: 'verification', renderMode: RenderMode.Client },
  { path: 'admin/**', renderMode: RenderMode.Client },
  { path: '**', renderMode: RenderMode.Server },
];
