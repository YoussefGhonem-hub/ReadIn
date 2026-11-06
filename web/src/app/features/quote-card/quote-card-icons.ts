import { LucideIconData, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import Link from 'lucide/dist/esm/icons/link.mjs';
import Quote from 'lucide/dist/esm/icons/quote.mjs';

/**
 * The quote card's icons (F24) that the app's registry doesn't have, as data for `[lucideIcon]`: Share quote in the
 * selection toolbar, Copy link in the dialog. Out of the initial bundle.
 */
export const QUOTE_ICON = Object.fromEntries(lucideLegacyIconMap({ Link, Quote }).map((icon) => [icon.aliases?.[0] ?? icon.name, icon])) as Record<
  'Link' | 'Quote',
  LucideIconData
>;
