import type { LucideIconData } from '@lucide/angular';

/**
 * Icons only the profile screens use, passed as icon data (`[lucideIcon]="icons.calendar"`) instead of being registered
 * app-wide, and written out here rather than imported from `lucide`, whose barrel would pull them into the initial
 * bundle: Lucide's calendar-days and image-plus (ISC). The social platforms' brand icons are
 * in link-icon.ts.
 */
export const PROFILE_ICONS = {
  calendar: {
    name: 'calendar-days',
    node: [
      ['path', { d: 'M8 2v3' }],
      ['path', { d: 'M16 2v3' }],
      ['rect', { x: '3', y: '3', width: '18', height: '18', rx: '2' }],
      ['path', { d: 'M3 9h18' }],
      ['path', { d: 'M8 13h.01' }],
      ['path', { d: 'M12 13h.01' }],
      ['path', { d: 'M16 13h.01' }],
      ['path', { d: 'M8 17h.01' }],
      ['path', { d: 'M12 17h.01' }],
      ['path', { d: 'M16 17h.01' }],
    ],
  },
  imagePlus: {
    name: 'image-plus',
    node: [
      ['path', { d: 'M16 5h6' }],
      ['path', { d: 'M19 2v6' }],
      ['path', { d: 'M21 11.5V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7.5' }],
      ['path', { d: 'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21' }],
      ['circle', { cx: '9', cy: '9', r: '2' }],
    ],
  },
} satisfies Record<string, LucideIconData>;
