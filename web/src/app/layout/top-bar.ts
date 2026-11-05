import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  PLATFORM_ID,
  Type,
  afterNextRender,
  computed,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { NgComponentOutlet, NgTemplateOutlet, isPlatformBrowser } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationStart, Router, RouterLink, RouterLinkActive } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { filter } from 'rxjs';
import { SessionStore } from '../core/auth/session.store';
import { ModerationSummaryStore } from '../core/moderation/moderation-summary.store';
import { NotificationsMenu } from '../features/notifications/notifications-menu';
import { Avatar } from '../shared/ui/avatar';
import { Wordmark } from '../shared/ui/wordmark';
import { MeMenuHost } from './me-menu-host';
import { TOP_NAV, profilePath } from './nav-items';
import { ThemeToggle } from './theme-toggle';

/** From this width the header has the search box (F16) and the nav row; below it, the compact bar. Tailwind's `md`. */
const SEARCH_BOX_QUERY = '(min-width: 48rem)';

type MeVariant = 'icon' | 'stacked';

/**
 * The top bar. From `md`: the ReadIn mark, the search box, then the destinations as an icon above a small label
 * (labels from `lg`; the current one gets a bar under it), the theme toggle and "Me" (its menu: profile, links,
 * appearance, sign out) or "Sign in". Below `md`: the mark, the search icon, the bell, the theme toggle and the avatar
 * (the bottom nav has the destinations). The Me menu is its own chunk, loaded when the button is hovered, focused or
 * opened; the bell's dropdown too (features/notifications/notifications-menu.ts).
 */
@Component({
  selector: 'rd-top-bar',
  imports: [RouterLink, RouterLinkActive, TranslocoPipe, Wordmark, Avatar, LucideDynamicIcon, NgComponentOutlet, NgTemplateOutlet, NotificationsMenu, ThemeToggle],
  providers: [{ provide: MeMenuHost, useExisting: TopBar }],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'sticky top-0 z-30 block border-b border-border bg-surface',
    '(document:pointerdown)': 'onDocumentPointer($event)',
    '(document:keydown.escape)': 'onEscape()',
  },
  template: `
    <ng-template #meMenuPanel>
      <div class="absolute end-0 top-full z-40 mt-2" data-me-menu-panel>
        @if (meMenu(); as component) {
          <ng-container *ngComponentOutlet="component" />
        } @else {
          <div class="rd-card w-72 p-4 shadow-raised" aria-hidden="true">
            <div class="flex items-center gap-3">
              <div class="rd-skeleton h-14 w-14 shrink-0 rounded-full"></div>
              <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-4 w-3/4"></div><div class="rd-skeleton h-3 w-1/2"></div></div>
            </div>
          </div>
        }
      </div>
    </ng-template>

    <div class="mx-auto flex h-16 max-w-[1128px] items-center gap-3 px-4">
      <a routerLink="/" class="flex shrink-0 items-center no-underline" [attr.aria-label]="'nav.home' | transloco" data-home-mark>
        <span class="inline-flex items-center" dir="ltr">
          <span class="inline-grid h-8 w-8 place-items-center rounded-md bg-primary font-latin text-[18px] font-bold text-on-primary" aria-hidden="true">R</span>
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
              <svg lucideIcon="Search" [size]="18" class="shrink-0" aria-hidden="true"></svg>
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
              <svg [lucideIcon]="item.icon" [size]="22" aria-hidden="true"></svg>
              <span class="sr-only max-w-full truncate text-xs leading-4 lg:not-sr-only">{{ item.labelKey | transloco }}</span>
              @if (rla.isActive) {
                <span class="absolute inset-x-1 bottom-0 h-0.5 rounded-full bg-text-primary" aria-hidden="true"></span>
              }
            </a>
          }
        }
        <span class="mx-1 h-8 w-px self-center bg-border" aria-hidden="true"></span>
        <rd-theme-toggle variant="stacked" />
        @if (session.isAuthenticated()) {
          <div class="relative flex h-full">
            <button
              #meStacked
              type="button"
              class="relative flex h-full min-w-12 cursor-pointer flex-col items-center justify-center gap-0.5 px-2 text-text-secondary transition-colors hover:text-text-primary aria-expanded:text-text-primary lg:min-w-20"
              aria-haspopup="menu"
              [attr.aria-expanded]="meOpen() === 'stacked'"
              [attr.aria-controls]="meOpen() === 'stacked' && meMenu() ? 'rd-me-menu' : null"
              (click)="toggleMe('stacked')"
              (pointerenter)="preloadMe()"
              (focus)="preloadMe()"
              data-me-trigger="stacked"
            >
              <span class="relative">
                <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="24" />
                @if (attention()) {
                  <span class="absolute -end-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-error ring-2 ring-surface" aria-hidden="true" data-me-attention></span>
                }
              </span>
              <span class="sr-only items-center gap-0.5 text-xs leading-4 lg:not-sr-only lg:flex">
                {{ 'nav.me' | transloco }}<svg lucideIcon="ChevronDown" [size]="14" aria-hidden="true"></svg>
              </span>
              @if (meOpen() === 'stacked') {
                <span class="absolute inset-x-1 bottom-0 h-0.5 rounded-full bg-text-primary" aria-hidden="true"></span>
              }
            </button>
            @if (meOpen() === 'stacked') {
              <ng-container [ngTemplateOutlet]="meMenuPanel" />
            }
          </div>
        } @else if (session.isGuest()) {
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary ms-2 min-h-10 self-center">{{ 'auth.signIn.submit' | transloco }}</a>
        }
      </nav>

      <!-- Below md: the compact bar. -->
      <div class="ms-auto flex items-center gap-2 md:hidden">
        @if (searchBox()) {
          <a routerLink="/search" class="rd-icon-btn" [attr.aria-label]="'nav.search' | transloco" data-search-link>
            <svg lucideIcon="Search" [size]="18"></svg>
          </a>
        }
        <rd-notifications-menu />
        <rd-theme-toggle variant="icon" />
        @if (session.isAuthenticated()) {
          <div class="relative flex">
            <button
              #meIcon
              type="button"
              class="relative grid h-10 w-10 cursor-pointer place-items-center rounded-full"
              aria-haspopup="menu"
              [attr.aria-expanded]="meOpen() === 'icon'"
              [attr.aria-controls]="meOpen() === 'icon' && meMenu() ? 'rd-me-menu' : null"
              (click)="toggleMe('icon')"
              (focus)="preloadMe()"
              data-me-trigger="icon"
            >
              <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="32" />
              @if (attention()) {
                <span class="absolute end-0 top-0 h-2.5 w-2.5 rounded-full bg-error ring-2 ring-surface" aria-hidden="true" data-me-attention></span>
              }
              <span class="sr-only">{{ 'nav.me' | transloco }}</span>
            </button>
            @if (meOpen() === 'icon') {
              <ng-container [ngTemplateOutlet]="meMenuPanel" />
            }
          </div>
        } @else if (session.isGuest()) {
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary hidden min-h-10 sm:inline-flex">{{ 'auth.signIn.submit' | transloco }}</a>
        }
      </div>
    </div>
  `,
})
export class TopBar implements MeMenuHost {
  protected readonly session = inject(SessionStore);
  /** Open reports (F22): a dot on Me for moderators; the count is in the menu. */
  private readonly moderation = inject(ModerationSummaryStore);
  private readonly router = inject(Router);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  protected readonly nav = TOP_NAV;
  protected readonly attention = computed(() => this.moderation.canModerate() && this.moderation.total() > 0);

