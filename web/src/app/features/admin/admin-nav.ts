import type { AdminSummaryDto } from '../../core/api/models';

export type AdminSectionId =
  | 'dashboard'
  | 'users'
  | 'content'
  | 'reports'
  | 'tickets'
  | 'verification'
  | 'taxonomy'
  | 'paths'
  | 'announcements'
  | 'audit'
  | 'system';

export interface AdminSection {
  id: AdminSectionId;
  /** `admin.nav.{id}`. */
  labelKey: string;
  icon: string;
  path: string;
  /** Shown when the session holds any of these (contract: "Permissions and sections"). */
  permissions: readonly string[];
  /** The summary count shown on the item. */
  badge?: keyof Pick<AdminSummaryDto, 'openReports' | 'openTickets' | 'pendingVerifications'>;
}

const section = (id: AdminSectionId, path: string, icon: string, permissions: string[], badge?: AdminSection['badge']): AdminSection => ({
  id,
  labelKey: `admin.nav.${id}`,
  icon,
  path,
  permissions,
  ...(badge ? { badge } : {}),
});

/** The console's side menu (SPEC F23), in its order. Each section needs its permission; the whole console `admin.access`. */
export const ADMIN_SECTIONS: readonly AdminSection[] = [
  section('dashboard', '/admin', 'LayoutDashboard', ['admin.access']),
  section('users', '/admin/users', 'Users', ['users.read']),
  section('content', '/admin/content', 'FileText', ['moderation.manage']),
  section('reports', '/admin/reports', 'Flag', ['moderation.manage'], 'openReports'),
  section('tickets', '/admin/tickets', 'LifeBuoy', ['support.manage'], 'openTickets'),
  section('verification', '/admin/verification', 'BadgeCheck', ['verification.manage'], 'pendingVerifications'),
  section('taxonomy', '/admin/taxonomy', 'Tags', ['taxonomy.manage']),
  section('paths', '/admin/paths', 'Route', ['paths.manage', 'articles.feature']),
  section('announcements', '/admin/announcements', 'Megaphone', ['notifications.broadcast']),
  section('audit', '/admin/audit', 'ScrollText', ['audit.read']),
  section('system', '/admin/system', 'Server', ['system.settings']),
];

/** The sections these permissions open. */
export function visibleSections(permissions: ReadonlySet<string>): AdminSection[] {
  return ADMIN_SECTIONS.filter((s) => s.permissions.some((p) => permissions.has(p)));
}

/** The section a URL is in (the longest matching path), or null. */
export function sectionOf(url: string): AdminSection | null {
  const path = url.split(/[?#]/)[0].replace(/\/+$/, '') || '/';
  let best: AdminSection | null = null;
  for (const s of ADMIN_SECTIONS) {
    if ((path === s.path || path.startsWith(`${s.path}/`)) && (!best || s.path.length > best.path.length)) best = s;
  }
  return best;
}
