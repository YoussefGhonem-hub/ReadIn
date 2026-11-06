import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import ArrowUp from 'lucide/dist/esm/icons/arrow-up.mjs';
import CornerDownRight from 'lucide/dist/esm/icons/corner-down-right.mjs';
import EllipsisVertical from 'lucide/dist/esm/icons/ellipsis-vertical.mjs';
import FaceSlightlySmiling from 'lucide/dist/esm/icons/face-slightly-smiling.mjs';
import Flag from 'lucide/dist/esm/icons/flag.mjs';
import Heart from 'lucide/dist/esm/icons/heart.mjs';
import PinOff from 'lucide/dist/esm/icons/pin-off.mjs';
import Pin from 'lucide/dist/esm/icons/pin.mjs';
import SendHorizontal from 'lucide/dist/esm/icons/send-horizontal.mjs';
import Send from 'lucide/dist/esm/icons/send.mjs';

/** Icons only the comments use. Registered on the comments section, so they stay out of the initial bundle. */
const COMMENT_ICONS = { ArrowUp, CornerDownRight, EllipsisVertical, FaceSlightlySmiling, Flag, Heart, Pin, PinOff, Send, SendHorizontal };

/** Adds {@link COMMENT_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="Heart">`). */
export function provideCommentIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(COMMENT_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
