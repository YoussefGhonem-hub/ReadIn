import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import CheckCheck from 'lucide/dist/esm/icons/check-check.mjs';
import MoonStar from 'lucide/dist/esm/icons/moon-star.mjs';
import PartyPopper from 'lucide/dist/esm/icons/party-popper.mjs';
import PenLine from 'lucide/dist/esm/icons/pen-line.mjs';
import Reply from 'lucide/dist/esm/icons/reply.mjs';

/** Icons only the notification center and its settings use. Registered there, so they stay out of the initial bundle. */
const NOTIFICATION_ICONS = { CheckCheck, MoonStar, PartyPopper, PenLine, Reply };

/** Adds {@link NOTIFICATION_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="Reply">`). */
export function provideNotificationIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(NOTIFICATION_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
