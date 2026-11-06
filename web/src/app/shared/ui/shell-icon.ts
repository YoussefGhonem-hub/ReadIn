import { ChangeDetectionStrategy, Component, computed, input, isDevMode } from '@angular/core';
// One file per icon, not the `lucide` barrel: through the barrel every icon of the app would join the initial bundle.
import Bell from 'lucide/dist/esm/icons/bell.mjs';
import Bookmark from 'lucide/dist/esm/icons/bookmark.mjs';
import ChevronDown from 'lucide/dist/esm/icons/chevron-down.mjs';
import Compass from 'lucide/dist/esm/icons/compass.mjs';
import House from 'lucide/dist/esm/icons/house.mjs';
import Languages from 'lucide/dist/esm/icons/languages.mjs';
import Moon from 'lucide/dist/esm/icons/moon.mjs';
import Route from 'lucide/dist/esm/icons/route.mjs';
import Search from 'lucide/dist/esm/icons/search.mjs';
import SquarePen from 'lucide/dist/esm/icons/square-pen.mjs';
import Sun from 'lucide/dist/esm/icons/sun.mjs';
import UserRound from 'lucide/dist/esm/icons/user-round.mjs';

/** The icons of the app shell: the top bar, the bottom nav, their toggles and the avatar's placeholder. */
export const SHELL_ICONS = { Bell, Bookmark, ChevronDown, Compass, House, Languages, Moon, Route, Search, SquarePen, Sun, UserRound };

export type ShellIconName = keyof typeof SHELL_ICONS;

type IconChild = (typeof House)[number];

/**
 * A Lucide icon for the app shell, drawn exactly like `<svg lucideIcon>` (same attributes and classes) but without the
 * `@lucide/angular` runtime or the app's icon registry, which load with the first page (shared/ui/app-icons.ts):
 * `<svg rdIcon="House" [size]="22" aria-hidden="true"></svg>`. Only the {@link SHELL_ICONS}; every other icon uses
 * `lucideIcon`.
 */
@Component({
  // An attribute on <svg>, like Lucide's `svg[lucideIcon]`: the icon is the svg element itself.
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'svg[rdIcon]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    xmlns: 'http://www.w3.org/2000/svg',
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    'stroke-width': '2',
    'stroke-linecap': 'round',
    'stroke-linejoin': 'round',
    'aria-hidden': 'true',
    class: 'lucide',
    '[class]': 'nameClasses()',
    '[attr.width]': 'size()',
    '[attr.height]': 'size()',
  },
  template: `
    @for (child of children(); track $index) {
      @let attrs = child[1];
      @switch (child[0]) {
        @case ('circle') {
          <svg:circle [attr.cx]="attrs['cx']" [attr.cy]="attrs['cy']" [attr.r]="attrs['r']" />
        }
        @case ('line') {
          <svg:line [attr.x1]="attrs['x1']" [attr.x2]="attrs['x2']" [attr.y1]="attrs['y1']" [attr.y2]="attrs['y2']" />
        }
        @default {
          <svg:path [attr.d]="attrs['d']" />
        }
      }
    }
  `,
})
export class ShellIcon {
  /** PascalCase name, like `lucideIcon`. */
  readonly rdIcon = input.required<string>();
  readonly size = input(24);

  protected readonly children = computed<readonly IconChild[]>(() => {
    const icon = SHELL_ICONS[this.rdIcon() as ShellIconName];
    if (!icon && isDevMode()) throw new Error(`'${this.rdIcon()}' is not a shell icon (shared/ui/shell-icon.ts)`);
    return icon ?? [];
  });
  /** `lucide-house lucide-House`, as Lucide names a registered icon. */
  protected readonly nameClasses = computed(() => {
    const name = this.rdIcon();
    return `lucide-${name.replaceAll(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase()} lucide-${name}`;
  });
}
