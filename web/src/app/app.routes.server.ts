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
  // Help & support (F35): `/support` itself is public (`**`); your tickets render in the browser, never indexed.
  { path: 'support/tickets', renderMode: RenderMode.Client, headers: { 'X-Robots-Tag': 'noindex' } },
  { path: 'support/tickets/**', renderMode: RenderMode.Client, headers: { 'X-Robots-Tag': 'noindex' } },
  // The admin console (F23): never indexed.
  { path: 'admin', renderMode: RenderMode.Client, headers: { 'X-Robots-Tag': 'noindex' } },
  { path: 'admin/**', renderMode: RenderMode.Client, headers: { 'X-Robots-Tag': 'noindex' } },
  // Search (F16): the page renders on the server without results (the browser searches); never indexed.
  { path: 'search', renderMode: RenderMode.Server, headers: { 'X-Robots-Tag': 'noindex' } },
  { path: '**', renderMode: RenderMode.Server },
];