  /** The search box or icon; the search page has its own box. */
  readonly searchBox = input(true);
  /** The header's search box (features/search/header-search.ts): its own chunk, loaded once a wide screen is idle. */
  protected readonly headerSearch = signal<Type<unknown> | null>(null);

  /** Which Me button's menu is open. */
  protected readonly meOpen = signal<MeVariant | null>(null);
  /** The Me menu (layout/me-menu.ts), once its chunk arrived. */
  protected readonly meMenu = signal<Type<unknown> | null>(null);
  private meLoading: Promise<boolean> | null = null;
  private readonly meStacked = viewChild<ElementRef<HTMLElement>>('meStacked');
  private readonly meIcon = viewChild<ElementRef<HTMLElement>>('meIcon');

  constructor() {
    // Leaving the page closes the Me menu (one of its links was opened).
    this.router.events
      .pipe(
        filter((e) => e instanceof NavigationStart),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.meOpen.set(null));

    if (!this.isBrowser) return;
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

  /** Starts loading the Me menu's chunk (hover or focus on the button); resolves to false when it couldn't load. */
  protected preloadMe(): Promise<boolean> {
    if (!this.isBrowser) return Promise.resolve(false);
    this.meLoading ??= import('./me-menu').then(
      ({ MeMenu }) => {
        this.meMenu.set(MeMenu);
        return true;
      },
      () => {
        this.meLoading = null; // offline: the next click tries again
        return false;
      },
    );
    return this.meLoading;
  }

  protected toggleMe(variant: MeVariant): void {
    if (this.meOpen() === variant) {
      this.closeMeMenu(true);
      return;
    }
    this.meOpen.set(variant);
    void this.preloadMe().then((loaded) => {
      if (loaded) return;
      // Offline before the menu's code arrived: the profile page has the same links.
      this.meOpen.set(null);
      void this.router.navigateByUrl(profilePath(this.session.username()));
    });
  }

  closeMeMenu(refocus: boolean): void {
    const open = this.meOpen();
    if (!open) return;
    this.meOpen.set(null);
    if (refocus) (open === 'stacked' ? this.meStacked() : this.meIcon())?.nativeElement.focus();
  }

  /** A click outside the open Me button and its menu closes the menu. */
  protected onDocumentPointer(event: PointerEvent): void {
    const open = this.meOpen();
    if (!open) return;
    const trigger = (open === 'stacked' ? this.meStacked() : this.meIcon())?.nativeElement;
    const wrapper = trigger?.parentElement;
    if (!wrapper?.contains(event.target as Node | null)) this.meOpen.set(null);
  }

  /** Escape closes the Me menu and gives the focus back to its button (also while the menu's code is loading). */
  protected onEscape(): void {
    this.closeMeMenu(true);
  }
}
