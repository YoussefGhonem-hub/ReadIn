import { LucideIconData, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import UserRoundCheck from 'lucide/dist/esm/icons/user-round-check.mjs';
import UserRoundX from 'lucide/dist/esm/icons/user-round-x.mjs';

const BLOCK_ICON_LIST = lucideLegacyIconMap({ UserRoundCheck, UserRoundX });

/**
 * The Block / Unblock icons (F36) as data, for `[lucideIcon]` in the "⋯" menus that already provide another icon set
 * (a second LUCIDE_ICONS provider there would replace it). Out of the initial bundle.
 */
export const BLOCK_ICON = Object.fromEntries(BLOCK_ICON_LIST.map((icon) => [icon.aliases?.[0] ?? icon.name, icon])) as Record<
  'UserRoundCheck' | 'UserRoundX',
  LucideIconData
>;
