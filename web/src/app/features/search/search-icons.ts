import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) it would be bundled there.
import History from 'lucide/dist/esm/icons/rotate-ccw-clock.mjs';

/** Icons only search uses (the recent searches' clock), in the header box's and the search page's lazy chunks. */
const SEARCH_ICONS = { History };

/**
 * Adds {@link SEARCH_ICONS} to the app's icon registry for the search components' trees, like `provideEditorIcons()`,
 * so the initial bundle keeps only the app-wide icons (shared/ui/icons.ts).
 */
export function provideSearchIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(SEARCH_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
