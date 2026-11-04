import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import EllipsisVertical from 'lucide/dist/esm/icons/ellipsis-vertical.mjs';
import PartyPopper from 'lucide/dist/esm/icons/party-popper.mjs';

/** Icons only the path page uses. Registered on that page, so they stay out of the initial bundle. */
const PATH_ICONS = { EllipsisVertical, PartyPopper };

/** Adds {@link PATH_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="PartyPopper">`). */
export function providePathIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(PATH_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
