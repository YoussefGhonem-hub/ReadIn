import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../core/auth/session.store';
import { LanguageService } from '../core/i18n/language.service';
import { ModerationSummaryStore } from '../core/moderation/moderation-summary.store';
import { translatePlural } from '../shared/pipes/intl';
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
          @if (item.id === 'moderation' && moderation.total() > 0) {
            <span class="ms-auto min-w-6 rounded-chip bg-error px-1.5 text-center text-xs font-semibold leading-5 text-on-error" aria-hidden="true" data-moderation-badge>{{
              moderation.total() > 99 ? '99+' : moderation.total()
            }}</span>
            <span class="sr-only">{{ badgeLabel() }}</span>
          }
        </a>
      }
    </nav>
  `,
})
export class SideNav {
  private readonly session = inject(SessionStore);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  /** Open reports for the Moderation badge (F22). */
  protected readonly moderation = inject(ModerationSummaryStore);
  protected readonly items = computed<NavItem[]>(() =>
    SIDE_NAV.filter((item) => !item.permission || this.session.permissions().has(item.permission)).map((item) =>
      item.id === 'profile' ? { ...item, path: profilePath(this.session.username()) } : item,
    ),
  );
  protected readonly badgeLabel = computed(() => translatePlural(this.transloco, 'moderation.openBadge', this.moderation.total(), this.lang()));
}
