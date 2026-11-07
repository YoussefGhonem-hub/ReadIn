import {
  ChangeDetectionStrategy,
  Component,
  PLATFORM_ID,
  Type,
  afterNextRender,
  effect,
  inject,
  input,
  signal,
} from '@angular/core';
import { NgComponentOutlet, isPlatformBrowser } from '@angular/common';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { SessionStore } from '../core/auth/session.store';
import { NotificationsMenu } from '../features/notifications/notifications-menu';
import { appIconsReady } from '../shared/ui/app-icons';
import { ShellIcon } from '../shared/ui/shell-icon';
import { LogoMark } from '../shared/ui/logo-mark';
import { Wordmark } from '../shared/ui/wordmark';
import { TOP_NAV } from './nav-items';
import { LanguageToggle } from './language-toggle';
import { ThemeToggle } from './theme-toggle';

/** From this width the header has the search box (F16) and the nav row; below it, the compact bar. Tailwind's `md`. */
const SEARCH_BOX_QUERY = '(min-width: 48rem)';

/**
 * The top bar. From `md`: the ReadIn logo mark (shared/ui/logo-mark.ts), the search box, then the destinations as an
 * icon above a small label (labels from `lg`; the current one gets a bar under it), the theme and language toggles and "Me" (its menu: profile, links,
 * appearance, sign out) or "Sign in". Below `md`: the mark, the search icon, the bell, the theme and language toggles and the avatar
 * (the bottom nav has the destinations). "Me" is its own chunk (layout/me-button.ts), loaded once the session is
 * restored as a member's (the server renders every page signed out); its menu loads when the button is hovered, focused
 * or opened; the bell's dropdown too (features/notifications/notifications-menu.ts).
 */
