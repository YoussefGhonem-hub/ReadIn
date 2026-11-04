import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import BadgeX from 'lucide/dist/esm/icons/badge-x.mjs';
import Hourglass from 'lucide/dist/esm/icons/hourglass.mjs';
import Paperclip from 'lucide/dist/esm/icons/paperclip.mjs';

/** Icons only writer verification uses (F19): the request page and the admins' review. Out of the initial bundle. */
const VERIFICATION_ICONS = { BadgeX, Hourglass, Paperclip };

/** Adds {@link VERIFICATION_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="Hourglass">`). */
export function provideVerificationIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(VERIFICATION_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
