import { LucideIconData, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import Eraser from 'lucide/dist/esm/icons/eraser.mjs';
import Highlighter from 'lucide/dist/esm/icons/highlighter.mjs';

/** The highlight toolbar's and the "⋯" item's icons (F30), as data for `[lucideIcon]`. Out of the initial bundle. */
export const HIGHLIGHT_ICON = Object.fromEntries(lucideLegacyIconMap({ Eraser, Highlighter }).map((icon) => [icon.aliases?.[0] ?? icon.name, icon])) as Record<
  'Eraser' | 'Highlighter',
  LucideIconData
>;