@Component({
  selector: 'rd-top-bar',
  imports: [RouterLink, RouterLinkActive, TranslocoPipe, LogoMark, Wordmark, ShellIcon, NgComponentOutlet, NotificationsMenu, ThemeToggle, LanguageToggle],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'sticky top-0 z-30 block border-b border-border bg-surface' },
  template: `
    <div class="mx-auto flex h-16 max-w-[1128px] items-center gap-3 px-4">
      <a routerLink="/" class="flex shrink-0 items-center no-underline" [attr.aria-label]="'nav.home' | transloco" data-home-mark>
        <span class="inline-flex items-center" dir="ltr">
          <rd-logo-mark [size]="32" />
          <!-- The full wordmark on narrow screens; the mark alone next to the search box and the nav row. -->
          <rd-wordmark class="ms-2 md:hidden" [size]="24" />
        </span>
      </a>
      @if (searchBox()) {
        <!-- The search box (F16) loads on its own; until then (and without JavaScript) this opens the search page. -->
        <div class="hidden min-w-0 max-w-[280px] flex-1 md:block">
          @if (headerSearch(); as component) {
            <ng-container *ngComponentOutlet="component" />
          } @else {
            <a
              routerLink="/search"
              class="rd-input flex h-10 min-h-10 items-center gap-2.5 ps-3 text-sm text-text-secondary no-underline"
              data-header-search-placeholder
            >
              <svg rdIcon="Search" [size]="18" class="shrink-0" aria-hidden="true"></svg>
              <span class="truncate">{{ 'search.headerPlaceholder' | transloco }}</span>
            </a>
          }
        </div>
      }

      <!-- md and up: the destinations, the theme toggle and Me. The bell's item is 48 px wide like the others until lg. -->
      <nav
        class="ms-auto hidden h-full items-stretch md:flex [&_[data-notifications-link]]:min-w-12 lg:[&_[data-notifications-link]]:min-w-20"
        [attr.aria-label]="'nav.main' | transloco"
        data-top-nav
      >
        @for (item of nav; track item.id) {
          @if (item.id === 'notifications') {
            <rd-notifications-menu variant="stacked" />
          } @else {
            <a
              [routerLink]="item.path"
              routerLinkActive
              #rla="routerLinkActive"
              [routerLinkActiveOptions]="{ exact: !!item.exact }"
              [attr.aria-current]="rla.isActive ? 'page' : null"
              class="relative flex h-full min-w-12 flex-col items-center justify-center gap-0.5 px-2 no-underline transition-colors hover:text-text-primary lg:min-w-20"
              [class.text-text-primary]="rla.isActive"
              [class.text-text-secondary]="!rla.isActive"
              [attr.data-nav]="item.id"
            >
              <svg [rdIcon]="item.icon" [size]="22" aria-hidden="true"></svg>
              <span class="sr-only max-w-full truncate text-xs leading-4 lg:not-sr-only">{{ item.labelKey | transloco }}</span>
              @if (rla.isActive) {
                <span class="absolute inset-x-1 bottom-0 h-0.5 rounded-full bg-text-primary" aria-hidden="true"></span>
              }
            </a>
          }
        }
        <span class="mx-1 h-8 w-px self-center bg-border" aria-hidden="true"></span>
        <rd-theme-toggle variant="stacked" />
        <rd-language-toggle variant="stacked" />
        @if (session.isAuthenticated()) {
          @if (meButton(); as me) {
            <ng-container *ngComponentOutlet="me; inputs: { variant: 'stacked' }" />
          }
        } @else if (session.isGuest()) {
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary ms-2 min-h-10 self-center">{{ 'auth.signIn.submit' | transloco }}</a>
        }
      </nav>

      <!-- Below md: the compact bar. -->
      <div class="ms-auto flex items-center gap-2 md:hidden">
        @if (searchBox()) {
          <a routerLink="/search" class="rd-icon-btn" [attr.aria-label]="'nav.search' | transloco" data-search-link>
            <svg rdIcon="Search" [size]="18"></svg>
          </a>
        }
        <rd-notifications-menu />
        <rd-theme-toggle variant="icon" />
        <rd-language-toggle variant="icon" />
        @if (session.isAuthenticated()) {
          @if (meButton(); as me) {
            <ng-container *ngComponentOutlet="me; inputs: { variant: 'icon' }" />
          }
        } @else if (session.isGuest()) {
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary hidden min-h-10 sm:inline-flex">{{ 'auth.signIn.submit' | transloco }}</a>
        }
      </div>
    </div>
  `,
})
export class TopBar {
  protected readonly session = inject(SessionStore);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  protected readonly nav = TOP_NAV;

  /** The search box or icon; the search page has its own box. */
  readonly searchBox = input(true);
  /** The header's search box (features/search/header-search.ts): its own chunk, loaded once a wide screen is idle. */
  protected readonly headerSearch = signal<Type<unknown> | null>(null);
  /** "Me" (layout/me-button.ts), once a member is signed in and its chunk arrived. */
  protected readonly meButton = signal<Type<unknown> | null>(null);
  /** Bumped to load "Me" again after a failed attempt. */
  private readonly retryMe = signal(0);

  constructor() {
    if (!this.isBrowser) return;

    let meLoading = false;
    effect(() => {
      this.retryMe();
      if (!this.session.isAuthenticated() || meLoading) return;
      meLoading = true;
      import('./me-button').then(
        ({ MeButton }) => this.meButton.set(MeButton),
        () => {
          // Offline before it arrived: try again once the browser is back online.
          meLoading = false;
          addEventListener('online', () => this.retryMe.update((n) => n + 1), { once: true });
        },
      );
    });

    afterNextRender(() => {
      if (typeof matchMedia === 'undefined') return;
      const wide = matchMedia(SEARCH_BOX_QUERY);
      const load = () => {
        wide.removeEventListener('change', onChange);
        const start = () =>
          Promise.all([import('../features/search/header-search'), appIconsReady()]).then(
            ([{ HeaderSearch }]) => this.headerSearch.set(HeaderSearch),
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
}
