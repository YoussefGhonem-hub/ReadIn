import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../core/auth/session.store';
import { NavItem, SIDE_NAV, profilePath } from './nav-items';

@Component({
  selector: 'rd-side-nav',
  imports: [RouterLink, RouterLinkActive, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <nav [attr.aria-label]="'nav.main' | transloco" class="flex flex-col gap-1 py-6 pe-4">
      @for (item of items(); track item.id) {
        <a
          [routerLink]="item.path"
          routerLinkActive="bg-primary-container! text-on-primary-container! font-semibold"
          [routerLinkActiveOptions]="{ exact: !!item.exact }"
          #rla="routerLinkActive"
          [attr.aria-current]="rla.isActive ? 'page' : null"
          class="flex min-h-11 items-center gap-3 rounded-md px-3 text-text-secondary no-underline hover:bg-surface-variant hover:text-text-primary"
        >
          <svg [lucideIcon]="item.icon" [size]="20"></svg>
          <span>{{ item.labelKey | transloco }}</span>
        </a>
      }
    </nav>
  `,
})
export class SideNav {
  private readonly session = inject(SessionStore);
  protected readonly items = computed<NavItem[]>(() =>
    SIDE_NAV.map((item) => (item.id === 'profile' ? { ...item, path: profilePath(this.session.username()) } : item)),
  );
}
