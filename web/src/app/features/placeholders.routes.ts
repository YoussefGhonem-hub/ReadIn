import { Route } from '@angular/router';

/**
 * Features scheduled after this slice (SPEC §12, §30). Each renders a translated "coming soon" page
 * (shared/ui/coming-soon.page.ts) and keeps its final URL and guard so links and permissions are already right. Empty
 * since the admin console (F23) replaced `/admin`.
 */
export const PLACEHOLDER_ROUTES: Route[] = [];
