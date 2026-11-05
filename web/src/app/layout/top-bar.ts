import { ChangeDetectionStrategy, Component, PLATFORM_ID, Type, afterNextRender, computed, inject, input, signal } from '@angular/core';
import { NgComponentOutlet, isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../core/auth/session.store';
import { LanguageService } from '../core/i18n/language.service';
import { NotificationBadge, notificationsLabel } from '../core/notifications/notification-badge';
import { StreakStore } from '../features/reading/streak.store';
import { Avatar } from '../shared/ui/avatar';
import { StreakBadge } from '../shared/ui/streak-badge';
import { Wordmark } from '../shared/ui/wordmark';
import { profilePath } from './nav-items';

/** From this width the header has the search box (F16); below it, the search icon. Tailwind's `md`. */
const SEARCH_BOX_QUERY = '(min-width: 48rem)';

@Component({
  selector: 'rd-top-bar',
  imports: [RouterLink, TranslocoPipe, Wordmark, StreakBadge, Avatar, LucideDynamicIcon, NgComponentOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'sticky top-0 z-30 block border-b border-border bg-bg/90 backdrop-blur' },
  template: `
    <div class="mx-auto flex h-16 max-w-[1200px] items-center gap-3 px-4 lg:px-6">
      <a routerLink="/" class="no-underline" [attr.aria-label]="'nav.home' | transloco">
        <rd-wordmark [size]="24" [withIcon]="true" />
      </a>
      @if (searchBox()) {
        <!-- The search box (F16) loads on its own; until then (and without JavaScript) this opens the search page. -->
        <div class="ms-4 hidden max-w-[420px] flex-1 md:block">
          @if (headerSearch(); as component) {
            <ng-container *ngComponentOutlet="component" />
          } @else {
            <a
              routerLink="/search"
              class="rd-input flex h-10 min-h-10 items-center gap-2.5 ps-3 text-sm text-text-secondary no-underline"
              data-header-search-placeholder
            >
              <svg lucideIcon="Search" [size]="18" class="shrink-0" aria-hidden="true"></svg>
              <span class="truncate">{{ 'search.headerPlaceholder' | transloco }}</span>
            </a>
          }
        </div>
      }
      <div class="ms-auto flex items-center gap-2">
        @if (session.isAuthenticated()) {
          <rd-streak-badge [streak]="streaks.streak()" />
        }
        @if (searchBox()) {
          <a routerLink="/search" class="rd-icon-btn md:hidden" [attr.aria-label]="'nav.search' | transloco" data-search-link>
            <svg lucideIcon="Search" [size]="18"></svg>
          </a>
        }
        <a routerLink="/notifications" class="rd-icon-btn relative" [attr.aria-label]="notificationsLabel()" data-notifications-link>
          <svg lucideIcon="Bell" [size]="18"></svg>
          @if (badge.count() > 0) {
            <span class="absolute -end-1 -top-1 h-2.5 w-2.5 rounded-full bg-accent" aria-hidden="true" data-unread-badge></span>
          }
        </a>
        @if (session.isAuthenticated()) {
          <a [routerLink]="profileLink()" class="hidden lg:inline-flex" [attr.aria-label]="'nav.profile' | transloco">
            <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="36" />
          </a>
        } @else if (session.isGuest()) {
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary hidden min-h-10 sm:inline-flex">{{ 'auth.signIn.submit' | transloco }}</a>
        }
      </div>
    </div>
  `,
})
export class TopBar {
  protected readonly session = inject(SessionStore);
  /** Unseen notifications (F17): live, or from the REST fallback. */
  protected readonly badge = inject(NotificationBadge);
  protected readonly streaks = inject(StreakStore);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  /** "Notifications" or "Notifications, 3 new": the dot alone says nothing to a screen reader. */
  protected readonly notificationsLabel = computed(() => notificationsLabel(this.transloco, this.lang(), this.badge.count()));

  /** The search box or icon; the search page has its own box. */
  readonly searchBox = input(true);
  /** The header's search box (features/search/header-search.ts): its own chunk, loaded once a wide screen is idle. */
  protected readonly headerSearch = signal<Type<unknown> | null>(null);

  constructor() {
    if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
    afterNextRender(() => {
      if (typeof matchMedia === 'undefined') return;
      const wide = matchMedia(SEARCH_BOX_QUERY);
      const load = () => {
        wide.removeEventListener('change', onChange);
        const start = () =>
          import('../features/search/header-search').then(
            ({ HeaderSearch }) => this.headerSearch.set(HeaderSearch),
            () => undefined, // offline: the placeholder still opens the search page
          );
        if (typeof requestIdleCallback === 'function') requestIdleCallback(() => void start(), { timeout: 2000 });
        else setTimeout(() => void start(), 200);
      };
      const onChange = () => {
        if (wide.matches) load();
      };
      if (wide.matches) load();
      else wide.addEventListener('change', onChange);
    });
  }

  protected profileLink(): string {
    return profilePath(this.session.username());
  }
}
