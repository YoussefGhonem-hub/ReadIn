import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import Ban from 'lucide/dist/esm/icons/ban.mjs';
import Ellipsis from 'lucide/dist/esm/icons/ellipsis.mjs';
import Flag from 'lucide/dist/esm/icons/flag.mjs';
import MessageSquare from 'lucide/dist/esm/icons/message-square.mjs';
import ScrollText from 'lucide/dist/esm/icons/scroll-text.mjs';
import UserRoundCheck from 'lucide/dist/esm/icons/user-round-check.mjs';

/** Icons only reporting and moderation use (F22). Registered on the components that show them, out of the initial bundle. */
const MODERATION_ICONS = { Ban, Ellipsis, Flag, MessageSquare, ScrollText, UserRoundCheck };

/** Adds {@link MODERATION_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="Flag">`). */
export function provideModerationIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(MODERATION_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
