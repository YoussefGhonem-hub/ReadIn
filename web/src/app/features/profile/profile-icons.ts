import type { LucideIconData } from '@lucide/angular';

/**
 * Icons only the profile screens use, passed as icon data (`[lucideIcon]="icons.github"`) instead of being registered
 * app-wide, and written out here rather than imported from `lucide`, whose barrel would pull them into the initial
 * bundle. Lucide 1.x has no brand icons: GitHub and LinkedIn are the line glyphs of earlier Lucide releases; the rest
 * are Lucide's globe, calendar-days and image-plus (ISC).
 */
export const PROFILE_ICONS = {
  github: {
    name: 'github',
    node: [
      [
        'path',
        {
          d: 'M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4',
        },
      ],
      ['path', { d: 'M9 18c-4.51 2-5-2-7-2' }],
    ],
  },
  linkedin: {
    name: 'linkedin',
    node: [
      ['path', { d: 'M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z' }],
      ['rect', { width: '4', height: '12', x: '2', y: '9' }],
      ['circle', { cx: '4', cy: '4', r: '2' }],
    ],
  },
  website: {
    name: 'globe',
    node: [
      ['circle', { cx: '12', cy: '12', r: '10' }],
      ['path', { d: 'M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20' }],
      ['path', { d: 'M2 12h20' }],
    ],
  },
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

export type LinkKind = 'github' | 'linkedin' | 'website';
export const LINK_KINDS: readonly LinkKind[] = ['github', 'linkedin', 'website'];
