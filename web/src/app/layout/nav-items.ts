import type { AppIconName } from '../shared/ui/icons';

export type NavId = 'home' | 'explore' | 'write' | 'saved' | 'profile' | 'notifications' | 'search' | 'paths' | 'settings';

export interface NavItem {
  id: NavId;
  labelKey: string;
  icon: AppIconName;
  /** Absolute path; `profile` is resolved at runtime from the signed-in user. */
  path: string;
  exact?: boolean;
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
};

/** Same five destinations as the mobile app's bottom navigation (SPEC §7.2). */
export const BOTTOM_NAV: readonly NavItem[] = [ITEMS.home, ITEMS.explore, ITEMS.write, ITEMS.saved, ITEMS.profile];

export const SIDE_NAV: readonly NavItem[] = [
  ITEMS.home,
  ITEMS.explore,
  ITEMS.search,
  ITEMS.paths,
  ITEMS.saved,
  ITEMS.notifications,
  ITEMS.write,
  ITEMS.profile,
  ITEMS.settings,
];

export function profilePath(username: string | null): string {
  return username ? `/@${username}` : '/auth/sign-in';
}
