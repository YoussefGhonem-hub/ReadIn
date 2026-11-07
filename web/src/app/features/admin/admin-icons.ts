import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import Activity from 'lucide/dist/esm/icons/activity.mjs';
import ArrowDown from 'lucide/dist/esm/icons/arrow-down.mjs';
import ArrowUp from 'lucide/dist/esm/icons/arrow-up.mjs';
import Ban from 'lucide/dist/esm/icons/ban.mjs';
import Ellipsis from 'lucide/dist/esm/icons/ellipsis.mjs';
import Eraser from 'lucide/dist/esm/icons/eraser.mjs';
import Flag from 'lucide/dist/esm/icons/flag.mjs';
import HardDrive from 'lucide/dist/esm/icons/hard-drive.mjs';
import Hash from 'lucide/dist/esm/icons/hash.mjs';
import ImagePlus from 'lucide/dist/esm/icons/image-plus.mjs';
import Lock from 'lucide/dist/esm/icons/lock.mjs';
import Megaphone from 'lucide/dist/esm/icons/megaphone.mjs';
import Menu from 'lucide/dist/esm/icons/menu.mjs';
import Merge from 'lucide/dist/esm/icons/merge.mjs';
import MessageSquare from 'lucide/dist/esm/icons/message-square.mjs';
import Minus from 'lucide/dist/esm/icons/minus.mjs';
import RotateCcw from 'lucide/dist/esm/icons/rotate-ccw.mjs';
import ScrollText from 'lucide/dist/esm/icons/scroll-text.mjs';
import Send from 'lucide/dist/esm/icons/send.mjs';
import Star from 'lucide/dist/esm/icons/star.mjs';
import StarOff from 'lucide/dist/esm/icons/star-off.mjs';
import StickyNote from 'lucide/dist/esm/icons/sticky-note.mjs';
import Tags from 'lucide/dist/esm/icons/tags.mjs';
import TrendingDown from 'lucide/dist/esm/icons/trending-down.mjs';
import TrendingUp from 'lucide/dist/esm/icons/trending-up.mjs';
import UserRoundCheck from 'lucide/dist/esm/icons/user-round-check.mjs';
import Users from 'lucide/dist/esm/icons/users.mjs';

/** Icons only the admin console (F23) and the support pages (F35) use. Registered on their layouts, out of the initial bundle. */
const ADMIN_ICONS = {
  Activity,
  ArrowDown,
  ArrowUp,
  Ban,
  Ellipsis,
  Eraser,
  Flag,
  HardDrive,
  Hash,
  ImagePlus,
  Lock,
  Megaphone,
  Menu,
  Merge,
  MessageSquare,
  Minus,
  RotateCcw,
  ScrollText,
  Send,
  Star,
  StarOff,
  StickyNote,
  Tags,
  TrendingDown,
  TrendingUp,
  UserRoundCheck,
  Users,
};

/** Adds {@link ADMIN_ICONS} to the app's icon registry for this component tree (`<svg lucideIcon="Megaphone">`). */
export function provideAdminIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(ADMIN_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
