import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import PenLine from 'lucide/dist/esm/icons/pen-line.mjs';
import Repeat2 from 'lucide/dist/esm/icons/repeat-2.mjs';
import Undo2 from 'lucide/dist/esm/icons/undo-2.mjs';

/**
 * Icons only the post bar uses (F29 Repost and its menu). Registered where they're used, so they stay out of the initial
 * bundle.
 */
const POST_BAR_ICONS = { Repeat2, PenLine, Undo2 };

/** Adds {@link POST_BAR_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="Repeat2">`). */
export function providePostBarIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(POST_BAR_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
