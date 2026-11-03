import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../core/auth/session.store';
import { BOTTOM_NAV, NavItem, profilePath } from './nav-items';

/** Mobile-web bottom navigation, matching the app (SPEC §7.2). The Write action is the raised center button. */
@Component({
  selector: 'rd-bottom-nav',
  imports: [RouterLink, RouterLinkActive, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'fixed inset-x-0 bottom-0 z-30 block border-t border-border bg-surface pb-[env(safe-area-inset-bottom)]',
  },
  template: `
    <nav [attr.aria-label]="'nav.main' | transloco" class="mx-auto flex h-16 max-w-lg items-center justify-around px-2">
      @for (item of items(); track item.id) {
        <a
          [routerLink]="item.path"
          routerLinkActive="text-primary! font-bold"
          [routerLinkActiveOptions]="{ exact: !!item.exact }"
          #rla="routerLinkActive"
          [attr.aria-current]="rla.isActive ? 'page' : null"
          class="flex w-16 flex-col items-center gap-1 text-[11px] text-text-secondary no-underline"
        >
          @if (item.id === 'write') {
            <span class="-mt-6 grid h-12 w-12 place-items-center rounded-card bg-primary text-on-primary shadow-raised">
              <svg [lucideIcon]="item.icon" [size]="22"></svg>
            </span>
          } @else {
            <svg [lucideIcon]="item.icon" [size]="22"></svg>
          }
          <span>{{ item.labelKey | transloco }}</span>
        </a>
      }
    </nav>
  `,
})
export class BottomNav {
  private readonly session = inject(SessionStore);
  protected readonly items = computed<NavItem[]>(() =>
    BOTTOM_NAV.map((item) => (item.id === 'profile' ? { ...item, path: profilePath(this.session.username()) } : item)),
  );
}
