import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, LucideIconData, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import ListX from 'lucide/dist/esm/icons/list-x.mjs';
import ThumbsDown from 'lucide/dist/esm/icons/thumbs-down.mjs';
import UserMinus from 'lucide/dist/esm/icons/user-minus.mjs';
import Volume2 from 'lucide/dist/esm/icons/volume-2.mjs';
import VolumeX from 'lucide/dist/esm/icons/volume-x.mjs';

/** Icons only the "⋯" menu's F28 items, the muted banner and Settings → Muted use. Out of the initial bundle. */
const MUTE_ICONS = { ListX, ThumbsDown, UserMinus, Volume2, VolumeX };
const MUTE_ICON_LIST = lucideLegacyIconMap(MUTE_ICONS);

/**
 * The same icons as data, for `[lucideIcon]` in a component that already provides another set (the article "⋯" menu
 * provides the moderation icons; a second LUCIDE_ICONS provider there would replace it).
 */
export const MUTE_ICON = Object.fromEntries(MUTE_ICON_LIST.map((icon) => [icon.aliases?.[0] ?? icon.name, icon])) as Record<
  keyof typeof MUTE_ICONS,
  LucideIconData
>;

/** Adds the mute icons to the app's icon registry for this component tree (`<svg lucideIcon="VolumeX">`). */
export function provideMuteIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of MUTE_ICON_LIST) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
