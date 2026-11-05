import type { AppIconName } from '../shared/ui/icons';

export type NavId =
  | 'home'
  | 'explore'
  | 'write'
  | 'saved'
  | 'profile'
  | 'notifications'
  | 'search'
  | 'paths'
  | 'settings'
  | 'myArticles'
  | 'myPaths'
  | 'moderation'
  | 'verificationRequests';

export interface NavItem {
  id: NavId;
  labelKey: string;
  icon: AppIconName;
  /** Absolute path; `profile` is resolved at runtime from the signed-in user. */
  path: string;
  /** Query parameters of the link (`/paths?tab=mine`). */
  queryParams?: Record<string, string>;
  exact?: boolean;
  /** Shown only to accounts with this permission (SPEC §10.2). */
  permission?: string;
}

const ITEMS: Record<NavId, NavItem> = {
  home: { id: 'home', labelKey: 'nav.home', icon: 'House', path: '/', exact: true },
  explore: { id: 'explore', labelKey: 'nav.explore', icon: 'Compass', path: '/explore' },
  write: { id: 'write', labelKey: 'nav.write', icon: 'SquarePen', path: '/write' },
  saved: { id: 'saved', labelKey: 'nav.saved', icon: 'Bookmark', path: '/saved' },
  profile: { id: 'profile', labelKey: 'nav.profile', icon: 'UserRound', path: '/auth/sign-in' },
  notifications: { id: 'notifications', labelKey: 'nav.notifications', icon: 'Bell', path: '/notifications' },
  search: { id: 'search', labelKey: 'nav.search', icon: 'Search', path: '/search' },
  paths: { id: 'paths', labelKey: 'nav.paths', icon: 'Route', path: '/paths' },
  settings: { id: 'settings', labelKey: 'nav.settings', icon: 'Settings', path: '/settings' },
  myArticles: { id: 'myArticles', labelKey: 'nav.myArticles', icon: 'FileText', path: '/write', permission: 'articles.create' },
  myPaths: { id: 'myPaths', labelKey: 'nav.myPaths', icon: 'Route', path: '/paths', queryParams: { tab: 'mine' } },
  moderation: { id: 'moderation', labelKey: 'nav.moderation', icon: 'ShieldAlert', path: '/moderation', permission: 'moderation.manage' },
  verificationRequests: {
    id: 'verificationRequests',
    labelKey: 'nav.verificationRequests',
    icon: 'BadgeCheck',
    path: '/admin/verification',
    permission: 'verification.manage',
  },
};

/** Same five destinations as the mobile app's bottom navigation (SPEC §7.2). */
export const BOTTOM_NAV: readonly NavItem[] = [ITEMS.home, ITEMS.explore, ITEMS.write, ITEMS.saved, ITEMS.profile];

/**
 * The top bar's destinations from `md` up, an icon above a small label (labels from `lg`). Notifications has its own
 * element in the bar (the unread dot, later its dropdown), in this position.
 */
export const TOP_NAV: readonly NavItem[] = [ITEMS.home, ITEMS.explore, ITEMS.paths, ITEMS.saved, ITEMS.notifications, ITEMS.write];

/** The "Me" menu's links, after the profile header; the permission items only for accounts that have them. */
export const ME_MENU: readonly NavItem[] = [ITEMS.settings, ITEMS.myArticles, ITEMS.myPaths, ITEMS.moderation, ITEMS.verificationRequests];

export function profilePath(username: string | null): string {
  return username ? `/@${username}` : '/auth/sign-in';
}
